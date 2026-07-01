#!/usr/bin/env node
const { spawn } = require("child_process");
const fs = require("fs");

function pickFirstExisting(candidates) {
  return candidates.find((p) => fs.existsSync(p));
}

const migrateCmd = fs.existsSync("package.json") ? "npm run db:migrate" : null;
const workerCmd = pickFirstExisting(["worker/autoClipConsumer.js"]);

const tasks = [
  { name: "Run migrations", cmd: migrateCmd },
  {
    name: "Start workers (once)",
    cmd: workerCmd ? `node ${workerCmd} --once` : null,
  },
  {
    name: "Run smoke tests",
    cmd: "bash ci/smoke_clip_publish_strict.sh --timeout 60 --retries 3",
  },
].filter((t) => !!t.cmd);

function runTask(t) {
  return new Promise((resolve, reject) => {
    console.log(`\n=== START ${t.name} ===`);
    const p = spawn(t.cmd, { shell: true, stdio: "inherit" });
    p.on("close", (code) => {
      if (code === 0) {
        console.log(`=== OK ${t.name} ===`);
        resolve();
      } else {
        reject(new Error(`${t.name} failed with code ${code}`));
      }
    });
  });
}

async function main() {
  try {
    for (const t of tasks) {
      await runTask(t);
    }
    console.log("All orchestrator tasks completed successfully");
    process.exit(0);
  } catch (err) {
    console.error("Orchestrator failed:", err.message);
    // optional: collect logs, upload artifacts, or call a webhook
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { runTask, main };
