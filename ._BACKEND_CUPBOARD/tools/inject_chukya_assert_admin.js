// tools/inject_chukya_assert_admin.js
// Node 18+ script. Uses Firebase Admin SDK to assert Firestore state after injections.
// Supports service account file (local) and ADC via Workload Identity (CI).
import fs from "fs/promises";
import fetch from "node-fetch";
import admin from "firebase-admin";

const API_BASE = process.env.API_BASE || "https://staging-api.example.com";
const TEST_TOKEN = process.env.TEST_TOKEN || "";
const SERVICE_ACCOUNT_PATH =
  process.env.SERVICE_ACCOUNT_PATH || "/tmp/service-account.json";
const FIREBASE_PROJECT = process.env.FIREBASE_PROJECT || "staging";
const FILES = [
  "test_fingerprint_high.json",
  "test_fingerprint_medium.json",
  "test_fingerprint_low.json",
];
const LOG = (s) => console.log(new Date().toISOString(), s);

if (!TEST_TOKEN) {
  LOG("ERROR: TEST_TOKEN not set");
  process.exit(2);
}

async function initAdmin() {
  // If service account file exists, use it; otherwise rely on ADC (Workload Identity / gcloud)
  try {
    await fs.stat(SERVICE_ACCOUNT_PATH);
    const key = JSON.parse(await fs.readFile(SERVICE_ACCOUNT_PATH, "utf8"));
    admin.initializeApp({
      credential: admin.credential.cert(key),
      projectId: FIREBASE_PROJECT,
    });
    LOG("Initialized Admin SDK with service account file");
  } catch (e) {
    // fallback to ADC
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId: FIREBASE_PROJECT,
    });
    LOG("Initialized Admin SDK with Application Default Credentials");
  }
  return admin.firestore();
}

