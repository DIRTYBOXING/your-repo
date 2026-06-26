// ─────────────────────────────────────────────────────────────
// drm-license-exchange.js — DRM license proxy for Widevine + FairPlay
//
// Validates playback tokens via the entitlement service, then
// proxies the license request to the DRM provider. Clients never
// contact the DRM provider directly. Logs every issuance to PG.
//
// Required env:
//   CANONICAL_ENTITLEMENT_API — canonical entitlement service base URL
//   ENTITLEMENT_API       — legacy entitlement service base URL
//   DRM_WIDEVINE_URL      — Widevine license provider endpoint
//   DRM_FAIRPLAY_URL      — FairPlay license provider endpoint
//   DRM_PROVIDER_KEY      — API key for the DRM provider
//   PG_CONN               — Postgres connection string (audit)
// ─────────────────────────────────────────────────────────────
import pg from "pg";
const { Pool } = pg;

let _pool = null;
function getPool() {
  if (!_pool) {
    _pool = new Pool({
      connectionString:
        process.env.PG_CONN || "postgresql://localhost:5432/dfc",
    });
  }
  return _pool;
}

async function logLicenseIssuance(userId, eventId, drmType, clientIp) {
  try {
    const pool = getPool();
    await pool.query(
      `INSERT INTO license_issuance (user_id, event_id, drm_type, client_ip, created_at)
       VALUES ($1,$2,$3,$4,now())`,
      [userId, eventId, drmType, clientIp],
    );
  } catch (err) {
    console.error("license audit log failed (non-fatal):", err.message);
  }
}

// Validate playback token with entitlement service
async function validatePlaybackToken(token) {
  const base =
    process.env.CANONICAL_ENTITLEMENT_API || process.env.ENTITLEMENT_API;
  if (!base) throw new Error("ENTITLEMENT_API not configured");

  const res = await fetch(`${base}/validate`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ playbackToken: token }),
  });
  if (!res.ok) return null;
  return res.json();
}

// Proxy license request to DRM provider
async function requestFromProvider(providerUrl, binaryBody) {
  const providerKey = process.env.DRM_PROVIDER_KEY || "";
  const res = await fetch(providerUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/octet-stream",
      "X-Provider-Key": providerKey,
    },
    body: binaryBody,
  });
  if (!res.ok) throw new Error(`DRM provider error: ${res.status}`);
  return Buffer.from(await res.arrayBuffer());
}

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  try {
    const { playbackToken, drmType, licenseRequestBase64, spc } = req.body;

    if (!playbackToken || !drmType) {
      return res
        .status(400)
        .json({ error: "Missing playbackToken or drmType" });
    }

    // Validate entitlement — checks ok:true from entitlement.js
    const entitlement = await validatePlaybackToken(playbackToken);
    if (entitlement?.ok !== true) {
      return res.status(403).json({ error: "Entitlement denied" });
    }

    const userId = entitlement.userId || null;
    const eventId = entitlement.eventId || null;
    const clientIp = req.ip || req.headers["x-forwarded-for"] || null;

    if (drmType === "widevine") {
      const widevineUrl = process.env.DRM_WIDEVINE_URL;
      if (!widevineUrl)
        return res.status(500).json({ error: "Widevine URL not configured" });

      const challengeBuffer = Buffer.from(licenseRequestBase64 || "", "base64");
      const licenseBuffer = await requestFromProvider(
        widevineUrl,
        challengeBuffer,
      );

      await logLicenseIssuance(userId, eventId, "widevine", clientIp);
      res.set("Content-Type", "application/octet-stream");
      return res.send(licenseBuffer);
    }

    if (drmType === "fairplay") {
      const fairplayUrl = process.env.DRM_FAIRPLAY_URL;
      if (!fairplayUrl)
        return res.status(500).json({ error: "FairPlay URL not configured" });

      const spcBuffer = Buffer.from(spc || "", "base64");
      const ckcBuffer = await requestFromProvider(fairplayUrl, spcBuffer);

      await logLicenseIssuance(userId, eventId, "fairplay", clientIp);
      return res.json({ ckcBase64: ckcBuffer.toString("base64") });
    }

    return res.status(400).json({ error: `Unsupported drmType: ${drmType}` });
  } catch (err) {
    console.error("DRM license exchange error:", err);
    return res.status(500).json({ error: "Internal server error" });
  }
}
