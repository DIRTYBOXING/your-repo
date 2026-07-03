// tools/rollback-job.js
// Usage: PROMOTE_BACKEND=http://localhost:4000 node tools/rollback-job.js <JOB_ID1> [JOB_ID2 ...]
const fetch = require("node-fetch");
const { v4: uuid } = require("uuid");

const BACKEND = process.env.PROMOTE_BACKEND || "http://localhost:4000";
const JOB_IDS = process.argv.slice(2);

if (!JOB_IDS.length) {
  console.error("Usage: node tools/rollback-job.js <JOB_ID1> [JOB_ID2 ...]");
  process.exit(2);
}

async function callRollback(jobId) {
  try {
    // Preferred endpoint: POST /api/jobs/:id/rollback (if implemented)
    const rollbackUrl = `${BACKEND}/api/jobs/${jobId}/rollback`;
    const res = await fetch(rollbackUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        requestedBy: "rollback-script",
        reason: "Automated rollback requested after failed promote or incident",
        traceId: uuid(),
      }),
    });

    if (res.ok) {
      const j = await res.json();
      console.log(`[OK] Rollback requested for ${jobId}:`, j);
      return { jobId, ok: true, resp: j };
    }

    // Fallback: create a revert job that undoes the promoted changes
    console.warn(
      `[WARN] Rollback endpoint returned ${res.status} for ${jobId}. Attempting revert-job fallback.`,
    );
    const fallbackUrl = `${BACKEND}/api/jobs`;
    const fallbackBody = {
      name: `rollback-for-${jobId}`,
      jobType: "rollback",
      targetJobId: jobId,
      requestedBy: "rollback-script",
      dryRun: false,
    };
    const res2 = await fetch(fallbackUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(fallbackBody),
    });
    const j2 = await res2.json();
    console.log(`[FALLBACK] Created rollback job for ${jobId}:`, j2);
    return { jobId, ok: res2.ok, resp: j2 };
  } catch (err) {
    console.error(`[ERR] Rollback failed for ${jobId}:`, err.message || err);
    return { jobId, ok: false, error: err.message || err };
  }
}

(async function main() {
  console.log("Starting rollback for", JOB_IDS);
  const results = [];
  for (const id of JOB_IDS) {
    // mark audit before action
    try {
      await fetch(`${BACKEND}/api/audit`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          action: "rollback_initiated",
          jobId: id,
          user: "rollback-script",
          ts: Date.now(),
        }),
      });
    } catch (e) {
      /* ignore audit errors */
    }

    const r = await callRollback(id);
    results.push(r);
  }

  console.log("Rollback summary:");
  results.forEach((r) => {
    if (r.ok) console.log(`  - ${r.jobId}: OK`);
    else
      console.log(
        `  - ${r.jobId}: FAILED (${r.error || JSON.stringify(r.resp)})`,
      );
  });

  // optional: notify via API (Slack/webhook) if configured
  try {
    await fetch(`${BACKEND}/api/notify`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        channel: "sre",
        subject: "Rollback executed",
        body: { results },
      }),
    });
  } catch (e) {
    /* best-effort notify */
  }

  process.exit(0);
})();
