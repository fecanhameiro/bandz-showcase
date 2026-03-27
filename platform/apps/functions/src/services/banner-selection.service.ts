import type { Firestore } from "firebase-admin/firestore";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { Collections } from "@bandz/shared/constants";
import type {
  BannerSlotType,
  BannerConfig,
  BannerWeights,
  BannerCandidateScore,
  HomeBanner,
} from "@bandz/shared/types";
import type { Artist } from "@bandz/shared/types";
import type { Place } from "@bandz/shared/types";
import type { Event } from "@bandz/shared/types";
import { getFirebaseStorage } from "../config/admin.js";

// ─── Default config (used when BR_banner_config/BR doesn't exist) ─

const DEFAULT_BANNER_CONFIG: BannerConfig = {
  cadence: { artist: 3, event: 1, place: 3 },
  recentEventWindowDays: 30,
  weights: {
    profileCompleteness: 20,
    recentEventCount: 25,
    hasSpotify: 10,
    instagramFollowers: 15,
    googleRating: 20,
    googleRatingsCount: 10,
    hasBannerImage: 30,
    isUpcoming: 25,
  },
};

const SORT_ORDER: Record<BannerSlotType, number> = {
  artist: 0,
  event: 10,
  place: 20,
};

const MAX_HISTORY_FALLBACK = 500;

const BUCKET_IMAGE_PATHS: Record<
  BannerSlotType,
  { prefix: string; suffix: string }
> = {
  artist: {
    prefix: "app-images/BR/artist-images/",
    suffix: "_profile_400x400",
  },
  place: { prefix: "app-images/BR/place-images/", suffix: "_cover_400x400" },
  event: {
    prefix: "app-images/BR/artist-images/",
    suffix: "_profile_400x400",
  }, // events use artist image
};

// ─── Image validation ─────────────────────────────────────────────

async function hasImageInBucket(
  entityId: string,
  slotType: BannerSlotType,
): Promise<boolean> {
  const { prefix, suffix } = BUCKET_IMAGE_PATHS[slotType];
  const filePath = `${prefix}${entityId}${suffix}`;
  try {
    const bucket = getFirebaseStorage().bucket();
    const [exists] = await bucket.file(filePath).exists();
    return exists;
  } catch {
    return false;
  }
}

// ─── Config fetch ─────────────────────────────────────────────────

export async function fetchBannerConfig(
  db: Firestore,
): Promise<BannerConfig> {
  const doc = await db
    .collection(Collections.BANNER_CONFIG)
    .doc("BR")
    .get();

  if (!doc.exists) {
    console.log("BR_banner_config/BR not found, using defaults");
    return DEFAULT_BANNER_CONFIG;
  }

  return doc.data() as BannerConfig;
}

// ─── Eligibility fetchers ─────────────────────────────────────────

interface ArtistCandidate extends Artist {
  recentEventCount: number;
}

interface PlaceCandidate extends Place {
  recentEventCount: number;
  instagramFollowers: number;
}

export async function fetchEligibleArtists(
  db: Firestore,
  windowDays: number,
): Promise<ArtistCandidate[]> {
  // TODO: re-enable active filter when production data has `active` field set
  const artistsSnap = await db
    .collection(Collections.ARTISTS)
    // .where("active", "==", true)
    .get();

  if (artistsSnap.empty) return [];

  const now = new Date();
  const windowStart = new Date(now);
  windowStart.setDate(windowStart.getDate() - windowDays);
  const windowEnd = new Date(now);
  windowEnd.setDate(windowEnd.getDate() + windowDays);

  // TODO: re-enable active filter when production data has `active` field set
  const eventsSnap = await db
    .collection(Collections.EVENTS)
    // .where("active", "==", true)
    .where("eventDate", ">=", Timestamp.fromDate(windowStart))
    .where("eventDate", "<=", Timestamp.fromDate(windowEnd))
    .get();

  const eventCountByArtist = new Map<string, number>();
  for (const doc of eventsSnap.docs) {
    const event = doc.data() as Event;
    if (event.artistId) {
      eventCountByArtist.set(
        event.artistId,
        (eventCountByArtist.get(event.artistId) ?? 0) + 1,
      );
    }
  }

  const candidates: ArtistCandidate[] = [];
  for (const doc of artistsSnap.docs) {
    const artist = doc.data() as Artist;
    const recentEventCount = eventCountByArtist.get(artist.id) ?? 0;

    if (recentEventCount >= 1) {
      candidates.push({ ...artist, recentEventCount });
    }
  }

  // Fallback: if no artist has recent events, include all artists
  if (candidates.length === 0) {
    console.log("No artists with recent events, falling back to all artists");
    for (const doc of artistsSnap.docs) {
      const artist = doc.data() as Artist;
      candidates.push({ ...artist, recentEventCount: 0 });
    }
  }

  return candidates;
}

