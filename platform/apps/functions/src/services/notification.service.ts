import { Timestamp, FieldValue } from "firebase-admin/firestore";
import type {
  CollectionReference,
  Firestore,
  DocumentData,
  WriteBatch,
  QueryDocumentSnapshot,
} from "firebase-admin/firestore";
import { NotificationType } from "@bandz/shared/types";
import { Collections, NotificationDefaults } from "@bandz/shared/constants";
import { ZonedDateTime } from "../lib/zoned-date-time.js";

interface UserDocument {
  notificationsEnabled?: boolean;
  preferences?: {
    favoriteGenres?: Array<Record<string, string>>;
    favoritePlaces?: Array<Record<string, string | boolean>>;
  };
  userID?: string;
  userLocation?: { city?: string; state?: string };
  timezone?: string;
  notificationSettings?: {
    preferredSummaryHour?: number;
    preferredReminderHour?: number;
    quietHours?: { startHour?: number; endHour?: number };
  };
}

interface SchedulingConfig {
  timezone: string;
  summaryHour: number;
  reminderHour: number;
}

interface FavoriteGenre {
  id?: string;
  name?: string;
}

interface FavoritePlace {
  id?: string;
  name?: string;
  city?: string;
  state?: string;
  active?: boolean;
}

interface EventMatch {
  id: string;
  eventName?: string;
  eventDate: Timestamp | null;
  genres: string[];
  placeId?: string;
  placeName?: string;
  placeCity?: string;
  placeState?: string;
  artistId?: string;
  artistName?: string;
  hasImage?: boolean;
}

type MatchedEvent = EventMatch & {
  matchedGenres: string[];
  matchedPlace?: FavoritePlace;
};

interface NotificationToCreate {
  id: string;
  data: Record<string, unknown>;
}

interface GenerationStats {
  usersProcessed: number;
  usersSkipped: number;
  notificationsCreated: number;
  errors: number;
}

const PAGE_SIZE = 500;

export async function generateDailyUserNotifications(
  db: Firestore,
): Promise<void> {
  const startTime = Date.now();
  const stats: GenerationStats = {
    usersProcessed: 0,
    usersSkipped: 0,
    notificationsCreated: 0,
    errors: 0,
  };

  const upcomingEvents = await fetchUpcomingEvents(db);
  if (upcomingEvents.length === 0) {
    console.log("GenerateNotifications: no upcoming events found");
    return;
  }

  let lastDoc: QueryDocumentSnapshot | undefined;

  while (true) {
    let query = db
      .collection(Collections.USERS)
      .orderBy("__name__")
      .limit(PAGE_SIZE);
    if (lastDoc) query = query.startAfter(lastDoc);

    const snapshot = await query.get();
    if (snapshot.empty) break;

    lastDoc = snapshot.docs[snapshot.docs.length - 1];

    const results = await Promise.allSettled(
      snapshot.docs.map((userDoc) =>
        processUserNotifications(db, userDoc, upcomingEvents, stats),
      ),
    );

    for (const result of results) {
      if (result.status === "rejected") {
        stats.errors++;
        console.error(
          "GenerateNotifications: user processing failed",
          result.reason,
        );
      }
    }

    if (snapshot.docs.length < PAGE_SIZE) break;
  }

  console.log("GenerateNotifications: completed", {
    ...stats,
    durationMs: Date.now() - startTime,
    eventsConsidered: upcomingEvents.length,
  });
}

