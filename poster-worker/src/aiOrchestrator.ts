// eslint-disable-next-line @typescript-eslint/no-require-imports
const sharp = require("sharp");
import { v4 as uuidv4 } from "uuid";
import { uploadPosterBuffer } from "./gcsUpload";

const AI_ENDPOINT = process.env["AI_ENDPOINT"] ?? "http://localhost:8000";
const TEMPLATE_BASE_URL =
  process.env["TEMPLATE_BASE_URL"] ??
  "https://storage.googleapis.com/datafightcentral.appspot.com/templates/posters";

async function callCaptionModel(
  prompt: string,
): Promise<{ variants?: string[] } | null> {
  try {
    const res = await globalThis.fetch(`${AI_ENDPOINT}/caption`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ prompt }),
    });
    return res.ok ? ((await res.json()) as { variants?: string[] }) : null;
  } catch {
    return null;
  }
}

async function composePoster(
  templateUrl: string,
  fighterImageUrl: string | null,
  _headline: string,
): Promise<Buffer> {
  const templateRes = await globalThis.fetch(templateUrl);
  const templateBuf = Buffer.from(await templateRes.arrayBuffer());
  let image = sharp(templateBuf);
  if (fighterImageUrl) {
    try {
      const fighterRes = await globalThis.fetch(fighterImageUrl);
      const fighterBuf = Buffer.from(await fighterRes.arrayBuffer());
      image = image.composite([
        { input: fighterBuf, gravity: "center", blend: "over" },
      ]);
    } catch (err) {
      console.warn("[composePoster] fighter image fetch failed", err);
    }
  }
  return image.resize(1200, 1600).png().toBuffer();
}

interface PosterJobContext {
  campaign: Record<string, unknown>;
  media: Record<string, unknown> | null;
  templateRef: string;
  market: string;
}

export interface PosterVariant {
  id: string;
  posterUrl: string;
  storagePath?: string;
  caption: string;
  predictedConversion: number;
}

export async function generatePosterVariants(
  ctx: PosterJobContext,
): Promise<PosterVariant[]> {
  const campaign = ctx.campaign;
  const media = ctx.media ?? {};
  const fighters = (media["fighters"] as string[] | undefined) ?? [];
  const campaignName =
    typeof campaign["name"] === "string" && campaign["name"].trim().length > 0
      ? campaign["name"]
      : "DFC Campaign";
  const headlinePrompt = `Create 3 short promotional headlines for ${campaignName} featuring ${fighters.join(" vs ")} for market ${ctx.market}`;

  const captions = await callCaptionModel(headlinePrompt);
  const templateUrl = `${TEMPLATE_BASE_URL}/${ctx.templateRef}.png`;

  const variants: PosterVariant[] = [];
  for (let i = 0; i < 3; i++) {
    const headline = captions?.variants?.[i] ?? `${campaignName} Live`;
    const posterBuffer = await composePoster(
      templateUrl,
      (media["thumbnail_url"] as string | null) ?? null,
      headline,
    );
    const { url: posterUrl, objectName } =
      await uploadPosterBuffer(posterBuffer);
    variants.push({
      id: uuidv4(),
      posterUrl,
      storagePath: objectName,
      caption: headline,
      predictedConversion: Math.random() * 0.3 + 0.5,
    });
  }
  return variants;
}
