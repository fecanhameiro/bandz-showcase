import { AuditFields, GeoPoint } from "./common.js";

export interface GooglePlacePeriod {
  open: { day: number; time: string };
  close: { day: number; time: string };
}

export interface GooglePlaceOpeningHours {
  open_now: boolean;
  periods: GooglePlacePeriod[];
  weekday_text: string[];
}

export interface GooglePlaceDetail {
  googlePlaceName: string;
  googlePlaceFormattedPhoneNumber?: string;
  googlePlaceinternationalPhoneNumber?: string;
  googlePlaceOpeningHours?: GooglePlaceOpeningHours;
  googlePlaceEditorialSummary?: string;
  googlePlaceRating?: number;
  googlePlaceUserRatingsTotal?: number;
  googlePlaceUrl?: string;
}

export interface Place extends AuditFields, GooglePlaceDetail {
  id: string;
  name: string;
  placeType: string;
  location: GeoPoint | null;
  genres: string[];
  style: string;
  description: string;
  country: string;
  state: string;
  city: string;
  address: string;
  addressNumber?: string;
  postalCode?: string;
  email?: string;
  phone?: string;
  whatsapp?: string;
  website?: string;
  instagramId?: string;
  facebookId?: string;
  tiktokId?: string;
  googlePlaceId?: string;
  styleGroupId: string;
  styleGroupName: string;
  styleGroupColor: string;
  styleGroupGenres: string[];
  neighborhood?: string;
  active: boolean;
  isPlaceLGBTFriendly: boolean;
}
