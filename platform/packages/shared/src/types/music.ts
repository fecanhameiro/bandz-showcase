import { FirestoreTimestamp } from "./common.js";
import type { SupportedLocale } from "../constants/locales.js";

// --- Generic Music Data (adapter output) ---

export interface GenericMusicData {
  provider: string;
  providerId: string;
  syncedAt?: FirestoreTimestamp;
  lastUpdated?: FirestoreTimestamp;
  genreData: GenreGroup[];
}

export interface GenreGroup {
  source?: string;
  weight?: number;
  genres: string[];
}

export interface RawMusicData {
  provider?: string;
  syncedAt?: FirestoreTimestamp;
  lastUpdated?: FirestoreTimestamp;
  genreData?: GenreGroup[];
  [key: string]: unknown;
}

// --- Genre Processing ---

export interface GenreWithScore {
  name: string;
  score: number;
  percentage: number;
}

export interface ProcessedGenreData {
  lastUpdated: FirestoreTimestamp;
  genres: Record<string, number>;
  favoriteGenres: GenreWithScore[];
}

// --- Genre Match Config (used by cloud function for matching) ---

export interface GenreMatchConfig {
  styleGroupId: string;
  matchTerms: string[];
}

// --- Style Group Translations ---

export interface StyleGroupTranslation {
  name: string;
  description?: string;
}

// --- Style Groups ---

export interface StyleGroup {
  id: string;
  name: string;
  mainGenre: string;
  color: string;
  icon: string;
  genres: string[];
  styleStrings: string[];
  createdAt: FirestoreTimestamp;
  description?: string;
  active?: boolean;
  order?: number;
  emoji?: string;
  imageUrl?: string;
  translations?: Partial<Record<SupportedLocale, StyleGroupTranslation>>;
}

export interface StyleGroupReference {
  id: string;
  name: string;
  mainGenre: string;
  color: string;
  icon: string;
}

export interface StyleGroupWithScore {
  id: string;
  mainGenre: string;
  name: string;
  color: string;
  icon: string;
  score: number;
  percentage: number;
}

export interface ProcessedGenreSourceMetadata {
  providerId: string;
  provider: string;
  rawDocumentPath: string;
  rawDocumentLastUpdated?: FirestoreTimestamp | null;
}

export interface ProcessedStyleGroupData {
  lastUpdated: FirestoreTimestamp;
  styleGroups: Record<string, number>;
  topStyleGroups: StyleGroupWithScore[];
  genreToStyleGroupMap: Record<string, StyleGroupReference>;
  unclassifiedGenres: Record<string, number>;
  metadata: {
    totalRawGenres: number;
    classifiedGenres: number;
    unclassifiedGenreCount: number;
    styleGroupCount: number;
    processedAt: FirestoreTimestamp;
    source: ProcessedGenreSourceMetadata;
  };
}
