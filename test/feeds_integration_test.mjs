// feeds_integration_test.mjs
// Integration test for DFC auto-feed pipeline (ESM compatible)
import { execSync } from "child_process";
import pg from "pg";
import assert from "assert";

const { Client } = pg;
const DATABASE_URL =
  process.env.DATABASE_URL || "postgres://dfc:dfcpass@localhost:5432/dfc_audit";

async function runIntake() {
  execSync("npx ts-node-esm src/feeds/intake.ts", { stdio: "inherit" });
}

async function testFeedIngestion() {
  const client = new Client({ connectionString: DATABASE_URL });
  await client.connect();
  const { rows } = await client.query(
    "SELECT * FROM feeds_incoming ORDER BY created_at DESC LIMIT 5",
  );
  await client.end();
  assert(rows.length > 0, "No feed items ingested");
  console.log("✅ Feed ingestion test passed.");
}

(async () => {
  await runIntake();
  await testFeedIngestion();
})();
