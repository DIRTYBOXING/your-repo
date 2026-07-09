import 'package:flutter/foundation.dart';

import '../models/creator_earnings_model.dart';
import '../models/creator_insights_model.dart';
import '../models/creator_profile_model.dart';
import '../models/clip_analytics_model.dart';
import '../services/creator_analytics_service.dart';
import '../services/creator_badge_service.dart';
import '../services/creator_dashboard_service.dart';
import '../services/creator_insights_engine.dart';
import '../services/creator_rank_service.dart';
import '../../core/utils/creator_hero_seeder.dart';

/// Central controller for the Creator Dashboard
/// Manages state, orchestrates service calls, handles UI interactions
class CreatorDashboardController extends ChangeNotifier {
  final CreatorDashboardService _dashboardService;
  final CreatorAnalyticsService _analyticsService;
  final CreatorInsightsEngine _insightsEngine;
  final CreatorBadgeService _badgeService;
  final CreatorRankService _rankService;

  // State
  CreatorProfile? _profile;
  CreatorEarnings? _currentMonthEarnings;
  List<ClipAnalytics> _recentClips = [];
  CreatorInsights? _insights;
  List<Map<String, dynamic>> _badgeProgress = [];
  int _creatorRank = 9999;
  String _selectedTab = 'overview';
  bool _isLoading = false;
  String? _error;

  // Getters
  CreatorProfile? get profile => _profile;
  CreatorEarnings? get currentMonthEarnings => _currentMonthEarnings;
  List<ClipAnalytics> get recentClips => _recentClips;
  CreatorInsights? get insights => _insights;
  List<Map<String, dynamic>> get badgeProgress => _badgeProgress;
  int get creatorRank => _creatorRank;
  String get selectedTab => _selectedTab;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CreatorDashboardController(
    this._dashboardService,
    this._analyticsService,
    this._insightsEngine,
    this._badgeService,
    this._rankService,
  );

  /// Load hero creator test data (Phase 2A mock)
  Future<void> loadHeroCreator() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load mock data directly
      _profile = CreatorHeroSeeder.getMockHeroProfile();
      _currentMonthEarnings = CreatorHeroSeeder.getMockHeroEarnings();
      _recentClips = CreatorHeroSeeder.getMockHeroClips();
      _insights = CreatorHeroSeeder.getMockHeroInsights();
      _creatorRank = CreatorHeroSeeder.getMockHeroRanking()['rank'];

      // Mock badge progress
      final badges = CreatorHeroSeeder.getMockHeroBadges();
      _badgeProgress = [
        {
          'badge': 'bronze',
          'earned': badges.contains('bronze'),
          'threshold': 10,
          'current': 5,
        },
        {
          'badge': 'silver',
          'earned': badges.contains('silver'),
          'threshold': 100,
          'current': 12,
        },
        {
          'badge': 'gold',
          'earned': badges.contains('gold'),
          'threshold': 500,
          'current': 12,
        },
      ];

