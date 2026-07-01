import { expect, test } from "@playwright/test";

const apiBase =
  process.env.SOCIAL_API_BASE ??
  process.env.STAGING_BASE ??
  "http://localhost:8080";
const feedUserId = process.env.FEED_USER_ID ?? "demo_user";
const clipUrl = process.env.CLIP_CDN_URL ?? "";

test.describe("Social and messaging smoke", () => {
  test("feed endpoint returns canonical contract shape", async ({
    request,
  }) => {
    const resp = await request.get(`${apiBase}/api/users/${feedUserId}/feed`);
    if (resp.status() === 404 || resp.status() === 501) {
      test.skip(true, "Feed endpoint not available in this environment.");
    }

    expect(resp.ok()).toBeTruthy();
    const body = await resp.json();
    expect(typeof body.userId).toBe("string");
    expect(Array.isArray(body.items)).toBeTruthy();
    expect(typeof body.nextCursor).toBe("string");
  });

  test("clip CDN URL returns success when configured", async ({ request }) => {
    if (!clipUrl) {
      test.skip(true, "CLIP_CDN_URL not configured.");
    }

    const resp = await request.get(clipUrl);
    expect(resp.status()).toBe(200);
  });
});
