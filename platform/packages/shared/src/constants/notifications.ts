/** Notification system defaults */
export const NotificationDefaults = {
  TIMEZONE: "America/Sao_Paulo",
  SUMMARY_HOUR: 9,
  REMINDER_HOUR: 17,
  QUIET_HOURS_START: 21,
  QUIET_HOURS_END: 8,
  DAILY_LIMIT: 2,
  DAYS_AHEAD: 30,
  BATCH_SIZE: 50,
  STALE_TOKEN_DAYS: 90,
  RETRY_DELAY_MINUTES: 30,
  PAYLOAD_VERSION: 2,
} as const;
