import fs from "node:fs";
import admin from "firebase-admin";

const projectId =
  process.env.GCLOUD_PROJECT ||
  process.env.FIREBASE_PROJECT_ID ||
  "datafightcentral";
const serviceAccountPath =
  process.env.FIREBASE_SA || "./serviceAccountKey.json";
const dryRun = process.argv.includes("--dry-run");
const maxDocs = Number(process.env.MIGRATION_LIMIT || "1000");

if (!admin.apps.length) {
  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = JSON.parse(
      fs.readFileSync(serviceAccountPath, "utf8"),
    );
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId,
    });
  } else {
    admin.initializeApp({ projectId });
  }
}

const db = admin.firestore();

function toTimestamp(value) {
  if (value == null) return null;
  if (value instanceof admin.firestore.Timestamp) return value;
  if (value instanceof Date) return admin.firestore.Timestamp.fromDate(value);
  if (typeof value === "string") {
    const d = new Date(value);
    if (!Number.isNaN(d.getTime()))
      return admin.firestore.Timestamp.fromDate(d);
  }
  if (typeof value === "number") {
    return admin.firestore.Timestamp.fromMillis(Math.trunc(value));
  }
  return null;
}

async function migrateCollection({ collection, fields }) {
  const snap = await db.collection(collection).limit(maxDocs).get();
  let touched = 0;

  for (const doc of snap.docs) {
    const data = doc.data() || {};
    const update = {};

    for (const field of fields) {
      const raw = data[field];
      const ts = toTimestamp(raw);
      if (raw != null && ts && !(raw instanceof admin.firestore.Timestamp)) {
        update[field] = ts;
      }
    }

    if (Object.keys(update).length > 0) {
      touched += 1;
      if (dryRun) {
        console.log(
          `[dry-run] ${collection}/${doc.id} ->`,
          Object.keys(update).join(", "),
        );
      } else {
        await doc.ref.set(update, { merge: true });
        console.log(`updated ${collection}/${doc.id}`);
      }
    }
  }

  console.log(
    `${collection}: scanned=${snap.size}, updated=${touched}, dryRun=${dryRun}`,
  );
}

async function run() {
  console.log(
    `Starting Firestore date migration (project=${projectId}, dryRun=${dryRun})`,
  );

  await migrateCollection({
    collection: "events",
    fields: ["eventDate", "date", "createdAt", "updatedAt"],
  });

  await migrateCollection({
    collection: "posts",
    fields: ["createdAt", "date", "publishedAt", "updatedAt"],
  });

  await migrateCollection({
    collection: "messages",
    fields: ["sentAt", "createdAt", "date", "readAt"],
  });

  console.log("Migration complete.");
}

run().catch((err) => {
  console.error("Migration failed:", err?.message || err);
  process.exitCode = 1;
});
