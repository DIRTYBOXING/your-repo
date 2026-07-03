import fs from "node:fs";
import fsp from "node:fs/promises";
import admin from "firebase-admin";

const projectId =
  process.env.GCLOUD_PROJECT ||
  process.env.FIREBASE_PROJECT_ID ||
  "datafightcentral";
const inputPath =
  process.env.SAMPLE_DOCS_PATH ||
  (fs.existsSync("sample_firestore_docs.json")
    ? "sample_firestore_docs.json"
    : "data/sample_firestore_docs.json");
const serviceAccountPath =
  process.env.FIREBASE_SA || "./serviceAccountKey.json";
const bucket = process.env.FIREBASE_BUCKET;

if (!admin.apps.length) {
  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = JSON.parse(
      fs.readFileSync(serviceAccountPath, "utf8"),
    );
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId,
      ...(bucket ? { storageBucket: bucket } : {}),
    });
  } else {
    admin.initializeApp({
      projectId,
      ...(bucket ? { storageBucket: bucket } : {}),
    });
  }
}

const db = admin.firestore();

function maybeTimestamp(data, key) {
  const v = data[key];
  if (typeof v === "string") {
    const parsed = new Date(v);
    if (!Number.isNaN(parsed.getTime())) {
      data[key] = admin.firestore.Timestamp.fromDate(parsed);
    }
  }
}

async function upsertCollection(collection, docs, dateKeys = []) {
  const entries = Array.isArray(docs)
    ? docs.map((d) => [String(d.id || ""), d])
    : Object.entries(docs || {});

  for (const [key, rawDoc] of entries) {
    const data = { ...(rawDoc || {}) };
    const id = String(data.id || key || db.collection(collection).doc().id);
    delete data.id;

    for (const field of dateKeys) {
      maybeTimestamp(data, field);
    }

    await db.collection(collection).doc(id).set(data, { merge: true });
    console.log(`upserted ${collection}/${id}`);
  }
}

async function run() {
  const raw = await fsp.readFile(inputPath, "utf8");
  const json = JSON.parse(raw);

  await upsertCollection("events", json.events || [], [
    "eventDate",
    "date",
    "createdAt",
    "updatedAt",
  ]);
  await upsertCollection("posts", json.posts || [], [
    "createdAt",
    "date",
    "publishedAt",
    "updatedAt",
  ]);
  await upsertCollection("messages", json.messages || [], [
    "sentAt",
    "createdAt",
    "date",
    "readAt",
  ]);

  console.log("Sample import complete.");
}

run().catch((err) => {
  console.error("Sample import failed:", err?.message || err);
  process.exitCode = 1;
});
