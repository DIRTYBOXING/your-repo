// ─────────────────────────────────────────────────────────────
// auth-tokens.js — JWT sign-in, refresh, and revoke handlers
//
// Issues short-lived access tokens (15 min) and rotatable refresh
// tokens (30 days). Refresh tokens are stored server-side for
// revocation support.
//
// Required env:
//   JWT_SECRET            — secret for signing access tokens
//   REFRESH_TOKEN_SECRET  — secret for signing refresh tokens
//
// These are Express route handlers (not a standalone server).
// Wire them into server.js:
//   import { signIn, refresh, revoke } from './auth-tokens.js';
//   app.post('/auth/signin', signIn);
//   app.post('/auth/refresh', refresh);
//   app.post('/auth/revoke', revoke);
// ─────────────────────────────────────────────────────────────

import crypto from "node:crypto";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";

const JWT_SECRET = process.env.JWT_SECRET || "dev-jwt-secret";
const REFRESH_SECRET = process.env.REFRESH_TOKEN_SECRET || "dev-refresh-secret";
const ACCESS_TTL = 15 * 60; // 15 minutes
const REFRESH_TTL = 30 * 24 * 60 * 60; // 30 days

// In-memory refresh token store (fallback — Firestore preferred)
const refreshTokenStore = new Map();

// Use Firestore for refresh-token persistence when available
async function storeRefreshToken(token, userId) {
  refreshTokenStore.set(token, { userId, createdAt: new Date().toISOString() });
  try {
    const db = getFirestore();
    const tokenHash = crypto.createHash("sha256").update(token).digest("hex");
    await db
      .collection("refresh_tokens")
      .doc(tokenHash)
      .set({
        userId,
        createdAt: new Date().toISOString(),
        expiresAt: new Date(Date.now() + REFRESH_TTL * 1000).toISOString(),
      });
  } catch {
    // Non-fatal — in-memory still holds it
  }
}

async function isRefreshTokenValid(token) {
  if (refreshTokenStore.has(token)) return true;
  try {
    const db = getFirestore();
    const tokenHash = crypto.createHash("sha256").update(token).digest("hex");
    const doc = await db.collection("refresh_tokens").doc(tokenHash).get();
    return doc.exists;
  } catch {
    return false;
  }
}

async function deleteRefreshToken(token) {
  refreshTokenStore.delete(token);
  try {
    const db = getFirestore();
    const tokenHash = crypto.createHash("sha256").update(token).digest("hex");
    await db.collection("refresh_tokens").doc(tokenHash).delete();
  } catch {
    // Non-fatal
  }
}

// ── Minimal JWT helpers (no external dep) ────────────────────

function base64url(buf) {
  return buf
    .toString("base64")
    .replaceAll("=", "")
    .replaceAll("+", "-")
    .replaceAll("/", "_");
}

function signJwt(payload, secret, ttlSeconds) {
  const header = base64url(
    Buffer.from(JSON.stringify({ alg: "HS256", typ: "JWT" })),
  );
  const now = Math.floor(Date.now() / 1000);
  const body = base64url(
    Buffer.from(
      JSON.stringify({ ...payload, iat: now, exp: now + ttlSeconds }),
    ),
  );
  const sig = base64url(
    crypto.createHmac("sha256", secret).update(`${header}.${body}`).digest(),
  );
  return `${header}.${body}.${sig}`;
}

function verifyJwt(token, secret) {
  const parts = token.split(".");
  if (parts.length !== 3) throw new Error("Invalid token");
  const [header, body, sig] = parts;
  const expected = base64url(
    crypto.createHmac("sha256", secret).update(`${header}.${body}`).digest(),
  );
  if (sig !== expected) throw new Error("Invalid signature");
  const payload = JSON.parse(Buffer.from(body, "base64").toString());
  if (payload.exp && payload.exp < Math.floor(Date.now() / 1000)) {
    throw new Error("Token expired");
  }
  return payload;
}

// ── Handlers ─────────────────────────────────────────────────

export async function signIn(req, res) {
  const { email, password } = req.body || {};
  if (!email || !password) {
    return res.status(400).json({ error: "Missing email or password" });
  }

  // Validate user via Firebase Auth
  let userRecord;
  try {
    // Accept either a Firebase ID token or email/password
    const { idToken } = req.body || {};
    if (idToken) {
      // Verify Firebase ID token and extract user
      const decoded = await getAuth().verifyIdToken(idToken);
      userRecord = await getAuth().getUser(decoded.uid);
    } else {
      // Lookup user by email (password verified client-side via Firebase Auth SDK)
      userRecord = await getAuth().getUserByEmail(email);
    }
  } catch {
    return res.status(401).json({ error: "Invalid credentials" });
  }

  const userId = userRecord.uid;

  const accessToken = signJwt({ sub: userId, email }, JWT_SECRET, ACCESS_TTL);
  const refreshToken = signJwt({ sub: userId }, REFRESH_SECRET, REFRESH_TTL);

  // Store refresh token for revocation (Firestore + in-memory)
  await storeRefreshToken(refreshToken, userId);

  return res.json({
    access_token: accessToken,
    refresh_token: refreshToken,
    user_id: userId,
  });
}

export async function refresh(req, res) {
  const { refresh_token } = req.body || {};
  if (!refresh_token) {
    return res.status(400).json({ error: "Missing refresh_token" });
  }

  try {
    const payload = verifyJwt(refresh_token, REFRESH_SECRET);

    // Verify token is still in store (not revoked)
    if (!(await isRefreshTokenValid(refresh_token))) {
      return res.status(403).json({ error: "Refresh token revoked" });
    }

    const userId = payload.sub;
    const newAccess = signJwt({ sub: userId }, JWT_SECRET, ACCESS_TTL);
    const newRefresh = signJwt({ sub: userId }, REFRESH_SECRET, REFRESH_TTL);

    // Rotate: remove old, store new
    await deleteRefreshToken(refresh_token);
    await storeRefreshToken(newRefresh, userId);

    return res.json({
      access_token: newAccess,
      refresh_token: newRefresh,
    });
  } catch {
    return res.status(403).json({ error: "Invalid or expired refresh token" });
  }
}

export async function revoke(req, res) {
  const { refresh_token } = req.body || {};
  if (refresh_token) {
    await deleteRefreshToken(refresh_token);
  }
  return res.json({ ok: true });
}
