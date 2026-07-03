#!/usr/bin/env node
/**
 * scripts/run_live_smoke.mjs
 * ─────────────────────────────────────────────────────────────────────────────
 * Fast live smoke test for www.datafightcentral.com (or any PLAYWRIGHT_BASE_URL).
 * Tests critical routes load with HTTP 200 and key DOM anchors are present.
 *
 * Usage:
 *   node scripts/run_live_smoke.mjs
 *
 * Env vars:
 *   PLAYWRIGHT_BASE_URL  — Target base URL (default: https://www.datafightcentral.com)
 *   PLAYWRIGHT_ENTER_DEMO — "1" to click through demo gate if present
 *   LIVE_SMOKE_TIMEOUT   — Per-page timeout in ms (default: 30000)
 */

import { chromium } from 'playwright';

const BASE_URL = process.env.PLAYWRIGHT_BASE_URL?.replace(/\/$/, '')
  || 'https://www.datafightcentral.com';
const ENTER_DEMO = process.env.PLAYWRIGHT_ENTER_DEMO === '1';
const PAGE_TIMEOUT = parseInt(process.env.LIVE_SMOKE_TIMEOUT || '30000', 10);

// Routes to smoke test — route token used for DOM anchor check
const SMOKE_ROUTES = [
  { path: '/#/',         token: 'home',       label: 'Home'      },
  { path: '/#/feed',     token: 'feed',       label: 'Feed'      },
  { path: '/#/ppv',      token: 'ppv',        label: 'PPV'       },
  { path: '/#/fighters', token: 'fighters',   label: 'Fighters'  },
  { path: '/#/maps',     token: 'map',        label: 'Map'       },
];

const results = [];
let browser;

async function tryDemoGate(page) {
  try {
    const btn = page.locator('text=/enter demo|get started|continue/i').first();
    if (await btn.isVisible({ timeout: 3000 })) {
      await btn.click();
      await page.waitForTimeout(1000);
    }
  } catch {
    // No demo gate — continue
  }
}

async function smokeRoute(page, route) {
  const url = `${BASE_URL}${route.path}`;
  const start = Date.now();

  try {
    const response = await page.goto(url, {
      waitUntil: 'domcontentloaded',
      timeout: PAGE_TIMEOUT,
    });

    const status = response?.status() ?? 0;

    if (ENTER_DEMO) await tryDemoGate(page);

    // Wait for Flutter to mount — look for the data-test anchor OR any canvas/flt-scene
    let mounted = false;
    try {
      await page.waitForSelector(
        `[data-test="${route.token}"], flt-scene, canvas`,
        { timeout: PAGE_TIMEOUT }
      );
      mounted = true;
    } catch {
      mounted = false;
    }

    const elapsed = Date.now() - start;
    const pass = status === 200 && mounted;

    results.push({
      label: route.label,
      url,
      status,
      mounted,
      elapsed,
      pass,
    });

    const icon = pass ? '✅' : '❌';
    console.log(`${icon} ${route.label.padEnd(12)} ${status}  mounted=${mounted}  ${elapsed}ms`);

  } catch (err) {
    const elapsed = Date.now() - start;
    results.push({
      label: route.label,
      url,
      status: 0,
      mounted: false,
      elapsed,
      pass: false,
      error: err.message,
    });
    console.log(`❌ ${route.label.padEnd(12)} ERROR  ${elapsed}ms  ${err.message}`);
  }
}

async function main() {
  console.log(`\n━━━ DFC Live Smoke Gate ━━━`);
  console.log(`Target: ${BASE_URL}`);
  console.log(`Routes: ${SMOKE_ROUTES.length}  |  Timeout: ${PAGE_TIMEOUT}ms\n`);

  browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    userAgent: 'DFC-LiveSmoke/1.0 (+https://datafightcentral.com)',
    viewport: { width: 1280, height: 800 },
  });
  const page = await context.newPage();
  page.setDefaultTimeout(PAGE_TIMEOUT);

  for (const route of SMOKE_ROUTES) {
    await smokeRoute(page, route);
  }

  await browser.close();

  // Summary
  const passed = results.filter(r => r.pass).length;
  const failed = results.filter(r => !r.pass).length;
  const avgMs = Math.round(results.reduce((s, r) => s + r.elapsed, 0) / results.length);

  console.log(`\n━━━ Results ━━━`);
  console.log(`Passed: ${passed}/${results.length}  |  Failed: ${failed}  |  Avg: ${avgMs}ms`);

  if (failed > 0) {
    console.log('\nFailed routes:');
    results.filter(r => !r.pass).forEach(r => {
      console.log(`  ❌ ${r.label}: status=${r.status} mounted=${r.mounted}${r.error ? ' error=' + r.error : ''}`);
    });
    process.exit(1);
  }

  console.log(`\n✅ All ${passed} smoke checks passed against ${BASE_URL}`);
  process.exit(0);
}

main().catch(err => {
  console.error('Fatal error:', err);
  if (browser) browser.close().catch(() => {});
  process.exit(1);
});
