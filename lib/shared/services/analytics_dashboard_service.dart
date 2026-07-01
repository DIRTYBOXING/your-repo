import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ANALYTICS DASHBOARD SERVICE — Admin KPI Visualization & Metrics
/// ═══════════════════════════════════════════════════════════════════════════

final _firestore = FirebaseFirestore.instance;
final _functions = FirebaseFunctions.instanceFor(
  region: 'australia-southeast1',
);

enum MetricPeriod { hour, day, week, month, quarter, year, allTime }

enum MetricType { count, sum, average, rate, percentage }

enum DashboardWidget { counter, chart, gauge, table, heatmap, funnel }

class KPIMetric {
  final String id;
  final String name;
  final String description;
  final MetricType type;
  final double value;
  final double? previousValue;
  final String unit;
  final DateTime measuredAt;
  final Map<String, dynamic> breakdown;

  const KPIMetric({
    required this.id,
    required this.name,
    this.description = '',
    required this.type,
    required this.value,
    this.previousValue,
    this.unit = '',
    required this.measuredAt,
    this.breakdown = const {},
  });

  factory KPIMetric.fromMap(Map<String, dynamic> map) => KPIMetric(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    description: map['description'] ?? '',
    type: MetricType.values.firstWhere(
      (t) => t.name == map['type'],
      orElse: () => MetricType.count,
    ),
    value: (map['value'] ?? 0).toDouble(),
    previousValue: map['previousValue']?.toDouble(),
    unit: map['unit'] ?? '',
    measuredAt: (map['measuredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    breakdown: Map<String, dynamic>.from(map['breakdown'] ?? {}),
  );

  double get changePercent {
    if (previousValue == null || previousValue == 0) return 0;
    return ((value - previousValue!) / previousValue!) * 100;
  }

  bool get isPositiveChange => changePercent > 0;
  String get formattedValue => type == MetricType.percentage
      ? '${value.toStringAsFixed(1)}%'
      : type == MetricType.rate
      ? '${value.toStringAsFixed(2)}$unit'
      : '${value.toInt()}$unit';
}

class TimeSeriesDataPoint {
  final DateTime timestamp;
  final double value;
  final String? label;

  const TimeSeriesDataPoint({
    required this.timestamp,
    required this.value,
    this.label,
  });

  factory TimeSeriesDataPoint.fromMap(Map<String, dynamic> map) =>
      TimeSeriesDataPoint(
        timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        value: (map['value'] ?? 0).toDouble(),
        label: map['label'],
      );
}

class DashboardPanel {
  final String id;
  final String title;
  final DashboardWidget widgetType;
  final String metricId;
  final MetricPeriod period;
  final List<TimeSeriesDataPoint> timeSeries;
  final Map<String, dynamic> config;

  const DashboardPanel({
    required this.id,
    required this.title,
    required this.widgetType,
    required this.metricId,
    this.period = MetricPeriod.day,
    this.timeSeries = const [],
    this.config = const {},
  });

  factory DashboardPanel.fromMap(Map<String, dynamic> map) => DashboardPanel(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    widgetType: DashboardWidget.values.firstWhere(
      (w) => w.name == map['widgetType'],
      orElse: () => DashboardWidget.counter,
    ),
    metricId: map['metricId'] ?? '',
    period: MetricPeriod.values.firstWhere(
      (p) => p.name == map['period'],
      orElse: () => MetricPeriod.day,
    ),
    timeSeries:
        (map['timeSeries'] as List?)
            ?.map((e) => TimeSeriesDataPoint.fromMap(e))
            .toList() ??
        [],
    config: Map<String, dynamic>.from(map['config'] ?? {}),
  );
}

class AnalyticsDashboardService with ChangeNotifier {
  static final AnalyticsDashboardService _instance =
      AnalyticsDashboardService._internal();
  factory AnalyticsDashboardService() => _instance;
  AnalyticsDashboardService._internal();

  bool _initialized = false;
  final Map<String, KPIMetric> _metrics = {};
  final List<DashboardPanel> _panels = [];
  DateTime? _lastRefresh;

  bool get initialized => _initialized;
  Map<String, KPIMetric> get metrics => Map.unmodifiable(_metrics);
  List<DashboardPanel> get panels => List.unmodifiable(_panels);
  DateTime? get lastRefresh => _lastRefresh;

  Future<void> initialize() async {
    if (_initialized) return;
    debugPrint('📊 AnalyticsDashboardService: Initializing...');
    await Future.wait([_loadMetrics(), _loadDashboardConfig()]);
    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadMetrics() async {
    try {
      final snap = await _firestore.collection('analytics_metrics').get();
      _metrics.clear();
      for (final doc in snap.docs) {
        _metrics[doc.id] = KPIMetric.fromMap({...doc.data(), 'id': doc.id});
      }
    } catch (e) {
      debugPrint('AnalyticsDashboardService: Load metrics failed: $e');
    }
  }

  Future<void> _loadDashboardConfig() async {
    try {
      final snap = await _firestore
          .collection('dashboard_panels')
          .orderBy('order')
          .get();
      _panels.clear();
      for (final doc in snap.docs) {
        _panels.add(DashboardPanel.fromMap({...doc.data(), 'id': doc.id}));
      }
    } catch (e) {
      debugPrint('AnalyticsDashboardService: Load panels failed: $e');
    }
  }

  Future<void> refresh() async {
    debugPrint('AnalyticsDashboardService: Refreshing...');
    await Future.wait([_loadMetrics(), _loadDashboardConfig()]);
    _lastRefresh = DateTime.now();
    notifyListeners();
  }

  Future<Map<String, dynamic>> fetchPlatformOverview() async {
    try {
      final callable = _functions.httpsCallable('getPlatformAnalytics');
      final result = await callable.call<Map<String, dynamic>>({});
      return result.data;
    } catch (e) {
      debugPrint('AnalyticsDashboardService: Fetch overview failed: $e');
      return {};
    }
  }

  Future<List<TimeSeriesDataPoint>> getTimeSeries(
    String metricId,
    MetricPeriod period,
  ) async {
    try {
      final callable = _functions.httpsCallable('getMetricTimeSeries');
      final result = await callable.call<Map<String, dynamic>>({
        'metricId': metricId,
        'period': period.name,
      });
      final data = result.data['timeSeries'] as List? ?? [];
      return data
          .map((e) => TimeSeriesDataPoint.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Core KPIs
  KPIMetric? get totalUsers => _metrics['total_users'];
  KPIMetric? get activeUsers => _metrics['active_users'];
  KPIMetric? get totalRevenue => _metrics['total_revenue'];
  KPIMetric? get ppvPurchases => _metrics['ppv_purchases'];
  KPIMetric? get liveViewers => _metrics['live_viewers'];
  KPIMetric? get engagementRate => _metrics['engagement_rate'];
  KPIMetric? get conversionRate => _metrics['conversion_rate'];
  KPIMetric? get retentionRate => _metrics['retention_rate'];

  /// Track custom event
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? params,
  }) async {
    await _firestore.collection('analytics_events').add({
      'event': eventName,
      'params': params ?? {},
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Get funnel data
  Future<List<Map<String, dynamic>>> getFunnelData(String funnelId) async {
    try {
      final doc = await _firestore
          .collection('analytics_funnels')
          .doc(funnelId)
          .get();
      if (doc.exists) {
        return List<Map<String, dynamic>>.from(doc.data()?['steps'] ?? []);
      }
    } catch (_) {}
    return [];
  }

  /// Get user cohorts
  Future<List<Map<String, dynamic>>> getCohortAnalysis(
    MetricPeriod period,
  ) async {
    try {
      final callable = _functions.httpsCallable('getCohortAnalysis');
      final result = await callable.call<Map<String, dynamic>>({
        'period': period.name,
      });
      return List<Map<String, dynamic>>.from(result.data['cohorts'] ?? []);
    } catch (_) {
      return [];
    }
  }
}
