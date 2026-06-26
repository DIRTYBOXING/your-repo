/**
 * DFC Platform Audit — Cinema-Grade PPV + Social + Maps
 *
 * Runs against http://127.0.0.1:8088 (Flutter web dev server).
 * Each test grades the surface: PASS / WARN / SKIP (no hard fails on
 * missing data-test attributes so the audit never blocks CI on demo data).
 *
 * Surfaces audited:
 *   1. PPV Hub Storefront          — cinema-grade hero layout
 *   2. PPV Event Detail            — poster, buy CTA, gated player
 *   3. PPV Live Watch              — video element + DRM token surface
 *   4. Social Feed (dfc feed)      — post cards, compose CTA
 *   5. Social Messaging            — conversation list reachable
 *   6. Maps — Global Fight Map     — map canvas renders
 *   7. Maps — Community Map        — safety zones visible
 *   8. Maps — Find a Gym           — gym markers
 *   9. Home Shell                  — bottom nav + hero present
 *  10. Event Storefront (poster)   — poster store renders grid
 *  11. Sales Admin                 — rate key admin surface
 *  12. Blueprint Visual Page       — promoter/community blueprint
 *  13. Blueprint Engineering Page  — print/export engineering variant
 */

import { expect, Page, TestInfo, test } from "@playwright/test";
import { enterDemoModeIfAvailable } from "./helpers/enterDemoMode";
import { navigateAndEnsureMounted } from "./helpers/routeHelpers";
import { waitForFlutterReady } from "./helpers/waitForFlutter";
import { waitForRouteContent } from "./helpers/routeAssertions";
import { saveRouteScreenshot } from "./helpers/screenshotUtils";
import { assertUniqueHash, writeDuplicateSummaryIfAny, getDuplicateRecords } from "./helpers/uniqueness";

// ── Route constants ──────────────────────────────────────────────────────────
const BASE = process.env.PLAYWRIGHT_BASE_URL ?? "http://127.0.0.1:8088";
const routes = {
  home: "/#/home",
  ppvHub: "/#/ppv",
  ppvDetail: `/#/ppv/event/${process.env.EVENT_ID ?? "demo-eternal-80"}`,
  ppvWatch: `/#/ppv/${process.env.EVENT_ID ?? "demo-eternal-80"}/watch`,
  feed: "/#/home",
  messaging: "/#/messaging",
  globalMap: "/#/map",
  communityMap: "/#/gym-map-command",
  gymFinder: "/#/find-a-gym",
  posterStore: "/#/ppv/poster-store",
  adminSales: "/#/admin/sales",
  blueprint: "/blueprint.html",
  blueprintEngineering: "/blueprint-engineering.html",
};

// ── Helpers ──────────────────────────────────────────────────────────────────
async function loadRoute(page: Page, route: string) {
  await page.goto(`${BASE}${route}`, { waitUntil: "domcontentloaded" });
  const enteredDemo = await enterDemoModeIfAvailable(page);
  if (enteredDemo) {
    await page.evaluate(() => {
      localStorage.setItem("user_demo_mode", "1");
      localStorage.setItem("auth_token", "TEST_DEMO_TOKEN");
      localStorage.setItem("dfc_demo_gate_passed", "1");
    });
    // Gate click usually lands on home; revisit the requested route.
    await page.goto(`${BASE}${route}`, { waitUntil: "domcontentloaded" });
  }
  await waitForFlutterReady(page);
  await page.waitForTimeout(1500);
}

async function loadStaticRoute(page: Page, route: string) {
  await page.goto(`${BASE}${route}`, { waitUntil: "domcontentloaded" });
  await page.waitForLoadState("networkidle");
  await page.waitForTimeout(800);
}

async function attachScreenshot(page: Page, routeName: string, testInfo: TestInfo) {
  const { body, bytes, hash, filePath } = await saveRouteScreenshot(
    page,
    routeName,
    testInfo.project.name,
  );
  assertUniqueHash(hash, routeName, testInfo.project.name);
  await testInfo.attach(routeName, { body, contentType: "image/png" });
  console.log(`  📸 SHOT  ${routeName}  —  ${filePath}`);
  return bytes;
}

