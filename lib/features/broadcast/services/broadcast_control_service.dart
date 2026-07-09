import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/broadcast_control_model.dart';
import '../../orchestration/models/event_session_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// BROADCAST CONTROL SERVICE — Professional Broadcast Engine
/// ═══════════════════════════════════════════════════════════════════════════
///
/// The director booth engine that:
///   - Listens to orchestration events (Tier 4)
///   - Auto-orchestrates camera switches based on fight action
///   - Creates replay markers on key moments
///   - Manages graphics overlay state
///   - Syncs commentary track
///   - Publishes broadcast state to Firestore
///
/// Data Flow:
///   EventOrchestrationService (Tier 4) writes events
///       ↓
///   Firestore ppv_events/{id}/event_sessions/{id}/fight_sessions/{id}/events
///       ↓
///   BroadcastControlService (real-time listener)
///       ├─ Auto-camera orchestration
///       ├─ Replay marker creation
///       ├─ Graphics state management
///       └─ Broadcast state publication
///       ↓
///   PPVWatchScreen (Tier 5 enhanced)
///       └─ Professional broadcast viewer experience
///
/// ═══════════════════════════════════════════════════════════════════════════

class BroadcastControlService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Broadcast State ──
  BroadcastSession? _broadcastSession;
  StreamSubscription<QuerySnapshot>? _eventsSubscription;
  StreamSubscription<DocumentSnapshot>? _broadcastStateSubscription;

  // ── Camera Profiles (predefined) ──
  final List<CameraProfile> _defaultCameras = [
    CameraProfile(
      id: 'cam_wide',
      name: 'Wide Angle',
      angle: CameraAngle.wide,
      streamUrl: 'https://stream.mux.com/wide.m3u8',
      lastUpdated: DateTime.now(),
    ),
    CameraProfile(
      id: 'cam_closeup',
      name: 'Closeup - Fighter 1',
      angle: CameraAngle.closeup,
      streamUrl: 'https://stream.mux.com/closeup1.m3u8',
      lastUpdated: DateTime.now(),
    ),
    CameraProfile(
      id: 'cam_replay',
      name: 'Replay',
      angle: CameraAngle.replay,
      streamUrl: 'https://stream.mux.com/replay.m3u8',
      lastUpdated: DateTime.now(),
    ),
  ];

  // ── Getters ──
  BroadcastSession? get broadcastSession => _broadcastSession;
  String? get activeCameraId => _broadcastSession?.activeCameraId;
  BroadcastMode get broadcastMode =>
      _broadcastSession?.mode ?? BroadcastMode.live;
  List<ReplayMarker> get replayQueue => _broadcastSession?.replayQueue ?? [];
  GraphicsState get graphicsState =>
      _broadcastSession?.graphicsState ?? const GraphicsState();

  /// Initialize broadcast session for a fight
  Future<void> initializeBroadcast(
    String eventId,
    String sessionId,
    String fightId,
  ) async {
    try {
      final broadcastPath =
          'ppv_events/$eventId/event_sessions/$sessionId/fight_sessions/$fightId/broadcast_control';

      // Create broadcast session document if it doesn't exist
      final broadcastDoc = await _firestore
          .doc('$broadcastPath/metadata')
          .get();

      if (!broadcastDoc.exists) {
        final newSession = BroadcastSession(
          id: '$fightId-broadcast',
          mode: BroadcastMode.live,
          activeCameraId: 'cam_wide', // Start with wide angle
          cameras: _defaultCameras,
          startedAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
          isLiveOnWire: true,
        );

        await _firestore
            .doc('$broadcastPath/metadata')
            .set(newSession.toFirestore());
      }

      _broadcastSession = BroadcastSession.fromFirestore(
        broadcastDoc.data() as Map<String, dynamic>? ?? {},
      );
      _broadcastSession = _broadcastSession?.copyWith(cameras: _defaultCameras);

      // Listen to orchestration events
      _eventsSubscription = _firestore
          .collection('ppv_events')
          .doc(eventId)
          .collection('event_sessions')
          .doc(sessionId)
          .collection('fight_sessions')
          .doc(fightId)
          .collection('events')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots()
          .listen((snapshot) {
            for (final change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                _onOrchestrationEvent(
                  change.doc.data() as Map<String, dynamic>,
                  eventId,
                  sessionId,
                  fightId,
                );
              }
            }
          });

      // Listen to broadcast state updates
      _broadcastStateSubscription = _firestore
          .doc('$broadcastPath/metadata')
          .snapshots()
          .listen((doc) {
            if (doc.exists) {
              _broadcastSession = BroadcastSession.fromFirestore(
                doc.data() as Map<String, dynamic>,
              );
              _broadcastSession = _broadcastSession?.copyWith(
                cameras: _defaultCameras,
              );
              notifyListeners();
            }
          });

      debugPrint('📺 [BROADCAST] Initialized broadcast for fight: $fightId');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [BROADCAST] Error initializing broadcast: $e');
      rethrow;
    }
  }

  /// Internal: Handle orchestration event
  Future<void> _onOrchestrationEvent(
    Map<String, dynamic> eventData,
    String eventId,
    String sessionId,
    String fightId,
  ) async {
    try {
      final eventType = eventData['type'] as String?;
      final description = eventData['description'] as String? ?? '';
      final round = eventData['round'] as int? ?? 1;
      final timeInRound = eventData['timeInRound'] as int? ?? 0;
      final fighterIndex = eventData['fighterIndex'] as int?;

      switch (eventType) {
        case 'roundStart':
          await _onRoundStart(eventId, sessionId, fightId, round);
          break;

        case 'knockdown':
          await _onKnockdown(
            eventId,
            sessionId,
            fightId,
            description,
            round,
            timeInRound,
            fighterIndex,
          );
          break;

        case 'submission':
          await _onSubmission(
            eventId,
            sessionId,
            fightId,
            description,
            round,
            timeInRound,
            fighterIndex,
          );
          break;

        case 'decision':
          await _onDecision(eventId, sessionId, fightId, description, round);
          break;

        default:
          break;
      }
    } catch (e) {
      debugPrint('❌ [BROADCAST] Error handling orchestration event: $e');
    }
  }

  /// Round started — show round banner
  Future<void> _onRoundStart(
    String eventId,
    String sessionId,
    String fightId,
    int round,
  ) async {
    try {
      final broadcastPath =
          'ppv_events/$eventId/event_sessions/$sessionId/fight_sessions/$fightId/broadcast_control';

      // Switch to wide angle for round start
      await switchCamera(eventId, sessionId, fightId, 'cam_wide');

      // Show round banner
      final updatedGraphics = graphicsState.copyWith(
        showRoundBanner: true,
        roundNumber: round,
        graphicsAlpha: 1.0,
      );

      await _firestore
          .doc('$broadcastPath/graphics')
          .set(updatedGraphics.toFirestore());

      debugPrint('🔔 [BROADCAST] Round $round started — wide angle + banner');
    } catch (e) {
      debugPrint('❌ [BROADCAST] Error on round start: $e');
    }
  }

  /// Knockdown — auto-switch to closeup, create replay marker
  Future<void> _onKnockdown(
    String eventId,
    String sessionId,
    String fightId,
    String description,
    int round,
    int timeInRound,
    int? fighterIndex,
  ) async {
    try {
      final broadcastPath =
          'ppv_events/$eventId/event_sessions/$sessionId/fight_sessions/$fightId/broadcast_control';

      // Switch to closeup for impact
      await switchCamera(eventId, sessionId, fightId, 'cam_closeup');

      // Create replay marker
      final marker = ReplayMarker(
        id: 'marker_knockdown_${DateTime.now().millisecondsSinceEpoch}',
        eventType: 'knockdown',
        startTimeSeconds: timeInRound,
        durationSeconds: 15, // 15 sec replay
        description: description,
        fighterIndex: fighterIndex,
        suggestedAngle: CameraAngle.closeup,
        playbackSpeed: 1.0,
        createdAt: DateTime.now(),
      );

      await _firestore
          .doc('$broadcastPath/markers/${marker.id}')
          .set(marker.toFirestore());

      // Add to replay queue
      await _addToReplayQueue(eventId, sessionId, fightId, marker);

      // Show knockout graphics
      final updatedGraphics = graphicsState.copyWith(showReplayGraphics: true);
      await _firestore
          .doc('$broadcastPath/graphics')
          .set(updatedGraphics.toFirestore());

      debugPrint(
        '💥 [BROADCAST] Knockdown detected\n'
        '  ├─ Camera: Closeup\n'
        '  ├─ Replay marker created\n'
        '  └─ Graphics: Knockout overlay',
      );
    } catch (e) {
      debugPrint('❌ [BROADCAST] Error on knockdown: $e');
    }
  }

  /// Submission — auto-switch to ground angle, create replay
  Future<void> _onSubmission(
    String eventId,
    String sessionId,
    String fightId,
    String description,
    int round,
    int timeInRound,
    int? fighterIndex,
  ) async {
    try {
      final broadcastPath =
          'ppv_events/$eventId/event_sessions/$sessionId/fight_sessions/$fightId/broadcast_control';

      // Switch to ground angle for submission
      await switchCamera(eventId, sessionId, fightId, 'cam_closeup');

      // Create replay marker
      final marker = ReplayMarker(
        id: 'marker_submission_${DateTime.now().millisecondsSinceEpoch}',
        eventType: 'submission',
        startTimeSeconds: timeInRound,
        durationSeconds: 20,
        description: description,
        fighterIndex: fighterIndex,
        suggestedAngle: CameraAngle.ground,
        playbackSpeed: 1.0,
        createdAt: DateTime.now(),
      );

      await _firestore
          .doc('$broadcastPath/markers/${marker.id}')
          .set(marker.toFirestore());

      // Add to replay queue
      await _addToReplayQueue(eventId, sessionId, fightId, marker);

      // Show submission graphics
      final updatedGraphics = graphicsState.copyWith(
        showReplayGraphics: true,
        lowerThirdText: 'SUBMISSION',
      );
      await _firestore
          .doc('$broadcastPath/graphics')
          .set(updatedGraphics.toFirestore());

      debugPrint(
        '🔐 [BROADCAST] Submission detected\n'
        '  ├─ Camera: Ground angle\n'
        '  ├─ Replay marker created\n'
        '  └─ Graphics: Submission overlay',
      );
    } catch (e) {
      debugPrint('❌ [BROADCAST] Error on submission: $e');
    }
  }

  /// Decision — show scorecard graphics
  Future<void> _onDecision(
    String eventId,
    String sessionId,
    String fightId,
    String description,
    int round,
  ) async {
    try {
      final broadcastPath =
          'ppv_events/$eventId/event_sessions/$sessionId/fight_sessions/$fightId/broadcast_control';

      // Switch to wide for decision announcement
      await switchCamera(eventId, sessionId, fightId, 'cam_wide');

      // Show decision graphics
      final updatedGraphics = graphicsState.copyWith(
        showStatsBanner: true,
        lowerThirdText: description,
      );
      await _firestore
          .doc('$broadcastPath/graphics')
          .set(updatedGraphics.toFirestore());

      debugPrint('🏁 [BROADCAST] Decision: $description');
    } catch (e) {
      debugPrint('❌ [BROADCAST] Error on decision: $e');
    }
  }

  /// Manual camera switch (from producer)
  Future<void> switchCamera(
    String eventId,
    String sessionId,
    String fightId,
    String cameraId,
  ) async {
    try {
      final broadcastPath =
          'ppv_events/$eventId/event_sessions/$sessionId/fight_sessions/$fightId/broadcast_control';

      await _firestore.doc('$broadcastPath/metadata').update({
        'activeCameraId': cameraId,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });

      _broadcastSession = _broadcastSession?.copyWith(activeCameraId: cameraId);
      notifyListeners();

      final camName = _defaultCameras
          .firstWhere((c) => c.id == cameraId, orElse: () => _defaultCameras[0])
          .name;

      debugPrint('🎥 [BROADCAST] Camera switched to: $camName');
    } catch (e) {
      debugPrint('❌ [BROADCAST] Error switching camera: $e');
    }
  }

  /// Set broadcast mode (live, replay, paused, slow-mo)
  Future<void> setBroadcastMode(
    String eventId,
    String sessionId,
    String fightId,
    BroadcastMode mode,
  ) async {
    try {
      final broadcastPath =
          'ppv_events/$eventId/event_sessions/$sessionId/fight_sessions/$fightId/broadcast_control';

      await _firestore.doc('$broadcastPath/metadata').update({
        'mode': mode.toString().split('.').last,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });

      _broadcastSession = _broadcastSession?.copyWith(mode: mode);
      notifyListeners();

      debugPrint(
        '📺 [BROADCAST] Mode changed to: ${mode.toString().split('.').last}',
      );
    } catch (e) {
      debugPrint('❌ [BROADCAST] Error setting broadcast mode: $e');
    }
  }

  /// Add marker to replay queue
  Future<void> _addToReplayQueue(
    String eventId,
    String sessionId,
    String fightId,
    ReplayMarker marker,
  ) async {
    try {
      final broadcastPath =
          'ppv_events/$eventId/event_sessions/$sessionId/fight_sessions/$fightId/broadcast_control';

      await _firestore
          .doc('$broadcastPath/replay_queue/${marker.id}')
          .set(marker.toFirestore());

      debugPrint('📋 [BROADCAST] Added to replay queue: ${marker.description}');
    } catch (e) {
      debugPrint('❌ [BROADCAST] Error adding to replay queue: $e');
    }
  }

  /// Play next replay in queue
  Future<void> playNextReplay(
    String eventId,
    String sessionId,
    String fightId,
  ) async {
    try {
      if (replayQueue.isEmpty) return;

      final marker = replayQueue.first;
      final broadcastPath =
          'ppv_events/$eventId/event_sessions/$sessionId/fight_sessions/$fightId/broadcast_control';

      // Set as current replay
      await _firestore.doc('$broadcastPath/metadata').update({
        'mode': 'replay',
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Show replay graphics
      final updatedGraphics = graphicsState.copyWith(showReplayGraphics: true);
      await _firestore
          .doc('$broadcastPath/graphics')
          .set(updatedGraphics.toFirestore());

      // Switch to replay camera
      await switchCamera(eventId, sessionId, fightId, 'cam_replay');

      debugPrint('▶️ [BROADCAST] Playing replay: ${marker.description}');
    } catch (e) {
      debugPrint('❌ [BROADCAST] Error playing replay: $e');
    }
  }

  /// Update graphics overlay state
  Future<void> updateGraphics(
    String eventId,
    String sessionId,
    String fightId,
    GraphicsState newState,
  ) async {
    try {
      final broadcastPath =
          'ppv_events/$eventId/event_sessions/$sessionId/fight_sessions/$fightId/broadcast_control';

      await _firestore
          .doc('$broadcastPath/graphics')
          .set(newState.toFirestore());

      _broadcastSession = _broadcastSession?.copyWith(graphicsState: newState);
      notifyListeners();

      debugPrint('🖼️ [BROADCAST] Graphics updated');
    } catch (e) {
      debugPrint('❌ [BROADCAST] Error updating graphics: $e');
    }
  }

  /// Go live on broadcast wire
  Future<void> goLiveOnWire(
    String eventId,
    String sessionId,
    String fightId,
  ) async {
    try {
      final broadcastPath =
          'ppv_events/$eventId/event_sessions/$sessionId/fight_sessions/$fightId/broadcast_control';

      await _firestore.doc('$broadcastPath/metadata').update({
        'isLiveOnWire': true,
        'mode': 'live',
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });

      _broadcastSession = _broadcastSession?.copyWith(isLiveOnWire: true);
      notifyListeners();

      debugPrint('🔴 [BROADCAST] NOW LIVE ON BROADCAST WIRE');
    } catch (e) {
      debugPrint('❌ [BROADCAST] Error going live: $e');
    }
  }

  /// Clean up
  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _broadcastStateSubscription?.cancel();
    _broadcastSession = null;
    super.dispose();
  }
}