export async function fetchEligiblePlaces(
  db: Firestore,
  windowDays: number,
): Promise<PlaceCandidate[]> {
  // TODO: re-enable active filter when production data has `active` field set
  const placesSnap = await db
    .collection(Collections.PLACES)
    // .where("active", "==", true)
    .get();

  if (placesSnap.empty) return [];

  const now = new Date();
  const windowStart = new Date(now);
  windowStart.setDate(windowStart.getDate() - windowDays);
  const windowEnd = new Date(now);
  windowEnd.setDate(windowEnd.getDate() + windowDays);

  // TODO: re-enable active filter when production data has `active` field set
  const eventsSnap = await db
    .collection(Collections.EVENTS)
    // .where("active", "==", true)
    .where("eventDate", ">=", Timestamp.fromDate(windowStart))
    .where("eventDate", "<=", Timestamp.fromDate(windowEnd))
    .get();

  const eventCountByPlace = new Map<string, number>();
  for (const doc of eventsSnap.docs) {
    const event = doc.data() as Event;
    if (event.placeId) {
      eventCountByPlace.set(
        event.placeId,
        (eventCountByPlace.get(event.placeId) ?? 0) + 1,
      );
    }
  }

  // Fetch Instagram followers for places
  const igSnap = await db
    .collection(Collections.INSTAGRAM_PROFILES)
    .get();

  const igFollowersByPlace = new Map<string, number>();
  for (const doc of igSnap.docs) {
    const data = doc.data();
    if (data.placeId && data.followers_count) {
      igFollowersByPlace.set(data.placeId, data.followers_count);
    }
  }

  const candidates: PlaceCandidate[] = [];
  for (const doc of placesSnap.docs) {
    const place = doc.data() as Place;
    const recentEventCount = eventCountByPlace.get(place.id) ?? 0;

    if (recentEventCount >= 1) {
      candidates.push({
        ...place,
        recentEventCount,
        instagramFollowers: igFollowersByPlace.get(place.id) ?? 0,
      });
    }
  }

  // Fallback: if no place has recent events, include all places
  if (candidates.length === 0) {
    console.log("No places with recent events, falling back to all places");
    for (const doc of placesSnap.docs) {
      const place = doc.data() as Place;
      candidates.push({
        ...place,
        recentEventCount: 0,
        instagramFollowers: igFollowersByPlace.get(place.id) ?? 0,
      });
    }
  }

  return candidates;
}

interface EventCandidate extends Event {
  _eventCandidate: true;
}

export async function fetchEligibleEvents(
  db: Firestore,
): Promise<EventCandidate[]> {
  const now = Timestamp.fromDate(new Date());

  // TODO: re-enable active filter when production data has `active` field set
  let eventsSnap = await db
    .collection(Collections.EVENTS)
    // .where("active", "==", true)
    .where("eventDate", ">=", now)
    .get();

  // Fallback: if no future events, grab the 10 most recent past events
  if (eventsSnap.empty) {
    console.log("No future events, falling back to most recent past events");
    eventsSnap = await db
      .collection(Collections.EVENTS)
      .orderBy("eventDate", "desc")
      .limit(10)
      .get();
  }

  if (eventsSnap.empty) return [];

  const candidates: EventCandidate[] = [];
  for (const doc of eventsSnap.docs) {
    const event = doc.data() as Event;
    candidates.push({ ...event, _eventCandidate: true });
  }

  return candidates;
}