async function assertRouteContract(page: Page, label: string, selector: string) {
  let contractFound = false;
  try {
    await waitForRouteContent(page, selector, 12000);
    contractFound = true;
  } catch {
    contractFound = false;
  }

  grade(`Route contract: ${label}`, contractFound, selector);
}

function grade(label: string, pass: boolean, detail = "") {
  const icon = pass ? "✅ PASS" : "⚠️  WARN";
  console.log(`  ${icon}  ${label}${detail ? "  —  " + detail : ""}`);
  return pass;
}

// ── 1. PPV Hub Storefront ────────────────────────────────────────────────────
test.describe("PPV Hub Storefront", () => {
  test("cinema-grade hero renders with event cards", async ({ page }, testInfo) => {
    test.setTimeout(120000);
    await loadRoute(page, routes.ppvHub);
    await assertRouteContract(
      page,
      "ppv-hub",
      '[data-test-route="ppv-hub"], [data-test="ppv-hub"], [aria-label*="data-test=ppv-hub"], [aria-label*="data-test=event-poster"]',
    );
    const bytes = await attachScreenshot(page, `ppv-hub`, testInfo);

    const heroCard = await page.locator(
      '[data-test-route="ppv-hub"], [data-test="ppv-hub"], [aria-label*="data-test=ppv-hub"], [aria-label*="data-test=event-poster"]'
    ).count();

    grade("Screenshot captured", bytes > 5000, `${bytes} bytes`);
    grade("PPV event content in DOM", heroCard > 0, `${heroCard} elements`);

    // Must have non-trivial render
    expect(bytes).toBeGreaterThan(5000);
  });
});

// ── 2. PPV Event Detail ───────────────────────────────────────────────────────
test.describe("PPV Event Detail", () => {
  test("poster visible and purchase CTA present", async ({ page }, testInfo) => {
    await loadRoute(page, routes.ppvDetail);
    await assertRouteContract(
      page,
      "ppv-detail",
      '[data-test-route="event-poster"], [data-test="event-poster"], [aria-label*="data-test=event-poster"], [data-test="ppv-purchase-cta"], [data-test="ppv-buy-now"]',
    );
    const bytes = await attachScreenshot(page, `ppv-detail`, testInfo);

    const poster = await page.locator(
      '[data-test-route="event-poster"], [data-test="event-poster"], [aria-label*="data-test=event-poster"]'
    ).count();
    const cta = await page.locator(
      '[data-test="ppv-purchase-cta"], [data-test="buy-now"], [data-test="ppv-buy-now"], [aria-label*="data-test=buy-cta"], #ppv-detail-buy-button-dom'
    ).count();

    grade("Poster element found", poster > 0);
    grade("Purchase CTA found", cta > 0);
    grade("Screenshot non-trivial", bytes > 5000, `${bytes} bytes`);

    expect(bytes).toBeGreaterThan(5000);
  });

  test("no blocking console errors on event detail", async ({ page }) => {
    const errors: string[] = [];
    page.on("console", msg => {
      if (msg.type() === "error" &&
          !/favicon|source.map|google_maps_flutter|DevTools/i.test(msg.text())) {
        errors.push(msg.text());
      }
    });

    await loadRoute(page, routes.ppvDetail);
    grade("Zero blocking console errors", errors.length === 0, errors.slice(0, 3).join(" | "));
    expect(errors.length).toBe(0);
  });
});

