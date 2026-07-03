// ─────────────────────────────────────────────────────────────
// server.js — Express wrapper for Cloud Run / local dev
// Routes: outreach, safety, DRM, auth, SMS
// ─────────────────────────────────────────────────────────────
import express from "express";
import sendPromoterEmail from "./sendPromoterEmail.js";
import sendSocialOutreach from "./sendSocialOutreach.js";
import smsWebhook from "./smsWebhook.js";
import safetyWebhook from "./safety-webhook.js";
import drmLicenseExchange from "./drm-license-exchange.js";
import { signIn, refresh, revoke } from "./auth-tokens.js";
import { requestEntitlement, validateEntitlement } from "./entitlement.js";

const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// Health check
app.get("/", (_req, res) =>
  res.json({ status: "ok", service: "dfc-outreach" }),
);
app.get("/health", (_req, res) => res.json({ status: "ok" }));

// Email outreach
app.post("/sendPromoterEmail", sendPromoterEmail);

// Social DM outreach (Messenger + Instagram)
app.post("/sendSocialOutreach", sendSocialOutreach);

// Twilio SMS inbound webhook
app.post("/sms", smsWebhook);

// Safety zone device alerts
app.post("/device-alert", safetyWebhook);

// DRM license exchange (Widevine + FairPlay)
app.post("/drm/license", drmLicenseExchange);

// Entitlement service (playback tokens)
app.post("/entitlements/request", requestEntitlement);
app.post("/entitlements/validate", validateEntitlement);

// Auth token endpoints
app.post("/auth/signin", signIn);
app.post("/auth/refresh", refresh);
app.post("/auth/revoke", revoke);

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`DFC Outreach server listening on port ${PORT}`);
});
