import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../features/social/models/social_clip_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ORCHESTRATION EVENT SIMULATOR — Test Harness Helper
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Simulates real orchestration events for testing:
///   - Knockdown
///   - Submission
///   - Round end
///   - Replay markers
///
/// Usage:
///   final simulator = OrchestrationEventSimulator();
///   await simulator.simulateKnockdown(eventId, sessionId, fightId);
///
/// ═══════════════════════════════════════════════════════════════════════════

class OrchestrationEventSimulator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Simulate a knockdown event
  Future<String> simulateKnockdown(
    String eventId,
    String sessionId,
    String fightId, {
    int round = 2,
    int timeInRound = 45,
    int fighterIndex = 0,
  }) async {
    try {
      final eventDoc = _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('fight_sessions')
          .doc(fightId)
          .collection('events')
          .doc();

      await eventDoc.set({
        'type': 'knockdown',
        'description': 'Fighter knocked down with precision strike',
        'round': round,
        'timeInRound': timeInRound,
        'fighterIndex': fighterIndex,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('⚡ Knockdown event simulated: ${eventDoc.id}');
      return eventDoc.id;
    } catch (e) {
      debugPrint('❌ Error simulating knockdown: $e');
      rethrow;
    }
  }

  /// Simulate a submission event
  Future<String> simulateSubmission(
    String eventId,
    String sessionId,
    String fightId, {
    int round = 1,
    int timeInRound = 90,
    int fighterIndex = 1,
    String submissionType = 'rear_naked_choke',
  }) async {
    try {
      final eventDoc = _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('fight_sessions')
          .doc(fightId)
          .collection('events')
          .doc();

      await eventDoc.set({
        'type': 'submission',
        'description': 'Fighter taps out to $submissionType',
        'submissionType': submissionType,
        'round': round,
        'timeInRound': timeInRound,
        'fighterIndex': fighterIndex,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('🔐 Submission event simulated: ${eventDoc.id}');
      return eventDoc.id;
    } catch (e) {
      debugPrint('❌ Error simulating submission: $e');
      rethrow;
    }
  }

  /// Simulate a round end event
  Future<String> simulateRoundEnd(
    String eventId,
    String sessionId,
    String fightId, {
    required int round,
  }) async {
    try {
      final eventDoc = _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('fight_sessions')
          .doc(fightId)
          .collection('events')
          .doc();

      await eventDoc.set({
        'type': 'roundEnd',
        'description': 'Round $round has ended',
        'round': round,
        'timeInRound': 0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('⏱️ Round end event simulated: round $round');
      return eventDoc.id;
    } catch (e) {
      debugPrint('❌ Error simulating round end: $e');
      rethrow;
    }
  }

  /// Simulate multiple events in sequence
  Future<List<String>> simulateSequence(
    String eventId,
    String sessionId,
    String fightId,
  ) async {
    final eventIds = <String>[];

    try {
      // Round 1 end
      eventIds.add(
        await simulateRoundEnd(eventId, sessionId, fightId, round: 1),
      );
      await Future.delayed(const Duration(milliseconds: 500));

      // Round 2 knockdown
      eventIds.add(
        await simulateKnockdown(eventId, sessionId, fightId, round: 2),
      );
      await Future.delayed(const Duration(milliseconds: 500));

      // Round 2 end
      eventIds.add(
        await simulateRoundEnd(eventId, sessionId, fightId, round: 2),
      );
      await Future.delayed(const Duration(milliseconds: 500));

      // Round 3 submission
      eventIds.add(
        await simulateSubmission(eventId, sessionId, fightId, round: 3),
      );

      debugPrint('✅ Event sequence complete: ${eventIds.length} events');
      return eventIds;
    } catch (e) {
      debugPrint('❌ Error simulating sequence: $e');
      rethrow;
    }
  }

  /// Get all events for a fight
  Future<List<Map<String, dynamic>>> getEventHistory(
    String eventId,
    String sessionId,
    String fightId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('fight_sessions')
          .doc(fightId)
          .collection('events')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Error getting event history: $e');
      return [];
    }
  }
}
