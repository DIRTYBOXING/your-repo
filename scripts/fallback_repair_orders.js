#!/usr/bin/env node
// scripts/fallback_repair_orders.js — Reconcile Stripe sessions with Firestore
// Run this if webhook delivery failed and orders are missing.
// Usage:
//   STRIPE_SECRET=sk_... node scripts/fallback_repair_orders.js
"use strict";

const admin = require("firebase-admin");
const Stripe = require("stripe");

const STRIPE_SECRET = process.env.STRIPE_SECRET;
if (!STRIPE_SECRET) {
  console.error("FATAL: STRIPE_SECRET env var required");
  process.exit(1);
}

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();
const stripe = new Stripe(STRIPE_SECRET, { apiVersion: "2022-11-15" });

async function repairOrders() {
  console.log("Scanning Stripe checkout sessions...");
  let repaired = 0;
  let skipped = 0;
  let hasMore = true;
  let startingAfter;

  while (hasMore) {
    const params = { limit: 100, status: "complete" };
    if (startingAfter) params.starting_after = startingAfter;

    const sessions = await stripe.checkout.sessions.list(params);

    for (const s of sessions.data) {
      const docRef = db.collection("ppv_orders").doc(s.id);
      const doc = await docRef.get();

      if (!doc.exists && s.payment_status === "paid") {
        await docRef.set({
          id: s.id,
          user_id: s.metadata?.user_id || "unknown",
          event_id: s.metadata?.event_id || "unknown",
          session_id: s.id,
          price_id: s.metadata?.price_id || "",
          status: "completed",
          email: s.customer_details?.email || "",
          amount_total: s.amount_total,
          currency: s.currency,
          created_at: new Date(s.created * 1000).toISOString(),
          repaired_at: new Date().toISOString(),
          source: "fallback_repair",
        });
        repaired++;
        console.log(`  ✓ Repaired: ${s.id} (${s.customer_details?.email})`);
      } else {
        skipped++;
      }
    }

    hasMore = sessions.has_more;
    if (sessions.data.length > 0) {
      startingAfter = sessions.data[sessions.data.length - 1].id;
    }
  }

  console.log(
    `\n✓ Repair complete — ${repaired} repaired, ${skipped} already existed`,
  );
}

repairOrders()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error("Repair failed:", e);
    process.exit(1);
  });
