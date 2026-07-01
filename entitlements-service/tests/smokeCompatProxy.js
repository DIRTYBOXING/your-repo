"use strict";

const assert = require("node:assert/strict");
const { generateKeyPairSync } = require("node:crypto");
const http = require("node:http");

const { createApp } = require("../server");

function sessionSortKey(session) {
  return Date.parse(session.completedAt || session.createdAt || 0) || 0;
}

function toResponseBuffer(body) {
  if (Buffer.isBuffer(body)) {
    return body;
  }

  if (typeof body === "string") {
    return Buffer.from(body);
  }

  return Buffer.from(JSON.stringify(body));
}

function createResponse({ status = 200, body = "", headers = {} }) {
  const normalizedHeaders = new Map(
    Object.entries(headers).map(([key, value]) => [key.toLowerCase(), value]),
  );

  return {
    ok: status >= 200 && status < 300,
    status,
    headers: {
      get(name) {
        return normalizedHeaders.get(String(name).toLowerCase()) || null;
      },
    },
    async json() {
      if (typeof body === "string") {
        return JSON.parse(body);
      }

      return body;
    },
    async text() {
      if (typeof body === "string") {
        return body;
      }

      if (Buffer.isBuffer(body)) {
        return body.toString("utf8");
      }

      return JSON.stringify(body);
    },
    async arrayBuffer() {
      const buffer = toResponseBuffer(body);
      return buffer.buffer.slice(
        buffer.byteOffset,
        buffer.byteOffset + buffer.byteLength,
      );
    },
  };
}

function createInMemoryCanonicalPpv() {
  const sessions = new Map();

  return {
    sessions,
    async getCheckoutSession(sessionId) {
      return sessions.get(sessionId) || null;
    },
    async markSessionComplete(sessionId, payload = {}) {
      const existing = sessions.get(sessionId) || { sessionId };
      const completedAt = payload.completedAt || new Date().toISOString();
      sessions.set(sessionId, {
        ...existing,
        ...payload,
        sessionId,
        status: "complete",
        completedAt,
        createdAt: existing.createdAt || payload.createdAt || completedAt,
      });
      return true;
    },
    async resolveEntitlement({ userId, ppvId, sessionId }) {
      if (sessionId) {
        const direct = sessions.get(sessionId);
        if (
          direct &&
          direct.userId === userId &&
          direct.ppvId === ppvId &&
          direct.status === "complete"
        ) {
          return direct;
        }
      }

      const matches = [...sessions.values()]
        .filter(
          (session) =>
            session.userId === userId &&
            session.ppvId === ppvId &&
            session.status === "complete",
        )
        .sort((left, right) => sessionSortKey(right) - sessionSortKey(left));

      return matches[0] || null;
    },
  };
}

function createInMemoryJtiStore() {
  const consumed = new Set();

  return {
    async isJtiConsumed(jti) {
      return consumed.has(jti);
    },
    async markJtiConsumed(jti) {
      if (consumed.has(jti)) {
        return false;
      }

      consumed.add(jti);
      return true;
    },
  };
}

async function startServer(app) {
  const server = http.createServer(app);
  await new Promise((resolve) => {
    server.listen(0, "127.0.0.1", resolve);
  });
  return server;
}

async function stopServer(server) {
  await new Promise((resolve, reject) => {
    server.close((error) => {
      if (error) {
        reject(error);
        return;
      }

      resolve();
    });
  });
}

