const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

exports.checkPpvEntitlement = functions.region('australia-southeast1').https.onCall(async (data, context) => {
  // 1. Enforce Authentication
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be signed in to verify PPV access.");
  }

  const userId = context.auth.uid;
  const eventId = data.eventId;

  if (!eventId) {
    throw new functions.https.HttpsError("invalid-argument", "Event ID is required.");
  }

  try {
    const db = admin.firestore();
    
    // 2. Validate Stripe/PPV Purchase Record in Firestore
    const purchaseRef = db.collection("users").doc(userId).collection("ppv_purchases").doc(eventId);
    const purchaseDoc = await purchaseRef.get();

    if (!purchaseDoc.exists) {
      return { hasAccess: false, message: "No active PPV purchase found for this event." };
    }

    // 3. Fetch the Secure Mux Playback ID
    const eventDoc = await db.collection("events").doc(eventId).get();
    const eventData = eventDoc.data();

    return { hasAccess: true, playbackId: eventData?.muxPlaybackId };
  } catch (error) {
    console.error("Entitlement check failed:", error);
    throw new functions.https.HttpsError("internal", "Failed to verify PPV entitlement.");
  }
});