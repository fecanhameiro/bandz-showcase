/**
 * Generic Firestore types — compatible with both firebase-admin and firebase client SDK.
 * Both SDKs satisfy these shapes.
 */

export interface FirestoreTimestamp {
  seconds: number;
  nanoseconds: number;
  toDate(): Date;
  toMillis(): number;
}

export interface GeoPoint {
  latitude: number;
  longitude: number;
}

/** Audit fields present on most Firestore documents */
export interface AuditFields {
  createdDate?: FirestoreTimestamp | Date;
  lastUpdate?: FirestoreTimestamp | Date;
  userCreatedUid?: string;
  userCreatedName?: string;
  userCreatedEmail?: string;
  userUpdatedUid?: string;
  userUpdatedName?: string;
  userUpdatedEmail?: string;
}
