import { expect, test } from "@playwright/test";

const apiBase = process.env.PLAYWRIGHT_API_BASE;
const posterBase = process.env.PLAYWRIGHT_POSTER_BASE;
const authExpected = process.env.PLAYWRIGHT_EXPECT_AUTH === "1";
const strictSmoke = process.env.PLAYWRIGHT_STRICT_SMOKE === "1";
const staticWebBase =
  process.env.PLAYWRIGHT_STATIC_WEB_BASE || process.env.PLAYWRIGHT_BASE_URL || "http://127.0.0.1:8088";

const testUser = process.env.PLAYWRIGHT_PPV_USER_ID ?? "smoke_user";
const eventId = Number(process.env.PLAYWRIGHT_PPV_EVENT_ID ?? "999");

function authHeaders(userId: string) {
  return {
    Authorization: `Bearer ${userId}`,
    "Content-Type": "application/json",
  };
}

function skipOrFail(condition: boolean, reason: string) {
  if (!condition) {
    return;
  }
  if (strictSmoke) {
    throw new Error(reason);
  }
  test.skip(condition, reason);
}

async function gotoStaticPageOrSkip(
  page: Parameters<typeof test>[0]["page"],
  route: string,
  requiredSelector: string,
) {
  const response = await page.goto(`${staticWebBase}${route}`, {
    waitUntil: "domcontentloaded",
  });

  const isReachable = Boolean(response?.ok());
  skipOrFail(
    !isReachable,
    `Static route ${route} is not reachable via PLAYWRIGHT_STATIC_WEB_BASE`,
  );

  const hasSelector = (await page.locator(requiredSelector).count()) > 0;
  skipOrFail(!hasSelector, `Static route ${route} missing selector ${requiredSelector}`);
}

test("@smoke promoters help menu + shakura welcome works", async ({ page }) => {
  let shakuraMessage = "";
  page.on("dialog", async (dialog) => {
    shakuraMessage = dialog.message();
    await dialog.accept();
  });

  // promoters.html uses a relative fetch URL that hits the static server;
  // mock it here so the dialog fires regardless of API availability
  await page.route("**/api/shakura/welcome", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({ text: "Hi - I'm Shakura, your DFC guide." }),
    });
  });

  await gotoStaticPageOrSkip(page, "/promoters.html", "#dfc-fuzzy");
  await expect(page.locator("#dfc-fuzzy")).toBeVisible();

  await page.click("#dfc-fuzzy");
  await expect(page.locator("#dfc-fuzzy-actions")).toBeVisible();

  await page.click("#shakura-action");
  await expect
    .poll(() => shakuraMessage, { timeout: 5000 })
    .toContain("Shakura");
});

test("@smoke AI sales modal preview and checkout calls render payload", async ({ page }) => {
  await page.route("**/api/ai/sell", async (route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        eventId,
        audience: "email_list",
        messages: {
          emailSubject: "Don't miss UFC 999 - PPV tickets on sale now",
          sms: "Live tonight",
          push: "Watch live",
        },
      }),
    });
  });

  await page.route("**/api/ppv/create-session", async (route) => {
    await route.fulfill({
      status: 201,
      contentType: "application/json",
      body: JSON.stringify({
        sessionId: "cs_smoke_123",
        checkoutUrl: "https://checkout.example/checkout?session=cs_smoke_123",
        sku: `PPV-${eventId}`,
      }),
    });
  });

  await gotoStaticPageOrSkip(page, "/templates/ai-sales-modal.html", "#ai-sales-modal");
  await page.evaluate((id) => {
    const openFn = (globalThis as any).DFC?.openAISales;
    if (typeof openFn === "function") {
      openFn(id, "UFC 999");
    }
  }, eventId);

  await page.fill("#ai-audience", "email_list");
  await page.fill("#ai-price", "49.99");
  await page.click("#ai-preview");
  await expect(page.locator("#ai-preview-output")).toContainText("emailSubject");

  await page.click("#ai-send");
  await expect(page.locator("#ai-preview-output")).toContainText("checkoutUrl");
});

