import React, { useEffect, useState, useRef, useCallback } from "react";
import { socket } from "./socket";
import { enqueue, dequeue, flushQueue } from "./offlineQueue";

/* ─── DFC Design Tokens ──────────────────────────────────────────────── */
const T = {
  bg: "#050A14",
  bgCard: "#0D1B2A",
  bgInput: "#0A1628",
  cyan: "#00F5FF",
  magenta: "#FF00FF",
  green: "#00FF88",
  amber: "#FFB800",
  red: "#FF3366",
  gold: "#FFD700",
  text: "#FFFFFF",
  textSec: "rgba(255,255,255,0.7)",
  textMute: "rgba(255,255,255,0.4)",
  border: "rgba(255,255,255,0.08)",
  glow: (c, a = 0.25) =>
    `0 0 20px ${c}${Math.round(a * 255)
      .toString(16)
      .padStart(2, "0")}`,
};

/* ─── Styles ─────────────────────────────────────────────────────────── */
const S = {
  app: {
    display: "flex",
    flexDirection: "column",
    height: "100vh",
    maxWidth: 520,
    margin: "0 auto",
    background: T.bg,
    position: "relative",
    overflow: "hidden",
  },
  header: {
    display: "flex",
    alignItems: "center",
    gap: 12,
    padding: "16px 20px",
    borderBottom: `1px solid ${T.border}`,
    background:
      "linear-gradient(180deg, rgba(0,245,255,0.04) 0%, transparent 100%)",
    flexShrink: 0,
  },
  logo: {
    fontWeight: 900,
    fontSize: 18,
    letterSpacing: 3,
    background: `linear-gradient(135deg, ${T.cyan}, ${T.magenta})`,
    WebkitBackgroundClip: "text",
    WebkitTextFillColor: "transparent",
  },
  status: {
    fontSize: 10,
    fontWeight: 600,
    padding: "3px 10px",
    borderRadius: 10,
    marginLeft: "auto",
  },
  peerBar: {
    display: "flex",
    alignItems: "center",
    gap: 10,
    padding: "10px 20px",
    background: "rgba(255,255,255,0.02)",
    borderBottom: `1px solid ${T.border}`,
    flexShrink: 0,
  },
  avatar: (color) => ({
    width: 32,
    height: 32,
    borderRadius: "50%",
    flexShrink: 0,
    background: `linear-gradient(135deg, ${T.cyan}, ${color || T.magenta})`,
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    fontSize: 13,
    fontWeight: 900,
    color: "#000",
  }),
  messages: {
    flex: 1,
    overflowY: "auto",
    padding: "12px 16px",
    display: "flex",
    flexDirection: "column",
    gap: 4,
  },
  bubbleWrap: (isMe) => ({
    display: "flex",
    justifyContent: isMe ? "flex-end" : "flex-start",
    width: "100%",
  }),
  bubble: (isMe) => ({
    maxWidth: "75%",
    padding: "10px 14px",
    background: isMe ? `rgba(0,245,255,0.1)` : "rgba(255,255,255,0.04)",
    border: `1px solid ${isMe ? "rgba(0,245,255,0.2)" : T.border}`,
    borderRadius: isMe ? "16px 16px 4px 16px" : "16px 16px 16px 4px",
    position: "relative",
  }),
  bubbleSender: {
    fontSize: 10,
    fontWeight: 800,
    marginBottom: 3,
    color: `${T.magenta}b3`,
  },
  bubbleText: { fontSize: 14, lineHeight: 1.5, color: T.text },
  bubbleTime: {
    fontSize: 9,
    marginTop: 4,
    color: T.textMute,
    textAlign: "right",
  },
  inputArea: {
    display: "flex",
    alignItems: "center",
    gap: 10,
    padding: "12px 16px 16px",
    background: T.bg,
    borderTop: `1px solid ${T.border}`,
    flexShrink: 0,
  },
  input: {
    flex: 1,
    padding: "10px 16px",
    fontSize: 14,
    background: "rgba(255,255,255,0.04)",
    border: `1px solid rgba(0,245,255,0.12)`,
    borderRadius: 24,
    color: T.text,
    outline: "none",
    transition: "border-color 0.2s",
  },
  sendBtn: {
    padding: "10px 20px",
    fontSize: 13,
    fontWeight: 700,
    background: T.cyan,
    color: "#000",
    border: "none",
    borderRadius: 22,
    cursor: "pointer",
    transition: "box-shadow 0.2s, transform 0.1s",
  },
  empty: {
    flex: 1,
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center",
    gap: 12,
    color: T.textMute,
    padding: 32,
  },
  onboard: {
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center",
    height: "100vh",
    gap: 20,
    padding: 32,
    background: T.bg,
  },
  onboardInput: {
    padding: "14px 20px",
    fontSize: 16,
    width: "100%",
    maxWidth: 300,
    background: T.bgCard,
    border: `1px solid rgba(0,245,255,0.2)`,
    borderRadius: 14,
    color: T.text,
    outline: "none",
    textAlign: "center",
  },
  peerInput: {
    flex: 1,
    padding: "8px 14px",
    fontSize: 13,
    background: T.bgInput,
    border: `1px solid rgba(0,245,255,0.12)`,
    borderRadius: 12,
    color: T.text,
    outline: "none",
  },
  peerBtn: {
    padding: "8px 16px",
    fontSize: 12,
    fontWeight: 700,
    background: T.magenta,
    color: "#fff",
    border: "none",
    borderRadius: 12,
    cursor: "pointer",
  },
};

