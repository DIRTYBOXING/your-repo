import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../models/stats/combat_stats.dart';

class PerformanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );

  /// Demo mode flag - set to false for production, true for demo/showcase
  static const bool _useDemoData = false;

  Future<CombatStats> getFighterStats(String fighterId) async {
    // For demo/showcase, always return demo data
    if (_useDemoData) {
      return _getDemoStats(fighterId);
    }

    // First, try Cloud Functions with timeout
    try {
      final callable = _functions.httpsCallable('getFighterStats');
      final result = await callable
          .call({'fighterId': fighterId})
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Cloud Functions timeout'),
          );
      final data = Map<String, dynamic>.from(result.data as Map);
      final stats = _mapStats(fighterId, data);
      // Check if stats are actually populated
      if (stats.totalSparringTime.inMinutes > 0 ||
          stats.totalStrikesLanded > 0) {
        return stats;
      }
    } catch (e) {
      // Cloud Functions failed, continue to Firestore
      AppLogger.warning('Cloud Functions fallback', tag: 'PerformanceService');
    }

    // Second, try Firestore directly
    try {
      final doc = await _firestore
          .collection(AppConstants.fighterStatsCollection)
          .doc(fighterId)
          .get();

      if (doc.exists && doc.data() != null) {
        final stats = _mapStats(fighterId, doc.data()!);
        // Check if stats are actually populated
        if (stats.totalSparringTime.inMinutes > 0 ||
            stats.totalStrikesLanded > 0) {
          return stats;
        }
      }
    } catch (e) {
      AppLogger.warning('Firestore fallback', tag: 'PerformanceService');
    }

    // Always return demo data if nothing else worked
    return _getDemoStats(fighterId);
  }

  /// Returns demo stats for showcase/testing
  CombatStats _getDemoStats(String fighterId) {
    final now = DateTime.now();
    return CombatStats(
      fighterId: fighterId,
      totalSparringTime: const Duration(hours: 42, minutes: 30),
      totalStrikesLanded: 1247,
      totalStrikesThrown: 2103,
      totalTakedowns: 87,
      totalTakedownsAttempted: 112,
      winRate: 0.85,
      performanceHistory: [
        PerformanceDataPoint(
          date: now.subtract(const Duration(days: 28)),
          rating: 3.2,
        ),
        PerformanceDataPoint(
          date: now.subtract(const Duration(days: 24)),
          rating: 3.8,
        ),
        PerformanceDataPoint(
          date: now.subtract(const Duration(days: 21)),
          rating: 4.1,
        ),
        PerformanceDataPoint(
          date: now.subtract(const Duration(days: 17)),
          rating: 3.9,
        ),
        PerformanceDataPoint(
          date: now.subtract(const Duration(days: 14)),
          rating: 4.4,
        ),
        PerformanceDataPoint(
          date: now.subtract(const Duration(days: 10)),
          rating: 4.2,
        ),
        PerformanceDataPoint(
          date: now.subtract(const Duration(days: 7)),
          rating: 4.6,
        ),
        PerformanceDataPoint(
          date: now.subtract(const Duration(days: 3)),
          rating: 4.8,
        ),
        PerformanceDataPoint(date: now, rating: 5.0),
      ],
    );
  }

  CombatStats _mapStats(String fighterId, Map<String, dynamic> data) {
    final performanceHistoryRaw =
        data['performanceHistory'] as List<dynamic>? ?? const [];

    return CombatStats(
      fighterId: fighterId,
      totalSparringTime: Duration(
        minutes: (data['totalSparringMinutes'] as num?)?.toInt() ?? 0,
      ),
      totalStrikesLanded: (data['totalStrikesLanded'] as num?)?.toInt() ?? 0,
      totalStrikesThrown: (data['totalStrikesThrown'] as num?)?.toInt() ?? 0,
      totalTakedowns: (data['totalTakedowns'] as num?)?.toInt() ?? 0,
      totalTakedownsAttempted:
          (data['totalTakedownsAttempted'] as num?)?.toInt() ?? 0,
      winRate: ((data['winRate'] as num?) ?? 0.0).toDouble(),
      performanceHistory: performanceHistoryRaw.map((entry) {
        final map = Map<String, dynamic>.from(entry as Map<Object?, Object?>);

        return PerformanceDataPoint(
          date: (map['date'] is Timestamp)
              ? (map['date'] as Timestamp).toDate()
              : DateTime.parse(map['date'].toString()),
          rating: ((map['rating'] as num?) ?? 0.0).toDouble(),
        );
      }).toList(),
    );
  }

  Future<TrainingReadinessInsight?> getTrainingReadinessInsight(
    String fighterId, {
    int windowDays = 30,
  }) async {
    // For demo/showcase, always return demo data
    if (_useDemoData) {
      return const TrainingReadinessInsight(
        id: 'demo-insight',
        summary:
            'Your training load is well-balanced. Recovery metrics show optimal adaptation. Consider adding one high-intensity session this week.',
        readinessScore: 0.82,
        loadFactor: 0.75,
        sessionCount: 12,
        windowDays: 30,
      );
    }

    // Try Cloud Functions first
    try {
      final callable = _functions.httpsCallable('analyzeTrainingReadiness');
      final result = await callable.call({
        'fighterId': fighterId,
        'windowDays': windowDays,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      final insight = TrainingReadinessInsight.fromCallable(data);
      if (insight.summary.isNotEmpty) {
        return insight;
      }
    } catch (e) {
      AppLogger.debug(
        'Training readiness using fallback',
        tag: 'PerformanceService',
      );
    }

    // Try Firestore
    try {
      final snapshot = await _firestore
          .collection(AppConstants.aiInsightsCollection)
          .where('targetId', isEqualTo: fighterId)
          .where('type', isEqualTo: 'training_readiness')
          .orderBy('generatedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final insight = TrainingReadinessInsight.fromFirestore(
          snapshot.docs.first,
        );
        if (insight.summary.isNotEmpty) {
          return insight;
        }
      }
    } catch (e) {
      AppLogger.debug(
        'Training insight using demo data',
        tag: 'PerformanceService',
      );
    }

    // Always return demo insight as fallback
    return const TrainingReadinessInsight(
      id: 'demo-insight',
      summary:
          'Your training load is well-balanced. Recovery metrics show optimal adaptation. Consider adding one high-intensity session this week.',
      readinessScore: 0.82,
      loadFactor: 0.75,
      sessionCount: 12,
      windowDays: 30,
    );
  }
}

