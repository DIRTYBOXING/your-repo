// ═══════════════════════════════════════════════════════════════════════════
// SHARED CONFIGURATION — All modules import from here
// ═══════════════════════════════════════════════════════════════════════════

const admin = require("firebase-admin");
const { FieldValue, Timestamp } = require("firebase-admin/firestore");
const { defineSecret } = require("firebase-functions/params");

// Initialize Firebase Admin (singleton)
if (admin.apps.length === 0) {
  admin.initializeApp();
}

if (!admin.firestore.FieldValue) {
  admin.firestore.FieldValue = FieldValue;
}

if (!admin.firestore.Timestamp) {
  admin.firestore.Timestamp = Timestamp;
}

const db = admin.firestore();
const REGION = "australia-southeast1";

// ─── Stripe ──────────────────────────────────────────────────────────────
const STRIPE_SECRET_KEY_PARAM = defineSecret("STRIPE_SECRET_KEY");
const MUX_TOKEN_ID_PARAM = defineSecret("MUX_TOKEN_ID");
const MUX_TOKEN_SECRET_PARAM = defineSecret("MUX_TOKEN_SECRET");
const MUX_SIGNING_KEY_ID_PARAM = defineSecret("MUX_SIGNING_KEY_ID");
const MUX_SIGNING_PRIVATE_KEY_PARAM = defineSecret("MUX_SIGNING_PRIVATE_KEY");
const MUX_WEBHOOK_SECRET_PARAM = defineSecret("MUX_WEBHOOK_SECRET");
const PPV_SMOKE_TOKEN_PARAM = defineSecret("PPV_SMOKE_TOKEN");
const DFC_ADMIN_SA_KEY_PARAM = defineSecret("DFC_ADMIN_SERVICE_ACCOUNT_KEY");
const ALLOW_STRIPE_LIVE_MODE =
  (process.env.ALLOW_STRIPE_LIVE_MODE || "").trim().toLowerCase() === "true";

let stripeClient = null;
let stripeClientKey = null;

function resolveStripeKey() {
  const envKey = (process.env.STRIPE_SECRET_KEY || "").trim();
  if (envKey) return envKey;

  try {
    return (STRIPE_SECRET_KEY_PARAM.value() || "").trim();
  } catch {
    return "";
  }
}

function getStripe() {
  try {
    const Stripe = require("stripe");
    const stripeKey = resolveStripeKey();
    if (!stripeKey) return null;
    if (
      (stripeKey.startsWith("sk_live_") || stripeKey.startsWith("rk_live_")) &&
      !ALLOW_STRIPE_LIVE_MODE
    ) {
      console.error(
        "Stripe live mode blocked. Set ALLOW_STRIPE_LIVE_MODE=true to enable live Stripe access.",
      );
      return null;
    }

    if (stripeClient && stripeClientKey === stripeKey) {
      return stripeClient;
    }

    stripeClient = new Stripe(stripeKey, { apiVersion: "2024-12-18.acacia" });
    stripeClientKey = stripeKey;
    return stripeClient;
  } catch {
    return null;
  }
}

function withStripeSecret(options = {}) {
  const existingSecrets = Array.isArray(options.secrets) ? options.secrets : [];
  if (existingSecrets.includes(STRIPE_SECRET_KEY_PARAM)) {
    return options;
  }

  return {
    ...options,
    secrets: [...existingSecrets, STRIPE_SECRET_KEY_PARAM],
  };
}

function resolveSecretValue(envName, param) {
  const envValue = (process.env[envName] || "").trim();
  if (envValue) return envValue;

  try {
    return (param.value() || "").trim();
  } catch {
    return "";
  }
}

function withMuxSecrets(options = {}) {
  const existingSecrets = Array.isArray(options.secrets) ? options.secrets : [];
  const muxSecrets = [
    MUX_TOKEN_ID_PARAM,
    MUX_TOKEN_SECRET_PARAM,
    MUX_SIGNING_KEY_ID_PARAM,
    MUX_SIGNING_PRIVATE_KEY_PARAM,
    MUX_WEBHOOK_SECRET_PARAM,
  ];

  return {
    ...options,
    secrets: [...new Set([...existingSecrets, ...muxSecrets])],
  };
}