async function processUserNotifications(
  db: Firestore,
  userDoc: QueryDocumentSnapshot,
  upcomingEvents: EventMatch[],
  stats: GenerationStats,
): Promise<void> {
  const userData = userDoc.data() as UserDocument;
  if (userData.notificationsEnabled === false) {
    stats.usersSkipped++;
    return;
  }

  const favoriteGenres = extractFavoriteGenres(
    userData.preferences?.favoriteGenres,
  );
  const favoritePlaces = extractFavoritePlaces(
    userData.preferences?.favoritePlaces,
  );

  if (favoriteGenres.length === 0 && favoritePlaces.length === 0) {
    stats.usersSkipped++;
    return;
  }

  const matchedEvents = findMatchingEvents(
    upcomingEvents,
    favoriteGenres,
    favoritePlaces,
  );
  if (matchedEvents.length === 0) {
    stats.usersSkipped++;
    return;
  }

  const notificationsCollection = userDoc.ref.collection("notifications");
  const scheduling = resolveSchedulingConfig(userData);
  const userId = userDoc.id;

  const existingIds = await fetchExistingNotificationIds(
    notificationsCollection,
  );

  const toCreate: NotificationToCreate[] = [];

  collectEventNotifications(
    toCreate,
    matchedEvents,
    scheduling,
    userId,
    existingIds,
  );
  collectPlaceNotifications(
    toCreate,
    matchedEvents,
    favoritePlaces,
    scheduling,
    userId,
    existingIds,
  );
  collectArtistNotifications(
    toCreate,
    matchedEvents,
    scheduling,
    userId,
    existingIds,
  );

  if (toCreate.length === 0) return;

  const batches: WriteBatch[] = [];
  let currentBatch = db.batch();
  let count = 0;

  for (const item of toCreate) {
    currentBatch.set(notificationsCollection.doc(item.id), item.data);
    count++;
    if (count >= 500) {
      batches.push(currentBatch);
      currentBatch = db.batch();
      count = 0;
    }
  }
  if (count > 0) batches.push(currentBatch);

  await Promise.all(batches.map((b) => b.commit()));
  stats.notificationsCreated += toCreate.length;
  stats.usersProcessed++;
}

async function fetchExistingNotificationIds(
  collection: CollectionReference,
): Promise<Set<string>> {
  const snapshot = await collection.select().get();
  return new Set(snapshot.docs.map((doc) => doc.id));
}

function resolveSchedulingConfig(userData: UserDocument): SchedulingConfig {
  return {
    timezone:
      userData.timezone?.trim() || NotificationDefaults.TIMEZONE,
    summaryHour: clampHour(
      userData.notificationSettings?.preferredSummaryHour,
      NotificationDefaults.SUMMARY_HOUR,
    ),
    reminderHour: clampHour(
      userData.notificationSettings?.preferredReminderHour,
      NotificationDefaults.REMINDER_HOUR,
    ),
  };
}

function clampHour(hour: number | undefined, fallback: number): number {
  if (
    typeof hour === "number" &&
    Number.isFinite(hour) &&
    hour >= 0 &&
    hour <= 23
  ) {
    return Math.floor(hour);
  }
  return fallback;
}

function calculateEligibleAt(
  eventDate: Timestamp | null,
  scheduling: SchedulingConfig,
): Timestamp {
  const zone = scheduling.timezone || NotificationDefaults.TIMEZONE;
  const nowLocal = ZonedDateTime.now(zone);
  const summaryHour = scheduling.summaryHour ?? NotificationDefaults.SUMMARY_HOUR;
  const reminderHour = scheduling.reminderHour ?? NotificationDefaults.REMINDER_HOUR;

  let target = nowLocal.setTime(summaryHour, 0, 0, 0);

  if (eventDate) {
    const eventLocal = ZonedDateTime.fromTimestamp(zone, eventDate);
    const hoursUntilEvent = eventLocal.diffHours(nowLocal);

    if (hoursUntilEvent <= 6) {
      target = nowLocal.plusMinutes(5);
    } else if (hoursUntilEvent <= 36) {
      let reminder = eventLocal.plusHours(-3);
      if (reminder.isBefore(nowLocal)) {
        reminder = nowLocal.plusMinutes(30);
      }
      if (reminder.hour < reminderHour) {
        reminder = reminder.setTime(reminderHour, 0, 0, 0);
        if (reminder.isBefore(nowLocal)) {
          reminder = nowLocal.plusMinutes(30);
        }
      }
      target = reminder;
    } else {
      target = eventLocal.startOfDay().setTime(summaryHour, 0, 0, 0);
      if (target.isBefore(nowLocal)) {
        target = nowLocal.plusMinutes(5);
      }
    }
  }

  if (target.isBefore(nowLocal)) {
    target = target.plusDays(1);
  }

  return target.toTimestamp();
}

