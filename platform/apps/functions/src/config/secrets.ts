import { defineSecret } from "firebase-functions/params";

// Google Places
export const GOOGLE_PLACES_API_KEY = defineSecret("GOOGLE_PLACES_API_KEY");

// Instagram / Facebook Graph API
export const FACEBOOK_APP_ID = defineSecret("FACEBOOK_APP_ID");
export const FACEBOOK_APP_SECRET = defineSecret("FACEBOOK_APP_SECRET");
export const FACEBOOK_USER_TOKEN = defineSecret("FACEBOOK_USER_TOKEN");

// Telegram (notifications)
export const TELEGRAM_BOT_TOKEN = defineSecret("TELEGRAM_BOT_TOKEN");
export const TELEGRAM_CHAT_ID = defineSecret("TELEGRAM_CHAT_ID");
