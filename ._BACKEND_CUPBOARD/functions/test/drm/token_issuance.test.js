// ─────────────────────────────────────────────────────────────────────────────
// functions/test/drm/token_issuance.test.js
//
// Unit tests for the DRM token issuance handler.
// Uses Jest with manual mocks for firebase-admin and jsonwebtoken.
//
// Run: cd functions && npx jest test/drm/token_issuance.test.js --env=node
// ─────────────────────────────────────────────────────────────────────────────

"use strict";

const jwt = require("jsonwebtoken");

// ── Test constants ────────────────────────────────────────────────────────────
const TEST_DRM_SECRET = "test_drm_secret_32chars_minimum!!";
const TEST_UID = "uid-test-user-123";
const TEST_EVENT_ID = "bkfc-newcastle-2026";

// ── Firebase Admin mock ───────────────────────────────────────────────────────
jest.mock("firebase-admin", () => {
  const FieldValue = { serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP") };
  const mockAdd = jest.fn().mockResolvedValue({ id: "mock-doc-id" });
  const mockLimit = jest.fn().mockReturnValue({ get: jest.fn().mockResolvedValue({ empty: true }) });
  const mockWhere = jest.fn().mockReturnThis();
  const mockGet = jest.fn();
  const mockDoc = jest.fn(() => ({ get: mockGet }));
  const mockCollection = jest.fn(() => ({
    doc: mockDoc,
    add: mockAdd,
    where: mockWhere,
    limit: mockLimit,
  }));
  const mockFirestore = jest.fn(() => ({ collection: mockCollection }));
  mockFirestore.FieldValue = FieldValue;

  return {
    apps: [true],
    initializeApp: jest.fn(),
    auth: jest.fn(() => ({ verifyIdToken: jest.fn() })),
    firestore: mockFirestore,
    _mocks: { mockDoc, mockGet, mockAdd, mockCollection, FieldValue, mockWhere, mockLimit },
  };
});

// ── Firebase Functions mock ───────────────────────────────────────────────────
jest.mock("firebase-functions/v2/https", () => ({
  onRequest: jest.fn((opts, handler) => handler),
}));
jest.mock("firebase-functions/params", () => ({
  defineSecret: jest.fn(() => ({ value: jest.fn(() => TEST_DRM_SECRET) })),
}));

// ── Config mock ───────────────────────────────────────────────────────────────
jest.mock("../config", () => {
  const admin = require("firebase-admin");
  return {
    admin,
    db: admin.firestore(),
    REGION: "australia-southeast1",
  };
});

// ── Helpers ───────────────────────────────────────────────────────────────────

const admin = require("firebase-admin");
const { _mocks } = admin;

/** Build a minimal Express-like mock request */
function makeReq({ uid = TEST_UID, eventId = TEST_EVENT_ID, device = "web", scope = "playback", method = "POST" } = {}) {
  const idToken = jwt.sign({ uid }, "firebase-test-secret");
  return {
    method,
    headers: {
      authorization: `Bearer ${idToken}`,
      "x-forwarded-for": "1.2.3.4",
    },
    body: { eventId, device, scope },
    ip: "1.2.3.4",
  };
}

/** Build a minimal Express-like mock response */
function makeRes() {
  const res = {
    _status: 200,
    _body: null,
    status(code) { this._status = code; return this; },
    json(body) { this._body = body; return this; },
  };
  return res;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe("DRM token_issuance handler", () => {
  let handler;

  beforeAll(() => {
    process.env.DRM_PROVIDER_SECRET = TEST_DRM_SECRET;
    process.env.DRM_TOKEN_TTL_SECONDS = "60";
    // handler is the raw async function exported by onRequest mock
    handler = require("../drm/token_issuance").drmTokenApi;
  });

  beforeEach(() => {
    jest.clearAllMocks();

    // Default: verifyIdToken resolves successfully
    admin.auth.mockReturnValue({
      verifyIdToken: jest.fn().mockResolvedValue({ uid: TEST_UID }),
    });

    // Default: entitlement exists
    _mocks.mockGet.mockResolvedValue({
      exists: true,
      data: () => ({ expiresAt: null }),
    });
  });

  it("rejects non-POST requests with 405", async () => {
    const req = makeReq({ method: "GET" });
    const res = makeRes();
    await handler(req, res);
    expect(res._status).toBe(405);
  });

  it("rejects missing Authorization header with 401", async () => {
    admin.auth.mockReturnValue({
      verifyIdToken: jest.fn().mockRejectedValue(new Error("no token")),
    });
    const req = makeReq();
    req.headers.authorization = "";
    const res = makeRes();
    await handler(req, res);
    expect(res._status).toBe(401);
  });

  it("rejects missing eventId with 400", async () => {
    const req = makeReq({ eventId: undefined });
    req.body = {};
    const res = makeRes();
    await handler(req, res);
    expect(res._status).toBe(400);
    expect(res._body.error).toMatch(/eventId/i);
  });

  it("rejects user with no entitlement with 403", async () => {
    _mocks.mockGet.mockResolvedValue({ exists: false });
    _mocks.mockLimit.mockReturnValue({
      get: jest.fn().mockResolvedValue({ empty: true }),
    });
    const res = makeRes();
    await handler(makeReq(), res);
    expect(res._status).toBe(403);
    expect(res._body.error).toMatch(/entitlement/i);
  });

  it("issues a valid JWT for entitled user", async () => {
    const res = makeRes();
    await handler(makeReq(), res);
    expect(res._status).toBe(200);
    expect(res._body.token).toBeDefined();
    expect(res._body.expiresIn).toBe(60);

    // Verify the token payload is correct
    const decoded = jwt.verify(res._body.token, TEST_DRM_SECRET);
    expect(decoded.sub).toBe(TEST_UID);
    expect(decoded.event).toBe(TEST_EVENT_ID);
    expect(decoded.dev).toBe("web");
    expect(decoded.scope).toBe("playback");
  });

  it("caps TTL at MAX_TTL (300s) even if env sets higher", async () => {
    process.env.DRM_TOKEN_TTL_SECONDS = "9999";
    // reload module to pick up new env
    jest.resetModules();
    jest.mock("firebase-functions/params", () => ({
      defineSecret: jest.fn(() => ({ value: jest.fn(() => TEST_DRM_SECRET) })),
    }));
    const freshHandler = require("../drm/token_issuance").drmTokenApi;
    const res = makeRes();
    await freshHandler(makeReq(), res);
    expect(res._body.expiresIn).toBeLessThanOrEqual(300);
    process.env.DRM_TOKEN_TTL_SECONDS = "60";
  });

  it("falls back to query when composite doc missing", async () => {
    // composite doc doesn't exist
    _mocks.mockGet.mockResolvedValue({ exists: false });
    // but query returns a match
    _mocks.mockLimit.mockReturnValue({
      get: jest.fn().mockResolvedValue({
        empty: false,
        docs: [{ id: "ent-1", data: () => ({ status: "active" }) }],
      }),
    });
    const res = makeRes();
    await handler(makeReq(), res);
    expect(res._status).toBe(200);
    expect(res._body.token).toBeDefined();
  });
});
