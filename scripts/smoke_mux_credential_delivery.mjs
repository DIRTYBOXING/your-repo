import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";
import admin from "firebase-admin";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..");
const envFile = path.join(repoRoot, ".env");
const callableBaseDefault =
  "https://australia-southeast1-datafightcentral.cloudfunctions.net";

function parseArgs(argv) {
  const options = {};
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (!arg.startsWith("--")) {
      continue;
    }

    const key = arg.slice(2);
    const nextValue = argv[index + 1];
    if (!nextValue || nextValue.startsWith("--")) {
      options[key] = "true";
      continue;
    }

    options[key] = nextValue;
    index += 1;
  }
  return options;
}

async function loadEnvFile(filePath) {
  try {
    const raw = await fs.readFile(filePath, "utf8");
    for (const line of raw.split(/\r?\n/)) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith("#")) {
        continue;
      }

      const separatorIndex = trimmed.indexOf("=");
      if (separatorIndex <= 0) {
        continue;
      }

      const key = trimmed.slice(0, separatorIndex).trim();
      if (!key || process.env[key]) {
        continue;
      }

      let value = trimmed.slice(separatorIndex + 1).trim();
      if (
        value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'")))
      ) {
        value = value.slice(1, -1);
      }

      process.env[key] = value;
    }
  } catch (error) {
    if (error.code !== "ENOENT") {
      throw error;
    }
  }
}

async function ensureAdmin() {
  await loadEnvFile(envFile);
  if (!admin.apps.length) {
    admin.initializeApp();
  }
  return admin.firestore();
}

function buildTimestampKey() {
  return new Date().toISOString().replace(/[.:]/g, "-");
}

function baseUrl(value) {
  return (value || callableBaseDefault).replace(/\/+$/, "");
}

async function callCallable(callableBase, functionName, payload) {
  const response = await fetch(`${baseUrl(callableBase)}/${functionName}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ data: payload }),
  });

  const responseText = await response.text();
  let responseJson;
  try {
    responseJson = JSON.parse(responseText);
  } catch {
    throw new Error(
      `${functionName} returned a non-JSON response (${response.status}): ${responseText}`,
    );
  }

  if (!response.ok) {
    const message =
      responseJson?.error?.message ||
      responseJson?.error ||
      `HTTP ${response.status}`;
    throw new Error(`${functionName} failed: ${message}`);
  }

  const result = responseJson.result ?? responseJson;
  if (result?.error) {
    throw new Error(`${functionName} failed: ${result.error}`);
  }

  return result;
}

async function seedSmokeDocuments({
  db,
  promoterId,
  recipient,
  eventId,
  ppvEventId,
  title,
}) {
  const now = new Date();
  const serverTimestamp = admin.firestore.FieldValue.serverTimestamp();

  await db
    .collection("users")
    .doc(promoterId)
    .set(
      {
        email: recipient,
        displayName: "DFC Smoke Promoter",
        username: promoterId,
        role: "promoter",
        emailVerified: true,
        onboardingCompleted: true,
        businessVerified: true,
        isActive: true,
        updatedAt: serverTimestamp,
        createdAt: serverTimestamp,
        metadata: {
          smokeScript: true,
        },
      },
      { merge: true },
    );

  await db.collection("events").doc(eventId).set(
    {
      promoterId,
      name: title,
      description: "Smoke verification lane for PPV credential delivery.",
      venue: "DFC Control Room Test Rig",
      city: "Melbourne",
      state: "Victoria",
      country: "Australia",
      eventDate: now,
      mainCardTime: now,
      promotionName: "DFC Smoke Tests",
      sportType: "boxing",
      status: "upcoming",
      source: "smoke_script",
      updatedAt: serverTimestamp,
      createdAt: serverTimestamp,
    },
    { merge: true },
  );

  await db
    .collection("ppv_events")
    .doc(ppvEventId)
    .set(
      {
        eventId,
        promoterId,
        promoterEmail: recipient,
        promoterName: "DFC Smoke Promoter",
        title,
        description: "Smoke verification lane for Mux credential delivery.",
        promotion: "DFC Smoke Tests",
        sport: "boxing",
        eventDate: now,
        standardPriceCents: 2999,
        currency: "AUD",
        status: "announced",
        streamPlatforms: ["DFC"],
        updatedAt: serverTimestamp,
        createdAt: serverTimestamp,
      },
      { merge: true },
    );
}

async function readDeliverySnapshot(db, streamDocId) {
  const streamDoc = await db.collection("mux_streams").doc(streamDocId).get();
  if (!streamDoc.exists) {
    throw new Error(`mux_streams/${streamDocId} was not created`);
  }

  const data = streamDoc.data() || {};
  return {
    streamDocId,
    ppvEventId: data.ppvEventId || null,
    credentialDeliveryStatus: data.credentialDeliveryStatus || "unknown",
    credentialDeliveryRecipient: data.credentialDeliveryRecipient || null,
    credentialDeliveryError: data.credentialDeliveryError || null,
    playbackId: data.muxPlaybackId || null,
    latencyMode: data.latencyMode || null,
  };
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const timestampKey = buildTimestampKey();
  const callableBase = options.base || callableBaseDefault;
  const recipient = options.recipient || "info@datafightcentral.com";
  const promoterId = options.promoterId || `smoke-promoter-${timestampKey}`;
  const eventId = options.eventId || `smoke-event-${timestampKey}`;
  const ppvEventId = options.ppvEventId || `smoke-ppv-${timestampKey}`;
  const title = options.title || `DFC Credential Flow Smoke ${timestampKey}`;

  const db = await ensureAdmin();

  await seedSmokeDocuments({
    db,
    promoterId,
    recipient,
    eventId,
    ppvEventId,
    title,
  });

  const createResult = await callCallable(callableBase, "createMuxLiveStream", {
    ppvEventId,
    title,
    lowLatency: true,
    testMode: true,
  });

  const initialSnapshot = await readDeliverySnapshot(
    db,
    createResult.streamDocId,
  );

  const resendResult = await callCallable(
    callableBase,
    "resendMuxCredentialPack",
    { streamDocId: createResult.streamDocId },
  );

  const finalSnapshot = await readDeliverySnapshot(
    db,
    createResult.streamDocId,
  );

  const summary = {
    callableBase,
    recipient,
    promoterId,
    eventId,
    ppvEventId,
    createResult: {
      streamDocId: createResult.streamDocId,
      credentialDeliveryStatus: createResult.credentialDeliveryStatus,
      credentialDeliveryRecipient: createResult.credentialDeliveryRecipient,
      credentialDeliveryError: createResult.credentialDeliveryError || null,
      playbackId: createResult.playbackId || null,
    },
    initialSnapshot,
    resendResult,
    finalSnapshot,
  };

  console.log(JSON.stringify(summary, null, 2));

  if (finalSnapshot.credentialDeliveryStatus !== "sent") {
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error(error.message || error);
  process.exitCode = 1;
});
