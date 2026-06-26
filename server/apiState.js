// server/apiState.js
// Shared in-memory state for the pilot/dev API.
// Both apiStubs.js and internalRoutes.js import from here so they
// operate on the same objects.  In production, replace with DB calls.
//
// Null-prototype objects are used to prevent __proto__ prototype pollution.
"use strict";

const posts = Object.create(null); // postId → post record
const mediaJobs = Object.create(null); // jobId  → job record
const uploadSessions = Object.create(null); // uploadId → upload session
const audit = []; // append-only audit log

// Reconciliation state — keyed by runId
const reconciliationRuns = new Map(); // runId → run record
const reconciliationMismatches = new Map(); // mismatchId → mismatch record

module.exports = { posts, mediaJobs, audit, uploadSessions, reconciliationRuns, reconciliationMismatches };