// ─── Scoring (pure functions) ─────────────────────────────────────

export function scoreArtists(
  candidates: ArtistCandidate[],
  weights: BannerWeights,
): BannerCandidateScore[] {
  return candidates
    .map((artist) => {
      const fields = [
        artist.style,
        artist.genres?.length ? artist.genres : null,
        artist.description,
        artist.instagramId,
        artist.spotifyId,
        artist.website,
      ];
      const profileCompleteness =
        fields.filter((f) => f != null && f !== "").length / fields.length;

      const recentEventScore = Math.min(artist.recentEventCount, 5) / 5;

      const score =
        weights.profileCompleteness * profileCompleteness +
        weights.recentEventCount * recentEventScore +
        weights.hasSpotify * (artist.spotifyId ? 1 : 0);

      const genres = artist.genres?.length
        ? artist.genres.join(" . ")
        : artist.style || artist.name;

      return {
        entityId: artist.id,
        entityName: artist.name,
        imageUrl: "",
        subtitle: genres,
        score,
      };
    })
    .sort((a, b) => b.score - a.score);
}

export function scorePlaces(
  candidates: PlaceCandidate[],
  weights: BannerWeights,
): BannerCandidateScore[] {
  return candidates
    .map((place) => {
      const fields = [
        place.description,
        place.genres?.length ? place.genres : null,
        place.googlePlaceId,
        place.instagramId,
        place.website,
      ];
      const profileCompleteness =
        fields.filter((f) => f != null && f !== "").length / fields.length;

      const instagramScore = place.instagramFollowers
        ? Math.log10(place.instagramFollowers + 1) / Math.log10(100001)
        : 0;

      const googleRatingScore = (place.googlePlaceRating ?? 0) / 5;

      const googleCountScore = place.googlePlaceUserRatingsTotal
        ? Math.log10(place.googlePlaceUserRatingsTotal + 1) /
          Math.log10(10001)
        : 0;

      const recentEventScore = Math.min(place.recentEventCount, 5) / 5;

      const score =
        weights.profileCompleteness * profileCompleteness +
        weights.recentEventCount * recentEventScore +
        weights.instagramFollowers * instagramScore +
        weights.googleRating * googleRatingScore +
        weights.googleRatingsCount * googleCountScore;

      const genres = place.genres?.length
        ? place.genres.join(" . ")
        : place.style || place.name;

      return {
        entityId: place.id,
        entityName: place.name,
        imageUrl: "",
        subtitle: genres,
        score,
      };
    })
    .sort((a, b) => b.score - a.score);
}

export function scoreEvents(
  candidates: EventCandidate[],
  weights: BannerWeights,
): BannerCandidateScore[] {
  const now = new Date();
  const weekFromNow = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

  return candidates
    .map((event) => {
      const fields = [
        event.eventName,
        event.description,
        event.genres?.length ? event.genres : null,
        event.artistName,
      ];
      const profileCompleteness =
        fields.filter((f) => f != null && f !== "").length / fields.length;

      const eventDate = event.eventDate
        ? "toDate" in (event.eventDate as object)
          ? (event.eventDate as { toDate(): Date }).toDate()
          : new Date(event.eventDate as unknown as string)
        : null;

      const isUpcoming =
        eventDate && eventDate > now && eventDate <= weekFromNow ? 1 : 0;

      const score =
        weights.isUpcoming * isUpcoming +
        weights.profileCompleteness * profileCompleteness;

      const imageUrl = "";

      const genres = event.genres?.length
        ? event.genres.join(" . ")
        : event.style || event.eventName;

      return {
        entityId: event.id,
        entityName: event.eventName,
        imageUrl,
        subtitle: genres,
        score,
        artistId: event.artistId || undefined,
      };
    })
    .sort((a, b) => b.score - a.score);
}

// ─── Round-robin fairness (pure function) ─────────────────────────

