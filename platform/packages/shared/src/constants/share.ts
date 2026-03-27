/** Share / deep link constants — used by Cloud Functions and mobile apps. */

export const SHARE_DOMAIN = "https://bandz.com.br";

export const SharePaths = {
  EVENT: "event",
  ARTIST: "artist",
  PLACE: "place",
} as const;

export type ShareEntityType = (typeof SharePaths)[keyof typeof SharePaths];

/** Build the canonical share URL for an entity. */
export function buildShareUrl(type: ShareEntityType, id: string): string {
  return `${SHARE_DOMAIN}/${type}/${id}`;
}

/** Build the OG image URL for an entity. */
export function buildOgImageUrl(type: ShareEntityType, id: string): string {
  return `${SHARE_DOMAIN}/${type}/${id}/og.jpg`;
}

/** Build the analytics beacon endpoint URL. */
export function buildAnalyticsUrl(): string {
  return `${SHARE_DOMAIN}/api/track`;
}
