import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// BROADCAST CONTROL MODEL — Professional Broadcast State Machine
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Complete state machine for multi-camera, replay-driven, commentary-synced
/// professional combat sports broadcast.
///
/// This is the single source of truth for:
///   - Active camera selection
///   - Replay queue and playback
///   - Commentary track sync
///   - Graphics overlay state
///   - Broadcast timeline + markers
///   - Production mode (live, replay, paused)
///
/// Firestore Structure:
///   ppv_events/{eventId}/event_sessions/{sessionId}/fight_sessions/{fightId}/
///   └─ broadcast_control/
///      ├─ metadata (active camera, mode, graphics state)
///      ├─ cameras/{cameraId} (camera profile + feed state)
///      ├─ replay_queue (pending replays)
///      ├─ markers (timeline markers)
///      └─ commentary_tracks/{trackId}
///
/// ═══════════════════════════════════════════════════════════════════════════

enum BroadcastMode { live, replay, paused, slowMotion }

enum CameraAngle { wide, closeup, ground, overhead, replay }

/// ── Camera Profile ──
class CameraProfile extends Equatable {
  /// Unique camera ID
  final String id;

  /// Camera name/label (e.g., "Wide Angle", "Closeup Left")
  final String name;

  /// Camera angle/type
  final CameraAngle angle;

  /// Stream URL or ID
  final String streamUrl;

  /// Is this camera currently active
  final bool isActive;

  /// Last updated
  final DateTime lastUpdated;

