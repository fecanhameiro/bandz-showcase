import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getDb, getFirebaseMessaging } from "../../config/admin.js";
import {
  notifyArtistFollowers,
  notifyPlaceFollowers,
} from "../../services/follow-notification.service.js";

/**
 * Triggers when a new event is created in BR_events.
 * Notifies users who follow the event's artist or place.
 */
export const onEventCreated = onDocumentCreated(
  { document: "BR_events/{eventId}", region: "us-central1" },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    const eventId = event.params.eventId;

    const eventData = {
      eventName: data.eventName as string | undefined,
      eventDate: data.eventDate,
      artistId: data.artistId as string | undefined,
      artistName: data.artistName as string | undefined,
      placeId: data.placeId as string | undefined,
      placeName: data.placeName as string | undefined,
      placeCity: data.placeCity as string | undefined,
      placeState: data.placeState as string | undefined,
      genre: (data.style as string) || undefined,
      hasImage: false,
    };

    console.log("onEventCreated: processing", {
      eventId,
      artistId: eventData.artistId,
      artistName: eventData.artistName,
      placeId: eventData.placeId,
      placeName: eventData.placeName,
    });

    const db = getDb();
    const messaging = getFirebaseMessaging();

    const [artistResult, placeResult] = await Promise.all([
      eventData.artistId
        ? notifyArtistFollowers(db, messaging, eventId, eventData)
        : Promise.resolve({ usersNotified: 0, notificationsCreated: 0, errors: 0 }),
      eventData.placeId
        ? notifyPlaceFollowers(db, messaging, eventId, eventData)
        : Promise.resolve({ usersNotified: 0, notificationsCreated: 0, errors: 0 }),
    ]);

    console.log("onEventCreated: completed", {
      eventId,
      artistFollowers: artistResult,
      placeFollowers: placeResult,
    });
  },
);
