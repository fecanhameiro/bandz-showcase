import type { Artist } from "../types/artist.js";
import type { Place } from "../types/place.js";
import type { Event } from "../types/event.js";
import type { User, DeviceTokenRecord } from "../types/user.js";
import type { Notification } from "../types/notification.js";
import type {
  StyleGroup,
  GenreMatchConfig,
  RawMusicData,
  ProcessedStyleGroupData,
} from "../types/music.js";
import type { BandzParameters } from "../types/parameters.js";
import type { InstagramUser, InstagramMedia } from "../types/instagram.js";
import type { AdminUser, Client, AuditLogEntry } from "../types/admin.js";
import type {
  HomeBanner,
  BannerHistoryEntry,
  BannerConfig,
} from "../types/banner.js";
import { Collections } from "../constants/collections.js";

/**
 * Maps Firestore collection names to their document types.
 * Used by typedCollection() to provide type-safe reads/writes.
 */
export interface CollectionMap {
  [Collections.USERS]: User;
  [Collections.EVENTS]: Event;
  [Collections.PLACES]: Place;
  [Collections.ARTISTS]: Artist;
  [Collections.STYLE_GROUPS]: StyleGroup;
  [Collections.GENRE_MATCH_CONFIG]: GenreMatchConfig;
  [Collections.PARAMETERS]: BandzParameters;
  [Collections.INSTAGRAM_PROFILES]: InstagramUser;
  [Collections.ADMIN_USERS]: AdminUser;
  [Collections.CLIENTS]: Client;
  [Collections.AUDIT_LOG]: AuditLogEntry;
  [Collections.HOME_BANNERS]: HomeBanner;
  [Collections.BANNER_HISTORY]: BannerHistoryEntry;
  [Collections.BANNER_CONFIG]: BannerConfig;
}

/**
 * Maps subcollection names to their document types.
 */
export interface SubcollectionMap {
  [Collections.SUB_NOTIFICATIONS]: Notification;
  [Collections.SUB_RAW_MUSIC_DATA]: RawMusicData;
  [Collections.SUB_PROCESSED_GENRES]: ProcessedStyleGroupData;
  [Collections.SUB_DEVICE_TOKENS]: DeviceTokenRecord;
  [Collections.SUB_INSTAGRAM_POSTS]: InstagramMedia;
}
