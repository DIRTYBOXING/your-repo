import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
admin.initializeApp();
const db = admin.firestore();

export const onPpvEventCreated = functions.firestore
  .document('ppv_events/{eventId}/events/{eventDoc}')
  .onCreate(async (snap, context) => {
    const eventId = context.params.eventId;
    const data = snap.data();
    if (!data) return;

    const statsRef = db.doc(`ppv_events/${eventId}/metrics/live`);
    const updates: any = { updated_at: admin.firestore.FieldValue.serverTimestamp() };

    if (data.funnel_step === 'gate_access_granted') {
      updates.total_entitlements = admin.firestore.FieldValue.increment(1);
      updates.purchases = admin.firestore.FieldValue.increment(1);
      updates.revenue = admin.firestore.FieldValue.increment(data.price || 0);
      if (data.promoter_id) updates[`affiliate_breakdown.${data.promoter_id}`] = admin.firestore.FieldValue.increment(data.price || 0);
      if (data.fighter_id) updates[`fighter_breakdown.${data.fighter_id}`] = admin.firestore.FieldValue.increment(data.price || 0);
    } else if (data.funnel_step === 'watch_start') {
      updates.live_viewers = admin.firestore.FieldValue.increment(1);
      updates.unique_viewers = admin.firestore.FieldValue.increment(1);
    } else if (data.funnel_step === 'watch_complete') {
      updates.live_viewers = admin.firestore.FieldValue.increment(-1);
    } else if (data.funnel_step === 'gate_access_denied') {
      updates.failed_entitlements_count = admin.firestore.FieldValue.increment(1);
    }

    await statsRef.set(updates, { merge: true });
  });