export function applyRoundRobin(
  scored: BannerCandidateScore[],
  featuredIds: Set<string>,
): BannerCandidateScore | null {
  if (scored.length === 0) return null;

  // Filter to entities not yet featured in this cycle
  const freshPool = scored.filter((c) => !featuredIds.has(c.entityId));

  // If all have been featured (full cycle), reset and use full pool
  if (freshPool.length === 0) {
    return scored[0]; // Top scorer from full pool
  }

  return freshPool[0]; // Top scorer from fresh pool
}

// ─── History fetch ────────────────────────────────────────────────

export async function fetchBannerHistory(
  db: Firestore,
  slotType: BannerSlotType,
  poolSize: number,
): Promise<Set<string>> {
  // Limit to pool size so the round-robin window spans exactly one cycle.
  // When all N entities have been featured in the last N selections,
  // the fresh pool will be empty and the cycle resets.
  const limit = poolSize > 0 ? poolSize : MAX_HISTORY_FALLBACK;

  const historySnap = await db
    .collection(Collections.BANNER_HISTORY)
    .where("slotType", "==", slotType)
    .orderBy("selectedAt", "desc")
    .limit(limit)
    .get();

  const featuredIds = new Set<string>();
  for (const doc of historySnap.docs) {
    featuredIds.add(doc.data().entityId as string);
  }
  return featuredIds;
}

// ─── Winner selection with image validation ──────────────────────

async function selectWinnerWithImageValidation(
  scored: BannerCandidateScore[],
  featuredIds: Set<string>,
  slotType: BannerSlotType,
  maxAttempts = 3,
): Promise<BannerCandidateScore | null> {
  if (scored.length === 0) return null;

  const freshPool = scored.filter((c) => !featuredIds.has(c.entityId));
  const pool = freshPool.length > 0 ? freshPool : scored;

  let bucketChecks = 0;
  for (let i = 0; i < pool.length && bucketChecks < maxAttempts; i++) {
    const candidate = pool[i];

    // For events with their own bannerImageUrl, trust it (no bucket check needed)
    if (slotType === "event" && candidate.imageUrl) {
      return candidate;
    }

    // For events without bannerImageUrl, check the artist's image; for artist/place, check by entityId
    const checkId =
      slotType === "event" ? candidate.artistId : candidate.entityId;

    if (!checkId) {
      console.warn(
        `Banner [${slotType}] "${candidate.entityName}" has no ID to check image, skipping`,
      );
      continue;
    }

    bucketChecks++;
    const exists = await hasImageInBucket(checkId, slotType);
    if (exists) return candidate;

    console.warn(
      `Banner [${slotType}] "${candidate.entityName}" (${checkId}) has no image in bucket, trying next`,
    );
  }

  // All attempts failed -- use first as fallback (better than empty slot)
  console.warn(
    `Banner [${slotType}] no candidate with valid image found after ${bucketChecks} bucket checks, using top scorer as fallback`,
  );
  return pool[0];
}

// ─── Write selection ──────────────────────────────────────────────

async function writeBannerSelection(
  db: Firestore,
  slotType: BannerSlotType,
  winner: BannerCandidateScore,
): Promise<void> {
  const now = Timestamp.now();

  const bannerDoc: HomeBanner = {
    entityId: winner.entityId,
    entityType: slotType,
    entityName: winner.entityName,
    subtitle: winner.subtitle,
    imageUrl: winner.imageUrl,
    sortOrder: SORT_ORDER[slotType],
    score: winner.score,
    selectedAt: now,
    selectedBy: "algorithm",
    ...(winner.artistId ? { artistId: winner.artistId } : {}),
  };

  const historyEntry = {
    slotType,
    entityId: winner.entityId,
    entityName: winner.entityName,
    score: winner.score,
    selectedAt: now,
    selectedBy: "algorithm",
  };

  const batch = db.batch();
  batch.set(
    db.collection(Collections.HOME_BANNERS).doc(slotType),
    bannerDoc,
  );
  batch.create(
    db.collection(Collections.BANNER_HISTORY).doc(),
    historyEntry,
  );
  await batch.commit();

  console.log(
    `Banner [${slotType}] selected: "${winner.entityName}" (score: ${winner.score.toFixed(1)})`,
  );
}

