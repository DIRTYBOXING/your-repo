import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * ═══════════════════════════════════════════════════════════════════════════
 * FIGHT STOCK EXCHANGE ENGINE — Trade Execution (Secure Transaction)
 * ═══════════════════════════════════════════════════════════════════════════
 * Processes BUY/SELL orders for virtual fighter shares.
 * Guarantees atomic updates to user balances, portfolio shares, and stock prices.
 */
export const executeVirtualTrade = onCall(async (request) => {
  const { auth, data } = request;

  // 1. Security Gate: Verify Authentication
  if (!auth) {
    throw new HttpsError("unauthenticated", "Authentication required to execute trades.");
  }

  const { ticker, action, quantity } = data; // action: 'BUY' or 'SELL'
  const uid = auth.uid;

  if (!ticker || !action || typeof quantity !== 'number' || quantity <= 0) {
    throw new HttpsError("invalid-argument", "Malformed trade parameters.");
  }

  try {
    // 2. Atomic Transaction Execution
    return await db.runTransaction(async (transaction) => {
      const userRef = db.collection("users").doc(uid);
      const portfolioRef = userRef.collection("portfolio").doc(ticker);
      const stockRef = db.collection("fighter_stocks").doc(ticker);

      // Fetch all required data concurrently
      const [userSnap, portfolioSnap, stockSnap] = await Promise.all([
        transaction.get(userRef),
        transaction.get(portfolioRef),
        transaction.get(stockRef)
      ]);

      if (!userSnap.exists) {
        throw new HttpsError("not-found", "User account not found in database.");
      }
      if (!stockSnap.exists) {
        throw new HttpsError("not-found", `Fighter stock [${ticker}] not found.`);
      }

      const userData = userSnap.data()!;
      const stockData = stockSnap.data()!;
      const portfolioData = portfolioSnap.exists ? portfolioSnap.data()! : { shares: 0 };

      let userBalance = userData.walletBalance || 0;
      const currentPrice = stockData.currentPrice;
      const totalValue = currentPrice * quantity;
      let userShares = portfolioData.shares;

      let newStockPrice = currentPrice;

      // ── Process BUY Order ──
      if (action === "BUY") {
        if (userBalance < totalValue) {
          throw new HttpsError("failed-precondition", "Insufficient funds to execute this trade.");
        }
        userBalance -= totalValue;
        userShares += quantity;

        // Gamification: Buying pressure slightly increases stock price
        newStockPrice = currentPrice + (quantity * 0.005);

      // ── Process SELL Order ──
      } else if (action === "SELL") {
        if (userShares < quantity) {
          throw new HttpsError("failed-precondition", "Insufficient shares. You cannot short this asset.");
        }
        userBalance += totalValue;
        userShares -= quantity;

        // Gamification: Selling pressure slightly decreases stock price
        newStockPrice = Math.max(1.0, currentPrice - (quantity * 0.005));
      } else {
        throw new HttpsError("invalid-argument", "Trade action must be exactly 'BUY' or 'SELL'.");
      }

      // 3. Commit Mutations
      transaction.update(userRef, { walletBalance: userBalance });
      transaction.update(stockRef, {
        currentPrice: newStockPrice,
        volume: admin.firestore.FieldValue.increment(quantity)
      });

      if (userShares === 0) {
        transaction.delete(portfolioRef);
      } else {
        transaction.set(portfolioRef, {
          shares: userShares,
          avgPrice: currentPrice, // In a full implementation, you'd calculate VWAP here
          lastTradedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
      }

      return { success: true, newBalance: userBalance, currentShares: userShares, executionPrice: currentPrice };
    });
  } catch (error) {
    console.error(`[Trade Engine Error] UID: ${uid} | Ticker: ${ticker} | Error:`, error);
    throw new HttpsError("internal", "Trade execution failed. Transaction rolled back.");
  }
});
