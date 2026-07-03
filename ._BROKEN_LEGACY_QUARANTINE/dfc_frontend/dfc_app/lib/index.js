const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

exports.getDashboard = functions.region("australia-southeast1").https.onCall(async (data, context) => {
  const uid = context && context.auth ? context.auth.uid : null;
  if (!uid) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
  }

  const doc = await admin.firestore().collection("dashboards").doc(uid).get();

  const base = doc.exists ? doc.data() : {};

  return {
    upcomingEventTitle: base.upcomingEventTitle || "DFC 2: REDEMPTION",
    daysOut: typeof base.daysOut === "number" ? base.daysOut : 14,
    weight: typeof base.weight === "number" ? base.weight : 74.5,
    readiness: typeof base.readiness === "number" ? base.readiness : 88,
    tokens: typeof base.tokens === "number" ? base.tokens : 2400,
  };
});
