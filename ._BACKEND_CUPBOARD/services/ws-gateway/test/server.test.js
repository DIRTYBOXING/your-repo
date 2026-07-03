const assert = require("node:assert/strict");
const { once } = require("node:events");
const test = require("node:test");

const { WebSocket } = require("ws");

const { createGatewayServer } = require("../server");

async function startGateway() {
  const gateway = createGatewayServer();
  await new Promise((resolve) => {
    gateway.server.listen(0, "127.0.0.1", resolve);
  });

  const address = gateway.server.address();
  const port = typeof address === "object" && address ? address.port : 0;
  return {
    ...gateway,
    baseUrl: `http://127.0.0.1:${port}`,
    wsUrl: `ws://127.0.0.1:${port}/ws/social`,
  };
}

async function stopGateway(server) {
  await new Promise((resolve, reject) => {
    server.close((error) => {
      if (error) {
        reject(error);
        return;
      }

      resolve();
    });
  });
}

async function waitForOpen(socket) {
  if (socket.readyState === WebSocket.OPEN) {
    return;
  }

  await once(socket, "open");
}

async function nextJson(socket) {
  const [data] = await once(socket, "message");
  return JSON.parse(data.toString());
}

test("status endpoints expose readiness and unknown routes return 404", async () => {
  const gateway = await startGateway();

  try {
    const statusResponse = await fetch(`${gateway.baseUrl}/v1/status`);
    assert.equal(statusResponse.status, 200);
    assert.deepEqual(await statusResponse.json(), {
      status: "ok",
      ready: true,
      service: "ws-gateway",
      activeConnections: 0,
    });

    const healthResponse = await fetch(`${gateway.baseUrl}/healthz`);
    assert.equal(healthResponse.status, 200);
    assert.deepEqual(await healthResponse.json(), {
      status: "ok",
      service: "ws-gateway",
      activeConnections: 0,
    });

    const readyResponse = await fetch(`${gateway.baseUrl}/ready`);
    assert.equal(readyResponse.status, 200);
    assert.deepEqual(await readyResponse.json(), {
      ready: true,
      service: "ws-gateway",
      activeConnections: 0,
    });

    const missingResponse = await fetch(`${gateway.baseUrl}/missing`);
    assert.equal(missingResponse.status, 404);
    assert.equal(await missingResponse.text(), "not found");
  } finally {
    await stopGateway(gateway.server);
  }
});

test("websocket connections validate input, respond to ping, and fan out messages", async () => {
  const gateway = await startGateway();
  const alice = new WebSocket(`${gateway.wsUrl}?userId=alice`);
  const bob = new WebSocket(`${gateway.wsUrl}?userId=bob`);

  try {
    await Promise.all([waitForOpen(alice), waitForOpen(bob)]);

    const readyWithConnections = await fetch(`${gateway.baseUrl}/ready`);
    assert.equal(readyWithConnections.status, 200);
    assert.deepEqual(await readyWithConnections.json(), {
      ready: true,
      service: "ws-gateway",
      activeConnections: 2,
    });

    const invalidJsonPromise = nextJson(alice);
    alice.send("not-json");
    assert.deepEqual(await invalidJsonPromise, {
      type: "error",
      reason: "invalid_json",
    });

    const missingTypePromise = nextJson(alice);
    alice.send(JSON.stringify({}));
    assert.deepEqual(await missingTypePromise, {
      type: "error",
      reason: "type_required",
    });

    const unsupportedPromise = nextJson(alice);
    alice.send(JSON.stringify({ type: "unknown" }));
    assert.deepEqual(await unsupportedPromise, {
      type: "error",
      reason: "unsupported_type",
    });

    const pongPromise = nextJson(alice);
    alice.send(JSON.stringify({ type: "ping" }));
    const pong = await pongPromise;
    assert.equal(pong.type, "pong");
    assert.match(pong.at, /^\d{4}-\d{2}-\d{2}T/);

    const ackPromise = nextJson(alice);
    const messagePromise = nextJson(bob);
    alice.send(
      JSON.stringify({
        type: "message",
        recipientId: "bob",
        threadId: "thread-1",
        body: "hello from alice",
      }),
    );

    const [ack, envelope] = await Promise.all([ackPromise, messagePromise]);
    assert.deepEqual(ack, { type: "ack", delivered: 1 });
    assert.equal(envelope.type, "message");
    assert.equal(envelope.threadId, "thread-1");
    assert.equal(envelope.senderId, "alice");
    assert.equal(envelope.recipientId, "bob");
    assert.equal(envelope.body, "hello from alice");
    assert.match(envelope.sentAt, /^\d{4}-\d{2}-\d{2}T/);

    const closeAlice = once(alice, "close");
    const closeBob = once(bob, "close");
    alice.close();
    bob.close();
    await Promise.all([closeAlice, closeBob]);
    await new Promise((resolve) => setImmediate(resolve));

    const readyAfterClose = await fetch(`${gateway.baseUrl}/ready`);
    assert.equal(readyAfterClose.status, 200);
    assert.deepEqual(await readyAfterClose.json(), {
      ready: true,
      service: "ws-gateway",
      activeConnections: 0,
    });
  } finally {
    if (alice.readyState === WebSocket.OPEN) {
      alice.close();
    }
    if (bob.readyState === WebSocket.OPEN) {
      bob.close();
    }

    await stopGateway(gateway.server);
  }
});

test("connections without a userId are rejected", async () => {
  const gateway = await startGateway();
  const anonymous = new WebSocket(gateway.wsUrl);

  try {
    const [code, reason] = await once(anonymous, "close");
    assert.equal(code, 4000);
    assert.equal(reason.toString(), "userId required");
  } finally {
    if (anonymous.readyState === WebSocket.OPEN) {
      anonymous.close();
    }

    await stopGateway(gateway.server);
  }
});
