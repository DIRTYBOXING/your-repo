const crypto = require("node:crypto");

function decodeBase64Url(input) {
  const normalized = input.replaceAll("-", "+").replaceAll("_", "/");
  const padded = normalized + "=".repeat((4 - (normalized.length % 4)) % 4);
  return Buffer.from(padded, "base64");
}

function encodeBase64Url(buffer) {
  return buffer.toString("base64").replaceAll("=", "").replaceAll("+", "-").replaceAll("/", "_");
}

function parseJsonBuffer(buffer) {
  try {
    return JSON.parse(buffer.toString("utf8"));
  } catch {
    return null;
  }
}

function timingSafeEqualStrings(left, right) {
  const leftBuffer = Buffer.from(String(left));
  const rightBuffer = Buffer.from(String(right));
  if (leftBuffer.length !== rightBuffer.length) {
    return false;
  }
  return crypto.timingSafeEqual(leftBuffer, rightBuffer);
}

function verifyHs256Jwt(token, secret) {
  const parts = String(token || "").split(".");
  if (parts.length !== 3) {
    return null;
  }

  const [encodedHeader, encodedPayload, signature] = parts;
  const header = parseJsonBuffer(decodeBase64Url(encodedHeader));
  const payload = parseJsonBuffer(decodeBase64Url(encodedPayload));
  if (!header || !payload || header.alg !== "HS256") {
    return null;
  }

  const signed = `${encodedHeader}.${encodedPayload}`;
  const expectedSignature = encodeBase64Url(
    crypto.createHmac("sha256", secret).update(signed).digest(),
  );

  if (!timingSafeEqualStrings(signature, expectedSignature)) {
    return null;
  }

  const now = Math.floor(Date.now() / 1000);
  if (typeof payload.exp === "number" && payload.exp <= now) {
    return null;
  }
  if (typeof payload.nbf === "number" && payload.nbf > now) {
    return null;
  }

  const userId = payload.sub || payload.userId || payload.uid;
  if (!userId || typeof userId !== "string") {
    return null;
  }

  return {
    userId,
    claims: payload,
    authType: "jwt",
  };
}

function verifySignedSessionToken(sessionToken, secret) {
  const parts = String(sessionToken || "").split(".");
  if (parts.length !== 2) {
    return null;
  }

  const [encodedPayload, providedSignature] = parts;
  const expectedSignature = encodeBase64Url(
    crypto.createHmac("sha256", secret).update(encodedPayload).digest(),
  );
  if (!timingSafeEqualStrings(providedSignature, expectedSignature)) {
    return null;
  }

  const payload = parseJsonBuffer(decodeBase64Url(encodedPayload));
  if (!payload || typeof payload !== "object") {
    return null;
  }

  const now = Math.floor(Date.now() / 1000);
  if (typeof payload.exp === "number" && payload.exp <= now) {
    return null;
  }

  if (!payload.userId || typeof payload.userId !== "string") {
    return null;
  }

  return {
    userId: payload.userId,
    claims: payload,
    authType: "session",
  };
}

function getBearerToken(req) {
  const header = req.headers.authorization || "";
  const token = header.replace(/^Bearer\s+/i, "").trim();
  return token || null;
}

function tryBearerAuthentication(req, jwtSecret, allowOpaqueTokens) {
  const bearerToken = getBearerToken(req);
  if (!bearerToken) {
    return null;
  }

  if (jwtSecret) {
    const jwtAuth = verifyHs256Jwt(bearerToken, jwtSecret);
    if (jwtAuth) {
      return { ok: true, auth: jwtAuth };
    }
    if (!allowOpaqueTokens) {
      return { ok: false, error: "invalid auth token" };
    }
  }

  if (!allowOpaqueTokens) {
    return null;
  }

  const headerUserId = req.headers["x-dfc-user-id"];
  const userId = typeof headerUserId === "string" && headerUserId.trim()
    ? headerUserId.trim()
    : bearerToken;
  return {
    ok: true,
    auth: { userId, authType: "opaque" },
  };
}

function trySessionAuthentication(req, sessionSecret) {
  const sessionToken = req.headers["x-dfc-session-token"];
  if (!sessionSecret || typeof sessionToken !== "string" || !sessionToken.trim()) {
    return null;
  }

  const sessionAuth = verifySignedSessionToken(sessionToken.trim(), sessionSecret);
  if (!sessionAuth) {
    return { ok: false, error: "invalid session token" };
  }

  return { ok: true, auth: sessionAuth };
}

function applyAuthToRequest(req, auth) {
  req.authUserId = auth.userId;
  req.authContext = auth;
}

function createApiAuthMiddleware(options = {}) {
  const requireEnvVar = options.requireEnvVar || "REQUIRE_AUTH_FOR_PPV";

  return function requireApiAuth(req, res, next) {
    if (process.env[requireEnvVar] !== "true") {
      return next();
    }

    const jwtSecret = process.env.JWT_SECRET || "";
    const sessionSecret = process.env.SESSION_SECRET || "";
    const allowOpaqueTokens = process.env.ALLOW_OPAQUE_AUTH_TOKENS === "true" || !jwtSecret;

    const bearerResult = tryBearerAuthentication(req, jwtSecret, allowOpaqueTokens);
    if (bearerResult?.ok) {
      applyAuthToRequest(req, bearerResult.auth);
      return next();
    }
    if (bearerResult && !bearerResult.ok) {
      return res.status(401).json({ error: bearerResult.error });
    }

    const sessionResult = trySessionAuthentication(req, sessionSecret);
    if (sessionResult?.ok) {
      applyAuthToRequest(req, sessionResult.auth);
      return next();
    }
    if (sessionResult && !sessionResult.ok) {
      return res.status(401).json({ error: sessionResult.error });
    }

    return res.status(401).json({ error: "authentication required" });
  };
}

module.exports = {
  createApiAuthMiddleware,
};
