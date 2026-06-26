import { type Page } from "@playwright/test";

function shouldEnterDemoFromEnv(): boolean {
  const raw = process.env.PLAYWRIGHT_ENTER_DEMO?.trim().toLowerCase();
  return raw === "1" || raw === "true" || raw === "yes";
}

export async function enterDemoModeIfAvailable(page: Page): Promise<boolean> {
  const demoButton = page.getByRole("button", { name: /enter dfc/i });
  const hasDemoButton = (await demoButton.count()) > 0;

  if (!hasDemoButton) {
    return false;
  }

  if (!shouldEnterDemoFromEnv()) {
    throw new Error(
      'Playwright detected the "ENTER DFC — DEMO MODE" gate. ' +
        "Run the app in real mode (scripts/run_with_env.ps1 -Mode real) " +
        "or set PLAYWRIGHT_ENTER_DEMO=1 to allow demo-mode screenshots.",
    );
  }

  await demoButton.first().click();
  try {
    await page.waitForURL((url) => /\/home/.test(url.href), {
      timeout: 12000,
    });
  } catch {
    // Some routes can settle without URL mutation after gate click.
  }

  return true;
}
