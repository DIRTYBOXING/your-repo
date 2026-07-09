import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/social_clip_model.dart';
import '../../ppv/models/ppv_model.dart';
import '../../broadcast/models/broadcast_control_model.dart';
import '../../orchestration/models/event_session_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// AUTO CLIP GENERATOR SERVICE — Social Viral Moment Factory
/// ═══════════════════════════════════════════════════════════════════════════
///
/// The growth engine of DFC's social layer.
/// Listens to:
///   - Tier 4: Orchestration events (knockdowns, submissions, round ends)
///   - Tier 5: Broadcast replay markers
/// And automatically creates social clips that are published to:
///   - Social feed
///   - Creator dashboards
///   - Promoter analytics
///   - Trending algorithm
///
/// This is how every fight moment becomes a viral opportunity.
///
/// Data Flow:
///   Orchestration Event (e.g., knockdown)
///       ↓
///   ReplayMarker (Tier 5 creates)
///       ↓
///   AutoClipGeneratorService (listens)
///       ├─ Generates SocialClip
///       ├─ Publishes to Firestore
///       ├─ Adds to social feed
///       └─ Triggers trending algorithm
///       ↓
///   Social Feed (displays clip)
///       ↓
///   User engagement (likes, shares, PPV conversions)
///
/// ═══════════════════════════════════════════════════════════════════════════

