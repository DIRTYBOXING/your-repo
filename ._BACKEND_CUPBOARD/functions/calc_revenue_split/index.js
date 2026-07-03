const { onCall } = require("firebase-functions/v2/https");
const { db, REGION } = require("../config");

async function resolveRate(rateKey) {
  const settingsDoc = await db.doc("admin/settings").get();
  const settings = settingsDoc.exists ? settingsDoc.data() : {};
  if (settings?.[rateKey] == null) {
    return null;
  }

  const resolved = Number(settings[rateKey]);
  return Number.isFinite(resolved) ? resolved : null;
}

const calcRevenueSplit = onCall({ region: REGION }, async (request) => {
  const { eventId, saleAmount, tierId } = request.data || {};

  if (!eventId || saleAmount == null || !tierId) {
    return {
      status: "error",
      message: "Missing required fields: eventId, saleAmount, tierId",
    };
  }

  const numericSaleAmount = Number(saleAmount);
  if (!Number.isFinite(numericSaleAmount) || numericSaleAmount <= 0) {
    return {
      status: "error",
      message: "saleAmount must be a positive number",
    };
  }

  const tierDoc = await db.doc(`config/contract_tiers/tiers/${tierId}`).get();
  if (!tierDoc.exists) {
    return { status: "error", message: "Tier not found" };
  }

  const tierData = tierDoc.data() || {};
  const rateKey = tierData.rate_key;
  if (!rateKey) {
    return { status: "error", message: "Tier missing rate_key" };
  }

  const rate = await resolveRate(rateKey);
  if (rate == null) {
    return {
      status: "error",
      message: `Rate not configured for key ${rateKey}`,
    };
  }

  const platformShare = Math.round(numericSaleAmount * rate);
  const promoterShare = numericSaleAmount - platformShare;

  console.log(
    JSON.stringify({
      severity: "INFO",
      metric: "revenue_split_calculated",
      service: "calcRevenueSplit",
      eventId,
      tierId,
      rateKey,
      rate,
      saleAmount: numericSaleAmount,
      platformShare,
      promoterShare,
      ts: new Date().toISOString(),
    })
  );

  return {
    status: "ok",
    eventId,
    tierId,
    saleAmount: numericSaleAmount,
    platformShare,
    promoterShare,
  };
});

module.exports = {
  calcRevenueSplit,
};
