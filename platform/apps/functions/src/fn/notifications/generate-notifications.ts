import { onSchedule } from "firebase-functions/v2/scheduler";
import { getDb } from "../../config/admin.js";
import { generateDailyUserNotifications } from "../../services/notification.service.js";

export const generateUserNotifications = onSchedule(
  { schedule: "0 9 * * *", timeoutSeconds: 540, region: "us-central1" },
  async () => {
    try {
      await generateDailyUserNotifications(getDb());
      console.log("User notifications generated successfully");
    } catch (error) {
      console.error("Error generating user notifications:", error);
    }
  },
);
