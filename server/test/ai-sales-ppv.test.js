const assert = require("node:assert/strict");
const http = require("node:http");
const test = require("node:test");
const express = require("express");
const Stripe = require("stripe");

function loadApiRouter() {
  const modulePath = require.resolve("../apiStubs");
  delete require.cache[modulePath];
  return require("../apiStubs");
}

async function startServer(env = {}) {
  const previousEnv = {
    STRIPE_SECRET_KEY: process.env.STRIPE_SECRET_KEY,
    STRIPE_WEBHOOK_SECRET: process.env.STRIPE_WEBHOOK_SECRET,
    CHECKOUT_BASE_URL: process.env.CHECKOUT_BASE_URL,
    PAYPAL_REQUIRE_WEBHOOK_VERIFY: process.env.PAYPAL_REQUIRE_WEBHOOK_VERIFY,
    PAYPAL_WEBHOOK_VERIFY_BYPASS: process.env.PAYPAL_WEBHOOK_VERIFY_BYPASS,
  };

  for (const [key, value] of Object.entries(env)) {
    if (value === undefined || value === null) {
      delete process.env[key];
    } else {
      process.env[key] = String(value);
    }
  }

  const api = loadApiRouter();
  const app = express();
  app.use("/api", api);
  const server = http.createServer(app);

  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  const address = server.address();
  const port = typeof address === "object" && address ? address.port : 0;

  return {
    server,
    baseUrl: `http://127.0.0.1:${port}`,
    restoreEnv: () => {
      for (const [key, value] of Object.entries(previousEnv)) {
        if (value === undefined) {
          delete process.env[key];
        } else {
          process.env[key] = value;
        }
      }
      loadApiRouter();
    },
  };
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

test("ai sell endpoint returns message payload", async () => {
  const instance = await startServer();
  try {
    const response = await fetch(`${instance.baseUrl}/api/ai/sell`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        eventId: 999,
        audience: "email_list",
        offer: { title: "UFC 999", price: 49.99 },
      }),
    });

    assert.equal(response.status, 200);
    const payload = await response.json();
    assert.equal(payload.eventId, 999);
    assert.equal(payload.audience, "email_list");
    assert.ok(payload.messages.emailSubject.includes("UFC 999"));
    assert.ok(payload.messages.sms.includes("Get PPV access now"));
  } finally {
    await stopServer(instance.server);
    instance.restoreEnv();
  }
});

test("ppv session + payment webhook create entitlement", async () => {
  const instance = await startServer();
  try {
    const sessionResponse = await fetch(`${instance.baseUrl}/api/ppv/create-session`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ eventId: 999, priceCents: 4999, currency: "USD", userId: "fan_1" }),
    });

    assert.equal(sessionResponse.status, 201);
    const sessionPayload = await sessionResponse.json();
    assert.ok(sessionPayload.checkoutUrl.includes("session="));

    const webhookResponse = await fetch(`${instance.baseUrl}/api/webhook/payment`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        sessionId: sessionPayload.sessionId,
        eventId: 999,
        userId: "fan_1",
        amountCents: 4999,
        status: "paid",
      }),
    });

    assert.equal(webhookResponse.status, 200);
    const webhookPayload = await webhookResponse.json();
    assert.equal(webhookPayload.entitlement.userId, "fan_1");
    assert.equal(webhookPayload.entitlement.eventId, 999);

    const entitlementsResponse = await fetch(`${instance.baseUrl}/api/entitlements/fan_1`);
    assert.equal(entitlementsResponse.status, 200);
    const entitlementsPayload = await entitlementsResponse.json();
    assert.equal(entitlementsPayload.count, 1);
    assert.equal(entitlementsPayload.entitlements[0].status, "active");
  } finally {
    await stopServer(instance.server);
    instance.restoreEnv();
  }
});

test("stripe signature is enforced when webhook secret is configured", async () => {
  const webhookSecret = "whsec_test_secret";
  const instance = await startServer({
    STRIPE_SECRET_KEY: "sk_test_51ExampleDontUseInProd",
    STRIPE_WEBHOOK_SECRET: webhookSecret,
  });

  try {
    const responseWithoutSignature = await fetch(`${instance.baseUrl}/api/webhook/payment`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ eventId: 999, userId: "fan_2", status: "paid" }),
    });
    assert.equal(responseWithoutSignature.status, 400);

    const stripe = new Stripe("sk_test_51ExampleDontUseInProd", { apiVersion: "2024-06-20" });
    const stripeEventPayload = {
      id: "evt_test_123",
      object: "event",
      type: "checkout.session.completed",
      data: {
        object: {
          id: "cs_test_123",
          object: "checkout.session",
          amount_total: 4999,
          payment_status: "paid",
          metadata: {
            eventId: "999",
            userId: "fan_2",
            sku: "PPV-999",
          },
        },
      },
    };
    const rawBody = JSON.stringify(stripeEventPayload);
    const signature = stripe.webhooks.generateTestHeaderString({
      payload: rawBody,
      secret: webhookSecret,
    });

    const signedResponse = await fetch(`${instance.baseUrl}/api/webhook/payment`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "stripe-signature": signature,
      },
      body: rawBody,
    });
    assert.equal(signedResponse.status, 200);
    const signedPayload = await signedResponse.json();
    assert.equal(signedPayload.entitlement.userId, "fan_2");
    assert.equal(signedPayload.entitlement.eventId, 999);
  } finally {
    await stopServer(instance.server);
    instance.restoreEnv();
  }
});

test("paypal webhook accepts valid decimal amount and stores cents", async () => {
  const instance = await startServer({
    PAYPAL_REQUIRE_WEBHOOK_VERIFY: "true",
    PAYPAL_WEBHOOK_VERIFY_BYPASS: "true",
  });

  try {
    const response = await fetch(`${instance.baseUrl}/api/paypal/webhook`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        id: "WH-123",
        event_type: "PAYMENT.CAPTURE.COMPLETED",
        resource: {
          id: "CAPTURE-123",
          custom_id: "eventId=999;userId=fan_3",
          amount: { value: "49.99", currency_code: "USD" },
        },
      }),
    });

    assert.equal(response.status, 200);
    const payload = await response.json();
    assert.equal(payload.purchase.amountCents, 4999);
    assert.equal(payload.entitlement.userId, "fan_3");
    assert.equal(payload.entitlement.eventId, 999);
  } finally {
    await stopServer(instance.server);
    instance.restoreEnv();
  }
});

test("paypal webhook rejects invalid amount values", async () => {
  const instance = await startServer({
    PAYPAL_REQUIRE_WEBHOOK_VERIFY: "true",
    PAYPAL_WEBHOOK_VERIFY_BYPASS: "true",
  });

  try {
    const response = await fetch(`${instance.baseUrl}/api/paypal/webhook`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        id: "WH-124",
        event_type: "PAYMENT.CAPTURE.COMPLETED",
        resource: {
          id: "CAPTURE-124",
          custom_id: "eventId=999;userId=fan_4",
          amount: { value: "not-a-number", currency_code: "USD" },
        },
      }),
    });

    assert.equal(response.status, 400);
    const payload = await response.json();
    assert.equal(payload.error, "eventId, userId, and amountCents are required");
  } finally {
    await stopServer(instance.server);
    instance.restoreEnv();
  }
});
