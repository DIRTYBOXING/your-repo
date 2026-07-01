import { expect, test } from "@playwright/test";

import { enterDemoModeIfAvailable } from "./helpers/enterDemoMode";
import { waitForFlutterReady } from "./helpers/waitForFlutter";

const apiBase = process.env.PLAYWRIGHT_API_BASE;
const watchRoute =
  process.env.PLAYWRIGHT_PPV_WATCH_ROUTE ?? "/#/ppv/demo-eternal-80/watch";
const eventId = process.env.PLAYWRIGHT_PPV_EVENT_ID ?? "demo-eternal-80";
const userId = process.env.PLAYWRIGHT_PPV_USER_ID ?? "demo_user";

test("purchase webhook creates entitlement and watch surface is reachable", async ({
  page,
  request,
}) => {
  test.skip(!apiBase, "PLAYWRIGHT_API_BASE is required for purchase E2E");

  const createOrder = await request.post(`${apiBase}/api/orders/create`, {
    data: {
      eventId,
      userId,
      amountCents: 2999,
      tierId: "starter",
    },
  });
  expect(createOrder.ok()).toBeTruthy();

  const orderPayload = await createOrder.json();
  expect(orderPayload.orderId).toBeTruthy();

  const webhook = await request.post(`${apiBase}/api/orders/webhook`, {
    data: {
      orderId: orderPayload.orderId,
      eventId,
      userId,
      status: "succeeded",
    },
  });
  expect(webhook.ok()).toBeTruthy();

  const entitlement = await request.get(
    `${apiBase}/api/entitlement/${userId}/${eventId}`,
  );
  expect(entitlement.ok()).toBeTruthy();

  const entitlementPayload = await entitlement.json();
  expect(entitlementPayload.hasAccess).toBeTruthy();

  await page.goto(watchRoute, { waitUntil: "domcontentloaded" });
  await enterDemoModeIfAvailable(page);
  await waitForFlutterReady(page);
  await page.waitForTimeout(1800);

  const watchSurface = page.locator(
    '[aria-label*="data-test=entitlement-success-"], [aria-label*="data-test=ppv-watch-root-"]',
  );
  await expect(watchSurface.first()).toBeVisible();
});
