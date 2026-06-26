import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/drone_racing_models.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC AIRCOMBAT — Drone Racing Service
///
/// "Can't fight? FLY. Same adrenaline. Same glory."
///
/// Manages the full drone racing pipeline:
///   Pilot registration → Track catalog → Race events → Live timing →
///   Leaderboards → Season standings → Sponsor integration
///
/// Firestore collections:
///   race_pilots/{pilotId}
///   race_tracks/{trackId}
///   race_events/{raceId}
///   race_events/{raceId}/laps/{lapDoc}
///   race_seasons/{seasonId}
///   race_leaderboard (aggregated)
/// ═══════════════════════════════════════════════════════════════════════════
class DroneRacingService extends ChangeNotifier {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── Cached state ──────────────────────────────────────────────────
  List<DroneRaceEvent> _upcomingRaces = [];
  List<DroneRaceEvent> get upcomingRaces => List.unmodifiable(_upcomingRaces);

  List<RaceTrack> _tracks = [];
  List<RaceTrack> get tracks => List.unmodifiable(_tracks);

  // ══════════════════════════════════════════════════════════════════
  //  PILOT REGISTRATION
  // ══════════════════════════════════════════════════════════════════

  /// Register a fighter as a drone racing pilot.
  /// Requires an active injury or recovery status.
  Future<RacePilot> registerPilot({
    required String fighterId,
    required String callsign,
    InjuryStatus? injury,
    String? injuryNote,
    String? droneSetup,
  }) async {
    final id = _db.collection('race_pilots').doc().id;
    final pilot = RacePilot(
      odId: id,
      odighterId: fighterId,
      callsign: callsign.toUpperCase(),
      currentInjury: injury,
      injuryNote: injuryNote,
      droneSetup: droneSetup,
      joinedAt: DateTime.now(),
    );
    await _db.collection('race_pilots').doc(id).set(pilot.toMap());
    return pilot;
  }

