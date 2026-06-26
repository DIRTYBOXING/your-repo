// lib/core/config/feature_flags_stub.dart
// Temporary local stub for FeatureFlags. Replace with real client import later.

class FeatureFlags {
  // Example: read from environment map for tests or a local JSON file.
  // In production replace this with your real config client.
  static Map<String, dynamic> _overrides = {};

  static void setOverrides(Map<String, dynamic> m) {
    _overrides = m;
  }

  static dynamic get(String key) {
    if (_overrides.containsKey(key)) return _overrides[key];
    // safe defaults for keys used by chukya_config.dart
    if (key == 'env') return 'staging';
    if (key == 'feedRanking') return null;
    return null;
  }
}