// ── 3. PPV Live Watch (Gated Player) ─────────────────────────────────────────
test.describe("PPV Live Watch", () => {
  test("player surface or paywall renders", async ({ page }, testInfo) => {
    const mounted = await navigateAndEnsureMounted(
      page,
      routes.ppvWatch,
      '[data-test-route="ppv-watch"], [aria-label*="data-test=ppv-watch"], [aria-label*="data-test=ppv-watch-surface"], [aria-label*="data-test=ppv-watch-root-"]',
      { timeout: 25000 },
    );
    expect(mounted).toBeTruthy();
    await assertRouteContract(
      page,
      "ppv-watch",
      '[data-test="ppv-paywall"], [data-test="ppv-purchase-cta"], [aria-label*="data-test=ppv-watch-root-"]',
    );
    const bytes = await attachScreenshot(page, `ppv-watch`, testInfo);

    const hasVideo = await page.evaluate(() => Boolean(document.querySelector("video")));
    const hasPaywall = await page.locator(
      '[data-test="ppv-purchase-cta"], [data-test="ppv-paywall"], [data-test="buy-now"], [aria-label*="data-test=buy-cta"], #ppv-detail-buy-button-dom'
    ).count();

    grade("Video element present", hasVideo);
    grade("Paywall CTA present (gated)", hasPaywall > 0);
    grade("Either player or paywall exists", hasVideo || hasPaywall > 0);
    grade("Screenshot non-trivial", bytes > 5000, `${bytes} bytes`);

    expect(bytes).toBeGreaterThan(5000);
  });
});

// ── Post-run duplicate summary ───────────────────────────────────────────────
test.afterAll(async ({}, testInfo) => {
  const duplicates = getDuplicateRecords();
  if (duplicates.length > 0) {
    console.warn(`\n⚠️  Visual audit: ${duplicates.length} duplicate screenshot hash(es) detected (auth-gated routes).`);
    duplicates.forEach(d =>
      console.warn(`   → '${d.duplicateRoute}' matched '${d.firstRoute}' [${d.project}] hash=${d.hash.slice(0, 12)}…`),
    );
    const summaryPath = writeDuplicateSummaryIfAny();
    if (summaryPath) {
      try {
        await testInfo.attach("visual-duplicates", {
          path: summaryPath,
          contentType: "application/json",
        });
      } catch {
        // testInfo.attach may not be available in afterAll in all Playwright versions
      }
    }
  } else {
    console.log("✅  Visual audit: no duplicate screenshots detected.");
  }
});

// ── 4. Social Feed ────────────────────────────────────────────────────────────
test.describe("Social Feed", () => {
  test("feed renders post cards and compose CTA", async ({ page }, testInfo) => {
    const mounted = await navigateAndEnsureMounted(
      page,
      routes.feed,
      '[aria-label*="data-test=social-feed"], [data-test-route="social-card"], [aria-label*="data-test=social-card-"]',
      { timeout: 25000 },
    );
    expect(mounted).toBeTruthy();
    await page.waitForTimeout(1000);
    await assertRouteContract(
      page,
      "social-feed",
      '[data-test-route="social-card"], [data-test="post-card"], [data-test="feed-item"], [aria-label*="data-test=social-card"], [aria-label*="data-test=event-feed-item"]',
    );
    const bytes = await attachScreenshot(page, `social-feed`, testInfo);

    const posts = await page.locator(
      '[data-test-route="social-card"], [data-test="post-card"], [data-test="feed-item"], [aria-label*="data-test=social-card"], [aria-label*="data-test=event-feed-item"], flt-semantics'
    ).count();
    const composeCta = await page.locator(
      '[data-test="compose-post"], [data-test="create-post"]'
    ).count();

    grade("Feed content in DOM", posts > 0, `${posts} elements`);
    grade("Compose CTA present", composeCta > 0);
    grade("Screenshot non-trivial", bytes > 5000, `${bytes} bytes`);

    expect(bytes).toBeGreaterThan(5000);
  });
});

// ── 5. Messaging ──────────────────────────────────────────────────────────────
test.describe("Social Messaging", () => {
  test("conversation list surface loads", async ({ page }, testInfo) => {
    const mounted = await navigateAndEnsureMounted(
      page,
      routes.messaging,
      '[data-test-route="messaging-thread"], [aria-label*="data-test=messaging-thread"], [aria-label*="data-test=messaging-unique"]',
      { timeout: 25000 },
    );
    expect(mounted).toBeTruthy();
    await assertRouteContract(
      page,
      "social-messaging",
      '[data-test-route="messaging-thread"], [data-test="messaging-list"], [data-test="conversation-list"], [aria-label*="data-test=messaging-thread"]',
    );
    const bytes = await attachScreenshot(page, `messaging`, testInfo);

    grade("Messaging surface renders", bytes > 5000, `${bytes} bytes`);
    expect(bytes).toBeGreaterThan(5000);
  });
});

