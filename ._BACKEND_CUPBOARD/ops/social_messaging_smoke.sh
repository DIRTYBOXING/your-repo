#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8080}"
WS_BASE="${WS_BASE:-ws://localhost:8799/ws/social}"
FEED_USER_ID="${FEED_USER_ID:-demo_user}"
CLIP_CDN_URL="${CLIP_CDN_URL:-}"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

echo "[1/4] Feed API contract smoke"
FEED_JSON="$(curl -fsS "$BASE_URL/api/users/$FEED_USER_ID/feed" || true)"
if [[ -z "$FEED_JSON" ]]; then
  fail "Feed endpoint unavailable at $BASE_URL/api/users/$FEED_USER_ID/feed"
fi

echo "$FEED_JSON" | jq -e '.userId and .items and .nextCursor' >/dev/null || fail "Feed payload contract mismatch"

echo "[2/4] Presence TTL smoke"
PRESENCE_JSON="$(curl -fsS "$BASE_URL/api/users/$FEED_USER_ID/presence" || true)"
if [[ -n "$PRESENCE_JSON" ]]; then
  echo "$PRESENCE_JSON" | jq -e '.expiresAt' >/dev/null || fail "Presence payload missing expiresAt"
else
  echo "SKIP: presence endpoint not exposed on BASE_URL"
fi

echo "[3/4] WebSocket connect and ping smoke"
node -e '
const { WebSocket } = require("ws");
const wsBase = process.env.WS_BASE;
const url = `${wsBase}?userId=smoke_sender`;
const ws = new WebSocket(url);
let done = false;
const timeout = setTimeout(() => {
  if (!done) {
    console.error("FAIL: websocket timeout");
    process.exit(1);
  }
}, 5000);
ws.onopen = () => ws.send(JSON.stringify({ type: "ping" }));
ws.onmessage = (ev) => {
  try {
    const payload = JSON.parse(ev.data.toString());
    if (payload.type === "pong") {
      done = true;
      clearTimeout(timeout);
      ws.close();
      process.exit(0);
    }
  } catch {}
};
ws.onerror = () => {
  console.error("FAIL: websocket connect error");
  process.exit(1);
};
' || fail "WebSocket smoke failed"

echo "[4/4] Clip CDN smoke"
if [[ -n "$CLIP_CDN_URL" ]]; then
  code="$(curl -sS -o /dev/null -w '%{http_code}' "$CLIP_CDN_URL" || true)"
  [[ "$code" == "200" ]] || fail "Clip CDN URL did not return 200"
else
  echo "SKIP: CLIP_CDN_URL not set"
fi

echo "Social messaging smoke passed"
