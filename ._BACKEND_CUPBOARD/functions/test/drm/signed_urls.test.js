// ─────────────────────────────────────────────────────────────────────────────
// test/drm/signed_urls.test.js — Unit tests for CDN Signed URL module
// ─────────────────────────────────────────────────────────────────────────────

"use strict";

// ── Mocks (must be hoisted before require) ───────────────────────────────────

// Minimal firebase-admin mock
const mockGetSignedUrl = jest.fn();
const mockFileExists  = jest.fn();
const mockFile        = jest.fn(() => ({
  exists: mockFileExists,
  getSignedUrl: mockGetSignedUrl,
}));
const mockBucket      = jest.fn(() => ({ file: mockFile }));

jest.mock("firebase-admin", () => ({
  storage:   () => ({ bucket: mockBucket }),
  auth:      () => ({ verifyIdToken: jest.fn() }),
  firestore: { FieldValue: { serverTimestamp: () => "SERVER_TS" } },
}));

jest.mock("firebase-functions/v2/https", () => ({
  onCall:   (_, handler) => handler,
  onRequest: (_, handler) => handler,
  HttpsError: class HttpsError extends Error {
    constructor(code, message) {
      super(message);
      this.code = code;
    }
  },
}));

jest.mock("firebase-functions/params", () => ({
  defineSecret: () => ({ value: () => "test-cdn-secret" }),
}));

jest.mock("../config", () => ({
  admin: require("firebase-admin"),
  db: {
    collection: () => ({
      add: jest.fn().mockResolvedValue({}),
    }),
  },
  REGION: "australia-southeast1",
}));

// ── Module under test ────────────────────────────────────────────────────────

const { signCdnUrl, cdnTokenApi, getPosterSignedUrl } =
  require("../../drm/signed_urls");

// ── Helpers ───────────────────────────────────────────────────────────────────

const crypto = require("crypto");

function makeReq(overrides = {}) {
  return {
    method:  "POST",
    headers: { authorization: "Bearer valid-id-token" },
    body:    { assetUrl: "https://cdn.example.com/poster.jpg", ttlSeconds: 3600 },
    ...overrides,
  };
}

function makeRes() {
  const res = { _status: null, _body: null };
  res.status = (code) => { res._status = code; return res; };
  res.json   = (body)  => { res._body  = body;  return res; };
  return res;
}

beforeEach(() => {
  jest.clearAllMocks();
  // default: auth verification succeeds
  require("firebase-admin")
    .auth()
    .verifyIdToken.mockResolvedValue({ uid: "user-abc" });
});

// ── signCdnUrl (pure function) ────────────────────────────────────────────────

describe("signCdnUrl", () => {
  it("appends expires and sig query params", () => {
    const { signedUrl, expires } = signCdnUrl(
      "https://cdn.example.com/image.jpg",
      "my-secret",
      60
    );
    expect(signedUrl).toContain("?expires=");
    expect(signedUrl).toContain("&sig=");
    expect(expires).toBeGreaterThan(Math.floor(Date.now() / 1000));
  });

  it("uses & separator when URL already has a query string", () => {
    const { signedUrl } = signCdnUrl(
      "https://cdn.example.com/image.jpg?foo=bar",
      "secret",
      60
    );
    expect(signedUrl).toContain("foo=bar&expires=");
  });

  it("signature is reproducible with the same inputs", () => {
    // freeze expires so we can verify determinism
    const url    = "https://cdn.example.com/asset.mp4";
    const secret = "stable-secret";
    const expires = Math.floor(Date.now() / 1000) + 300;
    const expected = crypto
      .createHmac("sha256", secret)
      .update(`${url}|${expires}`)
      .digest("hex");

    const { signedUrl } = signCdnUrl(url, secret, 300);
    // The URL must contain the expected sig hex (TTL drift < 1s in test runner)
    expect(signedUrl).toContain(`sig=${expected}`);
  });
});

// ── cdnTokenApi (HTTP endpoint) ───────────────────────────────────────────────

