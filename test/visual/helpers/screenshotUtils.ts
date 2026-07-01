import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";

import { Page } from "@playwright/test";

export async function saveRouteScreenshot(
  page: Page,
  routeName: string,
  projectName: string,
): Promise<{ body: Buffer; bytes: number; hash: string; filePath: string }> {
  const outDir = path.resolve(process.cwd(), "test-results", "screenshots");
  fs.mkdirSync(outDir, { recursive: true });

  const safeRoute = routeName.replace(/[^a-zA-Z0-9-_]/g, "_").slice(0, 80);
  const safeProject = projectName.replace(/[^a-zA-Z0-9-_]/g, "_").slice(0, 40);
  const fileName = `${safeRoute}-${safeProject}-${Date.now()}.png`;
  const filePath = path.join(outDir, fileName);

  const body = (await page.screenshot({ animations: "disabled", fullPage: true })) as Buffer;
  fs.writeFileSync(filePath, body);

  const hash = crypto.createHash("sha256").update(body).digest("hex");
  return { body, bytes: body.byteLength, hash, filePath };
}
