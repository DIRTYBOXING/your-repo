const WebSocket = require("ws");

let wss;
function init(server) {
  wss = new WebSocket.Server({ server });
  wss.on("connection", (socket) => {
    socket.on("message", (msg) => {
      try {
        const m = JSON.parse(msg);
        // handle incoming control messages if needed
      } catch (e) {
        console.error(e);
      }
    });
  });
  console.log("WebSocket server initialized");
}

function broadcast(msg) {
  if (!wss) return;
  const s = JSON.stringify(msg);
  wss.clients.forEach((c) => {
    if (c.readyState === WebSocket.OPEN) c.send(s);
  });
}

module.exports = { init, broadcast };
