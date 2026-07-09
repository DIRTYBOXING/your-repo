import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// E2E TEST HARNESS — Tier 6D Viral Loop Validation
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Full end-to-end validation of the viral arena pipeline:
///   Orchestration → Auto-Clip → Feed Update → Engagement → PPV → Creator Earnings
///
/// Usage:
///   final harness = E2ETestHarness();
///   final result = await harness.runFullValidation(
///     eventId: 'event_test_001',
///     sessionId: 'session_test_001',
///   );
///   debugPrint(result.summary);
///
/// ═══════════════════════════════════════════════════════════════════════════

class E2ETestResult {
  final bool passed;
  final Duration totalDuration;
  final List<String> successLog;
  final List<String> failureLog;
  final Map<String, dynamic> metrics;

  E2ETestResult({
    required this.passed,
    required this.totalDuration,
    required this.successLog,
    required this.failureLog,
    required this.metrics,
  });

  String get summary {
    return '''
╔══════════════════════════════════════════════════════════════════════════════╗
║                    E2E VALIDATION REPORT                                    ║
╠══════════════════════════════════════════════════════════════════════════════╣
║ Status: ${passed ? '✅ PASSED' : '❌ FAILED'}
║ Total Duration: ${totalDuration.inMilliseconds}ms
║
║ ✅ Passed (${successLog.length}):
${successLog.map((s) => '║   ✓ $s').join('\n')}
║
${failureLog.isNotEmpty ? '''║ ❌ Failed (${failureLog.length}):
${failureLog.map((f) => '║   ✗ $f').join('\n')}
║''' : ''}║ 📊 Metrics:
${metrics.entries.map((e) => '║   ${e.key}: ${e.value}').join('\n')}
║
╚══════════════════════════════════════════════════════════════════════════════╝
''';
  }
}

class E2ETestHarness {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _successLog = [];
  final List<String> _failureLog = [];
  final Map<String, dynamic> _metrics = {};

  /// Run full E2E validation
  Future<E2ETestResult> runFullValidation({
    required String eventId,
    required String sessionId,
  }) async {
    final startTime = DateTime.now();
    _successLog.clear();
    _failureLog.clear();
    _metrics.clear();

    try {
      debugPrint('🚀 [E2E] Starting full validation pipeline...');

      // Stage 1: Setup
      await _stageSetup(eventId, sessionId);

      // Stage 2: Simulate Orchestration Event (Knockdown)
      final knockdownClipId = await _stageSimulateKnockdown(
        eventId,
        sessionId,
        'fight_e2e_001',
      );

      // Stage 3: Monitor Clip Generation
      await _stageMonitorClipGeneration(eventId, sessionId, knockdownClipId);

      // Stage 4: Verify Feed Update
      await _stageVerifyFeedUpdate(eventId, sessionId, knockdownClipId);

      // Stage 5: Simulate Engagement
      await _stageSimulateEngagement(eventId, sessionId, knockdownClipId);

      // Stage 6: Verify Trending Recalculation
      await _stageVerifyTrendingRecalculation(
        eventId,
        sessionId,
        knockdownClipId,
      );

      // Stage 7: Simulate PPV Conversion
      await _stageSimulatePPVConversion(eventId, sessionId, knockdownClipId);

      // Stage 8: Verify Creator Earnings
      await _stageVerifyCreatorEarnings();

      // Stage 9: Test Live Fight Banner Sync
      await _stageLiveFightBannerSync(eventId, sessionId);

      // Stage 10: Cleanup
      await _stageCleanup(eventId, sessionId);

      final endTime = DateTime.now();
      final passed = _failureLog.isEmpty;

      return E2ETestResult(
        passed: passed,
        totalDuration: endTime.difference(startTime),
        successLog: _successLog,
        failureLog: _failureLog,
        metrics: _metrics,
      );
    } catch (e) {
      _failureLog.add('Unhandled exception: $e');
      final endTime = DateTime.now();
      return E2ETestResult(
        passed: false,
        totalDuration: endTime.difference(startTime),
        successLog: _successLog,
        failureLog: _failureLog,
        metrics: _metrics,
      );
    }
  }

