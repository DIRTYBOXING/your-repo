import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import { deleteApp, initializeApp } from "firebase/app";
import { getFunctions, httpsCallableFromURL } from "firebase/functions";

const callableTimeoutMs = 30000;
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..");
const envFile = path.join(repoRoot, ".env");
const firebaseOptionsFile = path.join(repoRoot, "lib", "firebase_options.dart");
const require = createRequire(import.meta.url);
const {
  resolveBaseUrl,
  resolveProjectId,
  resolveRegion,
} = require("../entitlements-service/helpers/functions_env.js");

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

function normalizeBooleanFlag(value) {
  return (
    typeof value === "string" &&
    ["1", "true", "yes", "on"].includes(value.trim().toLowerCase())
  );
}

function stripTrailingSlash(value) {
  return value.replace(/\/+$/, "");
}

function isLoopbackHost(hostname) {
  return ["127.0.0.1", "localhost", "::1"].includes(hostname.toLowerCase());
}

async function readWebFirebaseConfig(filePath) {
  const source = await fs.readFile(filePath, "utf8");
  const blockMatch = source.match(
    /static const FirebaseOptions web = FirebaseOptions\(([\s\S]*?)\n  \);/,
  );
  if (!blockMatch) {
    throw new Error(`Unable to locate web FirebaseOptions in ${filePath}`);
  }

  const block = blockMatch[1];
  const fields = [
    "apiKey",
    "appId",
    "messagingSenderId",
    "projectId",
    "authDomain",
    "databaseURL",
    "storageBucket",
    "measurementId",
  ];
  const config = {};

  for (const field of fields) {
    const match = block.match(new RegExp(`${field}:\\s*'([^']+)'`));
    if (match) {
      config[field] = match[1];
    }
  }

  if (!config.apiKey || !config.appId || !config.projectId) {
    throw new Error("Web FirebaseOptions are missing required fields");
  }

  return config;
}

function resolveTarget(options, firebaseConfig) {
  if (typeof options.project === "string" && options.project.trim()) {
    process.env.PPV_PROJECT_ID = options.project.trim();
  }
  if (typeof options.region === "string" && options.region.trim()) {
    process.env.PPV_REGION = options.region.trim();
  }

  const baseUrl = stripTrailingSlash(options["base-url"] || resolveBaseUrl());
  const parsedBaseUrl = new URL(baseUrl);
  const projectId = resolveProjectId();
  const region = resolveRegion();
  const allowEmulator = normalizeBooleanFlag(options["allow-emulator"]);
  const emulatorTarget = isLoopbackHost(parsedBaseUrl.hostname);

  if (projectId !== firebaseConfig.projectId) {
    throw new Error(
      `Resolved project ${projectId} does not match web Firebase config ${firebaseConfig.projectId}`,
    );
  }

  if (emulatorTarget && !allowEmulator) {
    throw new Error(
      "Refusing to target a local Functions base URL without --allow-emulator",
    );
  }

  return {
    allowEmulator,
    emulatorTarget,
    baseUrl,
    functionUrl: `${baseUrl}/testMuxAuth`,
    projectId,
    region,
  };
}

function extractError(error) {
  return {
    code: typeof error?.code === "string" ? error.code : null,
    message: error instanceof Error ? error.message : String(error),
    details:
      error && typeof error === "object" && "details" in error
        ? error.details
        : null,
  };
}

async function main() {
  await loadEnvFile(envFile);

  const options = parseArgs(process.argv.slice(2));
  const firebaseConfig = await readWebFirebaseConfig(firebaseOptionsFile);
  const target = resolveTarget(options, firebaseConfig);
  const smokeToken = (
    options["smoke-token"] ||
    process.env.PPV_SMOKE_TOKEN ||
    ""
  ).trim();

  const app = initializeApp(
    firebaseConfig,
    `mux-auth-smoke-${process.pid}-${Date.now()}`,
  );
  const functions = getFunctions(app, target.region);
  const callable = httpsCallableFromURL(functions, target.functionUrl, {
    timeout: callableTimeoutMs,
  });

  try {
    const result = await callable(smokeToken ? { smokeToken } : {});
    console.log(
      JSON.stringify(
        {
          target,
          firebase: {
            projectId: firebaseConfig.projectId,
            appId: firebaseConfig.appId,
            authDomain: firebaseConfig.authDomain,
            storageBucket: firebaseConfig.storageBucket,
          },
          result: {
            ok: true,
            data: result.data,
          },
        },
        null,
        2,
      ),
    );
    return 0;
  } catch (error) {
    console.log(
      JSON.stringify(
        {
          target,
          firebase: {
            projectId: firebaseConfig.projectId,
            appId: firebaseConfig.appId,
            authDomain: firebaseConfig.authDomain,
            storageBucket: firebaseConfig.storageBucket,
          },
          result: {
            ok: false,
            ...extractError(error),
          },
        },
        null,
        2,
      ),
    );
    return 1;
  } finally {
    await deleteApp(app);
  }
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
