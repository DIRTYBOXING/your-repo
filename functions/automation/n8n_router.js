const { onCall, onRequest } = require("firebase-functions/v2/https");
const { admin, db, REGION } = require("../config");
const { executeContentBrain } = require("../content/content_brain");

const N8N_API_KEY = process.env.N8N_API_KEY || "";
const N8N_BASE_URL = process.env.N8N_BASE_URL || "";
const N8N_EVENT_SEED_URL = process.env.N8N_WEBHOOK_URL || "";
const N8N_ACTIVATION_URL = process.env.N8N_PROMOTE_WEBHOOK_URL || "";
const N8N_POST_FIGHT_URL = process.env.N8N_POST_FIGHT_WEBHOOK_URL || "";

function workflowRunRef(requestId) {
  return db.collection("workflow_runs").doc(requestId);
}

async function writeWorkflowRun(requestId, payload) {
  await workflowRunRef(requestId).set(
    {
      requestId,
      ...payload,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

function buildRequestId(prefix) {
  return `${prefix}_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
}

function callbackUrl() {
  return `https://${REGION}-datafightcentral.cloudfunctions.net/n8nWorkflowCallback`;
}

function buildWebhookUrl(path) {
  if (!N8N_BASE_URL) {
    return "";
  }

  const normalizedBaseUrl = N8N_BASE_URL.replace(/\/$/, "");
  const normalizedPath = path.startsWith("/") ? path : `/${path}`;
  return `${normalizedBaseUrl}${normalizedPath}`;
}

function resolveWorkflowConfig(workflowType) {
  switch (workflowType) {
    case "event_seed":
      return {
        webhookUrl: N8N_EVENT_SEED_URL,
        source: "triggerN8N.event_seed",
      };
    case "activation":
      return {
        webhookUrl: N8N_ACTIVATION_URL,
        source: "triggerN8N.activation",
      };
    case "post_fight":
      return {
        webhookUrl: N8N_POST_FIGHT_URL,
        source: "triggerN8N.post_fight",
      };
    case "ppv_event":
      return {
        webhookUrl: buildWebhookUrl("/webhook/ppv-event"),
        source: "triggerN8N.ppv_event",
      };
    case "user_register":
      return {
        webhookUrl: buildWebhookUrl("/webhook/user-register"),
        source: "triggerN8N.user_register",
      };
    case "payment":
      return {
        webhookUrl: buildWebhookUrl("/webhook/payment"),
        source: "triggerN8N.payment",
      };
    case "prediction":
      return {
        webhookUrl: buildWebhookUrl("/webhook/ppv-prediction"),
        source: "triggerN8N.prediction",
      };
    default:
      return { webhookUrl: "", source: "triggerN8N.unknown" };
  }
}

const triggerN8N = onCall(
  {
    region: REGION,
    memory: "512MiB",
    timeoutSeconds: 120,
  },
  async (request) => {
    const {
      workflowType,
      payload = {},
      expectCallback = false,
    } = request.data || {};
    if (!workflowType) {
      return { status: "error", message: "workflowType is required" };
    }

    const allowsAnonymousCaller = workflowType === "user_register";
    if (!request.auth && !allowsAnonymousCaller) {
      return { status: "error", message: "Authentication required" };
    }

    if (workflowType === "content_brain") {
      return executeContentBrain({
        auth: request.auth,
        data: payload,
      });
    }

    const { webhookUrl, source } = resolveWorkflowConfig(workflowType);
    if (!webhookUrl) {
      return {
        status: "error",
        message: `No webhook configured for workflowType ${workflowType}`,
      };
    }

    const requestId = payload.requestId || buildRequestId(workflowType);
    const eventId = payload.eventId || payload.eventData?.eventId || null;

    await writeWorkflowRun(requestId, {
      workflowType,
      status: "pending",
      attemptCount: 1,
      userId: request.auth?.uid || payload.userId || null,
      eventId,
      source,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastError: null,
      requestPayloadPreview: JSON.stringify(payload).slice(0, 500),
    });

    try {
      const response = await fetch(webhookUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          ...(N8N_API_KEY ? { Authorization: `Bearer ${N8N_API_KEY}` } : {}),
        },
        body: JSON.stringify({
          ...payload,
          workflowType,
          requestId,
          callbackUrl: callbackUrl(),
        }),
      });

      const responseText = await response.text();
      let responseJson = null;
      try {
        responseJson = responseText ? JSON.parse(responseText) : null;
      } catch {
        responseJson = null;
      }

      if (!response.ok) {
        const message = `n8n returned ${response.status}: ${responseText.slice(0, 500)}`;
        await writeWorkflowRun(requestId, {
          status: "failed",
          lastError: message,
        });
        return { status: "error", message, requestId };
      }

      await writeWorkflowRun(requestId, {
        status: expectCallback ? "processing" : "completed",
        dispatchStatus: response.status,
        dispatchedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastCallbackAt: expectCallback
          ? null
          : admin.firestore.FieldValue.serverTimestamp(),
        responsePreview: responseJson || responseText.slice(0, 500),
      });

      return {
        status: "success",
        requestId,
        workflowType,
        response: responseJson || responseText,
        pendingCallback: expectCallback,
      };
    } catch (error) {
      await writeWorkflowRun(requestId, {
        status: "error",
        lastError: error.message,
      });
      return { status: "error", message: error.message, requestId };
    }
  },
);

const n8nWorkflowCallback = onRequest(
  {
    region: REGION,
    memory: "256MiB",
    timeoutSeconds: 30,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "POST only" });
      return;
    }

    const {
      requestId,
      workflowType,
      status = "completed",
      lastError = null,
      result = null,
      eventId = null,
    } = req.body || {};

    if (!requestId) {
      res.status(400).json({ error: "requestId required" });
      return;
    }

    const runSnap = await workflowRunRef(requestId).get();
    if (!runSnap.exists) {
      res.status(404).json({ error: "workflow run not found" });
      return;
    }

    await writeWorkflowRun(requestId, {
      workflowType: workflowType || runSnap.data().workflowType || "unknown",
      status,
      eventId: eventId || runSnap.data().eventId || null,
      result,
      lastError,
      lastCallbackAt: admin.firestore.FieldValue.serverTimestamp(),
      completedAt:
        status === "completed"
          ? admin.firestore.FieldValue.serverTimestamp()
          : null,
    });

    res.status(200).json({ status: "ok", requestId });
  },
);

module.exports = {
  triggerN8N,
  n8nWorkflowCallback,
};
