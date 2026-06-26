const WS_URL =
  process.env.REACT_APP_WS ||
  (window.location.protocol === "https:" ? "wss://" : "ws://") +
    window.location.host +
    "/ws/telemetry";
let ws;

export default {
  connect() {
    ws = new WebSocket(WS_URL);
    ws.onopen = () => console.log("ws open");
    ws.onmessage = (ev) => {
      try {
        const msg = JSON.parse(ev.data);
        window.dispatchEvent(new CustomEvent("ws-msg", { detail: msg }));
      } catch (e) {
        console.error(e);
      }
    };
    ws.onclose = () => setTimeout(() => this.connect(), 2000);
  },
  disconnect() {
    if (ws) ws.close();
  },
};
