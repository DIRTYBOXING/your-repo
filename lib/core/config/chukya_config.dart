// lib/chukya_config.dart

class FeedRankingConfig {
  final bool enabled;
  final Map<String, double> defaultWeights;
  final Map<String, dynamic> decay;
  final Map<String, dynamic> canary;

  FeedRankingConfig({
    required this.enabled,
    required this.defaultWeights,
    required this.decay,
    required this.canary,
  });

  factory FeedRankingConfig.fromMap(Map<String, dynamic> m) {
    final defaultWeightsRaw =
        m['defaultWeights'] ??
        {
          'recency': 1.0,
          'trust': 1.0,
          'engagement': 1.0,
          'strategicBoost': 0.0,
        };
    final defaultWeights = Map<String, double>.from(
      (defaultWeightsRaw as Map).map(
        (k, v) => MapEntry(k as String, (v as num).toDouble()),
      ),
    );

    return FeedRankingConfig(
      enabled: m['enabled'] ?? true,
      defaultWeights: defaultWeights,
      decay: Map<String, dynamic>.from(
        m['decay'] ?? {'type': 'exponential', 'halfLifeHours': 24},
      ),
      canary: Map<String, dynamic>.from(
        m['canary'] ?? {'enabled': false, 'percent': 0},
      ),
    );
  }
}
