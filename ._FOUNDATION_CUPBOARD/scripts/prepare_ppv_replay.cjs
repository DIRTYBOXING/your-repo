#!/usr/bin/env node
"use strict";

const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

function parseArgs(argv) {
  const args = {};
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith("--")) {
      continue;
    }

    const key = token.slice(2);
    const next = argv[index + 1];
    if (!next || next.startsWith("--")) {
      args[key] = "true";
      continue;
    }

    args[key] = next;
    index += 1;
  }
  return args;
}

function loadLocalEnv() {
  const envCandidates = [
    path.resolve(process.cwd(), ".env"),
    path.resolve(__dirname, "..", ".env"),
  ];

  for (const envPath of envCandidates) {
    if (!fs.existsSync(envPath)) {
      continue;
    }

    const lines = fs.readFileSync(envPath, "utf8").split(/\r?\n/);
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith("#")) {
        continue;
      }

      const separatorIndex = trimmed.indexOf("=");
      if (separatorIndex === -1) {
        continue;
      }

      const key = trimmed.slice(0, separatorIndex).trim();
      let value = trimmed.slice(separatorIndex + 1).trim();
      if (!key || process.env[key]) {
        continue;
      }

      if (
        (value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))
      ) {
        value = value.slice(1, -1);
      }

      process.env[key] = value;
    }

    return envPath;
  }

  return null;
}

function resolveFirebaseCredential() {
  const rawCredential = process.env.GOOGLE_APPLICATION_CREDENTIALS;

  if (!rawCredential) {
    return admin.credential.applicationDefault();
  }

  if (rawCredential.trim().startsWith("{")) {
    return admin.credential.cert(JSON.parse(rawCredential));
  }

  return admin.credential.cert(
    JSON.parse(fs.readFileSync(rawCredential, "utf8")),
  );
}

function normalizeBoolean(value) {
  return String(value || "").toLowerCase() === "true";
}

function inferReplayUrl(playbackId, replayUrl) {
  if (replayUrl) {
    return replayUrl;
  }

  if (!playbackId) {
    return null;
  }

  return `https://stream.mux.com/${playbackId}.m3u8`;
}

async function main() {
  loadLocalEnv();

  const args = parseArgs(process.argv.slice(2));
  const eventId = args.eventId || args.ppvId;
  const playbackId = args.playbackId || args.replayPlaybackId || "";
  const replayUrl = inferReplayUrl(playbackId, args.replayUrl || "");
  const replayPath = args.replayPath || "";
  const dryRun = normalizeBoolean(args.dryRun);
  const status = args.status || "replay";

  if (!eventId) {
    throw new Error("Missing required argument --eventId");
  }

  if (!playbackId && !replayUrl && !replayPath) {
    throw new Error(
      "Provide at least one of --playbackId, --replayUrl, or --replayPath",
    );
  }

  if (!admin.apps.length) {
    admin.initializeApp({
      credential: resolveFirebaseCredential(),
      storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
    });
  }

  const db = admin.firestore();
  const ppvEventRef = db.collection("ppv_events").doc(eventId);
  const vaultVodRef = db.collection("vault_vod").doc(eventId);

  const ppvEventSnap = await ppvEventRef.get();
  if (!ppvEventSnap.exists) {
    throw new Error(`ppv_events/${eventId} does not exist`);
  }

  const ppvEventUpdates = {
    replayAvailable: true,
    vodStatus: "ready",
    status,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    replayActivatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (replayUrl) {
    ppvEventUpdates.replayUrl = replayUrl;
  }
  if (playbackId) {
    ppvEventUpdates.replayPlaybackId = playbackId;
    ppvEventUpdates.muxPlaybackId = playbackId;
  }
  if (replayPath) {
    ppvEventUpdates.replayVideoPath = replayPath;
  }

  const vaultVodUpdates = {
    status: "active",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (playbackId) {
    vaultVodUpdates.vodPlaybackId = playbackId;
  }

  const summary = {
    eventId,
    dryRun,
    ppvEventUpdates: {
      ...ppvEventUpdates,
      updatedAt: "[serverTimestamp]",
      replayActivatedAt: "[serverTimestamp]",
    },
    vaultVodUpdates: {
      ...vaultVodUpdates,
      updatedAt: "[serverTimestamp]",
    },
  };

  console.log(JSON.stringify(summary, null, 2));

  if (dryRun) {
    console.log("Dry run only. No Firestore changes were written.");
    return;
  }

  await ppvEventRef.set(ppvEventUpdates, { merge: true });

  const vaultVodSnap = await vaultVodRef.get();
  if (vaultVodSnap.exists) {
    await vaultVodRef.set(vaultVodUpdates, { merge: true });
  }

  console.log(`Replay metadata ready for ${eventId}.`);
}

main().catch((error) => {
  console.error(`prepare_ppv_replay failed: ${error.message}`);
  process.exit(1);
});
