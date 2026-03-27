import type { FirestoreTimestamp } from "./common.js";

export type FeedbackType =
  | "bug"
  | "suggestion"
  | "question"
  | "compliment"
  | "other";

export type FeedbackStatus = "new" | "read" | "resolved" | "archived";

export interface Feedback {
  type: FeedbackType;
  message: string;
  email: string | null;
  locale: "pt-br" | "en" | "es";
  source: string;
  pagePath: string;
  imageUrl: string | null;
  userAgent: string;
  referrer: string;
  ipAddress: string;
  createdAt: FirestoreTimestamp | Date;
  status: FeedbackStatus;
}
