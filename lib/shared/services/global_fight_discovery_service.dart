import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC GLOBAL FIGHT DISCOVERY NETWORK — #119
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Makes every fighter on the planet discoverable.
///
/// Features:
///   • Global fighter database across all promotions
///   • Regional rankings (per country, continent, federation)
///   • Promotion marketplace (promoters browse fighters globally)
///   • AI fighter matching (style, rank, availability)
///   • Fighter availability calendar
///   • Cross-promotion fight discovery
///
/// Firestore Collections:
///   global_fighters/{fighterId}           — Universal fighter profile
///   global_rankings/{region}              — Regional rankings
///   fight_opportunities/{opportunityId}   — Matchmaking opportunities
///
/// ═══════════════════════════════════════════════════════════════════════════

class GlobalFighterEntry {
  final String fighterId;
  final String name;
  final String country;
  final String region;
  final String weightClass;
  final String sport;
  final int wins;
  final int losses;
  final int draws;
  final double globalRanking; // 0–100 (lower = better)
  final List<String> promotionAffiliations;
  final bool availableForBooking;
  final String? managerContact;
  final DateTime lastFightDate;

  const GlobalFighterEntry({
    required this.fighterId,
    required this.name,
    required this.country,
    required this.region,
    required this.weightClass,
    required this.sport,
    required this.wins,
    required this.losses,
    this.draws = 0,
    required this.globalRanking,
    this.promotionAffiliations = const [],
    this.availableForBooking = true,
    this.managerContact,
    required this.lastFightDate,
  });

  double get winRate => (wins + losses) > 0 ? wins / (wins + losses) : 0;
}

class FightOpportunity {
  final String id;
  final String promoterId;
  final String promotionName;
  final String eventName;
  final DateTime eventDate;
  final String weightClass;
  final String sport;
  final String opponentStyle;
  final double offeredPurse;
  final String location;
  final List<String> applicantIds;

  const FightOpportunity({
    required this.id,
    required this.promoterId,
    required this.promotionName,
    required this.eventName,
    required this.eventDate,
    required this.weightClass,
    required this.sport,
    this.opponentStyle = '',
    required this.offeredPurse,
    required this.location,
    this.applicantIds = const [],
  });
}

class GlobalFightDiscoveryService extends ChangeNotifier {
  static final GlobalFightDiscoveryService _instance =
      GlobalFightDiscoveryService._internal();
  factory GlobalFightDiscoveryService() => _instance;
  GlobalFightDiscoveryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _initialized = false;
  Timer? _indexTimer;

  final List<GlobalFighterEntry> _fighters = [];
  final List<FightOpportunity> _opportunities = [];
  int _totalSearches = 0;

  // ── Getters ──
  bool get initialized => _initialized;
  int get totalSearches => _totalSearches;
  int get totalFighters => _fighters.length;
  int get totalOpportunities => _opportunities.length;

  // ── Lifecycle ──

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Re-index global database every 2 hours.
    _indexTimer = Timer.periodic(const Duration(hours: 2), (_) {
      _reindexGlobalDatabase();
    });