// ─── Main orchestrator ────────────────────────────────────────────

async function processSlot(
  db: Firestore,
  slotType: BannerSlotType,
  config: BannerConfig,
): Promise<void> {
  // 1. Check current banner for cadence and pin
  const currentDoc = await db
    .collection(Collections.HOME_BANNERS)
    .doc(slotType)
    .get();

  let pinJustExpired = false;

  if (currentDoc.exists) {
    const current = currentDoc.data() as HomeBanner;

    // Check admin pin
    if (current.pinnedEntityId) {
      if (
        !current.pinnedUntil ||
        current.pinnedUntil.toDate() > new Date()
      ) {
        console.log(
          `Banner [${slotType}] is pinned to "${current.pinnedEntityId}", skipping`,
        );
        return;
      }

      // Pin expired, clear it and force algorithm to run immediately
      console.log(`Banner [${slotType}] pin expired, clearing`);
      await db
        .collection(Collections.HOME_BANNERS)
        .doc(slotType)
        .update({
          pinnedEntityId: FieldValue.delete(),
          pinnedBy: FieldValue.delete(),
          pinnedAt: FieldValue.delete(),
          pinnedUntil: FieldValue.delete(),
        });
      pinJustExpired = true;
    }

    // Check cadence (skip if pin just expired -- force immediate rotation)
    if (!pinJustExpired && current.selectedAt) {
      const cadenceDays = config.cadence[slotType];
      const selectedDate = current.selectedAt.toDate();
      const nextSelectionDate = new Date(selectedDate);
      nextSelectionDate.setDate(nextSelectionDate.getDate() + cadenceDays);

      if (new Date() < nextSelectionDate) {
        console.log(
          `Banner [${slotType}] cadence not elapsed (next: ${nextSelectionDate.toISOString()})`,
        );
        return;
      }
    }
  }

  // 2. Fetch eligible candidates and score them
  let scored: BannerCandidateScore[];

  switch (slotType) {
    case "artist": {
      const candidates = await fetchEligibleArtists(
        db,
        config.recentEventWindowDays,
      );
      scored = scoreArtists(candidates, config.weights);
      break;
    }
    case "place": {
      const candidates = await fetchEligiblePlaces(
        db,
        config.recentEventWindowDays,
      );
      scored = scorePlaces(candidates, config.weights);
      break;
    }
    case "event": {
      const candidates = await fetchEligibleEvents(db);
      scored = scoreEvents(candidates, config.weights);
      break;
    }
  }

  if (scored.length === 0) {
    console.log(`Banner [${slotType}] no eligible candidates found`);
    return;
  }

  // 3. Apply round-robin fairness + validate winner has image in bucket
  const featuredIds = await fetchBannerHistory(db, slotType, scored.length);
  const winner = await selectWinnerWithImageValidation(
    scored,
    featuredIds,
    slotType,
  );

  if (!winner) {
    console.log(`Banner [${slotType}] round-robin returned no winner`);
    return;
  }

  // 4. Write selection
  await writeBannerSelection(db, slotType, winner);
}

export async function refreshHomeBanners(db: Firestore): Promise<void> {
  const config = await fetchBannerConfig(db);
  const slotTypes: BannerSlotType[] = ["artist", "event", "place"];

  for (const slotType of slotTypes) {
    try {
      await processSlot(db, slotType, config);
    } catch (error) {
      console.error(`Error processing banner [${slotType}]:`, error);
    }
  }
}

// ─── Seed default config ──────────────────────────────────────────

export async function seedBannerConfig(db: Firestore): Promise<void> {
  const doc = await db
    .collection(Collections.BANNER_CONFIG)
    .doc("BR")
    .get();

  if (doc.exists) {
    console.log("BR_banner_config/BR already exists, skipping seed");
    return;
  }

  await db
    .collection(Collections.BANNER_CONFIG)
    .doc("BR")
    .set({
      ...DEFAULT_BANNER_CONFIG,
      updatedAt: Timestamp.now(),
      updatedBy: "system-seed",
    });

  console.log("BR_banner_config/BR seeded with defaults");
}

