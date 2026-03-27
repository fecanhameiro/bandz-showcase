import { Timestamp, FieldValue } from "firebase-admin/firestore";
import type {
  Firestore,
  DocumentData,
  QueryDocumentSnapshot,
} from "firebase-admin/firestore";
import type {
  Messaging,
  MulticastMessage,
  BatchResponse,
} from "firebase-admin/messaging";
import type { Notification } from "@bandz/shared/types";
import { NotificationType } from "@bandz/shared/types";
import { Collections, NotificationDefaults } from "@bandz/shared/constants";
import { ZonedDateTime } from "../lib/zoned-date-time.js";

interface DispatchConfig {
  batchSize: number;
  dailyUserLimit: number;
  quietHoursStart: number;
  quietHoursEnd: number;
  primaryWindowStart: number;
  fallbackTimezone: string;
  staleTokenDays: number;
  retryDelayMinutes: number;
  timeoutMs: number;
}

interface DeviceTokenRecord {
  id: string;
  token: string;
  platform?: string | null;
  locale?: string | null;
  lastSeenAt?: Timestamp | null;
}

interface NotificationDocument {
  id: string;
  ref: FirebaseFirestore.DocumentReference<DocumentData>;
  data: Notification;
  userId: string;
}

interface DispatchUserDocument {
  notificationsEnabled?: boolean;
  timezone?: string;
  notificationSettings?: {
    quietHours?: { startHour?: number; endHour?: number };
  };
  dailyPushCount?: number;
  dailyPushDate?: string;
}

interface QuietHoursConfig {
  startHour: number;
  endHour: number;
}

interface DispatchStats {
  batchesProcessed: number;
  notificationsProcessed: number;
  notificationsSent: number;
  notificationsDeferred: number;
  usersProcessed: number;
  errors: number;
}

const DEFAULT_CONFIG: DispatchConfig = {
  batchSize: NotificationDefaults.BATCH_SIZE,
  dailyUserLimit: NotificationDefaults.DAILY_LIMIT,
  quietHoursStart: NotificationDefaults.QUIET_HOURS_START,
  quietHoursEnd: NotificationDefaults.QUIET_HOURS_END,
  primaryWindowStart: NotificationDefaults.SUMMARY_HOUR,
  fallbackTimezone: NotificationDefaults.TIMEZONE,
  staleTokenDays: NotificationDefaults.STALE_TOKEN_DAYS,
  retryDelayMinutes: NotificationDefaults.RETRY_DELAY_MINUTES,
  timeoutMs: 480_000, // 8 min — stop 1 min before 540s function timeout
};

export async function dispatchPendingNotifications(
  db: Firestore,
  messaging: Messaging,
  config: Partial<DispatchConfig> = {},
): Promise<void> {
  const cfg = { ...DEFAULT_CONFIG, ...config };
  const startTime = Date.now();
  const stats: DispatchStats = {
    batchesProcessed: 0,
    notificationsProcessed: 0,
    notificationsSent: 0,
    notificationsDeferred: 0,
    usersProcessed: 0,
    errors: 0,
  };

  let lastDoc: QueryDocumentSnapshot | undefined;

  while (Date.now() - startTime < cfg.timeoutMs) {
    let query = db
      .collectionGroup("notifications")
      .where("isSent", "==", false)
      .orderBy("__name__")
      .limit(cfg.batchSize);

    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const pendingSnapshot = await query.get();

    if (pendingSnapshot.empty) break;

    stats.batchesProcessed++;
    lastDoc = pendingSnapshot.docs[pendingSnapshot.docs.length - 1];

    const notificationsByUser = new Map<string, NotificationDocument[]>();

    for (const doc of pendingSnapshot.docs) {
      const userId = doc.ref.parent.parent?.id;
      if (!userId) continue;

      const data = doc.data() as Notification;
      const notification: NotificationDocument = {
        id: data.id || doc.id,
        ref: doc.ref,
        data: { ...data, id: data.id || doc.id },
        userId,
      };

      if (!notificationsByUser.has(userId))
        notificationsByUser.set(userId, []);
      notificationsByUser.get(userId)!.push(notification);
    }

    for (const [userId, notifications] of notificationsByUser) {
      try {
        await processUserNotifications(
          db,
          messaging,
          cfg,
          userId,
          notifications,
          stats,
        );
        stats.usersProcessed++;
      } catch (error) {
        stats.errors++;
        console.error("PushDispatch: failed for user", { userId, error });
      }
    }

    if (pendingSnapshot.docs.length < cfg.batchSize) break;
  }

  if (
    stats.batchesProcessed > 0 ||
    stats.notificationsSent > 0 ||
    stats.errors > 0
  ) {
    console.log("PushDispatch: completed", {
      ...stats,
      durationMs: Date.now() - startTime,
    });
  } else {
    console.log("PushDispatch: no pending notifications");
  }
}

