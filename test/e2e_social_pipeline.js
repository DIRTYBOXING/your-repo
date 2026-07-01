#!/usr/bin/env node
// ═══════════════════════════════════════════════════════════════════════════
// E2E Social Pipeline Smoke Test
// ═══════════════════════════════════════════════════════════════════════════
//
// Tests the full social pipeline end-to-end:
//   1. OG serving (bot user-agent → gets meta tags)
//   2. OG serving (normal user-agent → redirect)
//   3. Create post via callable (requires Firebase Auth emulator or token)
//   4. Read personalized feed
//   5. Verify post appears in feed
//
// Usage:
//   node test/e2e_social_pipeline.js [--emulator]
//
// Flags:
//   --emulator   Run against local Firebase emulators (default: production)
//
// Env:
//   FIREBASE_PROJECT   (default: datafightcentral)
//   FIREBASE_REGION    (default: australia-southeast1)
//   TEST_ID_TOKEN      Firebase Auth ID token for authenticated calls
//
// ═══════════════════════════════════════════════════════════════════════════

const http = require("http");
const https = require("https");

const useEmulator = process.argv.includes("--emulator");
const PROJECT = process.env.FIREBASE_PROJECT || "datafightcentral";
const REGION = process.env.FIREBASE_REGION || "australia-southeast1";

const EMULATOR_HOST = "http://127.0.0.1:5001";
const PROD_HOST = `https://${REGION}-${PROJECT}.cloudfunctions.net`;
const BASE = useEmulator ? `${EMULATOR_HOST}/${PROJECT}/${REGION}` : PROD_HOST;

// Hosting URLs (for OG tests)
const HOSTING_EMULATOR = "http://127.0.0.1:5000";
const HOSTING_PROD = `https://${PROJECT}.web.app`;
const HOSTING_BASE = useEmulator ? HOSTING_EMULATOR : HOSTING_PROD;

const ID_TOKEN = process.env.TEST_ID_TOKEN || "";

let passed = 0;
let failed = 0;

// ─── Helpers ────────────────────────────────────────────────────────────

function request(url, options = {}) {
  return new Promise((resolve, reject) => {
    const mod = url.startsWith("https") ? https : http;
    const req = mod.request(
      url,
      {
        method: options.method || "GET",
        headers: options.headers || {},
        timeout: 15000,
      },
      (res) => {
        // Don't follow redirects — we want to inspect the status
        let body = "";
        res.on("data", (chunk) => {
          body += chunk;
        });
        res.on("end", () =>
          resolve({ status: res.statusCode, headers: res.headers, body }),
        );
      },
    );
    req.on("error", reject);
    req.on("timeout", () => {
      req.destroy();
      reject(new Error("timeout"));
    });
    if (options.body) req.write(options.body);
    req.end();
  });
}

function callCallable(functionName, data) {
  const url = `${BASE}/${functionName}`;
  const headers = {
    "Content-Type": "application/json",
  };
  if (ID_TOKEN) {
    headers["Authorization"] = `Bearer ${ID_TOKEN}`;
  }
  return request(url, {
    method: "POST",
    headers,
    body: JSON.stringify({ data }),
  });
}

function assert(label, condition) {
  if (condition) {
    passed++;
    console.log(`  ✅ ${label}`);
  } else {
    failed++;
    console.error(`  ❌ ${label}`);
  }
}

// ─── Test: OG bot serving ───────────────────────────────────────────────

async function testOgBotServing() {
  console.log("\n🔍 Test: OG Dynamic Serving (bot UA)");
  try {
    const res = await request(`${HOSTING_BASE}/posts/test-post-id`, {
      headers: { "User-Agent": "facebookexternalhit/1.1" },
    });
    assert("Returns 200 for bot UA", res.status === 200);
    assert("Contains og:title meta tag", res.body.includes("og:title"));
    assert("Contains og:image meta tag", res.body.includes("og:image"));
    assert("Contains og:url meta tag", res.body.includes("og:url"));
  } catch (err) {
    failed++;
    console.error(`  ❌ OG bot test failed: ${err.message}`);
  }
}

// ─── Test: OG normal user → redirect ────────────────────────────────────

