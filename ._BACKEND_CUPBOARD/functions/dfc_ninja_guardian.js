// DFC Ninja Guardian Workflow
// The mystical guardian that protects the DFC ecosystem, welcomes users, rewards good deeds,
// and maintains harmony by cleaning toxic content.
// Features: Auto DM, Push Notifications, Social Posts, Dashboard Updates, Welcome Messages,
//           Ninja Appear/Disappear, Ecosystem Harmony & Cleaning

const admin = require("firebase-admin");

// Use shared admin instance from index.js (initializeApp called there)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// Collection constants
const CAMPAIGNS = [
  "gold_coin_drive",
  "pink_shield",
  "coffee_campaign",
  "fighter_signup",
];
const FRIENDS_COLLECTION = "friends";
const USERS_COLLECTION = "users";
const POSTS_COLLECTION = "posts";
const NOTIFICATIONS_COLLECTION = "notifications";
const REPORTS_COLLECTION = "reports";
const MODERATION_LOGS_COLLECTION = "moderation_logs";

// ==================== AUTO DM TO FRIENDS ====================
async function sendAutoDMs() {
  console.log("🥷 Ninja: Sending auto DMs to friends...");
  try {
    const friendsSnap = await db.collection(FRIENDS_COLLECTION).get();

    for (const friendDoc of friendsSnap.docs) {
      const friend = friendDoc.data();

      // Only send DM if friend hasn't engaged yet
      if (!friend.engaged) {
        const dmMessage = `Hey ${friend.name}! 👋 The DFC community needs you. Support ${friend.campaign || "our campaigns"} and make a real difference. Even $1 helps a child get food, shoes, or safety. Join us: ${friend.link}`;

        await db
          .collection(USERS_COLLECTION)
          .doc(friend.userId)
          .collection("messages")
          .add({
            from: "DFC Ninja",
            message: dmMessage,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            type: "campaign_invite",
            campaignId: friend.campaign || "general",
          });

        console.log(`✉️ DM sent to ${friend.name}`);
      }
    }
  } catch (error) {
    console.error("❌ Error sending auto DMs:", error);
  }
}

