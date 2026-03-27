/** Firestore collection names — single source of truth */
export const Collections = {
  USERS: "BR_users",
  EVENTS: "BR_events",
  PLACES: "BR_places",
  ARTISTS: "BR_artists",
  STYLE_GROUPS: "BR_bandz_style_groups",
  GENRE_MATCH_CONFIG: "BR_genre_match_config",
  PARAMETERS: "BR_bandz_parameters",
  INSTAGRAM_PROFILES: "BR_instagram_profile_businesses",
  ERRORS: "errors",
  SECRETS: "secrets",

  // Admin collections
  ADMIN_USERS: "BR_admin_users",
  CLIENTS: "BR_clients",
  AUDIT_LOG: "BR_audit_log",
  DELETION_LOG: "BR_deletion_log",
  WAITLIST_SIGNUPS: "BR_waitlist_signups",
  FEEDBACKS: "BR_feedbacks",

  // Banner collections
  HOME_BANNERS: "BR_home_banners",
  BANNER_HISTORY: "BR_banner_history",
  BANNER_CONFIG: "BR_banner_config",

  // Subcollections (relative to parent doc)
  SUB_RAW_MUSIC_DATA: "rawMusicData",
  SUB_PROCESSED_GENRES: "processedGenres",
  SUB_NOTIFICATIONS: "notifications",
  SUB_DEVICE_TOKENS: "deviceTokens",
  SUB_INSTAGRAM_POSTS: "BR_instagram_posts",
} as const;

export type CollectionName = (typeof Collections)[keyof typeof Collections];