async function processUserNotifications(
  db: Firestore,
  messaging: Messaging,
  cfg: DispatchConfig,
  userId: string,
  notifications: NotificationDocument[],
  stats: DispatchStats,
): Promise<void> {
  if (notifications.length === 0) return;

  const userRef = db.collection(Collections.USERS).doc(userId);
  const userSnap = await userRef.get();
  if (!userSnap.exists) return;

  const userData = userSnap.data() as DispatchUserDocument;
  if (userData.notificationsEnabled === false) return;

  const tokens = await fetchActiveTokens(userRef, cfg.staleTokenDays);
  if (tokens.length === 0) return;

  const timezone = userData.timezone?.trim() || cfg.fallbackTimezone;
  const nowLocal = ZonedDateTime.now(timezone);
  const quietHours = resolveQuietHours(userData, cfg);

  if (isWithinQuietHours(nowLocal, quietHours)) {
    const deferUntil = nextAllowedTime(
      nowLocal,
      quietHours,
      cfg.primaryWindowStart,
    );
    await deferNotifications(notifications, deferUntil);
    stats.notificationsDeferred += notifications.length;
    return;
  }

  const todayKey = formatDateKey(nowLocal);
  const existingCount =
    userData.dailyPushDate === todayKey ? (userData.dailyPushCount ?? 0) : 0;

  if (existingCount >= cfg.dailyUserLimit) {
    await deferNotifications(
      notifications,
      nextMorning(nowLocal, cfg.primaryWindowStart),
    );
    stats.notificationsDeferred += notifications.length;
    return;
  }

  const eligible = filterEligibleNotifications(notifications);
  if (eligible.length === 0) return;

  const prioritized = prioritizeNotifications(eligible, nowLocal);
  let remainingSlots = cfg.dailyUserLimit - existingCount;
  let sentCount = existingCount;

  for (const notification of prioritized) {
    if (remainingSlots <= 0) break;

    stats.notificationsProcessed++;
    const sent = await dispatchNotification(
      messaging,
      userRef,
      userId,
      notification,
      tokens,
      timezone,
      nowLocal,
      todayKey,
      sentCount,
      cfg.retryDelayMinutes,
    );

    if (sent) {
      sentCount++;
      remainingSlots--;
      stats.notificationsSent++;
    }
  }
}