async function main() {
  const { privateKey, publicKey } = generateKeyPairSync("rsa", {
    modulusLength: 2048,
    privateKeyEncoding: { type: "pkcs8", format: "pem" },
    publicKeyEncoding: { type: "spki", format: "pem" },
  });

  const eventId = "ppv-smoke-event";
  const userId = "user-smoke-1";
  const canonicalPpv = createInMemoryCanonicalPpv();
  const jtiStore = createInMemoryJtiStore();
  const outboundCalls = [];
  const drmLicenseUrl = "https://drm.local/license";

  const app = createApp({
    config: {
      STRIPE_SECRET: "stripe_secret_smoke", // pragma: allowlist secret
      STRIPE_WEBHOOK_SECRET: "whsec_smoke", // pragma: allowlist secret
      JWT_PRIVATE_KEY: privateKey,
      JWT_PUBLIC_KEY: publicKey,
      TOKEN_TTL: "120",
      DRM_LICENSE_URL: drmLicenseUrl,
      FRONTEND_URL: "https://datafightcentral.local",
      NODE_ENV: "test",
    },
    canonicalPpv,
    jtiStore,
    getCanonicalPpvEvent: async (ppvId) => {
      if (ppvId !== eventId) {
        return null;
      }

      return {
        id: eventId,
        title: "Smoke Test Event",
        currency: "AUD",
        vipPriceCents: 4999,
        standardPriceCents: 2999,
      };
    },
    buildFunctionUrlFn: (functionName) =>
      `https://functions.local/${functionName}`,
    fetchFn: async (url, options = {}) => {
      outboundCalls.push({ url, options });

      if (url === "https://functions.local/createPPVCheckoutSession") {
        const payload = JSON.parse(options.body || "{}");
        const data = payload.data || {};
        const sessionId = "cs_smoke_proxy_001";
        canonicalPpv.sessions.set(sessionId, {
          sessionId,
          userId: data.userId,
          ppvId: data.ppvId,
          status: "pending",
          source: data.checkoutSource,
          amountCents: data.amountCents,
          currency: data.currency,
          createdAt: new Date().toISOString(),
        });

        return createResponse({
          status: 200,
          headers: { "content-type": "application/json" },
          body: {
            result: {
              url: "https://checkout.stripe.com/pay/cs_smoke_proxy_001",
              sessionId,
              amountCents: data.amountCents,
            },
          },
        });
      }

      if (url === drmLicenseUrl) {
        return createResponse({
          status: 200,
          headers: { "content-type": "application/octet-stream" },
          body: Buffer.from("license-ok", "utf8"),
        });
      }

      throw new Error(`Unexpected outbound URL: ${url}`);
    },
    logger: {
      error: (...args) => console.error(...args),
      warn: (...args) => console.warn(...args),
      log: () => {},
    },
  });

  const server = await startServer(app);
  const address = server.address();
  const baseUrl = `http://127.0.0.1:${address.port}`;

  try {
    const healthResponse = await fetch(`${baseUrl}/health`);
    assert.equal(healthResponse.status, 200);
    const healthBody = await healthResponse.json();
    assert.equal(healthBody.status, "ok");
    assert.equal(healthBody.ready, true);
    assert.equal(healthBody.mode, "canonical_ppv_compat_proxy");
    assert.equal(healthBody.checks.stripeSecret, true);
    assert.equal(healthBody.checks.checkoutProxyUrl, true);

    const readyResponse = await fetch(`${baseUrl}/ready`);
    assert.equal(readyResponse.status, 200);
    const readyBody = await readyResponse.json();
    assert.equal(readyBody.status, "ready");
    assert.equal(
      readyBody.checkoutProxyUrl,
      "https://functions.local/createPPVCheckoutSession",
    );

    const checkoutResponse = await fetch(`${baseUrl}/checkout`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        user_id: userId,
        event_id: eventId,
        tier: "vip",
      }),
    });
    assert.equal(checkoutResponse.status, 200);
    const checkoutBody = await checkoutResponse.json();
    assert.equal(checkoutBody.session_id, "cs_smoke_proxy_001");
    assert.equal(checkoutBody.tier, "vip");

    const orderResponse = await fetch(
      `${baseUrl}/orders/${checkoutBody.session_id}`,
    );
    assert.equal(orderResponse.status, 200);
    const orderBody = await orderResponse.json();
    assert.equal(orderBody.status, "pending");

    await canonicalPpv.markSessionComplete(checkoutBody.session_id, {
      userId,
      ppvId: eventId,
      source: "smoke-complete",
    });

    const tokenResponse = await fetch(`${baseUrl}/entitlements/token`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        user_id: userId,
        event_id: eventId,
        session_id: checkoutBody.session_id,
      }),
    });
    assert.equal(tokenResponse.status, 200);
    const tokenBody = await tokenResponse.json();
    assert.ok(tokenBody.token);
    assert.equal(tokenBody.session_id, checkoutBody.session_id);

    const validateResponse = await fetch(`${baseUrl}/validate`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ playbackToken: tokenBody.token }),
    });
    assert.equal(validateResponse.status, 200);
    const validateBody = await validateResponse.json();
    assert.equal(validateBody.ok, true);
    assert.equal(validateBody.userId, userId);
    assert.equal(validateBody.eventId, eventId);

    const licenseResponse = await fetch(`${baseUrl}/license`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${tokenBody.token}`,
        "Content-Type": "application/octet-stream",
      },
      body: Buffer.from("license-request", "utf8"),
    });
    assert.equal(licenseResponse.status, 200);
    const licenseText = Buffer.from(
      await licenseResponse.arrayBuffer(),
    ).toString("utf8");
    assert.equal(licenseText, "license-ok");

    const secondLicenseResponse = await fetch(`${baseUrl}/license`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${tokenBody.token}`,
        "Content-Type": "application/octet-stream",
      },
      body: Buffer.from("license-request", "utf8"),
    });
    assert.equal(secondLicenseResponse.status, 403);
    const secondLicenseText = await secondLicenseResponse.text();
    assert.equal(secondLicenseText, "token already used");

    assert.equal(outboundCalls.length, 2);
    assert.equal(
      outboundCalls[0].url,
      "https://functions.local/createPPVCheckoutSession",
    );
    assert.equal(outboundCalls[1].url, drmLicenseUrl);

    console.log("compat proxy smoke passed");
  } finally {
    await stopServer(server);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
