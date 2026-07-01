import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/app_logger.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT MATCHER SERVICE — Smart Fighter Matching Engine
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Connects to the fighter databank to match fighters evenly by:
///   - Weight class
///   - Win/loss record & experience level
///   - Fighting style & stance
///   - Location (local / interstate / international)
///   - Availability & travel willingness
///
/// Key use-cases:
///   1. Build even matchups for fight cards
///   2. Last-minute / emergency replacements
///   3. Auto-fill fight card bouts from database
///   4. Send filled cards to fighters, coaches, promoters
///
/// ═══════════════════════════════════════════════════════════════════════════

/// A scored match result
class MatchResult {
  final Map<String, dynamic> fighter;
  final double score; // 0-100 compatibility
  final List<String> matchReasons;

  const MatchResult({
    required this.fighter,
    required this.score,
    this.matchReasons = const [],
  });

  String get name => (fighter['fullName'] ?? 'Unknown').toString();
  String get record =>
      '${fighter['wins'] ?? 0}-${fighter['losses'] ?? 0}-${fighter['draws'] ?? 0}';
  String get weightClass => (fighter['weightClass'] ?? '').toString();
  String get sportType => (fighter['sportType'] ?? '').toString();
  String get gym => (fighter['currentGymId'] ?? '').toString();
  String get city => (fighter['city'] ?? '').toString();
  String get country => (fighter['country'] ?? '').toString();
  String get stance => (fighter['stance'] ?? '').toString();
  String get fighterId =>
      (fighter['fighterId'] ?? fighter['id'] ?? '').toString();
  int get wins => (fighter['wins'] as num?)?.toInt() ?? 0;
  int get losses => (fighter['losses'] as num?)?.toInt() ?? 0;
  int get totalFights => (fighter['totalFights'] as num?)?.toInt() ?? 0;
  double get winPercentage =>
      (fighter['winPercentage'] as num?)?.toDouble() ?? 0;
  String get nickname => (fighter['nickname'] ?? '').toString();
  bool get willingToTravel => fighter['willingToTravel'] == true;
  String get matchupNotes => (fighter['matchupNotes'] ?? '').toString();
  String get availability => (fighter['matchupAvailability'] ?? '').toString();
}

/// Matching criteria configuration
class MatchCriteria {
  final String? weightClass;
  final String? sportType;
  final String? country;
  final String? state;
  final String? city;
  final int? minWins;
  final int? maxWins;
  final int? minTotalFights;
  final int? maxTotalFights;
  final String? preferredStance;
  final bool onlyWillingToTravel;
  final bool onlyAvailable;
  final bool lastMinuteOnly;
  final String? excludeFighterId; // don't match against self
  final DateTime? eventDate;

  const MatchCriteria({
    this.weightClass,
    this.sportType,
    this.country,
    this.state,
    this.city,
    this.minWins,
    this.maxWins,
    this.minTotalFights,
    this.maxTotalFights,
    this.preferredStance,
    this.onlyWillingToTravel = false,
    this.onlyAvailable = true,
    this.lastMinuteOnly = false,
    this.excludeFighterId,
    this.eventDate,
  });
}

class FightMatcherService extends ChangeNotifier {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static const String _databankCollection = 'fighter_databank';

  List<MatchResult> _results = [];
  List<MatchResult> get results => _results;

  bool _searching = false;
  bool get searching => _searching;

  MatchCriteria? _lastCriteria;
  MatchCriteria? get lastCriteria => _lastCriteria;

  // ─────────────────────────────────────────────────────────────────────────
  // SMART MATCH — scored & ranked
  // ─────────────────────────────────────────────────────────────────────────

  /// Find fighters matching criteria, scored by compatibility
  Future<List<MatchResult>> findMatches(MatchCriteria criteria) async {
    _searching = true;
    _lastCriteria = criteria;
    notifyListeners();

    try {
      Query query = _firestore
          .collection(_databankCollection)
          .where('isInPool', isEqualTo: true)
          .where('status', isEqualTo: 'active');

      // Primary filter: weight class
      if (criteria.weightClass != null && criteria.weightClass!.isNotEmpty) {
        query = query.where('weightClass', isEqualTo: criteria.weightClass);
      }

      // Sport type filter
      if (criteria.sportType != null && criteria.sportType!.isNotEmpty) {
        query = query.where('sportType', isEqualTo: criteria.sportType);
      }

      // Country filter
      if (criteria.country != null && criteria.country!.isNotEmpty) {
        query = query.where('country', isEqualTo: criteria.country);
      }

      // Willing to travel
      if (criteria.onlyWillingToTravel) {
        query = query.where('willingToTravel', isEqualTo: true);
      }

      final snap = await query.limit(50).get();
      final fighters = snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        data['id'] = d.id;
        return data;
      }).toList();

