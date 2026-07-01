// ─── Campaign Scheduled Trigger ──────────────────────────────────────────────
// Scans active campaigns hourly and enqueues poster generation jobs to Pub/Sub.
// Deployed as a Firebase scheduled function running in Australia/Brisbane.

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { PubSub } = require("@google-cloud/pubsub");

const pubsub = new PubSub();

module.exports.scheduledCampaignTrigger = onSchedule(
  {
    schedule: "every 1 hours",
    timeZone: "Australia/Brisbane",
    region: "australia-southeast1",
  },
  async () => {
    const { admin, db } = require("../config");
    const now = admin.firestore.Timestamp.now();

    const campaignsSnap = await db
      .collection("campaigns")
      .where("status", "==", "active")
      .get();

    const publishes = [];

    campaignsSnap.forEach((doc) => {
      const c = doc.data();
      if (!c) return;

      const startSec = c.start_at?.seconds ?? 0;
      const endSec = c.end_at?.seconds ?? 0;

      // Enqueue if within 24-hour window before event start and before end
      if (now.seconds >= startSec - 86400 && now.seconds <= endSec) {
        const payload = {
          campaignId: c.id || doc.id,
          market: (c.markets && c.markets[0]) || "AU",
          templateRef: c.templateRef || "default",
        };
        publishes.push(pubsub.topic("poster_generation").publishJSON(payload));
      }
    });

    if (publishes.length > 0) {
      await Promise.all(publishes);
      console.info(
        `[scheduledCampaignTrigger] enqueued ${publishes.length} poster jobs`,
      );
    }
  },
);
