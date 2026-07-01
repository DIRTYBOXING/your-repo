// ═══════════════════════════════════════════════════════════════════════════
// DFC NOTIFICATIONS — FCM Push Notifications for Events, PPV, Safety
// ═══════════════════════════════════════════════════════════════════════════

const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { admin, db, REGION } = require("../config");

const messaging = admin.messaging();

// ═══════════════════════════════════════════════════════════════════════════
// PPV EVENT GOING LIVE — Notify all purchasers
// ═══════════════════════════════════════════════════════════════════════════
const onPPVGoLive = onDocumentUpdated(
  {
    document: "ppv_events/{ppvId}",
    region: REGION,
  },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    // Only fire when status changes to 'live'
    if (before.status === "live" || after.status !== "live") return;

    const ppvId = event.params.ppvId;
    const title = after.title || "DFC PPV Event";

    // Get all purchasers for this event
    const purchasesSnap = await db
      .collection("ppv_purchases")
      .where("ppvId", "==", ppvId)
      .where("isActive", "==", true)
      .get();

    if (purchasesSnap.empty) return;

    const tokens = [];
    for (const doc of purchasesSnap.docs) {
      const userId = doc.data().userId;
      if (!userId) continue;

      const userDoc = await db.collection("users").doc(userId).get();
      const fcmToken = userDoc.data()?.fcmToken;
      if (fcmToken) tokens.push(fcmToken);
    }

    if (tokens.length === 0) return;

    // Send multicast notification
    const message = {
      notification: {
        title: "🔴 LIVE NOW",
        body: `${title} is streaming now! Tap to watch.`,
      },
      data: {
        type: "ppv_live",
        ppvId,
        route: `/ppv/${ppvId}/watch`,
      },
      tokens,
    };

    const response = await messaging.sendEachForMulticast(message);
    console.log(
      `ppv_live_notify: Sent to ${response.successCount}/${tokens.length} devices for ${ppvId}`,
    );
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// PPV PURCHASE CONFIRMATION — Notify buyer
// ═══════════════════════════════════════════════════════════════════════════
const onPPVPurchase = onDocumentCreated(
  {
    document: "ppv_purchases/{purchaseId}",
    region: REGION,
  },
  async (event) => {
    const purchase = event.data.data();
    const userId = purchase.userId;
    if (!userId) return;

    const userDoc = await db.collection("users").doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) return;

    const eventTitle = purchase.ppvTitle || purchase.eventTitle || "PPV Event";
    const tierName = purchase.tierName || "Full Access";

    await messaging.send({
      token: fcmToken,
      notification: {
        title: "🎟️ PPV Access Confirmed",
        body: `You're locked in for ${eventTitle} (${tierName}). We'll notify you when it goes live.`,
      },
      data: {
        type: "ppv_purchase_confirmed",
        ppvId: purchase.ppvId || "",
        route: `/ppv/event/${purchase.ppvId || ""}`,
      },
    });
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// EVENT REMINDER — 1 hour before event start, notify purchasers
// ═══════════════════════════════════════════════════════════════════════════
const sendEventReminders = onSchedule(
  {
    schedule: "every 15 minutes",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
  },
  async () => {
    const now = new Date();
    const oneHourFromNow = new Date(now.getTime() + 60 * 60 * 1000);
    const fifteenMinAgo = new Date(
      now.getTime() - 15 * 60 * 1000 + 60 * 60 * 1000,
    );

    // Find events starting in ~1 hour that haven't had reminders sent
    const eventsSnap = await db
      .collection("ppv_events")
      .where(
        "startTime",
        ">=",
        admin.firestore.Timestamp.fromDate(fifteenMinAgo),
      )
      .where(
        "startTime",
        "<=",
        admin.firestore.Timestamp.fromDate(oneHourFromNow),
      )
      .where("reminderSent", "!=", true)
      .limit(20)
      .get();

    for (const eventDoc of eventsSnap.docs) {
      const eventData = eventDoc.data();
      const ppvId = eventDoc.id;

      // Get purchasers
      const purchasesSnap = await db
        .collection("ppv_purchases")
        .where("ppvId", "==", ppvId)
        .where("isActive", "==", true)
        .get();

      const tokens = [];
      for (const purchaseDoc of purchasesSnap.docs) {
        const userId = purchaseDoc.data().userId;
        if (!userId) continue;
        const userDoc = await db.collection("users").doc(userId).get();
        const fcmToken = userDoc.data()?.fcmToken;
        if (fcmToken) tokens.push(fcmToken);
      }

      if (tokens.length > 0) {
        await messaging.sendEachForMulticast({
          notification: {
            title: "⏰ Starting Soon",
            body: `${eventData.title || "PPV Event"} starts in about 1 hour!`,
          },
          data: {
            type: "event_reminder",
            ppvId,
            route: `/ppv/event/${ppvId}`,
          },
          tokens,
        });
      }

      // Mark reminder as sent
      await eventDoc.ref.update({ reminderSent: true });
      console.log(
        `event_reminder: Sent reminder for ${ppvId} to ${tokens.length} devices`,
      );
    }
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// NEW POST NOTIFICATION — Notify followers when someone posts
// ═══════════════════════════════════════════════════════════════════════════
const onNewPost = onDocumentCreated(
  {
    document: "posts/{postId}",
    region: REGION,
  },
  async (event) => {
    const post = event.data.data();
    const authorId = post.authorId;
    if (!authorId) return;

    // Get author name
    const authorDoc = await db.collection("users").doc(authorId).get();
    const authorName = authorDoc.data()?.displayName || "Someone";

    // Get followers (users who follow this author)
    const followersSnap = await db
      .collection("follows")
      .where("followingId", "==", authorId)
      .limit(500)
      .get();

    if (followersSnap.empty) return;

    const tokens = [];
    for (const followDoc of followersSnap.docs) {
      const followerId = followDoc.data().followerId;
      if (!followerId) continue;
      const userDoc = await db.collection("users").doc(followerId).get();
      const fcmToken = userDoc.data()?.fcmToken;
      if (fcmToken) tokens.push(fcmToken);
    }

    if (tokens.length === 0) return;

    const contentPreview =
      (post.content || "").substring(0, 80) +
      ((post.content || "").length > 80 ? "..." : "");

    await messaging.sendEachForMulticast({
      notification: {
        title: `${authorName} posted`,
        body: contentPreview || "New post on DFC",
      },
      data: {
        type: "new_post",
        postId: event.params.postId,
        authorId,
        route: `/social/post/${event.params.postId}`,
      },
      tokens,
    });
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// SAFETY ALERT — Emergency SOS notification
// ═══════════════════════════════════════════════════════════════════════════
const onSafetyAlert = onDocumentCreated(
  {
    document: "safety_alerts/{alertId}",
    region: REGION,
  },
  async (event) => {
    const alert = event.data.data();
    const userId = alert.userId;
    if (!userId) return;

    // Get trusted contacts for this user
    const contactsSnap = await db
      .collection("users")
      .doc(userId)
      .collection("trusted_contacts")
      .get();

    if (contactsSnap.empty) return;

    const tokens = [];
    for (const contactDoc of contactsSnap.docs) {
      const contactUserId = contactDoc.data().userId;
      if (!contactUserId) continue;
      const userDoc = await db.collection("users").doc(contactUserId).get();
      const fcmToken = userDoc.data()?.fcmToken;
      if (fcmToken) tokens.push(fcmToken);
    }

    if (tokens.length === 0) return;

    const userName =
      (await db.collection("users").doc(userId).get()).data()?.displayName ||
      "A DFC user";

    await messaging.sendEachForMulticast({
      notification: {
        title: "🚨 SAFETY ALERT",
        body: `${userName} has triggered an emergency alert. Check on them immediately.`,
      },
      data: {
        type: "safety_alert",
        alertId: event.params.alertId,
        userId,
        route: `/safety/alert/${event.params.alertId}`,
      },
      android: {
        priority: "high",
        notification: { channelId: "dfc_safety_alerts" },
      },
      apns: {
        payload: {
          aps: {
            sound: "critical",
            "content-available": 1,
            "interruption-level": "critical",
          },
        },
      },
      tokens,
    });

    console.log(
      `safety_alert: Notified ${tokens.length} trusted contacts for user ${userId}`,
    );
  },
);

module.exports = {
  onPPVGoLive,
  onPPVPurchase,
  sendEventReminders,
  onNewPost,
  onSafetyAlert,
};