function App() {
  const [me, setMe] = useState(localStorage.getItem("dfc_me") || "");
  const [displayName, setDisplayName] = useState(
    localStorage.getItem("dfc_name") || "",
  );
  const [peerId, setPeerId] = useState("");
  const [activePeer, setActivePeer] = useState(null);
  const [msgs, setMsgs] = useState([]);
  const [text, setText] = useState("");
  const [connected, setConnected] = useState(false);
  const [nameInput, setNameInput] = useState("");
  const [peerInput, setPeerInput] = useState("");
  const endRef = useRef(null);

  // Auto-scroll to bottom
  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [msgs]);

  // Socket setup
  useEffect(() => {
    if (!me) return;
    socket.connect();
    socket.emit("join", me);

    socket.on("connect", () => setConnected(true));
    socket.on("disconnect", () => setConnected(false));

    socket.on("receive_message", (m) => setMsgs((s) => [...s, m]));
    socket.on("message_sent", async (ack) => {
      setMsgs((s) =>
        s.map((x) =>
          x.clientId === ack.clientId
            ? { ...x, _id: ack._id, ts: ack.ts, pending: false }
            : x,
        ),
      );
      await dequeue(ack.clientId);
    });

    const onOnline = async () => {
      await flushQueue(async (m) => socket.emit("send_message", m));
    };
    window.addEventListener("online", onOnline);

    return () => {
      window.removeEventListener("online", onOnline);
      socket.off("connect");
      socket.off("disconnect");
      socket.off("receive_message");
      socket.off("message_sent");
      socket.disconnect();
    };
  }, [me]);

  const handleJoin = useCallback(() => {
    const name = nameInput.trim();
    if (!name) return;
    const uid =
      name.toLowerCase().replace(/\s+/g, "_") +
      "_" +
      Date.now().toString(36).slice(-4);
    localStorage.setItem("dfc_me", uid);
    localStorage.setItem("dfc_name", name);
    setMe(uid);
    setDisplayName(name);
  }, [nameInput]);

  const startChat = useCallback(() => {
    const id = peerInput.trim();
    if (!id || id === me) return;
    setPeerId(id);
    setActivePeer(id);
    setMsgs([]);
  }, [peerInput, me]);

  const send = useCallback(async () => {
    const trimmed = text.trim();
    if (!trimmed || !peerId) return;
    const clientId =
      Date.now().toString() + Math.random().toString(36).slice(2, 8);
    const payload = { to: peerId, from: me, text: trimmed, clientId };
    setMsgs((s) => [...s, { ...payload, ts: Date.now(), pending: true }]);
    if (!navigator.onLine || !socket.connected) {
      await enqueue(payload);
    } else {
      socket.emit("send_message", payload);
    }
    setText("");
  }, [text, peerId, me]);

  const fmtTime = (ts) => {
    if (!ts) return "";
    const d = new Date(ts);
    return d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  };

  // Onboarding — no ugly prompt()
  if (!me) {
    return (
      <div style={S.onboard}>
        <div style={{ ...S.logo, fontSize: 28, marginBottom: 4 }}>
          DFC MESSENGER
        </div>
        <div
          style={{
            color: T.textSec,
            fontSize: 13,
            textAlign: "center",
            maxWidth: 280,
          }}
        >
          Real-time messaging for the fight community. Enter your name to begin.
        </div>
        <input
          style={S.onboardInput}
          placeholder="Your name"
          value={nameInput}
          onChange={(e) => setNameInput(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && handleJoin()}
          autoFocus
        />
        <button
          onClick={handleJoin}
          style={{
            ...S.sendBtn,
            padding: "12px 40px",
            fontSize: 15,
            opacity: nameInput.trim() ? 1 : 0.4,
            boxShadow: nameInput.trim() ? T.glow(T.cyan, 0.3) : "none",
          }}
        >
          ENTER
        </button>
      </div>
    );
  }

  return (
    <div style={S.app}>
      {/* ── Header ───────────────────────────────────────────────── */}
      <div style={S.header}>
        <div style={S.logo}>DFC</div>
        <div style={{ fontSize: 12, color: T.textSec, fontWeight: 600 }}>
          MESSENGER
        </div>
        <div
          style={{
            ...S.status,
            background: connected
              ? `rgba(0,255,136,0.15)`
              : `rgba(255,51,102,0.15)`,
            color: connected ? T.green : T.red,
          }}
        >
          {connected ? "● LIVE" : "○ OFFLINE"}
        </div>
      </div>

      {/* ── Peer selector ────────────────────────────────────────── */}
      <div style={S.peerBar}>
        <div style={S.avatar(T.magenta)}>
          {displayName?.[0]?.toUpperCase() || "?"}
        </div>
        <input
          style={S.peerInput}
          placeholder="Enter user ID to message..."
          value={peerInput}
          onChange={(e) => setPeerInput(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && startChat()}
        />
        <button
          onClick={startChat}
          disabled={!peerInput.trim()}
          style={{
            ...S.peerBtn,
            opacity: peerInput.trim() ? 1 : 0.4,
          }}
        >
          CHAT
        </button>
      </div>

      {/* ── Messages ─────────────────────────────────────────────── */}
      {!activePeer ? (
        <div style={S.empty}>
          <div style={{ fontSize: 40, opacity: 0.2 }}>💬</div>
          <div
            style={{
              fontWeight: 700,
              fontSize: 15,
              color: "rgba(255,255,255,0.25)",
            }}
          >
            No active conversation
          </div>
          <div style={{ fontSize: 12, textAlign: "center", maxWidth: 240 }}>
            Enter a user ID above to start messaging.
          </div>
        </div>
      ) : (
        <>
          <div style={S.messages}>
            {msgs.length === 0 && (
              <div
                style={{ ...S.empty, padding: 0, flex: "none", marginTop: 60 }}
              >
                <div style={{ fontSize: 36, opacity: 0.15 }}>👋</div>
                <div
                  style={{
                    fontWeight: 600,
                    fontSize: 14,
                    color: "rgba(255,255,255,0.2)",
                  }}
                >
                  Say hello to {activePeer}
                </div>
              </div>
            )}
            {msgs.map((m, i) => {
              const isMe = m.from === me;
              return (
                <div key={m.clientId || m._id || i} style={S.bubbleWrap(isMe)}>
                  <div style={S.bubble(isMe)}>
                    {!isMe && <div style={S.bubbleSender}>{m.from}</div>}
                    <div style={S.bubbleText}>{m.text}</div>
                    <div style={S.bubbleTime}>
                      {m.pending ? (
                        <span style={{ color: T.amber }}>Sending…</span>
                      ) : (
                        fmtTime(m.ts)
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
            <div ref={endRef} />
          </div>

          {/* ── Input bar ────────────────────────────────────────── */}
          <div style={S.inputArea}>
            <input
              style={S.input}
              value={text}
              onChange={(e) => setText(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && !e.shiftKey && send()}
              placeholder="Type a message..."
              onFocus={(e) => {
                e.target.style.borderColor = `${T.cyan}40`;
              }}
              onBlur={(e) => {
                e.target.style.borderColor = "rgba(0,245,255,0.12)";
              }}
            />
            <button
              onClick={send}
              disabled={!text.trim()}
              style={{
                ...S.sendBtn,
                opacity: text.trim() ? 1 : 0.4,
                boxShadow: text.trim() ? T.glow(T.cyan, 0.2) : "none",
              }}
              onMouseDown={(e) => {
                e.target.style.transform = "scale(0.95)";
              }}
              onMouseUp={(e) => {
                e.target.style.transform = "scale(1)";
              }}
              onMouseLeave={(e) => {
                e.target.style.transform = "scale(1)";
              }}
            >
              SEND ➤
            </button>
          </div>
        </>
      )}
    </div>
  );
}

export default App;
