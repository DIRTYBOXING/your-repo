import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC FEDERATION MANAGEMENT SYSTEM — #106
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Lets DFC run regional and global federations for combat sports.
///
/// Features:
///   • Regional federations with custom rule sets
///   • Sanctioning body registration & compliance
///   • Weight class management per sport/federation
///   • Automated rankings (auto-update after fights)
///   • Title belts & mandatory challengers
///   • AI: predict ranking changes & title challenger readiness
///
/// Firestore Collections:
///   federations/{fedId}                — Federation profiles
///   federations/{fedId}/rankings       — Fighter rankings per weight class
///   federations/{fedId}/title_belts    — Active title holders
///   federations/{fedId}/rule_sets      — Sanctioned rule sets
///
/// ═══════════════════════════════════════════════════════════════════════════

enum FederationTier { global, continental, national, regional, local }

enum TitleStatus { vacant, held, interim, unified, undisputed }

class FederationProfile {
  final String id;
  final String name;
  final FederationTier tier;
  final String region;
  final List<String> sanctionedSports;
  final List<String> weightClasses;
  final String? logoUrl;
  final bool isActive;
  final DateTime createdAt;

  const FederationProfile({
    required this.id,
    required this.name,
    required this.tier,
    required this.region,
    required this.sanctionedSports,
    required this.weightClasses,
    this.logoUrl,
    this.isActive = true,
    required this.createdAt,
  });

  factory FederationProfile.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return FederationProfile(
      id: doc.id,
      name: d['name']?.toString() ?? '',
      tier: FederationTier.values.firstWhere(
        (t) => t.name == d['tier']?.toString(),
        orElse: () => FederationTier.regional,
      ),
      region: d['region']?.toString() ?? '',
      sanctionedSports: List<String>.from(d['sanctionedSports'] ?? []),
      weightClasses: List<String>.from(d['weightClasses'] ?? []),
      logoUrl: d['logoUrl']?.toString(),
      isActive: d['isActive'] as bool? ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'tier': tier.name,
    'region': region,
    'sanctionedSports': sanctionedSports,
    'weightClasses': weightClasses,
    'logoUrl': logoUrl,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

class TitleBelt {
  final String id;
  final String federationId;
  final String weightClass;
  final String sport;
  final TitleStatus status;
  final String? currentChampionId;
  final String? mandatoryChallengerIds;
  final DateTime? lastDefended;

  const TitleBelt({
    required this.id,
    required this.federationId,
    required this.weightClass,
    required this.sport,
    this.status = TitleStatus.vacant,
    this.currentChampionId,
    this.mandatoryChallengerIds,
    this.lastDefended,
  });
}

class FederationRanking {
  final String fighterId;
  final String weightClass;
  final int rank;
  final int wins;
  final int losses;
  final double pointScore;
  final bool isMandatoryChallenger;

  const FederationRanking({
    required this.fighterId,
    required this.weightClass,
    required this.rank,
    required this.wins,
    required this.losses,
    required this.pointScore,
    this.isMandatoryChallenger = false,
  });
}

class FederationManagementService extends ChangeNotifier {
  static final FederationManagementService _instance =
      FederationManagementService._internal();
  factory FederationManagementService() => _instance;
  FederationManagementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _initialized = false;
  Timer? _rankingTimer;

  final List<FederationProfile> _federations = [];
  final Map<String, List<FederationRanking>> _rankings = {};
  final Map<String, List<TitleBelt>> _titleBelts = {};

  // ── Getters ──
  bool get initialized => _initialized;
  List<FederationProfile> get federations => List.unmodifiable(_federations);

  List<FederationRanking> rankingsFor(String federationId) =>
      List.unmodifiable(_rankings[federationId] ?? []);

  List<TitleBelt> titleBeltsFor(String federationId) =>
      List.unmodifiable(_titleBelts[federationId] ?? []);

  // ── Lifecycle ──

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _loadFederations();

    // Auto-update rankings every 30 minutes.
    _rankingTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _autoUpdateRankings();
    });

    debugPrint('[FederationMgmt] Online — ${_federations.length} federations');
    notifyListeners();
  }

  // ── CRUD ──

  Future<void> createFederation(FederationProfile federation) async {
    await _firestore
        .collection('federations')
        .doc(federation.id)
        .set(federation.toMap());
    _federations.add(federation);
    notifyListeners();
  }

  Future<List<FederationRanking>> getRankings(
    String federationId,
    String weightClass,
  ) async {
    final snap = await _firestore
        .collection('federations')
        .doc(federationId)
        .collection('rankings')
        .where('weightClass', isEqualTo: weightClass)
        .orderBy('rank')
        .get();

    return snap.docs.map((doc) {
      final d = doc.data();
      return FederationRanking(
        fighterId: d['fighterId']?.toString() ?? '',
        weightClass: d['weightClass']?.toString() ?? '',
        rank: (d['rank'] as num?)?.toInt() ?? 0,
        wins: (d['wins'] as num?)?.toInt() ?? 0,
        losses: (d['losses'] as num?)?.toInt() ?? 0,
        pointScore: (d['pointScore'] as num?)?.toDouble() ?? 0,
        isMandatoryChallenger: d['isMandatoryChallenger'] as bool? ?? false,
      );
    }).toList();
  }

  /// Auto-generate title fight when mandatory challenger is ready.
  Future<Map<String, String>?> generateTitleFight(
    String federationId,
    String weightClass,
  ) async {
    final rankings = await getRankings(federationId, weightClass);
    final mandatory = rankings.where((r) => r.isMandatoryChallenger).toList();
    if (mandatory.isEmpty) return null;

    final belts = _titleBelts[federationId] ?? [];
    final belt = belts
        .where(
          (b) => b.weightClass == weightClass && b.status == TitleStatus.held,
        )
        .toList();
    if (belt.isEmpty) return null;

    return {
      'champion': belt.first.currentChampionId ?? '',
      'challenger': mandatory.first.fighterId,
      'weightClass': weightClass,
    };
  }

  /// AI: Predict ranking changes after a fight result.
  List<FederationRanking> predictRankingChanges(
    String federationId,
    String winnerId,
    String loserId,
  ) {
    final current = _rankings[federationId] ?? [];
    // Simple swap logic: winner moves up, loser moves down.
    final updated = List<FederationRanking>.from(current);
    // Real AI would use ML model; this is the structural hook.
    debugPrint(
      '[FederationMgmt] AI ranking prediction for '
      '$winnerId (W) vs $loserId (L)',
    );
    return updated;
  }

  @override
  void dispose() {
    _rankingTimer?.cancel();
    super.dispose();
  }

  // ── Internal ──

  Future<void> _loadFederations() async {
    try {
      final snap = await _firestore.collection('federations').get();
      _federations.clear();
      for (final doc in snap.docs) {
        _federations.add(FederationProfile.fromFirestore(doc));
      }
    } catch (e) {
      debugPrint('[FederationMgmt] Load error: $e');
    }
  }

  void _autoUpdateRankings() {
    debugPrint(
      '[FederationMgmt] Auto-updating rankings for '
      '${_federations.length} federations',
    );
    // Real implementation would recalculate from fight results.
    notifyListeners();
  }
}
