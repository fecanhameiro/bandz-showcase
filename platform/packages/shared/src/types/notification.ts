import { FirestoreTimestamp } from "./common.js";

export enum NotificationType {
  EVENT = "event",
  PLACE = "place",
  ARTIST = "artist",
  GENERAL = "general",
  FOLLOW_ARTIST = "follow_artist",
  FOLLOW_PLACE = "follow_place",
  EVENT_TODAY = "event_today",
}

export interface Notification {
  id: string;
  userId?: string;
  type: NotificationType;
  date: FirestoreTimestamp;
  genre: string | null;
  city: string | null;
  state: string | null;
  eventId: string | null;
  eventName: string | null;
  placeId: string | null;
  placeName: string | null;
  artistId: string | null;
  artistName: string | null;
  count: number;
  isRead: boolean;
  createdAt: FirestoreTimestamp;
  readAt: FirestoreTimestamp | null;
  isSent: boolean;
  payloadVersion?: number;
  eligibleAt?: FirestoreTimestamp | null;
  nextEligibleAt?: FirestoreTimestamp | null;
  sentAt?: FirestoreTimestamp | null;
  deliveryAttempts?: number;
  deliveryTokens?: string[];
  fcmMessageIds?: string[];
  fallbackTitle?: string | null;
  fallbackBody?: string | null;
  deeplink?: string | null;
  lastAttemptedAt?: FirestoreTimestamp | null;
  notificationCategory?: string | null;
  eventHasImage?: boolean | null;
}