  /// Fetch a pilot by fighter ID.
  Future<RacePilot?> getPilotByFighterId(String fighterId) async {
    final snap = await _db
        .collection('race_pilots')
        .where('odighterId', isEqualTo: fighterId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return RacePilot.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  /// Update pilot callsign, drone setup, or injury info.
  Future<void> updatePilotProfile({
    required String pilotId,
    String? callsign,
    String? droneSetup,
    InjuryStatus? injury,
    String? injuryNote,
  }) async {
    final updates = <String, dynamic>{};
    if (callsign != null) updates['callsign'] = callsign.toUpperCase();
    if (droneSetup != null) updates['droneSetup'] = droneSetup;
    if (injury != null) updates['currentInjury'] = injury.name;
    if (injuryNote != null) updates['injuryNote'] = injuryNote;
    if (updates.isNotEmpty) {
      await _db.collection('race_pilots').doc(pilotId).update(updates);
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  TRACK CATALOG
  // ══════════════════════════════════════════════════════════════════

  /// Load all race tracks.
  Future<List<RaceTrack>> loadTracks() async {
    final snap = await _db.collection('race_tracks').orderBy('name').get();
    _tracks = snap.docs
        .map((doc) => RaceTrack.fromMap(doc.id, doc.data()))
        .toList();
    notifyListeners();
    return _tracks;
  }

  /// Create a new race track (admin only).
  Future<RaceTrack> createTrack(RaceTrack track) async {
    await _db.collection('race_tracks').doc(track.trackId).set(track.toMap());
    _tracks.add(track);
    notifyListeners();
    return track;
  }

  // ══════════════════════════════════════════════════════════════════
  //  RACE EVENTS
  // ══════════════════════════════════════════════════════════════════

  /// Load upcoming races.
  Future<List<DroneRaceEvent>> loadUpcomingRaces() async {
    final snap = await _db
        .collection('race_events')
        .where('status', isEqualTo: 'upcoming')
        .orderBy('scheduledAt')
        .get();
    _upcomingRaces = snap.docs
        .map((doc) => DroneRaceEvent.fromMap(doc.id, doc.data()))
        .toList();
    notifyListeners();
    return _upcomingRaces;
  }

  /// Create a race event (admin / organiser).
  Future<DroneRaceEvent> createRace(DroneRaceEvent race) async {
    await _db.collection('race_events').doc(race.raceId).set(race.toMap());
    notifyListeners();
    return race;
  }

  /// Register a pilot for a race.
  Future<bool> registerForRace({
    required String raceId,
    required String pilotId,
  }) async {
    final ref = _db.collection('race_events').doc(raceId);
    return _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return false;
      final race = DroneRaceEvent.fromMap(snap.id, snap.data()!);
      if (race.isFull) return false;
      if (race.registeredPilotIds.contains(pilotId)) return false;
      tx.update(ref, {
        'registeredPilotIds': FieldValue.arrayUnion([pilotId]),
      });
      return true;
    });
  }

  /// Withdraw from a race.
  Future<void> withdrawFromRace({
    required String raceId,
    required String pilotId,
  }) async {
    await _db.collection('race_events').doc(raceId).update({
      'registeredPilotIds': FieldValue.arrayRemove([pilotId]),
    });
  }

  /// Set race status (upcoming → live → finished).
  Future<void> setRaceStatus(String raceId, String status) async {
    await _db.collection('race_events').doc(raceId).update({'status': status});
  }

  /// Stream live race status.
  Stream<DroneRaceEvent?> streamRace(String raceId) {
    return _db.collection('race_events').doc(raceId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return DroneRaceEvent.fromMap(snap.id, snap.data()!);
    });
  }

  // ══════════════════════════════════════════════════════════════════
  //  LIVE TIMING / LAP RESULTS
  // ══════════════════════════════════════════════════════════════════

  /// Record a lap during a live race.
  Future<void> recordLap({
    required String raceId,
    required LapResult lap,
  }) async {
    await _db
        .collection('race_events')
        .doc(raceId)
        .collection('laps')
        .add(lap.toMap());
  }

  /// Stream lap results for a race (real-time leaderboard).
  Stream<QuerySnapshot<Map<String, dynamic>>> streamLaps(String raceId) {
    return _db
        .collection('race_events')
        .doc(raceId)
        .collection('laps')
        .orderBy('lapTimeSeconds')
        .snapshots();
  }

  // ══════════════════════════════════════════════════════════════════
  //  LEADERBOARDS & STANDINGS
  // ══════════════════════════════════════════════════════════════════

  /// Get global leaderboard (top pilots by reputation points).
  Future<List<RacePilot>> getLeaderboard({int limit = 20}) async {
    final snap = await _db
        .collection('race_pilots')
        .where('isActive', isEqualTo: true)
        .orderBy('reputationPoints', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((doc) => RacePilot.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Award points after a race finishes.
  Future<void> awardRacePoints({
    required String pilotId,
    required int points,
    required bool won,
    required bool podium,
    required double bestLap,
  }) async {
    final ref = _db.collection('race_pilots').doc(pilotId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final d = snap.data()!;
      final currentBest = (d['bestLapSeconds'] ?? 0).toDouble();
      tx.update(ref, {
        'totalRaces': FieldValue.increment(1),
        'wins': FieldValue.increment(won ? 1 : 0),
        'podiums': FieldValue.increment(podium ? 1 : 0),
        'reputationPoints': FieldValue.increment(points),
        if (currentBest == 0 || bestLap < currentBest)
          'bestLapSeconds': bestLap,
      });
    });
  }

  // ══════════════════════════════════════════════════════════════════
  //  SEASON MANAGEMENT
  // ══════════════════════════════════════════════════════════════════

  /// Get current active season info.
  Future<Map<String, dynamic>?> getCurrentSeason() async {
    final snap = await _db
        .collection('race_seasons')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return {'id': snap.docs.first.id, ...snap.docs.first.data()};
  }

  /// Create a new race season.
  Future<void> createSeason({
    required String name,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    await _db.collection('race_seasons').add({
      'name': name,
      'startsAt': Timestamp.fromDate(startsAt),
      'endsAt': Timestamp.fromDate(endsAt),
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ══════════════════════════════════════════════════════════════════
  //  SEED DATA (demo / dev)
  // ══════════════════════════════════════════════════════════════════

  /// Seed sample tracks for development/demo.
  static List<RaceTrack> get sampleTracks => [
    const RaceTrack(
      trackId: 'track_neon_gauntlet',
      name: 'Neon Gauntlet',
      location: 'Las Vegas, NV',
      difficulty: TrackDifficulty.pro,
      gateCount: 18,
      trackLengthMeters: 320,
      hasNightMode: true,
    ),
    const RaceTrack(
      trackId: 'track_warehouse_blitz',
      name: 'Warehouse Blitz',
      location: 'Brooklyn, NY',
      difficulty: TrackDifficulty.amateur,
      gateCount: 12,
      trackLengthMeters: 200,
      laps: 5,
    ),
    const RaceTrack(
      trackId: 'track_redbull_micro',
      name: 'Red Bull Ring Micro',
      location: 'Spielberg, Austria',
      difficulty: TrackDifficulty.elite,
      gateCount: 24,
      trackLengthMeters: 510,
      hasNightMode: true,
      hasMovingObstacles: true,
      trackRecordSeconds: 42.3,
      trackRecordHolder: 'GHOST HAWK',
    ),
    const RaceTrack(
      trackId: 'track_cage_circuit',
      name: 'The Cage Circuit',
      location: 'DFC Virtual',
      difficulty: TrackDifficulty.rookie,
      gateCount: 8,
      trackLengthMeters: 120,
      laps: 5,
      isVirtual: true,
    ),
    const RaceTrack(
      trackId: 'track_nightmare_alley',
      name: 'Nightmare Alley',
      location: 'Tokyo, Japan',
      difficulty: TrackDifficulty.nightmare,
      gateCount: 30,
      trackLengthMeters: 680,
      laps: 2,
      hasNightMode: true,
      hasMovingObstacles: true,
    ),
  ];
}