class AutoClipGeneratorService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Configuration ──
  static const int knockdownClipDuration = 20; // seconds
  static const int submissionClipDuration = 25;
  static const int roundEndClipDuration = 15;
  static const String baseClipUrl =
      'https://mux.com/clips'; // Mux clips endpoint

  // ── Generated clips tracking ──
  final List<SocialClip> _generatedClips = [];
  List<SocialClip> get generatedClips => List.unmodifiable(_generatedClips);

  /// Initialize clip generator for a fight
  Future<void> initializeForFight(
    String eventId,
    String sessionId,
    String fightId,
    PPVEvent? event,
    FightSession? fight,
  ) async {
    try {
      debugPrint(
        '📹 [CLIP GEN] Initialized for fight: $fightId\n'
        '  ├─ Event: ${event?.title ?? "Unknown"}\n'
        '  └─ Fight: ${fight?.fight1Name ?? "Unknown"} vs ${fight?.fight2Name ?? "Unknown"}',
      );

      // Listen to orchestration events for this fight
      _listenToOrchestrationEvents(eventId, sessionId, fightId, event, fight);
    } catch (e) {
      debugPrint('❌ [CLIP GEN] Error initializing: $e');
    }
  }

  /// Listen to orchestration events and generate clips
  void _listenToOrchestrationEvents(
    String eventId,
    String sessionId,
    String fightId,
    PPVEvent? event,
    FightSession? fight,
  ) {
    _firestore
        .collection('ppv_events')
        .doc(eventId)
        .collection('event_sessions')
        .doc(sessionId)
        .collection('fight_sessions')
        .doc(fightId)
        .collection('events')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              _onOrchestrationEvent(
                change.doc.data() as Map<String, dynamic>,
                eventId,
                sessionId,
                fightId,
                event,
                fight,
              );
            }
          }
        });
  }

  /// Handle orchestration event → generate clip
  Future<void> _onOrchestrationEvent(
    Map<String, dynamic> eventData,
    String eventId,
    String sessionId,
    String fightId,
    PPVEvent? event,
    FightSession? fight,
  ) async {
    try {
      final eventType = eventData['type'] as String?;
      final round = eventData['round'] as int? ?? 1;
      final timeInRound = eventData['timeInRound'] as int? ?? 0;
      final description = eventData['description'] as String? ?? '';

      switch (eventType) {
        case 'knockdown':
          await _generateKnockdownClip(
            eventId,
            sessionId,
            fightId,
            event,
            fight,
            round,
            timeInRound,
            description,
          );
          break;

        case 'submission':
          await _generateSubmissionClip(
            eventId,
            sessionId,
            fightId,
            event,
            fight,
            round,
            timeInRound,
            description,
          );
          break;

        case 'roundEnd':
          await _generateRoundEndClip(
            eventId,
            sessionId,
            fightId,
            event,
            fight,
            round,
          );
          break;

        default:
          break;
      }
    } catch (e) {
      debugPrint('❌ [CLIP GEN] Error generating clip: $e');
    }
  }

  /// Generate knockdown clip
  Future<void> _generateKnockdownClip(
    String eventId,
    String sessionId,
    String fightId,
    PPVEvent? event,
    FightSession? fight,
    int round,
    int timeInRound,
    String description,
  ) async {
    try {
      final clipId = 'clip_knockdown_${DateTime.now().millisecondsSinceEpoch}';
      final title = '💥 ${fight?.fight1Name ?? "Fighter 1"} KNOCKDOWN';

      final clip = SocialClip(
        id: clipId,
        eventId: eventId,
        sessionId: sessionId,
        fightId: fightId,
        clipType: ClipType.knockdown,
        videoUrl: '$baseClipUrl/$clipId.m3u8',
        durationSeconds: knockdownClipDuration,
        startTimeInFight: timeInRound,
        fighter1Id: fight?.fight1Id ?? 'unknown',
        fighter1Name: fight?.fight1Name ?? 'Fighter 1',
        fighter2Id: fight?.fight2Id ?? 'unknown',
        fighter2Name: fight?.fight2Name ?? 'Fighter 2',
        round: round,
        title: title,
        description: description,
        autoGenerated: true,
        createdAt: DateTime.now(),
      );

      // Publish to Firestore
      await _publishClip(eventId, sessionId, fightId, clip);

      debugPrint(
        '💥 [CLIP GEN] Knockdown clip created\n'
        '  ├─ ID: $clipId\n'
        '  ├─ Title: $title\n'
        '  ├─ Round: $round\n'
        '  └─ Time: ${timeInRound}s',
      );

      _generatedClips.add(clip);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [CLIP GEN] Error generating knockdown clip: $e');
    }
  }

  /// Generate submission clip
  Future<void> _generateSubmissionClip(
    String eventId,
    String sessionId,
    String fightId,
    PPVEvent? event,
    FightSession? fight,
    int round,
    int timeInRound,
    String description,
  ) async {
    try {
      final clipId = 'clip_submission_${DateTime.now().millisecondsSinceEpoch}';
      final title = '🔐 SUBMISSION';

      final clip = SocialClip(
        id: clipId,
        eventId: eventId,
        sessionId: sessionId,
        fightId: fightId,
        clipType: ClipType.submission,
        videoUrl: '$baseClipUrl/$clipId.m3u8',
        durationSeconds: submissionClipDuration,
        startTimeInFight: timeInRound,
        fighter1Id: fight?.fight1Id ?? 'unknown',
        fighter1Name: fight?.fight1Name ?? 'Fighter 1',
        fighter2Id: fight?.fight2Id ?? 'unknown',
        fighter2Name: fight?.fight2Name ?? 'Fighter 2',
        round: round,
        title: title,
        description: description,
        autoGenerated: true,
        createdAt: DateTime.now(),
      );

      await _publishClip(eventId, sessionId, fightId, clip);

      debugPrint(
        '🔐 [CLIP GEN] Submission clip created\n'
        '  ├─ ID: $clipId\n'
        '  ├─ Round: $round\n'
        '  └─ Submission: $description',
      );

      _generatedClips.add(clip);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [CLIP GEN] Error generating submission clip: $e');
    }
  }

  /// Generate round end clip (round summary)
  Future<void> _generateRoundEndClip(
    String eventId,
    String sessionId,
    String fightId,
    PPVEvent? event,
    FightSession? fight,
    int round,
  ) async {
    try {
      final clipId = 'clip_roundend_${DateTime.now().millisecondsSinceEpoch}';
      final title = '🔔 ROUND $round SUMMARY';

      final clip = SocialClip(
        id: clipId,
        eventId: eventId,
        sessionId: sessionId,
        fightId: fightId,
        clipType: ClipType.roundEnd,
        videoUrl: '$baseClipUrl/$clipId.m3u8',
        durationSeconds: roundEndClipDuration,
        startTimeInFight: 0, // Round summary
        fighter1Id: fight?.fight1Id ?? 'unknown',
        fighter1Name: fight?.fight1Name ?? 'Fighter 1',
        fighter2Id: fight?.fight2Id ?? 'unknown',
        fighter2Name: fight?.fight2Name ?? 'Fighter 2',
        round: round,
        title: title,
        description: 'Round $round summary with key moments',
        autoGenerated: true,
        createdAt: DateTime.now(),
      );

      await _publishClip(eventId, sessionId, fightId, clip);

      debugPrint(
        '🔔 [CLIP GEN] Round end clip created\n'
        '  ├─ ID: $clipId\n'
        '  └─ Round: $round',
      );

      _generatedClips.add(clip);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [CLIP GEN] Error generating round end clip: $e');
    }
  }

  /// Publish clip to Firestore
  Future<void> _publishClip(
    String eventId,
    String sessionId,
    String fightId,
    SocialClip clip,
  ) async {
    try {
      final clipPath =
          'ppv_events/$eventId/event_sessions/$sessionId/social_clips/${clip.id}';

      await _firestore.doc(clipPath).set(clip.toFirestore());

      // Also add to trending cache
      await _addToTrendingCache(eventId, sessionId, clip);

      debugPrint('✅ [CLIP GEN] Published clip to Firestore: ${clip.id}');
    } catch (e) {
      debugPrint('❌ [CLIP GEN] Error publishing clip: $e');
      rethrow;
    }
  }

  /// Add clip to trending cache (for feed ranking)
  Future<void> _addToTrendingCache(
    String eventId,
    String sessionId,
    SocialClip clip,
  ) async {
    try {
      // Add to trending subcollection for quick queries
      await _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('trending_clips')
          .doc(clip.id)
          .set({
            'clipId': clip.id,
            'trendingScore': clip.trendingScore,
            'clipType': clip.clipType.toString().split('.').last,
            'createdAt': clip.createdAt,
            'views': 0,
            'likes': 0,
            'shares': 0,
          });
    } catch (e) {
      debugPrint('⚠️ [CLIP GEN] Error adding to trending cache: $e');
    }
  }

  /// Increment clip engagement metric
  Future<void> incrementEngagement(
    String eventId,
    String sessionId,
    String clipId,
    String metric, // 'views', 'likes', 'shares', 'comments', 'ppvConversions'
  ) async {
    try {
      final clipPath =
          'ppv_events/$eventId/event_sessions/$sessionId/social_clips/$clipId';

      await _firestore.doc(clipPath).update({
        'engagement.$metric': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update trending cache
      await _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('trending_clips')
          .doc(clipId)
          .update({metric: FieldValue.increment(1)});

      debugPrint(
        '📊 [CLIP GEN] Engagement incremented\n'
        '  ├─ Clip: $clipId\n'
        '  └─ Metric: $metric',
      );
    } catch (e) {
      debugPrint('⚠️ [CLIP GEN] Error incrementing engagement: $e');
    }
  }

  /// Record PPV conversion for clip attribution
  Future<void> recordPPVConversion(
    String eventId,
    String sessionId,
    String clipId,
    String userId,
    double amount,
  ) async {
    try {
      // Increment clip PPV conversions
      await incrementEngagement(eventId, sessionId, clipId, 'ppvConversions');

      // Log conversion for analytics
      await _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('clip_conversions')
          .add({
            'clipId': clipId,
            'userId': userId,
            'amount': amount,
            'timestamp': FieldValue.serverTimestamp(),
          });

      debugPrint(
        '💰 [CLIP GEN] PPV conversion recorded\n'
        '  ├─ Clip: $clipId\n'
        '  ├─ User: $userId\n'
        '  └─ Amount: \$$amount',
      );
    } catch (e) {
      debugPrint('❌ [CLIP GEN] Error recording PPV conversion: $e');
    }
  }

  /// Get trending clips for a fight
  Future<List<SocialClip>> getTrendingClips(
    String eventId,
    String sessionId, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('social_clips')
          .orderBy('engagement.trendingScore', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => SocialClip.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('❌ [CLIP GEN] Error fetching trending clips: $e');
      return [];
    }
  }

  /// Get recent clips
  Future<List<SocialClip>> getRecentClips(
    String eventId,
    String sessionId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('social_clips')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => SocialClip.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('❌ [CLIP GEN] Error fetching recent clips: $e');
      return [];
    }
  }

  /// Get clips by type
  Future<List<SocialClip>> getClipsByType(
    String eventId,
    String sessionId,
    ClipType type, {
    int limit = 10,
  }) async {
    try {
      final typeStr = type.toString().split('.').last;
      final snapshot = await _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('social_clips')
          .where('clipType', isEqualTo: typeStr)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => SocialClip.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('❌ [CLIP GEN] Error fetching clips by type: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _generatedClips.clear();
    super.dispose();
  }
}