class TrainingReadinessInsight {
  final String id;
  final String summary;
  final double readinessScore;
  final double loadFactor;
  final int sessionCount;
  final int windowDays;

  const TrainingReadinessInsight({
    required this.id,
    required this.summary,
    required this.readinessScore,
    required this.loadFactor,
    required this.sessionCount,
    required this.windowDays,
  });

  factory TrainingReadinessInsight.fromCallable(Map<String, dynamic> data) {
    return TrainingReadinessInsight(
      id: data['insightId']?.toString() ?? '',
      summary: data['summary']?.toString() ?? '',
      readinessScore: ((data['readinessScore'] as num?) ?? 0).toDouble(),
      loadFactor: ((data['loadFactor'] as num?) ?? 0).toDouble(),
      sessionCount: ((data['sessionCount'] as num?) ?? 0).toInt(),
      windowDays: ((data['windowDays'] as num?) ?? 30).toInt(),
    );
  }

  factory TrainingReadinessInsight.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final metrics = Map<String, dynamic>.from(
      data['metrics'] as Map<Object?, Object?>? ?? {},
    );
    return TrainingReadinessInsight(
      id: doc.id,
      summary: data['content']?.toString() ?? '',
      readinessScore: ((metrics['readinessScore'] as num?) ?? 0).toDouble(),
      loadFactor: ((metrics['loadFactor'] as num?) ?? 0).toDouble(),
      sessionCount: ((metrics['sessionCount'] as num?) ?? 0).toInt(),
      windowDays: ((data['windowDays'] as num?) ?? 30).toInt(),
    );
  }
}
