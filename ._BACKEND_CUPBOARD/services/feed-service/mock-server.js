import http from "node:http";

const PORT = Number.parseInt(process.env.SOCIAL_FEED_PORT || "8080", 10);

function json(res, code, payload) {
  res.statusCode = code;
  res.setHeader("content-type", "application/json");
  res.end(JSON.stringify(payload));
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);

  if (url.pathname === "/healthz") {
    return json(res, 200, { status: "ok" });
  }

  const feedMatch = /^\/api\/users\/([^/]+)\/feed$/.exec(url.pathname);
  if (feedMatch) {
    const userId = decodeURIComponent(feedMatch[1]);
    return json(res, 200, {
      userId,
      items: [
        {
          id: "clip_smoke_1",
          type: "clip",
          actorId: "creator_smoke",
          createdAt: new Date().toISOString(),
          payload: {
            title: "Smoke Clip",
            thumbnailUrl:
              process.env.CLIP_CDN_URL || "https://example.com/smoke-thumb.jpg",
          },
        },
      ],
      nextCursor: "",
    });
  }

  const presenceMatch = /^\/api\/users\/([^/]+)\/presence$/.exec(url.pathname);
  if (presenceMatch) {
    const userId = decodeURIComponent(presenceMatch[1]);
    return json(res, 200, {
      userId,
      state: "online",
      expiresAt: new Date(Date.now() + 30000).toISOString(),
    });
  }

  return json(res, 404, { error: "Not found" });
});

server.listen(PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`[feed-service/mock] listening on :${PORT}`);
});
