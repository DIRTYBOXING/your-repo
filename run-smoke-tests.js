// run-smoke-tests.js
// Node 18+, requires newman to be installed locally or globally.
// Usage: node run-smoke-tests.js
import fs from "node:fs";
import net from "node:net";
import path from "node:path";
import { fileURLToPath } from "node:url";

process.noDeprecation = true;

const originalEmitWarning = process.emitWarning.bind(process);
process.emitWarning = (warning, ...args) => {
  let code;

  if (typeof warning === "object" && warning !== null && "code" in warning) {
    code = warning.code;
  } else if (typeof args[0] === "string") {
    code = args[0];
  }

  if (code === "DEP0176") {
    return;
  }

  return originalEmitWarning(warning, ...args);
};

const { default: newman } = await import("newman");

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const collectionFile = process.env.SMOKE_COLLECTION_FILE
  ? path.resolve(__dirname, process.env.SMOKE_COLLECTION_FILE)
  : path.join(
      __dirname,
      "docs",
      "postman",
      "DFC-Core-APIs.postman_collection.json",
    );
const envFile = process.env.SMOKE_ENV_FILE
  ? path.resolve(__dirname, process.env.SMOKE_ENV_FILE)
  : path.join(__dirname, "docs", "postman", "DFC-Dev.postman_environment.json");
const reportsDir = path.join(__dirname, "reports");

fs.mkdirSync(reportsDir, { recursive: true });

function getEnvironmentMap(environment) {
  return new Map(
    (environment.values ?? []).map((entry) => [entry.key, entry.value ?? ""]),
  );
}

function resolveVar(key, envMap) {
  const override = envOverrides.find((entry) => entry.key === key)?.value;
  return override ?? envMap.get(key) ?? "";
}

function validatePreflight(environment) {
  const envMap = getEnvironmentMap(environment);
  const issues = [];
  const atlasBase = resolveVar("ATLAS_BASE", envMap);
  const callableBase = resolveVar("CALLABLE_BASE", envMap);

  if (callableBase) {
    if (
      !callableBase.startsWith("http://") &&
      !callableBase.startsWith("https://")
    ) {
      issues.push("CALLABLE_BASE must be an absolute http(s) URL");
    }
    return { profile: "callable", baseUrl: callableBase, issues };
  }

  const requiredTokens = [
    "BOT_JWT",
    "ADMIN_JWT",
    "PROMOTER_JWT",
    "ATLAS_SERVICE_JWT",
  ];
  const missingTokens = requiredTokens.filter(
    (key) => !resolveVar(key, envMap),
  );

  if (!atlasBase) {
    issues.push("ATLAS_BASE is not set");
  } else if (atlasBase.includes("atlas.api.internal")) {
    issues.push(
      "ATLAS_BASE still points at the placeholder internal host atlas.api.internal",
    );
  }

  if (missingTokens.length > 0) {
    issues.push(`Missing required JWTs: ${missingTokens.join(", ")}`);
  }

  return { profile: "atlas", baseUrl: atlasBase, issues };
}

function checkTcpReachability(urlString) {
  const url = new URL(urlString);
  let port;
  if (url.port) {
    port = Number.parseInt(url.port, 10);
  } else {
    port = url.protocol === "https:" ? 443 : 80;
  }

  return new Promise((resolve) => {
    const socket = net.createConnection({ host: url.hostname, port });
    socket.setTimeout(3000);
    socket.on("connect", () => {
      socket.destroy();
      resolve(true);
    });
    socket.on("timeout", () => {
      socket.destroy();
      resolve(false);
    });
    socket.on("error", () => {
      socket.destroy();
      resolve(false);
    });
  });
}

// Allow environment overrides from CI secrets
const envOverrides = [];
if (process.env.ATLAS_BASE)
  envOverrides.push({ key: "ATLAS_BASE", value: process.env.ATLAS_BASE });
if (process.env.BOT_JWT)
  envOverrides.push({ key: "BOT_JWT", value: process.env.BOT_JWT });
if (process.env.ADMIN_JWT)
  envOverrides.push({ key: "ADMIN_JWT", value: process.env.ADMIN_JWT });
if (process.env.PROMOTER_JWT)
  envOverrides.push({ key: "PROMOTER_JWT", value: process.env.PROMOTER_JWT });
if (process.env.ATLAS_SERVICE_JWT)
  envOverrides.push({
    key: "ATLAS_SERVICE_JWT",
    value: process.env.ATLAS_SERVICE_JWT,
  });

const options = {
  collection: JSON.parse(fs.readFileSync(collectionFile, "utf8")),
  environment: JSON.parse(fs.readFileSync(envFile, "utf8")),
  reporters: ["cli", "json"],
  reporter: { json: { export: path.join(reportsDir, "smoke-results.json") } },
  timeoutRequest: 30000,
  insecure: false,
};

if (envOverrides.length > 0) {
  options.envVar = envOverrides;
}

const preflight = validatePreflight(options.environment);
if (preflight.issues.length > 0) {
  console.error("Smoke test preflight failed:");
  preflight.issues.forEach((issue) => console.error(`- ${issue}`));
  console.error(
    "Provide real values via environment variables or update docs/postman/DFC-Dev.postman_environment.json.",
  );
  process.exit(3);
}

if (preflight.profile === "callable") {
  const reachable = await checkTcpReachability(preflight.baseUrl);
  if (!reachable) {
    console.error("Smoke test preflight failed:");
    console.error(
      `- Callable emulator is not reachable at ${preflight.baseUrl}`,
    );
    console.error(
      "Start the Firebase Functions emulator locally before running the callable smoke suite.",
    );
    process.exit(4);
  }
}

newman.run(options, function (err, summary) {
  if (err) {
    console.error("Newman run failed", err);
    process.exit(2);
  }
  const failures = summary.run.failures || [];
  if (failures.length > 0) {
    console.error(`Smoke tests failed. Failures: ${failures.length}`);
    failures.forEach((f) => console.error(f.source.name, f.error?.message));
    process.exit(1);
  }
  console.log("Smoke tests passed.", {
    totalRequests: summary.run.stats.requests.total,
    assertions: summary.run.stats.assertions.total,
    failures: summary.run.stats.assertions.failed,
  });
  process.exit(0);
});
