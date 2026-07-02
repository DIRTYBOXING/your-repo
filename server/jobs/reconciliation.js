// server/jobs/reconciliation.js
// Nightly wallet reconciliation job.
//
// Compares the sum of all purchases (purchaseStore) against the sum of all
// wallet debits (walletLedger) for each userId and flags discrepancies.
//
// Can be triggered:
//   - Manually via  POST /api/admin/reconciliation/run
//   - On a schedule via cron (configure outside this module)
//
// Emits Prometheus metrics:
//   dfc_wallet_reconciliation_mismatch_ratio
//   dfc_wallet_reconciliation_runs_total
//   dfc_wallet_reconciliation_mismatch_cents

"use strict";

const { v4: uuid } = require("uuid");
const { reconciliationRuns, reconciliationMismatches } = require("../apiState");
const { ppvCommerceMetrics } = require("../monitoring/server/metrics");

// Maximum mismatches stored per run (memory guard for dev environment)
const MAX_MISMATCHES_PER_RUN = 500;
// Minimum absolute discrepancy (cents) to be flagged as a mismatch
const MISMATCH_THRESHOLD_CENTS = 1;

/** Aggregate total paid purchase cents per userId from purchaseStore. */
function aggregatePurchaseTotals(purchaseStore) {
  const totals = new Map();
  for (const purchase of purchaseStore.values()) {
    if (!purchase?.userId || purchase.status !== "paid") continue;
    if (purchase.provider !== "wallet") continue;
    const cents = Number(purchase.amountCents || 0);
    totals.set(purchase.userId, (totals.get(purchase.userId) || 0) + cents);
  }
  return totals;
}

/** Aggregate total debit cents per userId from walletTransactions. */
function aggregateWalletDebits(walletTransactions) {
  const totals = new Map();
  for (const tx of walletTransactions.values()) {
    if (!tx?.userId || tx.type !== "debit") continue;
    const cents = Number(tx.amountCents || 0);
    totals.set(tx.userId, (totals.get(tx.userId) || 0) + cents);
  }
  return totals;
}

/**
 * Run one reconciliation pass.
 *
 * @param {Map} purchaseStore       - purchaseId → { userId, amountCents, status }
 * @param {Map} walletTransactions  - txId → { userId, type, amountCents }
 * @returns {{ runId: string, summary: object, mismatches: object[] }}
 */
function runReconciliation(purchaseStore, walletTransactions) {
  const runId = uuid();
  const startedAt = new Date().toISOString();

  const purchaseTotalsByUser = aggregatePurchaseTotals(purchaseStore);
  const walletSpendByUser = aggregateWalletDebits(walletTransactions);

  // --- Identify mismatches ---
  const checkedUsers = new Set([
    ...purchaseTotalsByUser.keys(),
    ...walletSpendByUser.keys(),
  ]);

  const mismatches = [];
  let totalDiscrepancyCents = 0;

  for (const userId of checkedUsers) {
    const purchaseTotal = purchaseTotalsByUser.get(userId) || 0;
    const walletSpend = walletSpendByUser.get(userId) || 0;
    const discrepancy = Math.abs(purchaseTotal - walletSpend);

    if (discrepancy >= MISMATCH_THRESHOLD_CENTS) {
      totalDiscrepancyCents += discrepancy;
      const mismatch = {
        id: uuid(),
        runId,
        userId,
        purchaseTotalCents: purchaseTotal,
        walletSpendCents: walletSpend,
        discrepancyCents: discrepancy,
        direction: purchaseTotal > walletSpend ? "purchase_excess" : "wallet_excess",
        status: "open",
        detectedAt: new Date().toISOString(),
        resolvedAt: null,
        resolvedBy: null,
        notes: null,
      };
      mismatches.push(mismatch);

      if (mismatches.length <= MAX_MISMATCHES_PER_RUN) {
        reconciliationMismatches.set(mismatch.id, mismatch);
      }
    }
  }

  const mismatchCount = mismatches.length;
  const accountsChecked = checkedUsers.size;
  const mismatchRatio = accountsChecked > 0 ? mismatchCount / accountsChecked : 0;

  const completedAt = new Date().toISOString();
  const runRecord = {
    runId,
    status: "completed",
    startedAt,
    completedAt,
    accountsChecked,
    mismatchCount,
    mismatchRatio,
    totalDiscrepancyCents,
    truncated: mismatches.length > MAX_MISMATCHES_PER_RUN,
  };

  reconciliationRuns.set(runId, runRecord);

  // Emit Prometheus metrics
  ppvCommerceMetrics.walletReconciliationMismatchRatio.set({ run_id: runId }, mismatchRatio);
  ppvCommerceMetrics.walletReconciliationMismatchCents.set({ run_id: runId }, totalDiscrepancyCents);
  ppvCommerceMetrics.walletReconciliationRunsTotal.inc({ status: "completed" });

  return { runId, summary: runRecord, mismatches: mismatches.slice(0, MAX_MISMATCHES_PER_RUN) };
}

/**
 * Resolve a mismatch by ID. Marks it as resolved in-memory.
 * In production, also persist to the DB row.
 *
 * @param {string} mismatchId
 * @param {{ resolvedBy: string, notes?: string }} resolution
 * @returns {{ ok: boolean, mismatch: object|null }}
 */
function resolveMismatch(mismatchId, { resolvedBy, notes = null }) {
  const mismatch = reconciliationMismatches.get(mismatchId);
  if (!mismatch) return { ok: false, mismatch: null };

  mismatch.status = "resolved";
  mismatch.resolvedAt = new Date().toISOString();
  mismatch.resolvedBy = resolvedBy;
  mismatch.notes = notes;
  reconciliationMismatches.set(mismatchId, mismatch);

  return { ok: true, mismatch };
}

/**
 * Return the latest completed run record and its open mismatches.
 * @returns {{ run: object|null, mismatches: object[] }}
 */
function getLatestRun() {
  let latest = null;
  for (const run of reconciliationRuns.values()) {
    if (!latest || run.completedAt > latest.completedAt) {
      latest = run;
    }
  }

  if (!latest) return { run: null, mismatches: [] };

  const runMismatches = [...reconciliationMismatches.values()].filter(
    (m) => m.runId === latest.runId,
  );

  return { run: latest, mismatches: runMismatches };
}

module.exports = { runReconciliation, resolveMismatch, getLatestRun };
