// ═══════════════════════════════════════════════════════════════════════════
// REGIONAL PRICING — Purchasing Power Parity + Currency Localization
// ═══════════════════════════════════════════════════════════════════════════
//
// Detects user region and returns localized pricing for PPV events.
// AU/NZ = base price in AUD/NZD. Emerging markets = adjusted down.
// Ensures 100% conversion by removing price-shock barriers.
//
// Usage: Called by Flutter frontend before showing payment sheet.
//        Returns localized price, currency, and display string.
//
// ═══════════════════════════════════════════════════════════════════════════

const { onCall } = require("firebase-functions/v2/https");
const { REGION } = require("../config");

// ─── Regional Pricing Tiers ──────────────────────────────────────────────
// Base prices in AUD cents. Multipliers adjust per region.
// Multiplier < 1.0 = cheaper (emerging market).
// Multiplier > 1.0 = premium market (not currently used, but future-ready).
const REGION_CONFIG = {
  // Tier 1: Core AU/NZ markets (base price)
  AU: { currency: "aud", multiplier: 1.0, label: "AUD", flag: "🇦🇺" },
  NZ: { currency: "nzd", multiplier: 1.05, label: "NZD", flag: "🇳🇿" },

  // Tier 2: Premium English-speaking markets
  US: { currency: "usd", multiplier: 0.95, label: "USD", flag: "🇺🇸" },
  GB: { currency: "gbp", multiplier: 0.8, label: "GBP", flag: "🇬🇧" },
  CA: { currency: "cad", multiplier: 1.0, label: "CAD", flag: "🇨🇦" },
  IE: { currency: "eur", multiplier: 0.85, label: "EUR", flag: "🇮🇪" },

  // Tier 3: European markets
  DE: { currency: "eur", multiplier: 0.85, label: "EUR", flag: "🇩🇪" },
  FR: { currency: "eur", multiplier: 0.85, label: "EUR", flag: "🇫🇷" },
  NL: { currency: "eur", multiplier: 0.85, label: "EUR", flag: "🇳🇱" },

  // Tier 4: Asian markets (PPP adjusted)
  JP: {
    currency: "jpy",
    multiplier: 0.7,
    label: "JPY",
    flag: "🇯🇵",
    noDecimals: true,
  },
  SG: { currency: "sgd", multiplier: 0.8, label: "SGD", flag: "🇸🇬" },
  TH: { currency: "thb", multiplier: 0.4, label: "THB", flag: "🇹🇭" },
  PH: { currency: "php", multiplier: 0.3, label: "PHP", flag: "🇵🇭" },
  IN: { currency: "inr", multiplier: 0.25, label: "INR", flag: "🇮🇳" },

  // Tier 5: Emerging combat sports markets
  BR: { currency: "brl", multiplier: 0.35, label: "BRL", flag: "🇧🇷" },
  MX: { currency: "mxn", multiplier: 0.35, label: "MXN", flag: "🇲🇽" },
  ZA: { currency: "zar", multiplier: 0.3, label: "ZAR", flag: "🇿🇦" },
  NG: { currency: "ngn", multiplier: 0.2, label: "NGN", flag: "🇳🇬" },
};

// Fallback for unknown regions
const DEFAULT_REGION = {
  currency: "usd",
  multiplier: 0.9,
  label: "USD",
  flag: "🌍",
};

// ─── Micro-transaction round pricing (base cents AUD) ────────────────────
const ROUND_BASE_PRICE_CENTS = 250; // $2.50 AUD per round
const MAIN_EVENT_BASE_PRICE_CENTS = 999; // $9.99 AUD for main event only

/**
 * getRegionalPricing
 *
 * Input:  { countryCode, basePriceCents, tierId }
 * Output: { currency, priceCents, displayPrice, region, roundPriceCents,
 *           mainEventPriceCents, microTiers }
 */
const getRegionalPricing = onCall({ region: REGION }, async (request) => {
  const { countryCode, basePriceCents, tierId, eventId } = request.data;

  if (!basePriceCents) {
    return { error: "Missing basePriceCents" };
  }

  const country = (countryCode || "AU").toUpperCase();
  const config = REGION_CONFIG[country] || DEFAULT_REGION;

  // Calculate regional price
  const adjustedCents = Math.round(basePriceCents * config.multiplier);

  // Enforce Stripe minimum (50 cents in most currencies)
  const priceCents = Math.max(50, adjustedCents);

  // Regional round and main event pricing
  const roundPriceCents = Math.max(
    50,
    Math.round(ROUND_BASE_PRICE_CENTS * config.multiplier),
  );
  const mainEventPriceCents = Math.max(
    50,
    Math.round(MAIN_EVENT_BASE_PRICE_CENTS * config.multiplier),
  );

  // Format display price
  const dollars = config.noDecimals
    ? Math.round(priceCents / 100)
    : (priceCents / 100).toFixed(2);
  const displayPrice = `${config.flag} ${config.label} ${dollars}`;

  // Build full micro-tier menu for this region
  const microTiers = [
    {
      id: "round",
      name: "SINGLE ROUND",
      priceCents: roundPriceCents,
      display: formatRegionalPrice(roundPriceCents, config),
      type: "micro",
    },
    {
      id: "main_event",
      name: "MAIN EVENT ONLY",
      priceCents: mainEventPriceCents,
      display: formatRegionalPrice(mainEventPriceCents, config),
      type: "micro",
    },
    {
      id: "full_show",
      name: "FULL SHOW",
      priceCents: priceCents,
      display: formatRegionalPrice(priceCents, config),
      type: "standard",
    },
  ];

  return {
    country,
    currency: config.currency,
    priceCents,
    displayPrice,
    multiplier: config.multiplier,
    roundPriceCents,
    mainEventPriceCents,
    microTiers,
    region: getRegionTier(country),
  };
});

function formatRegionalPrice(cents, config) {
  const dollars = config.noDecimals
    ? Math.round(cents / 100)
    : (cents / 100).toFixed(2);
  return `${config.label} ${dollars}`;
}

function getRegionTier(country) {
  if (["AU", "NZ"].includes(country)) return "core";
  if (["US", "GB", "CA", "IE"].includes(country)) return "premium";
  if (["DE", "FR", "NL", "JP", "SG"].includes(country)) return "standard";
  if (["TH", "PH", "IN", "BR", "MX", "ZA", "NG"].includes(country))
    return "emerging";
  return "global";
}

module.exports = {
  getRegionalPricing,
  REGION_CONFIG,
  DEFAULT_REGION,
  ROUND_BASE_PRICE_CENTS,
  MAIN_EVENT_BASE_PRICE_CENTS,
};
