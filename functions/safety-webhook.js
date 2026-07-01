// ─────────────────────────────────────────────────────────────
// safety-webhook.js — Device alert handler for safety zone system
//
// Receives alerts from wearable devices (TEKTELIC SEAL, Radar geofences)
// and dispatches multi-channel notifications (SMS, email, push).
//
// Required env:
//   HMAC_SECRET       — shared secret for request signature validation
//   SENDGRID_API_KEY  — for email alerts
//   FROM_EMAIL        — sender address
//   TWILIO_SID        — Twilio account SID
//   TWILIO_AUTH_TOKEN  — Twilio auth token
//   TWILIO_FROM       — Twilio sender number
//   ONCALL_SMS        — comma-separated on-call phone numbers
//   RADAR_API_KEY     — Radar.io API key for geofence lookups
//
// Alert types:
//   panic        — SOS button pressed
//   geofence     — zone breach (entry/exit)
//   fall         — fall detection from accelerometer
//   low_battery  — battery below threshold
//   proximity    — close proximity alert
// ─────────────────────────────────────────────────────────────

import crypto from "crypto";
import fs from "fs/promises";
import path from "path";

const LOG_DIR = process.env.SAFETY_LOG_DIR || "docs/legal/safety_logs";
const BATTERY_THRESHOLD = 15;

// ── Severity classification ──────────────────────────────────
function classifyAlert(payload) {
  if (payload.panic === true) return { level: "critical", type: "panic" };
  if (payload.accel?.impact >= 4.0) return { level: "critical", type: "fall" };
  if (payload.geofence?.breach === true)
    return { level: "high", type: "geofence" };
  if (payload.proximity != null && payload.proximity < 0.3)
    return { level: "high", type: "proximity" };
  if (payload.accel?.impact >= 2.5) return { level: "medium", type: "fall" };
  if (payload.battery != null && payload.battery < BATTERY_THRESHOLD)
    return { level: "low", type: "low_battery" };
  return { level: "info", type: "heartbeat" };
}

// ── HMAC-SHA256 signature validation ─────────────────────────
function validateSignature(req, rawBody) {
  const secret = process.env.HMAC_SECRET;
  if (!secret) return false;
  const sig = req.headers["x-dfc-signature"];
  if (!sig) return false;
  const expected = crypto
    .createHmac("sha256", secret)
    .update(rawBody)
    .digest("hex");
  try {
    return crypto.timingSafeEqual(
      Buffer.from(sig, "hex"),
      Buffer.from(expected, "hex"),
    );
  } catch {
    return false;
  }
}

