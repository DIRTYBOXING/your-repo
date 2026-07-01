import { expect, test } from "@playwright/test";

import { enterDemoModeIfAvailable } from "./helpers/enterDemoMode";
import { waitForFlutterReady } from "./helpers/waitForFlutter";

const adminSalesRoute =
  process.env.PLAYWRIGHT_ADMIN_SALES_ROUTE ?? "/#/admin/sales";

test("sales admin review screen is discoverable", async ({ page }) => {
  await page.goto(adminSalesRoute, { waitUntil: "domcontentloaded" });
  await enterDemoModeIfAvailable(page);
  await waitForFlutterReady(page);
  await page.waitForTimeout(1500);

  const screen = page.locator(
    '[data-test="sales-admin-screen"], [aria-label*="data-test=sales-admin-screen"], text=Sales Admin',
  );
  await expect(screen.first()).toBeVisible();
});
