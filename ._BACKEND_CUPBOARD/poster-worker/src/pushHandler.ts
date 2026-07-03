// poster-worker/src/pushHandler.ts
import express, { Request, Response } from "express";
import bodyParser from "body-parser";

// handleJob is the existing job processor from index.ts — re-export it there or import here
// If building as a separate entrypoint, move handleJob to a shared worker.ts module
let handleJob: (payload: Record<string, unknown>) => Promise<void>;

// Dynamic import to avoid circular deps when used alongside index.ts
(async () => {
  const mod = await import("./index");
  handleJob = (mod as any).handleJob;
})();

const app = express();
app.use(bodyParser.json({ limit: "1mb" }));

// Pub/Sub push: POST body = { message: { data: '<base64>' } }
app.post("/pubsub/push", async (req: Request, res: Response) => {
  try {
    const envelope = req.body as { message?: { data?: string } };
    if (!envelope?.message) {
      res.status(400).send("Bad Request: no message");
      return;
    }
    const data = envelope.message.data
      ? Buffer.from(envelope.message.data, "base64").toString()
      : "{}";
    const payload = JSON.parse(data) as Record<string, unknown>;
    await handleJob(payload);
    res.status(200).send("OK");
  } catch (err) {
    console.error("[pushHandler] error", err);
    // 200 to ACK and avoid infinite Pub/Sub retries for bad payloads
    res.status(200).send("OK");
  }
});

app.get("/health", (_req: Request, res: Response) =>
  res.json({ status: "healthy", worker: "poster-push-handler" }),
);

const port = Number.parseInt(process.env["PORT"] ?? "8080", 10);
app.listen(port, () =>
  console.log(`[poster-push-handler] listening on :${port}`),
);
