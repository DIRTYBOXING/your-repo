import process from "node:process";
import { createRequire } from "node:module";
import { generateKeyPairSync } from "node:crypto";

import { runReadinessCheck } from "./ppv_runtime_readiness_check.mjs";

const require = createRequire(import.meta.url);
const { createApp } = require("../entitlements-service/server");

function setEnv(overrides) {
  const previous = new Map();
  for (const [key, value] of Object.entries(overrides)) {
    previous.set(key, process.env[key]);
    process.env[key] = value;
  }

  return () => {
    for (const [key, value] of previous.entries()) {
      if (value === undefined) {
        delete process.env[key];
      } else {
        process.env[key] = value;
      }
    }
  };
}

async function closeServer(server) {
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
  const port = 8091;
  const { privateKey, publicKey } = generateKeyPairSync("rsa", {
    modulusLength: 2048,
    publicKeyEncoding: { type: "spki", format: "pem" },
    privateKeyEncoding: { type: "pkcs8", format: "pem" },
  });

  const restoreEnv = setEnv({
    STRIPE_SECRET: "stripe_secret_runtime_mock", // pragma: allowlist secret
    STRIPE_WEBHOOK_SECRET: "whsec_runtime", // pragma: allowlist secret
    JWT_PRIVATE_KEY: privateKey,
    JWT_PUBLIC_KEY: publicKey,
    DRM_LICENSE_URL: "https://drm.local/license",
    PPV_FUNCTIONS_BASE_URL:
      "http://127.0.0.1:5001/datafightcentral/australia-southeast1",
    ENTITLEMENTS_SERVICE_BASE_URL: `http://127.0.0.1:${port}`,
    NODE_ENV: "development",
  });

  const app = createApp({
    config: {
      STRIPE_SECRET: process.env.STRIPE_SECRET,
      STRIPE_WEBHOOK_SECRET: process.env.STRIPE_WEBHOOK_SECRET,
      JWT_PRIVATE_KEY: process.env.JWT_PRIVATE_KEY,
      JWT_PUBLIC_KEY: process.env.JWT_PUBLIC_KEY,
      DRM_LICENSE_URL: process.env.DRM_LICENSE_URL,
      NODE_ENV: process.env.NODE_ENV,
    },
    buildFunctionUrlFn: () =>
      "http://127.0.0.1:5001/datafightcentral/australia-southeast1/createPPVCheckoutSession",
    jtiStore: {
      isJtiConsumed: async () => false,
      markJtiConsumed: async () => true,
    },
    canonicalPpv: {
      getCheckoutSession: async () => null,
      markSessionComplete: async () => true,
      resolveEntitlement: async () => null,
    },
  });

  const server = await new Promise((resolve, reject) => {
    const listener = app.listen(port, () => resolve(listener));
    listener.on("error", reject);
  });

  try {
    const summary = await runReadinessCheck({
      base: process.env.ENTITLEMENTS_SERVICE_BASE_URL,
      loadEnvFile: false,
    });
    console.log(JSON.stringify(summary, null, 2));
    process.exitCode = summary.ready ? 0 : 1;
  } finally {
    await closeServer(server);
    restoreEnv();
  }
}

try {
  await main();
} catch (error) {
  console.error(
    JSON.stringify(
      {
        ready: false,
        error: error instanceof Error ? error.message : String(error),
      },
      null,
      2,
    ),
  );
  process.exit(1);
}
