import 'package:cloud_firestore/cloud_firestore.dart';

/// Per-platform distribution channel configuration.
class DistributionChannelConfig {
  final String platform;
  final bool enabled;
  final DateTime? lastSync;
  final int syncIntervalMinutes;
  final int itemsSynced;

  const DistributionChannelConfig({
    required this.platform,
    required this.enabled,
    this.lastSync,
    this.syncIntervalMinutes = 15,
    this.itemsSynced = 0,
  });

  DistributionChannelConfig copyWith({bool? enabled}) =>
      DistributionChannelConfig(
        platform: platform,
        enabled: enabled ?? this.enabled,
        lastSync: lastSync,
        syncIntervalMinutes: syncIntervalMinutes,
        itemsSynced: itemsSynced,
      );

  factory DistributionChannelConfig.fromMap(
    String platform,
    Map<String, dynamic> d,
  ) {
    return DistributionChannelConfig(
      platform: platform,
      enabled: d['enabled'] as bool? ?? false,
      lastSync: d['lastSync'] != null
          ? (d['lastSync'] as Timestamp).toDate()
          : null,
      syncIntervalMinutes: d['syncIntervalMinutes'] as int? ?? 15,
      itemsSynced: d['itemsSynced'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'syncIntervalMinutes': syncIntervalMinutes,
    'itemsSynced': itemsSynced,
  };
}

/// A single entry in the distribution log.
class DistributionLogEntry {
  final String id;
  final DateTime timestamp;
  final String platform;
  final int itemsSynced;
  final List<String> errors;

  const DistributionLogEntry({
    required this.id,
    required this.timestamp,
    required this.platform,
    required this.itemsSynced,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;

  factory DistributionLogEntry.fromMap(String id, Map<String, dynamic> d) {
    return DistributionLogEntry(
      id: id,
      timestamp: d['timestamp'] != null
          ? (d['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      platform: d['platform'] as String? ?? '',
      itemsSynced: d['itemsSynced'] as int? ?? 0,
      errors: List<String>.from(d['errors'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'timestamp': FieldValue.serverTimestamp(),
    'platform': platform,
    'itemsSynced': itemsSynced,
    'errors': errors,
  };
}

/// GlobalDistributionService — manages per-platform distribution channels,
/// Firestore-backed settings, sync recording, and audit logs.
class GlobalDistributionService {
  static final GlobalDistributionService _instance =
      GlobalDistributionService._internal();
  factory GlobalDistributionService() => _instance;
  GlobalDistributionService._internal();

  static const List<String> platforms = [
    'facebook',
    'instagram',
    'youtube',
    'tiktok',
    'whatsapp',
  ];

  // ── Region → dominant platforms ─────────────────────────────────────────────

  List<String> getPlatformsForRegion(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'IN':
        return ['facebook', 'instagram', 'youtube', 'whatsapp'];
      case 'PK':
        return ['facebook', 'youtube', 'whatsapp'];
      case 'PH':
        return ['facebook', 'instagram', 'youtube', 'tiktok'];
      case 'NG':
        return ['facebook', 'instagram', 'youtube'];
      case 'BR':
        return ['facebook', 'instagram', 'youtube'];
      case 'US':
        return ['instagram', 'youtube', 'tiktok'];
      case 'AU':
        return ['facebook', 'instagram', 'youtube'];
      case 'GB':
        return ['instagram', 'tiktok', 'youtube'];
      case 'EU':
        return ['instagram', 'tiktok', 'youtube'];
      case 'JP':
        return ['youtube', 'instagram'];
      case 'AE':
        return ['instagram', 'tiktok', 'youtube'];
      case 'ZA':
        return ['facebook', 'instagram', 'youtube'];
      case 'TH':
        return ['facebook', 'instagram', 'youtube', 'tiktok'];
      case 'PB':
        return ['facebook', 'instagram', 'youtube', 'whatsapp'];
      case 'PF':
        return ['facebook', 'youtube'];
      case 'FJ':
        return ['facebook', 'youtube'];
      case 'WS':
        return ['facebook', 'youtube'];
      case 'TO':
        return ['facebook', 'youtube'];
      case 'PG':
        return ['facebook', 'youtube'];
      case 'NZ':
        return ['facebook', 'instagram', 'youtube'];
      case 'MX':
        return ['facebook', 'instagram', 'youtube', 'tiktok'];
      case 'CO':
        return ['facebook', 'instagram', 'youtube'];
      case 'AR':
        return ['facebook', 'instagram', 'youtube'];
      case 'PE':
        return ['facebook', 'instagram', 'youtube'];
      case 'CL':
        return ['facebook', 'instagram', 'youtube'];
      case 'KE':
        return ['facebook', 'instagram', 'youtube'];
      case 'GH':
        return ['facebook', 'instagram', 'youtube'];
      case 'ET':
        return ['facebook', 'youtube'];
      case 'CM':
        return ['facebook', 'instagram', 'youtube'];
      case 'SG':
        return ['facebook', 'instagram', 'youtube', 'tiktok'];
      case 'MY':
        return ['facebook', 'instagram', 'youtube', 'tiktok'];
      case 'ID':
        return ['facebook', 'instagram', 'youtube', 'tiktok'];
      default:
        return ['facebook', 'instagram', 'youtube'];
    }
  }

  Map<String, List<String>> getAllRegionPlatforms() {
    const codes = [
      'US',
      'AU',
      'GB',
      'EU',
      'IN',
      'PB',
      'PK',
      'PH',
      'NG',
      'BR',
      'JP',
      'AE',
      'ZA',
      'TH',
      'PF',
      'FJ',
      'WS',
      'TO',
      'PG',
      'NZ',
      'MX',
      'CO',
      'AR',
      'PE',
      'CL',
      'KE',
      'GH',
      'ET',
      'CM',
      'SG',
      'MY',
      'ID',
    ];
    return {for (final c in codes) c: getPlatformsForRegion(c)};
  }

  // ── Demo channel configs (used when Firestore is unavailable) ──────────────

  static final List<DistributionChannelConfig> _demoCconfigs = [
    DistributionChannelConfig(
      platform: 'facebook',
      enabled: true,
      lastSync: DateTime.now().subtract(const Duration(minutes: 12)),
      itemsSynced: 384,
    ),
    DistributionChannelConfig(
      platform: 'instagram',
      enabled: true,
      lastSync: DateTime.now().subtract(const Duration(minutes: 8)),
      itemsSynced: 512,
    ),
    DistributionChannelConfig(
      platform: 'youtube',
      enabled: true,
      lastSync: DateTime.now().subtract(const Duration(minutes: 5)),
      itemsSynced: 261,
    ),
    const DistributionChannelConfig(
      platform: 'tiktok',
      enabled: false,
    ),
    const DistributionChannelConfig(
      platform: 'whatsapp',
      enabled: false,
      syncIntervalMinutes: 30,
    ),
  ];

  List<DistributionChannelConfig> getDemoChannelConfigs() =>
      List.from(_demoCconfigs);

  // ── Firestore channel config CRUD ──────────────────────────────────────────

  Future<List<DistributionChannelConfig>> getChannelConfigs() async {
    try {
      final configs = <DistributionChannelConfig>[];
      for (final p in platforms) {
        final doc = await FirebaseFirestore.instance
            .collection('distribution_settings')
            .doc(p)
            .get();
        if (doc.exists) {
          configs.add(DistributionChannelConfig.fromMap(p, doc.data()!));
        } else {
          // Seed with safe disabled defaults if missing
          configs.add(DistributionChannelConfig(platform: p, enabled: false));
        }
      }
      return configs;
    } catch (_) {
      return getDemoChannelConfigs();
    }
  }

  Future<void> setEnabled(String platform, {required bool enabled}) async {
    try {
      await FirebaseFirestore.instance
          .collection('distribution_settings')
          .doc(platform)
          .set({'enabled': enabled}, SetOptions(merge: true));
    } catch (_) {
      // Firestore unavailable — toggle is UI-only in demo mode
    }
  }

  // ── Distribution log ────────────────────────────────────────────────────────

  Future<List<DistributionLogEntry>> getRecentLogs({int limit = 20}) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('distribution_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      return snap.docs
          .map((d) => DistributionLogEntry.fromMap(d.id, d.data()))
          .toList();
    } catch (_) {
      return _demoLogs;
    }
  }

  Future<void> recordSync(
    String platform,
    int itemsSynced, {
    List<String> errors = const [],
  }) async {
    try {
      await FirebaseFirestore.instance.collection('distribution_logs').add({
        'timestamp': FieldValue.serverTimestamp(),
        'platform': platform,
        'itemsSynced': itemsSynced,
        'errors': errors,
      });
      await FirebaseFirestore.instance
          .collection('distribution_settings')
          .doc(platform)
          .set({
            'lastSync': FieldValue.serverTimestamp(),
            'itemsSynced': FieldValue.increment(itemsSynced),
          }, SetOptions(merge: true));
    } catch (_) {
      // Ignore in demo mode
    }
  }

  static final List<DistributionLogEntry> _demoLogs = [
    DistributionLogEntry(
      id: 'd1',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      platform: 'instagram',
      itemsSynced: 14,
      errors: [],
    ),
    DistributionLogEntry(
      id: 'd2',
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      platform: 'facebook',
      itemsSynced: 9,
      errors: [],
    ),
    DistributionLogEntry(
      id: 'd3',
      timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
      platform: 'youtube',
      itemsSynced: 6,
      errors: [],
    ),
    DistributionLogEntry(
      id: 'd4',
      timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
      platform: 'instagram',
      itemsSynced: 11,
      errors: ['Rate limit warning'],
    ),
    DistributionLogEntry(
      id: 'd5',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      platform: 'facebook',
      itemsSynced: 22,
      errors: [],
    ),
  ];
}