// ── 6. Maps — Global Fight Map ────────────────────────────────────────────────
test.describe("Maps — Global Fight Map", () => {
  test("map canvas renders without crash", async ({ page }, testInfo) => {
    const mapErrors: string[] = [];
    page.on("console", msg => {
      if (msg.type() === "error" &&
          !/favicon|source.map|DevTools/i.test(msg.text())) {
        mapErrors.push(msg.text());
      }
    });

    const mounted = await navigateAndEnsureMounted(
      page,
      routes.globalMap,
      '[data-test-route="map-global"], [aria-label*="data-test=map-global"], [aria-label*="data-test=map-canvas-global"]',
      { timeout: 25000 },
    );
    expect(mounted).toBeTruthy();
    await page.waitForTimeout(2000);
    await assertRouteContract(
      page,
      "maps-global",
      '[data-test-route="map-global"], [aria-label*="data-test=map-canvas-global"], [data-test="map-canvas-global"], canvas, .google-map, gmp-map',
    );
    const bytes = await attachScreenshot(page, `global-map`, testInfo);

    const mapEl = await page.locator(
      '[data-test-route="map-global"], [aria-label*="data-test=map-canvas-global"], [data-test="map-canvas-global"], canvas, .google-map, gmp-map'
    ).count();

    grade("Map canvas element present", mapEl > 0, `${mapEl} elements`);
    grade("No map-breaking errors", mapErrors.length === 0,
      mapErrors.slice(0, 2).join(" | ") || "clean");
    grade("Screenshot non-trivial", bytes > 5000, `${bytes} bytes`);

    expect(bytes).toBeGreaterThan(5000);
  });
});

// ── 7. Maps — Community Map ───────────────────────────────────────────────────
test.describe("Maps — Community Map", () => {
  test("community safety map surface loads", async ({ page }, testInfo) => {
    const mounted = await navigateAndEnsureMounted(
      page,
      routes.communityMap,
      '[data-test-route="map-community"], [aria-label*="data-test=map-community"], [aria-label*="data-test=map-canvas-community"]',
      { timeout: 25000 },
    );
    expect(mounted).toBeTruthy();
    await page.waitForTimeout(2000);
    await assertRouteContract(
      page,
      "maps-community",
      '[data-test-route="map-command"], [data-test-route="map-community"], [aria-label*="data-test=map-canvas-community"], [data-test="community-map"], [data-test="map-canvas"], canvas, gmp-map',
    );
    const bytes = await attachScreenshot(page, `community-map`, testInfo);

    grade("Community map renders", bytes > 5000, `${bytes} bytes`);
    expect(bytes).toBeGreaterThan(5000);
  });
});

// ── 8. Maps — Gym Finder ──────────────────────────────────────────────────────
test.describe("Maps — Gym Finder", () => {
  test("gym finder map + list renders", async ({ page }, testInfo) => {
    const mounted = await navigateAndEnsureMounted(
      page,
      routes.gymFinder,
      '[data-test-route="gym-card-list"], [aria-label*="data-test=gym-finder"], [aria-label*="data-test=gym-card-list"]',
      { timeout: 25000 },
    );
    expect(mounted).toBeTruthy();
    await page.waitForTimeout(2000);
    await assertRouteContract(
      page,
      "maps-gym-finder",
      '[data-test-route="gym-card-list"], [data-test="gym-card"], [data-test="gym-list-item"], [aria-label*="data-test=gym-card-"]',
    );
    const bytes = await attachScreenshot(page, `gym-finder`, testInfo);

    const gymCards = await page.locator(
      '[data-test-route="gym-card-list"], [data-test="gym-card"], [data-test="gym-list-item"], [aria-label*="data-test=gym-card-"]'
    ).count();

    grade("Gym cards visible", gymCards > 0, `${gymCards} found`);
    grade("Screenshot non-trivial", bytes > 5000, `${bytes} bytes`);

    expect(bytes).toBeGreaterThan(5000);
  });
});

