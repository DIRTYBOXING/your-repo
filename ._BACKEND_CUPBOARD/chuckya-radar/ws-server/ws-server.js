/**
 * ╔══════════════════════════════════════════════════════════════╗
 * ║  DFC CHUCKYA — WebSocket Server with Redis Adapter          ║
 * ║  Sub-second realtime alert broadcast, JWT auth,             ║
 * ║  region-partitioned rooms, horizontal scaling via Redis     ║
 * ╚══════════════════════════════════════════════════════════════╝
 */
"use strict";

const http = require("http");
const WebSocket = require("ws");
const Redis = require("ioredis");
const jwt = require("jsonwebtoken");

const REDIS_URL = process.env.REDIS_URL || "redis://localhost:6379";
const JWT_SECRET = process.env.JWT_SECRET || "replace-me-in-production";
const ADMIN_TOKEN = process.env.ADMIN_TOKEN || "admintoken";
const PORT = process.env.PORT || 8080;
const AUTH_TIMEOUT_MS = 5000;
const MAX_HANDSHAKES_PER_IP_PER_SEC = 5;

// ─── Redis Pub/Sub ───
const pub = new Redis(REDIS_URL);
const sub = new Redis(REDIS_URL);

pub.on("error", (err) => console.error("[redis-pub]", err.message));
sub.on("error", (err) => console.error("[redis-sub]", err.message));

// ─── HTTP + WS Server ───
const server = http.createServer();
const wss = new WebSocket.Server({ server });

/**
 * In-memory map: ws -> { regions: Set<string>, clientId: string }
 */
const clients = new Map();

// Simple per-IP rate limiter (sliding window)
const ipHandshakes = new Map(); // ip -> { count, resetAt }

function checkRateLimit(ip) {
  const now = Date.now();
  let entry = ipHandshakes.get(ip);
  if (!entry || now > entry.resetAt) {
    entry = { count: 0, resetAt: now + 1000 };
    ipHandshakes.set(ip, entry);
  }
  entry.count++;
  return entry.count <= MAX_HANDSHAKES_PER_IP_PER_SEC;
}

// Periodic cleanup of stale rate-limit entries
setInterval(() => {
  const now = Date.now();
  for (const [ip, entry] of ipHandshakes) {
    if (now > entry.resetAt + 10_000) ipHandshakes.delete(ip);
  }
}, 30_000);

function sendJson(ws, obj) {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(obj));
  }
}

// ─── Redis subscriber: relay alerts to local WS clients ───
sub.psubscribe("region:*", (err) => {
  if (err) console.error("[redis] psubscribe error", err);
});

sub.on("pmessage", (_pattern, channel, message) => {
  try {
    const region = channel.split(":")[1];
    const payload = JSON.parse(message);
    for (const [ws, meta] of clients.entries()) {
      if (meta.regions.has(region) && ws.readyState === WebSocket.OPEN) {
        sendJson(ws, {
          type: "alert",
          region,
          payload,
          ts: new Date().toISOString(),
        });
      }
    }
  } catch (e) {
    console.error("[relay] pmessage error", e.message);
  }
});

// ─── WebSocket connection handler ───
wss.on("connection", (ws, req) => {
  const ip =
    req.headers["x-forwarded-for"]?.split(",")[0]?.trim() ||
    req.socket.remoteAddress ||
    "unknown";

  // Rate limit handshake
  if (!checkRateLimit(ip)) {
    ws.close(1013, "rate limited");
    return;
  }

  // Require auth message within AUTH_TIMEOUT_MS
  const authTimeout = setTimeout(() => {
    ws.close(4001, "auth timeout");
  }, AUTH_TIMEOUT_MS);

  const onAuthMessage = (raw) => {
    try {
      const msg = JSON.parse(raw);
      if (msg.type !== "auth" || !msg.token) return;

      clearTimeout(authTimeout);

      let claims;
      try {
        claims = jwt.verify(msg.token, JWT_SECRET);
      } catch {
        ws.close(4003, "invalid token");
        return;
      }

      const allowedRegions = new Set(
        Array.isArray(claims.regions) ? claims.regions : [],
      );

      const meta = { regions: new Set(), clientId: claims.sub || "unknown" };
      // Auto-subscribe to allowed regions
      for (const r of allowedRegions) meta.regions.add(r);
      clients.set(ws, meta);

      sendJson(ws, {
        type: "auth_ok",
        clientId: meta.clientId,
        allowedRegions: Array.from(allowedRegions),
      });

      // Replace auth handler with normal handler
      ws.removeListener("message", onAuthMessage);
      ws.on("message", normalHandler);
    } catch {
      ws.close(1007, "bad message");
    }
  };

  const normalHandler = (raw) => {
    try {
      const msg = JSON.parse(raw);
      const meta = clients.get(ws);
      if (!meta) return;

      switch (msg.type) {
        case "subscribe":
          if (msg.region && typeof msg.region === "string") {
            meta.regions.add(msg.region);
            sendJson(ws, { type: "subscribed", region: msg.region });
          }
          break;
        case "unsubscribe":
          if (msg.region) {
            meta.regions.delete(msg.region);
            sendJson(ws, { type: "unsubscribed", region: msg.region });
          }
          break;
        case "ping":
          sendJson(ws, { type: "pong", ts: Date.now() });
          break;
        default:
          break; // ignore unknown
      }
    } catch {
      // ignore malformed
    }
  };

  ws.on("message", onAuthMessage);
  ws.on("close", () => clients.delete(ws));
  ws.on("error", () => ws.close());
});

// ─── Publish helper (call from any Node service) ───
function publishAlert(region, payload) {
  pub.publish(`region:${region}`, JSON.stringify(payload));
}

// ─── Admin HTTP endpoint to publish alerts ───
server.on("request", (req, res) => {
  // Health check
  if (req.method === "GET" && req.url === "/healthz") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ status: "ok", clients: clients.size }));
    return;
  }

  // Publish alert to a region
  if (req.method === "POST" && req.url === "/publish") {
    const auth = req.headers["authorization"] || "";
    if (auth !== `Bearer ${ADMIN_TOKEN}`) {
      res.writeHead(403);
      res.end("forbidden");
      return;
    }

    let body = "";
    req.on("data", (chunk) => {
      body += chunk;
      if (body.length > 65536) {
        req.destroy();
        return;
      } // 64KB limit
    });
    req.on("end", () => {
      try {
        const { region, payload } = JSON.parse(body);
        if (!region || !payload) throw new Error("missing region or payload");
        publishAlert(region, payload);
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ status: "published", region }));
      } catch (e) {
        res.writeHead(400);
        res.end(JSON.stringify({ error: "bad request" }));
      }
    });
    return;
  }

  res.writeHead(404);
  res.end();
});

// ─── Start ───
server.listen(PORT, () => {
  console.log("═══════════════════════════════════════════");
  console.log(" DFC CHUCKYA — WebSocket Server");
  console.log(` Port: ${PORT}  |  Redis: ${REDIS_URL}`);
  console.log(" Auth: JWT  |  Rooms: region:*");
  console.log("═══════════════════════════════════════════");
});

module.exports = { publishAlert };
