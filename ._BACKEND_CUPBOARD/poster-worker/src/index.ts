import express, { Request, Response } from "express";
import { generatePosterVariants } from "./aiOrchestrator";
import { getCampaign, getMedia, updateCampaignVariant } from "./db";
import { publish } from "./queue";

const app = express();
app.use(express.json());

// Health check for Cloud Run autoscaler
app.get("/health", (_req: Request, res: Response) => {
  res.json({ status: "healthy", worker: "poster-worker" });
});

// Pub/Sub push handler — Cloud Run receives messages via HTTP POST
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
    console.error("[poster-worker] unhandled error", err);
    // Return 200 to ack the message and avoid redelivery of bad payloads
    res.status(200).json({ error: String(err) });
  }
});

async function handleJob(job: Record<string, unknown>): Promise<void> {
  const campaignId = job["campaignId"] as string | undefined;
  if (!campaignId) throw new Error("missing campaignId");

  const campaign = await getCampaign(campaignId);
  if (!campaign || campaign["status"] !== "active") return;

  const mediaId = job["mediaId"] as string | undefined;
  const media = mediaId ? await getMedia(mediaId) : null;

  const variants = await generatePosterVariants({
    campaign,
    media,
    templateRef: (job["templateRef"] as string | undefined) ?? "default",
    market: (job["market"] as string | undefined) ?? "AU",
  });

  const best = variants.sort(
    (a, b) => b.predictedConversion - a.predictedConversion,
  )[0];
  await updateCampaignVariant(
    campaign["id"] as string,
    best as unknown as Record<string, unknown>,
  );

  await publish("promotion_jobs", {
    campaignId: campaign["id"],
    mediaId: (media as Record<string, unknown> | null)?.["media_id"] ?? null,
    posterUrl: best.posterUrl,
    caption: best.caption,
    market: job["market"] ?? "AU",
    channel: "site",
  });

  console.info(
    `[poster-worker] generated poster for campaign ${campaignId}, market ${job["market"]}`,
  );
}

const PORT = parseInt(process.env["PORT"] ?? "8080", 10);
app.listen(PORT, () => {
  console.info(`[poster-worker] listening on :${PORT}`);
});
