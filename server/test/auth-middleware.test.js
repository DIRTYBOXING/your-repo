const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const http = require("node:http");
const test = require("node:test");
const express = require("express");

function encodeBase64Url(input) {
  return Buffer.from(input)
    .toString("base64")
    .replaceAll("=", "")
    .replaceAll("+", "-")
    .replaceAll("/", "_");
}

function createHs256Jwt(payload, secret) {
  const header = { alg: "HS256", typ: "JWT" };
  const encodedHeader = encodeBase64Url(JSON.stringify(header));
  const encodedPayload = encodeBase64Url(JSON.stringify(payload));
  const signed = `${encodedHeader}.${encodedPayload}`;
  const signature = crypto
    .createHmac("sha256", secret)
    .update(signed)
    .digest("base64")
    .replaceAll("=", "")
    .replaceAll("+", "-")
    .replaceAll("/", "_");

  return `${signed}.${signature}`;
}

function loadApiRouter() {
  const modulePath = require.resolve("../apiStubs");
  delete require.cache[modulePath];
  return require("../apiStubs");
}

async function startServer(env = {}) {
  const trackedKeys = [
    "REQUIRE_AUTH_FOR_PPV",
    "JWT_SECRET",
    "ALLOW_OPAQUE_AUTH_TOKENS",
  ];
  const previousEnv = {};
  for (const key of trackedKeys) {
    previousEnv[key] = process.env[key];
  }

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

test("wallet endpoint requires auth when REQUIRE_AUTH_FOR_PPV=true", async () => {
  const instance = await startServer({ REQUIRE_AUTH_FOR_PPV: "true" });

  try {
    const response = await fetch(`${instance.baseUrl}/api/wallet/topup`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        userId: "fan_noauth",
        amountCents: 1000,
        provider: "stripe",
        idempotencyKey: "wallet-auth-required",
      }),
    });

    assert.equal(response.status, 401);
  } finally {
    await stopServer(instance.server);
    instance.restoreEnv();
  }
});

test("ppv session rejects user mismatch under auth", async () => {
  const instance = await startServer({ REQUIRE_AUTH_FOR_PPV: "true" });

  try {
    const response = await fetch(`${instance.baseUrl}/api/ppv/create-session`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: "Bearer auth_user_1",
      },
      body: JSON.stringify({
        eventId: 999,
        priceCents: 4999,
        currency: "USD",
        userId: "auth_user_2",
      }),
    });

    assert.equal(response.status, 403);
  } finally {
    await stopServer(instance.server);
    instance.restoreEnv();
  }
});

test("JWT auth works when JWT_SECRET is configured", async () => {
  const jwtSecret = "test_jwt_secret";
  const now = Math.floor(Date.now() / 1000);
  const token = createHs256Jwt({ sub: "jwt_user", exp: now + 300 }, jwtSecret);

  const instance = await startServer({
    REQUIRE_AUTH_FOR_PPV: "true",
    JWT_SECRET: jwtSecret,
    ALLOW_OPAQUE_AUTH_TOKENS: "false",
  });

  try {
    const response = await fetch(`${instance.baseUrl}/api/wallet/jwt_user`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    assert.equal(response.status, 200);
    const payload = await response.json();
    assert.equal(payload.userId, "jwt_user");
  } finally {
    await stopServer(instance.server);
    instance.restoreEnv();
  }
});

test("opaque token is rejected when JWT_SECRET is configured and opaque disabled", async () => {
  const instance = await startServer({
    REQUIRE_AUTH_FOR_PPV: "true",
    JWT_SECRET: "test_jwt_secret",
    ALLOW_OPAQUE_AUTH_TOKENS: "false",
  });

  try {
    const response = await fetch(`${instance.baseUrl}/api/wallet/opaque_user`, {
      headers: {
        Authorization: "Bearer opaque_user",
      },
    });

    assert.equal(response.status, 401);
  } finally {
    await stopServer(instance.server);
    instance.restoreEnv();
  }
});
