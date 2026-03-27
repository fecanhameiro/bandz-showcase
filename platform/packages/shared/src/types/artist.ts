import { AuditFields, GeoPoint } from "./common.js";

export interface Artist extends AuditFields {
  id: string;
  name: string;
  country: string;
  state: string;
  city: string;
  location?: GeoPoint;
  style: string;
  genres?: string[];
  description?: string;
  email?: string;
  phone?: string;
  whatsapp?: string;
  website?: string;
  instagramId?: string;
  facebookId?: string;
  tiktokId?: string;
  youtubeId?: string;
  youtubeURL?: string;
  spotifyId?: string;
  soundcloudId?: string;
  styleGroupId: string;
  styleGroupName: string;
  styleGroupColor: string;
  styleGroupGenres: string[];
  active: boolean;
}
