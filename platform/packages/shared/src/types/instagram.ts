export interface InstagramUser {
  username: string;
  website: string;
  name: string;
  ig_id: string;
  id: string;
  profile_picture_url: string;
  biography: string;
  follows_count: number;
  followers_count: number;
  media_count: number;
  media: { data: InstagramMedia[] };
  placeId: string;
  placeName: string;
  placeType: string;
  placeCountry: string;
  placeState: string;
  placeCity: string;
  lastDateUpdated: Date;
}

export interface InstagramMedia {
  id: string;
  caption: string;
  like_count: number;
  comments_count: number;
  timestamp: string;
  username: string;
  media_product_type: string;
  media_type: string;
  owner: string;
  permalink: string;
  media_url: string;
  children: InstagramMedia[];
}
