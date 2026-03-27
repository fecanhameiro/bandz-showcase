import { AuditFields, FirestoreTimestamp, GeoPoint } from "./common.js";
import { GooglePlaceOpeningHours } from "./place.js";

export interface Event extends AuditFields {
  id: string;
  eventName: string;
  description: string;
  youtubeURL: string;
  placeId: string;
  placeName: string;
  placeType: string;
  location?: GeoPoint;
  placeCity: string;
  placeState: string;
  placeCountry: string;
  genres: string[];
  style: string;
  artistId: string;
  artistName: string;
  eventDate?: FirestoreTimestamp | Date;
  styleGroupId: string;
  styleGroupName: string;
  styleGroupColor: string;
  styleGroupGenres: string[];
  placeStyleGroupId: string;
  placeStyleGroupName: string;
  placeStyleGroupColor: string;
  placeStyleGroupGenres: string[];
  linkEvent?: string;
  active: boolean;

  // Place enrichment (denormalized for recommendation engine)
  placeGoogleRating?: number;
  placeGoogleTotalRatings?: number;
  placeViewsTotal?: number;
  placeCreatedAt?: FirestoreTimestamp | Date;
  placeOpeningHours?: string[];
  placeUpcomingEventCount?: number;
  placeFavoriteCount?: number;
  placeNeighborhood?: string;

  // Artist enrichment (denormalized for recommendation engine)
  artistStyleGroupId?: string;
  artistStyleGroupName?: string;
  artistStyleGroupGenres?: string[];
  artistCity?: string;
  artistState?: string;
  artistViewsTotal?: number;
  artistCreatedAt?: FirestoreTimestamp | Date;
  artistUpcomingEventCount?: number;
  artistFavoriteCount?: number;

  // Event own enrichment
  eventViewsTotal?: number;
  eventFavoriteCount?: number;
  eventIsFree?: boolean;
}

/** Denormalized event data used in notifications and event feeds */
export interface EventData {
  id: string;
  eventName: string;
  eventDate: FirestoreTimestamp;
  eventDescription: string;
  eventLink: string | null;
  eventHasImage: boolean;
  eventYouTubeURL: string | null;

  placeId: string;
  placeName: string;
  placeType: string;
  placeLocation: GeoPoint | null;
  placeAddress: string | null;
  placeAddressNumber: string | null;
  placeCity: string;
  placeState: string;
  placeCountry: string;
  placePhoneNumber: string | null;
  placeWebsite: string | null;
  placeGooglePlaceOpeningHours: GooglePlaceOpeningHours | null;
  placeIsLGBTFriendly: boolean;
  placeGenres: string[];
  placeStyles: string;

  artistId: string;
  artistName: string;
  artistInstagramId: string | null;
  artistTiktokId: string | null;
  artistSpotifyId: string | null;
  artistSoundCloudId: string | null;
  artistFacebookId: string | null;
  artistYoutubeId: string | null;
  artistWebsite: string | null;
  artistGenres: string[];
  artistStyles: string;

  active: boolean;
  createdDate: FirestoreTimestamp;
  userCreatedId: string;
  userCreatedName: string;
  userCreatedEmail: string;
}