async function dispatchNotification(
  messaging: Messaging,
  userRef: FirebaseFirestore.DocumentReference,
  userId: string,
  notification: NotificationDocument,
  tokens: DeviceTokenRecord[],
  timezone: string,
  nowLocal: ZonedDateTime,
  todayKey: string,
  currentCount: number,
  retryDelayMinutes: number,
): Promise<boolean> {
  const message = buildMulticastMessage(
    notification.data,
    tokens,
    timezone,
    nowLocal,
  );

  let response: BatchResponse;
  try {
    response = await messaging.sendEachForMulticast(message);
  } catch (error) {
    console.error("PushDispatch: sendEachForMulticast error", {
      userId,
      notificationId: notification.id,
      error,
    });
    await recordDeliveryAttempt(notification, false);
    await notification.ref.update({
      nextEligibleAt: Timestamp.fromDate(
        new Date(Date.now() + retryDelayMinutes * 60_000),
      ),
    });
    return false;
  }

  const successfulTokens: string[] = [];
  const successfulMessageIds: string[] = [];
  const invalidTokens: DeviceTokenRecord[] = [];

  response.responses.forEach((res, index) => {
    const tokenRecord = tokens[index];
    if (!tokenRecord) return;

    if (res.success) {
      successfulTokens.push(tokenRecord.token);
      if (res.messageId) successfulMessageIds.push(res.messageId);
    } else if (res.error) {
      const code = res.error.code;
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token"
      ) {
        invalidTokens.push(tokenRecord);
      }
    }
  });

  if (invalidTokens.length > 0) {
    await disableInvalidTokens(userRef, invalidTokens);
  }

  const hasSuccess = successfulTokens.length > 0;
  await recordDeliveryAttempt(
    notification,
    hasSuccess,
    successfulTokens,
    successfulMessageIds,
  );

  if (hasSuccess) {
    await userRef.set(
      {
        dailyPushCount: FieldValue.increment(1),
        dailyPushDate: todayKey,
        lastPushAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    console.log("PushDispatch: sent", {
      userId,
      notificationId: notification.id,
      tokensDelivered: successfulTokens.length,
    });
    return true;
  }

  await notification.ref.update({
    nextEligibleAt: Timestamp.fromDate(
      new Date(Date.now() + retryDelayMinutes * 60_000),
    ),
  });
  return false;
}

async function recordDeliveryAttempt(
  notification: NotificationDocument,
  success: boolean,
  tokens?: string[],
  messageIds?: string[],
): Promise<void> {
  const update: Record<string, unknown> = {
    deliveryAttempts: FieldValue.increment(1),
    lastAttemptedAt: FieldValue.serverTimestamp(),
  };

  if (success) {
    update.isSent = true;
    update.sentAt = FieldValue.serverTimestamp();
    update.nextEligibleAt = null;
    if (tokens && tokens.length > 0)
      update.deliveryTokens = FieldValue.arrayUnion(...tokens);
    if (messageIds && messageIds.length > 0)
      update.fcmMessageIds = FieldValue.arrayUnion(...messageIds);
  }

  await notification.ref.update(update);
}

async function deferNotifications(
  notifications: NotificationDocument[],
  nextAttempt: ZonedDateTime,
): Promise<void> {
  const nextTimestamp = nextAttempt.toTimestamp();
  await Promise.all(
    notifications.map((n) =>
      n.ref.update({
        nextEligibleAt: nextTimestamp,
        eligibleAt: nextTimestamp,
      }),
    ),
  );
}

async function disableInvalidTokens(
  userRef: FirebaseFirestore.DocumentReference,
  tokens: DeviceTokenRecord[],
): Promise<void> {
  await Promise.all(
    tokens.map((t) =>
      userRef
        .collection("deviceTokens")
        .doc(t.id)
        .set(
          { disabled: true, disabledAt: FieldValue.serverTimestamp() },
          { merge: true },
        ),
    ),
  );
}

async function fetchActiveTokens(
  userRef: FirebaseFirestore.DocumentReference,
  staleTokenDays: number,
): Promise<DeviceTokenRecord[]> {
  const snapshot = await userRef.collection("deviceTokens").get();
  if (snapshot.empty) return [];

  const staleThreshold = Date.now() - staleTokenDays * 24 * 60 * 60 * 1000;

  return snapshot.docs
    .map((doc) => {
      const data = doc.data();
      const token = data.token as string | undefined;
      if (!token || data.disabled === true) return null;

      const lastSeenAt = data.lastSeenAt as Timestamp | undefined;
      if (lastSeenAt && lastSeenAt.toMillis() < staleThreshold) return null;

      return {
        id: doc.id,
        token,
        platform: (data.platform as string) ?? null,
        locale: (data.locale as string) ?? null,
        lastSeenAt: lastSeenAt ?? null,
      } as DeviceTokenRecord;
    })
    .filter((t): t is DeviceTokenRecord => t !== null);
}

function resolveQuietHours(
  userData: DispatchUserDocument,
  cfg: DispatchConfig,
): QuietHoursConfig {
  const qh = userData.notificationSettings?.quietHours;
  return {
    startHour: clampHour(qh?.startHour, cfg.quietHoursStart),
    endHour: clampHour(qh?.endHour, cfg.quietHoursEnd),
  };
}

function clampHour(value: number | undefined, fallback: number): number {
  if (
    typeof value === "number" &&
    Number.isFinite(value) &&
    value >= 0 &&
    value <= 23
  ) {
    return Math.floor(value);
  }
  return fallback;
}

/** @internal exported for testing */
export function isWithinQuietHours(
  nowLocal: ZonedDateTime,
  qh: QuietHoursConfig,
): boolean {
  if (qh.startHour === qh.endHour) return false;
  if (qh.startHour < qh.endHour)
    return nowLocal.hour >= qh.startHour && nowLocal.hour < qh.endHour;
  return nowLocal.hour >= qh.startHour || nowLocal.hour < qh.endHour;
}

function nextAllowedTime(
  nowLocal: ZonedDateTime,
  qh: QuietHoursConfig,
  primaryWindowStart: number,
): ZonedDateTime {
  const windowHour = Math.max(qh.endHour, primaryWindowStart);
  const candidate = nowLocal.setTime(windowHour, 0, 0, 0);

  if (qh.startHour < qh.endHour) {
    return candidate.isBefore(nowLocal) ? candidate.plusDays(1) : candidate;
  }

  if (nowLocal.hour >= qh.startHour) return candidate.plusDays(1);
  return candidate.isBefore(nowLocal) ? candidate.plusDays(1) : candidate;
}

function nextMorning(
  nowLocal: ZonedDateTime,
  primaryWindowStart: number,
): ZonedDateTime {
  return nowLocal.plusDays(1).setTime(primaryWindowStart, 0, 0, 0);
}

/** @internal exported for testing */
export function filterEligibleNotifications(
  notifications: NotificationDocument[],
): NotificationDocument[] {
  const now = Date.now();
  return notifications.filter((n) => {
    const eligibleAt = n.data.eligibleAt;
    const nextEligibleAt = n.data.nextEligibleAt;
    if (eligibleAt && eligibleAt.toMillis() > now) return false;
    if (nextEligibleAt && nextEligibleAt.toMillis() > now) return false;
    return true;
  });
}

/** @internal exported for testing */
export function prioritizeNotifications(
  notifications: NotificationDocument[],
  nowLocal: ZonedDateTime,
): NotificationDocument[] {
  return [...notifications].sort(
    (a, b) => getPriority(a, nowLocal) - getPriority(b, nowLocal),
  );
}

function getPriority(
  notification: NotificationDocument,
  nowLocal: ZonedDateTime,
): number {
  const type = notification.data.type;

  if (type === NotificationType.EVENT && notification.data.date) {
    const eventLocal = ZonedDateTime.fromTimestamp(
      nowLocal.zone,
      notification.data.date as Timestamp,
    );
    const hours = eventLocal.diffHours(nowLocal);
    if (hours <= 6) return 0;
    if (hours <= 24) return 1;
    return 2;
  }

  if (type === NotificationType.FOLLOW_ARTIST) return 0;
  if (type === NotificationType.EVENT_TODAY) return 0;
  if (type === NotificationType.FOLLOW_PLACE) return 1;
  if (type === NotificationType.PLACE) return 3;
  if (type === NotificationType.ARTIST) return 4;
  return 5;
}

function formatDateKey(date: ZonedDateTime): string {
  return `${date.year.toString().padStart(4, "0")}-${date.month.toString().padStart(2, "0")}-${date.day.toString().padStart(2, "0")}`;
}

function buildMulticastMessage(
  notification: Notification,
  tokens: DeviceTokenRecord[],
  timezone: string,
  nowLocal: ZonedDateTime,
): MulticastMessage {
  const data: Record<string, string> = {
    notification_id: notification.id,
    notification_type: notification.type,
    payload_version: String(notification.payloadVersion ?? 1),
    timezone,
  };

  if (notification.eventId) data.event_id = notification.eventId;
  if (notification.placeId) data.place_id = notification.placeId;
  if (notification.artistId) data.artist_id = notification.artistId;
  if (notification.deeplink) data.deeplink = notification.deeplink;
  data.city = notification.city || "";
  data.state = notification.state || "";
  data.event_name = notification.eventName || "";
  data.place_name = notification.placeName || "";
  data.artist_name = notification.artistName || "";
  data.genre = notification.genre || "";
  if (
    notification.type === NotificationType.EVENT &&
    typeof notification.eventHasImage === "boolean"
  ) {
    data.event_has_image = notification.eventHasImage ? "true" : "false";
  }
  if (typeof notification.count === "number")
    data.count = String(notification.count);
  if (notification.date)
    data.event_date = String(notification.date.toMillis());

  const { titleKey, bodyKey } = getTemplateKeys(notification);
  data.title_key = titleKey;
  data.body_key = bodyKey;

  const titleArgs = buildArgs({
    eventName: notification.eventName,
    placeName: notification.placeName,
    artistName: notification.artistName,
  });
  const bodyArgs = buildArgs({
    city: notification.city,
    state: notification.state,
    genre: notification.genre,
    count: notification.count != null ? String(notification.count) : undefined,
  });

  if (titleArgs) data.title_args = titleArgs;
  if (bodyArgs) data.body_args = bodyArgs;
  if (notification.fallbackTitle)
    data.fallback_title = notification.fallbackTitle;
  if (notification.fallbackBody)
    data.fallback_body = notification.fallbackBody;

  const isHighPriority =
    notification.type === NotificationType.EVENT &&
    notification.date &&
    ZonedDateTime.fromTimestamp(
      nowLocal.zone,
      notification.date as Timestamp,
    ).diffHours(nowLocal) <= 3;

  const collapseKey =
    notification.type === NotificationType.EVENT && notification.eventId
      ? `event_${notification.eventId}`
      : `bandz_${notification.type}`;

  return {
    tokens: tokens.map((t) => t.token),
    data,
    notification: {
      title: notification.fallbackTitle || "Bandz",
      body: notification.fallbackBody || "",
    },
    android: { priority: isHighPriority ? "high" : "normal", collapseKey },
    apns: {
      headers: {
        "apns-push-type": "alert",
        "apns-priority": isHighPriority ? "10" : "5",
      },
      payload: {
        aps: {
          "mutable-content": 1,
          sound: "default",
          "content-available": 1,
          "thread-id": `bandz-${notification.type}`,
        },
      },
    },
    fcmOptions: { analyticsLabel: `notification_${notification.type}` },
  };
}

function getTemplateKeys(notification: Notification): {
  titleKey: string;
  bodyKey: string;
} {
  switch (notification.type) {
    case NotificationType.EVENT:
      return {
        titleKey: "push.event.title",
        bodyKey: "push.event.body.city",
      };
    case NotificationType.PLACE:
      return {
        titleKey: "push.place.title",
        bodyKey: "push.place.body.city",
      };
    case NotificationType.ARTIST:
      return {
        titleKey: "push.artist.title",
        bodyKey: "push.artist.body.city",
      };
    case NotificationType.FOLLOW_ARTIST:
      return {
        titleKey: "push.follow_artist.title",
        bodyKey: "push.follow_artist.body",
      };
    case NotificationType.FOLLOW_PLACE:
      return {
        titleKey: "push.follow_place.title",
        bodyKey: "push.follow_place.body",
      };
    case NotificationType.EVENT_TODAY:
      return {
        titleKey: "push.event_today.title",
        bodyKey: "push.event_today.body",
      };
    default:
      return {
        titleKey: "notifications.general.default_title",
        bodyKey: "notifications.general.default_message",
      };
  }
}

function buildArgs(
  fields: Record<string, string | null | undefined>,
): string | undefined {
  const values = Object.values(fields).filter((v): v is string => !!v);
  return values.length > 0 ? JSON.stringify(values) : undefined;
}

/**
 * Dispatches all pending notifications for a single user immediately.
 * Used by admin test trigger — intentionally bypasses quiet hours, daily limits,
 * and does NOT update dailyPushCount (to avoid polluting real user counters during tests).
 */
export async function dispatchNotificationsForUser(
  db: Firestore,
  messaging: Messaging,
  userId: string,
): Promise<{ sent: number; succeeded: number; failed: number }> {
  const userRef = db.collection(Collections.USERS).doc(userId);
  const userSnap = await userRef.get();
  if (!userSnap.exists) {
    return { sent: 0, succeeded: 0, failed: 0 };
  }

  const userData = userSnap.data() as DispatchUserDocument;
  const tokens = await fetchActiveTokens(
    userRef,
    DEFAULT_CONFIG.staleTokenDays,
  );
  if (tokens.length === 0) {
    return { sent: 0, succeeded: 0, failed: 0 };
  }

  const pendingSnapshot = await userRef
    .collection("notifications")
    .where("isSent", "==", false)
    .get();

  if (pendingSnapshot.empty) {
    return { sent: 0, succeeded: 0, failed: 0 };
  }

  const timezone =
    userData.timezone?.trim() || DEFAULT_CONFIG.fallbackTimezone;
  const nowLocal = ZonedDateTime.now(timezone);

  let succeeded = 0;
  let failed = 0;

  for (const doc of pendingSnapshot.docs) {
    const data = doc.data() as Notification;
    const notification: NotificationDocument = {
      id: data.id || doc.id,
      ref: doc.ref,
      data: { ...data, id: data.id || doc.id },
      userId,
    };

    const message = buildMulticastMessage(
      notification.data,
      tokens,
      timezone,
      nowLocal,
    );

    try {
      const response = await messaging.sendEachForMulticast(message);

      const successfulTokens: string[] = [];
      const successfulMessageIds: string[] = [];
      const invalidTokens: DeviceTokenRecord[] = [];

      response.responses.forEach((res, index) => {
        const tokenRecord = tokens[index];
        if (!tokenRecord) return;

        if (res.success) {
          successfulTokens.push(tokenRecord.token);
          if (res.messageId) successfulMessageIds.push(res.messageId);
        } else if (res.error) {
          const code = res.error.code;
          if (
            code === "messaging/registration-token-not-registered" ||
            code === "messaging/invalid-registration-token"
          ) {
            invalidTokens.push(tokenRecord);
          }
        }
      });

      if (invalidTokens.length > 0) {
        await disableInvalidTokens(userRef, invalidTokens);
      }

      const hasSuccess = successfulTokens.length > 0;
      await recordDeliveryAttempt(
        notification,
        hasSuccess,
        successfulTokens,
        successfulMessageIds,
      );

      if (hasSuccess) {
        succeeded++;
      } else {
        failed++;
      }
    } catch (error) {
      console.error("dispatchNotificationsForUser: send error", {
        userId,
        notificationId: notification.id,
        error,
      });
      failed++;
    }
  }

  console.log("dispatchNotificationsForUser: completed", {
    userId,
    total: pendingSnapshot.size,
    succeeded,
    failed,
    tokensUsed: tokens.length,
  });

  return { sent: pendingSnapshot.size, succeeded, failed };
}

/**
 * Dispatches a single specific notification for a user.
 * Used by follow/event-today triggers to avoid re-dispatching all pending notifications.
 * Respects notificationsEnabled, quiet hours, and updates dailyPushCount.
 */
export async function dispatchSingleNotification(
  db: Firestore,
  messaging: Messaging,
  userId: string,
  notificationId: string,
): Promise<{ succeeded: boolean; deferred: boolean }> {
  const userRef = db.collection(Collections.USERS).doc(userId);
  const userSnap = await userRef.get();
  if (!userSnap.exists) return { succeeded: false, deferred: false };

  const userData = userSnap.data() as DispatchUserDocument;

  // Check notificationsEnabled
  if (userData.notificationsEnabled === false) {
    return { succeeded: false, deferred: false };
  }

  const tokens = await fetchActiveTokens(userRef, DEFAULT_CONFIG.staleTokenDays);
  if (tokens.length === 0) return { succeeded: false, deferred: false };

  const notifDoc = await userRef
    .collection("notifications")
    .doc(notificationId)
    .get();

  if (!notifDoc.exists) return { succeeded: false, deferred: false };

  const data = notifDoc.data() as Notification;
  if (data.isSent) return { succeeded: false, deferred: false };

  const timezone = userData.timezone?.trim() || DEFAULT_CONFIG.fallbackTimezone;
  const nowLocal = ZonedDateTime.now(timezone);

  // Check quiet hours -- defer if within quiet hours
  const quietHours = resolveQuietHours(userData, DEFAULT_CONFIG);
  if (isWithinQuietHours(nowLocal, quietHours)) {
    const deferUntil = nextAllowedTime(nowLocal, quietHours, DEFAULT_CONFIG.primaryWindowStart);
    await notifDoc.ref.update({
      eligibleAt: deferUntil.toTimestamp(),
      nextEligibleAt: deferUntil.toTimestamp(),
    });
    console.log("dispatchSingleNotification: deferred (quiet hours)", {
      userId, notificationId, deferUntil: deferUntil.toString(),
    });
    return { succeeded: false, deferred: true };
  }

  // Check daily limit
  const todayKey = formatDateKey(nowLocal);
  const existingCount =
    userData.dailyPushDate === todayKey ? (userData.dailyPushCount ?? 0) : 0;
  if (existingCount >= DEFAULT_CONFIG.dailyUserLimit) {
    const deferUntil = nextMorning(nowLocal, DEFAULT_CONFIG.primaryWindowStart);
    await notifDoc.ref.update({
      eligibleAt: deferUntil.toTimestamp(),
      nextEligibleAt: deferUntil.toTimestamp(),
    });
    console.log("dispatchSingleNotification: deferred (daily limit)", {
      userId, notificationId, existingCount, limit: DEFAULT_CONFIG.dailyUserLimit,
    });
    return { succeeded: false, deferred: true };
  }

  const notification: NotificationDocument = {
    id: data.id || notifDoc.id,
    ref: notifDoc.ref,
    data: { ...data, id: data.id || notifDoc.id },
    userId,
  };

  const message = buildMulticastMessage(notification.data, tokens, timezone, nowLocal);

  try {
    const response = await messaging.sendEachForMulticast(message);

    const successfulTokens: string[] = [];
    const successfulMessageIds: string[] = [];
    const invalidTokens: DeviceTokenRecord[] = [];

    response.responses.forEach((res, index) => {
      const tokenRecord = tokens[index];
      if (!tokenRecord) return;
      if (res.success) {
        successfulTokens.push(tokenRecord.token);
        if (res.messageId) successfulMessageIds.push(res.messageId);
      } else if (res.error) {
        const code = res.error.code;
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          invalidTokens.push(tokenRecord);
        }
      }
    });

    if (invalidTokens.length > 0) {
      await disableInvalidTokens(userRef, invalidTokens);
    }

    const hasSuccess = successfulTokens.length > 0;
    await recordDeliveryAttempt(notification, hasSuccess, successfulTokens, successfulMessageIds);

    // Update daily push count
    if (hasSuccess) {
      const todayKey = formatDateKey(nowLocal);
      await userRef.set(
        {
          dailyPushCount: FieldValue.increment(1),
          dailyPushDate: todayKey,
          lastPushAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }

    return { succeeded: hasSuccess, deferred: false };
  } catch (error) {
    console.error("dispatchSingleNotification: error", { userId, notificationId, error });
    await recordDeliveryAttempt(notification, false);
    await notifDoc.ref.update({
      nextEligibleAt: Timestamp.fromDate(
        new Date(Date.now() + DEFAULT_CONFIG.retryDelayMinutes * 60_000),
      ),
    });
    return { succeeded: false, deferred: false };
  }
}
