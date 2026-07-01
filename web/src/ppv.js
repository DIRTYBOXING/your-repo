// web/src/ppv.js
"use strict";

/**
 * PPV checkout → entitlement token → DRM license → playback helpers.
 * Used by the DFC web player UI.
 */

const API_BASE = process.env.REACT_APP_API_BASE || "";

/**
 * Creates a Stripe Checkout session and returns the redirect URL + session ID.
 * @param {string} userId
 * @param {string} eventId
 * @param {string|Object} priceIdOrOptions  — legacy Stripe Price ID or a structured options object
 * @returns {{ checkout_url: string, session_id: string }}
 */
export async function startCheckout(userId, eventId, priceIdOrOptions) {
  const options =
    priceIdOrOptions && typeof priceIdOrOptions === "object"
      ? priceIdOrOptions
      : { priceId: priceIdOrOptions };

  const body = {
    user_id: userId,
    event_id: eventId,
  };

  const priceId = options.priceId || options.price_id;
  const tier = options.tier || options.tierKey || options.tier_key;
  const successUrl = options.successUrl || options.success_url;
  const cancelUrl = options.cancelUrl || options.cancel_url;

  if (priceId) body.price_id = priceId;
  if (tier) body.tier = tier;
  if (successUrl) body.success_url = successUrl;
  if (cancelUrl) body.cancel_url = cancelUrl;

  const res = await fetch(`${API_BASE}/checkout`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error("Checkout failed: " + text);
  }
  return res.json();
}

/**
 * Requests a short-lived RS256 JWT entitlement token after payment.
 * Call this after the Stripe success redirect.
 * @param {string} userId
 * @param {string} sessionId
 * @param {string} eventId
 * @returns {{ token: string, expires_in: number }}
 */
export async function requestEntitlementToken(userId, sessionId, eventId) {
  const res = await fetch(`${API_BASE}/entitlements/token`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      user_id: userId,
      session_id: sessionId,
      event_id: eventId,
    }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error("Token request failed: " + text);
  }
  return res.json();
}

/**
 * Configures a Shaka Player instance with DRM and the entitlement token,
 * then loads and plays the manifest.
 *
 * @param {shaka.Player} player  — already attached to video element
 * @param {string} manifestUrl   — DASH/HLS manifest URL
 * @param {string} entitlementToken — JWT from requestEntitlementToken
 */
export async function playWithToken(player, manifestUrl, entitlementToken) {
  player.configure({
    drm: {
      servers: {
        "com.widevine.alpha": `${API_BASE}/license`,
        "com.apple.fps.1_0": `${API_BASE}/license`,
      },
    },
    streaming: { rebufferingGoal: 0.5 },
  });

  // Attach entitlement token to every DRM license request
  player.getNetworkingEngine().registerRequestFilter((type, request) => {
    if (type === shaka.net.NetworkingEngine.RequestType.LICENSE) {
      request.headers["Authorization"] = `Bearer ${entitlementToken}`;
    }
  });

  await player.load(manifestUrl);
  player.getMediaElement().play();
}
