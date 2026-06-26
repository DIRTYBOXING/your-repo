import { test, expect } from "@playwright/test";

import { enterDemoModeIfAvailable } from "./helpers/enterDemoMode";
import { waitForFlutterReady } from "./helpers/waitForFlutter";

const shellRoute = process.env.PLAYWRIGHT_SHELL_ROUTE ?? "/#/home";

test("home shell renders consistently across mobile widths", async ({
  page,
}, testInfo) => {
  await page.goto(shellRoute, { waitUntil: "domcontentloaded" });
  await enterDemoModeIfAvailable(page);
  await waitForFlutterReady(page);

  await expect(page).toHaveScreenshot(
    `home-shell-${testInfo.project.name}.png`,
    {
      animations: "disabled",
      fullPage: true,
      maxDiffPixelRatio: 0.015,
      timeout: 15000,
    },
  );
});
