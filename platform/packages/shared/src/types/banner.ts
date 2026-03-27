import type { FirestoreTimestamp } from "./common.js";

export type BannerSlotType = "artist" | "event" | "place";

/** Document stored at BR_home_banners/{slotType} */
export interface HomeBanner {
  entityId: string;
  entityType: BannerSlotType;
  entityName: string;
  subtitle: string;
  imageUrl: string;
  sortOrder: number;
  artistId?: string; // event banners only: for artist image fallback

  score: number;
  selectedAt: FirestoreTimestamp;
  selectedBy: "algorithm" | "admin";

  pinnedEntityId?: string;
  pinnedBy?: string;
  pinnedAt?: FirestoreTimestamp;
  pinnedUntil?: FirestoreTimestamp; // absent = indefinite pin
}

/** Append-only ledger entry in BR_banner_history */
export interface BannerHistoryEntry {
  slotType: BannerSlotType;
  entityId: string;
  entityName: string;
  score: number;
  selectedAt: FirestoreTimestamp;
  selectedBy: "algorithm" | "admin";
}

export interface BannerWeights {
  profileCompleteness: number;
  recentEventCount: number;
  hasSpotify: number;
  instagramFollowers: number;
  googleRating: number;
  googleRatingsCount: number;
  hasBannerImage: number;
  isUpcoming: number;
}

export interface BannerCadence {
  artist: number;
  event: number;
  place: number;
}

/** Singleton config document at BR_banner_config/BR */
export interface BannerConfig {
  cadence: BannerCadence;
  recentEventWindowDays: number;
  weights: BannerWeights;
  updatedAt?: FirestoreTimestamp;
  updatedBy?: string;
}

export interface BannerCandidateScore {
  entityId: string;
  entityName: string;
  imageUrl: string;
  subtitle: string;
  score: number;
  artistId?: string; // event candidates only
}