      // Score and rank
      _results = _scoreAndRank(fighters, criteria);
      _searching = false;
      notifyListeners();
      return _results;
    } catch (e) {
      AppLogger.error('findMatches failed', error: e, tag: 'FightMatcher');
      _results = [];
      _searching = false;
      notifyListeners();
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LAST-MINUTE REPLACEMENTS
  // ─────────────────────────────────────────────────────────────────────────

  /// Quick search for emergency replacements — available, willing to travel
  Future<List<MatchResult>> findLastMinuteReplacements({
    required String weightClass,
    String? sportType,
    String? excludeFighterId,
  }) async {
    return findMatches(
      MatchCriteria(
        weightClass: weightClass,
        sportType: sportType,
        onlyWillingToTravel: true,
        lastMinuteOnly: true,
        excludeFighterId: excludeFighterId,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EVEN MATCH FINDER — match two fighters evenly
  // ─────────────────────────────────────────────────────────────────────────

  /// Given one fighter's details, find the most evenly-matched opponents
  Future<List<MatchResult>> findEvenMatch({
    required String weightClass,
    required int wins,
    required int losses,
    required int totalFights,
    String? sportType,
    String? stance,
    String? excludeFighterId,
  }) async {
    return findMatches(
      MatchCriteria(
        weightClass: weightClass,
        sportType: sportType,
        minWins: (wins - 3).clamp(0, 999),
        maxWins: wins + 3,
        minTotalFights: (totalFights - 5).clamp(0, 999),
        maxTotalFights: totalFights + 5,
        preferredStance: stance,
        excludeFighterId: excludeFighterId,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // QUICK SEARCH (by name query)
  // ─────────────────────────────────────────────────────────────────────────

  /// Search the databank by name keyword
  Future<List<MatchResult>> searchByName(String query) async {
    if (query.trim().length < 2) {
      _results = [];
      notifyListeners();
      return [];
    }

    _searching = true;
    notifyListeners();

    try {
      final keyword = query.trim().toLowerCase();
      final snap = await _firestore
          .collection(_databankCollection)
          .where('searchKeywords', arrayContains: keyword)
          .where('isInPool', isEqualTo: true)
          .limit(20)
          .get();

      _results = snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return MatchResult(
          fighter: data,
          score: 50, // neutral score for direct search
          matchReasons: ['Name search match'],
        );
      }).toList();
    } catch (e) {
      AppLogger.error('searchByName failed', error: e, tag: 'FightMatcher');
      _results = [];
    }

    _searching = false;
    notifyListeners();
    return _results;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SCORING ALGORITHM
  // ─────────────────────────────────────────────────────────────────────────

  List<MatchResult> _scoreAndRank(
    List<Map<String, dynamic>> fighters,
    MatchCriteria criteria,
  ) {
    final scored = <MatchResult>[];

    for (final f in fighters) {
      // Skip excluded fighter
      final fid = (f['fighterId'] ?? f['id'] ?? '').toString();
      if (criteria.excludeFighterId != null &&
          fid == criteria.excludeFighterId) {
        continue;
      }

      double score = 0;
      final reasons = <String>[];

      // ── Weight class match (30 pts) ──
      if (criteria.weightClass != null &&
          f['weightClass'] == criteria.weightClass) {
        score += 30;
        reasons.add('Weight class match');
      }

      // ── Experience level match (25 pts) ──
      final fWins = (f['wins'] as num?)?.toInt() ?? 0;
      final fTotal = (f['totalFights'] as num?)?.toInt() ?? 0;

      if (criteria.minWins != null && criteria.maxWins != null) {
        if (fWins >= criteria.minWins! && fWins <= criteria.maxWins!) {
          score += 25;
          reasons.add('Similar experience ($fWins wins)');
        } else {
          // Partial credit for close matches
          final diff = (fWins - ((criteria.minWins! + criteria.maxWins!) / 2))
              .abs();
          score += (15 - diff.clamp(0, 15)).toDouble();
          if (diff <= 5) reasons.add('Close experience level');
        }
      } else {
        score += 15; // neutral if no experience criteria
      }

      if (criteria.minTotalFights != null && criteria.maxTotalFights != null) {
        if (fTotal >= criteria.minTotalFights! &&
            fTotal <= criteria.maxTotalFights!) {
          score += 10;
          reasons.add('Similar fight count ($fTotal fights)');
        }
      } else {
        score += 5;
      }

      // ── Location match (15 pts) ──
      final fCountry = (f['country'] ?? '').toString();
      final fState = (f['state'] ?? '').toString();
      final fCity = (f['city'] ?? '').toString();

      if (criteria.city != null && fCity == criteria.city) {
        score += 15;
        reasons.add('Local fighter (same city)');
      } else if (criteria.state != null && fState == criteria.state) {
        score += 10;
        reasons.add('Same state/region');
      } else if (criteria.country != null && fCountry == criteria.country) {
        score += 7;
        reasons.add('Same country');
      } else if (f['willingToTravel'] == true) {
        score += 5;
        reasons.add('Willing to travel');
      }

      // ── Availability (10 pts) ──
      final avail = (f['matchupAvailability'] ?? '').toString();
      if (avail == 'available') {
        score += 10;
        reasons.add('Available now');
      } else if (avail == 'negotiating') {
        score += 5;
        reasons.add('Open to negotiation');
      }

      // ── Stance variety bonus (5 pts) ──
      if (criteria.preferredStance != null) {
        if (f['stance'] == criteria.preferredStance) {
          score += 5;
          reasons.add('Preferred stance match');
        }
      } else {
        score += 3;
      }

      // ── Win percentage parity (5 pts) ──
      final fWinPct = (f['winPercentage'] as num?)?.toDouble() ?? 0;
      if (fWinPct > 0) {
        // Reward similar win percentage (within 20%)
        score += 5;
        if (fWinPct >= 30 && fWinPct <= 70) {
          reasons.add('Competitive record (${fWinPct.toStringAsFixed(0)}%)');
        }
      }

      scored.add(
        MatchResult(
          fighter: f,
          score: score.clamp(0, 100),
          matchReasons: reasons,
        ),
      );
    }

    // Sort by score descending
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored;
  }

  /// Clear current results
  void clearResults() {
    _results = [];
    _lastCriteria = null;
    notifyListeners();
  }
}
