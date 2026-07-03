#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const path = require("node:path");
const admin = require("firebase-admin");

function printUsage(error, exitCode = 0) {
  const stream = exitCode === 0 ? process.stdout : process.stderr;
  if (error) {
    stream.write(`Error: ${error}\n\n`);
  }

  stream.write(
    [
      "Usage:",
      String.raw`  npm run upload:event-poster -- --file "C:\path\poster.jpg" --event-id ufc_fight_night_della_prates_2026_05_02`,
      String.raw`  npm run upload:event-poster -- --file "C:\path\poster.jpg" --event-id ufc_fight_night_della_prates_2026_05_02 --seed-file data/ufc_fight_night_della_prates_2026.seed.json`,
      "",
      "Required environment:",
      "  GOOGLE_APPLICATION_CREDENTIALS",
      "  FIREBASE_STORAGE_BUCKET",
    ].join("\n"),
  );

  process.exit(exitCode);
}

function parseArgs(argv) {
  const args = {
    file: null,
    eventId: null,
    seedFile: null,
    remotePath: null,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];

    if (token === "--file" || token === "-f") {
      args.file = argv[index + 1] || null;
      index += 1;
      continue;
    }
    if (token === "--event-id" || token === "-e") {
      args.eventId = argv[index + 1] || null;
      index += 1;
      continue;
    }
    if (token === "--seed-file" || token === "-s") {
      args.seedFile = argv[index + 1] || null;
      index += 1;
      continue;
    }
    if (token === "--remote-path" || token === "-r") {
      args.remotePath = argv[index + 1] || null;
      index += 1;
      continue;
    }
    if (token === "--help" || token === "-h") {
      printUsage(undefined, 0);
    }

    printUsage(`Unknown argument: ${token}`, 1);
  }

  if (!args.file) {
    printUsage("Missing required --file argument.", 1);
  }
  if (!args.eventId && !args.remotePath) {
    printUsage("Provide either --event-id or --remote-path.", 1);
  }

  return args;
}

function requireEnv(name) {
  const value = process.env[name];
  if (!value?.trim()) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value.trim();
}

function normalizeEnvValue(value) {
  if (
    (value.startsWith('"') && value.endsWith('"')) ||
    (value.startsWith("'") && value.endsWith("'"))
  ) {
    return value.slice(1, -1);
  }

  return value;
}

function parseEnvFile(envPath) {
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
    const rawValue = trimmed.slice(separatorIndex + 1).trim();
    if (!key || process.env[key]) {
      continue;
    }

    process.env[key] = normalizeEnvValue(rawValue);
  }
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

    parseEnvFile(envPath);
    return envPath;
  }

  return null;
}

function resolveFirebaseCredential() {
  const rawCredential = requireEnv("GOOGLE_APPLICATION_CREDENTIALS");
  if (rawCredential.startsWith("{")) {
    return admin.credential.cert(JSON.parse(rawCredential));
  }

  return admin.credential.cert(
    JSON.parse(fs.readFileSync(rawCredential, "utf8")),
  );
}

function resolveExistingFile(filePath, label) {
  const absolutePath = path.resolve(process.cwd(), filePath);
  if (!fs.existsSync(absolutePath)) {
    throw new Error(`${label} not found: ${absolutePath}`);
  }
  return absolutePath;
}

function contentTypeForExtension(extension) {
  switch (extension.toLowerCase()) {
    case ".jpg":
    case ".jpeg":
      return "image/jpeg";
    case ".png":
      return "image/png";
    case ".webp":
      return "image/webp";
    default:
      return "application/octet-stream";
  }
}

function buildRemotePath(localPath, eventId, explicitRemotePath) {
  if (explicitRemotePath) {
    return explicitRemotePath.replaceAll("\\", "/");
  }

  const extension = path.extname(localPath) || ".jpg";
  return `events/${eventId}/poster${extension.toLowerCase()}`;
}

function loadSeedFile(seedFile) {
  const absolutePath = resolveExistingFile(seedFile, "Seed file");
  const raw = fs.readFileSync(absolutePath, "utf8");
  return { absolutePath, data: JSON.parse(raw) };
}

function patchSeedPosterUrls(seedData, publicUrl) {
  if (seedData.event && typeof seedData.event === "object") {
    seedData.event.posterUrl = publicUrl;
    seedData.event.thumbnailUrl = publicUrl;
    seedData.event.bannerUrl = publicUrl;
  }

  if (seedData.ppv && typeof seedData.ppv === "object") {
    seedData.ppv.posterUrl = publicUrl;
  }

  return seedData;
}

async function uploadPoster(localFile, remotePath) {
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: resolveFirebaseCredential(),
      storageBucket: requireEnv("FIREBASE_STORAGE_BUCKET"),
    });
  }

  const bucket = admin.storage().bucket();
  const extension = path.extname(localFile);
  const contentType = contentTypeForExtension(extension);

  await bucket.upload(localFile, {
    destination: remotePath,
    metadata: {
      contentType,
      cacheControl: "public,max-age=3600",
    },
  });

  const file = bucket.file(remotePath);
  await file.makePublic();
  return `https://storage.googleapis.com/${bucket.name}/${remotePath}`;
}

async function main() {
  loadLocalEnv();
  requireEnv("GOOGLE_APPLICATION_CREDENTIALS");
  requireEnv("FIREBASE_STORAGE_BUCKET");

  const args = parseArgs(process.argv.slice(2));
  const localFile = resolveExistingFile(args.file, "Poster file");
  const remotePath = buildRemotePath(localFile, args.eventId, args.remotePath);
  const publicUrl = await uploadPoster(localFile, remotePath);

  console.log(`Uploaded poster to ${remotePath}`);
  console.log(`Public URL: ${publicUrl}`);

  if (args.seedFile) {
    const seed = loadSeedFile(args.seedFile);
    const patchedSeed = patchSeedPosterUrls(seed.data, publicUrl);
    fs.writeFileSync(
      seed.absolutePath,
      `${JSON.stringify(patchedSeed, null, 2)}\n`,
    );
    console.log(`Patched seed file: ${seed.absolutePath}`);
  }
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