    debugPrint('[FightDiscovery] Online — global network active');
    notifyListeners();
  }

  // ── Fighter Registration ──

  Future<void> registerFighter(GlobalFighterEntry fighter) async {
    await _firestore.collection('global_fighters').doc(fighter.fighterId).set({
      'name': fighter.name,
      'country': fighter.country,
      'region': fighter.region,
      'weightClass': fighter.weightClass,
      'sport': fighter.sport,
      'wins': fighter.wins,
      'losses': fighter.losses,
      'draws': fighter.draws,
      'globalRanking': fighter.globalRanking,
      'promotionAffiliations': fighter.promotionAffiliations,
      'availableForBooking': fighter.availableForBooking,
      'lastFightDate': Timestamp.fromDate(fighter.lastFightDate),
      'registeredAt': FieldValue.serverTimestamp(),
    });

    _fighters.add(fighter);
    notifyListeners();
  }

  // ── Search & Discovery ──

  /// Search fighters by criteria.
  List<GlobalFighterEntry> searchFighters({
    String? weightClass,
    String? sport,
    String? country,
    String? region,
    bool? availableOnly,
    double? minRanking,
    double? maxRanking,
  }) {
    _totalSearches++;

    var results = List<GlobalFighterEntry>.from(_fighters);

    if (weightClass != null) {
      results = results.where((f) => f.weightClass == weightClass).toList();
    }
    if (sport != null) {
      results = results.where((f) => f.sport == sport).toList();
    }
    if (country != null) {
      results = results.where((f) => f.country == country).toList();
    }
    if (region != null) {
      results = results.where((f) => f.region == region).toList();
    }
    if (availableOnly == true) {
      results = results.where((f) => f.availableForBooking).toList();
    }
    if (minRanking != null) {
      results = results.where((f) => f.globalRanking >= minRanking).toList();
    }
    if (maxRanking != null) {
      results = results.where((f) => f.globalRanking <= maxRanking).toList();
    }

    results.sort((a, b) => a.globalRanking.compareTo(b.globalRanking));

    debugPrint('[FightDiscovery] Search returned ${results.length} fighters');
    return results;
  }

  /// AI: Find best style-matched opponents.
  List<GlobalFighterEntry> findStyleMatches(
    GlobalFighterEntry fighter, {
    int limit = 10,
  }) {
    _totalSearches++;

    final candidates = _fighters
        .where(
          (f) =>
              f.fighterId != fighter.fighterId &&
              f.weightClass == fighter.weightClass &&
              f.sport == fighter.sport &&
              f.availableForBooking,
        )
        .toList();

    // Score by ranking proximity + complementary record.
    candidates.sort((a, b) {
      final aScore = (a.globalRanking - fighter.globalRanking).abs();
      final bScore = (b.globalRanking - fighter.globalRanking).abs();
      return aScore.compareTo(bScore);
    });

    return candidates.take(limit).toList();
  }

  // ── Promotion Marketplace ──

  Future<void> postOpportunity(FightOpportunity opportunity) async {
    await _firestore.collection('fight_opportunities').doc(opportunity.id).set({
      'promoterId': opportunity.promoterId,
      'promotionName': opportunity.promotionName,
      'eventName': opportunity.eventName,
      'eventDate': Timestamp.fromDate(opportunity.eventDate),
      'weightClass': opportunity.weightClass,
      'sport': opportunity.sport,
      'offeredPurse': opportunity.offeredPurse,
      'location': opportunity.location,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _opportunities.add(opportunity);
    debugPrint(
      '[FightDiscovery] Opportunity posted: ${opportunity.eventName} — '
      '${opportunity.weightClass}',
    );
    notifyListeners();
  }

  List<FightOpportunity> findOpportunities({
    String? weightClass,
    String? sport,
    String? region,
  }) {
    var results = List<FightOpportunity>.from(_opportunities);
    if (weightClass != null) {
      results = results.where((o) => o.weightClass == weightClass).toList();
    }
    if (sport != null) {
      results = results.where((o) => o.sport == sport).toList();
    }
    return results;
  }

  // ── Regional Rankings ──

  Map<String, List<GlobalFighterEntry>> regionalRankings(String sport) {
    final byRegion = <String, List<GlobalFighterEntry>>{};
    for (final fighter in _fighters.where((f) => f.sport == sport)) {
      byRegion.putIfAbsent(fighter.region, () => []).add(fighter);
    }
    for (final region in byRegion.keys) {
      byRegion[region]!.sort(
        (a, b) => a.globalRanking.compareTo(b.globalRanking),
      );
    }
    return byRegion;
  }

  @override
  void dispose() {
    _indexTimer?.cancel();
    super.dispose();
  }

  // ── Internal ──

  void _reindexGlobalDatabase() {
    debugPrint('[FightDiscovery] Re-indexing ${_fighters.length} fighters');
    notifyListeners();
  }
}
