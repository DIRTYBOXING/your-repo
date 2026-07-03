// ─────────────────────────────────────────────────────────────
// sendSocialOutreach.js — Serverless social DM outreach (Facebook Messenger + Instagram)
// Deploy alongside sendPromoterEmail.js on Cloud Run / AWS Lambda / Vercel.
//
// Required env vars:
//   FB_PAGE_ID            — Facebook Page numeric ID
//   FB_PAGE_ACCESS_TOKEN  — Long-lived Page access token
//   IG_BUSINESS_ACCOUNT_ID — Instagram Business Account ID
//   IG_ACCESS_TOKEN        — Instagram / Business API token
//
// Calling conventions:
//   POST { "channel": "messenger"|"instagram", "recipientId": "...",
//          "template": "promoter_initial"|"promoter_followup"|"gym_shields",
//          "vars": { "PROMOTER_NAME": "...", "EVENT_TITLE": "...", "GYM_NAME": "..." } }
//
// Fallback: if API tokens are not configured, generates DM text in response
//           for manual paste (safe, policy-compliant).
// ─────────────────────────────────────────────────────────────

import fs from "fs/promises";
import path from "path";
import { SOCIAL_CONFIG } from "./socialConfig.js";

const LOG_DIR = SOCIAL_CONFIG.logging.socialLogDir;

// ── Template loader ──

const TEMPLATE_MAP = {
  messenger: {
    promoter_initial: SOCIAL_CONFIG.dmTemplates.messenger_promoter_initial,
    promoter_followup: SOCIAL_CONFIG.dmTemplates.messenger_promoter_followup,
    gym_shields: SOCIAL_CONFIG.dmTemplates.messenger_gym_shields,
  },
  instagram: {
    promoter_initial: SOCIAL_CONFIG.dmTemplates.instagram_promoter_initial,
    promoter_followup: SOCIAL_CONFIG.dmTemplates.instagram_promoter_followup,
    gym_shields: SOCIAL_CONFIG.dmTemplates.instagram_gym_shields,
  },
};

async function loadTemplate(channel, template, vars) {
  const filePath = TEMPLATE_MAP[channel]?.[template];
  if (!filePath) throw new Error(`Unknown template: ${channel}/${template}`);

  let text = await fs.readFile(filePath, "utf8");

  // Replace placeholders with supplied vars
  for (const [key, value] of Object.entries(vars || {})) {
    const placeholder = `[${key}]`;
    text = text.replaceAll(placeholder, value);
  }
  return text.trim();
}

// ── Facebook Messenger send ──

async function sendMessengerDM(recipientId, messageText) {
  const pageId = process.env.FB_PAGE_ID;
  const token = process.env.FB_PAGE_ACCESS_TOKEN;

  if (!pageId || !token) {
    return {
      sent: false,
      fallback: true,
      text: messageText,
      reason: "FB_PAGE_ACCESS_TOKEN not configured",
    };
  }

  const url = `${SOCIAL_CONFIG.channels.messenger.apiBase}/${pageId}/messages`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      recipient: { id: recipientId },
      messaging_type: "MESSAGE_TAG",
      tag: "CONFIRMED_EVENT_UPDATE",
      message: { text: messageText },
    }),
  });

  const data = await res.json();
  if (!res.ok) {
    return {
      sent: false,
      fallback: false,
      error: data.error?.message || JSON.stringify(data),
      status: res.status,
    };
  }
  return { sent: true, messageId: data.message_id };
}

// ── Instagram DM send ──

async function sendInstagramDM(recipientId, messageText) {
  const igAccountId = process.env.IG_BUSINESS_ACCOUNT_ID;
  const token = process.env.IG_ACCESS_TOKEN;

  if (!igAccountId || !token) {
    return {
      sent: false,
      fallback: true,
      text: messageText,
      reason: "IG_ACCESS_TOKEN not configured",
    };
  }

  const url = `${SOCIAL_CONFIG.channels.instagram.apiBase}/${igAccountId}/messages`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      recipient: { id: recipientId },
      message: { text: messageText },
    }),
  });

  const data = await res.json();
  if (!res.ok) {
    return {
      sent: false,
      fallback: false,
      error: data.error?.message || JSON.stringify(data),
      status: res.status,
    };
  }
  return { sent: true, messageId: data.message_id };
}

// ── Audit log writer ──

async function writeSocialLog(channel, recipientId, template, status, extra) {
  const entry = {
    timestamp: new Date().toISOString(),
    channel,
    recipientId,
    template,
    status,
    ...extra,
  };
  try {
    await fs.mkdir(LOG_DIR, { recursive: true });
    const logFile = path.join(LOG_DIR, `${channel}_${template}_log.json`);
    await fs.appendFile(logFile, JSON.stringify(entry) + "\n");
  } catch (_) {
    // Non-critical — log failure should not break send
  }
}

// ── Handler ──

export default async function handler(req, res) {
  try {
    const body = req.body || {};
    const { channel, recipientId, template, vars } = body;

    if (!channel || !template) {
      return res.status(400).json({
        ok: false,
        error: "Provide channel (messenger|instagram) and template",
      });
    }

    if (!["messenger", "instagram"].includes(channel)) {
      return res.status(400).json({
        ok: false,
        error: 'channel must be "messenger" or "instagram"',
      });
    }

    // Load and fill template
    const messageText = await loadTemplate(channel, template, vars || {});

    // If no recipientId, return the filled text for manual paste
    if (!recipientId) {
      await writeSocialLog(channel, "manual", template, "text_generated", {
        vars,
      });
      return res.status(200).json({
        ok: true,
        mode: "manual",
        channel,
        template,
        text: messageText,
        note: "No recipientId provided — paste this text manually into the DM.",
      });
    }

    // Attempt API send
    let result;
    if (channel === "messenger") {
      result = await sendMessengerDM(recipientId, messageText);
    } else {
      result = await sendInstagramDM(recipientId, messageText);
    }

    // Fallback: tokens not configured
    if (result.fallback) {
      await writeSocialLog(channel, recipientId, template, "fallback_text", {
        reason: result.reason,
        vars,
      });
      return res.status(200).json({
        ok: true,
        mode: "fallback",
        channel,
        template,
        text: result.text,
        reason: result.reason,
        note: "API token not configured. Paste this text manually.",
      });
    }

    if (result.sent) {
      await writeSocialLog(channel, recipientId, template, "sent", {
        messageId: result.messageId,
        vars,
      });
      return res.status(200).json({
        ok: true,
        mode: "api",
        channel,
        template,
        messageId: result.messageId,
      });
    }

    // API error
    await writeSocialLog(channel, recipientId, template, "failed", {
      error: result.error,
      vars,
    });
    return res
      .status(result.status || 500)
      .json({ ok: false, error: result.error });
  } catch (err) {
    console.error("sendSocialOutreach error:", err);
    const channel = req.body?.channel || "unknown";
    const template = req.body?.template || "unknown";
    await writeSocialLog(
      channel,
      req.body?.recipientId || "unknown",
      template,
      "error",
      { error: err.message },
    );
    return res.status(500).json({ ok: false, error: err.message });
  }
}