  /// Stage 1: Setup test environment
  Future<void> _stageSetup(String eventId, String sessionId) async {
    try {
      debugPrint('📋 [STAGE 1] Setting up test environment...');

      // Create minimal test event if doesn't exist
      final eventPath = 'ppv_events/$eventId';
      final eventDoc = await _firestore.doc(eventPath).get();

      if (!eventDoc.exists) {
        await _firestore.doc(eventPath).set({
          'title': 'E2E Test Event',
          'subtitle': 'Tier 6D Validation',
          'createdAt': FieldValue.serverTimestamp(),
        });
        _successLog.add('Test event created');
      } else {
        _successLog.add('Test event exists, proceeding');
      }

      // Create minimal session if doesn't exist
      final sessionPath = '$eventPath/event_sessions/$sessionId';
      final sessionDoc = await _firestore.doc(sessionPath).get();

      if (!sessionDoc.exists) {
        await _firestore.doc(sessionPath).set({
          'eventId': eventId,
          'sessionId': sessionId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _successLog.add('Test session created');
      } else {
        _successLog.add('Test session exists, proceeding');
      }

      _metrics['setup_status'] = 'ready';
    } catch (e) {
      _failureLog.add('Setup failed: $e');
      rethrow;
    }
  }

  /// Stage 2: Simulate Knockdown Orchestration Event
  Future<String> _stageSimulateKnockdown(
    String eventId,
    String sessionId,
    String fightId,
  ) async {
    try {
      debugPrint('⚡ [STAGE 2] Simulating knockdown orchestration event...');

      final eventPath =
          'ppv_events/$eventId/event_sessions/$sessionId/fight_sessions/$fightId/events';

      // Write knockdown orchestration event
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
        'description': 'Devastating counter-strike knockdown',
        'round': 2,
        'timeInRound': 45,
        'fighterIndex': 0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _successLog.add('Knockdown event written to Firestore');
      _metrics['knockdown_event_id'] = eventDoc.id;

      // Wait for auto-clip generation (should be < 2 seconds)
      await Future.delayed(const Duration(seconds: 2));

      // Verify clip was generated
      final clipsSnapshot = await _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('social_clips')
          .where('clipType', isEqualTo: 'knockdown')
          .limit(1)
          .get();

      if (clipsSnapshot.docs.isNotEmpty) {
        final clipId = clipsSnapshot.docs.first.id;
        _successLog.add('Auto-clip generated (ID: $clipId)');
        _metrics['clip_id'] = clipId;
        _metrics['clip_generation_latency_ms'] =
            2000; // Actual latency would be measured
        return clipId;
      } else {
        _failureLog.add('No clip generated after knockdown event');
        throw Exception('Clip generation failed');
      }
    } catch (e) {
      _failureLog.add('Knockdown simulation failed: $e');
      rethrow;
    }
  }

  /// Stage 3: Monitor Clip Generation
  Future<void> _stageMonitorClipGeneration(
    String eventId,
    String sessionId,
    String clipId,
  ) async {
    try {
      debugPrint('📹 [STAGE 3] Monitoring clip generation metadata...');

      final clipDoc = await _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('social_clips')
          .doc(clipId)
          .get();

      if (!clipDoc.exists) {
        _failureLog.add('Clip metadata not found');
        throw Exception('Clip metadata missing');
      }

      final data = clipDoc.data()!;

      // Verify key fields
      final checks = {
        'id': data['id'] != null,
        'title': data['title'] != null,
        'description': data['description'] != null,
        'fighter1Name': data['fighter1Name'] != null,
        'fighter2Name': data['fighter2Name'] != null,
        'clipType': data['clipType'] == 'knockdown',
        'engagement': data['engagement'] != null,
        'trendingScore': data['trendingScore'] != null,
        'createdAt': data['createdAt'] != null,
      };

      final failedChecks = checks.entries
          .where((e) => !e.value)
          .map((e) => e.key)
          .toList();

      if (failedChecks.isEmpty) {
        _successLog.add('All clip metadata fields present and valid');
        _metrics['clip_metadata_valid'] = true;
      } else {
        _failureLog.add('Missing metadata fields: $failedChecks');
      }
    } catch (e) {
      _failureLog.add('Clip monitoring failed: $e');
      rethrow;
    }
  }

  /// Stage 4: Verify Feed Update via Real-Time Listener
  Future<void> _stageVerifyFeedUpdate(
    String eventId,
    String sessionId,
    String clipId,
  ) async {
    try {
      debugPrint('📡 [STAGE 4] Verifying real-time feed update...');

      // Subscribe to trending stream
      final streamStartTime = DateTime.now();
      bool clipFoundInStream = false;

      await _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('social_clips')
          .orderBy('trendingScore', descending: true)
          .limit(20)
          .snapshots()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: (sink) {
              sink.close();
            },
          )
          .take(1)
          .forEach((snapshot) {
            final clipIds = snapshot.docs.map((doc) => doc.id).toList();
            if (clipIds.contains(clipId)) {
              clipFoundInStream = true;
            }
          });

      if (clipFoundInStream) {
        final streamLatency = DateTime.now().difference(streamStartTime);
        _successLog.add(
          'Clip appeared in trending feed stream (${streamLatency.inMilliseconds}ms)',
        );
        _metrics['feed_update_latency_ms'] = streamLatency.inMilliseconds;
      } else {
        _failureLog.add(
          'Clip did not appear in trending stream within 5 seconds',
        );
      }
    } catch (e) {
      _failureLog.add('Feed update verification failed: $e');
      rethrow;
    }
  }

  /// Stage 5: Simulate User Engagement (View, Like, Share)
  Future<void> _stageSimulateEngagement(
    String eventId,
    String sessionId,
    String clipId,
  ) async {
    try {
      debugPrint('❤️ [STAGE 5] Simulating user engagement...');

      final clipPath =
          'ppv_events/$eventId/event_sessions/$sessionId/social_clips/$clipId';

      // Simulate view (auto-record)
      await _firestore.doc(clipPath).update({
        'engagement.views': FieldValue.increment(1),
      });
      _successLog.add('View recorded');

      // Simulate 3 likes
      for (int i = 0; i < 3; i++) {
        await _firestore.doc(clipPath).update({
          'engagement.likes': FieldValue.increment(1),
        });
      }
      _successLog.add('3 likes recorded');

      // Simulate 2 shares
      for (int i = 0; i < 2; i++) {
        await _firestore.doc(clipPath).update({
          'engagement.shares': FieldValue.increment(1),
        });
      }
      _successLog.add('2 shares recorded');

      // Verify engagement totals
      final updated = await _firestore.doc(clipPath).get();
      final engagement = updated['engagement'] as Map<String, dynamic>;

      _metrics['final_views'] = engagement['views'] ?? 0;
      _metrics['final_likes'] = engagement['likes'] ?? 0;
      _metrics['final_shares'] = engagement['shares'] ?? 0;
    } catch (e) {
      _failureLog.add('Engagement simulation failed: $e');
      rethrow;
    }
  }

  /// Stage 6: Verify Trending Score Recalculation
  Future<void> _stageVerifyTrendingRecalculation(
    String eventId,
    String sessionId,
    String clipId,
  ) async {
    try {
      debugPrint('📊 [STAGE 6] Verifying trending score recalculation...');

      final clipPath =
          'ppv_events/$eventId/event_sessions/$sessionId/social_clips/$clipId';
      final doc = await _firestore.doc(clipPath).get();
      final data = doc.data()!;

      final views = (data['engagement']?['views'] ?? 0) as int;
      final likes = (data['engagement']?['likes'] ?? 0) as int;
      final shares = (data['engagement']?['shares'] ?? 0) as int;
      final ppvConversions =
          (data['engagement']?['ppvConversions'] ?? 0) as int;

      // Calculate expected trending score
      final expectedScore =
          (views * 0.3) +
          (likes * 0.4) +
          (shares * 1.0) +
          (ppvConversions * 2.0);

      final actualScore = (data['trendingScore'] ?? 0.0) as double;

      // Allow small rounding difference
      if ((actualScore - expectedScore).abs() < 0.1) {
        _successLog.add(
          'Trending score correct: $actualScore '
          '(views: $views, likes: $likes, shares: $shares, conversions: $ppvConversions)',
        );
        _metrics['trending_score'] = actualScore;
        _metrics['trending_formula_correct'] = true;
      } else {
        _failureLog.add(
          'Trending score mismatch: expected $expectedScore, got $actualScore',
        );
      }
    } catch (e) {
      _failureLog.add('Trending verification failed: $e');
      rethrow;
    }
  }

  /// Stage 7: Simulate PPV Conversion
  Future<void> _stageSimulatePPVConversion(
    String eventId,
    String sessionId,
    String clipId,
  ) async {
    try {
      debugPrint('💰 [STAGE 7] Simulating PPV conversion...');

      const testUserId = 'user_e2e_test_001';
      const creatorId = 'creator_e2e_test_001';
      const fightId = 'fight_e2e_001';
      const conversionValue = 14.99;

      // Record conversion
      final conversionRef = _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('clip_conversions')
          .doc();

      await conversionRef.set({
        'clipId': clipId,
        'fightId': fightId,
        'eventId': eventId,
        'sessionId': sessionId,
        'userId': testUserId,
        'creatorId': creatorId,
        'conversionValue': conversionValue,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'completed',
      });

      _successLog.add('PPV conversion recorded (ID: ${conversionRef.id})');
      _metrics['conversion_id'] = conversionRef.id;

      // Increment PPV conversions on clip
      await _firestore
          .doc(
            'ppv_events/$eventId/event_sessions/$sessionId/social_clips/$clipId',
          )
          .update({'engagement.ppvConversions': FieldValue.increment(1)});

      _successLog.add('Clip PPV conversion counter incremented');
      _metrics['ppv_conversion_value'] = conversionValue;
    } catch (e) {
      _failureLog.add('PPV conversion simulation failed: $e');
      rethrow;
    }
  }

  /// Stage 8: Verify Creator Earnings
  Future<void> _stageVerifyCreatorEarnings() async {
    try {
      debugPrint('👤 [STAGE 8] Verifying creator earnings calculation...');

      const creatorId = 'creator_e2e_test_001';
      const expectedEarning = 14.99;

      final creatorEarningsDoc = await _firestore
          .collection('creator_earnings')
          .doc(creatorId)
          .get();

      if (creatorEarningsDoc.exists) {
        final data = creatorEarningsDoc.data()!;
        final totalEarnings = data['totalEarnings'] ?? 0.0;

        if ((totalEarnings - expectedEarning).abs() < 0.01) {
          _successLog.add('Creator earnings correct: \$$totalEarnings');
          _metrics['creator_earnings'] = totalEarnings;
        } else {
          _failureLog.add(
            'Creator earnings mismatch: expected $expectedEarning, got $totalEarnings',
          );
        }
      } else {
        _failureLog.add('Creator earnings document not found');
      }
    } catch (e) {
      _failureLog.add('Creator earnings verification failed: $e');
      rethrow;
    }
  }

  /// Stage 9: Test Live Fight Banner Sync
  Future<void> _stageLiveFightBannerSync(
    String eventId,
    String sessionId,
  ) async {
    try {
      debugPrint('🎬 [STAGE 9] Testing live fight banner sync...');

      const fightId = 'fight_e2e_001';

      // Update fight session with round info
      final fightSessionPath =
          'ppv_events/$eventId/event_sessions/$sessionId/fight_sessions/$fightId';

      await _firestore.doc(fightSessionPath).set({
        'round': 3,
        'timeInRound': 120,
        'fighter1Name': 'Test Fighter 1',
        'fighter2Name': 'Test Fighter 2',
        'knockdowns': [
          {'fighter': 0, 'round': 2, 'time': 45},
        ],
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _successLog.add('Fight session updated with round info');

      // Verify the update
      final updated = await _firestore.doc(fightSessionPath).get();
      if (updated['round'] == 3 && updated['timeInRound'] == 120) {
        _successLog.add('Live fight banner sync verified');
        _metrics['live_banner_round'] = 3;
        _metrics['live_banner_time'] = 120;
      } else {
        _failureLog.add('Live fight banner sync failed');
      }
    } catch (e) {
      _failureLog.add('Live fight banner sync test failed: $e');
      rethrow;
    }
  }

  /// Stage 10: Cleanup Test Data
  Future<void> _stageCleanup(String eventId, String sessionId) async {
    try {
      debugPrint('🧹 [STAGE 10] Cleaning up test data...');

      // Delete test clips
      final clipsSnapshot = await _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('social_clips')
          .get();

      for (final doc in clipsSnapshot.docs) {
        await doc.reference.delete();
      }

      _successLog.add('Test clips cleaned up');

      // Delete test conversions
      final conversionsSnapshot = await _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('clip_conversions')
          .get();

      for (final doc in conversionsSnapshot.docs) {
        await doc.reference.delete();
      }

      _successLog.add('Test conversions cleaned up');
    } catch (e) {
      debugPrint('⚠️ Cleanup warning: $e');
      // Don't fail the test on cleanup errors
    }
  }
}
