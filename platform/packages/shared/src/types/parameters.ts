import { FirestoreTimestamp } from "./common.js";

export interface BandzParameters {
  genres: string[];
  placeTypes: string[];
  lastDateSyncInstagramPosts: FirestoreTimestamp;
}
