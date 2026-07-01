import { expect, test } from "@playwright/test";

const staticWebBase =
  process.env.PLAYWRIGHT_STATIC_WEB_BASE || process.env.PLAYWRIGHT_BASE_URL || "http://127.0.0.1:8088";

const viewports = [
  { name: "desktop", width: 1280, height: 800 },
  { name: "tablet", width: 768, height: 1024 },
  { name: "mobile", width: 375, height: 812 },
];

for (const viewport of viewports) {
  test(`@smoke visual baseline profile landing ${viewport.name}`, async ({ page }) => {
    await page.setViewportSize({ width: viewport.width, height: viewport.height });
    const response = await page.goto(`${staticWebBase}/promoters.html`, {
      waitUntil: "domcontentloaded",
    });

    expect(response?.ok()).toBeTruthy();

    const profileCard = page.locator('.profile-card[aria-label="Promoter profile summary card"]');
    await expect(profileCard).toBeVisible({ timeout: 10_000 });
    await expect(profileCard).toHaveScreenshot(`profile-${viewport.name}.png`, {
      animations: "disabled",
    });
  });
}
