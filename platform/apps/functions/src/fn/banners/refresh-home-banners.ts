import { onSchedule } from "firebase-functions/v2/scheduler";
import { getDb } from "../../config/admin.js";
import { refreshHomeBanners } from "../../services/banner-selection.service.js";

export const refreshHomeBannersSchedule = onSchedule(
  {
    schedule: "0 9 * * *", // 06:00 BRT (UTC-3)
    timeoutSeconds: 300,
    memory: "512MiB",
    region: "southamerica-east1",
  },
  async () => {
    try {
      await refreshHomeBanners(getDb());
      console.log("Home banners refreshed successfully");
    } catch (error) {
      console.error("Error refreshing home banners:", error);
    }
  },
);
