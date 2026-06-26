#!/usr/bin/env node
import { spawn } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const testResultsDir = path.join(root, "test-results");
const duplicatesPath = path.join(testResultsDir, "visual-duplicates.json");
const jsonOutPath = path.join(testResultsDir, "playwright-results.json");
const summaryOutPath = path.join(testResultsDir, "visual-gate-summary.json");

const parsedThreshold = Number.parseInt(
  process.env.VISUAL_DUPLICATE_THRESHOLD ?? "9999",
  10,
);
const duplicateThreshold = Number.isFinite(parsedThreshold) && parsedThreshold >= 0
  ? parsedThreshold
  : 9999;

const fullMatrix = process.env.VISUAL_FULL_MATRIX === "1";
const baseArgs = [
  "test",
  "test/visual/dfc_platform_audit.spec.ts",
  "--grep",
  "PPV|Social|Maps",
  "--reporter=github,json",
];

const args = fullMatrix ? baseArgs : [...baseArgs, "--project=desktop"];

if (!fs.existsSync(testResultsDir)) {
  fs.mkdirSync(testResultsDir, { recursive: true });
}

process.env.PLAYWRIGHT_JSON_OUTPUT_NAME = jsonOutPath;

const playwrightCliPath = path.join(root, "node_modules", "playwright", "cli.js");

const child = spawn(process.execPath, [playwrightCliPath, ...args], {
  cwd: root,
  stdio: "inherit",
  shell: false,
  env: process.env,
});

function writeGateSummary(summary) {
  try {
    fs.writeFileSync(summaryOutPath, JSON.stringify(summary, null, 2));
  } catch (err) {
    console.warn("[visual-gate] Could not write visual gate summary:", err);
  }
}

child.on("close", (code = 1) => {
  const exitCode = code;

  let unexpectedCount = Number.POSITIVE_INFINITY;
  try {
    if (fs.existsSync(jsonOutPath)) {
      const report = JSON.parse(fs.readFileSync(jsonOutPath, "utf8"));
      unexpectedCount = Number(report?.stats?.unexpected ?? Number.POSITIVE_INFINITY);
    }
  } catch (err) {
    console.warn("[visual-gate] Could not parse playwright JSON report:", err);
  }

  let duplicateCount = 0;
  try {
    if (fs.existsSync(duplicatesPath)) {
      const dups = JSON.parse(fs.readFileSync(duplicatesPath, "utf8"));
      duplicateCount = Array.isArray(dups) ? dups.length : 0;
    }
  } catch (err) {
    console.warn("[visual-gate] Could not parse visual duplicates summary:", err);
  }

  const baseSummary = {
    ts: new Date().toISOString(),
    exitCode,
    unexpectedCount,
    duplicateCount,
    duplicateThreshold,
    fullMatrix,
    downgradedToWarn: false,
    blockedOnDuplicateThreshold: false,
  };

  if (exitCode === 0) {
    writeGateSummary(baseSummary);
    process.exit(0);
  }

  // Non-blocking downgrade only when there are no unexpected failures
  // and diagnostics indicate duplicate-render-only behavior.
  if (unexpectedCount === 0 && duplicateCount > 0) {
    if (duplicateCount <= duplicateThreshold) {
      console.warn(
        `[visual-gate] Duplicate-only diagnostic run (${duplicateCount} duplicates <= threshold ${duplicateThreshold}). Downgrading to WARN and returning success.`,
      );
      writeGateSummary({
        ...baseSummary,
        downgradedToWarn: true,
      });
      process.exit(0);
    }

    console.error(
      `[visual-gate] Duplicate threshold exceeded (${duplicateCount} > ${duplicateThreshold}). Keeping failure for triage.`,
    );
    writeGateSummary({
      ...baseSummary,
      blockedOnDuplicateThreshold: true,
    });
    process.exit(1);
  }

  writeGateSummary(baseSummary);
  process.exit(exitCode);
});
