import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ABTestService — Real A/B experiment framework.
/// Collection: `ab_experiments`
/// Each experiment has variants, traffic allocation, and result tracking.
class ABTestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'ab_experiments';
  static const String _resultsCollection = 'ab_results';

  CollectionReference<Map<String, dynamic>> get _experiments =>
      _db.collection(_collection);

  CollectionReference<Map<String, dynamic>> get _results =>
      _db.collection(_resultsCollection);

  final _random = Random();

  // ── CREATE EXPERIMENT ─────────────────────────────────────────

  /// Create a new A/B experiment
  Future<String> createExperiment({
    required String name,
    required String description,
    required List<ABVariant> variants,
    String? targetAudience,
    double trafficPercentage = 100, // % of users to include
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    assert(variants.length >= 2, 'Need at least 2 variants for A/B test');

    // Normalize weights to sum to 100
    final totalWeight = variants.fold<double>(
      0,
      (total, v) => total + v.weight,
    );
    final normalizedVariants = variants
        .map(
          (v) => {
            'id': v.id,
            'name': v.name,
            'weight': (v.weight / totalWeight * 100).round(),
            'description': v.description,
            'config': v.config,
          },
        )
        .toList();

    final doc = await _experiments.add({
      'name': name,
      'description': description,
      'variants': normalizedVariants,
      'targetAudience': targetAudience,
      'trafficPercentage': trafficPercentage,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'startDate': startDate != null ? Timestamp.fromDate(startDate) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
      'totalParticipants': 0,
      'metrics': {},
    });
    return doc.id;
  }

  // ── ASSIGN VARIANT ────────────────────────────────────────────

  /// Assign a user to a variant based on weighted random selection.
  /// Returns the variant ID. Persists the assignment in ab_results.
  Future<String> assignVariant({
    required String experimentId,
    required String userId,
  }) async {
    // Check for existing assignment
    final existing = await _results
        .where('experimentId', isEqualTo: experimentId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.data()['variantId'] as String;
    }

    // Get experiment
    final expDoc = await _experiments.doc(experimentId).get();
    if (!expDoc.exists) throw Exception('Experiment not found');
    final expData = expDoc.data()!;

    // Check if experiment is active
    if (expData['status'] != 'active') {
      throw Exception('Experiment is not active');
    }

    // Weighted random selection
    final variants = (expData['variants'] as List<dynamic>)
        .map((v) => v as Map<String, dynamic>)
        .toList();

    final roll = _random.nextInt(100);
    int cumulative = 0;
    String selectedVariant = variants.first['id'] as String;

    for (final v in variants) {
      cumulative += (v['weight'] as int?) ?? 0;
      if (roll < cumulative) {
        selectedVariant = v['id'] as String;
        break;
      }
    }

    // Record assignment
    await _results.add({
      'experimentId': experimentId,
      'userId': userId,
      'variantId': selectedVariant,
      'assignedAt': FieldValue.serverTimestamp(),
      'converted': false,
      'engagement': 0,
      'events': [],
    });

    // Increment participant count
    await _experiments.doc(experimentId).update({
      'totalParticipants': FieldValue.increment(1),
    });

    return selectedVariant;
  }

  // ── RECORD RESULT ─────────────────────────────────────────────

  /// Record a conversion or engagement event for a user in an experiment
  Future<void> recordResult({
    required String experimentId,
    required String userId,
    required String eventType, // conversion, click, view, share, purchase
    double value = 1.0,
    Map<String, dynamic>? metadata,
  }) async {
    final assignmentSnap = await _results
        .where('experimentId', isEqualTo: experimentId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (assignmentSnap.docs.isEmpty) return; // User not in experiment

    final assignmentDoc = assignmentSnap.docs.first;
    final variantId = assignmentDoc.data()['variantId'] as String;

    // Update assignment record
    await assignmentDoc.reference.update({
      if (eventType == 'conversion') 'converted': true,
      'engagement': FieldValue.increment(1),
      'events': FieldValue.arrayUnion([
        {
          'type': eventType,
          'value': value,
          'timestamp': DateTime.now().toIso8601String(),
          ...?metadata,
        },
      ]),
    });

    // Update experiment metrics
    await _experiments.doc(experimentId).update({
      'metrics.$variantId.$eventType': FieldValue.increment(1),
      'metrics.$variantId.totalValue': FieldValue.increment(value),
    });
  }

  // ── GET RESULTS ───────────────────────────────────────────────

  /// Get full experiment results with per-variant stats
  Future<Map<String, dynamic>> getResults(String experimentId) async {
    final expDoc = await _experiments.doc(experimentId).get();
    if (!expDoc.exists) return {};
    final expData = expDoc.data()!;

    final variants = (expData['variants'] as List<dynamic>)
        .map((v) => v as Map<String, dynamic>)
        .toList();

    final results = <String, dynamic>{
      'experimentId': experimentId,
      'name': expData['name'],
      'status': expData['status'],
      'totalParticipants': expData['totalParticipants'] ?? 0,
      'variants': <Map<String, dynamic>>[],
    };

    for (final variant in variants) {
      final variantId = variant['id'] as String;

      // Get all assignments for this variant
      final assignmentsSnap = await _results
          .where('experimentId', isEqualTo: experimentId)
          .where('variantId', isEqualTo: variantId)
          .get();

      final int participants = assignmentsSnap.docs.length;
      int converted = 0;
      int totalEngagement = 0;

      for (final doc in assignmentsSnap.docs) {
        final d = doc.data();
        if (d['converted'] == true) converted++;
        totalEngagement += (d['engagement'] as int?) ?? 0;
      }

      results['variants'].add({
        'id': variantId,
        'name': variant['name'],
        'participants': participants,
        'conversions': converted,
        'conversionRate': participants > 0
            ? (converted / participants * 100)
            : 0.0,
        'totalEngagement': totalEngagement,
        'avgEngagement': participants > 0
            ? totalEngagement / participants
            : 0.0,
      });
    }

    return results;
  }

  // ── MANAGEMENT ────────────────────────────────────────────────

  /// Get all experiments
  Stream<List<Map<String, dynamic>>> streamExperiments({int limit = 50}) {
    return _experiments
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  /// Pause/resume/end an experiment
  Future<void> updateExperimentStatus(
    String experimentId,
    String status,
  ) async {
    await _experiments.doc(experimentId).update({
      'status': status, // active, paused, completed
    });
  }

  /// Determine the winning variant
  Future<String?> getWinningVariant(String experimentId) async {
    final results = await getResults(experimentId);
    final variants = results['variants'] as List<Map<String, dynamic>>? ?? [];
    if (variants.isEmpty) return null;

    variants.sort(
      (a, b) => (b['conversionRate'] as double).compareTo(
        a['conversionRate'] as double,
      ),
    );

    return variants.first['id'] as String;
  }
}

/// Defines an A/B test variant
class ABVariant {
  final String id;
  final String name;
  final String description;
  final double weight; // relative weight (will be normalized)
  final Map<String, dynamic> config; // variant-specific config

  const ABVariant({
    required this.id,
    required this.name,
    this.description = '',
    this.weight = 50,
    this.config = const {},
  });
}
