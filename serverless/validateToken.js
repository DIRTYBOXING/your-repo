/**
 * DFC Serverless — Token Validation (Edge Function)
 * Validates entitlement JWT tokens at the CDN edge.
 */
"use strict";

const jwt = require("jsonwebtoken");

let redis;
function getRedis() {
  if (!redis) {
    const IORedis = require("ioredis");
    redis = new IORedis(process.env.REDIS_URL || "redis://localhost:6379", {
      maxRetriesPerRequest: 1,
      connectTimeout: 800,
      lazyConnect: true,
    });
  }
  return redis;
}

async function tryGet(key) {
  try {
    const r = getRedis();
    await r.connect().catch(() => {});
    return await r.get(key);
  } catch {
    return null;
  }
}

exports.handler = async (event) => {
  try {
    const body = JSON.parse(event.body || "{}");
    const { token, deviceId } = body;

    if (!token || !deviceId) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "token, deviceId required" }),
      };
    }

    let payload;
    try {
      payload = jwt.verify(
        token,
        process.env.ENT_SECRET || "dfc-local-dev-secret",
        {
          issuer: "dfc-entitlements",
        },
      );
    } catch (jwtErr) {
      return {
        statusCode: 401,
        body: JSON.stringify({
          error: "invalid_token",
          reason: jwtErr.message,
        }),
      };
    }

    if (payload.did !== deviceId) {
      return {
        statusCode: 403,
        body: JSON.stringify({ error: "device_mismatch" }),
      };
    }

    const revoked = payload.jti
      ? await tryGet(`ent:revoked:${payload.jti}`)
      : null;
    if (revoked) {
      return {
        statusCode: 403,
        body: JSON.stringify({ error: "token_revoked" }),
      };
    }

    const meta = payload.jti ? await tryGet(`ent:tok:${payload.jti}`) : null;

    return {
      statusCode: 200,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        valid: true,
        userId: payload.sub,
        postId: payload.pid,
        tier: payload.tier,
        persisted: !!meta,
        expiresAt: new Date(payload.exp * 1000).toISOString(),
      }),
    };
  } catch (err) {
    console.error("validateToken error:", err);
    return { statusCode: 500, body: JSON.stringify({ error: "internal" }) };
  }
};
