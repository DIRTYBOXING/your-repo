import { Page } from "@playwright/test";

export async function waitForFlutterReady(
  page: Page,
  selector?: string,
): Promise<void> {
  await page.waitForLoadState("domcontentloaded");

  if (selector) {
    await page.waitForSelector(selector, { timeout: 15000 });
  } else {
    // Flutter web can expose different readiness markers depending on renderer,
    // build mode, and bootstrap timing. Try strict checks first, then degrade.
    const strictReady = page
      .waitForFunction(
        () =>
          Boolean(
            document.querySelector('[data-test="ppv-ready"]') ||
            (globalThis as { __DFC_READY__?: boolean }).__DFC_READY__ ||
            document.querySelector(
              "flutter-view, flt-glass-pane, flt-semantics-placeholder",
            ),
          ),
        { timeout: 12000 },
      )
      .then(() => true)
      .catch(() => false);

    const domStable = page
      .waitForFunction(
        () => {
          const hasBody = Boolean(document.body);
          const ready = document.readyState;
          return hasBody && (ready === "interactive" || ready === "complete");
        },
        { timeout: 8000 },
      )
      .then(() => true)
      .catch(() => false);

    const hasSignal = await Promise.race([strictReady, domStable]);
    if (!hasSignal) {
      // Last-resort settle: do not fail the whole visual test suite on one
      // bootstrap signal mismatch; screenshots/assertions will still validate UI.
      await page.waitForTimeout(1000);
    }
  }

  await page.evaluate(async () => {
    document.body.style.transform = "translateZ(0)";
    await new Promise((resolve) => setTimeout(resolve, 300));
  });

  // Wait for images with a hard 5-second cap — stalled network images must not
  // block the test suite indefinitely (e.g. poster CDN timeouts on PPV Hub).
  await Promise.race([
    page.evaluate(async () => {
      const imgs = Array.from(document.images);
      const waitForImage = (img: HTMLImageElement) =>
        img.complete
          ? Promise.resolve()
          : new Promise<void>((resolve) => {
              img.onload = resolve;
              img.onerror = resolve;
            });
      await Promise.all(imgs.map(waitForImage));
    }),
    page.waitForTimeout(5000),
  ]);

  await page.waitForTimeout(250);
}
