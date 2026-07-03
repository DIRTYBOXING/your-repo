import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const resultsDir = path.join(__dirname, "results");
const resultsFile = path.join(resultsDir, "ppv_drm_check.json");

function requiredEnv(name) {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new TypeError(`Missing required environment variable: ${name}`);
  }
  return value;
}

function optionalEnv(name) {
  const value = process.env[name]?.trim();
  return value || null;
}

function normalizeBaseUrl(url) {
  return url.replace(/\/+$/, "");
}

function toAcceptedStatuses(rawStatuses, fallback) {
  const raw = rawStatuses?.trim();
  if (!raw) {
    return fallback;
  }
  return raw
    .split(",")
    .map((value) => Number(value.trim()))
    .filter((value) => Number.isInteger(value));
}

async function ensureResultsDir() {
  await fs.mkdir(resultsDir, { recursive: true });
}

async function writeReport(report) {
  await ensureResultsDir();
  await fs.writeFile(resultsFile, `${JSON.stringify(report, null, 2)}\n`, "utf8");
}

async function fetchWithTimeout(url, options = {}, timeoutMs = 10000) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } finally {
    clearTimeout(timeout);
  }
}

async function checkManifest(manifestUrl) {
  const response = await fetchWithTimeout(manifestUrl, { method: "HEAD" }, 10000);
  return {
    status: response.status,
    ok: response.ok,
    contentType: response.headers.get("content-type"),
  };
}

async function issueDrmToken(functionsBaseUrl, firebaseIdToken, eventId, device) {
  const response = await fetchWithTimeout(
    `${normalizeBaseUrl(functionsBaseUrl)}/drmTokenApi`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${firebaseIdToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        eventId,
        device,
        scope: "playback",
      }),
    },
    10000,
  );

  const raw = await response.text();
  let body = null;
  try {
    body = JSON.parse(raw);
  } catch {
    body = { raw };
  }

  return {
    status: response.status,
    ok: response.ok,
    body,
  };
}

async function issueCdnToken(functionsBaseUrl, firebaseIdToken, assetUrl) {
  const response = await fetchWithTimeout(
    `${normalizeBaseUrl(functionsBaseUrl)}/cdnTokenApi`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${firebaseIdToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        assetUrl,
        ttlSeconds: 900,
      }),
    },
    10000,
  );

  const raw = await response.text();
  let body = null;
  try {
    body = JSON.parse(raw);
  } catch {
    body = { raw };
  }

  return {
    status: response.status,
    ok: response.ok,
    body,
  };
}

async function probeLicense(probeConfig, drmToken) {
  if (!probeConfig.url) {
    return {
      skipped: true,
      reason: "LICENSE_PROBE_URL not set",
    };
  }

  const method = probeConfig.method ?? "HEAD";
  const acceptedStatuses = probeConfig.acceptedStatuses;
  const headers = {
    Authorization: `Bearer ${drmToken}`,
    ...(probeConfig.contentType
      ? { "Content-Type": probeConfig.contentType }
      : {}),
  };
  const body = probeConfig.bodyBase64
    ? Buffer.from(probeConfig.bodyBase64, "base64")
    : undefined;

  const response = await fetchWithTimeout(
    probeConfig.url,
    {
      method,
      headers,
      body,
    },
    10000,
  );

  return {
    skipped: false,
    status: response.status,
    ok: acceptedStatuses.includes(response.status),
  };
}

async function run() {
  const functionsBaseUrl = requiredEnv("FUNCTIONS_BASE_URL");
  const firebaseIdToken =
    optionalEnv("FIREBASE_ID_TOKEN") ?? requiredEnv("TEST_ENTITLEMENT_TOKEN");
  const eventId = requiredEnv("EVENT_ID");
  const manifestUrl = requiredEnv("MANIFEST_URL");
  const assetUrl = optionalEnv("CDN_ASSET_URL");
  const device = optionalEnv("SYNTHETIC_DEVICE") ?? "synthetic-monitor";

  const report = {
    startedAt: new Date().toISOString(),
    inputs: {
      functionsBaseUrl,
      eventId,
      manifestUrl,
      hasCdnAssetUrl: Boolean(assetUrl),
      hasLicenseProbeUrl: Boolean(optionalEnv("LICENSE_PROBE_URL")),
    },
  };

  try {
    report.manifest = await checkManifest(manifestUrl);
    if (!report.manifest.ok) {
      throw new Error(`Manifest check failed with status ${report.manifest.status}`);
    }

    report.drmToken = await issueDrmToken(
      functionsBaseUrl,
      firebaseIdToken,
      eventId,
      device,
    );
    if (!report.drmToken.ok || !report.drmToken.body?.token) {
      throw new Error(
        `DRM token issuance failed with status ${report.drmToken.status}`,
      );
    }

    if (assetUrl) {
      report.cdnToken = await issueCdnToken(
        functionsBaseUrl,
        firebaseIdToken,
        assetUrl,
      );
      if (!report.cdnToken.ok || !report.cdnToken.body?.signedAssetUrl) {
        throw new Error(
          `CDN token issuance failed with status ${report.cdnToken.status}`,
        );
      }
    } else {
      report.cdnToken = {
        skipped: true,
        reason: "CDN_ASSET_URL not set",
      };
    }

    report.licenseProbe = await probeLicense(
      {
        url: optionalEnv("LICENSE_PROBE_URL"),
        method: optionalEnv("LICENSE_PROBE_METHOD") ?? "HEAD",
        contentType: optionalEnv("LICENSE_PROBE_CONTENT_TYPE"),
        bodyBase64: optionalEnv("LICENSE_PROBE_BODY_BASE64"),
        acceptedStatuses: toAcceptedStatuses(
          optionalEnv("LICENSE_PROBE_ACCEPT_STATUSES"),
          [200, 204],
        ),
      },
      report.drmToken.body.token,
    );
    if (report.licenseProbe.skipped !== true && !report.licenseProbe.ok) {
      throw new Error(
        `License probe failed with status ${report.licenseProbe.status}`,
      );
    }

    report.ok = true;
    report.finishedAt = new Date().toISOString();
    await writeReport(report);
    console.log(JSON.stringify(report, null, 2));
  } catch (error) {
    report.ok = false;
    report.finishedAt = new Date().toISOString();
    report.error = error instanceof Error ? error.message : String(error);
    await writeReport(report);
    console.error(JSON.stringify(report, null, 2));
    process.exit(2);
  }
}

await run();
