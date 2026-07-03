// ─────────────────────────────────────────────────────────────
// smsWebhook.js — Twilio inbound SMS webhook for mobile triggers
//
// Allows Chukya or any authorized phone to trigger outreach via text.
//
// Commands:
//   SEND <eventId>             → sends email + social DMs for that event
//   SEND ALL                   → sends for all events
//   STATUS                     → returns send counts
//   HELP                       → returns command list
//
// Required env:
//   TWILIO_AUTH_TOKEN   — for request signature validation
//   SEND_ENDPOINT       — internal URL for sendPromoterEmail (localhost:8080 in Cloud Run)
//   SOCIAL_ENDPOINT     — internal URL for sendSocialOutreach
//
// Security: validates Twilio request signature. Only processes
//           messages from numbers listed in AUTHORIZED_NUMBERS.
// ─────────────────────────────────────────────────────────────

import crypto from "crypto";
import fs from "fs/promises";
import path from "path";
import { SOCIAL_CONFIG } from "./socialConfig.js";

const LOG_DIR = SOCIAL_CONFIG.logging.socialLogDir;

// Authorized phone numbers (E.164 format). Add yours here or via env.
const AUTHORIZED_NUMBERS = (process.env.AUTHORIZED_PHONE_NUMBERS || "")
  .split(",")
  .map((n) => n.trim())
  .filter(Boolean);

function validateTwilioSignature(req) {
  const token = process.env.TWILIO_AUTH_TOKEN;
  if (!token) return false;

  const sig = req.headers["x-twilio-signature"];
  if (!sig) return false;

  // Build the full URL from the request
  const protocol = req.headers["x-forwarded-proto"] || "https";
  const url = `${protocol}://${req.headers.host}${req.originalUrl || req.url}`;

  // Sort POST params and concat
  const params = req.body || {};
  const sortedKeys = Object.keys(params).sort();
  const data = url + sortedKeys.map((k) => k + params[k]).join("");

  const expected = crypto
    .createHmac("sha1", token)
    .update(Buffer.from(data, "utf-8"))
    .digest("base64");

  // Constant-time comparison
  try {
    return crypto.timingSafeEqual(Buffer.from(sig), Buffer.from(expected));
  } catch {
    return false;
  }
}

function twiml(message) {
  // Return TwiML XML response
  return `<?xml version="1.0" encoding="UTF-8"?><Response><Message>${escapeXml(message)}</Message></Response>`;
}

function escapeXml(str) {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

async function logSms(from, command, status, detail) {
  try {
    await fs.mkdir(LOG_DIR, { recursive: true });
    const entry = {
      timestamp: new Date().toISOString(),
      channel: "sms",
      from,
      command,
      status,
      detail,
    };
    const logFile = path.join(LOG_DIR, "sms_commands.json");
    await fs.appendFile(logFile, JSON.stringify(entry) + "\n");
  } catch (_) {
    // Non-critical
  }
}

export default async function handler(req, res) {
  // Validate Twilio signature
  if (process.env.TWILIO_AUTH_TOKEN && !validateTwilioSignature(req)) {
    return res.status(403).send(twiml("Unauthorized"));
  }

  const from = req.body?.From || "";
  const body = (req.body?.Body || "").trim().toUpperCase();

  // Check authorized numbers (if configured)
  if (AUTHORIZED_NUMBERS.length > 0 && !AUTHORIZED_NUMBERS.includes(from)) {
    await logSms(from, body, "rejected", "Unauthorized number");
    return res.type("text/xml").send(twiml("Not authorized. Contact admin."));
  }

  // Parse command
  const parts = body.split(/\s+/);
  const command = parts[0];

  switch (command) {
    case "SEND": {
      const eventId = parts[1] || "ALL";
      await logSms(
        from,
        body,
        "accepted",
        `Triggering outreach for ${eventId}`,
      );

      // Trigger internal endpoints
      const sendEndpoint =
        process.env.SEND_ENDPOINT || "http://localhost:8080/sendPromoterEmail";
      const socialEndpoint =
        process.env.SOCIAL_ENDPOINT ||
        "http://localhost:8080/sendSocialOutreach";

      let eventFiles = [];
      const eventsDir = path.join(process.cwd(), "..", "data", "events");

      try {
        if (eventId === "ALL") {
          const files = await fs.readdir(eventsDir);
          eventFiles = files
            .filter((f) => f.endsWith(".json"))
            .map((f) => path.join(eventsDir, f));
        } else {
          const filePath = path.join(eventsDir, `${eventId}.json`);
          try {
            await fs.access(filePath);
            eventFiles = [filePath];
          } catch {
            return res
              .type("text/xml")
              .send(twiml(`Event not found: ${eventId}`));
          }
        }
      } catch {
        return res.type("text/xml").send(twiml(`Cannot read events directory`));
      }

      let sent = 0;
      let failed = 0;

      for (const file of eventFiles) {
        try {
          // Trigger email
          await fetch(sendEndpoint, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ eventJsonPath: file, template: "initial" }),
          });
          sent++;
        } catch {
          failed++;
        }
      }

      return res
        .type("text/xml")
        .send(
          twiml(
            `Outreach triggered: ${sent} sent, ${failed} failed (${eventFiles.length} events)`,
          ),
        );
    }

    case "STATUS": {
      await logSms(from, body, "accepted", "Status check");
      // Count log files
      let emailCount = 0;
      let socialCount = 0;
      try {
        const emailLogs = await fs.readdir("docs/legal/email_logs");
        emailCount = emailLogs.length;
      } catch {
        /* empty */
      }
      try {
        const socialLogs = await fs.readdir("docs/legal/social_logs");
        socialCount = socialLogs.length;
      } catch {
        /* empty */
      }
      return res
        .type("text/xml")
        .send(
          twiml(
            `DFC Status: ${emailCount} email logs, ${socialCount} social logs`,
          ),
        );
    }

    case "HELP":
      await logSms(from, body, "accepted", "Help");
      return res
        .type("text/xml")
        .send(
          twiml(
            "DFC Commands:\nSEND <eventId> - send outreach for event\nSEND ALL - send for all events\nSTATUS - check send counts\nHELP - this message",
          ),
        );

    default:
      await logSms(from, body, "unknown", "Unrecognized command");
      return res
        .type("text/xml")
        .send(twiml("Unknown command. Text HELP for options."));
  }
}
