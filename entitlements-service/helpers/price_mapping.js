"use strict";

const TIER_DEFINITIONS = {
  early_bird: {
    tierId: 3,
    tierName: "EARLY_BIRD",
    displayName: "EARLY BIRD",
    amountFields: ["earlyBirdPriceCents", "standardPriceCents"],
    aliases: ["early_bird", "earlybird", "early-bird", "presale"],
  },
  standard: {
    tierId: 4,
    tierName: "STANDARD",
    displayName: "STANDARD",
    amountFields: ["standardPriceCents"],
    aliases: ["standard", "main_card", "main-card", "maincard"],
  },
  premium: {
    tierId: 8,
    tierName: "PREMIUM",
    displayName: "PREMIUM",
    amountFields: ["premiumPriceCents", "standardPriceCents"],
    aliases: ["premium", "title_fights", "title-fights", "titlefights"],
  },
  vip: {
    tierId: 5,
    tierName: "VIP",
    displayName: "VIP",
    amountFields: ["vipPriceCents", "premiumPriceCents", "standardPriceCents"],
    aliases: ["vip", "full_show", "full-show", "fullshow"],
  },
};

const TIER_KEYS = Object.keys(TIER_DEFINITIONS);

function normalizeTierKey(value) {
  if (!value) return null;

  const normalized = value
    .toString()
    .trim()
    .toLowerCase()
    .replaceAll(/[\s-]+/g, "_");

  return (
    TIER_KEYS.find((key) => {
      const definition = TIER_DEFINITIONS[key];
      return key === normalized || definition.aliases.includes(normalized);
    }) || null
  );
}

function readAmount(eventData, amountFields) {
  for (const field of amountFields) {
    const value = eventData?.[field];
    if (typeof value === "number" && Number.isFinite(value)) {
      return Math.round(value);
    }
    if (
      typeof value === "string" &&
      value.trim() &&
      !Number.isNaN(Number(value))
    ) {
      return Math.round(Number(value));
    }
  }

  return null;
}

function buildTierInfo(eventData, tier) {
  const tierKey = normalizeTierKey(tier);
  if (!tierKey) return null;

  const definition = TIER_DEFINITIONS[tierKey];
  const amountCents = readAmount(eventData, definition.amountFields);
  if (!Number.isInteger(amountCents)) return null;

  return {
    tierKey,
    tierId: definition.tierId,
    tierName: definition.tierName,
    displayName: definition.displayName,
    amountCents,
    currency: (eventData?.currency || "AUD").toString().toUpperCase(),
  };
}

function tierToPriceId(eventData, tier) {
  const tierKey = normalizeTierKey(tier);
  if (!tierKey) return null;

  const sources = [
    eventData?.stripePriceIds,
    eventData?.providerPriceIds?.stripe,
    eventData?.providerPriceIds,
  ];

  for (const source of sources) {
    if (!source || typeof source !== "object") continue;
    const direct =
      source[tierKey] || source[TIER_DEFINITIONS[tierKey].tierName];
    if (typeof direct === "string" && direct.trim()) {
      return direct.trim();
    }
  }

  return null;
}

function tierByAmount(eventData, unitAmount) {
  if (!Number.isInteger(unitAmount)) return null;

  const matches = TIER_KEYS.map((key) => buildTierInfo(eventData, key))
    .filter(Boolean)
    .filter((tier) => tier.amountCents === unitAmount);

  if (matches.length === 0) {
    return null;
  }

  const standardMatch = matches.find((tier) => tier.tierKey === "standard");
  return standardMatch || matches[0];
}

function priceIdToTier(eventData, price) {
  const priceId = typeof price === "string" ? price : price?.id;
  const mappedTierKey = TIER_KEYS.find(
    (key) => tierToPriceId(eventData, key) === priceId,
  );
  if (mappedTierKey) {
    return buildTierInfo(eventData, mappedTierKey);
  }

  const unitAmount =
    price && typeof price === "object" && Number.isInteger(price.unit_amount)
      ? price.unit_amount
      : null;
  return tierByAmount(eventData, unitAmount);
}

function resolveTier({ eventData, tier, priceId, price, unitAmount }) {
  if (!eventData) return null;

  const explicitTier = buildTierInfo(eventData, tier);
  if (explicitTier) {
    return explicitTier;
  }

  const resolvedFromPrice = priceIdToTier(
    eventData,
    price || { id: priceId || null, unit_amount: unitAmount ?? null },
  );
  if (resolvedFromPrice) {
    return resolvedFromPrice;
  }

  return null;
}

module.exports = {
  normalizeTierKey,
  priceIdToTier,
  resolveTier,
  tierToPriceId,
};