// ── SMS alert via Twilio ─────────────────────────────────────
async function sendSmsAlert(message) {
  const sid = process.env.TWILIO_SID;
  const token = process.env.TWILIO_AUTH_TOKEN;
  const from = process.env.TWILIO_FROM;
  const oncall = (process.env.ONCALL_SMS || "")
    .split(",")
    .map((n) => n.trim())
    .filter(Boolean);

  if (!sid || !token || !from || oncall.length === 0) {
    console.warn("Twilio not configured — skipping SMS alert");
    return [];
  }

  const results = [];
  for (const to of oncall) {
    try {
      const url = `https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`;
      const body = new URLSearchParams({ To: to, From: from, Body: message });
      const auth = Buffer.from(`${sid}:${token}`).toString("base64");
      const res = await fetch(url, {
        method: "POST",
        headers: {
          Authorization: `Basic ${auth}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: body.toString(),
      });
      results.push({
        to,
        status: res.ok ? "sent" : "failed",
        code: res.status,
      });
    } catch (err) {
      results.push({ to, status: "error", error: err.message });
    }
  }
  return results;
}

// ── Email alert via SendGrid ─────────────────────────────────
async function sendEmailAlert(subject, htmlBody) {
  const apiKey = process.env.SENDGRID_API_KEY;
  const from = process.env.FROM_EMAIL || "safety@datafightcentral.com";
  const oncall = (process.env.ONCALL_SMS || "")
    .split(",")
    .map((n) => n.trim())
    .filter(Boolean);

  if (!apiKey || oncall.length === 0) {
    console.warn("SendGrid not configured — skipping email alert");
    return;
  }

  // Send to configured safety email (use FROM_EMAIL as fallback recipient)
  const res = await fetch("https://api.sendgrid.com/v3/mail/send", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      personalizations: [{ to: [{ email: from }] }],
      from: { email: from, name: "DFC Safety System" },
      subject,
      content: [{ type: "text/html", value: htmlBody }],
    }),
  });

  if (!res.ok) {
    console.error("SendGrid alert failed:", res.status);
  }
}

// ── Audit log ────────────────────────────────────────────────
async function logAlert(payload, classification, actions) {
  try {
    await fs.mkdir(LOG_DIR, { recursive: true });
    const entry = {
      timestamp: new Date().toISOString(),
      deviceId: payload.deviceId,
      lat: payload.lat,
      lon: payload.lon,
      classification,
      actions,
      raw: payload,
    };
    const logFile = path.join(
      LOG_DIR,
      `alerts_${new Date().toISOString().slice(0, 10)}.json`,
    );
    await fs.appendFile(logFile, JSON.stringify(entry) + "\n");
  } catch (_) {
    // Non-critical
  }
}

// ── Build alert message ──────────────────────────────────────
function buildAlertMessage(payload, classification) {
  const ts = payload.ts || new Date().toISOString();
  const device = payload.deviceId || "unknown";
  const loc =
    payload.lat && payload.lon ? `${payload.lat}, ${payload.lon}` : "unknown";
  const battery = payload.battery != null ? `${payload.battery}%` : "N/A";

  const lines = [
    `🚨 DFC SAFETY ALERT — ${classification.level.toUpperCase()}`,
    `Type: ${classification.type}`,
    `Device: ${device}`,
    `Location: ${loc}`,
    `Battery: ${battery}`,
    `Time: ${ts}`,
  ];

  if (classification.type === "panic")
    lines.push("⚠️ SOS PANIC BUTTON PRESSED");
  if (classification.type === "fall")
    lines.push(`Impact: ${payload.accel?.impact ?? "N/A"}g`);
  if (classification.type === "geofence")
    lines.push(`Zone: ${payload.geofence?.zone ?? "unknown"}`);
  if (classification.type === "proximity")
    lines.push(`Distance: ${payload.proximity}m`);

  return lines.join("\n");
}

function buildAlertHtml(payload, classification) {
  const msg = buildAlertMessage(payload, classification);
  return `<pre style="font-family:monospace;font-size:14px;background:#1a1a1a;color:#ff4444;padding:16px;border-radius:8px;">${msg.replace(/\n/g, "<br>")}</pre>`;
}

// ── Main handler ─────────────────────────────────────────────
export default async function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  // Get raw body for HMAC validation
  const rawBody =
    typeof req.body === "string" ? req.body : JSON.stringify(req.body);

  // Validate HMAC signature
  if (process.env.HMAC_SECRET && !validateSignature(req, rawBody)) {
    return res.status(403).json({ error: "Invalid signature" });
  }

  const payload =
    typeof req.body === "string" ? JSON.parse(req.body) : req.body;

  if (!payload.deviceId) {
    return res.status(400).json({ error: "Missing deviceId" });
  }

  const classification = classifyAlert(payload);
  const actions = [];

  // ── Dispatch alerts based on severity ──────────────────────
  if (classification.level === "critical" || classification.level === "high") {
    // SMS to on-call team
    const smsResults = await sendSmsAlert(
      buildAlertMessage(payload, classification),
    );
    actions.push({ channel: "sms", results: smsResults });

    // Email alert
    await sendEmailAlert(
      `[DFC Safety] ${classification.level.toUpperCase()}: ${classification.type} — ${payload.deviceId}`,
      buildAlertHtml(payload, classification),
    );
    actions.push({ channel: "email", status: "sent" });
  }

  if (classification.level === "medium") {
    // Email only for medium severity
    await sendEmailAlert(
      `[DFC Safety] MEDIUM: ${classification.type} — ${payload.deviceId}`,
      buildAlertHtml(payload, classification),
    );
    actions.push({ channel: "email", status: "sent" });
  }

  // Always log
  await logAlert(payload, classification, actions);

  return res.status(200).json({
    status: "processed",
    deviceId: payload.deviceId,
    classification,
    actions: actions.map((a) => a.channel),
  });
}
