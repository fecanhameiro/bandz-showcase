import { Timestamp, FieldValue } from "firebase-admin/firestore";
import type {
  Firestore,
  DocumentData,
  QueryDocumentSnapshot,
} from "firebase-admin/firestore";
import type { Messaging } from "firebase-admin/messaging";
import { NotificationType } from "@bandz/shared/types";
import { Collections, NotificationDefaults } from "@bandz/shared/constants";
import { dispatchSingleNotification } from "./push-dispatch.service.js";
import { ZonedDateTime } from "../lib/zoned-date-time.js";

const PAGE_SIZE = 500;

interface EventData {
  eventName?: string;
  eventDate?: Timestamp;
  artistId?: string;
  artistName?: string;
  placeId?: string;
  placeName?: string;
  placeCity?: string;
  placeState?: string;
  genre?: string;
  hasImage?: boolean;
}

interface FollowNotifyResult {
  usersNotified: number;
  notificationsCreated: number;
  errors: number;
}

function buildLocation(
  city: string | null | undefined,
  state: string | null | undefined,
): string | null {
  const c = city?.trim() || "";
  const s = state?.trim() || "";
  if (!c && !s) return null;
  if (c && s) return `${c} - ${s}`;
  return c || s || null;
}

function buildNotificationDoc(
  notificationId: string,
  userId: string,
  type: NotificationType,
  eventId: string,
  eventData: EventData,
  category: string,
): Record<string, unknown> {
  const title =
    type === NotificationType.FOLLOW_PLACE
      ? eventData.placeName || eventData.eventName || "Novidade no seu lugar favorito"
      : eventData.artistName || eventData.eventName || "Show novo de artista que voce segue";

  const bodyParts: string[] = [];
  if (type === NotificationType.FOLLOW_ARTIST && eventData.placeName) {
    bodyParts.push(eventData.placeName);
  }
  if (type === NotificationType.FOLLOW_PLACE) {
    if (eventData.eventName) bodyParts.push(eventData.eventName);
    else if (eventData.artistName) bodyParts.push(eventData.artistName);
  }
  const location = buildLocation(eventData.placeCity, eventData.placeState);
  if (location) bodyParts.push(location);

  return {
    id: notificationId,
    userId,
    type,
    isRead: false,
    isSent: false,
    createdAt: FieldValue.serverTimestamp(),
    readAt: null,
    payloadVersion: NotificationDefaults.PAYLOAD_VERSION,
    nextEligibleAt: null,
    sentAt: null,
    deliveryAttempts: 0,
    deliveryTokens: [],
    fcmMessageIds: [],
    deeplink: null,
    lastAttemptedAt: null,
    date: eventData.eventDate ?? Timestamp.now(),
    genre: eventData.genre || null,
    city: eventData.placeCity || null,
    state: eventData.placeState || null,
    eventId,
    eventName: eventData.eventName || null,
    placeId: eventData.placeId || null,
    placeName: eventData.placeName || null,
    artistId: eventData.artistId || null,
    artistName: eventData.artistName || null,
    eventHasImage: eventData.hasImage ?? false,
    count: 1,
    eligibleAt: Timestamp.now(),
    fallbackTitle: title,
    fallbackBody: bodyParts.length > 0 ? bodyParts.join(", ") : null,
    notificationCategory: category,
  };
}

/**
 * Atomically creates a notification document. Returns true if created, false if already exists.
 */
async function createNotificationAtomic(
  notificationsRef: FirebaseFirestore.CollectionReference,
  notificationId: string,
  doc: Record<string, unknown>,
): Promise<boolean> {
  try {
    await notificationsRef.doc(notificationId).create(doc);
    return true;
  } catch (error: unknown) {
    const code = (error as { code?: number }).code;
    if (code === 6) {
      // ALREADY_EXISTS — safe to ignore (at-least-once trigger delivery)
      return false;
    }
    throw error;
  }
}

/**
 * Notify all users who follow a given artist about a new event.
 * Uses efficient Firestore array-contains query on preferences.favoriteArtists (string[]).
 */
