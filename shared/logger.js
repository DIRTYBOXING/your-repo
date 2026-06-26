// ═══════════════════════════════════════════════════════════════════════════
// DFC Structured Logger
// Shared by all Node.js services (auto-clip-worker, entitlements, server…)
//
// Usage:
//   const log = require('../../shared/logger').createLogger('auto-clip-worker');
//   log.info('job_started', { jobId: '123', eventId: 'ufc-305' });
//   log.warn('firebase_offline', { reason: 'EISDIR' });
//   log.error('job_failed', { jobId: '123', error: err.message });
// ═══════════════════════════════════════════════════════════════════════════

"use strict";

const { randomUUID } = require("node:crypto");

// Sane severity ordering
const LEVELS = { debug: 10, info: 20, warn: 30, error: 40 };
const MIN_LEVEL = LEVELS[process.env.LOG_LEVEL?.toLowerCase()] ?? LEVELS.info;

function createLogger(service) {
  if (!service || typeof service !== "string") {
    throw new Error("[logger] createLogger requires a non-empty service name");
  }

  /**
   * @param {'debug'|'info'|'warn'|'error'} level
   * @param {string} event  - snake_case event name (e.g. "job_started")
   * @param {object} [data] - arbitrary extra context
   * @param {string} [traceId] - optional request/job trace ID
   */
  function write(level, event, data = {}, traceId) {
    if ((LEVELS[level] ?? 0) < MIN_LEVEL) return;

    const entry = {
      timestamp: new Date().toISOString(),
      level,
      service,
      event,
      traceId: traceId ?? randomUUID(),
      ...data,
    };

    // Single JSON line per event — ingestible by any log aggregator
    const line = JSON.stringify(entry);

    if (level === "error") {
      process.stderr.write(line + "\n");
    } else {
      process.stdout.write(line + "\n");
    }
  }

  return {
    debug: (event, data, traceId) => write("debug", event, data, traceId),
    info: (event, data, traceId) => write("info", event, data, traceId),
    warn: (event, data, traceId) => write("warn", event, data, traceId),
    error: (event, data, traceId) => write("error", event, data, traceId),

    /**
     * Returns a child logger with a pinned traceId — useful for scoping a
     * single job or request lifecycle without passing traceId everywhere.
     */
    child(traceId) {
      return {
        debug: (event, data) => write("debug", event, data, traceId),
        info: (event, data) => write("info", event, data, traceId),
        warn: (event, data) => write("warn", event, data, traceId),
        error: (event, data) => write("error", event, data, traceId),
      };
    },
  };
}

module.exports = { createLogger };