async function fetchUpcomingEvents(db: Firestore): Promise<EventMatch[]> {
  const now = Timestamp.now();
  const futureLimit = Timestamp.fromDate(
    new Date(
      Date.now() + NotificationDefaults.DAYS_AHEAD * 24 * 60 * 60 * 1000,
    ),
  );

  const eventsSnapshot = await db
    .collection(Collections.EVENTS)
    .where("eventDate", ">=", now)
    .where("eventDate", "<=", futureLimit)
    .get();

  return eventsSnapshot.docs.map((doc) => {
    const data = doc.data();
    let eventDate: Timestamp | null = null;
    if (data.eventDate instanceof Timestamp) {
      eventDate = data.eventDate;
    } else if (data.eventDate) {
      eventDate = Timestamp.fromDate(
        data.eventDate.toDate
          ? data.eventDate.toDate()
          : new Date(data.eventDate),
      );
    }

    return {
      id: doc.id,
      eventName: data.eventName,
      eventDate,
      genres: collectEventGenres(data),
      placeId: data.placeId,
      placeName: data.placeName,
      placeCity: data.placeCity,
      placeState: data.placeState,
      artistId: data.artistId,
      artistName: data.artistName,
      hasImage: resolveEventHasImage(data),
    };
  });
}

function extractFavoriteGenres(
  rawGenres: Array<Record<string, string>> | undefined,
): FavoriteGenre[] {
  if (!rawGenres || !Array.isArray(rawGenres)) return [];
  return rawGenres
    .map((g) => ({ id: g.id, name: g.name }))
    .filter((g) => Boolean(g.id || g.name));
}

function extractFavoritePlaces(
  rawPlaces: Array<Record<string, string | boolean>> | undefined,
): FavoritePlace[] {
  if (!rawPlaces || !Array.isArray(rawPlaces)) return [];
  return rawPlaces
    .filter((p) => p.active !== false)
    .map((p) => ({
      id: p.id as string | undefined,
      name: p.name as string | undefined,
      city: p.city as string | undefined,
      state: p.state as string | undefined,
      active: p.active as boolean | undefined,
    }));
}

/** Same as extractFavoritePlaces but ignores active flag (for test mode) */
function extractAllFavoritePlaces(
  rawPlaces: Array<Record<string, string | boolean>> | undefined,
): FavoritePlace[] {
  if (!rawPlaces || !Array.isArray(rawPlaces)) return [];
  return rawPlaces.map((p) => ({
    id: p.id as string | undefined,
    name: p.name as string | undefined,
    city: p.city as string | undefined,
    state: p.state as string | undefined,
    active: true,
  }));
}

/** @internal exported for testing */
export function matchesPlace(event: EventMatch, place: FavoritePlace): boolean {
  if (place.id && event.placeId && place.id === event.placeId) return true;
  return (
    !!place.city &&
    !!event.placeCity &&
    normalizeText(place.city) === normalizeText(event.placeCity || "") &&
    (!place.state ||
      normalizeText(place.state) === normalizeText(event.placeState || ""))
  );
}

