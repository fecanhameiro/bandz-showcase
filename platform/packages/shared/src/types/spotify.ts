export interface SpotifyProfile {
  id: string;
  email: string;
  display_name: string;
  uri: string;
  images?: { url: string }[];
}

export interface SpotifyGenreGroup {
  genres: string[];
  source: string;
  timeRange: string;
  weight: number;
}
