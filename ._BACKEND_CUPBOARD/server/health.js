// ═══════════════════════════════════════════════════════════════════════════
// DFC Platform Heartbeat
// Single endpoint that shows the health of every layer in the platform.
//
// GET /health
// Returns:  { status, timestamp, uptime_s, services, queues }
// Status:   "ok" | "degraded" | "down"
//   ok       → all required services healthy
//   degraded → optional services unhealthy (platform still usable)
//   down     → a required service is unreachable
// ═══════════════════════════════════════════════════════════════════════════

"use strict";

const net = require("node:net");
const { Client } = require("pg");

const REQUIRED_SERVICES = ["redis", "db"];

// ── Helpers ─────────────────────────────────────────────────────────────────

function tcpProbe(host, port, timeoutMs = 2000) {
  return new Promise((resolve) => {
    const start = Date.now();
    const sock = new net.Socket();

    const done = (ok) => {
      sock.destroy();
      resolve({ ok, latency_ms: Date.now() - start });
    };

    sock.setTimeout(timeoutMs);
    sock.on("connect", () => done(true));
    sock.on("error", () => done(false));
    sock.on("timeout", () => done(false));
    sock.connect(port, host);
  });
}

async function httpProbe(url, timeoutMs = 3000) {
  const start = Date.now();
  try {
    const ctrl = new AbortController();
    const id = setTimeout(() => ctrl.abort(), timeoutMs);
    const res = await fetch(url, { signal: ctrl.signal });
    clearTimeout(id);
    return {
      ok: res.ok,
      latency_ms: Date.now() - start,
      statusCode: res.status,
    };
  } catch {
    return { ok: false, latency_ms: Date.now() - start };
  }
}

async function dbProbe() {
  const start = Date.now();
  const client = new Client({
    host: process.env.POSTGRES_HOST || "db",
    port: Number(process.env.POSTGRES_PORT || 5432),
    database: process.env.POSTGRES_DB || "dfc",
    user: process.env.POSTGRES_USER || "dfc_admin",
    password:
      process.env.POSTGRES_PASSWORD ||
      process.env.DB_PASSWORD ||
      "dfc-local-postgres-change-me",
    connectionTimeoutMillis: 3000,
    query_timeout: 2000,
  });
  try {
    await client.connect();
    await client.query("SELECT 1");
    return { ok: true, latency_ms: Date.now() - start };
  } catch (err) {
    return { ok: false, latency_ms: Date.now() - start, error: err.message };
  } finally {
    await client.end().catch(() => {});
  }
}

async function queueProbe() {
  // Use raw Redis commands (LLEN) to avoid importing BullMQ into the server.
  // BullMQ key pattern: bull:<queue>:<state>
  const { default: Redis } = await import("ioredis").catch(() => ({
    default: null,
  }));
  if (!Redis) return { auto_clip: { error: "ioredis not available" } };

  const redis = new Redis({
    host: process.env.REDIS_HOST || "redis",
    port: Number(process.env.REDIS_PORT || 6379),
    connectTimeout: 3000,
    maxRetriesPerRequest: 1,
    lazyConnect: true,
  });

  try {
    await redis.connect();
    const [waiting, active, failed, completed] = await Promise.all([
      redis.llen("bull:auto-clip:wait"),
      redis.llen("bull:auto-clip:active"),
      redis.zcard("bull:auto-clip:failed"),
      redis.zcard("bull:auto-clip:completed"),
    ]);
    return { auto_clip: { waiting, active, failed, completed } };
  } catch (err) {
    return { auto_clip: { error: err.message } };
  } finally {
    redis.disconnect();
  }
}

// ── Main health check ────────────────────────────────────────────────────────

async function collectHealth() {
  const redisHost = process.env.REDIS_HOST || "redis";
  const redisPort = Number(process.env.REDIS_PORT || 6379);

  const entitlementsUrl = `http://${process.env.ENTITLEMENTS_HOST || "entitlements"}:${process.env.ENTITLEMENTS_PORT || 4010}/health`;
  const predictorUrl = `http://${process.env.PREDICTOR_HOST || "predictor"}:${process.env.PREDICTOR_PORT || 8090}/health`;
  const ingestUrl = `http://${process.env.INGEST_HOST || "ingest"}:${process.env.INGEST_PORT || 8000}/health`;

  const [redis, db, entitlements, predictor, ingest, queues] =
    await Promise.all([
      tcpProbe(redisHost, redisPort),
      dbProbe(),
      httpProbe(entitlementsUrl),
      httpProbe(predictorUrl),
      httpProbe(ingestUrl),
      queueProbe(),
    ]);

  const services = {
    redis: { status: redis.ok ? "ok" : "down", latency_ms: redis.latency_ms },
    db: {
      status: db.ok ? "ok" : "down",
      latency_ms: db.latency_ms,
      ...(db.error ? { error: db.error } : {}),
    },
    entitlements: {
      status: entitlements.ok ? "ok" : "down",
      latency_ms: entitlements.latency_ms,
    },
    predictor: {
      status: predictor.ok ? "ok" : "down",
      latency_ms: predictor.latency_ms,
    },
    ingest: {
      status: ingest.ok ? "ok" : "down",
      latency_ms: ingest.latency_ms,
    },
    firebase: {
      status:
        process.env.FIREBASE_CONNECTED === "true" ? "connected" : "offline",
    },
  };

  const requiredDown = REQUIRED_SERVICES.filter(
    (s) => services[s]?.status === "down",
  );
  const anyDown = Object.values(services).some((s) => s.status === "down");

  const status = requiredDown.length > 0 ? "down" : anyDown ? "degraded" : "ok";

  return {
    status,
    timestamp: new Date().toISOString(),
    uptime_s: Math.floor(process.uptime()),
    services,
    queues,
  };
}

// ── Express middleware ───────────────────────────────────────────────────────

async function healthHandler(req, res) {
  try {
    const health = await collectHealth();
    const httpStatus = health.status === "down" ? 503 : 200;
    res.status(httpStatus).json(health);
  } catch (err) {
    res.status(500).json({
      status: "down",
      timestamp: new Date().toISOString(),
      error: err.message,
    });
  }
}

function livenessHandler(_req, res) {
  res.status(200).json({ status: "ok", timestamp: new Date().toISOString() });
}

module.exports = { healthHandler, collectHealth, livenessHandler };
