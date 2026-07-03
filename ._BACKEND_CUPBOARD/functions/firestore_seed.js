// DFC Firestore Seeder: Seeds initial collections for AI ecosystem
// Run this script once to create base collections and sample docs

const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

async function seed() {
  // ai_bots
  await db.collection("ai_bots").doc("bot_worker_1").set({
    id: "bot_worker_1",
    name: "DFC Bot Worker 1",
    type: "worker",
    active: true,
    lastSeen: admin.firestore.FieldValue.serverTimestamp(),
    memory: {},
  });
  await db.collection("ai_bots").doc("orchestrator").set({
    id: "orchestrator",
    name: "DFC Orchestrator",
    type: "orchestrator",
    active: true,
    lastSeen: admin.firestore.FieldValue.serverTimestamp(),
    memory: {},
  });
  // ai_tasks
  await db.collection("ai_tasks").add({
    type: "ingest",
    status: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    payload: { source: "UFC", content: "Sample fight news" },
  });
  // reasoning_chains
  await db.collection("reasoning_chains").add({
    status: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    steps: [],
  });
  // ingested_content
  await db.collection("ingested_content").add({
    status: "new",
    source: "UFC",
    content: "Sample fight content",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  // feed_content
  await db.collection("feed_content").add({
    status: "published",
    content: "Welcome to the DFC AI-powered feed!",
    publishedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log("✅ Firestore seeded for DFC AI ecosystem.");
}

seed();
