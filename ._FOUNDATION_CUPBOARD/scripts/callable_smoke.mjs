import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";
import { deleteApp, initializeApp } from "firebase/app";
import {
  connectFunctionsEmulator,
  getFunctions,
  httpsCallable,
} from "firebase/functions";

const defaultBaseUrl =
  "http://127.0.0.1:5001/datafightcentral/australia-southeast1";
const defaultFunctionChecks = ["healthCheck", "approvalsStats"];
const callableTimeoutMs = 30000;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..");
const envFile = path.join(repoRoot, ".env");

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

function splitList(value) {
  if (typeof value !== "string") {
    return [];
  }

  return [
    ...new Set(
      value
        .split(",")
        .map((entry) => entry.trim())
        .filter(Boolean),
    ),
  ];
}

function resolveTarget(options) {
  const rawBaseUrl =
    options["base-url"] || process.env.PPV_FUNCTIONS_BASE_URL || defaultBaseUrl;
  const parsedBaseUrl = new URL(rawBaseUrl);
  const pathSegments = parsedBaseUrl.pathname.split("/").filter(Boolean);
  const host =
    options.host ||
    process.env.FUNCTIONS_EMULATOR_HOST ||
    parsedBaseUrl.hostname ||
    "127.0.0.1";
  const port = Number.parseInt(
    options.port ||
      process.env.FUNCTIONS_EMULATOR_PORT ||
      parsedBaseUrl.port ||
      "5001",
    10,
  );

  if (!Number.isInteger(port) || port <= 0) {
    throw new Error(
      `Invalid Functions emulator port: ${options.port || parsedBaseUrl.port}`,
    );
  }

  const projectId =
    options.project ||
    process.env.PPV_PROJECT_ID ||
    pathSegments[0] ||
    "datafightcentral";
  const region =
    options.region ||
    process.env.PPV_REGION ||
    pathSegments[1] ||
    "australia-southeast1";

  return {
    baseUrl: `${parsedBaseUrl.protocol}//${host}:${port}/${projectId}/${region}`,
    host,
    port,
    projectId,
    region,
  };
}

function resolveChecks(options) {
  const requestedChecks = splitList(
    options.functions || process.env.CALLABLE_SMOKE_FUNCTIONS,
  );

  return requestedChecks.length > 0 ? requestedChecks : defaultFunctionChecks;
}

function extractRegistryNames(body) {
  const backends = Array.isArray(body?.backends) ? body.backends : [];
  const names = [];

  for (const backend of backends) {
    const functionTriggers = Array.isArray(backend?.functionTriggers)
      ? backend.functionTriggers
      : [];

    for (const trigger of functionTriggers) {
      const name = trigger?.name || trigger?.entryPoint || trigger?.id;
      if (typeof name === "string" && name.trim()) {
        names.push(name);
      }
    }
  }

  return [...new Set(names)];
}

async function fetchRegistrySummary(target) {
  if (typeof fetch !== "function") {
    return {
      ok: false,
      error: "Node fetch API unavailable in this runtime",
    };
  }

  const registryUrl = `http://${target.host}:${target.port}/backends`;

  try {
    const response = await fetch(registryUrl, {
      headers: {
        Accept: "application/json",
      },
    });

    const responseText = await response.text();
    let body;
    try {
      body = JSON.parse(responseText);
    } catch {
      throw new Error(`Non-JSON response from ${registryUrl}: ${responseText}`);
    }

    if (!response.ok) {
      throw new Error(
        `Functions emulator returned ${response.status} for ${registryUrl}`,
      );
    }

    const functionNames = extractRegistryNames(body);
    return {
      ok: true,
      backendCount: Array.isArray(body?.backends) ? body.backends.length : 0,
      functionTriggerCount: functionNames.length,
      functionNames,
      sampleFunctions: functionNames.slice(0, 10),
    };
  } catch (error) {
    return {
      ok: false,
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

async function invokeCallable(functions, name) {
  const startedAt = Date.now();

  try {
    const callable = httpsCallable(functions, name, {
      timeout: callableTimeoutMs,
    });
    const result = await callable({});
    return {
      name,
      ok: true,
      durationMs: Date.now() - startedAt,
      data: result.data,
    };
  } catch (error) {
    return {
      name,
      ok: false,
      durationMs: Date.now() - startedAt,
      code: typeof error?.code === "string" ? error.code : null,
      message: error instanceof Error ? error.message : String(error),
      details:
        error && typeof error === "object" && "details" in error
          ? error.details
          : null,
    };
  }
}

async function main() {
  await loadEnvFile(envFile);

  const options = parseArgs(process.argv.slice(2));
  const target = resolveTarget(options);
  const checks = resolveChecks(options);
  const registry = await fetchRegistrySummary(target);

  const app = initializeApp(
    {
      apiKey: "demo-key", // pragma: allowlist secret
      appId: `callable-smoke-${target.projectId}`,
      projectId: target.projectId,
    },
    `callable-smoke-${process.pid}-${Date.now()}`,
  );

  const functions = getFunctions(app, target.region);
  connectFunctionsEmulator(functions, target.host, target.port);

  let results;
  try {
    results = [];
    for (const name of checks) {
      results.push(await invokeCallable(functions, name));
    }
  } finally {
    await deleteApp(app);
  }

  const failures = results.filter((result) => !result.ok);
  const registryWarning =
    registry.ok && registry.functionTriggerCount === 0
      ? "The emulator responded on /backends with no registered triggers. In the full suite this endpoint is not authoritative, so callable results are used as the source of truth."
      : null;
  const missingFromRegistry =
    registry.ok && registry.functionTriggerCount > 0
      ? checks.filter((name) => !registry.functionNames.includes(name))
      : [];

  console.log(
    JSON.stringify(
      {
        target,
        registry,
        registryWarning,
        checks,
        missingFromRegistry,
        results,
      },
      null,
      2,
    ),
  );

  return failures.length === 0 ? 0 : 1;
}

try {
  process.exitCode = await main();
} catch (error) {
  console.error(
    JSON.stringify(
      {
        error: error instanceof Error ? error.message : String(error),
      },
      null,
      2,
    ),
  );
  process.exitCode = 1;
}
