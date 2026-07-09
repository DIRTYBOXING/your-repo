import 'package:flutter/foundation.dart';

import '../models/social_clip_model.dart';
import '../services/auto_clip_generator_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SOCIAL FEED CONTROLLER — Feed State Management
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Manages the state of the social feed:
///   - Trending clips
///   - Recent clips
///   - Live fights
///   - Filter state
///   - Loading state
///
/// ═══════════════════════════════════════════════════════════════════════════

enum FeedTab { viral, live, highlights, recent }

class SocialFeedController extends ChangeNotifier {
  final AutoClipGeneratorService _clipGeneratorService;

  // ── State ──
  FeedTab _activeTab = FeedTab.viral;
  bool _isLoading = false;
  String? _error;

  final List<SocialClip> _trendingClips = [];
  final List<SocialClip> _recentClips = [];
  final List<SocialClip> _highlightClips = [];

  // ── Event Context ──
  String? _eventId;
  String? _sessionId;

  // ── Getters ──
  FeedTab get activeTab => _activeTab;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<SocialClip> get trendingClips => List.unmodifiable(_trendingClips);
  List<SocialClip> get recentClips => List.unmodifiable(_recentClips);
  List<SocialClip> get highlightClips => List.unmodifiable(_highlightClips);

  /// Get clips for current tab
  List<SocialClip> get activeClips {
    switch (_activeTab) {
      case FeedTab.viral:
        return _trendingClips;
      case FeedTab.live:
        return _recentClips.where((c) => _isRecentlyCreated(c)).toList();
      case FeedTab.highlights:
        return _highlightClips;
      case FeedTab.recent:
        return _recentClips;
    }
  }

  SocialFeedController({required AutoClipGeneratorService clipGeneratorService})
    : _clipGeneratorService = clipGeneratorService;

  /// Initialize feed for an event
  Future<void> initializeForEvent(String eventId, String sessionId) async {
    try {
      _eventId = eventId;
      _sessionId = sessionId;
      await refreshFeed();
    } catch (e) {
      _error = 'Failed to initialize feed: $e';
      notifyListeners();
    }
  }

  /// Refresh all feed data
  Future<void> refreshFeed() async {
    if (_eventId == null || _sessionId == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Fetch trending clips
      final trending = await _clipGeneratorService.getTrendingClips(
        _eventId!,
        _sessionId!,
        limit: 20,
      );
      _trendingClips.clear();
      _trendingClips.addAll(trending);

      // Fetch recent clips
      final recent = await _clipGeneratorService.getRecentClips(
        _eventId!,
        _sessionId!,
        limit: 30,
      );
      _recentClips.clear();
      _recentClips.addAll(recent);

      // Fetch highlight clips
      final highlights = await _clipGeneratorService.getClipsByType(
        _eventId!,
        _sessionId!,
        ClipType.highlight,
        limit: 15,
      );
      _highlightClips.clear();
      _highlightClips.addAll(highlights);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to refresh feed: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Switch feed tab
  void switchTab(FeedTab tab) {
    if (_activeTab != tab) {
      _activeTab = tab;
      notifyListeners();
    }
  }

  /// Record engagement on a clip
  Future<void> recordEngagement(SocialClip clip, String metric) async {
    if (_eventId == null || _sessionId == null) return;

    try {
      await _clipGeneratorService.incrementEngagement(
        _eventId!,
        _sessionId!,
        clip.id,
        metric,
      );

      // Update local clip
      final index = _findClipIndex(clip.id);
      if (index >= 0) {
        final currentClip = _getCurrentClipList()[index];
        final updatedEngagement = currentClip.engagement.copyWith(
          views: metric == 'views'
              ? currentClip.engagement.views + 1
              : currentClip.engagement.views,
          likes: metric == 'likes'
              ? currentClip.engagement.likes + 1
              : currentClip.engagement.likes,
          shares: metric == 'shares'
              ? currentClip.engagement.shares + 1
              : currentClip.engagement.shares,
          comments: metric == 'comments'
              ? currentClip.engagement.comments + 1
              : currentClip.engagement.comments,
          ppvConversions: metric == 'ppvConversions'
              ? currentClip.engagement.ppvConversions + 1
              : currentClip.engagement.ppvConversions,
        );

        final updatedClip = currentClip.copyWith(
          engagement: updatedEngagement,
          trendingScore: updatedEngagement.calculateTrendingScore(),
        );

        _getCurrentClipList()[index] = updatedClip;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error recording engagement: $e');
    }
  }

  /// Record PPV conversion
  Future<void> recordPPVConversion(
    SocialClip clip,
    String userId,
    double amount,
  ) async {
    if (_eventId == null || _sessionId == null) return;

    try {
      await _clipGeneratorService.recordPPVConversion(
        _eventId!,
        _sessionId!,
        clip.id,
        userId,
        amount,
      );

      // Record engagement
      await recordEngagement(clip, 'ppvConversions');
    } catch (e) {
      debugPrint('Error recording PPV conversion: $e');
    }
  }

  /// Find clip index in current list
  int _findClipIndex(String clipId) {
    final list = _getCurrentClipList();
    return list.indexWhere((c) => c.id == clipId);
  }

  /// Get current active clip list
  List<SocialClip> _getCurrentClipList() {
    switch (_activeTab) {
      case FeedTab.viral:
        return _trendingClips;
      case FeedTab.live:
        return _recentClips;
      case FeedTab.highlights:
        return _highlightClips;
      case FeedTab.recent:
        return _recentClips;
    }
  }

  /// Check if clip was recently created (within 5 minutes)
  bool _isRecentlyCreated(SocialClip clip) {
    return DateTime.now().difference(clip.createdAt).inMinutes < 5;
  }

  /// Get clips for a specific type
  List<SocialClip> getClipsByType(ClipType type) {
    return activeClips.where((c) => c.clipType == type).toList();
  }

  /// Get trending threshold score
  double getTrendingThreshold() {
    if (_trendingClips.isEmpty) return 0.0;
    return _trendingClips.last.trendingScore;
  }
}
