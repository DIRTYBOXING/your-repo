"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.onPpvEventCreated = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
const db = admin.firestore();
exports.onPpvEventCreated = functions.firestore
    .document('ppv_events/{eventId}/events/{eventDoc}')
    .onCreate(async (snap, context) => {
    const eventId = context.params.eventId;
    const data = snap.data();
    if (!data)
        return;
    const statsRef = db.doc(`ppv_events/${eventId}/metrics/live`);
    const updates = { updated_at: admin.firestore.FieldValue.serverTimestamp() };
    if (data.funnel_step === 'gate_access_granted') {
        updates.total_entitlements = admin.firestore.FieldValue.increment(1);
        updates.purchases = admin.firestore.FieldValue.increment(1);
        updates.revenue = admin.firestore.FieldValue.increment(data.price || 0);
        if (data.promoter_id)
            updates[`affiliate_breakdown.${data.promoter_id}`] = admin.firestore.FieldValue.increment(data.price || 0);
        if (data.fighter_id)
            updates[`fighter_breakdown.${data.fighter_id}`] = admin.firestore.FieldValue.increment(data.price || 0);
    }
    else if (data.funnel_step === 'watch_start') {
        updates.live_viewers = admin.firestore.FieldValue.increment(1);
        updates.unique_viewers = admin.firestore.FieldValue.increment(1);
    }
    else if (data.funnel_step === 'watch_complete') {
        updates.live_viewers = admin.firestore.FieldValue.increment(-1);
    }
    else if (data.funnel_step === 'gate_access_denied') {
        updates.failed_entitlements_count = admin.firestore.FieldValue.increment(1);
    }
    await statsRef.set(updates, { merge: true });
});
//# sourceMappingURL=aggregator.js.map