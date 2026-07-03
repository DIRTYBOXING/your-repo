const assert = require("node:assert/strict");
const http = require("node:http");
const test = require("node:test");
const express = require("express");

function loadApiRouter() {
  const modulePath = require.resolve("../apiStubs");
  delete require.cache[modulePath];
  return require("../apiStubs");
}

async function startServer(env = {}) {
  const previousEnv = {
    REQUIRE_AUTH_FOR_PPV: process.env.REQUIRE_AUTH_FOR_PPV,
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

test("wallet topup + confirm + purchase updates balance and entitlements", async () => {
  const instance = await startServer({ REQUIRE_AUTH_FOR_PPV: "true" });

  try {
    const topupResponse = await fetch(`${instance.baseUrl}/api/wallet/topup`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: "Bearer u1",
      },
      body: JSON.stringify({
        userId: "u1",
        amountCents: 1000,
        provider: "stripe",
        idempotencyKey: "topup-1",
      }),
    });
    assert.equal(topupResponse.status, 201);
    const topupPayload = await topupResponse.json();
    assert.equal(topupPayload.userId, "u1");

    const confirmResponse = await fetch(`${instance.baseUrl}/api/wallet/topup/confirm`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        userId: "u1",
        walletTxId: topupPayload.walletTxId,
        amountCents: 1000,
        provider: "stripe",
        providerId: "evt_123",
        idempotencyKey: "confirm-1",
      }),
    });
    assert.equal(confirmResponse.status, 200);

    const walletAfterTopup = await fetch(`${instance.baseUrl}/api/wallet/u1`, {
      headers: { Authorization: "Bearer u1" },
    });
    assert.equal(walletAfterTopup.status, 200);
    const walletTopupJson = await walletAfterTopup.json();
    assert.equal(walletTopupJson.balanceCents, 1000);

    const purchaseResponse = await fetch(`${instance.baseUrl}/api/wallet/purchase`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: "Bearer u1",
      },
      body: JSON.stringify({
        userId: "u1",
        itemId: "clip_001",
        amountCents: 500,
        idempotencyKey: "purchase-1",
      }),
    });
    assert.equal(purchaseResponse.status, 200);
    const purchasePayload = await purchaseResponse.json();
    assert.equal(purchasePayload.entitlement.status, "active");

    const walletAfterPurchase = await fetch(`${instance.baseUrl}/api/wallet/u1`, {
      headers: { Authorization: "Bearer u1" },
    });
    const walletPurchaseJson = await walletAfterPurchase.json();
    assert.equal(walletPurchaseJson.balanceCents, 500);
  } finally {
    await stopServer(instance.server);
    instance.restoreEnv();
  }
});

test("wallet purchase fails with insufficient funds", async () => {
  const instance = await startServer({ REQUIRE_AUTH_FOR_PPV: "true" });

  try {
    const purchaseResponse = await fetch(`${instance.baseUrl}/api/wallet/purchase`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: "Bearer u2",
      },
      body: JSON.stringify({
        userId: "u2",
        itemId: "clip_002",
        amountCents: 500,
        idempotencyKey: "purchase-insufficient",
      }),
    });

    assert.equal(purchaseResponse.status, 402);
    const payload = await purchaseResponse.json();
    assert.equal(payload.error, "insufficient_funds");
  } finally {
    await stopServer(instance.server);
    instance.restoreEnv();
  }
});

test("wallet topup idempotency returns same walletTxId", async () => {
  const instance = await startServer({ REQUIRE_AUTH_FOR_PPV: "true" });

  try {
    const headers = {
      "Content-Type": "application/json",
      Authorization: "Bearer u3",
    };

    const requestBody = {
      userId: "u3",
      amountCents: 1000,
      provider: "paypal",
      idempotencyKey: "wallet-idem-1",
    };

    const firstResponse = await fetch(`${instance.baseUrl}/api/wallet/topup`, {
      method: "POST",
      headers,
      body: JSON.stringify(requestBody),
    });
    const secondResponse = await fetch(`${instance.baseUrl}/api/wallet/topup`, {
      method: "POST",
      headers,
      body: JSON.stringify(requestBody),
    });

    assert.equal(firstResponse.status, 201);
    assert.equal(secondResponse.status, 200);

    const firstPayload = await firstResponse.json();
    const secondPayload = await secondResponse.json();
    assert.equal(firstPayload.walletTxId, secondPayload.walletTxId);
  } finally {
    await stopServer(instance.server);
    instance.restoreEnv();
  }
});
