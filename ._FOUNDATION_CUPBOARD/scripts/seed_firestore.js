#!/usr/bin/env node
// scripts/seed_firestore.js — Seed Firestore with baseline data for dev/demo
// Usage: node scripts/seed_firestore.js
"use strict";

const admin = require("firebase-admin");
if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

async function seed() {
  console.log("Seeding Firestore...");

  // Sample event
  await db.collection("events").doc("demo_event_001").set(
    {
      title: "DFC Fight Night: Demo Event",
      date: new Date().toISOString(),
      status: "active",
      location: "Melbourne, AU",
      description: "Demo fight card for development testing",
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  console.log("  ✓ events/demo_event_001");

  // Sample PPV config
  await db.collection("ppv_config").doc("demo_event_001").set(
    {
      event_id: "demo_event_001",
      price_aud: 9.99,
      early_bird_price_aud: 4.99,
      stripe_price_id: "price_PLACEHOLDER",
      active: true,
    },
    { merge: true },
  );
  console.log("  ✓ ppv_config/demo_event_001");

  // Sample fighters
  const fighters = [
    {
      id: "fighter_demo_001",
      name: "Demo Fighter A",
      record: "10-2-0",
      weight_class: "Welterweight",
    },
    {
      id: "fighter_demo_002",
      name: "Demo Fighter B",
      record: "8-3-1",
      weight_class: "Welterweight",
    },
  ];
  for (const f of fighters) {
    await db
      .collection("fighters")
      .doc(f.id)
      .set(
        {
          ...f,
          created_at: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    console.log(`  ✓ fighters/${f.id}`);
  }

  console.log("\n✓ Seed complete");
}

seed()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error("Seed failed:", e);
    process.exit(1);
  });
