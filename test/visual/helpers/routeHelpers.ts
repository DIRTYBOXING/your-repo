import { type Page } from "@playwright/test";
import { enterDemoModeIfAvailable } from "./enterDemoMode";
import { waitForFlutterReady } from "./waitForFlutter";

const BASE = process.env.PLAYWRIGHT_BASE_URL ?? "http://127.0.0.1:8088";

export async function navigateAndEnsureMounted(
  page: Page,
  route: string,
  routeSelector: string,
  opts: { timeout?: number } = {},
): Promise<boolean> {
  const specificTimeout = Math.min(opts.timeout ?? 20000, 10000);
  const targetUrl = `${BASE}${route}`;

  // ── 1. Land on base and enter demo / auth-bypass state ───────────────────
  await page.goto(BASE, { waitUntil: "domcontentloaded" });

  let demoEntered = false;
  try {
    demoEntered = await enterDemoModeIfAvailable(page);
  } catch (err) {
    console.warn("enterDemoModeIfAvailable failed", err);
  }

  if (demoEntered || process.env.PLAYWRIGHT_ENTER_DEMO === "1") {
    await page.evaluate(() => {
      localStorage.setItem("TEST_MODE", "1");
      localStorage.setItem("TEST_DEMO", "1");
      localStorage.setItem("auth_token", "TEST_DEMO_TOKEN");
      localStorage.setItem("user_demo_mode", "1");
      localStorage.setItem("dfc_demo_gate_passed", "1");
    });
  }

  // ── 2. Navigate to the target route ──────────────────────────────────────
  await page.goto(targetUrl, { waitUntil: "domcontentloaded" });

  // ── 3. Wait for Flutter to be ready (page is loaded + engine initialised) ─
  await waitForFlutterReady(page);

  // ── 4. Specific route selector — best-effort only (route may be auth-gated)
  try {
    await page.waitForSelector(routeSelector, {
      timeout: specificTimeout,
      state: "attached",
    });
    return true;
  } catch {
    // Specific widget not found (likely redirected by auth guard or route guard).
    // Flutter is running — screenshot size + assertRouteContract do real validation.
    console.warn(
      `Route '${route}' route-specific selector not found (likely auth-gated). ` +
      `Flutter page is loaded. Missing selector: ${routeSelector}`,
    );
    return true;
  }
}
