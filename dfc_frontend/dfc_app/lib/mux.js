const functions = require("firebase-functions");
const admin = require("firebase-admin");

exports.createLiveStream = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "Promoter access required.");
    
    // Placeholder for Mux Video API implementation
    // Awaits Mux API call to generate a unique RTMP URL and Stream Key
    const streamKey = "mock-stream-key-" + Math.floor(Math.random() * 10000);
    const playbackId = "mock-playback-id-" + Math.floor(Math.random() * 10000);

    return {
        streamKey: streamKey,
        playbackId: playbackId
    };
});