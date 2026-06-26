const functions = require("firebase-functions");
const admin = require("firebase-admin");
if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

// Configurable thresholds
const AUTO_APPROVE_THRESHOLD = 0.0;
const FLAG_THRESHOLD = 0.45;
const AUTO_REJECT_THRESHOLD = 0.85;

// Simple keyword blocklist — replace with AI moderation API later
const BLOCKED_KEYWORDS = ["threatword1", "threatword2", "slur1"];

// Replace this stub with your AI moderation call (Perspective API, OpenAI, etc.)
async function computeToxicity(text) {
  const lower = (text || "").toLowerCase();
  let hits = 0;
  for (const k of BLOCKED_KEYWORDS) if (lower.includes(k)) hits++;
  const score = Math.min(1.0, hits * 0.6 + Math.min(0.5, text.length / 500));
  return score;
}

exports.moderateQuestion = functions.firestore
  .document("fighters/{fighterId}/questions/{questionId}")
  .onWrite(async (change, context) => {
    const after = change.after.exists ? change.after.data() : null;
    if (!after) return null;

    const status = after.status || "pending";
    if (status !== "pending") return null;

    const text = after.text || "";
    const toxicity = await computeToxicity(text);

    let newStatus = "pending";
    let action = "flagged";
    if (toxicity >= AUTO_REJECT_THRESHOLD) {
      newStatus = "rejected";
      action = "autoRejected";
    } else if (toxicity <= AUTO_APPROVE_THRESHOLD) {
      newStatus = "approved";
      action = "autoApproved";
    } else if (toxicity >= FLAG_THRESHOLD) {
      newStatus = "pending";
      action = "flagged";
    } else {
      newStatus = "approved";
      action = "autoApproved";
    }

    const audit = {
      targetType: "question",
      targetId: context.params.questionId,
      action,
      score: toxicity,
      reason: action === "flagged" ? "requires human review" : "auto decision",
      actor: "auto",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };

    const questionRef = db.doc(
      `fighters/${context.params.fighterId}/questions/${context.params.questionId}`,
    );
    const auditRef = db.collection("moderation_audit").doc();

    await db.runTransaction(async (tx) => {
      tx.set(auditRef, audit);
      tx.update(questionRef, {
        toxicityScore: toxicity,
        status: newStatus,
        autoDecision: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    return null;
  });
