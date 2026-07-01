import ws from "k6/experimental/websockets";
import { check, sleep } from "k6";

export const options = {
  vus: Number(__ENV.VUS || 25),
  duration: __ENV.DURATION || "30s",
};

const WS_BASE = __ENV.WS_BASE || "ws://localhost:8799/ws/social";

export default function signalingStorm() {
  const userId = `vu_${__VU}_${Date.now()}`;
  const url = `${WS_BASE}?userId=${userId}`;

  const socket = new ws.WebSocket(url);

  socket.onopen = () => {
    socket.send(JSON.stringify({ type: "ping" }));
    socket.send(
      JSON.stringify({
        type: "message",
        recipientId: userId,
        threadId: "storm",
        body: "signal-test",
      }),
    );
  };

  socket.onmessage = (event) => {
    check(event, {
      "received websocket data": (e) => Boolean(e?.data),
    });
  };

  socket.onerror = () => {
    check(false, {
      "websocket errors absent": () => false,
    });
  };

  sleep(1);
  socket.close();
}