async function callInject(file) {
  const body = await fs.readFile(file, "utf8");
  const res = await fetch(`${API_BASE}/chukya/test/inject_scan`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${TEST_TOKEN}`,
      "Content-Type": "application/json",
    },
    body,
  });
  const text = await res.text();
  let json = null;
  try {
    json = JSON.parse(text);
  } catch (e) {
    /* non-JSON response */
  }
  return { status: res.status, body: json, raw: text };
}

async function queryAlertsByRunId(db, runId) {
  const snaps = await db
    .collection("proximity_alerts")
    .where("testRunId", "==", runId)
    .get();
  return snaps.docs.map((d) => ({ id: d.id, data: d.data() }));
}

async function queryPoliceByRunId(db, runId) {
  const snaps = await db
    .collection("police_notifications")
    .where("testRunId", "==", runId)
    .get();
  return snaps.docs.map((d) => ({ id: d.id, data: d.data() }));
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}
function isNumber(v) {
  return typeof v === "number" && !Number.isNaN(v) && Number.isFinite(v);
}

async function assertFieldLevel(alert, expected) {
  const errors = [];
  if (!alert) {
    errors.push("alert is null");
    return errors;
  }
  const victimId = alert.data.victimId;
  const mode = alert.data.mode;
  const est = alert.data.estimatedDistanceMeters;

  if (victimId !== expected.victimId) {
    errors.push(
      `victimId mismatch: expected ${expected.victimId} got ${victimId}`,
    );
  }
  if (mode !== expected.mode) {
    errors.push(`mode mismatch: expected ${expected.mode} got ${mode}`);
  }
  if (!isNumber(est)) {
    errors.push(`estimatedDistanceMeters missing or not a number: ${est}`);
  } else {
    // sanity range check: 0.1m to 1000m
    if (est < 0.1 || est > 1000) {
      errors.push(`estimatedDistanceMeters out of expected range: ${est}`);
    }
  }
  return errors;
}

async function main() {
  const db = await initAdmin();
  let fail = false;

  for (const f of FILES) {
    LOG(`Processing ${f}`);
    const exists = await fs
      .stat(f)
      .then(() => true)
      .catch(() => false);
    if (!exists) {
      LOG(`MISSING: ${f}`);
      fail = true;
      continue;
    }

    const payload = JSON.parse(await fs.readFile(f, "utf8"));
    const runId = payload.meta?.testRunId || `run-${Date.now()}`;
    const expectedVictimId = payload.meta?.victimId || null;
    const expectedMode = payload.meta?.mode || null;

    const injectResp = await callInject(f);
    LOG(`HTTP ${injectResp.status} response for ${f}`);
    LOG(JSON.stringify(injectResp.body || injectResp.raw).slice(0, 1000));

    // wait for Firestore writes to propagate with retries
    let alerts = [];
    let police = [];
    const maxRetries = 10;
    for (let i = 0; i < maxRetries; i++) {
      alerts = await queryAlertsByRunId(db, runId);
      police = await queryPoliceByRunId(db, runId);
      if (alerts.length > 0 || police.length > 0) break;
      await sleep(2000);
    }

    if (f.includes("high")) {
      if (alerts.length === 0) {
        LOG(`ASSERT FAIL: expected proximity_alert for high runId ${runId}`);
        fail = true;
      } else {
        const alert = alerts[0];
        const conf = alert.data.confidence;
        if (typeof conf !== "number" || conf < 0.8) {
          LOG(`ASSERT FAIL: confidence ${conf} < 0.8 for ${runId}`);
          fail = true;
        } else {
          LOG(`PASS: high test produced alert with confidence ${conf}`);
        }
        // Field level assertions
        const fieldErrors = await assertFieldLevel(alert, {
          victimId: expectedVictimId,
          mode: expectedMode,
        });
        if (fieldErrors.length > 0) {
          LOG(
            `ASSERT FAIL: field-level errors for ${runId}: ${fieldErrors.join("; ")}`,
          );
          fail = true;
        } else {
          LOG(`PASS: field-level checks passed for ${runId}`);
        }
      }
      if (police.length > 0)
        LOG(`INFO: police_notifications found for ${runId}`);
      else LOG(`INFO: no police_notifications for ${runId} (may be paused)`);
    } else if (f.includes("medium")) {
      if (alerts.length === 0) {
        LOG(`PASS: medium test produced no proximity_alert (acceptable)`);
      } else {
        const alert = alerts[0];
        const conf = alert.data.confidence;
        if (typeof conf === "number" && conf < 0.8) {
          LOG(
            `PASS: medium test produced alert with confidence ${conf} (<0.8)`,
          );
          const fieldErrors = await assertFieldLevel(alert, {
            victimId: expectedVictimId,
            mode: expectedMode,
          });
          if (fieldErrors.length > 0) {
            LOG(
              `WARN: medium alert field-level warnings: ${fieldErrors.join("; ")}`,
            );
          } else {
            LOG(`INFO: medium alert field-level checks passed`);
          }
        } else {
          LOG(
            `ASSERT FAIL: medium test produced alert with confidence >= 0.8 for ${runId}`,
          );
          fail = true;
        }
      }
    } else {
      // low
      if (alerts.length > 0) {
        LOG(
          `ASSERT FAIL: low test unexpectedly produced proximity_alert for ${runId}`,
        );
        fail = true;
      } else {
        LOG(`PASS: low test produced no proximity_alert`);
      }
      if (police.length > 0) {
        LOG(
          `ASSERT FAIL: low test unexpectedly produced police_notifications for ${runId}`,
        );
        fail = true;
      } else {
        LOG(`PASS: low test produced no police_notifications`);
      }
    }
    LOG("---");
  }

  if (fail) {
    LOG("One or more assertions failed");
    process.exit(1);
  } else {
    LOG("All assertions passed");
    process.exit(0);
  }
}

main().catch((err) => {
  console.error("Fatal error", err);
  process.exit(2);
});
