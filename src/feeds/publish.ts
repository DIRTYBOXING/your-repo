// src/feeds/publish.ts
// Publish normalized feed items to Firestore, applying moderation rules.
import fs from "fs";
import path from "path";
import admin from "firebase-admin";

const FEED_INPUT = path.join(__dirname, "../../auto_feed.json");
const COLLECTION = "feed_items";

/** Minimum trust score to publish without manual review. */
const TRUST_THRESHOLD = 0.5;

type FeedItem = Record<string, unknown>;

function initFirebase(): void {
  if (!admin.apps.length) {
    admin.initializeApp();
  }
}

function loadItems(): FeedItem[] {
  if (!fs.existsSync(FEED_INPUT)) {
    console.error("No feed data found. Run intake first.");
    process.exit(1);
  }
  const raw = JSON.parse(fs.readFileSync(FEED_INPUT, "utf-8"));
  // Support both `{items:[...]}` and a top-level array.
  return Array.isArray(raw) ? raw : (raw.items ?? []);
}

function applyModeration(items: FeedItem[]): {
  approved: FeedItem[];
  rejected: FeedItem[];
} {
  const approved: FeedItem[] = [];
  const rejected: FeedItem[] = [];
  for (const item of items) {
    const trustScore =
      typeof item.trust_score === "number" ? item.trust_score : 1;
    const status = typeof item.status === "string" ? item.status : "approved";
    const hasContent = Boolean(item.content ?? item.title);
    if (trustScore >= TRUST_THRESHOLD && status !== "rejected" && hasContent) {
      approved.push(item);
    } else {
      rejected.push(item);
    }
  }
  return { approved, rejected };
}

async function publishFeed(): Promise<void> {
  initFirebase();
  const items = loadItems();
  const { approved, rejected } = applyModeration(items);

  console.log(
    `Feed: ${items.length} total — ${approved.length} approved, ${rejected.length} rejected by moderation.`
  );

  const db = admin.firestore();
  const batch = db.batch();

  for (const item of approved) {
    const id = typeof item.id === "string" && item.id ? item.id : db.collection(COLLECTION).doc().id;
    const ref = db.collection(COLLECTION).doc(id);
    batch.set(
      ref,
      {
        ...item,
        publishedAt: admin.firestore.FieldValue.serverTimestamp(),
        moderationStatus: "approved",
      },
      { merge: true }
    );
  }

  await batch.commit();
  console.log(`Published ${approved.length} items to Firestore '${COLLECTION}'.`);
}

publishFeed().catch((err) => {
  console.error("publishFeed failed:", err);
  process.exit(1);
});
