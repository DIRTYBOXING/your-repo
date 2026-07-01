import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// A/B TESTING SERVICE — Remote Config Experiments & Feature Flags
/// ═══════════════════════════════════════════════════════════════════════════

final _firestore = FirebaseFirestore.instance;

enum ExperimentStatus { draft, running, paused, completed, archived }

enum VariantType { control, treatment }

class Experiment {
  final String id;
  final String name;
  final String description;
  final ExperimentStatus status;
  final List<ExperimentVariant> variants;
  final String targetMetric;
  final double trafficAllocation;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Map<String, dynamic> targeting;

  const Experiment({
    required this.id,
    required this.name,
    this.description = '',
    required this.status,
    required this.variants,
    required this.targetMetric,
    this.trafficAllocation = 1.0,
    required this.startedAt,
    this.endedAt,
    this.targeting = const {},
  });

  factory Experiment.fromMap(Map<String, dynamic> map) => Experiment(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    description: map['description'] ?? '',
    status: ExperimentStatus.values.firstWhere(
      (s) => s.name == map['status'],
      orElse: () => ExperimentStatus.draft,
    ),
    variants:
        (map['variants'] as List?)
            ?.map((v) => ExperimentVariant.fromMap(v))
            .toList() ??
        [],
    targetMetric: map['targetMetric'] ?? '',
    trafficAllocation: (map['trafficAllocation'] ?? 1.0).toDouble(),
    startedAt: (map['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    endedAt: (map['endedAt'] as Timestamp?)?.toDate(),
    targeting: Map<String, dynamic>.from(map['targeting'] ?? {}),
  );
}

class ExperimentVariant {
  final String id;
  final String name;
  final VariantType type;
  final double weight;
  final Map<String, dynamic> config;
  final int participants;
  final int conversions;

  const ExperimentVariant({
    required this.id,
    required this.name,
    required this.type,
    this.weight = 0.5,
    this.config = const {},
    this.participants = 0,
    this.conversions = 0,
  });

  factory ExperimentVariant.fromMap(Map<String, dynamic> map) =>
      ExperimentVariant(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        type: VariantType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => VariantType.control,
        ),
        weight: (map['weight'] ?? 0.5).toDouble(),
        config: Map<String, dynamic>.from(map['config'] ?? {}),
        participants: map['participants'] ?? 0,
        conversions: map['conversions'] ?? 0,
      );

  double get conversionRate =>
      participants > 0 ? conversions / participants : 0;
}

class FeatureFlag {
  final String key;
  final bool enabled;
  final dynamic value;
  final String? rolloutPercentage;
  final Map<String, dynamic>? conditions;

  const FeatureFlag({
    required this.key,
    required this.enabled,
    this.value,
    this.rolloutPercentage,
    this.conditions,
  });
}

class ABTestingService with ChangeNotifier {
  static final ABTestingService _instance = ABTestingService._internal();
  factory ABTestingService() => _instance;
  ABTestingService._internal();

  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;
  final Map<String, Experiment> _experiments = {};
  final Map<String, String> _userAssignments = {}; // experimentId -> variantId
  final Map<String, FeatureFlag> _featureFlags = {};
  String? _userId;

  bool get initialized => _initialized;
  Map<String, Experiment> get experiments => Map.unmodifiable(_experiments);
  Map<String, FeatureFlag> get featureFlags => Map.unmodifiable(_featureFlags);

  Future<void> initialize(String userId) async {
    if (_initialized) return;
    _userId = userId;
    debugPrint('🧪 ABTestingService: Initializing...');

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      // Set defaults
      await _remoteConfig!.setDefaults({
        'feature_live_chat': true,
        'feature_nft_marketplace': false,
        'feature_ai_predictions': true,
        'ppv_price_variant': 'standard',
        'onboarding_variant': 'control',
        'feed_algorithm': 'chronological',
        'max_free_fights': 3,
      });

      await _remoteConfig!.fetchAndActivate();
      _loadFeatureFlags();
      await _loadExperiments();
      await _loadUserAssignments();

      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('ABTestingService: Init failed: $e');
      _initialized = true; // Still mark as initialized to prevent blocking
    }
  }

