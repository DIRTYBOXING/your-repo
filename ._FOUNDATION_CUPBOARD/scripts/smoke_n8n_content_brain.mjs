import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..");

function parseArgs(argv) {
  const args = {};
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith("--")) {
      continue;
    }

    const key = token.slice(2);
    const next = argv[index + 1];
    if (!next || next.startsWith("--")) {
      args[key] = "true";
      continue;
    }

    args[key] = next;
    index += 1;
  }
  return args;
}

function parseDotEnv(content) {
  const env = {};
  for (const rawLine of content.split(/\r?\n/u)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) {
      continue;
    }

    const separatorIndex = line.indexOf("=");
    if (separatorIndex === -1) {
      continue;
    }

    const key = line.slice(0, separatorIndex).trim();
    let value = line.slice(separatorIndex + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    env[key] = value;
  }
  return env;
}

async function loadFunctionsEnv() {
  const envPath = path.join(repoRoot, "functions", ".env");
  const content = await readFile(envPath, "utf8");
  return parseDotEnv(content);
}

function buildPayload() {
  const requestId = `n8n_smoke_${Date.now()}`;
  const posterUrl = "https://example.com/dfc-poster.png";
  const secondaryAssetUrl = "https://example.com/dfc-source.svg";
  return {
    webInput:
      "Create a short combat-sports promo pack for DFC smoke verification.",
    platform: "facebook",
    postType: "text",
    brandTone: "hype",
    audienceType: "fans",
    niche: "mma",
    objective: "engagement",
    requestId,
    eventData: {
      eventId: "dfc-smoke-event",
      title: "DFC Smoke Event",
      eventName: "DFC Smoke Event",
      posterUrl,
      thumbnailUrl: posterUrl,
      mediaUrls: [posterUrl, secondaryAssetUrl],
      promoterName: "DFC",
    },
    mediaPlan: {
      posterUrl,
      assetUrls: [posterUrl, secondaryAssetUrl],
    },
  };
}

function validateContentBrainShape(responseJson) {
  const issues = [];

  if (
    !responseJson ||
    typeof responseJson !== "object" ||
    Array.isArray(responseJson)
  ) {
    issues.push("response is not a JSON object");
    return issues;
  }

  if (!Array.isArray(responseJson.posts) || responseJson.posts.length === 0) {
    issues.push("posts[] is missing or empty");
  }

  if (
    typeof responseJson.headline !== "string" ||
    responseJson.headline.trim().length === 0
  ) {
    issues.push("headline is missing");
  }

  if (
    typeof responseJson.summary !== "string" ||
    responseJson.summary.trim().length === 0
  ) {
    issues.push("summary is missing");
  }

  if (typeof responseJson.viralScore !== "number") {
    issues.push("viralScore is missing or not numeric");
  }

  if (typeof responseJson.toneSummary !== "string") {
    issues.push("toneSummary is missing");
  }

  if (!Array.isArray(responseJson.suggestedMediaAssets)) {
    issues.push("suggestedMediaAssets is missing or not an array");
  }

  if (
    !responseJson.mediaPlan ||
    typeof responseJson.mediaPlan !== "object" ||
    Array.isArray(responseJson.mediaPlan)
  ) {
    issues.push("mediaPlan is missing");
  } else if (!Array.isArray(responseJson.mediaPlan.assetUrls)) {
    issues.push("mediaPlan.assetUrls is missing or not an array");
  }

  if (
    !responseJson.pipeline ||
    typeof responseJson.pipeline !== "object" ||
    Array.isArray(responseJson.pipeline)
  ) {
    issues.push("pipeline is missing");
  }

  return issues;
}

function printFailure(message, details) {
  console.error(message);
  if (details) {
    console.error(details);
  }
  process.exitCode = 1;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const env = await loadFunctionsEnv();

  const targetUrl = args.url || env.N8N_CONTENT_BRAIN_URL;
  const apiKey = args.apiKey || env.N8N_API_KEY || "";

  if (!targetUrl) {
    printFailure(
      "N8N content-brain smoke failed: N8N_CONTENT_BRAIN_URL is not configured.",
    );
    return;
  }

  const headers = {
    "Content-Type": "application/json",
  };

  if (apiKey) {
    headers.Authorization = `Bearer ${apiKey}`;
  }

  const payload = buildPayload();
  const response = await fetch(targetUrl, {
    method: "POST",
    headers,
    body: JSON.stringify(payload),
  });

  const rawBody = await response.text();
  let responseJson = null;
  try {
    responseJson = rawBody ? JSON.parse(rawBody) : null;
  } catch {
    responseJson = null;
  }

  if (!response.ok) {
    let hint = "";
    if (response.status === 404) {
      hint =
        "Meaning: the workflow is not imported, not active, or the webhook path is wrong.";
    } else if (response.status === 401 || response.status === 403) {
      hint =
        "Meaning: the webhook is protected. Either expose the webhook or set N8N_API_KEY for this smoke run.";
    }

    printFailure(
      `N8N content-brain smoke failed with HTTP ${response.status}.`,
      `${hint}\nURL: ${targetUrl}\nResponse: ${rawBody.slice(0, 500)}`,
    );
    return;
  }

  const issues = validateContentBrainShape(responseJson);
  if (issues.length > 0) {
    printFailure(
      "N8N content-brain smoke failed: response shape does not match the DFC contract.",
      `Issues: ${issues.join("; ")}\nResponse: ${rawBody.slice(0, 800)}`,
    );
    return;
  }

  const firstPost = responseJson.posts[0] || {};
  console.log("N8N content-brain smoke passed.");
  console.log(`URL: ${targetUrl}`);
  console.log(`Headline: ${responseJson.headline}`);
  console.log(
    `Platforms: ${responseJson.posts
      .map((post) => post.platform)
      .filter(Boolean)
      .join(", ")}`,
  );
  console.log(
    `Primary caption preview: ${String(firstPost.caption || "").slice(0, 120)}`,
  );
}

try {
  await main();
} catch (error) {
  printFailure(
    "N8N content-brain smoke crashed.",
    error instanceof Error ? error.stack || error.message : String(error),
  );
}
