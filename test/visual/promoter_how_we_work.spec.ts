import { expect, test } from "@playwright/test";

const BASE = process.env.PLAYWRIGHT_BASE_URL ?? "http://127.0.0.1:8088";

test.describe("Promoter How We Work", () => {
  test("hero headline and primary CTA render", async ({ page }) => {
    await page.goto(`${BASE}/promoters.html`, { waitUntil: "domcontentloaded" });
    await page.waitForLoadState("networkidle");

    await expect(page.getByRole("heading", { name: /partner with data fight central/i })).toBeVisible();
    await expect(page.getByRole("link", { name: /download pilot licence/i })).toBeVisible();
    await expect(page.getByText(/does\s+not\s+hold\s+promoter\s+funds/i).first()).toBeVisible();
  });
});
