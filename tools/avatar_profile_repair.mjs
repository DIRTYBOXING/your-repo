import fs from "fs/promises";
import process from "process";
import { randomUUID } from "crypto";
import admin from "firebase-admin";

function parseArgs(argv) {
  const args = {
    write: false,
    clearMissing: false,
    limit: 0,
    projectId: process.env.FIREBASE_PROJECT || "datafightcentral",
    bucket:
      process.env.FIREBASE_STORAGE_BUCKET ||
      "datafightcentral.firebasestorage.app",
    serviceAccountPath:
      process.env.SERVICE_ACCOUNT_PATH ||
      process.env.GOOGLE_APPLICATION_CREDENTIALS ||
      "",
  };

  for (let index = 0; index < argv.length; index++) {
    const arg = argv[index];
    switch (arg) {
      case "--write":
        args.write = true;
        break;
      case "--clear-missing":
        args.clearMissing = true;
        break;
      case "--limit":
        args.limit = Number(argv[index + 1] || "0");
        index += 1;
        break;
      case "--projectId":
        args.projectId = argv[index + 1] || args.projectId;
        index += 1;
        break;
      case "--bucket":
        args.bucket = argv[index + 1] || args.bucket;
        index += 1;
        break;
      case "--service-account":
        args.serviceAccountPath = argv[index + 1] || args.serviceAccountPath;
        index += 1;
        break;
      default:
        break;
    }
  }

  return args;
}

async function initAdmin({ projectId, bucket, serviceAccountPath }) {
  let credential;
  if (serviceAccountPath) {
    try {
      const key = JSON.parse(await fs.readFile(serviceAccountPath, "utf8"));
      credential = admin.credential.cert(key);
      console.log(`Using service account: ${serviceAccountPath}`);
    } catch (error) {
      console.warn(
        `Failed to read service account at ${serviceAccountPath}, falling back to ADC: ${error.message}`,
      );
    }
  }

  if (!credential) {
    credential = admin.credential.applicationDefault();
    console.log("Using Application Default Credentials");
  }

  admin.initializeApp({
    credential,
    projectId,
    storageBucket: bucket,
  });

  return {
    db: admin.firestore(),
    auth: admin.auth(),
    bucket: admin.storage().bucket(bucket),
  };
}

function resolvePhotoValue(data) {
  const canonical = String(data.photoUrl ?? "").trim();
  const legacy = String(data.photoURL ?? "").trim();
  return canonical || legacy;
}

function parseStorageUrl(rawUrl) {
  if (!rawUrl) return null;
  let url;
  try {
    url = new URL(rawUrl);
  } catch {
    return null;
  }

  if (url.hostname === "firebasestorage.googleapis.com") {
    const match = url.pathname.match(/^\/v0\/b\/([^/]+)\/o\/(.+)$/);
    if (!match) return null;
    return {
      bucket: decodeURIComponent(match[1]),
      objectPath: decodeURIComponent(match[2]),
      token: url.searchParams.get("token") || "",
    };
  }

  if (url.hostname === "storage.googleapis.com") {
    const parts = url.pathname.split("/").filter(Boolean);
    if (parts.length < 2) return null;
    return {
      bucket: decodeURIComponent(parts[0]),
      objectPath: decodeURIComponent(parts.slice(1).join("/")),
      token: "",
    };
  }

  return null;
}

function buildDownloadUrl(bucket, objectPath, token) {
  const encodedPath = encodeURIComponent(objectPath).replace(/%2F/g, "%2F");
  return `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${encodedPath}?alt=media&token=${token}`;
}

async function ensureDownloadToken(file, metadata, write) {
  const existingTokens = String(
    metadata?.metadata?.firebaseStorageDownloadTokens ?? "",
  )
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);

  if (existingTokens.length > 0) {
    return existingTokens[0];
  }

  if (!write) {
    return "DRY_RUN_TOKEN_REQUIRED";
  }

  const token = randomUUID();
  await file.setMetadata({
    metadata: {
      ...(metadata?.metadata ?? {}),
      firebaseStorageDownloadTokens: token,
    },
  });
  return token;
}

