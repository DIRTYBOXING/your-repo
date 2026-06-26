import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";

const require = createRequire(import.meta.url);
const {
  isEmulatorEnabled,
  resolveBaseUrl,
} = require("../entitlements-service/helpers/functions_env.js");

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..");
const envFile = path.join(repoRoot, ".env");
const defaultProxyBaseUrls = ["http://127.0.0.1:8080", "http://127.0.0.1:4010"];
const requiredEnvChecks = [
  {
    name: "STRIPE_SECRET",
    envNames: ["STRIPE_SECRET", "STRIPE_SECRET_KEY"],
  },
  {
    name: "STRIPE_WEBHOOK_SECRET",
    envNames: ["STRIPE_WEBHOOK_SECRET"],
  },
  {
    name: "JWT_PRIVATE_KEY",
    envNames: ["JWT_PRIVATE_KEY", "JWT_PRIVATE_KEY_PATH"],
  },
  {
    name: "JWT_PUBLIC_KEY",
    envNames: ["JWT_PUBLIC_KEY", "JWT_PUBLIC_KEY_PATH"],
  },
  {
    name: "DRM_LICENSE_URL",
    envNames: ["DRM_LICENSE_URL"],
  },
];

function parseArgs(argv) {
  const options = {};
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (!arg.startsWith("--")) {
      continue;
    }

    const key = arg.slice(2);
    const nextValue = argv[index + 1];
    if (!nextValue || nextValue.startsWith("--")) {
      options[key] = "true";
      continue;
    }

    options[key] = nextValue;
    index += 1;
  }
  return options;
}

async function loadEnvFile(filePath) {
  try {
    const raw = await fs.readFile(filePath, "utf8");
    for (const line of raw.split(/\r?\n/)) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith("#")) {
        continue;
      }

      const separatorIndex = trimmed.indexOf("=");
      if (separatorIndex <= 0) {
        continue;
      }

      const key = trimmed.slice(0, separatorIndex).trim();
      if (!key || process.env[key]) {
        continue;
      }

      let value = trimmed.slice(separatorIndex + 1).trim();
      if (
        value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'")))
      ) {
        value = value.slice(1, -1);
      }

      process.env[key] = value;
    }
  } catch (error) {
    if (error.code !== "ENOENT") {
      throw error;
    }
  }
}

function normalizeBaseUrl(value) {
  return value.replace(/\/+$/, "");
}

function resolveProxyBaseCandidates(value) {
  if (typeof value === "string" && value.trim()) {
    return [normalizeBaseUrl(value.trim())];
  }

  return defaultProxyBaseUrls;
}

function findMissingEnvVars(env) {
  return requiredEnvChecks
    .filter(
      ({ envNames }) =>
        !envNames.some((name) => {
          const value = env[name];
          return typeof value === "string" && value.trim();
        }),
    )
    .map(({ name }) => name);
}

function buildFunctionTargetSummary() {
  const nodeEnv = (process.env.NODE_ENV || "").trim().toLowerCase();
  const explicitBase =
    typeof process.env.PPV_FUNCTIONS_BASE_URL === "string" &&
    process.env.PPV_FUNCTIONS_BASE_URL.trim().length > 0;
  const emulator = isEmulatorEnabled();
  const functionsBaseUrl = resolveBaseUrl();
  const defaultsToProduction =
    !explicitBase && !emulator && nodeEnv !== "production";

  return {
    nodeEnv: nodeEnv || "dev",
    explicitBase,
    emulator,
    defaultsToProduction,
    functionsBaseUrl,
  };
}

async function fetchJson(url) {
  if (typeof fetch !== "function") {
    throw new TypeError("Node fetch API unavailable in this runtime");
  }

  const response = await fetch(url, {
    headers: {
      Accept: "application/json",
    },
  });

  const responseText = await response.text();
  let body;
  try {
    body = JSON.parse(responseText);
  } catch {
    throw new Error(`Non-JSON response from ${url}: ${responseText}`);
  }

  return {
    ok: response.ok,
    status: response.status,
    body,
  };
}

async function probeProxy(candidates) {
  let lastError = null;

  for (const candidate of candidates) {
    try {
      const readyResponse = await fetchJson(`${candidate}/ready`);
      return {
        proxyBaseUrl: candidate,
        readyResponse,
        requestError: null,
      };
    } catch (error) {
      lastError = error instanceof Error ? error.message : String(error);
    }
  }

  return {
    proxyBaseUrl: candidates[0],
    readyResponse: null,
    requestError: lastError,
  };
}

export async function runReadinessCheck(options = {}) {
  if (options.loadEnvFile !== false) {
    await loadEnvFile(options.envFilePath || envFile);
  }

  const proxyCandidates = resolveProxyBaseCandidates(
    options.base || process.env.ENTITLEMENTS_SERVICE_BASE_URL,
  );
  const localMissing = findMissingEnvVars(process.env);
  const functionTarget = buildFunctionTargetSummary();

  const { proxyBaseUrl, readyResponse, requestError } =
    await probeProxy(proxyCandidates);

  const proxyMissing = Array.isArray(readyResponse?.body?.missing)
    ? readyResponse.body.missing
    : [];
  const proxyReady =
    readyResponse?.status === 200 && readyResponse?.body?.status === "ready";
  const checkoutProxyUrl = readyResponse?.body?.checkoutProxyUrl ?? null;
  const proxyTargetsProduction =
    typeof checkoutProxyUrl === "string" &&
    /cloudfunctions\.net/i.test(checkoutProxyUrl) &&
    !/127\.0\.0\.1|localhost/i.test(checkoutProxyUrl);
  const localEnvBlocking = !proxyReady && localMissing.length > 0;
  const functionTargetBlocking = proxyReady
    ? proxyTargetsProduction
    : functionTarget.defaultsToProduction;
  const ready = proxyReady && !localEnvBlocking && !functionTargetBlocking;

  const guidance = [];
  if (localEnvBlocking) {
    guidance.push(
      "Set the missing entitlement proxy env vars before using the local runtime outside smoke mode.",
    );
  }
  if (functionTargetBlocking) {
    guidance.push(
      "Set PPV_FUNCTIONS_BASE_URL or enable the Firebase emulator env so local verification does not fall through to the production Functions URL.",
    );
  }
  if (requestError) {
    guidance.push(
      "Start the entitlement proxy locally on port 8080 or set ENTITLEMENTS_SERVICE_BASE_URL to the proxy you want to verify.",
    );
  } else if (!proxyReady) {
    guidance.push(
      "Fix the missing runtime inputs reported by /ready before running the Priority 1 verification lane.",
    );
  }

  const summary = {
    ready,
    proxyBaseUrl,
    functionsBaseUrl: functionTarget.functionsBaseUrl,
    nodeEnv: functionTarget.nodeEnv,
    emulator: functionTarget.emulator,
    usesExplicitFunctionsBase: functionTarget.explicitBase,
    defaultsToProduction: functionTarget.defaultsToProduction,
    localMissing,
    proxyStatus: readyResponse?.status ?? null,
    proxyState: readyResponse?.body?.status ?? null,
    proxyMissing,
    checkoutProxyUrl,
    proxyTargetsProduction,
    requestError,
    guidance,
  };

  return summary;
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const summary = await runReadinessCheck(options);

  console.log(JSON.stringify(summary, null, 2));
  process.exit(summary.ready ? 0 : 1);
}

if (process.argv[1] && path.resolve(process.argv[1]) === __filename) {
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
}
