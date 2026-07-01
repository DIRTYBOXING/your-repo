const functions = require("firebase-functions");
const admin = require("firebase-admin");
if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

// WebRTC signaling: offer, answer, ICE candidates
exports.signalWebRTC = functions.https.onCall(async (data, context) => {
  const { sessionId, senderId, type, payload } = data;
  // sessionId: unique for each fight event or overlay
  // type: 'offer', 'answer', 'candidate'
  // payload: SDP or ICE candidate

  // Store signaling message in Firestore
  await db.collection("webrtc_signaling").add({
    sessionId,
    senderId,
    type,
    payload,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { status: "ok" };
});

// Client listens to Firestore collection 'webrtc_signaling' for sessionId
// When a fight event triggers (e.g., walkout), push signaling messages
// Security: Use Firestore rules to restrict access to sessionId participants
