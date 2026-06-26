import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC AMATEUR LEAGUE SYSTEM — #108
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Builds the grassroots pipeline for combat sports.
///
/// Features:
///   • Amateur fighter profiles with safety-first design
///   • Skill-based divisions (novice, intermediate, advanced)
///   • Regional tournament brackets (auto-generation)
///   • Auto-generated fight cards & event posters
///   • Enhanced safety protocols (medical clearance required)
///   • AI: predict amateur breakout stars & skill progression
///
/// Firestore Collections:
///   amateur_fighters/{fighterId}       — Amateur profiles
///   amateur_tournaments/{tournamentId} — Tournament brackets
///   amateur_leagues/{leagueId}         — League definitions
///
/// ═══════════════════════════════════════════════════════════════════════════

enum AmateurDivision { novice, intermediate, advanced, eliteAmateur }

enum TournamentFormat { singleElimination, doubleElimination, roundRobin }

class AmateurFighterProfile {
  final String id;
  final String name;
  final String gymId;
  final AmateurDivision division;
  final String weightClass;
  final String sport;
  final int wins;
  final int losses;
  final int draws;
  final bool medicalCleared;
  final DateTime? lastMedicalDate;
  final double skillRating; // 0.0 – 100.0

  const AmateurFighterProfile({
    required this.id,
    required this.name,
    required this.gymId,
    required this.division,
    required this.weightClass,
    required this.sport,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.medicalCleared = false,
    this.lastMedicalDate,
    this.skillRating = 50.0,
  });

  int get totalFights => wins + losses + draws;
  double get winRate => totalFights > 0 ? wins / totalFights : 0.0;
}

class TournamentBracket {
  final String id;
  final String leagueId;
  final String name;
  final String weightClass;
  final String sport;
  final AmateurDivision division;
  final TournamentFormat format;
  final List<String> participantIds;
  final List<TournamentMatch> matches;
  final DateTime eventDate;
  final String? winnerId;

  const TournamentBracket({
    required this.id,
    required this.leagueId,
    required this.name,
    required this.weightClass,
    required this.sport,
    required this.division,
    required this.format,
    required this.participantIds,
    this.matches = const [],
    required this.eventDate,
    this.winnerId,
  });
}

class TournamentMatch {
  final String id;
  final int round;
  final int matchNumber;
  final String fighterAId;
  final String fighterBId;
  final String? winnerId;

  const TournamentMatch({
    required this.id,
    required this.round,
    required this.matchNumber,
    required this.fighterAId,
    required this.fighterBId,
    this.winnerId,
  });
}

class AmateurLeagueService extends ChangeNotifier {
  static final AmateurLeagueService _instance =
      AmateurLeagueService._internal();
  factory AmateurLeagueService() => _instance;
  AmateurLeagueService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _initialized = false;
  final _random = Random();

  final List<TournamentBracket> _activeTournaments = [];
  int _totalFightersRegistered = 0;
  final int _tournamentsCompleted = 0;

  // ── Getters ──
  bool get initialized => _initialized;
  int get totalFightersRegistered => _totalFightersRegistered;
  int get tournamentsCompleted => _tournamentsCompleted;
  List<TournamentBracket> get activeTournaments =>
      List.unmodifiable(_activeTournaments);

  // ── Lifecycle ──

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    debugPrint('[AmateurLeague] Online — grassroots pipeline active');
    notifyListeners();
  }

  // ── Fighter Registration ──

  Future<void> registerFighter(AmateurFighterProfile fighter) async {
    if (!fighter.medicalCleared) {
      debugPrint(
        '[AmateurLeague] BLOCKED: ${fighter.name} — no medical clearance',
      );
      return;
    }
    await _firestore.collection('amateur_fighters').doc(fighter.id).set({
      'name': fighter.name,
      'gymId': fighter.gymId,
      'division': fighter.division.name,
      'weightClass': fighter.weightClass,
      'sport': fighter.sport,
      'wins': fighter.wins,
      'losses': fighter.losses,
      'draws': fighter.draws,
      'medicalCleared': fighter.medicalCleared,
      'skillRating': fighter.skillRating,
      'registeredAt': FieldValue.serverTimestamp(),
    });
    _totalFightersRegistered++;
    notifyListeners();
  }

  // ── Auto-Generate Tournament Brackets ──

  TournamentBracket generateBracket({
    required String leagueId,
    required String name,
    required String weightClass,
    required String sport,
    required AmateurDivision division,
    required List<String> participantIds,
    required DateTime eventDate,
    TournamentFormat format = TournamentFormat.singleElimination,
  }) {
    final matches = <TournamentMatch>[];
    final shuffled = List<String>.from(participantIds)..shuffle(_random);

    // Generate first round matches.
    int matchNum = 0;
    for (int i = 0; i < shuffled.length - 1; i += 2) {
      matches.add(
        TournamentMatch(
          id: 'match_${matchNum++}',
          round: 1,
          matchNumber: matchNum,
          fighterAId: shuffled[i],
          fighterBId: shuffled[i + 1],
        ),
      );
    }

    final bracket = TournamentBracket(
      id: 'tournament_${DateTime.now().millisecondsSinceEpoch}',
      leagueId: leagueId,
      name: name,
      weightClass: weightClass,
      sport: sport,
      division: division,
      format: format,
      participantIds: shuffled,
      matches: matches,
      eventDate: eventDate,
    );

    _activeTournaments.add(bracket);
    debugPrint(
      '[AmateurLeague] Generated bracket: ${bracket.name} — '
      '${matches.length} first-round matches',
    );
    notifyListeners();
    return bracket;
  }

  // ── AI: Predict Breakout Stars ──

  /// Predict which amateur fighters are most likely to break out
  /// based on win rate, skill progression, and gym reputation.
  List<Map<String, dynamic>> predictBreakoutStars(
    List<AmateurFighterProfile> fighters,
  ) {
    final scored =
        fighters.map((f) {
          final winScore = f.winRate * 40;
          final skillScore = f.skillRating * 0.4;
          final experienceScore = (f.totalFights.clamp(0, 20) / 20.0) * 20;
          final total = winScore + skillScore + experienceScore;
          return {
            'fighterId': f.id,
            'name': f.name,
            'breakoutScore': total,
            'division': f.division.name,
          };
        }).toList()..sort(
          (a, b) => (b['breakoutScore'] as double).compareTo(
            a['breakoutScore'] as double,
          ),
        );

    debugPrint(
      '[AmateurLeague] AI breakout prediction — '
      'top: ${scored.isNotEmpty ? scored.first['name'] : 'none'}',
    );
    return scored.take(10).toList();
  }

  /// AI: Predict skill progression for a fighter.
  Map<String, double> predictSkillProgression(
    AmateurFighterProfile fighter, {
    int monthsAhead = 6,
  }) {
    final currentRating = fighter.skillRating;
    final growthRate = fighter.division == AmateurDivision.novice
        ? 3.0
        : fighter.division == AmateurDivision.intermediate
        ? 2.0
        : 1.0;

    return {
      'currentRating': currentRating,
      'projectedRating': (currentRating + growthRate * monthsAhead).clamp(
        0.0,
        100.0,
      ),
      'monthsToAdvanced': fighter.division != AmateurDivision.advanced
          ? ((80.0 - currentRating) / growthRate).ceilToDouble()
          : 0,
    };
  }
}
