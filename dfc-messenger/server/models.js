const mongoose = require("mongoose");
const { Schema } = mongoose;

const UserSchema = new Schema({
  uid: { type: String, unique: true },
  displayName: String,
  phone: String,
  lastSeen: Date,
});

const MessageSchema = new Schema({
  from: String,
  to: String,
  text: String,
  ts: { type: Date, default: Date.now },
  delivered: { type: Boolean, default: false },
  read: { type: Boolean, default: false },
  clientId: String,
  deleted: { type: Boolean, default: false },
});

const AuditLogSchema = new Schema({
  event: { type: String, required: true },
  payload: Schema.Types.Mixed,
  socketId: String,
  ts: { type: Date, default: Date.now },
});

module.exports = {
  User: mongoose.model("User", UserSchema),
  Message: mongoose.model("Message", MessageSchema),
  AuditLog: mongoose.model("AuditLog", AuditLogSchema),
};
