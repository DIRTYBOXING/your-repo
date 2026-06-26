// ═══════════════════════════════════════════════════════════════════════════
// DFC POST-EVENT EMAIL ENGINE — Auto-Highlight & Replay Emails
// ═══════════════════════════════════════════════════════════════════════════
//
// SYSTEM: "The Sale Doesn't End" — Keeps revenue flowing after the stream.
//
// Trigger: ppv_events/{ppvId} status transitions to 'replay'
//   (rides the same transition as onPPVReplayReady in post_event.js,
//    but sends personalized SendGrid emails to purchasers.)
//
// Emails sent:
//   1. PURCHASERS → "Your Replay + Spoiler-Free Highlights are Ready"
//      Personalized with their name, event title, direct replay link.
//
//   2. PREDICTION WINNERS → "You Nailed It! DFC Credits Awarded"
//      Triggered after prediction scoring completes.
//      Personalized with score breakdown and new credit balance.
//
// Firestore:
//   ppv_events/{ppvId}                    — event data + status
//   ppv_purchases where ppvId == ppvId    — purchaser user IDs
//   ppv_events/{ppvId}/predictions        — scored predictions
//   credit_wallets/{userId}               — updated balance
//   email_logs/{docId}                    — audit trail
//
// ═══════════════════════════════════════════════════════════════════════════

const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { admin, db, sgMail, REGION } = require("../config");

const FROM_EMAIL = "noreply@datafightcentral.com";
const FROM_NAME = "Data Fight Central";