  const CameraProfile({
    required this.id,
    required this.name,
    required this.angle,
    required this.streamUrl,
    this.isActive = false,
    required this.lastUpdated,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'angle': angle.toString().split('.').last,
      'streamUrl': streamUrl,
      'isActive': isActive,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  factory CameraProfile.fromFirestore(Map<String, dynamic> data) {
    return CameraProfile(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      angle: _parseCameraAngle(data['angle'] as String?),
      streamUrl: data['streamUrl'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? false,
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  CameraProfile copyWith({
    String? id,
    String? name,
    CameraAngle? angle,
    String? streamUrl,
    bool? isActive,
    DateTime? lastUpdated,
  }) {
    return CameraProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      angle: angle ?? this.angle,
      streamUrl: streamUrl ?? this.streamUrl,
      isActive: isActive ?? this.isActive,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    angle,
    streamUrl,
    isActive,
    lastUpdated,
  ];
}

/// ── Replay Marker ──
class ReplayMarker extends Equatable {
  /// Unique marker ID
  final String id;

  /// Type of moment (knockdown, submission, round_end, etc.)
  final String eventType;

  /// Timestamp in video (seconds)
  final int startTimeSeconds;

  /// Replay duration (seconds)
  final int durationSeconds;

  /// Description (e.g., "Knockdown by Fighter 1")
  final String description;

  /// Which fighter was involved
  final int? fighterIndex;

  /// Suggested camera angle for replay
  final CameraAngle? suggestedAngle;

  /// Replay speed (1.0 = normal, 0.5 = half speed, etc.)
  final double playbackSpeed;

  /// Has been replayed?
  final bool hasBeenReplayed;

  /// Created timestamp
  final DateTime createdAt;

  const ReplayMarker({
    required this.id,
    required this.eventType,
    required this.startTimeSeconds,
    this.durationSeconds = 10,
    required this.description,
    this.fighterIndex,
    this.suggestedAngle,
    this.playbackSpeed = 1.0,
    this.hasBeenReplayed = false,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'eventType': eventType,
      'startTimeSeconds': startTimeSeconds,
      'durationSeconds': durationSeconds,
      'description': description,
      'fighterIndex': fighterIndex,
      'suggestedAngle': suggestedAngle?.toString().split('.').last,
      'playbackSpeed': playbackSpeed,
      'hasBeenReplayed': hasBeenReplayed,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ReplayMarker.fromFirestore(Map<String, dynamic> data) {
    return ReplayMarker(
      id: data['id'] as String? ?? '',
      eventType: data['eventType'] as String? ?? '',
      startTimeSeconds: data['startTimeSeconds'] as int? ?? 0,
      durationSeconds: data['durationSeconds'] as int? ?? 10,
      description: data['description'] as String? ?? '',
      fighterIndex: data['fighterIndex'] as int?,
      suggestedAngle: _parseCameraAngle(data['suggestedAngle'] as String?),
      playbackSpeed: (data['playbackSpeed'] as num?)?.toDouble() ?? 1.0,
      hasBeenReplayed: data['hasBeenReplayed'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  ReplayMarker copyWith({
    String? id,
    String? eventType,
    int? startTimeSeconds,
    int? durationSeconds,
    String? description,
    int? fighterIndex,
    CameraAngle? suggestedAngle,
    double? playbackSpeed,
    bool? hasBeenReplayed,
    DateTime? createdAt,
  }) {
    return ReplayMarker(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      startTimeSeconds: startTimeSeconds ?? this.startTimeSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      description: description ?? this.description,
      fighterIndex: fighterIndex ?? this.fighterIndex,
      suggestedAngle: suggestedAngle ?? this.suggestedAngle,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      hasBeenReplayed: hasBeenReplayed ?? this.hasBeenReplayed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    eventType,
    startTimeSeconds,
    durationSeconds,
    description,
    fighterIndex,
    suggestedAngle,
    playbackSpeed,
    hasBeenReplayed,
    createdAt,
  ];
}

/// ── Graphics State ──
class GraphicsState extends Equatable {
  /// Current round banner showing?
  final bool showRoundBanner;

  /// Current round number (for banner)
  final int? roundNumber;

  /// Fighter stats banner showing?
  final bool showStatsBanner;

  /// Replay graphics showing?
  final bool showReplayGraphics;

  /// Lower third (commentary credit) showing?
  final bool showLowerThird;

  /// Lower third text
  final String? lowerThirdText;

  /// Graphics alpha (0-1 for fade)
  final double graphicsAlpha;

  const GraphicsState({
    this.showRoundBanner = false,
    this.roundNumber,
    this.showStatsBanner = false,
    this.showReplayGraphics = false,
    this.showLowerThird = false,
    this.lowerThirdText,
    this.graphicsAlpha = 1.0,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'showRoundBanner': showRoundBanner,
      'roundNumber': roundNumber,
      'showStatsBanner': showStatsBanner,
      'showReplayGraphics': showReplayGraphics,
      'showLowerThird': showLowerThird,
      'lowerThirdText': lowerThirdText,
      'graphicsAlpha': graphicsAlpha,
    };
  }

  factory GraphicsState.fromFirestore(Map<String, dynamic> data) {
    return GraphicsState(
      showRoundBanner: data['showRoundBanner'] as bool? ?? false,
      roundNumber: data['roundNumber'] as int?,
      showStatsBanner: data['showStatsBanner'] as bool? ?? false,
      showReplayGraphics: data['showReplayGraphics'] as bool? ?? false,
      showLowerThird: data['showLowerThird'] as bool? ?? false,
      lowerThirdText: data['lowerThirdText'] as String?,
      graphicsAlpha: (data['graphicsAlpha'] as num?)?.toDouble() ?? 1.0,
    );
  }

  GraphicsState copyWith({
    bool? showRoundBanner,
    int? roundNumber,
    bool? showStatsBanner,
    bool? showReplayGraphics,
    bool? showLowerThird,
    String? lowerThirdText,
    double? graphicsAlpha,
  }) {
    return GraphicsState(
      showRoundBanner: showRoundBanner ?? this.showRoundBanner,
      roundNumber: roundNumber ?? this.roundNumber,
      showStatsBanner: showStatsBanner ?? this.showStatsBanner,
      showReplayGraphics: showReplayGraphics ?? this.showReplayGraphics,
      showLowerThird: showLowerThird ?? this.showLowerThird,
      lowerThirdText: lowerThirdText ?? this.lowerThirdText,
      graphicsAlpha: graphicsAlpha ?? this.graphicsAlpha,
    );
  }

  @override
  List<Object?> get props => [
    showRoundBanner,
    roundNumber,
    showStatsBanner,
    showReplayGraphics,
    showLowerThird,
    lowerThirdText,
    graphicsAlpha,
  ];
}

/// ── Broadcast Session ──
class BroadcastSession extends Equatable {
  /// Unique session ID
  final String id;

  /// Current broadcast mode
  final BroadcastMode mode;

  /// Active camera ID
  final String? activeCameraId;

  /// All available cameras
  final List<CameraProfile> cameras;

  /// Replay queue (pending replays)
  final List<ReplayMarker> replayQueue;

  /// Current replay being played (if any)
  final ReplayMarker? currentReplay;

  /// Timeline markers (all marked moments)
  final List<ReplayMarker> markers;

  /// Graphics overlay state
  final GraphicsState graphicsState;

  /// Active commentary track ID
  final String? commentaryTrackId;

  /// Broadcast started at
  final DateTime startedAt;

  /// Last updated
  final DateTime lastUpdatedAt;

  /// Is broadcast live on the wire?
  final bool isLiveOnWire;

  const BroadcastSession({
    required this.id,
    this.mode = BroadcastMode.live,
    this.activeCameraId,
    this.cameras = const [],
    this.replayQueue = const [],
    this.currentReplay,
    this.markers = const [],
    this.graphicsState = const GraphicsState(),
    this.commentaryTrackId,
    required this.startedAt,
    required this.lastUpdatedAt,
    this.isLiveOnWire = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'mode': mode.toString().split('.').last,
      'activeCameraId': activeCameraId,
      'replayQueueCount': replayQueue.length,
      'markerCount': markers.length,
      'commentaryTrackId': commentaryTrackId,
      'startedAt': Timestamp.fromDate(startedAt),
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
      'isLiveOnWire': isLiveOnWire,
    };
  }

  factory BroadcastSession.fromFirestore(Map<String, dynamic> data) {
    return BroadcastSession(
      id: data['id'] as String? ?? '',
      mode: _parseBroadcastMode(data['mode'] as String?),
      activeCameraId: data['activeCameraId'] as String?,
      cameras: const [], // Populated separately
      replayQueue: const [],
      currentReplay: null,
      markers: const [],
      graphicsState: const GraphicsState(),
      commentaryTrackId: data['commentaryTrackId'] as String?,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdatedAt:
          (data['lastUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isLiveOnWire: data['isLiveOnWire'] as bool? ?? false,
    );
  }

  BroadcastSession copyWith({
    String? id,
    BroadcastMode? mode,
    String? activeCameraId,
    List<CameraProfile>? cameras,
    List<ReplayMarker>? replayQueue,
    ReplayMarker? currentReplay,
    List<ReplayMarker>? markers,
    GraphicsState? graphicsState,
    String? commentaryTrackId,
    DateTime? startedAt,
    DateTime? lastUpdatedAt,
    bool? isLiveOnWire,
  }) {
    return BroadcastSession(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      activeCameraId: activeCameraId ?? this.activeCameraId,
      cameras: cameras ?? this.cameras,
      replayQueue: replayQueue ?? this.replayQueue,
      currentReplay: currentReplay ?? this.currentReplay,
      markers: markers ?? this.markers,
      graphicsState: graphicsState ?? this.graphicsState,
      commentaryTrackId: commentaryTrackId ?? this.commentaryTrackId,
      startedAt: startedAt ?? this.startedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      isLiveOnWire: isLiveOnWire ?? this.isLiveOnWire,
    );
  }

  @override
  List<Object?> get props => [
    id,
    mode,
    activeCameraId,
    cameras,
    replayQueue,
    currentReplay,
    markers,
    graphicsState,
    commentaryTrackId,
    startedAt,
    lastUpdatedAt,
    isLiveOnWire,
  ];
}

/// ── Helpers ──
BroadcastMode _parseBroadcastMode(String? mode) {
  switch (mode) {
    case 'replay':
      return BroadcastMode.replay;
    case 'paused':
      return BroadcastMode.paused;
    case 'slowMotion':
      return BroadcastMode.slowMotion;
    default:
      return BroadcastMode.live;
  }
}

CameraAngle _parseCameraAngle(String? angle) {
  switch (angle) {
    case 'closeup':
      return CameraAngle.closeup;
    case 'ground':
      return CameraAngle.ground;
    case 'overhead':
      return CameraAngle.overhead;
    case 'replay':
      return CameraAngle.replay;
    default:
      return CameraAngle.wide;
  }
}
