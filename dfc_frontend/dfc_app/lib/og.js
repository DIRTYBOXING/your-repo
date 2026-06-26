const functions = require("firebase-functions");

exports.generateOGImage = functions.https.onRequest((req, res) => {
    const entityId = req.query.id || "default";
    const entityType = req.query.type || "fighter"; // fighter, event, etc.

    // Use 'canvas' library here to draw the stats, health metrics, and background
    
    res.set("Content-Type", "image/png");
    res.send(Buffer.from("mock-png-data-for-" + entityType + "-" + entityId));
});