// ═══════════════════════════════════════════════════════════════════════════
// EMAIL 1: REPLAY & HIGHLIGHTS READY (on status → replay)
// ═══════════════════════════════════════════════════════════════════════════
//
// Sends to every purchaser of this event.
// Includes: event title, direct replay link, highlights teaser.
//
const onReplayEmailTrigger = onDocumentUpdated(
  {
    document: "ppv_events/{ppvId}",
    region: REGION,
  },
  async (event) => {
    if (!sgMail) {
      console.log("[ReplayEmail] SendGrid not configured — skipping");
      return;
    }

    const before = event.data.before.data();
    const after = event.data.after.data();
    const ppvId = event.params.ppvId;

    // Only fire on status → replay
    if (before.status === after.status) return;
    if (after.status !== "replay") return;

    // Guard: don't re-send if already emailed
    if (after.replayEmailSent === true) return;

    const title = after.title || after.name || "FIGHT NIGHT";
    const replayUrl =
      after.replayUrl || `https://datafightcentral.com/ppv/event/${ppvId}`;
    const posterUrl = after.posterUrl || after.imageUrl || "";
    const highlightsReady = after.highlightsReady === true;

    console.log(`[ReplayEmail] Sending replay emails for ${ppvId} — ${title}`);

    // Get all purchaser user IDs
    const purchasesSnap = await db
      .collection("ppv_purchases")
      .where("ppvId", "==", ppvId)
      .where("isActive", "==", true)
      .get();

    if (purchasesSnap.empty) {
      console.log(`[ReplayEmail] No active purchasers for ${ppvId} — skipping`);
      return;
    }

    // Collect unique user emails
    const userEmails = new Map(); // userId → { email, displayName }
    for (const doc of purchasesSnap.docs) {
      const userId = doc.data().userId;
      if (!userId || userEmails.has(userId)) continue;

      const userDoc = await db.collection("users").doc(userId).get();
      if (!userDoc.exists) continue;
      const userData = userDoc.data();
      const email = userData.email;
      if (!email) continue;

      userEmails.set(userId, {
        email,
        displayName: userData.displayName || userData.name || "Fighter",
      });
    }

    if (userEmails.size === 0) {
      console.log(`[ReplayEmail] No purchaser emails found for ${ppvId}`);
      return;
    }

    // Build and send emails
    let sentCount = 0;
    let failCount = 0;

    for (const [userId, { email, displayName }] of userEmails) {
      const msg = {
        to: email,
        from: { email: FROM_EMAIL, name: FROM_NAME },
        subject: `📺 ${title} — Your Replay is Ready`,
        html: buildReplayEmailHtml({
          displayName,
          title,
          replayUrl,
          posterUrl,
          highlightsReady,
          ppvId,
        }),
      };

      try {
        await sgMail.send(msg);
        sentCount++;
      } catch (err) {
        console.error(`[ReplayEmail] Failed to send to ${email}:`, err.message);
        failCount++;
      }
    }

    // Audit log
    await db.collection("email_logs").add({
      type: "replay_ready",
      ppvId,
      eventTitle: title,
      totalRecipients: userEmails.size,
      sent: sentCount,
      failed: failCount,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Mark event so we don't double-send
    await db
      .collection("ppv_events")
      .doc(ppvId)
      .update({
        replayEmailSent: true,
        replayEmailSentAt: admin.firestore.FieldValue.serverTimestamp(),
        replayEmailCount: sentCount,
      })
      .catch(() => {});

    console.log(
      `[ReplayEmail] ✅ Sent ${sentCount} replay emails for ${ppvId} (${failCount} failed)`,
    );
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// EMAIL 2: PREDICTION PAYOUT NOTIFICATION (on predictionsScored → true)
// ═══════════════════════════════════════════════════════════════════════════
//
// Sends to every user who made a prediction and earned credits.
// Triggered when prediction_payouts.js sets predictionsScored=true on the event.
//
const onPredictionPayoutEmail = onDocumentUpdated(
  {
    document: "ppv_events/{ppvId}",
    region: REGION,
  },
  async (event) => {
    if (!sgMail) return;

    const before = event.data.before.data();
    const after = event.data.after.data();
    const ppvId = event.params.ppvId;

    // Only fire when predictionsScored flips to true
    if (before.predictionsScored === true) return;
    if (after.predictionsScored !== true) return;
    if (after.predictionPayoutEmailSent === true) return;

    const title = after.title || after.name || "FIGHT NIGHT";

    console.log(`[PredictionEmail] Sending payout notifications for ${ppvId}`);

    // Get all scored predictions that earned credits
    const predsSnap = await db
      .collection("ppv_events")
      .doc(ppvId)
      .collection("predictions")
      .where("scored", "==", true)
      .where("creditsAwarded", ">", 0)
      .get();

    if (predsSnap.empty) {
      console.log(`[PredictionEmail] No winners for ${ppvId}`);
      return;
    }

    let sentCount = 0;
    let failCount = 0;

    for (const predDoc of predsSnap.docs) {
      const pred = predDoc.data();
      const userId = pred.userId;
      if (!userId) continue;

      // Get user email
      const userDoc = await db.collection("users").doc(userId).get();
      if (!userDoc.exists) continue;
      const userData = userDoc.data();
      const email = userData.email;
      if (!email) continue;

      const displayName = userData.displayName || userData.name || "Fighter";

      // Get updated wallet balance
      const walletDoc = await db.collection("credit_wallets").doc(userId).get();
      const balance = walletDoc.exists
        ? walletDoc.data().balance || 0
        : pred.creditsAwarded;

      const msg = {
        to: email,
        from: { email: FROM_EMAIL, name: FROM_NAME },
        subject: pred.isPerfect
          ? `🏆 PERFECT PREDICTION — ${title}!`
          : `🎯 You Called It — ${pred.creditsAwarded} DFC Credits Earned!`,
        html: buildPayoutEmailHtml({
          displayName,
          title,
          correctCount: pred.correctCount,
          totalQuestions: pred.totalQuestions,
          isPerfect: pred.isPerfect,
          creditsAwarded: pred.creditsAwarded,
          newBalance: balance,
          ppvId,
        }),
      };

      try {
        await sgMail.send(msg);
        sentCount++;
      } catch (err) {
        console.error(
          `[PredictionEmail] Failed to send to ${email}:`,
          err.message,
        );
        failCount++;
      }
    }

    // Audit log
    await db.collection("email_logs").add({
      type: "prediction_payout",
      ppvId,
      eventTitle: title,
      totalRecipients: predsSnap.size,
      sent: sentCount,
      failed: failCount,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Guard flag
    await db
      .collection("ppv_events")
      .doc(ppvId)
      .update({
        predictionPayoutEmailSent: true,
        predictionPayoutEmailSentAt:
          admin.firestore.FieldValue.serverTimestamp(),
      })
      .catch(() => {});

    console.log(
      `[PredictionEmail] ✅ Sent ${sentCount} payout emails for ${ppvId}`,
    );
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// HTML EMAIL BUILDERS
// ═══════════════════════════════════════════════════════════════════════════

function buildReplayEmailHtml({
  displayName,
  title,
  replayUrl,
  posterUrl,
  highlightsReady,
  ppvId,
}) {
  const highlightSection = highlightsReady
    ? `<tr><td style="padding:16px 24px;">
        <a href="https://datafightcentral.com/ppv/event/${ppvId}/highlights"
           style="display:inline-block;background:#00F5FF;color:#050A14;padding:12px 28px;border-radius:100px;font-weight:800;text-decoration:none;font-size:14px;letter-spacing:1px;">
           🔥 WATCH HIGHLIGHTS
        </a>
       </td></tr>`
    : "";

  return `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width"></head>
<body style="margin:0;padding:0;background:#050A14;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#050A14;">
<tr><td align="center" style="padding:24px 16px;">
  <table width="600" cellpadding="0" cellspacing="0" style="background:#0D1B2A;border-radius:18px;border:1px solid rgba(255,255,255,0.1);overflow:hidden;">
    ${posterUrl ? `<tr><td><img src="${posterUrl}" alt="${title}" style="width:100%;display:block;"></td></tr>` : ""}
    <tr><td style="padding:24px;">
      <p style="color:#FFFFFF;font-size:22px;font-weight:900;margin:0 0 8px;">📺 YOUR REPLAY IS READY</p>
      <p style="color:rgba(255,255,255,0.7);font-size:14px;margin:0 0 16px;">Hey ${displayName},</p>
      <p style="color:rgba(255,255,255,0.7);font-size:14px;line-height:1.6;margin:0 0 16px;">
        <strong style="color:#FFFFFF;">${title}</strong> is now available as an exclusive replay.
        Every punch, every submission, every knockout — rewatch it all, spoiler-free.
      </p>
    </td></tr>
    <tr><td style="padding:0 24px 16px;" align="center">
      <a href="${replayUrl}"
         style="display:inline-block;background:#FF3366;color:#FFFFFF;padding:14px 32px;border-radius:100px;font-weight:800;text-decoration:none;font-size:15px;letter-spacing:1px;">
         ▶ WATCH FULL REPLAY
      </a>
    </td></tr>
    ${highlightSection}
    <tr><td style="padding:16px 24px 24px;">
      <p style="color:rgba(255,255,255,0.4);font-size:11px;margin:0;text-align:center;">
        This replay is exclusive to your DFC account and expires in 48 hours.<br>
        © ${new Date().getFullYear()} Data Fight Central — datafightcentral.com
      </p>
    </td></tr>
  </table>
</td></tr>
</table>
</body>
</html>`;
}

function buildPayoutEmailHtml({
  displayName,
  title,
  correctCount,
  totalQuestions,
  isPerfect,
  creditsAwarded,
  newBalance,
  ppvId,
}) {
  const scoreBar = [];
  for (let i = 0; i < totalQuestions; i++) {
    const isCorrect = i < correctCount;
    scoreBar.push(
      `<span style="display:inline-block;width:28px;height:28px;line-height:28px;text-align:center;border-radius:50%;margin:0 3px;font-size:13px;font-weight:700;${
        isCorrect
          ? "background:#00FF88;color:#050A14;"
          : "background:rgba(255,255,255,0.1);color:rgba(255,255,255,0.4);"
      }">${isCorrect ? "✓" : "✗"}</span>`,
    );
  }

  return `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width"></head>
<body style="margin:0;padding:0;background:#050A14;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0" style="background:#050A14;">
<tr><td align="center" style="padding:24px 16px;">
  <table width="600" cellpadding="0" cellspacing="0" style="background:#0D1B2A;border-radius:18px;border:1px solid rgba(255,255,255,0.1);overflow:hidden;">
    <tr><td style="padding:24px;">
      <p style="color:#FFFFFF;font-size:22px;font-weight:900;margin:0 0 8px;">
        ${isPerfect ? "🏆 PERFECT PREDICTION!" : "🎯 YOU CALLED IT!"}
      </p>
      <p style="color:rgba(255,255,255,0.7);font-size:14px;margin:0 0 16px;">Hey ${displayName},</p>
      <p style="color:rgba(255,255,255,0.7);font-size:14px;line-height:1.6;margin:0 0 16px;">
        Your predictions for <strong style="color:#FFFFFF;">${title}</strong> have been scored${
          isPerfect ? " — and you nailed every single one!" : "."
        }
      </p>
    </td></tr>
    <tr><td style="padding:0 24px 16px;" align="center">
      <p style="color:rgba(255,255,255,0.5);font-size:11px;font-weight:700;letter-spacing:2px;margin:0 0 8px;">YOUR SCORECARD</p>
      <p style="margin:0 0 12px;">${scoreBar.join("")}</p>
      <p style="color:#FFFFFF;font-size:16px;font-weight:700;margin:0;">
        ${correctCount} / ${totalQuestions} Correct
      </p>
    </td></tr>
    <tr><td style="padding:0 24px 16px;" align="center">
      <table cellpadding="0" cellspacing="0" style="background:rgba(0,245,255,0.08);border:1px solid rgba(0,245,255,0.2);border-radius:14px;padding:16px 24px;">
        <tr>
          <td style="text-align:center;">
            <p style="color:#00F5FF;font-size:32px;font-weight:900;margin:0;">+${creditsAwarded}</p>
            <p style="color:rgba(255,255,255,0.5);font-size:11px;font-weight:700;letter-spacing:2px;margin:4px 0 0;">DFC CREDITS EARNED</p>
          </td>
        </tr>
      </table>
    </td></tr>
    <tr><td style="padding:0 24px 16px;" align="center">
      <p style="color:rgba(255,255,255,0.5);font-size:12px;margin:0 0 4px;">New Wallet Balance</p>
      <p style="color:#00FF88;font-size:20px;font-weight:800;margin:0;">${newBalance} Credits</p>
    </td></tr>
    <tr><td style="padding:0 24px 16px;" align="center">
      <a href="https://datafightcentral.com/credits"
         style="display:inline-block;background:#FF3366;color:#FFFFFF;padding:12px 28px;border-radius:100px;font-weight:800;text-decoration:none;font-size:14px;letter-spacing:1px;">
         USE YOUR CREDITS →
      </a>
    </td></tr>
    <tr><td style="padding:16px 24px 24px;">
      <p style="color:rgba(255,255,255,0.4);font-size:11px;margin:0;text-align:center;">
        DFC Credits can be used for PPV access, replays, tips, and premium analysis.<br>
        © ${new Date().getFullYear()} Data Fight Central — datafightcentral.com
      </p>
    </td></tr>
  </table>
</td></tr>
</table>
</body>
</html>`;
}

// ═══════════════════════════════════════════════════════════════════════════
// EXPORTS
// ═══════════════════════════════════════════════════════════════════════════
module.exports = {
  onReplayEmailTrigger,
  onPredictionPayoutEmail,
};
