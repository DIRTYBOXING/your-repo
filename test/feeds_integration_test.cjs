// feeds_integration_test.cjs
// Integration test for DFC auto-feed pipeline
const { execSync } = require("child_process");
const { Client } = require("pg");
const assert = require("assert");

const DATABASE_URL =
  process.env.DATABASE_URL || "postgres://dfc:dfcpass@localhost:5432/dfc_audit";

async function runIntake() {
  execSync("npx ts-node src/feeds/intake.ts", { stdio: "inherit" });
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
