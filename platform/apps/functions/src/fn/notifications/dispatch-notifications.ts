import { onSchedule } from "firebase-functions/v2/scheduler";
import { getDb, getFirebaseMessaging } from "../../config/admin.js";
import { dispatchPendingNotifications } from "../../services/push-dispatch.service.js";

export const dispatchUserNotifications = onSchedule(
  {
    schedule: "*/30 * * * *",
    timeoutSeconds: 540,
    memory: "1GiB",
    region: "us-central1",
  },
  async () => {
    try {
      await dispatchPendingNotifications(getDb(), getFirebaseMessaging());
      console.log("User push notifications dispatched successfully");
    } catch (error) {
      console.error("Error dispatching user notifications:", error);
    }
  },
);
