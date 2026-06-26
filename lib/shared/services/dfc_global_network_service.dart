import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/apex_operating_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC GLOBAL NETWORK SERVICE — Layer 6: DFC's Reach
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Makes DFC *global*. Connects the entire world of combat sports.
///
/// Subsystems:
///   • Global fight discovery    — GlobalDistributionService, Earth feature
///   • Regional federations      — Region-scoped event hubs
///   • Gym management            — MapsService, gym profiles
///   • Multi-language support    — LocalizationService, AutoCaptionService
///   • Localized pricing         — GlobalPricingService, MultiCurrencyEngine
///   • Regional events           — CulturalCalendarService
///   • International matchmaking — MatchmakingService (cross-region)
///   • Global SEO                — GlobalSeoService
///
/// ═══════════════════════════════════════════════════════════════════════════

enum GlobalSubsystem {
  fightDiscovery,
  regionalFederations,
  gymManagement,
  multiLanguage,
  localizedPricing,
  regionalEvents,
  internationalMatchmaking,
  globalSeo,
}

/// Regional federation definition.
class RegionalFederation {
  final String id;
  final String name;
  final String region; // e.g. 'oceania', 'asia', 'europe', 'americas', 'africa'
  final List<String> countries;
  final int activePromotions;
  final int activeFighters;
  final String defaultCurrency;
  final String defaultLanguage;

  const RegionalFederation({
    required this.id,
    required this.name,
    required this.region,
    required this.countries,
    this.activePromotions = 0,
    this.activeFighters = 0,
    required this.defaultCurrency,
    required this.defaultLanguage,
  });
}

class DfcGlobalNetworkService extends ChangeNotifier {
  static final DfcGlobalNetworkService _instance =
      DfcGlobalNetworkService._internal();
  factory DfcGlobalNetworkService() => _instance;
  DfcGlobalNetworkService._internal();

  bool _initialized = false;
  Timer? _syncTimer;
  DateTime? _lastSync;

  int _countriesReached = 0;
  int _languagesSupported = 0;
  int _currenciesActive = 0;
  int _crossRegionMatchups = 0;

  final Map<GlobalSubsystem, double> _subsystemScores = {
    for (final s in GlobalSubsystem.values) s: 1.0,
  };

  /// Registered regional federations.
  final List<RegionalFederation> _federations = [
    const RegionalFederation(
      id: 'oceania',
      name: 'Oceania Combat Federation',
      region: 'oceania',
      countries: ['AU', 'NZ', 'FJ', 'PG', 'WS'],
      defaultCurrency: 'AUD',
      defaultLanguage: 'en',
    ),
    const RegionalFederation(
      id: 'se_asia',
      name: 'Southeast Asia Fight Alliance',
      region: 'asia',
      countries: ['TH', 'PH', 'ID', 'SG', 'MY', 'VN'],
      defaultCurrency: 'THB',
      defaultLanguage: 'th',
    ),
    const RegionalFederation(
      id: 'europe',
      name: 'European Combat Sports Union',
      region: 'europe',
      countries: ['GB', 'IE', 'FR', 'DE', 'ES', 'IT', 'NL', 'PL', 'SE'],
      defaultCurrency: 'EUR',
      defaultLanguage: 'en',
    ),
    const RegionalFederation(
      id: 'americas',
      name: 'Americas Fight Network',
      region: 'americas',
      countries: ['US', 'CA', 'MX', 'BR', 'AR', 'CO'],
      defaultCurrency: 'USD',
      defaultLanguage: 'en',
    ),
    const RegionalFederation(
      id: 'africa',
      name: 'African Combat Alliance',
      region: 'africa',
      countries: ['ZA', 'NG', 'KE', 'GH', 'TZ', 'EG'],
      defaultCurrency: 'ZAR',
      defaultLanguage: 'en',
    ),
    const RegionalFederation(
      id: 'east_asia',
      name: 'East Asia Martial Arts Commission',
      region: 'asia',
      countries: ['JP', 'KR', 'CN', 'TW', 'HK'],
      defaultCurrency: 'JPY',
      defaultLanguage: 'ja',
    ),
    const RegionalFederation(
      id: 'middle_east',
      name: 'Middle East Combat Council',
      region: 'middle_east',
      countries: ['AE', 'SA', 'QA', 'BH', 'KW'],
      defaultCurrency: 'USD',
      defaultLanguage: 'ar',
    ),
  ];

  // ── Getters ──
  bool get initialized => _initialized;
  int get countriesReached => _countriesReached;
  int get languagesSupported => _languagesSupported;
  int get currenciesActive => _currenciesActive;
  int get crossRegionMatchups => _crossRegionMatchups;
  List<RegionalFederation> get federations => List.unmodifiable(_federations);
  Map<GlobalSubsystem, double> get subsystemScores =>
      Map.unmodifiable(_subsystemScores);

  double get overallScore {
    if (_subsystemScores.isEmpty) return 0.0;
    return _subsystemScores.values.reduce((a, b) => a + b) /
        _subsystemScores.length;
  }

  ApexLayerStatus get layerStatus => ApexLayerStatus(
    layer: ApexLayer.globalNetwork,
    health: overallScore >= 0.8
        ? LayerHealth.optimal
        : overallScore >= 0.5
        ? LayerHealth.degraded
        : LayerHealth.critical,
    score: overallScore,
    activeSubsystems: _subsystemScores.values.where((s) => s >= 0.5).length,
    totalSubsystems: GlobalSubsystem.values.length,
    lastHeartbeat: _lastSync ?? DateTime.now(),
    statusMessage:
        '$_countriesReached countries · ${_federations.length} federations',
  );

  // ── Lifecycle ──

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Tally up initial reach from federation definitions.
    final allCountries = <String>{};
    for (final fed in _federations) {
      allCountries.addAll(fed.countries);
    }
    _countriesReached = allCountries.length;
    _languagesSupported = 12; // Localization service baseline
    _currenciesActive = 15; // Multi-currency engine baseline

    // Sync regional data every hour.
    _syncTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _syncRegions();
    });

    debugPrint(
      '[GlobalNetwork] Online — $_countriesReached countries, '
      '${_federations.length} federations',
    );
    notifyListeners();
  }

  /// Record a cross-region matchup (international fight booking).
  void recordCrossRegionMatchup(String regionA, String regionB) {
    _crossRegionMatchups++;
    _subsystemScores[GlobalSubsystem.internationalMatchmaking] = 1.0;
    notifyListeners();
  }

  /// Add a new regional federation dynamically.
  void registerFederation(RegionalFederation federation) {
    _federations.add(federation);
    _subsystemScores[GlobalSubsystem.regionalFederations] = 1.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  // ── Internal ──

  void _syncRegions() {
    _lastSync = DateTime.now();
    debugPrint('[GlobalNetwork] Region sync — $_countriesReached countries');
    notifyListeners();
  }
}