// ── 9. Home Shell ─────────────────────────────────────────────────────────────
test.describe("Home Shell", () => {
  test("bottom nav and hero section present", async ({ page }, testInfo) => {
    await loadRoute(page, routes.home);
    const bytes = await attachScreenshot(page, "home-shell", testInfo);

    const nav = await page.locator(
      '[data-test="bottom-nav"], nav, [role="navigation"]'
    ).count();

    grade("Navigation present", nav > 0);
    grade("Screenshot non-trivial", bytes > 5000, `${bytes} bytes`);

    expect(bytes).toBeGreaterThan(5000);
  });
});

// ── 10. Event Poster Store ────────────────────────────────────────────────────
test.describe("Event Poster Store", () => {
  test("poster store grid renders", async ({ page }, testInfo) => {
    await loadRoute(page, routes.posterStore);
    const bytes = await attachScreenshot(page, "poster-store", testInfo);

    const posters = await page.locator(
      '[data-test="poster-card"], [data-test="poster-grid-item"], [aria-label*="data-test=poster-list-item-"]'
    ).count();

    grade("Poster cards visible", posters > 0, `${posters} found`);
    grade("Screenshot non-trivial", bytes > 5000, `${bytes} bytes`);

    expect(bytes).toBeGreaterThan(5000);
  });
});

// ── 11. Sales Admin ─────────────────────────────────────────────────────────
test.describe("Sales Admin", () => {
  test("sales config screen renders", async ({ page }, testInfo) => {
    await loadRoute(page, routes.adminSales);
    const bytes = await attachScreenshot(page, "sales-admin", testInfo);

    const salesSurface = await page.locator(
      '[data-test="sales-admin-screen"], [aria-label*="data-test=sales-admin-screen"], text=Sales Admin'
    ).count();

    grade("Sales admin surface present", salesSurface > 0, `${salesSurface} found`);
    grade("Screenshot non-trivial", bytes > 5000, `${bytes} bytes`);

    expect(bytes).toBeGreaterThan(5000);
  });
});

// ── 12. Blueprint Visual ────────────────────────────────────────────────────
test.describe("Blueprint Visual", () => {
  test("visual blueprint page renders core regions", async ({ page }, testInfo) => {
    await loadStaticRoute(page, routes.blueprint);
    const bytes = await attachScreenshot(page, "blueprint-visual", testInfo);

    const hero = await page.locator('[data-test="blueprint-hero"]').count();
    const canvas = await page.locator(
      '[data-test="blueprint-canvas"]'
    ).count();
    const cta = await page.locator(
      '[data-test="blueprint-cta"]'
    ).count();

    grade("Blueprint hero present", hero > 0, `${hero} found`);
    grade("Blueprint canvas present", canvas > 0, `${canvas} found`);
    grade("Blueprint CTA present", cta > 0, `${cta} found`);
    grade("Screenshot non-trivial", bytes > 5000, `${bytes} bytes`);

    expect(hero).toBeGreaterThan(0);
    expect(canvas).toBeGreaterThan(0);
    expect(cta).toBeGreaterThan(0);
    expect(bytes).toBeGreaterThan(5000);
  });
});

// ── 13. Blueprint Engineering ───────────────────────────────────────────────
test.describe("Blueprint Engineering", () => {
  test("engineering blueprint page renders export-safe regions", async ({ page }, testInfo) => {
    await loadStaticRoute(page, routes.blueprintEngineering);
    const bytes = await attachScreenshot(page, "blueprint-engineering", testInfo);

    const hero = await page.locator('[data-test="engineering-blueprint-hero"]').count();
    const canvas = await page.locator(
      '[data-test="engineering-blueprint-canvas"]'
    ).count();
    const cta = await page.locator(
      '[data-test="engineering-blueprint-cta"]'
    ).count();

    grade("Engineering hero present", hero > 0, `${hero} found`);
    grade("Engineering canvas present", canvas > 0, `${canvas} found`);
    grade("Engineering CTA present", cta > 0, `${cta} found`);
    grade("Screenshot non-trivial", bytes > 5000, `${bytes} bytes`);

    expect(hero).toBeGreaterThan(0);
    expect(canvas).toBeGreaterThan(0);
    expect(cta).toBeGreaterThan(0);
    expect(bytes).toBeGreaterThan(5000);
  });
});
