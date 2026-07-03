"use strict";

const Redis = require("ioredis");

if (!process.env.REDIS_URL) {
  throw new Error("REDIS_URL env var is required");
}

const redis = new Redis(process.env.REDIS_URL);

const JTI_PREFIX = "ent:jti:";
const DEFAULT_TTL = Number.parseInt(process.env.JTI_TTL || "180", 10);

async function markJtiConsumed(jti, ttl = DEFAULT_TTL) {
  const key = JTI_PREFIX + jti;
  const set = await redis.set(key, "1", "EX", ttl, "NX");
  return set === "OK";
}

async function isJtiConsumed(jti) {
  const key = JTI_PREFIX + jti;
  const exists = await redis.exists(key);
  return exists === 1;
}

async function revokeJti(jti) {
  const key = JTI_PREFIX + jti;
  await redis.del(key);
}

async function close() {
  await redis.quit();
}

module.exports = { markJtiConsumed, isJtiConsumed, revokeJti, close, redis };
