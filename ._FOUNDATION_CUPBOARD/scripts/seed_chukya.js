#!/usr/bin/env node
// scripts/seed_chukya.js — Seed Firestore with Chukya 3.0 test data
// Usage: node scripts/seed_chukya.js
//
// Creates:
//   - settings/feature_flags (with chukya fields)
//   - threat_watchlist/{victimId}/profiles/{profileId}
//   - proximity_alerts/{alertId}
//   - safe_zones/{zoneId}
//   - evidence_vault/{victimId}/events/{eventId}
"use strict";

const crypto = require("crypto");
const admin = require("firebase-admin");
if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const Timestamp = admin.firestore.Timestamp;

// ── Helpers ─────────────────────────────────────────────────────────────

/** HMAC-SHA256 hash a phone number (mirrors Cloud Function logic). */
function hmacPhone(phone) {
  const secret = process.env.CHUKYA_HMAC_SECRET || "test-hmac-key-for-seeding";
  return crypto.createHmac("sha256", secret).update(phone).digest("hex");
}

// ── Seed Data ───────────────────────────────────────────────────────────

const VICTIM_UID = "victim_test_001";
const THREAT_PROFILE_ID = "tp_test_001";
const ALERT_ID = "alert_test_001";
const ALERT_ID_2 = "alert_test_002";
const SAFE_ZONE_ID = "sz_test_001";
const EVIDENCE_EVENT_ID = "ev_test_001";

async function seed() {
  console.log("🔒 Seeding Chukya 3.0 test data...\n");

  // ── 1. Feature flags ────────────────────────────────────────────────
  await db.doc("settings/feature_flags").set(
    {
      chukya_enabled: true,
      chukya_police_notifications_paused: false,
      chukya_scan_mode_override: null,
      updated_at: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  console.log("  ✓ settings/feature_flags (chukya fields merged)");

  // ── 2. Threat profile (as if police validated) ──────────────────────
  const hashedPhone = hmacPhone("+61400000001");
  await db
    .collection("threat_watchlist")
    .doc(VICTIM_UID)
    .collection("profiles")
    .doc(THREAT_PROFILE_ID)
    .set({
      victimUserId: VICTIM_UID,
      hashedPhoneId: hashedPhone,
      policeRefNumber: "QPS-2026-TEST-0001",
      offenderAlias: "Test Offender Alpha",
      restrainingDistanceMeters: 200,
      registeredAt: FieldValue.serverTimestamp(),
      expiresAt: Timestamp.fromDate(new Date("2027-03-26T00:00:00Z")),
      policeValidated: true,
      deviceFingerprint: {
        manufacturerHash: crypto
          .createHash("sha256")
          .update("Samsung")
          .digest("hex")
          .slice(0, 16),
        deviceNamePrefix: "Galaxy",
        rssiHistogram: [-70, -68, -72, -69, -71],
      },
      status: "active",
    });
  console.log(
    `  ✓ threat_watchlist/${VICTIM_UID}/profiles/${THREAT_PROFILE_ID}`,
  );

  // ── 3. Proximity alerts ─────────────────────────────────────────────
  await db
    .collection("proximity_alerts")
    .doc(ALERT_ID)
    .set({
      victimUserId: VICTIM_UID,
      threatProfileId: THREAT_PROFILE_ID,
      policeRefNumber: "QPS-2026-TEST-0001",
      estimatedDistanceMeters: 45.3,
      confidence: 0.87,
      latitude: -27.4698,
      longitude: 153.0251,
      scanMode: "travelRadar",
      threatLevel: "high",
      status: "active",
      detectedAt: FieldValue.serverTimestamp(),
      signalData: {
        rssi: -65,
        manufacturer: "Samsung",
        deviceName: "Galaxy S24",
      },
    });
  console.log(`  ✓ proximity_alerts/${ALERT_ID} (high confidence)`);

  await db
    .collection("proximity_alerts")
    .doc(ALERT_ID_2)
    .set({
      victimUserId: VICTIM_UID,
      threatProfileId: THREAT_PROFILE_ID,
      policeRefNumber: "QPS-2026-TEST-0001",
      estimatedDistanceMeters: 180.0,
      confidence: 0.42,
      latitude: -27.471,
      longitude: 153.023,
      scanMode: "stealthSentinel",
      threatLevel: "low",
      status: "monitoring",
      detectedAt: FieldValue.serverTimestamp(),
      signalData: {
        rssi: -82,
        manufacturer: "Unknown",
        deviceName: null,
      },
    });
  console.log(`  ✓ proximity_alerts/${ALERT_ID_2} (low confidence)`);

  // ── 4. Safe zone ────────────────────────────────────────────────────
  await db.collection("safe_zones").doc(SAFE_ZONE_ID).set({
    userId: VICTIM_UID,
    name: "Home — Test Safe Zone",
    latitude: -27.4705,
    longitude: 153.026,
    radiusMeters: 200,
    active: true,
    createdAt: FieldValue.serverTimestamp(),
  });
  console.log(`  ✓ safe_zones/${SAFE_ZONE_ID}`);

  // ── 5. Evidence vault entry ─────────────────────────────────────────
  await db
    .collection("evidence_vault")
    .doc(VICTIM_UID)
    .collection("events")
    .doc(EVIDENCE_EVENT_ID)
    .set({
      alertId: ALERT_ID,
      policeRefNumber: "QPS-2026-TEST-0001",
      capturedAt: FieldValue.serverTimestamp(),
      location: { latitude: -27.4698, longitude: 153.0251 },
      signalSnapshot: {
        rssi: -65,
        manufacturer: "Samsung",
        deviceName: "Galaxy S24",
        scanMode: "travelRadar",
      },
      metadata: {
        appVersion: "1.0.0",
        osVersion: "Android 15",
        deviceModel: "Pixel 9",
      },
      chainOfCustody: [
        {
          action: "captured",
          timestamp: new Date().toISOString(),
          actor: "system",
        },
      ],
    });
  console.log(`  ✓ evidence_vault/${VICTIM_UID}/events/${EVIDENCE_EVENT_ID}`);

  // ── Summary ─────────────────────────────────────────────────────────
  console.log("\n✓ Chukya 3.0 seed complete. Collections populated:");
  console.log("  - settings/feature_flags");
  console.log(`  - threat_watchlist/${VICTIM_UID}/profiles (1 profile)`);
  console.log("  - proximity_alerts (2 alerts: high + low confidence)");
  console.log("  - safe_zones (1 zone)");
  console.log(`  - evidence_vault/${VICTIM_UID}/events (1 event)`);
  console.log("\nVictim UID for testing:", VICTIM_UID);
  console.log("Police ref for testing: QPS-2026-TEST-0001");
}

seed()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error("Chukya seed failed:", e);
    process.exit(1);
  });
