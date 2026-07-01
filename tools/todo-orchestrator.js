#!/usr/bin/env node
/**
 * tools/todo-orchestrator.js
 * Scans codebase for TODO/FIXME/HACK comments and optionally runs
 * associated validation. Outputs todo-results.json for downstream
 * consumption by auto-pr-fixer.js and issue-triage.js.
 *
 * Usage:
 *   node tools/todo-orchestrator.js --scan          # scan only
 *   node tools/todo-orchestrator.js --scan --run     # scan + validate
 */

import fs from "fs";
import path from "path";

const SCAN_DIRS = ["lib", "functions", "server", "tools", "services", "src"];
const EXTENSIONS = [".js", ".ts", ".dart", ".py", ".yaml", ".yml"];
const TODO_PATTERN = /\/\/\s*(TODO|FIXME|HACK|XXX)\b[:\s]*(.*)/i;
const IGNORE_FILE = ".auto-fix-ignore";

const args = process.argv.slice(2);
const doScan = args.includes("--scan");
const doRun = args.includes("--run");

if (!doScan && !doRun) {
  console.log("Usage: node tools/todo-orchestrator.js --scan [--run]");
  process.exit(0);
}

function loadIgnorePatterns() {
  if (!fs.existsSync(IGNORE_FILE)) return [];
  return fs
    .readFileSync(IGNORE_FILE, "utf8")
    .split("\n")
    .map((l) => l.trim())
    .filter((l) => l && !l.startsWith("#"));
}

function shouldIgnore(filePath, ignorePatterns) {
  const normalized = filePath.replace(/\\/g, "/");
  return ignorePatterns.some((pattern) => normalized.includes(pattern));
}

function walkDir(dir, extensions) {
  const files = [];
  if (!fs.existsSync(dir)) return files;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (["node_modules", ".dart_tool", "build", ".git"].includes(entry.name))
        continue;
      files.push(...walkDir(full, extensions));
    } else if (extensions.some((ext) => entry.name.endsWith(ext))) {
      files.push(full);
    }
  }
  return files;
}

function scanTodos() {
  const ignorePatterns = loadIgnorePatterns();
  const todos = [];

  for (const dir of SCAN_DIRS) {
    const files = walkDir(dir, EXTENSIONS);
    for (const file of files) {
      if (shouldIgnore(file, ignorePatterns)) continue;
      let content;
      try {
        content = fs.readFileSync(file, "utf8");
      } catch {
        continue;
      }
      const lines = content.split("\n");
      lines.forEach((line, idx) => {
        const match = line.match(TODO_PATTERN);
        if (match) {
          todos.push({
            file: file.replace(/\\/g, "/"),
            line: idx + 1,
            tag: match[1].toUpperCase(),
            text: match[2].trim(),
            status: "pending",
            commands: [],
            runs: [],
          });
        }
      });
    }
  }

  return todos;
}

function runChecks(todos) {
  for (const todo of todos) {
    if (!fs.existsSync(todo.file)) {
      todo.status = "failed";
      todo.runs.push({ cmd: "file-exists-check", err: "File not found" });
      continue;
    }

    // FIXME and HACK tags always flag as needing human attention
    if (todo.tag === "FIXME" || todo.tag === "HACK") {
      todo.status = "failed";
      todo.runs.push({
        cmd: "tag-severity-check",
        out: `${todo.tag} requires manual attention`,
      });
      continue;
    }

    todo.status = "scanned";
  }
  return todos;
}

function main() {
  console.log("TODO Orchestrator starting...");

  let todos = [];
  if (doScan) {
    todos = scanTodos();
    console.log(`Found ${todos.length} TODO/FIXME/HACK comment(s).`);
  }

  if (doRun && todos.length > 0) {
    console.log("Running checks...");
    todos = runChecks(todos);
    const failed = todos.filter((t) => t.status === "failed");
    console.log(
      `Checks complete: ${failed.length} failed, ${todos.length - failed.length} passed/scanned.`,
    );
  }

  const output = {
    timestamp: new Date().toISOString(),
    totalFound: todos.length,
    failed: todos.filter((t) => t.status === "failed").length,
    results: todos,
  };

  fs.writeFileSync("todo-results.json", JSON.stringify(output, null, 2));
  console.log("Results written to todo-results.json");
}

main();