/** @internal exported for testing */
export function findMatchingEvents(
  events: EventMatch[],
  favoriteGenres: FavoriteGenre[],
  favoritePlaces: FavoritePlace[],
): MatchedEvent[] {
  const normalizedFavoriteGenres = favoriteGenres.map((g) =>
    normalizeText(g.name || g.id || ""),
  );

  return events
    .map((event) => {
      const matchedGenres = event.genres.filter((genre) => {
        const normalized = normalizeText(genre);
        return normalizedFavoriteGenres.some((fav) => normalized === fav);
      });

      const matchedPlace = favoritePlaces.find((place) =>
        matchesPlace(event, place),
      );

      return {
        ...event,
        matchedGenres: [...new Set(matchedGenres)],
        matchedPlace,
      };
    })
    .filter((e) => e.matchedGenres.length > 0 || e.matchedPlace);
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

function buildNotificationBase(
  notificationId: string,
  userId: string,
  scheduling: SchedulingConfig,
): Record<string, unknown> {
  return {
    id: notificationId,
    userId,
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
  };
}

function collectEventNotifications(
  toCreate: NotificationToCreate[],
  events: MatchedEvent[],
  scheduling: SchedulingConfig,
  userId: string,
  existingIds: Set<string>,
): void {
  for (const event of events) {
    const notificationId = `event_${event.id}`;
    if (existingIds.has(notificationId)) continue;

    const title =
      event.eventName ||
      event.artistName ||
      event.placeName ||
      "Evento que combina com voce";
    const bodyParts: string[] = [];
    if (event.placeName) bodyParts.push(event.placeName);
    const location = buildLocation(
      event.placeCity || event.matchedPlace?.city,
      event.placeState || event.matchedPlace?.state,
    );
    if (location) bodyParts.push(location);
    else if (event.matchedGenres.length > 0)
      bodyParts.push(event.matchedGenres[0]);

    toCreate.push({
      id: notificationId,
      data: {
        ...buildNotificationBase(notificationId, userId, scheduling),
        type: NotificationType.EVENT,
        date: event.eventDate ?? Timestamp.now(),
        genre: event.matchedGenres[0] || null,
        city: event.placeCity || event.matchedPlace?.city || null,
        state: event.placeState || event.matchedPlace?.state || null,
        eventId: event.id,
        eventName: event.eventName || null,
        placeId: event.placeId || event.matchedPlace?.id || null,
        placeName: event.placeName || event.matchedPlace?.name || null,
        artistId: event.artistId || null,
        artistName: event.artistName || null,
        eventHasImage: event.hasImage ?? false,
        count: 1,
        eligibleAt: calculateEligibleAt(event.eventDate ?? null, scheduling),
        fallbackTitle: title,
        fallbackBody: bodyParts.length > 0 ? bodyParts.join(" • ") : null,
        notificationCategory: "event_recommendation",
      },
    });
  }
}

function collectPlaceNotifications(
  toCreate: NotificationToCreate[],
  events: MatchedEvent[],
  favoritePlaces: FavoritePlace[],
  scheduling: SchedulingConfig,
  userId: string,
  existingIds: Set<string>,
): void {
  for (const place of favoritePlaces) {
    const relatedEvents = events.filter((event) =>
      matchesPlace(event, place),
    );

    if (relatedEvents.length === 0) continue;

    const fallbackKey = normalizeText(
      [place.name, place.city, place.state].filter(Boolean).join("_"),
    );
    const notificationId = `place_${place.id || fallbackKey || "favorito"}`;
    if (existingIds.has(notificationId)) continue;

    const earliest = relatedEvents.reduce((a, b) => {
      if (!a.eventDate) return b;
      if (!b.eventDate) return a;
      return b.eventDate.toMillis() < a.eventDate.toMillis() ? b : a;
    }, relatedEvents[0]);

    const genres = [...new Set(relatedEvents.flatMap((e) => e.matchedGenres))];
    const title =
      place.name || earliest.placeName || "Novidades no seu lugar favorito";
    const bodyParts: string[] = [];
    if (relatedEvents.length > 1)
      bodyParts.push(`${relatedEvents.length} eventos chegando`);
    else if (earliest.eventName) bodyParts.push(earliest.eventName);
    const location = buildLocation(
      place.city || earliest.placeCity,
      place.state || earliest.placeState,
    );
    if (location) bodyParts.push(location);

    toCreate.push({
      id: notificationId,
      data: {
        ...buildNotificationBase(notificationId, userId, scheduling),
        type: NotificationType.PLACE,
        date: earliest.eventDate ?? Timestamp.now(),
        genre: genres[0] || null,
        city: place.city || earliest.placeCity || null,
        state: place.state || earliest.placeState || null,
        eventId: null,
        eventName: null,
        placeId: place.id || earliest.placeId || null,
        placeName: place.name || earliest.placeName || null,
        artistId: null,
        artistName: null,
        count: relatedEvents.length,
        eligibleAt: calculateEligibleAt(
          earliest.eventDate ?? null,
          scheduling,
        ),
        fallbackTitle: title,
        fallbackBody: bodyParts.length > 0 ? bodyParts.join(" • ") : null,
        notificationCategory: "place_digest",
      },
    });
  }
}

function collectArtistNotifications(
  toCreate: NotificationToCreate[],
  events: MatchedEvent[],
  scheduling: SchedulingConfig,
  userId: string,
  existingIds: Set<string>,
  minEvents = 2,
): void {
  const artistGroups = new Map<string, MatchedEvent[]>();

  for (const event of events) {
    const key =
      event.artistId ||
      (event.artistName ? normalizeText(event.artistName) : null);
    if (!key) continue;
    if (!artistGroups.has(key)) artistGroups.set(key, []);
    artistGroups.get(key)!.push(event);
  }

  for (const [artistKey, artistEvents] of artistGroups) {
    if (artistEvents.length < minEvents) continue;

    const notificationId = `artist_${artistKey}`;
    if (existingIds.has(notificationId)) continue;

    const sorted = artistEvents
      .filter((e) => e.eventDate)
      .sort((a, b) => a.eventDate!.toMillis() - b.eventDate!.toMillis());
    const first = sorted[0] || artistEvents[0];

    const genres = [...new Set(artistEvents.flatMap((e) => e.matchedGenres))];
    const title = first.artistName || "Shows imperdiveis para voce";
    const bodyParts: string[] = [];
    if (artistEvents.length > 1)
      bodyParts.push(`${artistEvents.length} datas confirmadas`);
    if (first.placeName) bodyParts.push(first.placeName);
    const location = buildLocation(first.placeCity, first.placeState);
    if (location) bodyParts.push(location);

    toCreate.push({
      id: notificationId,
      data: {
        ...buildNotificationBase(notificationId, userId, scheduling),
        type: NotificationType.ARTIST,
        date: first.eventDate ?? Timestamp.now(),
        genre: genres[0] || null,
        city: first.placeCity || null,
        state: first.placeState || null,
        eventId: null,
        eventName: null,
        placeId: null,
        placeName: null,
        artistId: first.artistId || artistKey,
        artistName: first.artistName || null,
        count: artistEvents.length,
        eligibleAt: calculateEligibleAt(first.eventDate ?? null, scheduling),
        fallbackTitle: title,
        fallbackBody: bodyParts.length > 0 ? bodyParts.join(" • ") : null,
        notificationCategory: "artist_digest",
      },
    });
  }
}

function collectEventGenres(data: DocumentData): string[] {
  const genres: string[] = [];
  if (Array.isArray(data.placeGenres)) genres.push(...data.placeGenres);
  if (Array.isArray(data.placeStyles)) genres.push(...data.placeStyles);
  if (Array.isArray(data.artistGenres)) genres.push(...data.artistGenres);
  if (Array.isArray(data.artistStyles)) genres.push(...data.artistStyles);
  if (data.style && typeof data.style === "string") genres.push(data.style);
  return genres;
}

function resolveEventHasImage(data: DocumentData): boolean {
  for (const candidate of [
    data.hasImage,
    data.has_image,
    data.eventHasImage,
    data.event_has_image,
  ]) {
    if (typeof candidate === "boolean") return candidate;
    if (typeof candidate === "string") {
      const n = candidate.trim().toLowerCase();
      if (["true", "1", "yes"].includes(n)) return true;
      if (["false", "0", "no"].includes(n)) return false;
    }
    if (typeof candidate === "number") return candidate > 0;
  }

  return false;
}

/** @internal exported for testing */
export function normalizeText(value: string): string {
  return value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim();
}

const TYPE_PREFIXES: Record<string, string> = {
  [NotificationType.EVENT]: "event_",
  [NotificationType.PLACE]: "place_",
  [NotificationType.ARTIST]: "artist_",
};

async function deleteExistingNotificationsByType(
  collection: CollectionReference,
  typesFilter: NotificationType[] | null,
): Promise<void> {
  const snapshot = await collection.get();
  if (snapshot.empty) return;

  const prefixes = typesFilter
    ? typesFilter.map((t) => TYPE_PREFIXES[t]).filter(Boolean)
    : Object.values(TYPE_PREFIXES);

  const toDelete = snapshot.docs.filter((doc) =>
    prefixes.some((prefix) => doc.id.startsWith(prefix)),
  );

  if (toDelete.length === 0) return;

  const db = collection.firestore;
  const batches: WriteBatch[] = [];
  let batch = db.batch();
  let count = 0;

  for (const doc of toDelete) {
    batch.delete(doc.ref);
    count++;
    if (count >= 500) {
      batches.push(batch);
      batch = db.batch();
      count = 0;
    }
  }
  if (count > 0) batches.push(batch);

  await Promise.all(batches.map((b) => b.commit()));
}

/**
 * Generates notifications for a single user on demand (used by admin test trigger).
 * Reuses the same matching + collect logic as the daily scheduler but:
 * - Targets a single user by ID
 * - Optionally filters by notification type
 * - Sets eligibleAt = now so dispatch can send immediately
 */
export async function generateNotificationsForUser(
  db: Firestore,
  userId: string,
  options: { types?: NotificationType[]; force?: boolean } = {},
): Promise<{ created: string[]; skippedReason: string | null }> {
  const userRef = db.collection(Collections.USERS).doc(userId);
  const userSnap = await userRef.get();
  if (!userSnap.exists) {
    return { created: [], skippedReason: "user_not_found" };
  }

  const userData = userSnap.data() as UserDocument;

  const favoriteGenres = extractFavoriteGenres(
    userData.preferences?.favoriteGenres,
  );
  // In test/force mode, include all places regardless of active status
  const favoritePlaces = options.force
    ? extractAllFavoritePlaces(userData.preferences?.favoritePlaces)
    : extractFavoritePlaces(userData.preferences?.favoritePlaces);

  console.log("generateForUser: user preferences", {
    userId,
    favoriteGenres: favoriteGenres.map((g) => g.name || g.id),
    favoritePlaces: favoritePlaces.map((p) => ({
      id: p.id,
      name: p.name,
      city: p.city,
      state: p.state,
    })),
    forceMode: options.force ?? false,
  });

  if (favoriteGenres.length === 0 && favoritePlaces.length === 0) {
    return { created: [], skippedReason: "no_preferences" };
  }

  const upcomingEvents = await fetchUpcomingEvents(db);
  if (upcomingEvents.length === 0) {
    return { created: [], skippedReason: "no_upcoming_events" };
  }

  console.log("generateForUser: upcoming events", {
    total: upcomingEvents.length,
    sample: upcomingEvents.slice(0, 5).map((e) => ({
      id: e.id,
      name: e.eventName,
      placeId: e.placeId,
      placeName: e.placeName,
      placeCity: e.placeCity,
      artistId: e.artistId,
      artistName: e.artistName,
      genres: e.genres,
    })),
  });

  const matchedEvents = findMatchingEvents(
    upcomingEvents,
    favoriteGenres,
    favoritePlaces,
  );

  console.log("generateForUser: matched events", {
    matchedCount: matchedEvents.length,
    events: matchedEvents.map((e) => ({
      id: e.id,
      name: e.eventName,
      matchedGenres: e.matchedGenres,
      matchedPlace: e.matchedPlace
        ? { id: e.matchedPlace.id, name: e.matchedPlace.name, city: e.matchedPlace.city }
        : null,
      artistId: e.artistId,
      artistName: e.artistName,
      placeId: e.placeId,
      placeName: e.placeName,
      placeCity: e.placeCity,
    })),
  });

  if (matchedEvents.length === 0) {
    return { created: [], skippedReason: "no_matching_events" };
  }

  const notificationsCollection = userRef.collection("notifications");
  const scheduling = resolveSchedulingConfig(userData);

  // If force mode, delete existing notifications of the target types first
  const typesFilter = options.types && options.types.length > 0 ? options.types : null;
  if (options.force) {
    await deleteExistingNotificationsByType(notificationsCollection, typesFilter);
    console.log("generateForUser: force-deleted existing notifications for types", typesFilter ?? "all");
  }

  const existingIds = await fetchExistingNotificationIds(notificationsCollection);
  console.log("generateForUser: existing notification IDs", [...existingIds]);

  const toCreate: NotificationToCreate[] = [];

  if (!typesFilter || typesFilter.includes(NotificationType.EVENT)) {
    const beforeCount = toCreate.length;
    collectEventNotifications(toCreate, matchedEvents, scheduling, userId, existingIds);
    console.log("generateForUser: collectEvent created", toCreate.length - beforeCount);
  }
  if (!typesFilter || typesFilter.includes(NotificationType.PLACE)) {
    const beforeCount = toCreate.length;
    collectPlaceNotifications(toCreate, matchedEvents, favoritePlaces, scheduling, userId, existingIds);
    console.log("generateForUser: collectPlace created", toCreate.length - beforeCount, {
      favoritePlacesCount: favoritePlaces.length,
      matchedEventsWithPlace: matchedEvents.filter((e) => e.matchedPlace).length,
    });
  }
  if (!typesFilter || typesFilter.includes(NotificationType.ARTIST)) {
    const beforeCount = toCreate.length;
    collectArtistNotifications(toCreate, matchedEvents, scheduling, userId, existingIds, options.force ? 1 : 2);
    // Log artist grouping for debug
    const artistGroups = new Map<string, number>();
    for (const event of matchedEvents) {
      const key = event.artistId || (event.artistName ? normalizeText(event.artistName) : null);
      if (key) artistGroups.set(key, (artistGroups.get(key) ?? 0) + 1);
    }
    console.log("generateForUser: collectArtist created", toCreate.length - beforeCount, {
      artistGroups: Object.fromEntries(artistGroups),
    });
  }

  if (toCreate.length === 0) {
    const reason = options.force
      ? "no_matches_for_type"
      : "all_already_exist";
    console.log("generateForUser: nothing to create", { reason, typesFilter });
    return { created: [], skippedReason: reason };
  }

  // Override eligibleAt to NOW so dispatch sends immediately
  const now = Timestamp.now();
  for (const item of toCreate) {
    item.data.eligibleAt = now;
  }

  const batches: WriteBatch[] = [];
  let currentBatch = db.batch();
  let count = 0;

  for (const item of toCreate) {
    currentBatch.set(notificationsCollection.doc(item.id), item.data);
    count++;
    if (count >= 500) {
      batches.push(currentBatch);
      currentBatch = db.batch();
      count = 0;
    }
  }
  if (count > 0) batches.push(currentBatch);

  await Promise.all(batches.map((b) => b.commit()));

  return { created: toCreate.map((n) => n.id), skippedReason: null };
}
