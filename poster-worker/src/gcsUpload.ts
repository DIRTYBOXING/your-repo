import { Storage } from "@google-cloud/storage";
import { v4 as uuidv4 } from "uuid";

if (!process.env.ASSETS_BUCKET) {
  throw new Error("ASSETS_BUCKET env var is required");
}

const storage = new Storage();
const bucketName = process.env.ASSETS_BUCKET;

export async function uploadPosterBuffer(
  buffer: Buffer,
  contentType = "image/png",
): Promise<{ objectName: string; url: string; storagePath: string }> {
  const id = uuidv4();
  const objectName = `posters/${id}.png`;
  const bucket = storage.bucket(bucketName);
  const file = bucket.file(objectName);

  await file.save(buffer, {
    metadata: { contentType },
    resumable: false,
    public: false,
  });

  const [url] = await file.getSignedUrl({
    version: "v4",
    action: "read",
    expires: Date.now() + 1000 * 60 * 60,
  });

  return { objectName, url, storagePath: `gs://${bucketName}/${objectName}` };
}
