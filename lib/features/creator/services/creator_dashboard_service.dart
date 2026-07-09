import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/creator_profile_model.dart';
import '../models/creator_earnings_model.dart';
import '../models/clip_analytics_model.dart';

/// Aggregates all dashboard data for a creator
/// Combines profile, earnings, clips, and analytics into one view
class CreatorDashboardService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CreatorProfile? _profile;
  CreatorEarnings? _currentMonthEarnings;
  List<CreatorEarnings> _earningsHistory = [];
  List<ClipAnalytics> _recentClips = [];
  ClipAnalytics? _topTrendingClip;

  // Getters
  CreatorProfile? get profile => _profile;
  CreatorEarnings? get currentMonthEarnings => _currentMonthEarnings;
  List<CreatorEarnings> get earningsHistory => _earningsHistory;
  List<ClipAnalytics> get recentClips => _recentClips;
  ClipAnalytics? get topTrendingClip => _topTrendingClip;

  bool get isLoaded =>
      _profile != null &&
      _currentMonthEarnings != null &&
      _recentClips.isNotEmpty;

  /// Initialize dashboard for a creator
  Future<void> initializeDashboard(String creatorId) async {
    try {
      await Future.wait([
        _loadProfile(creatorId),
        _loadCurrentMonthEarnings(creatorId),
        _loadRecentClips(creatorId),
      ]);

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error initializing dashboard: $e');
    }
  }

  /// Load creator profile
  Future<void> _loadProfile(String creatorId) async {
    try {
      final doc = await _firestore
          .collection('creator_dashboards')
          .doc(creatorId)
          .collection('profile')
          .doc('info')
          .get();

      if (doc.exists) {
        _profile = CreatorProfile.fromFirestore(doc.data() ?? {});
      }
    } catch (e) {
      debugPrint('❌ Error loading profile: $e');
    }
  }

  /// Load current month earnings
  Future<void> _loadCurrentMonthEarnings(String creatorId) async {
    try {
      final now = DateTime.now();
      final monthKey = '${now.month}_${now.year}';

      final doc = await _firestore
          .collection('creator_dashboards')
          .doc(creatorId)
          .collection('earnings')
          .doc(monthKey)
          .get();

      if (doc.exists) {
        _currentMonthEarnings = CreatorEarnings.fromFirestore(doc.data() ?? {});
      } else {
        // Create default for current month
        _currentMonthEarnings = CreatorEarnings(
          creatorId: creatorId,
          month: now.month,
          year: now.year,
          totalEarnings: 0.0,
          clipsGenerated: 0,
          totalViews: 0,
          totalLikes: 0,
          totalShares: 0,
          totalConversions: 0,
          conversionRate: 0.0,
          avgEarningsPerClip: 0.0,
          nextPayoutDate: now.add(const Duration(days: 7)),
          payoutProcessed: false,
          createdAt: now,
          updatedAt: now,
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading earnings: $e');
    }
  }

  /// Load recent clips for creator
  Future<void> _loadRecentClips(String creatorId) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('social_clips')
          .where('creatorId', isEqualTo: creatorId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      _recentClips = snapshot.docs
          .map((doc) => ClipAnalytics.fromFirestore(doc.data()))
          .toList();

      // Find top trending clip
      if (_recentClips.isNotEmpty) {
        _topTrendingClip = _recentClips.reduce(
          (a, b) => a.trendingScore > b.trendingScore ? a : b,
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading clips: $e');
    }
  }

  /// Load earnings history (all months)
  Future<List<CreatorEarnings>> loadEarningsHistory(String creatorId) async {
    try {
      final snapshot = await _firestore
          .collection('creator_dashboards')
          .doc(creatorId)
          .collection('earnings')
          .orderBy('createdAt', descending: true)
          .limit(12)
          .get();

      _earningsHistory = snapshot.docs
          .map((doc) => CreatorEarnings.fromFirestore(doc.data()))
          .toList();

      notifyListeners();
      return _earningsHistory;
    } catch (e) {
      debugPrint('❌ Error loading earnings history: $e');
      return [];
    }
  }

  /// Refresh all dashboard data
  Future<void> refreshDashboard(String creatorId) async {
    await initializeDashboard(creatorId);
  }

  /// Get total lifetime earnings
  double getTotalLifetimeEarnings() {
    return _earningsHistory.fold<double>(
      0.0,
      (sum, earnings) => sum + earnings.totalEarnings,
    );
  }

  /// Get average monthly earnings
  double getAverageMonthlyEarnings() {
    if (_earningsHistory.isEmpty) return 0.0;
    final total = getTotalLifetimeEarnings();
    return total / _earningsHistory.length;
  }

  /// Get trend: is earnings going up or down?
  String getEarningsTrend() {
    if (_earningsHistory.length < 2) return 'N/A';

    final thisMonth = _earningsHistory[0];
    final lastMonth = _earningsHistory[1];

    if (thisMonth.totalEarnings > lastMonth.totalEarnings) {
      return '📈 UP';
    } else if (thisMonth.totalEarnings < lastMonth.totalEarnings) {
      return '📉 DOWN';
    }
    return '➡️ FLAT';
  }

  @override
  void dispose() {
    super.dispose();
  }
}
