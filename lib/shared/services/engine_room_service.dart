import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ENGINE ROOM SERVICE — Real-time Pipeline Telemetry & Controls
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Connects to:
///  - getFeedHealth (callable) → pipeline stats, category/region balance
///  - triggerWaterfall (callable) → force a conveyor run
///  - conveyor_runs (Firestore) → live telemetry from scheduled runs
///  - events (Firestore) → hype engine targets
///  - ingested_content / feed_content → article counts by status
/// ═══════════════════════════════════════════════════════════════════════════

final _functions = FirebaseFunctions.instanceFor(
  region: 'australia-southeast1',
);
final _firestore = FirebaseFirestore.instance;

class EngineRoomService {
  // ── Feed Health Dashboard Data ──
  Future<Map<String, dynamic>> getFeedHealth() async {
    try {
      final result = await _functions.httpsCallable('getFeedHealth').call();
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e) {
      return _buildFallbackHealth();
    }
  }

  // ── Trigger Waterfall Conveyor Manually ──
  Future<Map<String, dynamic>> triggerWaterfall() async {
    try {
      final result = await _functions.httpsCallable('triggerWaterfall').call();
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ── Stream: Last N Conveyor Runs (live telemetry) ──
  Stream<List<Map<String, dynamic>>> streamConveyorRuns({int limit = 10}) {
    return _firestore
        .collection('conveyor_runs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList(),
        );
  }

  // ── Stream: Upcoming Events (Hype Engine Targets) ──
  Stream<List<Map<String, dynamic>>> streamUpcomingEvents({int limit = 10}) {
    final now = DateTime.now().toIso8601String();
    return _firestore
        .collection('events')
        .where('eventDate', isGreaterThanOrEqualTo: now)
        .orderBy('eventDate')
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList(),
        )
        .handleError((_) => <Map<String, dynamic>>[]);
  }

  // ── Stream: Recently Ended Events (Adrenaline Dump Targets) ──
  Stream<List<Map<String, dynamic>>> streamRecentEvents({int limit = 10}) {
    final threeDaysAgo = DateTime.now()
        .subtract(const Duration(hours: 72))
        .toIso8601String();
    final now = DateTime.now().toIso8601String();
    return _firestore
        .collection('events')
        .where('eventDate', isGreaterThanOrEqualTo: threeDaysAgo)
        .where('eventDate', isLessThanOrEqualTo: now)
        .orderBy('eventDate', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList(),
        )
        .handleError((_) => <Map<String, dynamic>>[]);
  }

  // ── Pipeline Counts (quick snapshot) ──
  Future<Map<String, int>> getPipelineCounts() async {
    try {
      final futures = await Future.wait([
        _firestore
            .collection('ingested_content')
            .where('status', isEqualTo: 'new')
            .count()
            .get(),
        _firestore
            .collection('ingested_content')
            .where('status', isEqualTo: 'queued')
            .count()
            .get(),
        _firestore
            .collection('ingested_content')
            .where('status', isEqualTo: 'promoted')
            .count()
            .get(),
        _firestore
            .collection('feed_content')
            .where('status', isEqualTo: 'published')
            .count()
            .get(),
        _firestore
            .collection('feed_content')
            .where('status', isEqualTo: 'archived')
            .count()
            .get(),
      ]);
      return {
        'new': futures[0].count ?? 0,
        'queued': futures[1].count ?? 0,
        'promoted': futures[2].count ?? 0,
        'published': futures[3].count ?? 0,
        'archived': futures[4].count ?? 0,
      };
    } catch (_) {
      return {
        'new': 0,
        'queued': 0,
        'promoted': 0,
        'published': 0,
        'archived': 0,
      };
    }
  }

  Map<String, dynamic> _buildFallbackHealth() {
    return {
      'pipeline': {
        'ingested': {'new': 0, 'queued': 0, 'promoted': 0},
        'published': 0,
        'archived': 0,
      },
      'balance': {'categories': {}, 'regions': {}, 'tiers': {}},
      'scoring': {'averageRankScore': 0},
      'lastConveyorRun': null,
    };
  }
}
