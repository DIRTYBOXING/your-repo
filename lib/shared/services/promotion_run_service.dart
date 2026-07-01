import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/promotion_run_model.dart';

/// PromotionRunService — reads promotion execution records and DLQ from Firestore.
/// Collections:
///   `promotion_runs`  — live execution log (written by promotion worker)
///   `promotion_dlq`   — failed jobs pushed here after max retries
///
/// Write access is server-side only. Client is read-only + requeue.
class PromotionRunService {
  PromotionRunService._internal();
  static final PromotionRunService _instance = PromotionRunService._internal();
  factory PromotionRunService() => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Promotion Runs ────────────────────────────────────────────────────────

  /// Stream all runs for a given campaign, newest first.
  Stream<List<PromotionRunModel>> streamRunsForCampaign(
    String campaignId, {
    int limit = 50,
  }) {
    return _db
        .collection('promotion_runs')
        .where('campaignId', isEqualTo: campaignId)
        .orderBy('started_at', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (s) => s.docs.map(PromotionRunModel.fromFirestore).toList(),
        );
  }

  /// Stream runs filtered by status (e.g. show only errors).
  Stream<List<PromotionRunModel>> streamRunsByStatus(
    PromotionRunStatus status, {
    int limit = 100,
  }) {
    return _db
        .collection('promotion_runs')
        .where('status', isEqualTo: status.name)
        .orderBy('started_at', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (s) => s.docs.map(PromotionRunModel.fromFirestore).toList(),
        );
  }

  /// Fetch recent runs across all campaigns (for Command Centre summary).
  Future<List<PromotionRunModel>> getRecentRuns({int limit = 20}) async {
    final snap = await _db
        .collection('promotion_runs')
        .orderBy('started_at', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(PromotionRunModel.fromFirestore).toList();
  }

  // ── DLQ ──────────────────────────────────────────────────────────────────

  /// Stream failed jobs from promotion_dlq.
  Stream<List<Map<String, dynamic>>> streamDlq({int limit = 50}) {
    return _db
        .collection('promotion_dlq')
        .orderBy('failed_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Fetch DLQ count — used for Command Centre health badge.
  Future<int> getDlqCount() async {
    final agg = await _db.collection('promotion_dlq').count().get();
    return agg.count ?? 0;
  }

  /// Requeue a DLQ job: update its status to 'pending' and reset attempts.
  /// The worker polls for pending jobs and will pick this up.
  /// Note: actual re-insertion to Pub/Sub topic must be done server-side;
  /// this marks it for the next scheduled trigger sweep.
  Future<void> requeueDlqJob(String jobId) async {
    await _db.collection('promotion_dlq').doc(jobId).update({
      'status': 'pending',
      'attempts': 0,
      'requeued_at': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a DLQ job that you do not want reprocessed.
  Future<void> dismissDlqJob(String jobId) async {
    await _db.collection('promotion_dlq').doc(jobId).delete();
  }

  // ── Aggregates ────────────────────────────────────────────────────────────

  /// Summary stats for Command Centre health panel.
  Future<Map<String, int>> getHealthSummary() async {
    final runs = await getRecentRuns(limit: 100);
    int done = 0, error = 0, processing = 0, pending = 0;
    for (final r in runs) {
      switch (r.status) {
        case PromotionRunStatus.done:
          done++;
          break;
        case PromotionRunStatus.error:
          error++;
          break;
        case PromotionRunStatus.processing:
          processing++;
          break;
        case PromotionRunStatus.pending:
          pending++;
          break;
      }
    }
    final dlq = await getDlqCount();
    return {
      'done': done,
      'error': error,
      'processing': processing,
      'pending': pending,
      'dlq': dlq,
    };
  }
}
