/**
 * DFC Serverless — Leak Detection Handler
 * Receives forensic watermark matches and triggers takedown workflows.
 * Deploy: npx serverless deploy function -f leakHandler
 */
"use strict";

exports.handler = async (event) => {
  try {
    const body = JSON.parse(event.body || "{}");
    const {
      watermarkId,
      buyerId,
      eventId,
      platform,
      leakUrl,
      matchConfidence = 0,
    } = body;

    if (!watermarkId || !leakUrl) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "watermarkId, leakUrl required" }),
      };
    }

    const severity =
      matchConfidence > 0.9
        ? "CRITICAL"
        : matchConfidence > 0.7
          ? "HIGH"
          : matchConfidence > 0.5
            ? "MEDIUM"
            : "LOW";

    const leak = {
      watermarkId,
      buyerId: buyerId || "unknown",
      eventId: eventId || "unknown",
      platform: platform || "unknown",
      leakUrl,
      matchConfidence,
      severity,
      detectedAt: new Date().toISOString(),
      status: "detected",
    };

    // Forward to n8n leak detection workflow
    const n8nWebhook =
      process.env.N8N_LEAK_WEBHOOK ||
      "http://localhost:5678/webhook/leak-detected";
    const { default: fetch } = await import("node-fetch");

    const n8nRes = await fetch(n8nWebhook, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(leak),
      signal: AbortSignal.timeout(10000),
    });

    const n8nResult = await n8nRes
      .json()
      .catch(() => ({ status: n8nRes.status }));

    // If critical, also revoke entitlement directly
    if (severity === "CRITICAL" && buyerId) {
      const entitlementUrl =
        process.env.ENTITLEMENT_URL || "http://localhost:4010";
      await fetch(`${entitlementUrl}/revoke`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ buyerId, reason: "leak_detected", watermarkId }),
        signal: AbortSignal.timeout(5000),
      }).catch((err) => console.error("Revoke failed:", err.message));
    }

    return {
      statusCode: 200,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        ...leak,
        n8nTriggered: n8nRes.ok,
        revokedEntitlement: severity === "CRITICAL" && !!buyerId,
      }),
    };
  } catch (err) {
    console.error("leakHandler error:", err);
    return { statusCode: 500, body: JSON.stringify({ error: err.message }) };
  }
};
