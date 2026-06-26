import 'package:cloud_firestore/cloud_firestore.dart';

/// ContentPipelineService — TikTok-grade content pipeline.
/// Stages: Intake → Transform → Queue → Distribute → Track
/// Each piece of content flows through these stages with status tracking.
class ContentPipelineService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'content_pipeline';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _db.collection(_collection);

  // ── Pipeline Stages ──────────────────────────────────────────────

  static const stages = [
    'intake',
    'transform',
    'queue',
    'distribute',
    'track',
    'complete',
    'failed',
  ];

  // ── INTAKE — Accept raw content into the pipeline ─────────────

  Future<String> intake({
    required String contentType, // post, event, news, social, swarm
    required String title,
    required String body,
    String? imageUrl,
    String? videoUrl,
    String? sourceId,
    String? createdBy,
    List<String> targetPlatforms = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    final doc = await _ref.add({
      'stage': 'intake',
      'contentType': contentType,
      'title': title,
      'body': body,
      'imageUrl': ?imageUrl,
      'videoUrl': ?videoUrl,
      'sourceId': ?sourceId,
      'createdBy': createdBy ?? 'system',
      'targetPlatforms': targetPlatforms,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'stageHistory': [
        {'stage': 'intake', 'timestamp': DateTime.now().toIso8601String()},
      ],
      'retryCount': 0,
      'error': null,
    });
    return doc.id;
  }

  // ── ADVANCE STAGE — Move content to the next pipeline stage ───

  Future<void> advanceStage(
    String docId,
    String newStage, {
    Map<String, dynamic>? extraFields,
  }) async {
    final update = <String, dynamic>{
      'stage': newStage,
      'updatedAt': FieldValue.serverTimestamp(),
      'stageHistory': FieldValue.arrayUnion([
        {'stage': newStage, 'timestamp': DateTime.now().toIso8601String()},
      ]),
    };
    if (extraFields != null) update.addAll(extraFields);
    await _ref.doc(docId).update(update);
  }

  // ── TRANSFORM — Add transformed content variants ──────────────

  Future<void> addTransformResult(
    String docId, {
    required Map<String, String> platformVariants,
    int? hypeScore,
    List<String>? hashtags,
  }) async {
    await advanceStage(
      docId,
      'transform',
      extraFields: {
        'platformVariants': platformVariants,
        'hypeScore': ?hypeScore,
        'hashtags': ?hashtags,
      },
    );
  }

  // ── QUEUE — Mark as ready for distribution ────────────────────

  Future<void> enqueue(String docId, {DateTime? scheduledAt}) async {
    await advanceStage(
      docId,
      'queue',
      extraFields: {
        if (scheduledAt != null) 'scheduledAt': Timestamp.fromDate(scheduledAt),
        'queuedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  // ── DISTRIBUTE — Mark as pushed to platforms ──────────────────

  Future<void> markDistributed(
    String docId, {
    Map<String, String>? deliveryResults,
  }) async {
    await advanceStage(
      docId,
      'distribute',
      extraFields: {
        'distributedAt': FieldValue.serverTimestamp(),
        'deliveryResults': ?deliveryResults,
      },
    );
  }

  // ── TRACK — Record engagement metrics ─────────────────────────

  Future<void> recordMetrics(
    String docId, {
    int impressions = 0,
    int clicks = 0,
    int shares = 0,
    int likes = 0,
  }) async {
    await _ref.doc(docId).update({
      'stage': 'track',
      'metrics.impressions': FieldValue.increment(impressions),
      'metrics.clicks': FieldValue.increment(clicks),
      'metrics.shares': FieldValue.increment(shares),
      'metrics.likes': FieldValue.increment(likes),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── COMPLETE — Finalize pipeline item ─────────────────────────

  Future<void> complete(String docId) => advanceStage(docId, 'complete');

  // ── FAIL — Mark as failed with error ──────────────────────────

  Future<void> fail(String docId, String error) async {
    await _ref.doc(docId).update({
      'stage': 'failed',
      'error': error,
      'retryCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
      'stageHistory': FieldValue.arrayUnion([
        {
          'stage': 'failed',
          'timestamp': DateTime.now().toIso8601String(),
          'error': error,
        },
      ]),
    });
  }

  // ── RETRY — Move failed item back to intake ──────────────────

  Future<void> retry(String docId) => advanceStage(docId, 'intake');

  // ── QUERIES ───────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> streamByStage(
    String stage, {
    int limit = 50,
  }) {
    return _ref
        .where('stage', isEqualTo: stage)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  Future<Map<String, int>> getStageCounts() async {
    final counts = <String, int>{};
    for (final stage in stages) {
      final snap = await _ref.where('stage', isEqualTo: stage).count().get();
      counts[stage] = snap.count ?? 0;
    }
    return counts;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAll({int limit = 100}) {
    return _ref.orderBy('createdAt', descending: true).limit(limit).snapshots();
  }

  // ── FULL PIPELINE RUN (convenience) ───────────────────────────

  /// Runs a content piece through the full pipeline in one call.
  /// Each stage writes to Firestore so the dashboard can track progress.
  Future<String> runFullPipeline({
    required String contentType,
    required String title,
    required String body,
    String? imageUrl,
    List<String> targetPlatforms = const [],
    Map<String, String> platformVariants = const {},
    int hypeScore = 50,
  }) async {
    // 1. Intake
    final docId = await intake(
      contentType: contentType,
      title: title,
      body: body,
      imageUrl: imageUrl,
      targetPlatforms: targetPlatforms,
    );

    // 2. Transform
    await addTransformResult(
      docId,
      platformVariants: platformVariants,
      hypeScore: hypeScore,
    );

    // 3. Queue
    await enqueue(docId);

    return docId;
    // Steps 4-5 (distribute + track) happen when social engine fires
  }
}
