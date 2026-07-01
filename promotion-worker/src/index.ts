import * as admin from "firebase-admin";
import { PubSub } from "@google-cloud/pubsub";
import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import express, { Request, Response } from "express";
import https from "https";
import { Server } from "http";

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();
const pubsub = new PubSub();

const app = express();
app.use(express.json());

// Health check
app.get("/health", (_req: Request, res: Response) => {
  res.json({ status: "healthy", worker: "promotion-worker" });
});

// Pub/Sub push handler
app.post("/pubsub", async (req: Request, res: Response) => {
  try {
    const envelope = req.body as { message?: { data?: string } };
    if (!envelope?.message?.data) {
      res.status(400).json({ error: "missing message data" });
      return;
    }
    const payload = JSON.parse(
      Buffer.from(envelope.message.data, "base64").toString(),
    ) as Record<string, unknown>;

    await handleJob(payload);
    res.status(204).send();
  } catch (err) {
    console.error("[promotion-worker] unhandled error", err);
    await pushDlq({ error: String(err), payload: req.body });
    // Ack to prevent infinite redelivery; DLQ carries the failed payload
    res.status(200).json({ error: String(err) });
  }
});

async function handleJob(job: Record<string, unknown>): Promise<void> {
  const campaignId = job["campaignId"] as string | undefined;
  if (!campaignId) throw new Error("missing campaignId");

  // Idempotency check — skip if already written
  const existingSnap = await db
    .collection("promotion_runs")
    .where("campaign_id", "==", campaignId)
    .where("poster_url", "==", job["posterUrl"])
    .where("market", "==", job["market"])
    .limit(1)
    .get();
  if (!existingSnap.empty) {
    console.info(
      `[promotion-worker] duplicate job skipped for campaign ${campaignId}`,
    );
    return;
  }

  const campaignDoc = await db.collection("campaigns").doc(campaignId).get();
  if (!campaignDoc.exists) return;
  const campaign = campaignDoc.data() as Record<string, unknown>;
  if (campaign["status"] !== "active") return;

  const channel = (job["channel"] as string | undefined) ?? "site";
  if (channel === "site") {
    await publishToSite(job, campaign);
  } else if (channel === "facebook") {
    try {
      await publishToFacebook(job, campaign);
    } catch (fbErr) {
      console.error(JSON.stringify({
        metric: "facebook_publish_failure",
        channel: "facebook",
        campaignId,
        error: String(fbErr),
      }));
      throw fbErr;
    }
  }

  await db.collection("promotion_runs").add({
    campaign_id: campaignId,
    media_id: job["mediaId"] ?? null,
    market: job["market"] ?? "AU",
    channel,
    poster_url: job["posterUrl"] ?? null,
    caption: job["caption"] ?? null,
    status: "done",
    result: { delivered: true },
    started_at: admin.firestore.FieldValue.serverTimestamp(),
    finished_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.info(
    `[promotion-worker] published campaign ${campaignId} to ${channel}`,
  );
}

async function publishToSite(
  job: Record<string, unknown>,
  campaign: Record<string, unknown>,
): Promise<void> {
  await db.collection("site_feed").add({
    poster_url: job["posterUrl"] ?? null,
    caption: job["caption"] ?? null,
    market: job["market"] ?? "AU",
    campaign_id: campaign["id"] ?? null,
    campaign_name: campaign["name"] ?? null,
    channel: "site",
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/** Resolve a secret from Secret Manager and return the decoded string value. */
export async function getSecret(secretName: string): Promise<string> {
  const projectId = process.env["GOOGLE_CLOUD_PROJECT"] ?? process.env["GCLOUD_PROJECT"];
  if (!projectId) throw new Error("GOOGLE_CLOUD_PROJECT env var not set");
  const client = new SecretManagerServiceClient();
  const name = `projects/${projectId}/secrets/${secretName}/versions/latest`;
  const [version] = await client.accessSecretVersion({ name });
  const value = version.payload?.data?.toString();
  if (!value) throw new Error(`Secret '${secretName}' is empty`);
  return value;
}

/**
 * POST to the Facebook Graph API with exponential backoff on 429 / 5xx.
 * Returns the parsed JSON response body.
 */
export async function graphApiPost(
  path: string,
  formBody: string,
  maxAttempts = 4,
): Promise<Record<string, unknown>> {
  let attempt = 0;
  while (true) {
    attempt++;
    const result = await new Promise<{ status: number; body: Record<string, unknown> }>(
      (resolve, reject) => {
        const req = https.request(
          {
            hostname: "graph.facebook.com",
            path,
            method: "POST",
            headers: {
              "Content-Type": "application/x-www-form-urlencoded",
              "Content-Length": Buffer.byteLength(formBody),
            },
          },
          (res) => {
            let raw = "";
            res.on("data", (chunk: Buffer) => (raw += chunk.toString()));
            res.on("end", () => {
              try {
                resolve({ status: res.statusCode ?? 0, body: JSON.parse(raw) as Record<string, unknown> });
              } catch {
                reject(new Error(`Graph API non-JSON response (HTTP ${res.statusCode}): ${raw}`));
              }
            });
          },
        );
        req.on("error", reject);
        req.write(formBody);
        req.end();
      },
    );

    const { status, body } = result;
    const isTransient = status === 429 || status >= 500;

    if (!isTransient) {
      if (body["error"]) {
        throw new Error(`Graph API error: ${JSON.stringify(body["error"])}`);
      }
      return body;
    }

    if (attempt >= maxAttempts) {
      throw new Error(`Graph API transient failure after ${attempt} attempts (HTTP ${status})`);
    }

    const backoffMs = Math.min(1000 * 2 ** (attempt - 1), 16000);
    console.warn(
      `[promotion-worker] Graph API HTTP ${status} — retry ${attempt}/${maxAttempts} in ${backoffMs}ms`,
    );
    await new Promise((r) => setTimeout(r, backoffMs));
  }
}

export async function publishToFacebook(
  job: Record<string, unknown>,
  _campaign: Record<string, unknown>,
): Promise<void> {
  const projectId = process.env["GOOGLE_CLOUD_PROJECT"] ?? process.env["GCLOUD_PROJECT"];
  if (!projectId) {
    console.warn("[promotion-worker] GOOGLE_CLOUD_PROJECT not set — skipping Facebook publish");
    return;
  }

  const [pageId, pageToken] = await Promise.all([
    getSecret("facebook_page_id"),
    getSecret("facebook_page_token"),
  ]);

  const caption = (job["caption"] as string | undefined) ?? "";
  const imageUrl = job["posterUrl"] as string | undefined;

  const endpoint = imageUrl ? `/${pageId}/photos` : `/${pageId}/feed`;
  // Do NOT log pageToken or include it in any structured field
  const bodyParams: Record<string, string> = imageUrl
    ? { url: imageUrl, caption, access_token: pageToken }
    : { message: caption, access_token: pageToken };

  const formBody = new URLSearchParams(bodyParams).toString();
  const response = await graphApiPost(`/v19.0${endpoint}`, formBody);

  console.info(JSON.stringify({
    metric: "facebook_publish_success",
    channel: "facebook",
    campaignId: job["campaignId"] ?? null,
    postId: response["id"] ?? response["post_id"] ?? null,
    market: job["market"] ?? null,
  }));
}

async function pushDlq(payload: Record<string, unknown>): Promise<void> {
  try {
    await pubsub.topic("promotion_dlq").publishJSON(payload);
  } catch (dlqErr) {
    console.error("[promotion-worker] DLQ publish failed", dlqErr);
  }
}

const PORT = parseInt(process.env["PORT"] ?? "8080", 10);

export function startServer(port = PORT): Server {
  return app.listen(port, () => {
    console.info(`[promotion-worker] listening on :${port}`);
  });
}

if (require.main === module) {
  startServer();
}
