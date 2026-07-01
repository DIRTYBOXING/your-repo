import * as admin from "firebase-admin";

// Initialize only once
if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

export async function getCampaign(
  campaignId: string,
): Promise<Record<string, unknown> | null> {
  const doc = await db.collection("campaigns").doc(campaignId).get();
  return doc.exists
    ? ({ id: doc.id, ...doc.data() } as Record<string, unknown>)
    : null;
}

export async function getMedia(
  mediaId: string,
): Promise<Record<string, unknown> | null> {
  if (!mediaId) return null;
  const doc = await db.collection("media_library").doc(mediaId).get();
  return doc.exists
    ? ({ id: doc.id, ...doc.data() } as Record<string, unknown>)
    : null;
}

export async function updateCampaignVariant(
  campaignId: string,
  variant: Record<string, unknown>,
) {
  const ref = db.collection("campaigns").doc(campaignId);
  await ref.update({
    variants: admin.firestore.FieldValue.arrayUnion(variant),
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  });
}
