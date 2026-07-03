// entitlements-service/server.js
"use strict";

const fs = require("node:fs");
const express = require("express");
const bodyParser = require("body-parser");
const jwt = require("jsonwebtoken");
const Stripe = require("stripe");
const { v4: uuidv4 } = require("uuid");
const { buildFunctionUrl } = require("./helpers/functions_env");
const {
  normalizeCallableError,
  normalizeCallableResponse,
} = require("./helpers/callable_normalizer");
const { normalizeTierKey, resolveTier } = require("./helpers/price_mapping");

function pickFirstString(...values) {
  for (const value of values) {
    if (typeof value === "string" && value.trim()) {
      return value.trim();
    }
  }

  return null;
}

function normalizePemString(value) {
  const normalized = pickFirstString(value);
  if (!normalized) {
    return null;
  }

  return normalized.replaceAll(String.raw`\n`, "\n");
}

function readSecretFromFile(filePath) {
  const normalizedPath = pickFirstString(filePath);
  if (!normalizedPath) {
    return null;
  }

  try {
    const content = fs.readFileSync(normalizedPath, "utf8").trim();
    return content || null;
  } catch {
    return null;
  }
}

function resolveKeyMaterial(value, filePath) {
  return normalizePemString(value) || readSecretFromFile(filePath);
}

function createHttpError(statusCode, code, message) {
  const error = new Error(message);
  error.statusCode = statusCode;
  error.code = code;
  return error;
}

function createConfig(env = process.env) {
  return {
    STRIPE_SECRET: pickFirstString(env.STRIPE_SECRET, env.STRIPE_SECRET_KEY),
    STRIPE_WEBHOOK_SECRET: pickFirstString(env.STRIPE_WEBHOOK_SECRET),
    JWT_PRIVATE_KEY: resolveKeyMaterial(
      env.JWT_PRIVATE_KEY,
      env.JWT_PRIVATE_KEY_PATH,
    ),
    JWT_PUBLIC_KEY: resolveKeyMaterial(
      env.JWT_PUBLIC_KEY,
      env.JWT_PUBLIC_KEY_PATH,
    ),
    TOKEN_TTL: pickFirstString(env.TOKEN_TTL),
    DRM_LICENSE_URL: pickFirstString(env.DRM_LICENSE_URL),
    PORT: pickFirstString(env.PORT),
    NODE_ENV: pickFirstString(env.NODE_ENV),
    FRONTEND_URL: pickFirstString(env.FRONTEND_URL),
  };
}

function normalizeFirebaseCredentialEnv(env = process.env) {
  if (pickFirstString(env.GOOGLE_APPLICATION_CREDENTIALS)) {
    return;
  }

  const firebaseCredentials = pickFirstString(env.FIREBASE_CREDENTIALS);
  if (firebaseCredentials) {
    env.GOOGLE_APPLICATION_CREDENTIALS = firebaseCredentials;
  }
}

function requireConfigValue(config, key, code) {
  const value = pickFirstString(config?.[key]);
  if (value) {
    return value;
  }

  throw createHttpError(
    500,
    code || "missing_config",
    `${key} env var required`,
  );
}

function hasConfigValue(config, key) {
  return Boolean(pickFirstString(config?.[key]));
}

function buildRuntimeState(config, buildFunctionUrlFn) {
  let checkoutProxyUrl = null;
  try {
    checkoutProxyUrl = buildFunctionUrlFn("createPPVCheckoutSession");
  } catch {
    checkoutProxyUrl = null;
  }

  const checks = {
    stripeSecret: hasConfigValue(config, "STRIPE_SECRET"),
    stripeWebhookSecret: hasConfigValue(config, "STRIPE_WEBHOOK_SECRET"),
    jwtPrivateKey: hasConfigValue(config, "JWT_PRIVATE_KEY"),
    jwtPublicKey: hasConfigValue(config, "JWT_PUBLIC_KEY"),
    drmLicenseUrl: hasConfigValue(config, "DRM_LICENSE_URL"),
    checkoutProxyUrl: Boolean(checkoutProxyUrl),
  };

  const optional = {
    frontendUrl: hasConfigValue(config, "FRONTEND_URL"),
    tokenTtl: hasConfigValue(config, "TOKEN_TTL"),
  };

  const capabilities = {
    checkout: checks.checkoutProxyUrl,
    webhookVerification: checks.stripeSecret && checks.stripeWebhookSecret,
    entitlementTokenIssuance: checks.jwtPrivateKey,
    entitlementValidation: checks.jwtPublicKey,
    drmLicenseProxy: checks.jwtPublicKey && checks.drmLicenseUrl,
  };

  return {
    env: config.NODE_ENV || "dev",
    mode: "canonical_ppv_compat_proxy",
    ready: Object.values(checks).every(Boolean),
    checks,
    optional,
    capabilities,
    missing: Object.entries(checks)
      .filter(([, present]) => !present)
      .map(([name]) => name),
    checkoutProxyUrl,
  };
}