  void _loadFeatureFlags() {
    if (_remoteConfig == null) return;

    final keys = [
      'feature_live_chat',
      'feature_nft_marketplace',
      'feature_ai_predictions',
      'ppv_price_variant',
      'onboarding_variant',
      'feed_algorithm',
      'max_free_fights',
    ];

    for (final key in keys) {
      final value = _remoteConfig!.getValue(key);
      _featureFlags[key] = FeatureFlag(
        key: key,
        enabled: key.startsWith('feature_') ? value.asBool() : true,
        value: key.startsWith('feature_')
            ? value.asBool()
            : key == 'max_free_fights'
            ? value.asInt()
            : value.asString(),
      );
    }
  }

  Future<void> _loadExperiments() async {
    try {
      final snap = await _firestore
          .collection('experiments')
          .where('status', isEqualTo: 'running')
          .get();
      _experiments.clear();
      for (final doc in snap.docs) {
        _experiments[doc.id] = Experiment.fromMap({
          ...doc.data(),
          'id': doc.id,
        });
      }
    } catch (e) {
      debugPrint('ABTestingService: Load experiments failed: $e');
    }
  }

  Future<void> _loadUserAssignments() async {
    if (_userId == null) return;
    try {
      final doc = await _firestore
          .collection('experiment_assignments')
          .doc(_userId)
          .get();
      if (doc.exists) {
        _userAssignments.addAll(Map<String, String>.from(doc.data() ?? {}));
      }
    } catch (_) {}
  }

  // Feature flag methods
  bool isFeatureEnabled(String key) => _featureFlags[key]?.enabled ?? false;

  T getFeatureValue<T>(String key, T defaultValue) {
    final flag = _featureFlags[key];
    if (flag == null) return defaultValue;
    try {
      return flag.value as T;
    } catch (_) {
      return defaultValue;
    }
  }

  String getString(String key, {String defaultValue = ''}) {
    return _remoteConfig?.getString(key) ?? defaultValue;
  }

  int getInt(String key, {int defaultValue = 0}) {
    return _remoteConfig?.getInt(key) ?? defaultValue;
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _remoteConfig?.getBool(key) ?? defaultValue;
  }

  // Experiment methods
  ExperimentVariant? getVariant(String experimentId) {
    final experiment = _experiments[experimentId];
    if (experiment == null || experiment.status != ExperimentStatus.running) {
      return null;
    }

    // Check if user already assigned
    final assignedVariantId = _userAssignments[experimentId];
    if (assignedVariantId != null) {
      return experiment.variants.firstWhere(
        (v) => v.id == assignedVariantId,
        orElse: () => experiment.variants.first,
      );
    }

    // Assign user to variant based on weights
    return _assignVariant(experiment);
  }

  ExperimentVariant _assignVariant(Experiment experiment) {
    // Simple hash-based assignment for deterministic bucketing
    final hash = (_userId ?? DateTime.now().millisecondsSinceEpoch.toString())
        .hashCode
        .abs();
    final bucket = (hash % 100) / 100.0;

    double cumulative = 0;
    for (final variant in experiment.variants) {
      cumulative += variant.weight;
      if (bucket < cumulative) {
        _saveAssignment(experiment.id, variant.id);
        return variant;
      }
    }

    final fallback = experiment.variants.first;
    _saveAssignment(experiment.id, fallback.id);
    return fallback;
  }

  Future<void> _saveAssignment(String experimentId, String variantId) async {
    _userAssignments[experimentId] = variantId;
    if (_userId != null) {
      await _firestore.collection('experiment_assignments').doc(_userId).set({
        experimentId: variantId,
      }, SetOptions(merge: true));
    }
  }

  /// Track experiment conversion
  Future<void> trackConversion(String experimentId) async {
    final variantId = _userAssignments[experimentId];
    if (variantId == null) return;

    await _firestore.collection('experiment_conversions').add({
      'experimentId': experimentId,
      'variantId': variantId,
      'userId': _userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Force refresh remote config
  Future<void> forceRefresh() async {
    try {
      await _remoteConfig?.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: Duration.zero,
        ),
      );
      await _remoteConfig?.fetchAndActivate();
      _loadFeatureFlags();
      notifyListeners();
    } catch (e) {
      debugPrint('ABTestingService: Force refresh failed: $e');
    }
  }
}