describe("cdnTokenApi", () => {
  it("rejects non-POST with 405", async () => {
    const req = makeReq({ method: "GET" });
    const res = makeRes();
    await cdnTokenApi(req, res);
    expect(res._status).toBe(405);
  });

  it("rejects missing auth with 401", async () => {
    require("firebase-admin")
      .auth()
      .verifyIdToken.mockRejectedValue(new Error("bad token"));
    const req = makeReq({ headers: { authorization: "Bearer bad" } });
    const res = makeRes();
    await cdnTokenApi(req, res);
    expect(res._status).toBe(401);
  });

  it("rejects missing assetUrl with 400", async () => {
    const req = makeReq({ body: {} });
    const res = makeRes();
    await cdnTokenApi(req, res);
    expect(res._status).toBe(400);
    expect(res._body.error).toMatch(/assetUrl/i);
  });

  it("rejects non-HTTPS assetUrl with 400", async () => {
    const req = makeReq({ body: { assetUrl: "http://insecure.example.com/img.jpg" } });
    const res = makeRes();
    await cdnTokenApi(req, res);
    expect(res._status).toBe(400);
    expect(res._body.error).toMatch(/HTTPS/i);
  });

  it("returns signed URL for a valid request", async () => {
    const req = makeReq();
    const res = makeRes();
    await cdnTokenApi(req, res);
    expect(res._status).toBe(200);
    expect(res._body).toHaveProperty("signedAssetUrl");
    expect(res._body).toHaveProperty("expiresAt");
    expect(res._body.signedAssetUrl).toContain("?expires=");
    expect(res._body.signedAssetUrl).toContain("&sig=");
  });

  it("caps TTL at MAX_CDN_TTL (86400s)", async () => {
    const req = makeReq({
      body: { assetUrl: "https://cdn.example.com/poster.jpg", ttlSeconds: 999999 },
    });
    const res = makeRes();
    await cdnTokenApi(req, res);
    expect(res._status).toBe(200);
    const expiresAt = new Date(res._body.expiresAt).getTime() / 1000;
    const now       = Date.now() / 1000;
    expect(expiresAt - now).toBeLessThanOrEqual(86400 + 5); // 5s tolerance
  });
});

// ── getPosterSignedUrl (Callable) ─────────────────────────────────────────────

describe("getPosterSignedUrl", () => {
  it("throws unauthenticated when auth is missing", async () => {
    await expect(
      getPosterSignedUrl({ auth: null, data: { gsPath: "gs://bucket/poster.jpg" } })
    ).rejects.toMatchObject({ code: "unauthenticated" });
  });

  it("throws invalid-argument when gsPath is missing", async () => {
    await expect(
      getPosterSignedUrl({ auth: { uid: "user-abc" }, data: {} })
    ).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("throws invalid-argument for a non-gs:// path", async () => {
    await expect(
      getPosterSignedUrl({
        auth: { uid: "user-abc" },
        data: { gsPath: "https://not-gcs/poster.jpg" },
      })
    ).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("throws not-found when object does not exist", async () => {
    mockFileExists.mockResolvedValue([false]);
    await expect(
      getPosterSignedUrl({
        auth: { uid: "user-abc" },
        data: { gsPath: "gs://my-bucket/posters/event.jpg" },
      })
    ).rejects.toMatchObject({ code: "not-found" });
  });

  it("returns signedUrl and cache headers for an existing poster", async () => {
    mockFileExists.mockResolvedValue([true]);
    mockGetSignedUrl.mockResolvedValue(["https://storage.googleapis.com/signed?tok=abc"]);

    const result = await getPosterSignedUrl({
      auth: { uid: "user-abc" },
      data: { gsPath: "gs://my-bucket/posters/event.jpg" },
    });

    expect(result).toHaveProperty("signedUrl");
    expect(result.signedUrl).toContain("googleapis.com");
    expect(result).toHaveProperty("expiresAt");
    expect(result.cacheControl).toContain("immutable");
  });
});