      _isLoading = false;
      notifyListeners();
      debugPrint('✅ Hero creator loaded successfully');
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      debugPrint('❌ Error loading hero creator: $e');
      notifyListeners();
    }
  }

  /// Initialize dashboard for a creator
  Future<void> initializeDashboard(String creatorId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // For Phase 2A: Use hero creator mock if requested
      if (creatorId == CreatorHeroSeeder.heroCreatorId) {
        await loadHeroCreator();
        return;
      }

      // Load profile
      await _dashboardService.initializeDashboard(creatorId);
      _profile = _dashboardService.profile;
      _currentMonthEarnings = _dashboardService.currentMonthEarnings;
      _recentClips = _dashboardService.recentClips;

      // Load insights
      _insights = await _insightsEngine.getInsights(creatorId);

      // Load badge progress
      final totalClips = _recentClips.length;
      final badgeMap = await _badgeService.getBadgeProgress(
        creatorId,
        totalClips,
      );
      _badgeProgress = badgeMap.entries
          .map((e) => {'badge': e.key, ...e.value as Map<String, dynamic>})
          .toList();

      // Load rank
      _creatorRank = await _rankService.getCreatorRank(creatorId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      debugPrint('❌ Error initializing dashboard: $e');
      notifyListeners();
    }
  }

  /// Switch between dashboard tabs
  void switchTab(String tabName) {
    _selectedTab = tabName;
    notifyListeners();
  }

  /// Refresh all dashboard data
  Future<void> refreshDashboard(String creatorId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _dashboardService.refreshDashboard();
      _profile = _dashboardService.profile;
      _currentMonthEarnings = _dashboardService.currentMonthEarnings;
      _recentClips = _dashboardService.recentClips;

      // Regenerate insights
      _insights = await _insightsEngine.generateInsights(creatorId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      debugPrint('❌ Error refreshing dashboard: $e');
      notifyListeners();
    }
  }

  /// Get detailed analytics for a specific clip
  Future<ClipAnalytics?> getClipAnalytics(String clipId) async {
    try {
      return await _analyticsService.getClipAnalytics(clipId);
    } catch (e) {
      debugPrint('❌ Error getting clip analytics: $e');
      return null;
    }
  }

  /// Get top performing clips
  Future<List<ClipAnalytics>> getTopPerformingClips(String creatorId) async {
    try {
      final clips = await _analyticsService.getCreatorClips(creatorId);
      clips.sort((a, b) => b.conversions.compareTo(a.conversions));
      return clips.take(10).toList();
    } catch (e) {
      debugPrint('❌ Error getting top clips: $e');
      return [];
    }
  }

  /// Get best performing clip type
  Future<String?> getBestClipType(String creatorId) async {
    try {
      return await _analyticsService.getBestPerformingClipType(creatorId);
    } catch (e) {
      debugPrint('❌ Error getting best clip type: $e');
      return null;
    }
  }

  /// Get average metrics for all clips
  Future<Map<String, double>> getAverageMetrics(String creatorId) async {
    try {
      return await _analyticsService.getAverageClipMetrics(creatorId);
    } catch (e) {
      debugPrint('❌ Error getting average metrics: $e');
      return {};
    }
  }

  /// Get trending clips
  Future<List<ClipAnalytics>> getTrendingClips(String creatorId) async {
    try {
      return await _analyticsService.getTrendingClips(creatorId);
    } catch (e) {
      debugPrint('❌ Error getting trending clips: $e');
      return [];
    }
  }

  /// Get next badge to unlock
  Future<Map<String, dynamic>?> getNextBadge(String creatorId) async {
    try {
      final totalClips = _recentClips.length;
      return await _badgeService.getNextBadge(creatorId, totalClips);
    } catch (e) {
      debugPrint('❌ Error getting next badge: $e');
      return null;
    }
  }

  /// Get creator ranking info
  Future<Map<String, dynamic>> getCreatorRankingInfo(String creatorId) async {
    try {
      return await _rankService.getCreatorRankingInfo(creatorId);
    } catch (e) {
      debugPrint('❌ Error getting ranking info: $e');
      return {};
    }
  }

  /// Get leaderboard (top creators)
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 50}) async {
    try {
      return await _rankService.getTopCreators(limit: limit);
    } catch (e) {
      debugPrint('❌ Error getting leaderboard: $e');
      return [];
    }
  }

  /// Record an engagement event
  Future<void> recordClipEngagement(
    String clipId,
    String eventType, // view, like, share, conversion
  ) async {
    try {
      // Log to analytics
      debugPrint('📊 Recorded engagement: $eventType for clip $clipId');
      // This would typically call an analytics service
    } catch (e) {
      debugPrint('❌ Error recording engagement: $e');
    }
  }

  /// Clear dashboard state
  void clearDashboard() {
    _profile = null;
    _currentMonthEarnings = null;
    _recentClips = [];
    _insights = null;
    _badgeProgress = [];
    _creatorRank = 9999;
    _selectedTab = 'overview';
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
