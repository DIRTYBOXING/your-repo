/**
 * Unit tests for publishToFacebook, graphApiPost, and getSecret.
 *
 * All external I/O is mocked — no real HTTP requests or Secret Manager calls.
 */

import https from "https";
import { EventEmitter } from "events";

// ── Mock @google-cloud/secret-manager before any import ─────────────────────
const mockAccessSecretVersion = jest.fn();
jest.mock("@google-cloud/secret-manager", () => ({
  SecretManagerServiceClient: jest.fn().mockImplementation(() => ({
    accessSecretVersion: mockAccessSecretVersion,
  })),
}));

// ── Mock firebase-admin so module init doesn't fail ──────────────────────────
jest.mock("firebase-admin", () => ({
  apps: [],
  initializeApp: jest.fn(),
  firestore: jest.fn().mockReturnValue({
    collection: jest.fn().mockReturnValue({
      where: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      get: jest.fn().mockResolvedValue({ empty: true }),
      add: jest.fn().mockResolvedValue({}),
      doc: jest.fn().mockReturnValue({
        get: jest.fn().mockResolvedValue({ exists: false }),
      }),
    }),
  }),
}));

// ── Mock @google-cloud/pubsub ─────────────────────────────────────────────────
jest.mock("@google-cloud/pubsub", () => ({
  PubSub: jest.fn().mockImplementation(() => ({
    topic: jest.fn().mockReturnValue({ publishJSON: jest.fn() }),
  })),
}));

// ── Import after mocks ────────────────────────────────────────────────────────
import { getSecret, graphApiPost, publishToFacebook } from "../index";

