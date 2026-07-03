const crypto = require("node:crypto");
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

const { db, FieldValue, REGION } = require("../config");

const OPERATOR_ACTION_SECRET_PARAM = defineSecret(
  "OPERATOR_ACTION_SHARED_SECRET",
);

const ACTION_MAP = {
  send_promo: "promo_send",
  create_clip: "create_clip",
  retry_sync: "retry_sync",
};

function resolveSharedSecret() {
  const envValue = (process.env.OPERATOR_ACTION_SHARED_SECRET || "").trim();
  if (envValue) {
    return envValue;
  }

  try {
    return (OPERATOR_ACTION_SECRET_PARAM.value() || "").trim();
  } catch {
    return "";
  }
}

function readRawBody(req) {
  if (req.rawBody && Buffer.isBuffer(req.rawBody)) {
    return req.rawBody;
  }

  return Buffer.from(JSON.stringify(req.body || {}));
}

function signaturesMatch(signature, expected) {
  try {
    const received = Buffer.from(signature, "hex");
    const target = Buffer.from(expected, "hex");
    if (received.length !== target.length) {
      return false;
    }
    return crypto.timingSafeEqual(received, target);
  } catch {
    return false;
  }
}

function buildBootstrapOperator(operatorId) {
  return {
    id: operatorId,
    name: operatorId,
    displayName: operatorId,
    bootstrap: true,
    disabled: false,
    callbackSecretId: null,
  };
}

async function loadOperator(operatorId) {
  const snap = await db.collection("operators").doc(operatorId).get();
  if (!snap.exists) {
    return null;
  }

  return {
    id: snap.id,
    ...snap.data(),
  };
}

exports.operatorAction = onRequest(
  {
    region: REGION,
    cors: true,
    secrets: [OPERATOR_ACTION_SECRET_PARAM],
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.set("Allow", "POST");
      return res.status(405).json({ error: "method_not_allowed" });
    }

    const operatorId = (req.get("X-Operator-Id") || "").trim();
    const signature = (req.get("X-Operator-Signature") || "").trim();
    const secret = resolveSharedSecret();

    if (!operatorId) {
      return res.status(400).json({ error: "missing_operator_id" });
    }
    if (!signature) {
      return res.status(400).json({ error: "missing_signature" });
    }
    if (!secret) {
      return res.status(503).json({ error: "operator_secret_not_configured" });
    }

    const rawBody = readRawBody(req);
    const expectedSignature = crypto
      .createHmac("sha256", secret)
      .update(rawBody)
      .digest("hex");

    if (!signaturesMatch(signature, expectedSignature)) {
      return res.status(401).json({ error: "invalid_signature" });
    }

    const storedOperator = await loadOperator(operatorId);
    if (storedOperator?.disabled === true) {
      return res.status(403).json({ error: "operator_not_authorized" });
    }
    const operator = storedOperator || buildBootstrapOperator(operatorId);

    const action = String(req.body?.action || "").trim();
    const mappedType = ACTION_MAP[action];
    if (!mappedType) {
      return res.status(400).json({ error: "unknown_action" });
    }

    const params =
      req.body?.params && typeof req.body.params === "object"
        ? req.body.params
        : {};
    const idempotencyKey = String(
      params.idempotencyKey || `${action}_${operatorId}_${Date.now()}`,
    );

    const duplicateSnap = await db
      .collection("jobs")
      .where("idempotencyKey", "==", idempotencyKey)
      .limit(1)
      .get();

    if (!duplicateSnap.empty) {
      const existing = duplicateSnap.docs[0];
      return res.json({
        accepted: true,
        duplicate: true,
        jobId: existing.id,
        status: existing.data().status || "queued",
      });
    }

    const jobRef = db.collection("jobs").doc();
    const now = FieldValue.serverTimestamp();
    const operatorAction = {
      actorId: operatorId,
      actorName: operator.displayName || operator.name || operatorId,
      action,
      params,
      requestedAt: now,
    };

    await jobRef.set({
      type: mappedType,
      status: "queued",
      payload: params,
      attempts: 0,
      lockedBy: null,
      lockedUntil: null,
      callbackSecretId: operator.callbackSecretId || null,
      idempotencyKey,
      operatorAction,
      createdAt: now,
      updatedAt: now,
    });

    await db.collection("operator_action_audit").add({
      operatorId,
      action,
      jobId: jobRef.id,
      idempotencyKey,
      createdAt: now,
      source: "operator_panel",
      bootstrapOperator: operator.bootstrap === true,
    });

    return res.json({
      accepted: true,
      jobId: jobRef.id,
      status: "queued",
    });
  },
);