// ==================== WELCOME NEW USERS ====================
async function welcomeNewUsers() {
  console.log("🥷 Ninja: Welcoming new users...");
  try {
    const newUsersSnap = await db
      .collection(USERS_COLLECTION)
      .where("welcomed", "==", false)
      .get();

    for (const doc of newUsersSnap.docs) {
      const user = doc.data();
      const userId = doc.id;
      const userName = user.name || user.displayName || "Warrior";

      // Send personalized welcome message
      const welcomeMessage = `Hi ${userName}! 🙏 Welcome aboard to DataFightCentral. Thank you for joining DFC — may life bring you many blessings. ✨\n\nExplore FightWire, support our campaigns (Pink Shield 🛡️, Gold Coin Drive 🪙, Coffee Campaign ☕), and connect with your community. Together, we spread opportunity, not toxicity. 💪`;

      await db
        .collection(USERS_COLLECTION)
        .doc(userId)
        .collection("messages")
        .add({
          from: "DFC Ninja",
          message: welcomeMessage,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          type: "welcome",
        });

      // Send push notification
      const payload = {
        notification: {
          title: `Welcome ${userName}! 🥷`,
          body: `Thank you for joining DFC. May life bring you many blessings! The Ninja watches over you.`,
        },
      };
      await admin.messaging().sendToTopic(`user_${userId}`, payload);

      // Assign starter badge
      await db
        .collection(USERS_COLLECTION)
        .doc(userId)
        .update({
          badges: admin.firestore.FieldValue.arrayUnion("Antioxidant Recruit"),
          welcomed: true,
          welcomedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      // Ninja appears for this user
      await triggerNinjaAppearance(
        userId,
        `Welcomed new warrior ${userName} to the ecosystem`,
      );

      console.log(`✅ Welcomed user: ${userName}`);
    }
  } catch (error) {
    console.error("❌ Error welcoming new users:", error);
  }
}

// ==================== NINJA APPEAR/DISAPPEAR SYSTEM ====================
async function triggerNinjaAppearance(userId, actionDescription) {
  console.log(`🥷 Ninja appears for user ${userId}: ${actionDescription}`);

  try {
    // Ninja leaves a mysterious message
    await db
      .collection(USERS_COLLECTION)
      .doc(userId)
      .collection("messages")
      .add({
        from: "DFC Ninja",
        message: `🥷 The Ninja has appeared: ${actionDescription}.\n\n✨ Actions complete. The Ninja vanishes into the shadows... *disappears*`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        type: "ninja_appearance",
        mystical: true,
      });

    // Log ninja activity
    await db.collection("ninja_log").add({
      userId: userId,
      action: actionDescription,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error("❌ Ninja appearance error:", error);
  }
}

// ==================== ECOSYSTEM HARMONY & CLEANING ====================
async function maintainEcosystemHarmony() {
  console.log(
    "🥷 Ninja: Maintaining ecosystem harmony and cleaning toxic content...",
  );

  try {
    // Clean toxic posts
    const allPosts = await db.collection(POSTS_COLLECTION).get();
    let cleanedCount = 0;

    for (const postDoc of allPosts.docs) {
      const post = postDoc.data();

      // Check for toxic markers
      if (
        post.toxic ||
        post.reportCount >= 5 ||
        post.communityTrustScore < 0.3
      ) {
        // Remove toxic post
        await db.collection(POSTS_COLLECTION).doc(postDoc.id).delete();

        // Log cleanup action
        await db.collection(MODERATION_LOGS_COLLECTION).add({
          action: "ninja_cleanup",
          postId: postDoc.id,
          reason: post.toxic
            ? "toxic_content"
            : post.reportCount >= 5
              ? "high_reports"
              : "low_trust_score",
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          performedBy: "DFC Ninja",
        });

        // Notify post author
        if (post.authorId) {
          await triggerNinjaAppearance(
            post.authorId,
            "Your post was removed to maintain ecosystem harmony. The Ninja does not allow toxic behavior.",
          );
        }

        cleanedCount++;
        console.log(`🧹 Cleaned toxic post ${postDoc.id}`);
      }
    }

    // Update dashboard with cleanup stats
    await db
      .collection("dashboard")
      .doc("ninja_cleanup")
      .set(
        {
          lastCleaned: admin.firestore.FieldValue.serverTimestamp(),
          postsRemoved: admin.firestore.FieldValue.increment(cleanedCount),
          ecosystemHealth: "balanced",
        },
        { merge: true },
      );

    console.log(`✅ Ninja ensured harmony. Cleaned ${cleanedCount} posts.`);
  } catch (error) {
    console.error("❌ Error maintaining harmony:", error);
  }
}

// ==================== BALANCE FLOW & ENGAGEMENT ====================
async function balanceEcosystemFlow() {
  console.log("🥷 Ninja: Balancing ecosystem flow...");

  try {
    // Check for inactive users and re-engage them
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

    const inactiveUsers = await db
      .collection(USERS_COLLECTION)
      .where("lastActive", "<", oneWeekAgo)
      .where("welcomed", "==", true)
      .get();

    for (const doc of inactiveUsers.docs) {
      const user = doc.data();
      const userId = doc.id;
      const userName = user.name || user.displayName || "Warrior";

      // Send re-engagement message
      const reEngageMessage = `Hey ${userName}! 👋 We miss you at DFC. The community has grown, new campaigns launched, and fighters are crushing goals. Come back and see what's happening! 🥊`;

      await db
        .collection(USERS_COLLECTION)
        .doc(userId)
        .collection("messages")
        .add({
          from: "DFC Ninja",
          message: reEngageMessage,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          type: "re_engagement",
        });

      console.log(`🔄 Re-engaged inactive user: ${userName}`);
    }

    console.log("✅ Flow balanced. Ecosystem flowing smoothly.");
  } catch (error) {
    console.error("❌ Error balancing flow:", error);
  }
}

// ==================== PUSH NOTIFICATIONS ====================
async function sendPushNotifications() {
  console.log("🥷 Ninja: Sending push notifications...");

  try {
    const snapshot = await db
      .collection(NOTIFICATIONS_COLLECTION)
      .where("sent", "==", false)
      .get();

    for (const doc of snapshot.docs) {
      const notif = doc.data();

      const payload = {
        notification: {
          title: notif.title,
          body: notif.body,
          icon: notif.icon || "/icons/dfc-ninja.png",
        },
        data: {
          click_action: notif.clickAction || "FLUTTER_NOTIFICATION_CLICK",
          campaignId: notif.campaignId || "",
          type: notif.type || "general",
        },
      };

      if (notif.topic) {
        await admin.messaging().sendToTopic(notif.topic, payload);
      } else if (notif.userId) {
        await admin.messaging().sendToTopic(`user_${notif.userId}`, payload);
      }

      // Mark as sent
      await doc.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`📱 Push notification sent: ${notif.title}`);
    }
  } catch (error) {
    console.error("❌ Error sending push notifications:", error);
  }
}

// ==================== AUTO SOCIAL POSTS ====================
async function autoSocialPosts() {
  console.log("🥷 Ninja: Creating automated social posts...");

  try {
    const postsRef = db.collection(POSTS_COLLECTION);

    for (const campaign of CAMPAIGNS) {
      const campaignName = campaign.replace(/_/g, " ").toUpperCase();
      const campaignEmoji =
        campaign === "pink_shield"
          ? "🛡️"
          : campaign === "gold_coin_drive"
            ? "🪙"
            : campaign === "coffee_campaign"
              ? "☕"
              : "🥊";

      await postsRef.add({
        campaign: campaign,
        authorId: "dfc_ninja",
        authorName: "DFC Ninja",
        content: `${campaignEmoji} Join the ${campaignName} and make a real difference! The Ninja watches and rewards good deeds. Together, we are the antidote to toxic social media. 💪 #DFC #AntioxidantsForChange`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        type: "campaign_announcement",
        visibility: "public",
        campaignId: campaign,
        communityTrustScore: 1.0,
      });

      console.log(`📢 Auto-posted for campaign: ${campaign}`);
    }
  } catch (error) {
    console.error("❌ Error creating social posts:", error);
  }
}

// ==================== DASHBOARD UPDATE ====================
async function updateDashboard() {
  console.log("🥷 Ninja: Updating campaign dashboard...");

  try {
    const dashboardRef = db.collection("dashboard").doc("campaigns");
    const campaignData = {};

    for (let campaign of CAMPAIGNS) {
      const countSnap = await db
        .collection(USERS_COLLECTION)
        .where("engagedCampaigns", "array-contains", campaign)
        .get();

      const donationsSnap = await db
        .collection("donations")
        .where("campaignId", "==", campaign)
        .get();

      let totalDonations = 0;
      donationsSnap.forEach((doc) => {
        totalDonations += doc.data().amount || 0;
      });

      campaignData[campaign] = {
        engagedUsers: countSnap.size,
        totalDonations: totalDonations,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      };
    }

    await dashboardRef.set(campaignData, { merge: true });
    console.log("✅ Dashboard updated with latest campaign stats.");
  } catch (error) {
    console.error("❌ Error updating dashboard:", error);
  }
}

// ==================== REWARD GOOD DEEDS ====================
async function rewardGoodDeeds() {
  console.log("🥷 Ninja: Rewarding good deeds...");

  try {
    // Find users who donated or helped this week
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

    const recentDonations = await db
      .collection("donations")
      .where("timestamp", ">", oneWeekAgo)
      .get();

    const usersRewarded = new Set();

    for (const doc of recentDonations.docs) {
      const donation = doc.data();

      if (!usersRewarded.has(donation.userId)) {
        usersRewarded.add(donation.userId);

        // Award badge
        await db
          .collection(USERS_COLLECTION)
          .doc(donation.userId)
          .update({
            badges: admin.firestore.FieldValue.arrayUnion("Good Deed Warrior"),
            karmaPoints: admin.firestore.FieldValue.increment(10),
          });

        // Ninja appears to thank them
        await triggerNinjaAppearance(
          donation.userId,
          `Thank you for your generosity. Your good deed has been recorded. The Ninja honors you.`,
        );

        console.log(`🏅 Rewarded user ${donation.userId} for good deed.`);
      }
    }

    console.log(`✅ Rewarded ${usersRewarded.size} warriors for good deeds.`);
  } catch (error) {
    console.error("❌ Error rewarding good deeds:", error);
  }
}

// Export workflow functions for Firebase Functions scheduler wrappers.
module.exports = {
  sendAutoDMs,
  welcomeNewUsers,
  sendPushNotifications,
  autoSocialPosts,
  updateDashboard,
  maintainEcosystemHarmony,
  balanceEcosystemFlow,
  triggerNinjaAppearance,
  rewardGoodDeeds,
};