test("@smoke wallet modal top-up and refresh UI flow", async ({ page }) => {
  let balanceCents = 0;
  let latestTopupId = 0;

  await page.route("**/api/wallet/*", async (route) => {
    if (route.request().method() !== "GET") {
      await route.fallback();
      return;
    }

    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        userId: "u1",
        balanceCents,
        currency: "USD",
        transactions: [],
      }),
    });
  });

  await page.route("**/api/wallet/topup", async (route) => {
    const payload = route.request().postDataJSON() as { amountCents?: number };
    latestTopupId += 1;
    if (typeof payload.amountCents === "number") {
      balanceCents += payload.amountCents;
    }

    await route.fulfill({
      status: 201,
      contentType: "application/json",
      body: JSON.stringify({
        ok: true,
        walletTxId: latestTopupId,
        amountCents: payload.amountCents ?? 0,
        userId: "u1",
      }),
    });
  });

  await gotoStaticPageOrSkip(page, "/templates/wallet-modal.html", "#wallet-balance");
  await expect(page.locator("#wallet-balance")).toContainText("$0.00");

  await page.fill("#wallet-topup-amount", "10");
  await page.selectOption("#wallet-provider", "stripe");
  await page.click("#wallet-topup-btn");
  await expect(page.locator("#wallet-output")).toContainText("walletTxId");

  await page.click("#wallet-refresh-btn");
  await expect(page.locator("#wallet-balance")).toContainText("$10.00");
});

test("@smoke auth middleware blocks unauthenticated and mismatched users", async ({ request }) => {
  skipOrFail(!apiBase || !authExpected, "PLAYWRIGHT_API_BASE and PLAYWRIGHT_EXPECT_AUTH=1 are required");

  const unauthTopup = await request.post(`${apiBase}/api/wallet/topup`, {
    data: {
      userId: testUser,
      amountCents: 1000,
      provider: "stripe",
      idempotencyKey: `auth-topup-${Date.now()}`,
    },
  });
  expect(unauthTopup.status()).toBe(401);

  const mismatchedPpv = await request.post(`${apiBase}/api/ppv/create-session`, {
    headers: {
      Authorization: "Bearer auth_user_a",
      "Content-Type": "application/json",
    },
    data: {
      eventId,
      priceCents: 4999,
      currency: "USD",
      userId: "auth_user_b",
    },
  });
  expect(mismatchedPpv.status()).toBe(403);
});

test("@smoke wallet topup and micropurchase via API", async ({ request }) => {
  skipOrFail(!apiBase, "PLAYWRIGHT_API_BASE is required");

  const topupRes = await request.post(`${apiBase}/api/wallet/topup`, {
    headers: authHeaders(testUser),
    data: {
      userId: testUser,
      amountCents: 1000,
      provider: "stripe",
      idempotencyKey: `pw-topup-${Date.now()}`,
    },
  });
  expect([200, 201]).toContain(topupRes.status());
  const topupPayload = await topupRes.json();
  expect(topupPayload.walletTxId).toBeTruthy();

  const confirmRes = await request.post(`${apiBase}/api/wallet/topup/confirm`, {
    data: {
      userId: testUser,
      walletTxId: topupPayload.walletTxId,
      amountCents: 1000,
      provider: "stripe",
      providerId: `evt_${Date.now()}`,
      idempotencyKey: `pw-confirm-${Date.now()}`,
    },
  });
  expect(confirmRes.ok()).toBeTruthy();

  const purchaseRes = await request.post(`${apiBase}/api/wallet/purchase`, {
    headers: authHeaders(testUser),
    data: {
      userId: testUser,
      itemId: `poster_${eventId}`,
      amountCents: 500,
      idempotencyKey: `pw-purchase-${Date.now()}`,
    },
  });
  expect(purchaseRes.ok()).toBeTruthy();

  const walletRes = await request.get(`${apiBase}/api/wallet/${testUser}`, {
    headers: authHeaders(testUser),
  });
  expect(walletRes.ok()).toBeTruthy();
  const walletPayload = await walletRes.json();
  expect(walletPayload.balanceCents).toBeGreaterThanOrEqual(500);
});

test("@smoke poster service endpoint responds", async ({ request }) => {
  skipOrFail(!posterBase, "PLAYWRIGHT_POSTER_BASE is required");

  const health = await request.get(`${posterBase}/health/live`);
  expect(health.ok()).toBeTruthy();
});
