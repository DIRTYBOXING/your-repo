const http = require("node:http");
const { WebSocketServer } = require("ws");

const PORT = Number.parseInt(process.env.SOCIAL_WS_PORT || "8799", 10);

function createConnectionRegistry() {
  const connectionsByUser = new Map();

  function addConnection(userId, ws) {
    if (!connectionsByUser.has(userId)) {
      connectionsByUser.set(userId, new Set());
    }
    connectionsByUser.get(userId).add(ws);
  }

  function removeConnection(userId, ws) {
    const set = connectionsByUser.get(userId);
    if (!set) return;
    set.delete(ws);
    if (set.size === 0) connectionsByUser.delete(userId);
  }

  function fanout(recipientId, payload) {
    const targets = connectionsByUser.get(recipientId);
    if (!targets) return 0;

    const serialized = JSON.stringify(payload);
    let delivered = 0;
    for (const ws of targets) {
      if (ws.readyState === ws.OPEN) {
        ws.send(serialized);
        delivered += 1;
      }
    }

    return delivered;
  }

  function getActiveConnections() {
    return [...connectionsByUser.values()].reduce(
      (sum, set) => sum + set.size,
      0,
    );
  }

  return {
    addConnection,
    removeConnection,
    fanout,
    getActiveConnections,
  };
}

function createGatewayServer() {
  const registry = createConnectionRegistry();

  const server = http.createServer((req, res) => {
    if (req.url === "/v1/status") {
      const active = registry.getActiveConnections();
      res.setHeader("content-type", "application/json");
      res.end(
        JSON.stringify({
          status: "ok",
          ready: true,
          service: "ws-gateway",
          activeConnections: active,
        }),
      );
      return;
    }

    if (req.url === "/healthz" || req.url === "/health") {
      const active = registry.getActiveConnections();
      res.setHeader("content-type", "application/json");
      res.end(
        JSON.stringify({
          status: "ok",
          service: "ws-gateway",
          activeConnections: active,
        }),
      );
      return;
    }

    if (req.url === "/ready") {
      const active = registry.getActiveConnections();
      res.setHeader("content-type", "application/json");
      res.end(
        JSON.stringify({
          ready: true,
          service: "ws-gateway",
          activeConnections: active,
        }),
      );
      return;
    }

    res.statusCode = 404;
    res.end("not found");
  });

  const wss = new WebSocketServer({ server, path: "/ws/social" });

  wss.on("connection", (ws, req) => {
    const url = new URL(req.url, `http://${req.headers.host}`);
    const userId = url.searchParams.get("userId");
    if (!userId) {
      ws.close(4000, "userId required");
      return;
    }

    registry.addConnection(userId, ws);

    ws.on("message", (raw) => {
      let payload;
      try {
        payload = JSON.parse(raw.toString());
      } catch {
        ws.send(JSON.stringify({ type: "error", reason: "invalid_json" }));
        return;
      }

      if (!payload.type) {
        ws.send(JSON.stringify({ type: "error", reason: "type_required" }));
        return;
      }

      if (payload.type === "ping") {
        ws.send(JSON.stringify({ type: "pong", at: new Date().toISOString() }));
        return;
      }

      if (payload.type === "message" && payload.recipientId) {
        const envelope = {
          type: "message",
          threadId: payload.threadId || "direct",
          senderId: userId,
          recipientId: payload.recipientId,
          body: payload.body || "",
          sentAt: new Date().toISOString(),
        };
        const delivered = registry.fanout(payload.recipientId, envelope);
        ws.send(JSON.stringify({ type: "ack", delivered }));
        return;
      }

      ws.send(JSON.stringify({ type: "error", reason: "unsupported_type" }));
    });

    ws.on("close", () => registry.removeConnection(userId, ws));
    ws.on("error", () => registry.removeConnection(userId, ws));
  });

  return { server, wss, registry };
}

if (require.main === module) {
  const { server } = createGatewayServer();
  server.listen(PORT, () => {
    // eslint-disable-next-line no-console
    console.log(`[ws-gateway] listening on :${PORT}`);
  });
}

module.exports = {
  createConnectionRegistry,
  createGatewayServer,
};
