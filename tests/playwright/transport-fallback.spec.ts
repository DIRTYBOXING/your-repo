import { test, expect } from "@playwright/test";

test("transport fallback smoke", async ({ request }) => {
  const base =
    process.env.TRANSPORT_BASE || "https://transport.staging.yourdomain.com";
  const url = `${base.replace(/\/$/, "")}/v1/status`;

  const headers: Record<string, string> = {};
  if (process.env.TEST_ENTITLEMENT_TOKEN) {
    headers.Authorization = `Bearer ${process.env.TEST_ENTITLEMENT_TOKEN}`;
  }

  const res = await request.get(url, { headers });

  expect(res.ok()).toBeTruthy();
});
