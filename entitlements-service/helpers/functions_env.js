"use strict";

const DEFAULT_PROJECT_ID = "datafightcentral";
const DEFAULT_REGION = "australia-southeast1";
const EMULATOR_ENV_VARS = [
  "FUNCTIONS_EMULATOR",
  "FIREBASE_AUTH_EMULATOR_HOST",
  "FIRESTORE_EMULATOR_HOST",
  "FIREBASE_STORAGE_EMULATOR_HOST",
];

function readEnv(name) {
  const value = process.env[name];
  return typeof value === "string" ? value.trim() : "";
}

function parseFirebaseConfigProjectId() {
  const raw = readEnv("FIREBASE_CONFIG");
  if (!raw) return "";

  try {
    const parsed = JSON.parse(raw);
    return typeof parsed.projectId === "string" ? parsed.projectId.trim() : "";
  } catch {
    return "";
  }
}

function isEmulatorEnabled() {
  return EMULATOR_ENV_VARS.some((name) => {
    const value = readEnv(name);
    if (!value) return false;
    if (name === "FUNCTIONS_EMULATOR") {
      return value.toLowerCase() !== "false";
    }
    return true;
  });
}

function resolveProjectId() {
  return (
    readEnv("PPV_PROJECT_ID") ||
    readEnv("GOOGLE_CLOUD_PROJECT") ||
    readEnv("GCLOUD_PROJECT") ||
    parseFirebaseConfigProjectId() ||
    DEFAULT_PROJECT_ID
  );
}

function resolveRegion() {
  return readEnv("PPV_REGION") || DEFAULT_REGION;
}

function stripTrailingSlash(value) {
  return value.replace(/\/+$/, "");
}

function resolveBaseUrl() {
  const override = readEnv("PPV_FUNCTIONS_BASE_URL");
  if (override) {
    return stripTrailingSlash(override);
  }

  const projectId = resolveProjectId();
  const region = resolveRegion();

  if (isEmulatorEnabled()) {
    return `http://127.0.0.1:5001/${projectId}/${region}`;
  }

  return `https://${region}-${projectId}.cloudfunctions.net`;
}

function buildFunctionUrl(functionName) {
  if (!functionName) {
    throw new Error("functionName is required");
  }

  return `${resolveBaseUrl()}/${encodeURIComponent(functionName)}`;
}

module.exports = {
  buildFunctionUrl,
  isEmulatorEnabled,
  resolveBaseUrl,
  resolveProjectId,
  resolveRegion,
};