function resolveFetchFn(fetchFn) {
  if (typeof fetchFn === "function") {
    return fetchFn;
  }

  if (typeof globalThis.fetch === "function") {
    return globalThis.fetch.bind(globalThis);
  }

  throw new Error("Fetch API unavailable for entitlements service");
}

function getFirebaseAdmin() {
  normalizeFirebaseCredentialEnv();
  const admin = require("firebase-admin");
  if (!admin.apps.length) {
    admin.initializeApp();
  }

  return admin;
}

function createDefaultGetCanonicalPpvEvent() {
  return async function getCanonicalPpvEvent(ppvId) {
    if (!ppvId) return null;

    const admin = getFirebaseAdmin();
    const db = admin.firestore();
    const directDoc = await db.collection("ppv_events").doc(ppvId).get();
    if (directDoc.exists) {
      return { id: directDoc.id, ...directDoc.data() };
    }

    const eventIdQuery = await db
      .collection("ppv_events")
      .where("eventId", "==", ppvId)
      .limit(1)
      .get();

    if (!eventIdQuery.empty) {
      const doc = eventIdQuery.docs[0];
      return { id: doc.id, ...doc.data() };
    }

    return null;
  };
}

function parseUserIdFromSubject(subject) {
  const raw = pickFirstString(subject);
  if (!raw) {
    return null;
  }

  return raw.startsWith("user:") ? raw.slice(5) : raw;
}

