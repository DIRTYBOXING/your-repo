// ─────────────────────────────────────────────────────────────
// twilio-sms-webhook.js — Standalone Twilio SMS entry point
//
// This is a standalone Express server for the Twilio SMS webhook,
// deployable as a separate Cloud Run service (dfc-twilio-webhook).
//
// Wraps the same SMS command handler from smsWebhook.js with its
// own Express server and health check endpoint.
//
// Required env:
//   TWILIO_AUTH_TOKEN          — for request signature validation
//   SEND_PROMOTER_ENDPOINT    — URL for the sendPromoterEmail handler
//   AUTHORIZED_PHONE_NUMBERS  — comma-separated E.164 numbers
//   LOG_DIR                   — directory for log files (default: docs/legal/email_logs)
// ─────────────────────────────────────────────────────────────

import express from "express";
import smsWebhook from "./smsWebhook.js";

const app = express();

// Twilio sends application/x-www-form-urlencoded
app.use(express.urlencoded({ extended: false }));
app.use(express.json());

// Health check
app.get("/", (_req, res) =>
  res.json({ status: "ok", service: "dfc-twilio-webhook" }),
);
app.get("/health", (_req, res) => res.json({ status: "ok" }));

// Twilio inbound SMS
app.post("/sms", smsWebhook);

const PORT = process.env.PORT || 8081;
app.listen(PORT, () => {
  console.log(`DFC Twilio webhook listening on port ${PORT}`);
});
