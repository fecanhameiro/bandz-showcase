import { FirestoreTimestamp } from "./common.js";

export interface User {
  uid: string;
  email: string;
  displayName: string;
  spotifyId?: string;
  spotifyUri?: string;
  profileImageURL?: string;
  lastAuthMethod?: string;
  authMethods?: string[];
  isOnboardingCompleted?: boolean;
  notificationsEnabled?: boolean;
  timezone?: string;
  userLocation?: {
    city?: string;
    state?: string;
  };
  preferences?: {
    favoriteGenres?: FavoriteGenre[];
    favoritePlaces?: FavoritePlace[];
    favoriteArtists?: string[];
    favoriteEvents?: string[];
  };
  notificationSettings?: {
    preferredSummaryHour?: number;
    preferredReminderHour?: number;
    quietHours?: QuietHoursSetting;
  };
  dailyPushCount?: number;
  dailyPushDate?: string;
  pendingDeletion?: boolean;
  deletionRequestedAt?: FirestoreTimestamp;
  createdAt?: FirestoreTimestamp;
  updatedAt?: FirestoreTimestamp;
}

export interface FavoriteGenre {
  id?: string;
  name?: string;
}

export interface FavoritePlace {
  id?: string;
  name?: string;
  city?: string;
  state?: string;
  active?: boolean;
}

export interface QuietHoursSetting {
  startHour?: number;
  endHour?: number;
}

export interface DeviceTokenRecord {
  id: string;
  token: string;
  platform?: string | null;
  locale?: string | null;
  lastSeenAt?: FirestoreTimestamp | null;
}