async function updateDependents(db, userId, displayName, photoUrl) {
  const batch = db.batch();

  const conversations = await db
    .collection("conversations")
    .where("participants", "array-contains", userId)
    .get();
  for (const doc of conversations.docs) {
    batch.set(
      doc.ref,
      {
        [`participantNames.${userId}`]: displayName,
        [`participantPhotoUrls.${userId}`]: photoUrl,
      },
      { merge: true },
    );
  }

  const userConnections = await db
    .collection("connections")
    .where("userId", "==", userId)
    .get();
  for (const doc of userConnections.docs) {
    batch.set(
      doc.ref,
      { userName: displayName, userPhotoUrl: photoUrl },
      { merge: true },
    );
  }

  const friendConnections = await db
    .collection("connections")
    .where("friendId", "==", userId)
    .get();
  for (const doc of friendConnections.docs) {
    batch.set(
      doc.ref,
      { friendName: displayName, friendPhotoUrl: photoUrl },
      { merge: true },
    );
  }

  const pendingRequests = await db
    .collection("friend_requests")
    .where("senderId", "==", userId)
    .where("status", "==", "pending")
    .get();
  for (const doc of pendingRequests.docs) {
    batch.set(
      doc.ref,
      { senderName: displayName, senderPhotoUrl: photoUrl },
      { merge: true },
    );
  }

  await batch.commit();
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const { db, auth, bucket } = await initAdmin(args);

  let query = db.collection("users");
  if (args.limit > 0) {
    query = query.limit(args.limit);
  }

  const snapshot = await query.get();
  const summary = {
    scanned: 0,
    repairedUsers: 0,
    canonicalizedFields: 0,
    regeneratedTokens: 0,
    missingStorageObjects: 0,
    clearedMissing: 0,
    externalUrlsKept: 0,
    errors: 0,
  };

  for (const doc of snapshot.docs) {
    summary.scanned += 1;
    const data = doc.data();
    const userId = doc.id;
    const displayName = String(data.displayName ?? data.name ?? "User");
    const currentPhoto = resolvePhotoValue(data);
    const parsed = parseStorageUrl(currentPhoto);
    let targetPhoto = currentPhoto;
    let needsWrite = false;
    let regeneratedToken = false;

    try {
      if (parsed && parsed.bucket === args.bucket) {
        const file = bucket.file(parsed.objectPath);
        const [exists] = await file.exists();

        if (!exists) {
          summary.missingStorageObjects += 1;
          if (args.clearMissing) {
            targetPhoto = "";
            needsWrite = true;
            summary.clearedMissing += 1;
          }
        } else {
          const [metadata] = await file.getMetadata();
          const token = await ensureDownloadToken(file, metadata, args.write);
          if (token === "DRY_RUN_TOKEN_REQUIRED") {
            regeneratedToken = true;
          } else if (!parsed.token || parsed.token !== token) {
            regeneratedToken = true;
            targetPhoto = buildDownloadUrl(
              parsed.bucket,
              parsed.objectPath,
              token,
            );
            needsWrite = true;
          } else {
            const canonicalUrl = buildDownloadUrl(
              parsed.bucket,
              parsed.objectPath,
              token,
            );
            if (currentPhoto !== canonicalUrl) {
              targetPhoto = canonicalUrl;
              needsWrite = true;
            }
          }
        }
      } else if (currentPhoto) {
        summary.externalUrlsKept += 1;
      }

      if (
        (data.photoUrl ?? "") !== targetPhoto ||
        (data.photoURL ?? "") !== targetPhoto
      ) {
        needsWrite = true;
        summary.canonicalizedFields += 1;
      }

      if (!needsWrite) {
        continue;
      }

      if (!args.write) {
        console.log(`[DRY RUN] ${userId} -> ${targetPhoto || "<cleared>"}`);
        if (regeneratedToken) {
          console.log(`  token regeneration needed for ${userId}`);
        }
        summary.repairedUsers += 1;
        if (regeneratedToken) summary.regeneratedTokens += 1;
        continue;
      }

      await doc.ref.set(
        {
          photoUrl: targetPhoto,
          photoURL: targetPhoto,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      await updateDependents(db, userId, displayName, targetPhoto);

      try {
        await auth.updateUser(userId, { photoURL: targetPhoto || null });
      } catch (error) {
        console.warn(
          `Auth photoURL update skipped for ${userId}: ${error.message}`,
        );
      }

      summary.repairedUsers += 1;
      if (regeneratedToken) summary.regeneratedTokens += 1;
      console.log(`[WRITE] ${userId} -> ${targetPhoto || "<cleared>"}`);
    } catch (error) {
      summary.errors += 1;
      console.error(`Failed to process ${userId}: ${error.message}`);
    }
  }

  console.log("\nAvatar repair summary");
  console.table(summary);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
