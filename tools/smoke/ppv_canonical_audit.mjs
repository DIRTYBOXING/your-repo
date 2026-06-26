import fs from "node:fs";
import process from "node:process";
import {
  applicationDefault,
  cert,
  getApp,
  getApps,
  initializeApp,
} from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

function parseArgs(argv) {
  const parsed = {};

  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith("--")) {
      continue;
    }

    const key = token.slice(2);
    const next = argv[index + 1];
    if (!next || next.startsWith("--")) {
      parsed[key] = "true";
      continue;
    }

    parsed[key] = next;
    index += 1;
  }

  return parsed;
}

function printUsage() {
  console.log(
    "Usage: node tools/smoke/ppv_canonical_audit.mjs --eventId <id> --userId <id> [--projectId <id>] [--credentials <path-or-json>]",
  );
  console.log(
    "Verifies canonical Firebase PPV artifacts: ppv_purchases, ppv_access, optional legacy subcollection, and replay source resolution hints.",
  );
}

function loadCredentialFromValue(rawCredential) {
  if (!rawCredential) {
    return applicationDefault();
  }

  const trimmed = rawCredential.trim();
  if (!trimmed) {
    return applicationDefault();
  }

  if (trimmed.startsWith("{")) {
    return cert(JSON.parse(trimmed));
  }

  if (!fs.existsSync(trimmed)) {
    throw new Error(`Credential file not found: ${trimmed}`);
  }

  return cert(JSON.parse(fs.readFileSync(trimmed, "utf8")));
}

function resolveProjectId(cliProjectId) {
  if (cliProjectId) {
    return cliProjectId;
  }

  return (
    process.env.GOOGLE_CLOUD_PROJECT ||
    process.env.GCLOUD_PROJECT ||
    process.env.FIREBASE_PROJECT_ID ||
    undefined
  );
}

function getFirestoreValue(value) {
  if (!value) {
    return null;
  }

  if (typeof value.toDate === "function") {
    return value.toDate().toISOString();
  }

  if (value instanceof Date) {
    return value.toISOString();
  }

  return value;
}

function summarizeDoc(snapshot) {
  if (!snapshot.exists) {
    return null;
  }

  const data = snapshot.data();
  return {
    id: snapshot.id,
    ...Object.fromEntries(
      Object.entries(data).map(([key, value]) => [
        key,
        getFirestoreValue(value),
      ]),
    ),
  };
}

async function findPurchaseDocs(db, compositeId, userId, eventId) {
  const directDoc = await db.collection("ppv_purchases").doc(compositeId).get();
  if (directDoc.exists) {
    return [summarizeDoc(directDoc)];
  }

  const [canonicalQuery, legacyQuery] = await Promise.all([
    db
      .collection("ppv_purchases")
      .where("userId", "==", userId)
      .where("ppvId", "==", eventId)
      .limit(5)
      .get(),
    db
      .collection("ppv_purchases")
      .where("userId", "==", userId)
      .where("eventId", "==", eventId)
      .limit(5)
      .get(),
  ]);

  const merged = new Map();
  for (const doc of [...canonicalQuery.docs, ...legacyQuery.docs]) {
    merged.set(doc.id, summarizeDoc(doc));
  }

  return [...merged.values()];
}

async function findReplayHints(db, eventId) {
  const [eventDoc, ppvEventDoc, vaultVodDoc, streamSnap] = await Promise.all([
    db.collection("events").doc(eventId).get(),
    db.collection("ppv_events").doc(eventId).get(),
    db.collection("vault_vod").doc(eventId).get(),
    db
      .collection("mux_streams")
      .where("ppvEventId", "==", eventId)
      .limit(3)
      .get(),
  ]);

  return {
    event: summarizeDoc(eventDoc),
    ppvEvent: summarizeDoc(ppvEventDoc),
    vaultVod: summarizeDoc(vaultVodDoc),
    muxStreams: streamSnap.docs.map((doc) => summarizeDoc(doc)),
  };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help === "true" || !args.eventId || !args.userId) {
    printUsage();
    process.exit(args.help === "true" ? 0 : 1);
  }

  const projectId = resolveProjectId(args.projectId);
  const credentialValue =
    args.credentials || process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const credential = loadCredentialFromValue(credentialValue);

  const app =
    getApps().length > 0
      ? getApp()
      : initializeApp({ credential, ...(projectId ? { projectId } : {}) });

  const db = getFirestore(app);
  const compositeId = `${args.userId}_${args.eventId}`;

  const [topLevelAccessDoc, nestedAccessDoc, purchaseDocs, replayHints] =
    await Promise.all([
      db.collection("ppv_access").doc(compositeId).get(),
      db
        .collection("users")
        .doc(args.userId)
        .collection("ppv_access")
        .doc(args.eventId)
        .get(),
      findPurchaseDocs(db, compositeId, args.userId, args.eventId),
      findReplayHints(db, args.eventId),
    ]);

  const report = {
    runtime: "canonical-firebase-audit",
    projectId: projectId || app.options.projectId || null,
    eventId: args.eventId,
    userId: args.userId,
    checks: {
      topLevelPpvAccess: summarizeDoc(topLevelAccessDoc),
      legacyUserSubcollectionAccess: summarizeDoc(nestedAccessDoc),
      ppvPurchases: purchaseDocs,
      replayHints,
    },
  };

  console.log(JSON.stringify(report, null, 2));

  const hasTopLevelAccess = Boolean(report.checks.topLevelPpvAccess);
  const hasCompletedPurchase = purchaseDocs.some(
    (doc) => doc?.status === "completed" || doc?.accessGranted === true,
  );
  if (!hasTopLevelAccess || !hasCompletedPurchase) {
    process.exitCode = 2;
  }
}

try {
  await main();
} catch (error) {
  console.error(
    JSON.stringify(
      {
        runtime: "canonical-firebase-audit",
        error: error.message,
      },
      null,
      2,
    ),
  );
  process.exit(1);
}
