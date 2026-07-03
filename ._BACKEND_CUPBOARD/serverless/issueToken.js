const crypto = require("crypto");
const jwt = require("jsonwebtoken");
const IORedis = require("ioredis");

let redis;

function getRedis() {
  if (!redis) {
    redis = new IORedis(process.env.REDIS_URL || "redis://localhost:6379", {
      maxRetriesPerRequest: 1,
      connectTimeout: 800,
      lazyConnect: true,
    });
  }
  return redis;
}

async function tryPersistToken(jti, payload, ttl) {
  try {
    const r = getRedis();
    await r.connect().catch(() => {});
    await r.set(`ent:tok:${jti}`, JSON.stringify(payload), "EX", ttl);
    return true;
  } catch {
    return false;
  }
}

exports.handler = async (event) => {
  try {
    const body = JSON.parse(event.body || "{}");
    const { userId, postId, deviceId, ttl = 3600 } = body;

    if (!userId || !postId || !deviceId) {
      return { statusCode: 400, body: JSON.stringify({ error: "missing" }) };
    }

    const secret = process.env.ENT_SECRET || "dfc-local-dev-secret";
    const safeTtl = Number.isFinite(ttl) ? Math.max(60, Math.floor(ttl)) : 3600;
    const jti = crypto.randomUUID();

    const token = jwt.sign(
      {
        sub: userId,
        pid: postId,
        did: deviceId,
        jti,
        tier: "basic",
      },
      secret,
      {
        expiresIn: safeTtl,
        issuer: "dfc-entitlements",
      },
    );

    const persisted = await tryPersistToken(
      jti,
      { userId, postId, deviceId },
      safeTtl,
    );

    return {
      statusCode: 200,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ token, expiresIn: safeTtl, persisted }),
    };
  } catch (err) {
    return { statusCode: 500, body: JSON.stringify({ error: err.message }) };
  }
};
