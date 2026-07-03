#!/usr/bin/env node
/**
 * tools/auto-pr-fixer.js
 * Safe auto fixer: runs fix commands, creates branch, commits, pushes, opens PR.
 *
 * Requirements:
 *   - GITHUB_TOKEN with repo scope (for opening PRs)
 *   - git configured in CI environment
 *
 * Usage:
 *   node tools/auto-pr-fixer.js
 */

import { execSync } from "child_process";
import fs from "fs";
import fetch from "node-fetch";

const FIX_COMMANDS = [
  "npm run lint -- --fix || true",
  "npm run format || true",
];

const BRANCH_PREFIX = "auto/fix/";
const PR_BASE = process.env.PR_BASE || "master";
const REPO = process.env.GITHUB_REPOSITORY;
const TOKEN = process.env.GITHUB_TOKEN;

function run(cmd) {
  console.log("> ", cmd);
  try {
    const out = execSync(cmd, { stdio: "pipe" }).toString();
    if (out.trim()) console.log(out);
    return { ok: true, out };
  } catch (e) {
    const msg = e.stdout ? e.stdout.toString() : e.message;
    console.error("Command failed:", cmd, msg);
    return { ok: false, err: msg };
  }
}

async function openPR(branch, title, body) {
  if (!TOKEN || !REPO) {
    console.log(
      "Skipping PR creation: missing GITHUB_TOKEN or GITHUB_REPOSITORY",
    );
    return null;
  }
  const url = `https://api.github.com/repos/${REPO}/pulls`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `token ${TOKEN}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ title, head: branch, base: PR_BASE, body }),
  });
  const json = await res.json();
  if (!res.ok) {
    console.error("Failed to create PR", json);
    return null;
  }
  console.log("PR created:", json.html_url);
  return json;
}

async function main() {
  // 1. Run fixers
  for (const cmd of FIX_COMMANDS) {
    run(cmd);
  }

  // 2. Check for changes
  const diff = execSync("git status --porcelain").toString().trim();
  if (!diff) {
    console.log("No changes after fixers. Nothing to do.");
    return;
  }

  // 3. Run tests to validate fixes
  console.log("Running test suite to validate fixes...");
  const testRes = run("npm test --silent");
  if (!testRes.ok) {
    console.error("Tests failed after auto fixes. Aborting auto PR.");
    fs.writeFileSync(
      "auto-fixer-report.json",
      JSON.stringify(
        {
          ok: false,
          reason: "tests_failed",
          testOut: testRes.err || testRes.out,
        },
        null,
        2,
      ),
    );
    return;
  }

  // 4. Create branch, commit, push
  const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
  const branch = `${BRANCH_PREFIX}${timestamp}`;
  run(`git checkout -b ${branch}`);
  run("git add -A");

  const commitRes = run(
    'git commit -m "chore: automated fixes (eslint/prettier) [skip ci]"',
  );
  if (!commitRes.ok) {
    console.log("Nothing to commit. Aborting.");
    return;
  }

  const pushRes = run(`git push origin ${branch}`);
  if (!pushRes.ok) {
    console.error("Failed to push branch. Aborting.");
    return;
  }

  // 5. Open PR
  const title = "Automated fixes: lint/format";
  const body = [
    "This PR was created automatically by the auto-fixer.",
    "It runs eslint --fix and formatting tools.",
    "",
    "If tests pass, please review and merge.",
    "",
    "**Auto Fix Summary**:",
    "```",
    diff,
    "```",
  ].join("\n");
  await openPR(branch, title, body);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
