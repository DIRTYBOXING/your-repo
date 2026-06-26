import { expect, Locator, Page } from "@playwright/test";

export async function waitForRouteContent(
  page: Page,
  selector: string,
  timeout = 10000,
): Promise<Locator> {
  const locator = page.locator(selector).first();
  await expect(locator).toBeVisible({ timeout });
  return locator;
}