export async function notifyArtistFollowers(
  db: Firestore,
  messaging: Messaging,
  eventId: string,
  eventData: EventData,
): Promise<FollowNotifyResult> {
  const result: FollowNotifyResult = { usersNotified: 0, notificationsCreated: 0, errors: 0 };

  if (!eventData.artistId) return result;

  const followersSnapshot = await db
    .collection(Collections.USERS)
    .where("preferences.favoriteArtists", "array-contains", eventData.artistId)
    .where("notificationsEnabled", "==", true)
    .get();

  if (followersSnapshot.empty) {
    console.log("notifyArtistFollowers: no followers found", { artistId: eventData.artistId });
    return result;
  }

  console.log("notifyArtistFollowers: found followers", {
    artistId: eventData.artistId,
    artistName: eventData.artistName,
    followerCount: followersSnapshot.size,
  });

  for (const userDoc of followersSnapshot.docs) {
    try {
      const userId = userDoc.id;
      const notificationId = `follow_artist_${eventId}`;
      const notificationsRef = userDoc.ref.collection(Collections.SUB_NOTIFICATIONS);

      const doc = buildNotificationDoc(
        notificationId, userId, NotificationType.FOLLOW_ARTIST,
        eventId, eventData, "follow_artist",
      );

      const created = await createNotificationAtomic(notificationsRef, notificationId, doc);
      if (!created) continue;

      result.notificationsCreated++;

      const dispatch = await dispatchSingleNotification(db, messaging, userId, notificationId);
      if (dispatch.succeeded) result.usersNotified++;
    } catch (error) {
      result.errors++;
      console.error("notifyArtistFollowers: error for user", { userId: userDoc.id, error });
    }
  }

  console.log("notifyArtistFollowers: completed", { eventId, ...result });
  return result;
}

/**
 * Notify all users who have a given place in favoritePlaces about a new event.
 * Iterates users in batches since favoritePlaces is an array of objects (can't use array-contains).
 * Known limitation: full scan, acceptable for <10k users (Campinas pilot).
 */
export async function notifyPlaceFollowers(
  db: Firestore,
  messaging: Messaging,
  eventId: string,
  eventData: EventData,
): Promise<FollowNotifyResult> {
  const result: FollowNotifyResult = { usersNotified: 0, notificationsCreated: 0, errors: 0 };

  if (!eventData.placeId) return result;

  let lastDoc: QueryDocumentSnapshot | undefined;

  while (true) {
    let query = db
      .collection(Collections.USERS)
      .where("notificationsEnabled", "==", true)
      .orderBy("__name__")
      .limit(PAGE_SIZE);
    if (lastDoc) query = query.startAfter(lastDoc);

    const snapshot = await query.get();
    if (snapshot.empty) break;
    lastDoc = snapshot.docs[snapshot.docs.length - 1];

    for (const userDoc of snapshot.docs) {
      const userData = userDoc.data();
      const favPlaces = userData.preferences?.favoritePlaces;
      if (!Array.isArray(favPlaces)) continue;

      const hasPlace = favPlaces.some(
        (p: DocumentData) => p.id === eventData.placeId,
      );
      if (!hasPlace) continue;

      try {
        const userId = userDoc.id;
        const notificationId = `follow_place_${eventId}`;
        const notificationsRef = userDoc.ref.collection(Collections.SUB_NOTIFICATIONS);

        const doc = buildNotificationDoc(
          notificationId, userId, NotificationType.FOLLOW_PLACE,
          eventId, eventData, "follow_place",
        );

        const created = await createNotificationAtomic(notificationsRef, notificationId, doc);
        if (!created) continue;

        result.notificationsCreated++;

        const dispatch = await dispatchSingleNotification(db, messaging, userId, notificationId);
        if (dispatch.succeeded) result.usersNotified++;
      } catch (error) {
        result.errors++;
        console.error("notifyPlaceFollowers: error for user", { userId: userDoc.id, error });
      }
    }

    if (snapshot.docs.length < PAGE_SIZE) break;
  }

  console.log("notifyPlaceFollowers: completed", { eventId, placeId: eventData.placeId, ...result });
  return result;
}

/**
 * Send "event today" reminders for all events happening today.
 * Uses Brazil timezone (America/Sao_Paulo) for "today" calculation.
 * Targets users who have favorited the event OR already received a notification for it.
 */