// ── Helper: create a mock HTTPS response ────────────────────────────────────
function mockHttpResponse(statusCode: number, body: object): void {
  const mockRes = new EventEmitter() as NodeJS.ReadableStream & { statusCode: number };
  (mockRes as unknown as { statusCode: number }).statusCode = statusCode;

  jest.spyOn(https, "request").mockImplementationOnce((_opts, cb) => {
    if (cb) process.nextTick(() => (cb as (res: import("http").IncomingMessage) => void)(mockRes as unknown as import("http").IncomingMessage));
    const mockReq = new EventEmitter() as ReturnType<typeof https.request>;
    (mockReq as unknown as { write: () => void; end: () => void }).write = jest.fn();
    (mockReq as unknown as { write: () => void; end: () => void }).end = jest.fn(() => {
      process.nextTick(() => {
        mockRes.emit("data", Buffer.from(JSON.stringify(body)));
        mockRes.emit("end");
      });
    });
    return mockReq;
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// getSecret
// ─────────────────────────────────────────────────────────────────────────────
describe("getSecret", () => {
  const OLD_ENV = process.env;

  beforeEach(() => {
    process.env = { ...OLD_ENV, GOOGLE_CLOUD_PROJECT: "test-project" };
  });

  afterEach(() => {
    process.env = OLD_ENV;
    jest.clearAllMocks();
  });

  it("returns the secret value on success", async () => {
    mockAccessSecretVersion.mockResolvedValueOnce([
      { payload: { data: Buffer.from("my-secret-value") } },
    ]);
    const value = await getSecret("my-secret");
    expect(value).toBe("my-secret-value");
    expect(mockAccessSecretVersion).toHaveBeenCalledWith({
      name: "projects/test-project/secrets/my-secret/versions/latest",
    });
  });

  it("throws when GOOGLE_CLOUD_PROJECT is not set", async () => {
    delete process.env["GOOGLE_CLOUD_PROJECT"];
    delete process.env["GCLOUD_PROJECT"];
    await expect(getSecret("any-secret")).rejects.toThrow("GOOGLE_CLOUD_PROJECT env var not set");
  });

  it("throws when the secret payload is empty", async () => {
    mockAccessSecretVersion.mockResolvedValueOnce([{ payload: { data: null } }]);
    await expect(getSecret("empty-secret")).rejects.toThrow("Secret 'empty-secret' is empty");
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// graphApiPost
// ─────────────────────────────────────────────────────────────────────────────
describe("graphApiPost", () => {
  afterEach(() => {
    jest.restoreAllMocks();
    jest.clearAllMocks();
  });

  it("returns the response body on HTTP 200", async () => {
    mockHttpResponse(200, { id: "post_123" });
    const result = await graphApiPost("/v19.0/123/feed", "message=hello");
    expect(result).toEqual({ id: "post_123" });
  });

  it("throws on a Graph API error body", async () => {
    mockHttpResponse(200, { error: { message: "Invalid token", code: 190 } });
    await expect(graphApiPost("/v19.0/123/feed", "message=hello")).rejects.toThrow(
      "Graph API error",
    );
  });

  it("retries on HTTP 429 and succeeds on subsequent attempt", async () => {
    mockHttpResponse(429, { error: { message: "rate limited" } });
    mockHttpResponse(200, { id: "post_after_retry" });

    const result = await graphApiPost("/v19.0/123/feed", "body=x", /* maxAttempts */ 3);
    expect(result).toEqual({ id: "post_after_retry" });
  }, 10_000);

  it("throws after exhausting maxAttempts on persistent 500", async () => {
    for (let i = 0; i < 3; i++) {
      mockHttpResponse(500, { error: "server error" });
    }
    await expect(
      graphApiPost("/v19.0/123/feed", "body=x", /* maxAttempts */ 3),
    ).rejects.toThrow("transient failure after 3 attempts");
  }, 20_000);
});

// ─────────────────────────────────────────────────────────────────────────────
// publishToFacebook
// ─────────────────────────────────────────────────────────────────────────────
describe("publishToFacebook", () => {
  const OLD_ENV = process.env;

  beforeEach(() => {
    process.env = { ...OLD_ENV, GOOGLE_CLOUD_PROJECT: "test-project" };
  });

  afterEach(() => {
    process.env = OLD_ENV;
    jest.restoreAllMocks();
    jest.clearAllMocks();
  });

  it("logs success metric on successful photo publish", async () => {
    mockAccessSecretVersion
      .mockResolvedValueOnce([{ payload: { data: Buffer.from("page_123") } }])
      .mockResolvedValueOnce([{ payload: { data: Buffer.from("tok_abc") } }]);
    mockHttpResponse(200, { id: "new_post_456" });

    const logSpy = jest.spyOn(console, "info").mockImplementation(() => {});

    await publishToFacebook(
      { campaignId: "c1", caption: "Fight Night!", posterUrl: "https://cdn.dfc.com/img.jpg", market: "AU" },
      {},
    );

    const loggedJson = JSON.parse(logSpy.mock.calls[0][0] as string);
    expect(loggedJson.metric).toBe("facebook_publish_success");
    expect(loggedJson.postId).toBe("new_post_456");
  });

  it("logs success metric on feed-only (no image) publish", async () => {
    mockAccessSecretVersion
      .mockResolvedValueOnce([{ payload: { data: Buffer.from("page_123") } }])
      .mockResolvedValueOnce([{ payload: { data: Buffer.from("tok_abc") } }]);
    mockHttpResponse(200, { post_id: "feed_789" });

    const logSpy = jest.spyOn(console, "info").mockImplementation(() => {});

    await publishToFacebook({ campaignId: "c2", caption: "Text only" }, {});

    const loggedJson = JSON.parse(logSpy.mock.calls[0][0] as string);
    expect(loggedJson.metric).toBe("facebook_publish_success");
    expect(loggedJson.postId).toBe("feed_789");
  });

  it("does not log the page token in any console output", async () => {
    mockAccessSecretVersion
      .mockResolvedValueOnce([{ payload: { data: Buffer.from("page_123") } }])
      .mockResolvedValueOnce([{ payload: { data: Buffer.from("SECRET_TOKEN_DO_NOT_LOG") } }]);
    mockHttpResponse(200, { id: "p1" });

    const outputs: string[] = [];
    jest.spyOn(console, "info").mockImplementation((...args) => outputs.push(args.join(" ")));
    jest.spyOn(console, "warn").mockImplementation((...args) => outputs.push(args.join(" ")));

    await publishToFacebook({ campaignId: "c3", caption: "Safe" }, {});

    const allOutput = outputs.join(" ");
    expect(allOutput).not.toContain("SECRET_TOKEN_DO_NOT_LOG");
  });

  it("skips gracefully when GOOGLE_CLOUD_PROJECT is not set", async () => {
    delete process.env["GOOGLE_CLOUD_PROJECT"];
    delete process.env["GCLOUD_PROJECT"];
    const warnSpy = jest.spyOn(console, "warn").mockImplementation(() => {});
    await publishToFacebook({}, {});
    expect(warnSpy).toHaveBeenCalledWith(
      expect.stringContaining("GOOGLE_CLOUD_PROJECT not set"),
    );
  });

  it("throws (so DLQ can capture) when Graph API returns an error", async () => {
    mockAccessSecretVersion
      .mockResolvedValueOnce([{ payload: { data: Buffer.from("page_123") } }])
      .mockResolvedValueOnce([{ payload: { data: Buffer.from("tok_abc") } }]);
    mockHttpResponse(200, { error: { message: "Invalid token", code: 190 } });

    await expect(publishToFacebook({ campaignId: "c4", caption: "Bad" }, {})).rejects.toThrow(
      "Graph API error",
    );
  });
});
