const functions = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { initializeApp } = require("firebase-admin/app");

// Initialize if not already done by another function file
try {
  initializeApp();
} catch (_) {
  /* already initialized */
}
const db = getFirestore();

const REGION = "australia-southeast1";

// ── Auth helper ──────────────────────────────────────────────────────────
async function validateModeratorOrAdmin(req) {
  const authHeader = req.headers.authorization || "";
  if (!authHeader.startsWith("Bearer ")) {
    throw new Error("Missing or invalid Authorization header");
  }
  const token = authHeader.split("Bearer ")[1];
  const decoded = await getAuth().verifyIdToken(token);
  if (!decoded.moderator && !decoded.admin) {
    throw new Error(
      "Insufficient permissions: moderator or admin claim required",
    );
  }
  return decoded.uid;
}

// ── Immutable audit helper ───────────────────────────────────────────────
function writeAudit(tx, data) {
  const ref = db.collection("takedown_audit").doc();
  tx.set(ref, {
    ...data,
    timestamp: FieldValue.serverTimestamp(),
  });
}

// ═════════════════════════════════════════════════════════════════════════
// 1. REQUEST TAKEDOWN — any authenticated user can file
// ═════════════════════════════════════════════════════════════════════════
exports.requestTakedown = functions.onRequest(
  { region: REGION },
  async (req, res) => {
    try {
      // Validate auth (any authenticated user, not just moderators)
      const authHeader = req.headers.authorization || "";
      let uid = "anonymous";
      if (authHeader.startsWith("Bearer ")) {
        const token = authHeader.split("Bearer ")[1];
        const decoded = await getAuth().verifyIdToken(token);
        uid = decoded.uid;
      }

      const { url, reason, category, priority, evidence, reporter, template } =
        req.body;
      if (!url || !reason) {
        return res.status(400).json({ error: "url and reason are required" });
      }

      const docRef = db.collection("takedown_requests").doc();
      await docRef.set({
        url,
        reason,
        category: category || "Other",
        priority: priority || "MEDIUM",
        evidence: evidence || "",
        reporter: reporter || uid,
        template: template || "",
        status: "pending",
        filedBy: uid,
        createdAt: FieldValue.serverTimestamp(),
      });

      // Slack notification if configured
      const slackUrl = process.env.SLACK_WEBHOOK;
      if (slackUrl) {
        try {
          await fetch(slackUrl, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              text: `:rotating_light: *Takedown Request* ${docRef.id}\n*URL:* ${url}\n*Category:* ${category || "Other"}\n*Priority:* ${priority || "MEDIUM"}\n*Reason:* ${reason}\n*Reporter:* ${reporter || uid}`,
            }),
          });
        } catch (slackErr) {
          console.warn("Slack notification failed:", slackErr.message);
        }
      }

      res.json({ ok: true, id: docRef.id });
    } catch (err) {
      console.error("requestTakedown error:", err);
      res.status(500).json({ error: err.message });
    }
  },
);

// ═════════════════════════════════════════════════════════════════════════
// 2. UPDATE TAKEDOWN STATUS — moderator/admin only
// ═════════════════════════════════════════════════════════════════════════
exports.updateTakedownStatus = functions.onRequest(
  { region: REGION },
  async (req, res) => {
    try {
      const uid = await validateModeratorOrAdmin(req);
      const { id, status, notes } = req.body;

      if (!id || !status) {
        return res.status(400).json({ error: "id and status are required" });
      }

      const validStatuses = [
        "pending",
        "sent",
        "acknowledged",
        "resolved",
        "rejected",
      ];
      if (!validStatuses.includes(status)) {
        return res.status(400).json({
          error: `Invalid status. Must be one of: ${validStatuses.join(", ")}`,
        });
      }

      const docRef = db.doc(`takedown_requests/${id}`);

      await db.runTransaction(async (tx) => {
        const snap = await tx.get(docRef);
        if (!snap.exists) throw new Error("Takedown request not found");

        const updates = {
          status,
          updatedBy: uid,
          updatedAt: FieldValue.serverTimestamp(),
        };
        if (notes) updates.notes = notes;
        if (status === "resolved")
          updates.resolvedAt = FieldValue.serverTimestamp();

        tx.update(docRef, updates);
        writeAudit(tx, {
          targetId: id,
          action: `takedown_${status}`,
          actor: uid,
          reason: notes || `Status updated to ${status}`,
        });
      });

      res.json({ ok: true });
    } catch (err) {
      console.error("updateTakedownStatus error:", err);
      res
        .status(err.message.includes("permissions") ? 403 : 500)
        .json({ error: err.message });
    }
  },
);

// ═════════════════════════════════════════════════════════════════════════
// 3. GENERATE TAKEDOWN EMAIL — moderator/admin, returns email body
// ═════════════════════════════════════════════════════════════════════════
exports.generateTakedownEmail = functions.onRequest(
  { region: REGION },
  async (req, res) => {
    try {
      await validateModeratorOrAdmin(req);
      const { id, template } = req.body;

      if (!id) return res.status(400).json({ error: "id is required" });

      const snap = await db.doc(`takedown_requests/${id}`).get();
      if (!snap.exists) return res.status(404).json({ error: "Not found" });

      const data = snap.data();
      const url = data.url || "[URL]";
      const reason = data.reason || "[REASON]";
      const category = data.category || "[CATEGORY]";
      const evidence = data.evidence || "[EVIDENCE_LINKS]";
      const reporter = data.reporter || "DataFightCentral Safety Team";
      const date = new Date().toISOString().split("T")[0];

      let subject, body;

      switch (template || data.template || "Support") {
        case "DMCA":
          subject = "DMCA Takedown Notice";
          body = `To Whom It May Concern,\n\nPursuant to the Digital Millennium Copyright Act (17 U.S.C. § 512), I hereby provide notice of copyright infringement.\n\nInfringing Material Location:\n${url}\n\nDescription: ${reason}\n\nI have a good faith belief that the use of the material described above is not authorized by the copyright owner, its agent, or the law.\n\nI swear, under penalty of perjury, that the information in this notification is accurate.\n\nContact: DataFightCentral Safety Team\nEmail: safety@datafightcentral.com\nDate: ${date}`;
          break;

        case "Host Escalation":
          subject = "URGENT — Hosting Provider Content Escalation";
          body = `Dear Abuse Team,\n\nWe are reporting content hosted on your infrastructure that constitutes ${category} and poses an immediate safety risk.\n\nOffending URL: ${url}\n\nNature of Violation:\n${reason}\n\nEvidence:\n${evidence}\n\nWe request immediate investigation and removal under your Acceptable Use Policy. This matter has been logged for potential legal follow-up if unresolved within 48 hours.\n\nDataFightCentral Safety & Legal Team\nsafety@datafightcentral.com`;
          break;

        default: // Support
          subject = "Content Removal Request — DataFightCentral";
          body = `Dear Support Team,\n\nI am writing to request the removal of content hosted at:\n${url}\n\nThis content violates our platform's community guidelines and constitutes ${category}. The content is harmful because:\n${reason}\n\nEvidence of the violation is available at:\n${evidence}\n\nWe respectfully request prompt removal.\n\nThank you,\nDataFightCentral Safety Team\nBrisbane, Australia`;
          break;
      }

      res.json({ ok: true, subject, body, to: "[PLATFORM_ABUSE_EMAIL]" });
    } catch (err) {
      console.error("generateTakedownEmail error:", err);
      res.status(500).json({ error: err.message });
    }
  },
);
