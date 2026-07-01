import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..");

const surfaces = [
  {
    path: "docs/DFC_STREAMING_DOCTRINE_V1.md",
    requiredSnippets: [
      "streaming_doctrine_v1",
      "primaryPlatform",
      "VS Code heartbeat",
    ],
  },
  {
    path: "docs/DFC_STACK_BLUEPRINT_V1.md",
    requiredSnippets: [
      "Firebase + GCP is the control plane",
      "n8n only as optional automation glue",
      "Do Not Build",
    ],
  },
  {
    path: "docs/DFC_N8N_WORKFLOW_REBUILD.md",
    requiredSnippets: [
      "DFC Content Brain",
      "DFC Publisher",
      "Five-Step Go-Live Checklist",
    ],
  },
  {
    path: "functions/content/content_brain.js",
    requiredSnippets: [
      "STREAMING_DOCTRINE_V1",
      "streamingDoctrineV1",
      "primaryPlatform",
    ],
  },
  {
    path: "lib/shared/services/n8n_service.dart",
    requiredSnippets: ["getStreamingDoctrine", "streamingDoctrineV1"],
  },
  {
    path: "lib/features/content_brain/screens/content_brain_screen.dart",
    requiredSnippets: ["Streaming Doctrine v1", "_loadStreamingDoctrine"],
  },
  {
    path: ".github/prompts/dfc-brain.prompt.md",
    requiredSnippets: [
      "streaming_doctrine_v1",
      "Firebase + GCP is the control plane",
      "n8n is optional automation glue",
    ],
  },
  {
    path: ".github/prompts/dfc-brain-interface.prompt.md",
    requiredSnippets: [
      "recommendedNextAction",
      "riskFlags",
      "canonical control plane",
    ],
  },
  {
    path: "n8n/flows/dfc_content_brain_minimal.json",
    requiredSnippets: [
      "DFC Content Brain Minimal",
      "Webhook Brain Request",
      "Generate Structured Content",
    ],
  },
  {
    path: "n8n/flows/dfc_publisher_minimal.json",
    requiredSnippets: [
      "DFC Publisher Minimal",
      "Post to Facebook Page",
      "Respond Publish Result",
    ],
  },
  {
    path: "scripts/smoke_n8n_content_brain.mjs",
    requiredSnippets: [
      "N8N content-brain smoke passed.",
      "validateContentBrainShape",
      "N8N_CONTENT_BRAIN_URL",
    ],
  },
  {
    path: ".vscode/tasks.json",
    requiredSnippets: [
      "DFC Brain: Heartbeat",
      "scripts/dfc_brain_heartbeat.mjs",
    ],
  },
];

async function main() {
  const missing = [];

  for (const surface of surfaces) {
    const absolutePath = path.join(repoRoot, surface.path);

    try {
      const content = await readFile(absolutePath, "utf8");
      const absentSnippets = surface.requiredSnippets.filter(
        (snippet) => !content.includes(snippet),
      );

      if (absentSnippets.length > 0) {
        missing.push({
          path: surface.path,
          missing: absentSnippets,
        });
      }
    } catch (error) {
      missing.push({
        path: surface.path,
        missing: ["file_unreadable"],
        error: error.message,
      });
    }
  }

  if (missing.length > 0) {
    console.error("DFC Brain heartbeat failed. Missing doctrine surfaces:");
    for (const failure of missing) {
      const errorSuffix = failure.error ? ` (${failure.error})` : "";
      console.error(
        `- ${failure.path}: ${failure.missing.join(", ")}${errorSuffix}`,
      );
    }
    process.exitCode = 1;
    return;
  }

  console.log("DFC Brain heartbeat healthy.");
  console.log("Objective: streaming_doctrine_v1");
  console.log(
    "Primary lane: Mux live ingest + signed HLS playback on DFC-owned surfaces.",
  );
  console.log(
    "Conditional lane: WebRTC premium room only when lowLatencyTier is enabled.",
  );
  console.log(
    "Guardrail: external platforms remain acquisition lanes, not the primary paid watch surface.",
  );
}

try {
  await main();
} catch (error) {
  console.error("DFC Brain heartbeat crashed:", error);
  process.exitCode = 1;
}