function createApp(options = {}) {
  const config = options.config || createConfig(options.env);
  const logger = options.logger || console;
  const fetchFn = resolveFetchFn(options.fetchFn);
  const canonicalPpv = options.canonicalPpv || require("./canonical_ppv");
  const jtiStore = options.jtiStore || require("./jtiStore");
  const getCanonicalPpvEvent =
    options.getCanonicalPpvEvent || createDefaultGetCanonicalPpvEvent();
  const buildFunctionUrlFn = options.buildFunctionUrlFn || buildFunctionUrl;
  const createStripeClient =
    options.createStripeClient ||
    ((secret) => new Stripe(secret, { apiVersion: "2022-11-15" }));

  let stripeClient = options.stripeClient || null;

  function getStripeClient() {
    if (!stripeClient) {
      const stripeSecret = requireConfigValue(
        config,
        "STRIPE_SECRET",
        "stripe_not_configured",
      );
      stripeClient = createStripeClient(stripeSecret);
    }

    return stripeClient;
  }

  function verifyEntitlementToken(token) {
    const publicKey = requireConfigValue(
      config,
      "JWT_PUBLIC_KEY",
      "jwt_public_key_missing",
    );
    return jwt.verify(token, publicKey, {
      algorithms: ["RS256"],
      audience: "dfc-player-v1",
    });
  }

  async function validateEntitlementToken(token) {
    let decoded;
    try {
      decoded = verifyEntitlementToken(token);
    } catch (err) {
      throw createHttpError(
        401,
        "invalid_token",
        err.message || "invalid token",
      );
    }

    const userId = parseUserIdFromSubject(decoded.sub);
    const eventId = pickFirstString(decoded.event_id, decoded.eventId);
    const sessionId = pickFirstString(decoded.session_id, decoded.sessionId);

    if (!userId || !eventId) {
      throw createHttpError(
        401,
        "invalid_token_claims",
        "token is missing user or event claims",
      );
    }

    const entitlement = await canonicalPpv.resolveEntitlement({
      userId,
      ppvId: eventId,
      sessionId,
    });

    if (!entitlement) {
      throw createHttpError(
        403,
        "no_complete_checkout_session",
        "no complete checkout session",
      );
    }

    return {
      decoded,
      userId,
      eventId,
      sessionId: entitlement.sessionId,
      entitlement,
    };
  }

  async function getLegacyStripePrice(priceId) {
    const price = await getStripeClient().prices.retrieve(priceId);
    if (!price || price.deleted || price.active === false) {
      throw createHttpError(
        400,
        "invalid_price_id",
        "price_id does not reference an active Stripe Price",
      );
    }

    if (!Number.isInteger(price.unit_amount)) {
      throw createHttpError(
        400,
        "invalid_price_id",
        "price_id does not expose a unit_amount for tier resolution",
      );
    }

    return price;
  }

  async function normalizeCheckoutRequest(body = {}) {
    const userId = pickFirstString(body.userId, body.user_id);
    const requestedPpvId = pickFirstString(
      body.ppvId,
      body.ppv_id,
      body.eventId,
      body.event_id,
    );
    const requestedTier = pickFirstString(
      body.tier,
      body.tierKey,
      body.tier_key,
    );
    const legacyPriceId = pickFirstString(body.priceId, body.price_id);

    if (!userId || !requestedPpvId) {
      throw createHttpError(
        400,
        "invalid_request",
        "user_id/userId and event_id/ppvId are required",
      );
    }

    if (!requestedTier && !legacyPriceId) {
      throw createHttpError(
        400,
        "invalid_request",
        "Provide either tier or price_id",
      );
    }

    const event = await getCanonicalPpvEvent(requestedPpvId);
    if (!event) {
      throw createHttpError(
        404,
        "ppv_not_found",
        "PPV event could not be resolved",
      );
    }

    if (requestedTier && !normalizeTierKey(requestedTier)) {
      throw createHttpError(400, "invalid_tier", "tier is not recognized");
    }

    const stripePrice =
      !requestedTier && legacyPriceId
        ? await getLegacyStripePrice(legacyPriceId)
        : null;

    const tier = resolveTier({
      eventData: event,
      tier: requestedTier,
      priceId: legacyPriceId,
      price: stripePrice,
      unitAmount: stripePrice?.unit_amount ?? null,
    });

    if (!tier) {
      throw createHttpError(
        400,
        "tier_resolution_failed",
        "Unable to resolve a canonical PPV tier from the provided tier/price_id",
      );
    }

    const base = config.FRONTEND_URL || "https://datafightcentral.com";
    return {
      userId,
      ppvId: event.id,
      event,
      legacyPriceId,
      promoCode: pickFirstString(body.promoCode, body.promo_code),
      tier,
      successUrl:
        pickFirstString(body.successUrl, body.success_url) ||
        `${base}/ppv/${event.id}/success?session_id={CHECKOUT_SESSION_ID}`,
      cancelUrl:
        pickFirstString(body.cancelUrl, body.cancel_url) ||
        `${base}/ppv/${event.id}`,
    };
  }

  async function invokeCanonicalCheckout(normalizedCheckout) {
    const callableUrl = buildFunctionUrlFn("createPPVCheckoutSession");
    const response = await fetchFn(callableUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify({
        data: {
          userId: normalizedCheckout.userId,
          ppvId: normalizedCheckout.ppvId,
          ppvTitle:
            normalizedCheckout.event.title ||
            normalizedCheckout.event.name ||
            normalizedCheckout.event.subtitle ||
            "DFC Event",
          tierId: normalizedCheckout.tier.tierId,
          tierName: normalizedCheckout.tier.displayName,
          tierKey: normalizedCheckout.tier.tierName,
          amountCents: normalizedCheckout.tier.amountCents,
          currency: normalizedCheckout.tier.currency,
          promoCode: normalizedCheckout.promoCode || undefined,
          successUrl: normalizedCheckout.successUrl,
          cancelUrl: normalizedCheckout.cancelUrl,
          checkoutSource: "entitlements-service-compat-proxy",
          legacyPriceId: normalizedCheckout.legacyPriceId || "",
        },
      }),
    });

    const contentType = response.headers.get("content-type") || "";
    const responseBody = contentType.includes("application/json")
      ? await response.json()
      : await response.text();

    if (!response.ok) {
      throw normalizeCallableError(
        { statusCode: response.status, body: responseBody },
        "Canonical PPV checkout callable failed",
      );
    }

    const normalizedResponse = normalizeCallableResponse(responseBody);
    if (
      normalizedResponse &&
      typeof normalizedResponse === "object" &&
      normalizedResponse.error
    ) {
      throw normalizeCallableError(
        { statusCode: response.status, body: normalizedResponse },
        "Canonical PPV checkout callable returned an error payload",
      );
    }

    return normalizedResponse;
  }

  function describeRuntimeState() {
    return buildRuntimeState(config, buildFunctionUrlFn);
  }

  const app = express();

  app.use((req, res, next) => {
    if (req.originalUrl === "/webhook/stripe") {
      bodyParser.raw({ type: "application/json" })(req, res, next);
    } else {
      bodyParser.json({ limit: "1mb" })(req, res, next);
    }
  });

  app.post("/checkout", async (req, res) => {
    try {
      const normalizedCheckout = await normalizeCheckoutRequest(req.body);
      const result = await invokeCanonicalCheckout(normalizedCheckout);

      if (result?.alreadyPurchased) {
        return res.status(409).json({
          error: "already_purchased",
          message:
            result.message || "You already have access to this PPV event",
        });
      }

      if (!result?.url || !result?.sessionId) {
        throw createHttpError(
          502,
          "invalid_callable_response",
          "Canonical PPV checkout callable did not return a checkout URL and session ID",
        );
      }

      return res.json({
        checkout_url: result.url,
        session_id: result.sessionId,
        amount_cents: result.amountCents ?? normalizedCheckout.tier.amountCents,
        currency: normalizedCheckout.tier.currency,
        tier: normalizedCheckout.tier.tierKey,
        tier_id: normalizedCheckout.tier.tierId,
        tier_name: normalizedCheckout.tier.tierName,
      });
    } catch (err) {
      logger.error("[checkout] error", err);
      return res.status(err.statusCode || 500).json({
        error: err.code || "checkout_failed",
        message: err.message || "checkout failed",
      });
    }
  });

  app.post("/webhook/stripe", async (req, res) => {
    const sig = req.headers["stripe-signature"];
    let event;
    try {
      const webhookSecret = requireConfigValue(
        config,
        "STRIPE_WEBHOOK_SECRET",
        "webhook_secret_not_configured",
      );
      event = getStripeClient().webhooks.constructEvent(
        req.body,
        sig,
        webhookSecret,
      );
    } catch (err) {
      logger.error("[webhook] signature verification failed", err);
      return res
        .status(err.statusCode || 400)
        .send(`Webhook Error: ${err.message}`);
    }

    try {
      if (event.type === "checkout.session.completed") {
        const session = event.data.object;
        const checkoutSource = session.metadata?.checkoutSource || "";
        if (checkoutSource === "entitlements-service") {
          await canonicalPpv.markSessionComplete(session.id, {
            userId: session.metadata?.dfcUserId || null,
            ppvId: session.metadata?.ppvId || null,
            priceId: session.metadata?.priceId || null,
            stripePaymentIntentId: session.payment_intent || null,
            amountCents: session.amount_total || null,
            currency: session.currency || null,
            source: "entitlements-service-webhook",
          });
          logger.log(
            "[webhook] legacy entitlements-service PPV session marked complete:",
            session.id,
          );
        } else {
          logger.log(
            "[webhook] skipping non-legacy PPV session completion:",
            session.id,
          );
        }
      }
    } catch (err) {
      logger.error("[webhook] processing error", err);
    }

    return res.json({ received: true });
  });

  app.post("/entitlements/token", async (req, res) => {
    try {
      const { user_id, session_id, order_id, event_id } = req.body;
      if (!user_id || !event_id) {
        return res.status(400).json({ error: "user_id and event_id required" });
      }

      const entitlement = await canonicalPpv.resolveEntitlement({
        userId: user_id,
        ppvId: event_id,
        sessionId: session_id || order_id || null,
      });

      if (!entitlement) {
        return res.status(403).json({ error: "no_complete_checkout_session" });
      }

      const privateKey = requireConfigValue(
        config,
        "JWT_PRIVATE_KEY",
        "jwt_private_key_missing",
      );
      const jti = uuidv4();
      const now = Math.floor(Date.now() / 1000);
      const ttl = Number.parseInt(config.TOKEN_TTL || "120", 10);

      const payload = {
        sub: `user:${user_id}`,
        session_id: entitlement.sessionId,
        event_id,
        aud: "dfc-player-v1",
        scope: "playback",
        iat: now,
        exp: now + ttl,
        jti,
      };

      const token = jwt.sign(payload, privateKey, { algorithm: "RS256" });
      return res.json({
        token,
        expires_in: ttl,
        jti,
        session_id: entitlement.sessionId,
      });
    } catch (err) {
      logger.error("[entitlements/token] error", err);
      return res.status(err.statusCode || 500).json({
        error: err.code || "token_issuance_failed",
        message: err.message || "token issuance failed",
      });
    }
  });

  app.post("/validate", async (req, res) => {
    try {
      const { playbackToken } = req.body || {};
      if (!playbackToken) {
        return res.status(400).json({ error: "missing token" });
      }

      const validated = await validateEntitlementToken(playbackToken);
      return res.json({
        ok: true,
        userId: validated.userId,
        eventId: validated.eventId,
        sessionId: validated.sessionId,
        jti: validated.decoded.jti || null,
      });
    } catch (err) {
      logger.error("[validate] error", err);
      return res.status(err.statusCode || 500).json({
        error: err.code || "validation_failed",
        message: err.message || "validation failed",
      });
    }
  });

  app.post(
    "/license",
    bodyParser.raw({ type: "*/*", limit: "1mb" }),
    async (req, res) => {
      try {
        const auth = req.headers.authorization || "";
        const match = /^Bearer (.+)$/.exec(auth);
        if (!match) return res.status(401).send("missing entitlement token");

        const token = match[1];
        const validated = await validateEntitlementToken(token);
        const decoded = validated.decoded;

        if (!decoded.jti) return res.status(400).send("missing jti");

        const consumed = await jtiStore.isJtiConsumed(decoded.jti);
        if (consumed) return res.status(403).send("token already used");

        const ttlRemaining = Math.max(
          60,
          (decoded.exp || 0) - Math.floor(Date.now() / 1000),
        );
        const ok = await jtiStore.markJtiConsumed(decoded.jti, ttlRemaining);
        if (!ok) return res.status(403).send("token already used");

        const drmLicenseUrl = requireConfigValue(
          config,
          "DRM_LICENSE_URL",
          "drm_license_not_configured",
        );
        const upstream = await fetchFn(drmLicenseUrl, {
          method: "POST",
          headers: { "Content-Type": "application/octet-stream" },
          body: req.body,
        });

        if (!upstream.ok) {
          logger.error("[license] upstream DRM error", upstream.status);
          return res.status(502).send("license upstream error");
        }

        const licenseBuffer = await upstream.arrayBuffer();
        res.set("Content-Type", "application/octet-stream");
        return res.status(200).send(Buffer.from(licenseBuffer));
      } catch (err) {
        if (err?.statusCode) {
          logger.warn("[license] entitlement denied", err.message);
          return res
            .status(err.statusCode)
            .send(err.message || "license denied");
        }
        logger.error("[license] proxy error", err);
        return res.status(500).send("license proxy failed");
      }
    },
  );

  app.get("/orders/:id", async (req, res) => {
    const session = await canonicalPpv.getCheckoutSession(req.params.id);
    if (!session) return res.status(404).json({ error: "not found" });
    return res.json(session);
  });

  app.get("/health", (_req, res) => {
    const runtime = describeRuntimeState();
    return res.json({
      status: "ok",
      env: runtime.env,
      mode: runtime.mode,
      ready: runtime.ready,
      checks: runtime.checks,
      optional: runtime.optional,
      capabilities: runtime.capabilities,
      missing: runtime.missing,
      checkoutProxyUrl: runtime.checkoutProxyUrl,
    });
  });

  app.get("/ready", (_req, res) => {
    const runtime = describeRuntimeState();
    return res.status(runtime.ready ? 200 : 503).json({
      status: runtime.ready ? "ready" : "not_ready",
      env: runtime.env,
      mode: runtime.mode,
      checks: runtime.checks,
      capabilities: runtime.capabilities,
      missing: runtime.missing,
      checkoutProxyUrl: runtime.checkoutProxyUrl,
    });
  });

  return app;
}

function startServer(options = {}) {
  const config = options.config || createConfig(options.env);
  const app = createApp({ ...options, config });
  const port = Number.parseInt(config.PORT || "8080", 10);
  return app.listen(port, () =>
    console.log(`[entitlements-service] listening on ${port}`),
  );
}

if (require.main === module) {
  startServer();
}

module.exports = {
  createApp,
  createConfig,
  parseUserIdFromSubject,
  startServer,
};
