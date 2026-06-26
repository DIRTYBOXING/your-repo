// server/test/reconciliation.test.js
// Tests for the wallet reconciliation job and admin API endpoints.

"use strict";

const assert = require("node:assert/strict");
const http = require("node:http");
const test = require("node:test");
const express = require("express");

// ── Unit tests for the reconciliation job module ──────────────────────────────

const { runReconciliation, resolveMismatch, getLatestRun } = require("../jobs/reconciliation");
const { reconciliationRuns, reconciliationMismatches } = require("../apiState");

function clearReconciliationState() {
  reconciliationRuns.clear();
  reconciliationMismatches.clear();
}

test("runReconciliation — clean books: no mismatches", () => {
  clearReconciliationState();

  const purchaseStore = new Map([
    ["p1", { userId: "alice", amountCents: 2999, status: "paid" }],
  ]);
  const walletTransactions = new Map([
    [1, { userId: "alice", type: "debit", amountCents: 2999 }],
  ]);

  const { summary, mismatches } = runReconciliation(purchaseStore, walletTransactions);

  assert.equal(summary.accountsChecked, 1);
  assert.equal(summary.mismatchCount, 0);
  assert.equal(summary.mismatchRatio, 0);
  assert.equal(mismatches.length, 0);
});

test("runReconciliation — purchase excess mismatch detected", () => {
  clearReconciliationState();

  const purchaseStore = new Map([
    ["p1", { userId: "bob", amountCents: 5000, status: "paid" }],
  ]);
  const walletTransactions = new Map([
    [1, { userId: "bob", type: "debit", amountCents: 4000 }],
  ]);

  const { summary, mismatches } = runReconciliation(purchaseStore, walletTransactions);

  assert.equal(summary.mismatchCount, 1);
  assert.equal(mismatches[0].discrepancyCents, 1000);
  assert.equal(mismatches[0].direction, "purchase_excess");
  assert.equal(mismatches[0].status, "open");
  assert.equal(mismatches[0].userId, "bob");
});

test("runReconciliation — wallet excess mismatch detected", () => {
  clearReconciliationState();

  const purchaseStore = new Map([
    ["p1", { userId: "carol", amountCents: 1000, status: "paid" }],
  ]);
  const walletTransactions = new Map([
    [1, { userId: "carol", type: "debit", amountCents: 1500 }],
  ]);

  const { summary, mismatches } = runReconciliation(purchaseStore, walletTransactions);

  assert.equal(summary.mismatchCount, 1);
  assert.equal(mismatches[0].discrepancyCents, 500);
  assert.equal(mismatches[0].direction, "wallet_excess");
});

test("runReconciliation — unpaid purchases are excluded", () => {
  clearReconciliationState();

  const purchaseStore = new Map([
    ["p1", { userId: "dave", amountCents: 3000, status: "pending" }],
    ["p2", { userId: "dave", amountCents: 1000, status: "paid" }],
  ]);
  const walletTransactions = new Map([
    [1, { userId: "dave", type: "debit", amountCents: 1000 }],
  ]);

  const { summary } = runReconciliation(purchaseStore, walletTransactions);
  assert.equal(summary.mismatchCount, 0);
});

test("runReconciliation — non-debit wallet transactions are excluded", () => {
  clearReconciliationState();

  const purchaseStore = new Map([
    ["p1", { userId: "eve", amountCents: 500, status: "paid" }],
  ]);
  const walletTransactions = new Map([
    [1, { userId: "eve", type: "credit", amountCents: 5000 }], // topup, should not count
    [2, { userId: "eve", type: "debit", amountCents: 500 }],
  ]);

  const { summary } = runReconciliation(purchaseStore, walletTransactions);
  assert.equal(summary.mismatchCount, 0);
});

