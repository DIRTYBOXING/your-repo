import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const getDashboard = functions
  .region("australia-southeast1")
  .https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated."
      );
    }
    
    const doc = await admin
      .firestore()
      .collection("dashboards")
      .doc(uid)
      .get();

    const base = (doc.exists ? doc.data() : {}) as any;

    return {
      upcomingEventTitle: base.upcomingEventTitle ?? "DFC 2: REDEMPTION",
      daysOut: base.daysOut ?? 14,
      weight: base.weight ?? 74.5,
      readiness: base.readiness ?? 88,
      tokens: base.tokens ?? 2400,
    };
  });