import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' hide TargetPlatform;

/// Blotato Viral AI Coach integration service.
///
/// Flow: Upload draft video → Backend proxy → Blotato API → Feedback + Hooks + Hashtags
/// Supports: TikTok, Instagram Reels, YouTube Shorts analysis
class BlotatoViralCoachService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Collections ──
  static const _analysisCol = 'video_analyses';
  static const _hooksCol = 'viral_hooks_library';

  bool _isAnalyzing = false;
  bool get isAnalyzing => _isAnalyzing;

  VideoAnalysis? _latestAnalysis;
  VideoAnalysis? get latestAnalysis => _latestAnalysis;

  // ─── Submit Video for Analysis ─────────────────────────────────────────
  /// Creates an analysis request doc that triggers the Cloud Function proxy.
  Future<String> submitForAnalysis({
    required String userId,
    required String videoUrl,
    required String videoTitle,
    String? thumbnailUrl,
    TargetPlatform targetPlatform = TargetPlatform.tiktok,
  }) async {
    _isAnalyzing = true;
    notifyListeners();

    final doc = await _firestore.collection(_analysisCol).add({
      'userId': userId,
      'videoUrl': videoUrl,
      'videoTitle': videoTitle,
      'thumbnailUrl': thumbnailUrl,
      'targetPlatform': targetPlatform.name,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Listen for completion
    _listenForResult(doc.id);
    return doc.id;
  }

  // ─── Listen for Analysis Result ────────────────────────────────────────
  void _listenForResult(String analysisId) {
    _firestore.collection(_analysisCol).doc(analysisId).snapshots().listen((
      snap,
    ) {
      final data = snap.data();
      if (data == null) return;

      final status = data['status'] as String? ?? 'pending';
      if (status == 'completed') {
        _latestAnalysis = VideoAnalysis.fromFirestore(snap.id, data);
        _isAnalyzing = false;
        notifyListeners();
      } else if (status == 'failed') {
        _isAnalyzing = false;
        notifyListeners();
      }
    });
  }

  // ─── Get Analysis by ID ────────────────────────────────────────────────
  Future<VideoAnalysis?> getAnalysis(String analysisId) async {
    final snap = await _firestore
        .collection(_analysisCol)
        .doc(analysisId)
        .get();
    if (!snap.exists) return null;
    return VideoAnalysis.fromFirestore(snap.id, snap.data()!);
  }

  // ─── Get User's Analysis History ───────────────────────────────────────
  Future<List<VideoAnalysis>> getUserAnalyses(String userId) async {
    final snap = await _firestore
        .collection(_analysisCol)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    return snap.docs
        .map((d) => VideoAnalysis.fromFirestore(d.id, d.data()))
        .toList();
  }

  // ─── Get Viral Hooks Library ───────────────────────────────────────────
  Future<List<ViralHook>> getViralHooks({
    String? category,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(_hooksCol);
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    final snap = await query
        .orderBy('useCount', descending: true)
        .limit(limit)
        .get();

    return snap.docs
        .map((d) => ViralHook.fromFirestore(d.id, d.data()))
        .toList();
  }

  // ─── Apply Hook to Video ───────────────────────────────────────────────
  Future<void> applyHookToAnalysis(String analysisId, String hookText) async {
    await _firestore.collection(_analysisCol).doc(analysisId).update({
      'appliedHook': hookText,
      'hookAppliedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Reanalyze ────────────────────────────────────────────────────────
  Future<String> reanalyze(String originalAnalysisId) async {
    final original = await _firestore
        .collection(_analysisCol)
        .doc(originalAnalysisId)
        .get();
    if (!original.exists) throw Exception('Original analysis not found');

    final data = original.data()!;
    return submitForAnalysis(
      userId: data['userId'] as String,
      videoUrl: data['videoUrl'] as String,
      videoTitle: data['videoTitle'] as String,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      targetPlatform: TargetPlatform.values.firstWhere(
        (p) => p.name == (data['targetPlatform'] ?? 'tiktok'),
        orElse: () => TargetPlatform.tiktok,
      ),
    );
  }
}

// ─── Target Platforms ────────────────────────────────────────────────────

enum TargetPlatform { tiktok, instagram, youtube, facebook, threads, linkedin }

extension TargetPlatformExt on TargetPlatform {
  String get label {
    switch (this) {
      case TargetPlatform.tiktok:
        return 'TikTok';
      case TargetPlatform.instagram:
        return 'Instagram Reels';
      case TargetPlatform.youtube:
        return 'YouTube Shorts';
      case TargetPlatform.facebook:
        return 'Facebook Reels';
      case TargetPlatform.threads:
        return 'Threads';
      case TargetPlatform.linkedin:
        return 'LinkedIn';
    }
  }
}

// ─── Video Analysis Model ────────────────────────────────────────────────

class VideoAnalysis {
  final String id;
  final String userId;
  final String videoUrl;
  final String videoTitle;
  final String? thumbnailUrl;
  final String status;
  final int overallScore;
  final ScoreBreakdown scores;
  final String overallFeedback;
  final List<String> suggestedHooks;
  final HashtagRecommendation hashtags;
  final List<String> improvementTips;
  final DateTime? createdAt;

  const VideoAnalysis({
    required this.id,
    required this.userId,
    required this.videoUrl,
    required this.videoTitle,
    this.thumbnailUrl,
    required this.status,
    required this.overallScore,
    required this.scores,
    required this.overallFeedback,
    required this.suggestedHooks,
    required this.hashtags,
    required this.improvementTips,
    this.createdAt,
  });

  factory VideoAnalysis.fromFirestore(String id, Map<String, dynamic> data) {
    final scoresMap =
        data['scores'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final hashtagsMap =
        data['hashtags'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return VideoAnalysis(
      id: id,
      userId: data['userId'] as String? ?? '',
      videoUrl: data['videoUrl'] as String? ?? '',
      videoTitle: data['videoTitle'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String?,
      status: data['status'] as String? ?? 'pending',
      overallScore: data['overallScore'] as int? ?? 0,
      scores: ScoreBreakdown.fromMap(scoresMap),
      overallFeedback: data['overallFeedback'] as String? ?? '',
      suggestedHooks: List<String>.from(data['suggestedHooks'] ?? []),
      hashtags: HashtagRecommendation.fromMap(hashtagsMap),
      improvementTips: List<String>.from(data['improvementTips'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  bool get isPassing => overallScore >= 70;
}

// ─── Score Breakdown ─────────────────────────────────────────────────────

class ScoreBreakdown {
  final int openingHook;
  final int painBenefitHook;
  final int noSoundClarity;
  final int infoDensity;
  final int emotionalResonance;

  const ScoreBreakdown({
    this.openingHook = 0,
    this.painBenefitHook = 0,
    this.noSoundClarity = 0,
    this.infoDensity = 0,
    this.emotionalResonance = 0,
  });

  factory ScoreBreakdown.fromMap(Map<String, dynamic> map) {
    return ScoreBreakdown(
      openingHook: map['openingHook'] as int? ?? 0,
      painBenefitHook: map['painBenefitHook'] as int? ?? 0,
      noSoundClarity: map['noSoundClarity'] as int? ?? 0,
      infoDensity: map['infoDensity'] as int? ?? 0,
      emotionalResonance: map['emotionalResonance'] as int? ?? 0,
    );
  }

  List<MapEntry<String, int>> get entries => [
    MapEntry('Opening Hook', openingHook),
    MapEntry('Pain & Benefit', painBenefitHook),
    MapEntry('No-Sound Clarity', noSoundClarity),
    MapEntry('Info Density', infoDensity),
    MapEntry('Emotional Resonance', emotionalResonance),
  ];
}

// ─── Hashtag Recommendation ──────────────────────────────────────────────

class HashtagRecommendation {
  final List<String> broad;
  final List<String> niche;

  const HashtagRecommendation({this.broad = const [], this.niche = const []});

  factory HashtagRecommendation.fromMap(Map<String, dynamic> map) {
    return HashtagRecommendation(
      broad: List<String>.from(map['broad'] ?? []),
      niche: List<String>.from(map['niche'] ?? []),
    );
  }

  List<String> get all => [...broad, ...niche];
}

// ─── Viral Hook Model ────────────────────────────────────────────────────

class ViralHook {
  final String id;
  final String text;
  final String category;
  final int useCount;
  final double avgScoreImprovement;

  const ViralHook({
    required this.id,
    required this.text,
    required this.category,
    this.useCount = 0,
    this.avgScoreImprovement = 0,
  });

  factory ViralHook.fromFirestore(String id, Map<String, dynamic> data) {
    return ViralHook(
      id: id,
      text: data['text'] as String? ?? '',
      category: data['category'] as String? ?? 'general',
      useCount: data['useCount'] as int? ?? 0,
      avgScoreImprovement:
          (data['avgScoreImprovement'] as num?)?.toDouble() ?? 0,
    );
  }
}
