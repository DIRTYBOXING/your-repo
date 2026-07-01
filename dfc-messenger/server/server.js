require("dotenv").config();
const express = require("express");
const http = require("http");
const cors = require("cors");
const mongoose = require("mongoose");
const { Server } = require("socket.io");
const { User, Message, AuditLog } = require("./models");

const app = express();
app.use(cors());
app.use(express.json());

const MONGO_URI = process.env.MONGO_URI || "mongodb://localhost:27017/dfc";
mongoose
  .connect(MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(() => console.log("Mongo connected"))
  .catch((err) => console.error("Mongo error", err));

app.post("/register", async (req, res) => {
  const { uid, displayName, phone } = req.body;
  try {
    const u = await User.findOneAndUpdate(
      { uid },
      { displayName, phone, lastSeen: new Date() },
      { upsert: true, new: true },
    );
    res.json(u);
  } catch (err) {
    res.status(500).json({ error: "register failed" });
  }
});

app.get("/messages/:userId/:peerId", async (req, res) => {
  const { userId, peerId } = req.params;
  try {
    const msgs = await Message.find({
      deleted: { $ne: true },
      $or: [
        { from: userId, to: peerId },
        { from: peerId, to: userId },
      ],
    })
      .sort("ts")
      .limit(200);
    res.json(msgs);
  } catch (err) {
    res.status(500).json({ error: "fetch messages failed" });
  }
});

// Soft-delete a message
app.patch("/messages/:messageId/delete", async (req, res) => {
  try {
    const m = await Message.findByIdAndUpdate(
      req.params.messageId,
      { deleted: true },
      { new: true },
    );
    if (!m) return res.status(404).json({ error: "message not found" });
    res.json({ ok: true, message: m });
  } catch (err) {
    res.status(500).json({ error: "soft-delete failed" });
  }
});

// Restore a soft-deleted message
app.patch("/messages/:messageId/restore", async (req, res) => {
  try {
    const m = await Message.findByIdAndUpdate(
      req.params.messageId,
      { deleted: false },
      { new: true },
    );
    if (!m) return res.status(404).json({ error: "message not found" });
    res.json({ ok: true, message: m });
  } catch (err) {
    res.status(500).json({ error: "restore failed" });
  }
});

const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

io.on("connection", (socket) => {
  console.log("socket connected", socket.id);

  socket.on("join", async (uid) => {
    socket.join(uid);
    try {
      await User.findOneAndUpdate({ uid }, { lastSeen: new Date() });
    } catch (e) {
      /* ignore */
    }
  });

  socket.on("send_message", async (payload) => {
    const { to, from, text, clientId } = payload;
    if (!to || !from || !clientId) return;

    // Audit log: persist raw payload before processing
    try {
      await AuditLog.create({
        event: "send_message",
        payload: { to, from, text, clientId },
        socketId: socket.id,
      });
    } catch (e) {
      /* audit failure is non-blocking */
    }

    try {
      const exists = await Message.findOne({ clientId });
      if (exists) {
        // Dedupe — still ack so client can clear its queue
        socket.emit("message_sent", {
          clientId,
          _id: exists._id,
          ts: exists.ts,
        });
        return;
      }
      const m = await Message.create({ from, to, text, clientId });
      io.to(to).emit("receive_message", {
        from,
        text,
        ts: m.ts,
        clientId,
        _id: m._id,
      });
      socket.emit("message_sent", { clientId, _id: m._id, ts: m.ts });
    } catch (err) {
      console.error("send_message error", err);
    }
  });

  socket.on("delivered", async ({ messageId }) => {
    if (!messageId) return;
    try {
      await Message.findByIdAndUpdate(messageId, { delivered: true });
    } catch (e) {
      /* ignore */
    }
  });

  socket.on("read", async ({ messageId }) => {
    if (!messageId) return;
    try {
      await Message.findByIdAndUpdate(messageId, { read: true });
    } catch (e) {
      /* ignore */
    }
  });
});

const PORT = process.env.PORT || 3001;
server.listen(PORT, () => console.log("Server listening on", PORT));