function getMuxRuntimeConfig() {
  return {
    tokenId: resolveSecretValue("MUX_TOKEN_ID", MUX_TOKEN_ID_PARAM),
    tokenSecret: resolveSecretValue("MUX_TOKEN_SECRET", MUX_TOKEN_SECRET_PARAM),
    signingKeyId: resolveSecretValue(
      "MUX_SIGNING_KEY_ID",
      MUX_SIGNING_KEY_ID_PARAM,
    ),
    signingPrivateKey: resolveSecretValue(
      "MUX_SIGNING_PRIVATE_KEY",
      MUX_SIGNING_PRIVATE_KEY_PARAM,
    ),
    webhookSecret: resolveSecretValue(
      "MUX_WEBHOOK_SECRET",
      MUX_WEBHOOK_SECRET_PARAM,
    ),
  };
}

// Returns the parsed service-account object (or null if not available).
// Functions that need it must declare DFC_ADMIN_SA_KEY_PARAM in their secrets array.
function getDFCAdminServiceAccount() {
  const raw = resolveSecretValue(
    "DFC_ADMIN_SERVICE_ACCOUNT_KEY",
    DFC_ADMIN_SA_KEY_PARAM,
  );
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    console.error("DFC_ADMIN_SERVICE_ACCOUNT_KEY is not valid JSON");
    return null;
  }
}

function withDFCAdminSecret(options = {}) {
  const existingSecrets = Array.isArray(options.secrets) ? options.secrets : [];
  if (existingSecrets.includes(DFC_ADMIN_SA_KEY_PARAM)) return options;
  return { ...options, secrets: [...existingSecrets, DFC_ADMIN_SA_KEY_PARAM] };
}

const stripe = new Proxy(
  {},
  {
    get(_target, prop) {
      const client = getStripe();
      if (!client) return undefined;

      const value = client[prop];
      return typeof value === "function" ? value.bind(client) : value;
    },
  },
);

const STRIPE_WEBHOOK_SECRET = process.env.STRIPE_WEBHOOK_SECRET || "";

// ─── RSS Feed Parser ─────────────────────────────────────────────────────
let Parser = null;
try {
  Parser = require("rss-parser");
} catch {
  Parser = null;
}

// ─── SendGrid ────────────────────────────────────────────────────────────
let sgMail = null;
try {
  sgMail = require("@sendgrid/mail");
  const sgKey = process.env.SENDGRID_API_KEY;
  if (sgKey) {
    sgMail.setApiKey(sgKey);
  } else {
    sgMail = null;
  }
} catch {
  sgMail = null;
}

// ─── Google Gemini AI ─────────────────────────────────────────────────
let geminiModel = null;
try {
  const { GoogleGenerativeAI } = require("@google/generative-ai");
  const geminiKey = process.env.GEMINI_KEY;
  if (geminiKey) {
    const genAI = new GoogleGenerativeAI(geminiKey);
    geminiModel = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });
  }
} catch {
  // @google/generative-ai not installed
}

module.exports = {
  admin,
  db,
  FieldValue,
  Timestamp,
  REGION,
  stripe,
  getStripe,
  withStripeSecret,
  withMuxSecrets,
  getMuxRuntimeConfig,
  STRIPE_SECRET_KEY_PARAM,
  STRIPE_WEBHOOK_SECRET,
  MUX_TOKEN_ID_PARAM,
  MUX_TOKEN_SECRET_PARAM,
  MUX_SIGNING_KEY_ID_PARAM,
  MUX_SIGNING_PRIVATE_KEY_PARAM,
  MUX_WEBHOOK_SECRET_PARAM,
  PPV_SMOKE_TOKEN_PARAM,
  DFC_ADMIN_SA_KEY_PARAM,
  getDFCAdminServiceAccount,
  withDFCAdminSecret,
  Parser,
  sgMail,
  geminiModel,
  FROM_EMAIL: "info@datafightcentral.com",
};
