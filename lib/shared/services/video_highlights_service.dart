import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// AI-based video highlights service — Cloudinary-style interest graph.
///
/// Analyzes fight videos via Gemini (Cloud Function) to produce
/// per-segment interest scores, key moments, and auto-generated clips.
///
/// Firestore: `video_highlights/{videoId}`
/// Cloud Function: `analyzeVideoHighlights`
class VideoHighlightsService extends ChangeNotifier {
  static final VideoHighlightsService _instance =
      VideoHighlightsService._internal();
  factory VideoHighlightsService() => _instance;
  VideoHighlightsService._internal();

  final _db = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );
  static const _col = 'video_highlights';

  // ─── Request Analysis ─────────────────────────────────────────────────
  /// Submit a video for AI highlight analysis.
  /// Returns the highlight doc ID for polling.
  Future<String> analyzeVideo({
    required String videoUrl,
    required String videoTitle,
    String? userId,
    String? eventId,
    double? durationSeconds,
    HighlightAnalysisMode mode = HighlightAnalysisMode.full,
  }) async {
    // Check for existing analysis first
    final existing = await _db
        .collection(_col)
        .where('videoUrl', isEqualTo: videoUrl)
        .where('status', isEqualTo: 'completed')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return existing.docs.first.id;

    // Create analysis request
    final doc = await _db.collection(_col).add({
      'videoUrl': videoUrl,
      'videoTitle': videoTitle,
      'userId': userId,
      'eventId': eventId,
      'durationSeconds': durationSeconds,
      'mode': mode.name,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Trigger Cloud Function
    try {
      await _functions.httpsCallable('analyzeVideoHighlights').call<dynamic>({
        'highlightId': doc.id,
        'videoUrl': videoUrl,
        'videoTitle': videoTitle,
        'durationSeconds': durationSeconds,
        'mode': mode.name,
      });
    } catch (e) {
      debugPrint('Highlight analysis trigger failed: $e');
      // Cloud Function trigger may work via Firestore onCreate instead
    }

    return doc.id;
  }

  // ─── Get Highlights (Realtime) ─────────────────────────────────────────
  Stream<VideoHighlights?> streamHighlights(String highlightId) {
    return _db.collection(_col).doc(highlightId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return VideoHighlights.fromFirestore(snap.id, snap.data()!);
    });
  }

  /// One-shot fetch
  Future<VideoHighlights?> getHighlights(String highlightId) async {
    final snap = await _db.collection(_col).doc(highlightId).get();
    if (!snap.exists) return null;
    return VideoHighlights.fromFirestore(snap.id, snap.data()!);
  }

  /// Find highlights for a video URL
  Future<VideoHighlights?> getHighlightsForVideo(String videoUrl) async {
    final snap = await _db
        .collection(_col)
        .where('videoUrl', isEqualTo: videoUrl)
        .where('status', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return VideoHighlights.fromFirestore(doc.id, doc.data());
  }

  // ─── Get Channel Highlights ────────────────────────────────────────────
  /// All analyzed videos for a user/channel
  Stream<List<VideoHighlights>> streamChannelHighlights(String userId) {
    return _db
        .collection(_col)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => VideoHighlights.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  // ─── Generate Demo Highlights ──────────────────────────────────────────
  /// Produces realistic fight highlight data for demo/offline mode.
  static VideoHighlights generateDemoHighlights({
    String videoTitle = 'UFC 300 Main Event — Championship Round',
    double durationSeconds = 300.0,
    int segmentCount = 60,
  }) {
    final segmentDuration = durationSeconds / segmentCount;
    final segments = <HighlightSegment>[];

    // Fight-realistic interest curve: peaks at exchanges, KD moments
    final peakIndices = {
      (segmentCount * 0.08).round(), // Early action
      (segmentCount * 0.22).round(), // First exchange
      (segmentCount * 0.35).round(), // Mid-round flurry
      (segmentCount * 0.52).round(), // Momentum shift
      (segmentCount * 0.68).round(), // Near-finish sequence
      (segmentCount * 0.78).round(), // Knockdown
      (segmentCount * 0.92).round(), // Finish/Decision
    };

    for (var i = 0; i < segmentCount; i++) {
      final startTime = i * segmentDuration;
      double score;

      if (peakIndices.contains(i)) {
        score = 0.82 + (i.hashCode % 18) / 100; // 0.82–0.99
      } else if (peakIndices.any((p) => (p - i).abs() <= 1)) {
        score = 0.55 + (i.hashCode % 25) / 100; // Near-peak buildup
      } else if (peakIndices.any((p) => (p - i).abs() <= 3)) {
        score = 0.35 + (i.hashCode % 20) / 100; // Shoulder
      } else {
        score = 0.10 + (i.hashCode % 25) / 100; // Baseline
      }

      segments.add(
        HighlightSegment(
          startTime: startTime,
          endTime: startTime + segmentDuration,
          interestScore: score.clamp(0.0, 1.0),
          label: peakIndices.contains(i) ? _demoLabel(i, segmentCount) : null,
        ),
      );
    }

    final keyMoments = [
      KeyMoment(
        timestamp: durationSeconds * 0.22,
        label: 'Heavy overhand right lands',
        interestScore: 0.88,
        type: MomentType.strike,
      ),
      KeyMoment(
        timestamp: durationSeconds * 0.52,
        label: 'Momentum shift — body kick',
        interestScore: 0.85,
        type: MomentType.technique,
      ),
      KeyMoment(
        timestamp: durationSeconds * 0.78,
        label: 'Knockdown!',
        interestScore: 0.97,
        type: MomentType.knockdown,
      ),
      KeyMoment(
        timestamp: durationSeconds * 0.92,
        label: 'TKO finish',
        interestScore: 0.99,
        type: MomentType.finish,
      ),
    ];

    return VideoHighlights(
      id: 'demo_highlights',
      videoUrl: '',
      videoTitle: videoTitle,
      status: 'completed',
      durationSeconds: durationSeconds,
      segments: segments,
      keyMoments: keyMoments,
      overallExcitement: 0.76,
      peakMomentTimestamp: durationSeconds * 0.78,
      suggestedClipStart: durationSeconds * 0.75,
      suggestedClipEnd: durationSeconds * 0.95,
    );
  }

  static String _demoLabel(int index, int total) {
    final pos = index / total;
    if (pos < 0.15) return 'Opening exchange';
    if (pos < 0.30) return 'Heavy strikes';
    if (pos < 0.45) return 'Flurry';
    if (pos < 0.60) return 'Momentum shift';
    if (pos < 0.75) return 'Near-finish';
    if (pos < 0.85) return 'Knockdown';
    return 'Finish sequence';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MODELS
// ═════════════════════════════════════════════════════════════════════════════

enum HighlightAnalysisMode { quick, full, clipGeneration }

enum MomentType {
  strike,
  takedown,
  submission,
  knockdown,
  finish,
  technique,
  crowd,
  other,
}

/// Full highlight analysis result for a video
class VideoHighlights {
  final String id;
  final String videoUrl;
  final String videoTitle;
  final String status; // pending, processing, completed, failed
  final double durationSeconds;
  final List<HighlightSegment> segments;
  final List<KeyMoment> keyMoments;
  final double overallExcitement; // 0.0–1.0
  final double? peakMomentTimestamp;
  final double? suggestedClipStart;
  final double? suggestedClipEnd;
  final String? userId;
  final String? eventId;
  final DateTime? createdAt;

  const VideoHighlights({
    required this.id,
    required this.videoUrl,
    required this.videoTitle,
    this.status = 'pending',
    this.durationSeconds = 0,
    this.segments = const [],
    this.keyMoments = const [],
    this.overallExcitement = 0,
    this.peakMomentTimestamp,
    this.suggestedClipStart,
    this.suggestedClipEnd,
    this.userId,
    this.eventId,
    this.createdAt,
  });

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending' || status == 'processing';

  /// Normalized interest scores (0.0–1.0) for the graph
  List<double> get interestCurve =>
      segments.map((s) => s.interestScore).toList();

  /// Interest score at a given playback position (0.0–1.0 of duration)
  double interestAt(double position) {
    if (segments.isEmpty) return 0;
    final idx = (position * segments.length)
        .clamp(0, segments.length - 1)
        .toInt();
    return segments[idx].interestScore;
  }

  /// Suggested highlight clip duration
  double get suggestedClipDuration =>
      (suggestedClipEnd ?? durationSeconds) - (suggestedClipStart ?? 0);

  factory VideoHighlights.fromFirestore(String id, Map<String, dynamic> data) {
    return VideoHighlights(
      id: id,
      videoUrl: data['videoUrl'] as String? ?? '',
      videoTitle: data['videoTitle'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      durationSeconds: (data['durationSeconds'] as num?)?.toDouble() ?? 0,
      segments:
          (data['segments'] as List<dynamic>?)
              ?.map((s) => HighlightSegment.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      keyMoments:
          (data['keyMoments'] as List<dynamic>?)
              ?.map((m) => KeyMoment.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      overallExcitement: (data['overallExcitement'] as num?)?.toDouble() ?? 0,
      peakMomentTimestamp: (data['peakMomentTimestamp'] as num?)?.toDouble(),
      suggestedClipStart: (data['suggestedClipStart'] as num?)?.toDouble(),
      suggestedClipEnd: (data['suggestedClipEnd'] as num?)?.toDouble(),
      userId: data['userId'] as String?,
      eventId: data['eventId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// A single time segment with an interest score
class HighlightSegment {
  final double startTime;
  final double endTime;
  final double interestScore; // 0.0–1.0
  final String? label;

  const HighlightSegment({
    required this.startTime,
    required this.endTime,
    required this.interestScore,
    this.label,
  });

  factory HighlightSegment.fromMap(Map<String, dynamic> m) {
    return HighlightSegment(
      startTime: (m['startTime'] as num?)?.toDouble() ?? 0,
      endTime: (m['endTime'] as num?)?.toDouble() ?? 0,
      interestScore: (m['interestScore'] as num?)?.toDouble() ?? 0,
      label: m['label'] as String?,
    );
  }
}

/// A notable moment in the video (strike, knockdown, finish, etc.)
class KeyMoment {
  final double timestamp;
  final String label;
  final double interestScore;
  final MomentType type;

  const KeyMoment({
    required this.timestamp,
    required this.label,
    required this.interestScore,
    this.type = MomentType.other,
  });

  factory KeyMoment.fromMap(Map<String, dynamic> m) {
    return KeyMoment(
      timestamp: (m['timestamp'] as num?)?.toDouble() ?? 0,
      label: m['label'] as String? ?? '',
      interestScore: (m['interestScore'] as num?)?.toDouble() ?? 0,
      type: MomentType.values.firstWhere(
        (t) => t.name == (m['type'] as String? ?? ''),
        orElse: () => MomentType.other,
      ),
    );
  }
}
