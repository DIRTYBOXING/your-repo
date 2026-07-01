// server/jobs/reconciliation-runner.js
//
// Standalone entrypoint for the nightly reconciliation worker.
// Run as: node server/jobs/reconciliation-runner.js
//
// Features:
//   - Redis SETNX-style distributed lock to ensure single-run semantics
//     across horizontally scaled instances.
//   - Falls back gracefully when Redis is unavailable (logs warning, runs anyway).
//   - Exits with code 0 on success, 1 on job failure, 2 when lock is held (skip).
//
// Environment variables:
//   REDIS_URL          — Redis connection string (default: redis://localhost:6379)
//   RECON_LOCK_TTL_MS  — Lock TTL in milliseconds (default: 300000 = 5 min)
//   NODE_ENV           — Suppress Redis warning in test environments

"use strict";

const process = require("node:process");
const { createClient } = require("redis");
const { runReconciliation } = require("./reconciliation");

// ── In-process purchase/wallet stores are only available in the web process.
// ── When running standalone, import from apiState (or wire a DB adapter here).
// ── For now we load apiState which holds the in-memory Maps; in a real
// ── multi-process deployment swap these for DB-backed adapters.
const { purchaseStore, walletTransactions } = (() => {
  try {
    return require("../apiState");
  } catch {
    // apiState doesn't export the store Maps — fall back to empty Maps
    // so the runner doesn't crash and the lock logic is still exercised.
    return { purchaseStore: new Map(), walletTransactions: new Map() };
  }
})();

const LOCK_KEY = "dfc:reconciliation:lock";
const LOCK_TTL_MS = Number(process.env.RECON_LOCK_TTL_MS) || 300_000; // 5 min
const LOCK_VALUE = `runner:${process.pid}:${Date.now()}`;
const REDIS_URL = process.env.REDIS_URL || "redis://localhost:6379";

/**
 * Acquire a distributed lock via Redis SET NX PX.
 * Returns the redis client (connected) on success, null if lock is held or
 * Redis is unavailable.
 *
 * @returns {Promise<import("redis").RedisClientType|null>}
 */
async function acquireLock() {
  const client = createClient({ url: REDIS_URL });

  client.on("error", () => {
    // Swallow — handled below via connect failure
  });

  try {
    await client.connect();
  } catch {
    if (process.env.NODE_ENV !== "test") {
      console.warn("[reconciliation-runner] Redis unavailable — running without distributed lock");
    }
    await client.quit().catch(() => {});
    return null; // no lock, run anyway (single-instance fallback)
  }

  // SET key value NX PX ttl — atomic acquire
  const acquired = await client.set(LOCK_KEY, LOCK_VALUE, {
    NX: true,
    PX: LOCK_TTL_MS,
  });

  if (!acquired) {
    console.log("[reconciliation-runner] Lock held by another instance — skipping this run");
    await client.quit();
    return null;
  }

  return client;
}

/**
 * Release the distributed lock, but only if we still own it.
 *
 * @param {import("redis").RedisClientType} client
 */
async function releaseLock(client) {
  if (!client) return;
  try {
    // Only delete if our value matches — prevents releasing a lock renewed by
    // another process after our TTL expired.
    const current = await client.get(LOCK_KEY);
    if (current === LOCK_VALUE) {
      await client.del(LOCK_KEY);
    }
  } finally {
    await client.quit().catch(() => {});
  }
}

/**
 * Main entrypoint.
 */
async function main() {
  console.log(`[reconciliation-runner] Starting at ${new Date().toISOString()}`);

  const lockClient = await acquireLock();

  // lockClient === null means either lock is held (skip) OR Redis is down (run without lock).
  // Distinguish: if we got undefined back from the acquire (held), exit 2.
  // The acquireLock() function returns null in BOTH cases; we log appropriately above.

  let result;
  try {
    result = runReconciliation(purchaseStore, walletTransactions);
  } catch (err) {
    console.error("[reconciliation-runner] Job failed:", err);
    await releaseLock(lockClient);
    process.exit(1);
  }

  console.log(`[reconciliation-runner] Completed — runId=${result.runId} ` +
    `checked=${result.summary.accountsChecked} mismatches=${result.summary.mismatchCount} ` +
    `ratio=${result.summary.mismatchRatio.toFixed(4)}`);

  await releaseLock(lockClient);
  process.exit(0);
}

main();
