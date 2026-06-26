#!/usr/bin/env node
// ═══════════════════════════════════════════════════════════════════════════
// DFC PPV PAYOUT CSV GENERATOR
// ═══════════════════════════════════════════════════════════════════════════
//
// Generates a full CSV projection for buys 1 → maxBuys showing:
//   buys, gross, stripe_fees, net, dfc_pct, dfc_cut, promoter_cut, reserve, payable_promoter
//
// Usage:
//   node scripts/generate_payout_csv.js                  # defaults: $20 price, 10000 buys
//   node scripts/generate_payout_csv.js 25.00 5000       # custom price + max buys
//   node scripts/generate_payout_csv.js 20.00 10000 > payouts.csv
//
// Formula (mirrors functions/stripe/ppv.js):
//   DFC_pct = 30% + (min(buys, 10000) / 10000) × 20%
//   Stripe fee per tx = price × 2.9% + $0.30
//   Reserve = 2% of Net
//   Payable Promoter = Promoter Cut − Reserve
// ═══════════════════════════════════════════════════════════════════════════

function dfcPctForBuys(buys) {
  const capped = Math.min(buys, 10000);
  return 0.3 + (capped / 10000) * 0.2;
}

function stripeFees(buys, price) {
  return buys * (price * 0.029 + 0.3);
}

function generateCsv(price, maxBuys) {
  const rows = [
    "buys,gross,stripe_fees,net,dfc_pct,dfc_cut,promoter_cut,reserve,payable_promoter",
  ];

  for (let buys = 1; buys <= maxBuys; buys++) {
    const gross = buys * price;
    const stripe = stripeFees(buys, price);
    const net = Math.max(0, gross - stripe);
    const dfcPct = dfcPctForBuys(buys);
    const dfcCut = net * dfcPct;
    const promoterCut = net - dfcCut;
    const reserve = net * 0.02;
    const payablePromoter = Math.max(0, promoterCut - reserve);

    rows.push(
      [
        buys,
        gross.toFixed(2),
        stripe.toFixed(2),
        net.toFixed(2),
        (dfcPct * 100).toFixed(2) + "%",
        dfcCut.toFixed(2),
        promoterCut.toFixed(2),
        reserve.toFixed(2),
        payablePromoter.toFixed(2),
      ].join(","),
    );
  }

  return rows.join("\n");
}

// ── CLI entry ──────────────────────────────────────────────────────────
const price = parseFloat(process.argv[2]) || 20.0;
const maxBuys = parseInt(process.argv[3], 10) || 10000;

console.log(generateCsv(price, maxBuys));