export async function generateEventTodayReminders(
  db: Firestore,
  messaging: Messaging,
): Promise<{ eventsProcessed: number; remindersCreated: number; remindersSent: number; errors: number }> {
  const stats = { eventsProcessed: 0, remindersCreated: 0, remindersSent: 0, errors: 0 };

  // Use Brazil timezone for "today" calculation
  const nowLocal = ZonedDateTime.now(NotificationDefaults.TIMEZONE);
  const todayStart = nowLocal.startOfDay().toTimestamp();
  const todayEnd = nowLocal.startOfDay().plusDays(1).toTimestamp();

  const eventsSnapshot = await db
    .collection(Collections.EVENTS)
    .where("eventDate", ">=", todayStart)
    .where("eventDate", "<", todayEnd)
    .get();

  if (eventsSnapshot.empty) {
    console.log("eventTodayReminders: no events today");
    return stats;
  }

  console.log("eventTodayReminders: events today", { count: eventsSnapshot.size });

  for (const eventDoc of eventsSnapshot.docs) {
    stats.eventsProcessed++;
    const eventData = eventDoc.data();
    const eventId = eventDoc.id;

    // Find users who favorited this event
    const usersWithFavorite = await db
      .collection(Collections.USERS)
      .where("preferences.favoriteEvents", "array-contains", eventId)
      .where("notificationsEnabled", "==", true)
      .get();

    // Also find users who already have any notification for this event (matched by genre/place/follow)
    const existingNotifications = await db
      .collectionGroup(Collections.SUB_NOTIFICATIONS)
      .where("eventId", "==", eventId)
      .get();

    // Collect unique userIds
    const userIds = new Set<string>();
    for (const doc of usersWithFavorite.docs) {
      userIds.add(doc.id);
    }
    for (const doc of existingNotifications.docs) {
      const userId = doc.ref.parent.parent?.id;
      if (userId) userIds.add(userId);
    }

    if (userIds.size === 0) continue;

    const title =
      eventData.artistName || eventData.eventName || "Show hoje";
    const bodyParts: string[] = [];
    if (eventData.placeName) bodyParts.push(eventData.placeName);
    const location = buildLocation(eventData.placeCity, eventData.placeState);
    if (location) bodyParts.push(location);

    for (const userId of userIds) {
      try {
        const notificationId = `event_today_${eventId}`;
        const userRef = db.collection(Collections.USERS).doc(userId);
        const notificationsRef = userRef.collection(Collections.SUB_NOTIFICATIONS);

        // Verify user still has notifications enabled
        const userSnap = await userRef.get();
        if (!userSnap.exists || userSnap.data()?.notificationsEnabled === false) continue;

        const doc: Record<string, unknown> = {
          id: notificationId,
          userId,
          type: NotificationType.EVENT_TODAY,
          isRead: false,
          isSent: false,
          createdAt: FieldValue.serverTimestamp(),
          readAt: null,
          payloadVersion: NotificationDefaults.PAYLOAD_VERSION,
          nextEligibleAt: null,
          sentAt: null,
          deliveryAttempts: 0,
          deliveryTokens: [],
          fcmMessageIds: [],
          deeplink: null,
          lastAttemptedAt: null,
          date: eventData.eventDate ?? Timestamp.now(),
          genre: eventData.genre || eventData.style || null,
          city: eventData.placeCity || null,
          state: eventData.placeState || null,
          eventId,
          eventName: eventData.eventName || null,
          placeId: eventData.placeId || null,
          placeName: eventData.placeName || null,
          artistId: eventData.artistId || null,
          artistName: eventData.artistName || null,
          eventHasImage: false,
          count: 1,
          eligibleAt: Timestamp.now(),
          fallbackTitle: `Hoje tem ${title}`,
          fallbackBody: bodyParts.length > 0 ? bodyParts.join(", ") : null,
          notificationCategory: "event_today",
        };

        const created = await createNotificationAtomic(notificationsRef, notificationId, doc);
        if (!created) continue;

        stats.remindersCreated++;

        const dispatch = await dispatchSingleNotification(db, messaging, userId, notificationId);
        if (dispatch.succeeded) stats.remindersSent++;
      } catch (error) {
        stats.errors++;
        console.error("eventTodayReminders: error", { eventId, userId, error });
      }
    }
  }

  console.log("eventTodayReminders: completed", stats);
  return stats;
}
