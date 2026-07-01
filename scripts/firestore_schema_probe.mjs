import fs from "node:fs";
import admin from "firebase-admin";

const projectId =
  process.env.GCLOUD_PROJECT ||
  process.env.FIREBASE_PROJECT_ID ||
  "datafightcentral";
const serviceAccountPath =
  process.env.FIREBASE_SA || "./serviceAccountKey.json";

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
const sampleLimit = Number(process.env.SCHEMA_PROBE_LIMIT || "100");

function valueType(v) {
  if (v === null) return "null";
  if (Array.isArray(v)) return "array";
  if (v && typeof v === "object" && v.constructor?.name === "Timestamp")
    return "timestamp";
  return typeof v;
}

function parseDateLike(v) {
  if (!v) return null;
  if (v && typeof v === "object" && v.constructor?.name === "Timestamp") {
    return v.toDate();
  }
  if (v instanceof Date) return v;
  if (typeof v === "string") {
    const parsed = new Date(v);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  return null;
}

async function inspectCollection(name, keyFields = []) {
  const snap = await db.collection(name).limit(sampleLimit).get();
  const fieldStats = {};

  for (const doc of snap.docs) {
    const data = doc.data() || {};
    for (const [k, v] of Object.entries(data)) {
      fieldStats[k] ??= {};
      const t = valueType(v);
      fieldStats[k][t] = (fieldStats[k][t] || 0) + 1;
    }
  }

  console.log(`\n=== ${name} (${snap.size} docs sampled) ===`);
  if (snap.empty) {
    console.log("No documents found.");
    return;
  }

  for (const field of Object.keys(fieldStats).sort()) {
    const counts = fieldStats[field];
    const types = Object.entries(counts)
      .map(([t, c]) => `${t}:${c}`)
      .join(", ");
    console.log(`- ${field}: ${types}`);
  }

  for (const keyField of keyFields) {
    let valid = 0;
    for (const doc of snap.docs) {
      const raw = doc.get(keyField);
      if (raw === undefined || raw === null || raw === "") continue;
      if (keyField.toLowerCase().includes("date") || keyField.endsWith("At")) {
        if (parseDateLike(raw)) valid += 1;
      } else {
        valid += 1;
      }
    }
    console.log(`* coverage ${keyField}: ${valid}/${snap.size}`);
  }

  const firstFive = snap.docs.slice(0, 5);
  for (const doc of firstFive) {
    const data = doc.data() || {};
    const missing = [];
    const warnings = [];

    for (const keyField of keyFields) {
      if (!(keyField in data)) {
        missing.push(keyField);
        continue;
      }
      const raw = data[keyField];
      if (keyField.toLowerCase().includes("date") || keyField.endsWith("At")) {
        if (!parseDateLike(raw)) {
          warnings.push(`${keyField} is ${valueType(raw)}`);
        }
      }
    }

    if (missing.length || warnings.length) {
      console.log(
        `! doc ${doc.id} missing=[${missing.join(",")}] warnings=[${warnings.join(",")}]`,
      );
    }
  }
}

async function run() {
  console.log(`Firestore schema probe for project ${projectId}`);
  await inspectCollection("events", [
    "title",
    "eventDate",
    "date",
    "status",
    "posterUrl",
    "latitude",
    "longitude",
  ]);
  await inspectCollection("posts", [
    "content",
    "createdAt",
    "date",
    "publishedAt",
    "authorId",
    "userId",
  ]);
  await inspectCollection("conversations", ["participants", "lastMessageAt"]);
  await inspectCollection("messages", [
    "senderId",
    "receiverId",
    "authorId",
    "content",
    "sentAt",
    "createdAt",
  ]);
  console.log("\nProbe complete.");
}

run().catch((err) => {
  console.error("Schema probe failed:", err?.message || err);
  process.exitCode = 1;
});
