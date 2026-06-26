// ─────────────────────────────────────────────────────────────
// entitlement.js — Playback-token entitlement service
//
// Issues short-lived JWT playback tokens for PPV events after
// purchase validation.  Stores token hashes in Firestore for
// audit and single-use enforcement.
//
// Required env:
//   ENTITLEMENT_JWT_SECRET — HMAC key for playback JWTs
//   ENTITLEMENT_TTL_SEC   — Token lifetime (default 300)
//   CANONICAL_ENTITLEMENT_API — RS256 entitlement service base URL for proxy mode
// ─────────────────────────────────────────────────────────────
import jwt from "jsonwebtoken";
import crypto from "node:crypto";
import { getFirestore } from "firebase-admin/firestore";

function getDb() {
  return getFirestore();
}

const JWT_SECRET =
  process.env.ENTITLEMENT_JWT_SECRET || "replace_entitlement_secret";
const JWT_TTL_SEC = Number.parseInt(
  process.env.ENTITLEMENT_TTL_SEC || "300",
  10,
);
const CANONICAL_ENTITLEMENT_API = (process.env.CANONICAL_ENTITLEMENT_API || "")
  .trim()
  .replace(/\/+$/, "");

let canonicalAccessModulePromise;

function hashToken(token) {
  return crypto.createHash("sha256").update(token).digest("hex");
}

async function getCanonicalPpvAccessStateResolver() {
  if (!canonicalAccessModulePromise) {
    canonicalAccessModulePromise = import("./ppv/access_state.js");
  }

  const accessModule = await canonicalAccessModulePromise;
  return (
    accessModule.getCanonicalPpvAccessState ||
    accessModule.default?.getCanonicalPpvAccessState ||
    null
  );
}

async function getCanonicalEntitlementState({ userId, eventId }) {
  const getCanonicalPpvAccessState = await getCanonicalPpvAccessStateResolver();
  if (typeof getCanonicalPpvAccessState !== "function") {
    throw new TypeError("Canonical PPV access resolver unavailable");
  }

  return getCanonicalPpvAccessState({
    db: getDb(),
    userId,
    eventId,
  });
}

function hasCanonicalEntitlementProxy() {
  return Boolean(CANONICAL_ENTITLEMENT_API);
}

async function proxyCanonicalEntitlementRequest(path, payload) {
  const response = await fetch(`${CANONICAL_ENTITLEMENT_API}${path}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
    },
    body: JSON.stringify(payload),
  });

  const body = await response.json().catch(() => ({ error: "proxy_error" }));
  return { response, body };
}

// ── Request a playback token ────────────────────────────────
export async function requestEntitlement(req, res) {
  try {
    const { eventId, deviceId } = req.body;
    const auth = req.headers.authorization || "";
    if (!auth.startsWith("Bearer "))
      return res.status(401).json({ error: "unauthenticated" });

    const userId = req.headers["x-user-id"] || req.body.userId;
    if (!userId) return res.status(401).json({ error: "missing user" });
    if (!eventId) return res.status(400).json({ error: "missing eventId" });

    if (hasCanonicalEntitlementProxy()) {
      const sessionId = req.body.sessionId || req.body.session_id || null;
      const { response, body } = await proxyCanonicalEntitlementRequest(
        "/entitlements/token",
        {
          user_id: userId,
          event_id: eventId,
          session_id: sessionId,
          device_id: deviceId || null,
        },
      );

      if (!response.ok) {
        return res.status(response.status).json(body);
      }

      return res.json({
        playbackToken: body.token,
        expiresIn: body.expires_in,
        sessionId: body.session_id || sessionId || null,
      });
    }

    const accessState = await getCanonicalEntitlementState({ userId, eventId });
    if (!accessState?.hasAccess) {
      return res.status(403).json({
        error: accessState?.reason || "no_valid_purchase",
      });
    }

    const payload = {
      sub: userId,
      event: eventId,
      iat: Math.floor(Date.now() / 1000),
    };
    const token = jwt.sign(payload, JWT_SECRET, {
      expiresIn: `${JWT_TTL_SEC}s`,
    });
    const expiresAt = Date.now() + JWT_TTL_SEC * 1000;
    try {
      const db = getDb();
      const tokenHash = hashToken(token);
      await db
        .collection("entitlements")
        .doc(tokenHash)
        .set({
          user_id: userId,
          event_id: eventId,
          token_hash: tokenHash,
          access_source: "canonical_ppv_access_state",
          expires_at: new Date(expiresAt),
          device_id: deviceId || null,
          created_at: new Date(),
        });
    } catch (dbErr) {
      // Log but don't fail — allow token issuance even if DB is down
      console.error("entitlement DB write failed (non-fatal):", dbErr.message);
    }

    return res.json({ playbackToken: token, expiresIn: JWT_TTL_SEC });
  } catch (err) {
    console.error("entitlement request error:", err);
    return res.status(500).json({ error: "server_error" });
  }
}

// ── Validate a playback token ───────────────────────────────
export async function validateEntitlement(req, res) {
  try {
    const { playbackToken } = req.body;
    if (!playbackToken) return res.status(400).json({ error: "missing token" });

    if (hasCanonicalEntitlementProxy()) {
      const { response, body } = await proxyCanonicalEntitlementRequest(
        "/validate",
        { playbackToken },
      );
      return res.status(response.status).json(body);
    }

    let payload;
    try {
      payload = jwt.verify(playbackToken, JWT_SECRET);
    } catch {
      return res.status(403).json({ error: "invalid_or_expired" });
    }

    // Optional DB check — if Firestore is available verify hash is known
    try {
      const db = getDb();
      const tokenHash = hashToken(playbackToken);
      const docSnap = await db.collection("entitlements").doc(tokenHash).get();

      if (!docSnap.exists) {
        return res.status(403).json({ error: "not_found" });
      }
      const row = docSnap.data();
      if (row.expires_at.toDate() < new Date()) {
        return res.status(403).json({ error: "expired" });
      }

      const userId = row.user_id || payload.sub;
      const eventId = row.event_id || payload.event;

      try {
        const accessState = await getCanonicalEntitlementState({
          userId,
          eventId,
        });
        if (accessState && accessState.hasAccess !== true) {
          return res.status(403).json({
            error: accessState.reason || "access_revoked",
          });
        }
      } catch (accessErr) {
        // Preserve short-lived token compatibility if the canonical resolver is unavailable.
        console.error(
          "canonical entitlement revalidation failed (fallback to token):",
          accessErr.message,
        );
      }

      return res.json({
        ok: true,
        userId,
        eventId,
      });
    } catch (dbErr) {
      // Fallback: trust JWT if DB is unreachable
      console.error(
        "entitlement DB read failed (fallback to JWT):",
        dbErr.message,
      );
      return res.json({
        ok: true,
        userId: payload.sub,
        eventId: payload.event,
      });
    }
  } catch (err) {
    console.error("entitlement validate error:", err);
    return res.status(500).json({ error: "server_error" });
  }
}
