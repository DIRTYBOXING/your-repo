#!/usr/bin/env node
/**
 * tools/issue-triage.js
 * Reads todo-results.json and creates GitHub issues for failed entries.
 *
 * Requires:
 *   - GITHUB_TOKEN env var
 *   - GITHUB_REPOSITORY env var
 *
 * Usage:
 *   node tools/issue-triage.js
 */

import fs from "fs";
import fetch from "node-fetch";

const TOKEN = process.env.GITHUB_TOKEN;
const REPO = process.env.GITHUB_REPOSITORY;
const TODO_RESULTS = "todo-results.json";

if (!TOKEN || !REPO) {
  console.error("GITHUB_TOKEN and GITHUB_REPOSITORY required");
  process.exit(1);
}

function loadResults() {
  if (!fs.existsSync(TODO_RESULTS)) {
    console.log(`${TODO_RESULTS} not found — nothing to triage.`);
    process.exit(0);
  }
  return JSON.parse(fs.readFileSync(TODO_RESULTS, "utf8"));
}

async function createIssue(title, body, labels = []) {
  const url = `https://api.github.com/repos/${REPO}/issues`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `token ${TOKEN}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ title, body, labels }),
  });
  const json = await res.json();
  if (!res.ok) {
    console.error("Issue creation failed", json);
    return null;
  }
  console.log("Created issue", json.html_url);
  return json;
}

async function main() {
  const data = loadResults();
  const results = data.results || [];
  const failed = results.filter((r) => r.status === "failed");

  if (failed.length === 0) {
    console.log("No failed TODOs. Nothing to triage.");
    return;
  }

  console.log(`Triaging ${failed.length} failed TODO(s)...`);

  for (const r of failed) {
    const title = `Automated TODO failed: ${r.tag} in ${r.file}:${r.line}`;
    const logs =
      r.runs && r.runs.length
        ? r.runs.map((x) => `${x.cmd}\n${x.err || x.out || ""}`).join("\n\n")
        : "No logs";
    const body = [
      `Automated run failed for TODO tag **${r.tag}** in \`${r.file}\` line ${r.line}.`,
      "",
      "Commands attempted:",
      "```",
      (r.commands || []).join("\n"),
      "```",
      "",
      "Logs:",
      "```",
      logs,
      "```",
    ].join("\n");

    const labels = ["triage", "auto-failed"];
    if (r.tag === "migrate") labels.push("high-priority");

    await createIssue(title, body, labels);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