// ─── Pin/unpin helpers ────────────────────────────────────────────

export async function pinBanner(
  db: Firestore,
  slotType: BannerSlotType,
  entityId: string,
  adminUid: string,
  pinnedUntil: Date | null,
): Promise<void> {
  // Look up the entity to populate display fields
  let entityName = "";
  let imageUrl = "";
  let subtitle = "";
  let eventArtistId: string | undefined;

  switch (slotType) {
    case "artist": {
      const doc = await db
        .collection(Collections.ARTISTS)
        .doc(entityId)
        .get();
      if (!doc.exists) throw new Error(`Artist ${entityId} not found`);
      const artist = doc.data() as Artist;
      entityName = artist.name;
      imageUrl = "";
      subtitle = artist.genres?.length
        ? artist.genres.join(" . ")
        : artist.style || artist.name;
      break;
    }
    case "place": {
      const doc = await db
        .collection(Collections.PLACES)
        .doc(entityId)
        .get();
      if (!doc.exists) throw new Error(`Place ${entityId} not found`);
      const place = doc.data() as Place;
      entityName = place.name;
      imageUrl = "";
      subtitle = place.genres?.length
        ? place.genres.join(" . ")
        : place.style || place.name;
      break;
    }
    case "event": {
      const doc = await db
        .collection(Collections.EVENTS)
        .doc(entityId)
        .get();
      if (!doc.exists) throw new Error(`Event ${entityId} not found`);
      const event = doc.data() as Event;
      entityName = event.eventName;
      imageUrl = "";
      eventArtistId = event.artistId || undefined;
      subtitle = event.genres?.length
        ? event.genres.join(" . ")
        : event.style || event.eventName;
      break;
    }
  }

  // Warn if pinned entity has no image in bucket (non-blocking)
  const imageCheckId =
    slotType === "event" ? eventArtistId : entityId;
  if (imageCheckId) {
    const hasImage = await hasImageInBucket(imageCheckId, slotType);
    if (!hasImage) {
      console.warn(
        `Banner [${slotType}] pinned entity "${entityName}" (${imageCheckId}) has no image in bucket`,
      );
    }
  }

  const now = Timestamp.now();

  const bannerDoc: HomeBanner = {
    entityId,
    entityType: slotType,
    entityName,
    subtitle,
    imageUrl,
    sortOrder: SORT_ORDER[slotType],
    score: 0,
    selectedAt: now,
    selectedBy: "admin",
    pinnedEntityId: entityId,
    ...(eventArtistId ? { artistId: eventArtistId } : {}),
    pinnedBy: adminUid,
    pinnedAt: now,
    ...(pinnedUntil
      ? { pinnedUntil: Timestamp.fromDate(pinnedUntil) }
      : {}),
  };

  const historyEntry = {
    slotType,
    entityId,
    entityName,
    score: 0,
    selectedAt: now,
    selectedBy: "admin" as const,
  };

  const batch = db.batch();
  batch.set(
    db.collection(Collections.HOME_BANNERS).doc(slotType),
    bannerDoc,
  );
  batch.create(
    db.collection(Collections.BANNER_HISTORY).doc(),
    historyEntry,
  );
  await batch.commit();

  console.log(
    `Banner [${slotType}] pinned to "${entityName}" by admin ${adminUid}`,
  );
}

export async function unpinBanner(
  db: Firestore,
  slotType: BannerSlotType,
): Promise<void> {
  await db
    .collection(Collections.HOME_BANNERS)
    .doc(slotType)
    .update({
      pinnedEntityId: FieldValue.delete(),
      pinnedBy: FieldValue.delete(),
      pinnedAt: FieldValue.delete(),
      pinnedUntil: FieldValue.delete(),
    });

  console.log(`Banner [${slotType}] pin cleared`);
}