async function testOgNormalRedirect() {
  console.log("\n🔍 Test: OG Dynamic Serving (normal UA → redirect)");
  try {
    const res = await request(`${HOSTING_BASE}/posts/test-post-id`, {
      headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120",
      },
    });
    // Normal users get redirected to the SPA or served index.html
    assert(
      "Returns 200 or 302 for normal UA",
      res.status === 200 || res.status === 302,
    );
    if (res.status === 302) {
      assert(
        "Redirect location is the SPA",
        (res.headers.location || "").includes("/posts/"),
      );
    }
  } catch (err) {
    failed++;
    console.error(`  ❌ OG normal redirect test failed: ${err.message}`);
  }
}

// ─── Test: Create post (requires auth) ──────────────────────────────────

async function testCreatePost() {
  console.log("\n🔍 Test: createSocialPost callable");
  if (!ID_TOKEN && !useEmulator) {
    console.log("  ⏭  Skipped (no TEST_ID_TOKEN and not using emulator)");
    return null;
  }
  try {
    const res = await callCallable("createSocialPost", {
      content: `E2E test post ${Date.now()}`,
      postType: "text",
      visibility: "public",
    });
    assert("Returns 200", res.status === 200);
    const json = JSON.parse(res.body);
    const postId = json?.result?.postId;
    assert("Response contains postId", !!postId);
    console.log(`    → Created post: ${postId}`);
    return postId;
  } catch (err) {
    failed++;
    console.error(`  ❌ Create post test failed: ${err.message}`);
    return null;
  }
}

// ─── Test: Personalized feed ────────────────────────────────────────────

async function testPersonalizedFeed(expectedPostId) {
  console.log("\n🔍 Test: getPersonalizedFeed callable");
  if (!ID_TOKEN && !useEmulator) {
    console.log("  ⏭  Skipped (no TEST_ID_TOKEN and not using emulator)");
    return;
  }
  try {
    const res = await callCallable("getPersonalizedFeed", {
      limit: 20,
    });
    assert("Returns 200", res.status === 200);
    const json = JSON.parse(res.body);
    const posts = json?.result?.posts;
    assert("Response contains posts array", Array.isArray(posts));
    if (expectedPostId && Array.isArray(posts)) {
      const found = posts.some((p) => p.id === expectedPostId);
      assert(`Created post ${expectedPostId} appears in feed`, found);
    }
  } catch (err) {
    failed++;
    console.error(`  ❌ Feed test failed: ${err.message}`);
  }
}

// ─── Test: OG image variant exists in video worker output ───────────────

async function testOgImageField() {
  console.log("\n🔍 Test: Video worker OG image field schema check");
  // This is a code-level check — verify the worker.js includes ogImageUrl
  const fs = require("fs");
  const path = require("path");
  const workerPath = path.join(
    __dirname,
    "..",
    "dfc-content-pipeline",
    "video-worker",
    "src",
    "worker.js",
  );
  try {
    const code = fs.readFileSync(workerPath, "utf8");
    assert(
      "worker.js contains generateOgImage function",
      code.includes("generateOgImage"),
    );
    assert(
      "worker.js writes ogImageUrl to Firestore",
      code.includes("ogImageUrl"),
    );
    assert("worker.js generates 1200x630 OG image", code.includes("1200:630"));
  } catch (err) {
    failed++;
    console.error(`  ❌ Worker schema check failed: ${err.message}`);
  }
}

// ─── Run ────────────────────────────────────────────────────────────────

async function main() {
  console.log("═══════════════════════════════════════════════════════════");
  console.log("  DFC Social Pipeline E2E Smoke Tests");
  console.log(`  Target: ${useEmulator ? "Emulators" : "Production"}`);
  console.log("═══════════════════════════════════════════════════════════");

  // Code-level checks (always run)
  await testOgImageField();

  // Network tests
  await testOgBotServing();
  await testOgNormalRedirect();

  // Auth-required tests
  const postId = await testCreatePost();
  if (postId) {
    // Small delay for Firestore propagation
    await new Promise((r) => setTimeout(r, 2000));
  }
  await testPersonalizedFeed(postId);

  // ── Summary ─────────────────────────────────────────────────────────
  console.log("\n═══════════════════════════════════════════════════════════");
  console.log(`  Results: ${passed} passed, ${failed} failed`);
  console.log("═══════════════════════════════════════════════════════════\n");

  process.exit(failed > 0 ? 1 : 0);
}

main().catch((err) => {
  console.error("Fatal:", err);
  process.exit(2);
});