test("resolveMismatch — resolves an open mismatch", () => {
  clearReconciliationState();

  const purchaseStore = new Map([
    ["p1", { userId: "frank", amountCents: 999, status: "paid" }],
  ]);
  const walletTransactions = new Map([
    [1, { userId: "frank", type: "debit", amountCents: 1 }],
  ]);

  const { mismatches } = runReconciliation(purchaseStore, walletTransactions);
  const mismatchId = mismatches[0].id;

  const { ok, mismatch } = resolveMismatch(mismatchId, { resolvedBy: "admin@dfc", notes: "manual adjustment" });

  assert.equal(ok, true);
  assert.equal(mismatch.status, "resolved");
  assert.equal(mismatch.resolvedBy, "admin@dfc");
  assert.equal(mismatch.notes, "manual adjustment");
  assert.ok(mismatch.resolvedAt);
});

test("resolveMismatch — returns ok:false for unknown id", () => {
  const { ok, mismatch } = resolveMismatch("nonexistent-id", { resolvedBy: "admin" });
  assert.equal(ok, false);
  assert.equal(mismatch, null);
});

test("getLatestRun — returns null when no runs exist", () => {
  clearReconciliationState();
  const { run } = getLatestRun();
  assert.equal(run, null);
});

test("getLatestRun — returns latest run after multiple runs", () => {
  clearReconciliationState();

  const p = new Map([["p1", { userId: "grace", amountCents: 100, status: "paid" }]]);
  const w = new Map([[1, { userId: "grace", type: "debit", amountCents: 100 }]]);

  runReconciliation(p, w);
  runReconciliation(p, w);

  const { run } = getLatestRun();
  assert.equal(reconciliationRuns.size, 2);
  assert.ok(run.runId);
  assert.equal(run.status, "completed");
});

// ── Integration tests for admin API endpoints ──────────────────────────────────

function loadApiRouter() {
  // Bust cache so each test group gets a fresh apiStubs with clean stores
  const modulePath = require.resolve("../apiStubs");
  delete require.cache[modulePath];
  return require("../apiStubs");
}

async function startServer() {
  const api = loadApiRouter();
  const app = express();
  app.use("/api", api);
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  const { port } = server.address();
  return {
    server,
    baseUrl: `http://127.0.0.1:${port}`,
    stop: () => new Promise((resolve, reject) => server.close((e) => (e ? reject(e) : resolve()))),
  };
}

async function post(url, body) {
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  return { status: res.status, body: await res.json() };
}

async function get(url) {
  const res = await fetch(url);
  return { status: res.status, body: await res.json() };
}

test("GET /api/admin/reconciliation/latest — returns no-run message initially", async () => {
  clearReconciliationState();
  const { baseUrl, stop } = await startServer();
  try {
    const { status, body } = await get(`${baseUrl}/api/admin/reconciliation/latest`);
    assert.equal(status, 200);
    assert.equal(body.run, null);
  } finally {
    await stop();
  }
});

test("POST /api/admin/reconciliation/run — returns completed run summary", async () => {
  clearReconciliationState();
  const { baseUrl, stop } = await startServer();
  try {
    const { status, body } = await post(`${baseUrl}/api/admin/reconciliation/run`, {});
    assert.equal(status, 201);
    assert.equal(body.summary.status, "completed");
    assert.ok(body.runId);
    assert.equal(Array.isArray(body.mismatches), true);
  } finally {
    await stop();
  }
});

test("POST /api/admin/reconciliation/resolve/:id — 400 if resolvedBy missing", async () => {
  clearReconciliationState();
  const { baseUrl, stop } = await startServer();
  try {
    const { status, body } = await post(`${baseUrl}/api/admin/reconciliation/resolve/fake-id`, {});
    assert.equal(status, 400);
    assert.ok(body.error);
  } finally {
    await stop();
  }
});

test("POST /api/admin/reconciliation/resolve/:id — 404 for unknown mismatch", async () => {
  clearReconciliationState();
  const { baseUrl, stop } = await startServer();
  try {
    const { status, body } = await post(`${baseUrl}/api/admin/reconciliation/resolve/no-such-id`, { resolvedBy: "admin" });
    assert.equal(status, 404);
    assert.ok(body.error);
  } finally {
    await stop();
  }
});
