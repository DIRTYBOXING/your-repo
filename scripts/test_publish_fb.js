#!/usr/bin/env node
/**
 * scripts/test_publish_fb.js
 *
 * Staging integration harness for the Facebook publish path.
 * Requires:
 *   - GOOGLE_CLOUD_PROJECT env var (or GCLOUD_PROJECT)
 *   - Application Default Credentials with secretmanager.secretAccessor
 *     on facebook_page_id and facebook_page_token
 *   - promotion-worker/node_modules installed via `cd promotion-worker && npm ci`
 *
 * Usage:
 *   GOOGLE_CLOUD_PROJECT=datafightcentral node scripts/test_publish_fb.js
 *   GOOGLE_CLOUD_PROJECT=datafightcentral DRY_RUN=1 node scripts/test_publish_fb.js
 *
 * Set DRY_RUN=1 to read secrets and log the request without actually calling
 * the Graph API.
 */

import https from "node:https";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { SecretManagerServiceClient } = require("../promotion-worker/node_modules/@google-cloud/secret-manager");

const DRY_RUN = process.env.DRY_RUN === "1";
const projectId = process.env.GOOGLE_CLOUD_PROJECT ?? process.env.GCLOUD_PROJECT;

if (!projectId) {
  console.error("ERROR: GOOGLE_CLOUD_PROJECT environment variable is not set.");
  process.exit(1);
}

async function getSecret(secretName) {
  const client = new SecretManagerServiceClient();
  const name = `projects/${projectId}/secrets/${secretName}/versions/latest`;
  const [version] = await client.accessSecretVersion({ name });
  const value = version.payload?.data?.toString();
  if (!value) throw new Error(`Secret '${secretName}' is empty`);
  return value;
}

function graphPost(path, formBody) {
  return new Promise((resolve, reject) => {
    const req = https.request(
      {
        hostname: "graph.facebook.com",
        path,
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Content-Length": Buffer.byteLength(formBody),
        },
      },
      (res) => {
        let raw = "";
        res.on("data", (chunk) => (raw += chunk.toString()));
        res.on("end", () => {
          console.log(`Graph API HTTP ${res.statusCode}`);
          try {
            const json = JSON.parse(raw);
            if (json.error) {
              reject(new Error(`Graph API error: ${JSON.stringify(json.error)}`));
            } else {
              resolve(json);
            }
          } catch {
            reject(new Error(`Non-JSON response: ${raw}`));
          }
        });
      },
    );
    req.on("error", reject);
    req.write(formBody);
    req.end();
  });
}

(async () => {
  console.log(`[test_publish_fb] project=${projectId} dry_run=${DRY_RUN}`);

  // 1) Fetch secrets
  console.log("[test_publish_fb] Fetching secrets from Secret Manager...");
  const [pageId, pageToken] = await Promise.all([
    getSecret("facebook_page_id"),
    getSecret("facebook_page_token"),
  ]);
  console.log(`[test_publish_fb] page_id=${pageId} token=***${pageToken.slice(-4)}`);

  // 2) Build payload
  const caption = "[DFC STAGING TEST] Ignore - automated publish harness";
  const body = new URLSearchParams({ message: caption, access_token: pageToken }).toString();
  const path = `/v19.0/${pageId}/feed`;

  if (DRY_RUN) {
    console.log(`[test_publish_fb] DRY_RUN: would POST to https://graph.facebook.com${path}`);
    console.log(
      `[test_publish_fb] body (token redacted): message=${encodeURIComponent(caption)}&access_token=***`,
    );
    process.exit(0);
  }

  // 3) Post
  console.log(`[test_publish_fb] Posting to https://graph.facebook.com${path}...`);
  const result = await graphPost(path, body);
  console.log("[test_publish_fb] SUCCESS:", JSON.stringify(result));
  console.log(
    `[test_publish_fb] Verify post at https://www.facebook.com/${pageId}/posts/${result.id ?? result.post_id}`,
  );
})().catch((err) => {
  console.error("[test_publish_fb] FAILED:", err.message);
  process.exit(1);
});
