import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════════════════════════════════════
// DFC AIRCOMBAT — FPV Drone Racing for Injured Fighters
// Models & Enums
//
// "Can't fight? FLY. Same adrenaline. Same glory."
// ═══════════════════════════════════════════════════════════════════════════

/// Injury status that qualifies a fighter for drone racing league.
enum InjuryStatus {
  acl,
  concussion,
  fracture,
  shoulderLabrum,
  backDisc,
  postSurgery,
  chronicPain,
  mentalHealthBreak,
  other,
}

/// Race track difficulty.
enum TrackDifficulty {
  rookie, // Wide gates, slow speed, no obstacles
  amateur, // Standard gates, moderate speed
  pro, // Tight gates, fast, moving obstacles
  elite, // Red Bull-level — inverted gates, night racing, wind
  nightmare, // Only legends attempt this
}

/// Race format.
enum RaceFormat {
  timeAttack, // Solo — fastest lap wins
  headToHead, // 1v1 bracket elimination
  pack, // 4-8 pilots, first across the line
  endurance, // Most laps in X minutes
  freestyle, // Style points, tricks, crowd vote
}

/// Pilot rank (mirrors fighter tiers).
enum PilotRank {
  cadet, // Just started
  wingman, // Consistent finisher
  ace, // Top 25%
  maverick, // Top 10%
  legend, // Top 1% — invitation only
}

/// A drone racing pilot profile (linked to fighter profile).
class RacePilot {
  final String odId;
  final String odighterId; // links to existing fighter profile
  final String callsign; // e.g. "GHOST HAWK", "IRON TALON"
  final PilotRank rank;
  final InjuryStatus? currentInjury;
  final String? injuryNote;
  final int totalRaces;
  final int wins;
  final int podiums; // top 3
  final double bestLapSeconds;
  final String? droneSetup; // e.g. "5-inch FPV, DJI O3 Air Unit"
  final int reputationPoints;
  final DateTime joinedAt;
  final bool isActive;

  const RacePilot({
    required this.odId,
    required this.odighterId,
    required this.callsign,
    this.rank = PilotRank.cadet,
    this.currentInjury,
    this.injuryNote,
    this.totalRaces = 0,
    this.wins = 0,
    this.podiums = 0,
    this.bestLapSeconds = 0,
    this.droneSetup,
    this.reputationPoints = 0,
    required this.joinedAt,
    this.isActive = true,
  });

  double get winRate => totalRaces > 0 ? (wins / totalRaces * 100) : 0;

  Map<String, dynamic> toMap() => {
    'odId': odId,
    'odighterId': odighterId,
    'callsign': callsign,
    'rank': rank.name,
    'currentInjury': currentInjury?.name,
    'injuryNote': injuryNote ?? '',
    'totalRaces': totalRaces,
    'wins': wins,
    'podiums': podiums,
    'bestLapSeconds': bestLapSeconds,
    'droneSetup': droneSetup ?? '',
    'reputationPoints': reputationPoints,
    'joinedAt': Timestamp.fromDate(joinedAt),
    'isActive': isActive,
  };

  factory RacePilot.fromMap(String id, Map<String, dynamic> d) => RacePilot(
    odId: id,
    odighterId: d['odighterId'] ?? '',
    callsign: d['callsign'] ?? 'UNKNOWN',
    rank: PilotRank.values.firstWhere(
      (r) => r.name == d['rank'],
      orElse: () => PilotRank.cadet,
    ),
    currentInjury: d['currentInjury'] != null
        ? InjuryStatus.values.firstWhere(
            (i) => i.name == d['currentInjury'],
            orElse: () => InjuryStatus.other,
          )
        : null,
    injuryNote: d['injuryNote'],
    totalRaces: d['totalRaces'] ?? 0,
    wins: d['wins'] ?? 0,
    podiums: d['podiums'] ?? 0,
    bestLapSeconds: (d['bestLapSeconds'] ?? 0).toDouble(),
    droneSetup: d['droneSetup'],
    reputationPoints: d['reputationPoints'] ?? 0,
    joinedAt: (d['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    isActive: d['isActive'] ?? true,
  );
}

/// A race track / course definition.
class RaceTrack {
  final String trackId;
  final String name; // e.g. "Neon Gauntlet", "Red Bull Ring Micro"
  final String location; // city / virtual
  final TrackDifficulty difficulty;
  final int gateCount;
  final double trackLengthMeters;
  final int laps;
  final bool isVirtual; // sim racing or real FPV
  final bool hasNightMode;
  final bool hasMovingObstacles;
  final String? imageUrl;
  final double? trackRecordSeconds;
  final String? trackRecordHolder;

  const RaceTrack({
    required this.trackId,
    required this.name,
    required this.location,
    required this.difficulty,
    required this.gateCount,
    required this.trackLengthMeters,
    this.laps = 3,
    this.isVirtual = false,
    this.hasNightMode = false,
    this.hasMovingObstacles = false,
    this.imageUrl,
    this.trackRecordSeconds,
    this.trackRecordHolder,
  });

  Map<String, dynamic> toMap() => {
    'trackId': trackId,
    'name': name,
    'location': location,
    'difficulty': difficulty.name,
    'gateCount': gateCount,
    'trackLengthMeters': trackLengthMeters,
    'laps': laps,
    'isVirtual': isVirtual,
    'hasNightMode': hasNightMode,
    'hasMovingObstacles': hasMovingObstacles,
    'imageUrl': imageUrl ?? '',
    'trackRecordSeconds': trackRecordSeconds ?? 0,
    'trackRecordHolder': trackRecordHolder ?? '',
  };

  factory RaceTrack.fromMap(String id, Map<String, dynamic> d) => RaceTrack(
    trackId: id,
    name: d['name'] ?? '',
    location: d['location'] ?? '',
    difficulty: TrackDifficulty.values.firstWhere(
      (t) => t.name == d['difficulty'],
      orElse: () => TrackDifficulty.rookie,
    ),
    gateCount: d['gateCount'] ?? 0,
    trackLengthMeters: (d['trackLengthMeters'] ?? 0).toDouble(),
    laps: d['laps'] ?? 3,
    isVirtual: d['isVirtual'] ?? false,
    hasNightMode: d['hasNightMode'] ?? false,
    hasMovingObstacles: d['hasMovingObstacles'] ?? false,
    imageUrl: d['imageUrl'],
    trackRecordSeconds: (d['trackRecordSeconds'] as num?)?.toDouble(),
    trackRecordHolder: d['trackRecordHolder'],
  );
}

/// A single race event.
class DroneRaceEvent {
  final String raceId;
  final String trackId;
  final String title; // e.g. "AirCombat Round 5 — Neon Gauntlet"
  final RaceFormat format;
  final DateTime scheduledAt;
  final int maxPilots;
  final List<String> registeredPilotIds;
  final String status; // 'upcoming', 'live', 'finished', 'cancelled'
  final String? livestreamUrl;
  final String? sponsorName; // Red Bull, Monster, etc.
  final String? sponsorLogoUrl;
  final int prizePool; // in DFC points or $
  final Map<String, double>? results; // pilotId → lap time

  const DroneRaceEvent({
    required this.raceId,
    required this.trackId,
    required this.title,
    required this.format,
    required this.scheduledAt,
    this.maxPilots = 8,
    this.registeredPilotIds = const [],
    this.status = 'upcoming',
    this.livestreamUrl,
    this.sponsorName,
    this.sponsorLogoUrl,
    this.prizePool = 0,
    this.results,
  });

  bool get isFull => registeredPilotIds.length >= maxPilots;
  bool get isLive => status == 'live';

  Map<String, dynamic> toMap() => {
    'raceId': raceId,
    'trackId': trackId,
    'title': title,
    'format': format.name,
    'scheduledAt': Timestamp.fromDate(scheduledAt),
    'maxPilots': maxPilots,
    'registeredPilotIds': registeredPilotIds,
    'status': status,
    'livestreamUrl': livestreamUrl ?? '',
    'sponsorName': sponsorName ?? '',
    'sponsorLogoUrl': sponsorLogoUrl ?? '',
    'prizePool': prizePool,
    'results': results ?? {},
  };

  factory DroneRaceEvent.fromMap(String id, Map<String, dynamic> d) =>
      DroneRaceEvent(
        raceId: id,
        trackId: d['trackId'] ?? '',
        title: d['title'] ?? '',
        format: RaceFormat.values.firstWhere(
          (f) => f.name == d['format'],
          orElse: () => RaceFormat.timeAttack,
        ),
        scheduledAt:
            (d['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        maxPilots: d['maxPilots'] ?? 8,
        registeredPilotIds: List<String>.from(d['registeredPilotIds'] ?? []),
        status: d['status'] ?? 'upcoming',
        livestreamUrl: d['livestreamUrl'],
        sponsorName: d['sponsorName'],
        sponsorLogoUrl: d['sponsorLogoUrl'],
        prizePool: d['prizePool'] ?? 0,
        results: (d['results'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      );
}

/// A single lap result during a race.
class LapResult {
  final String pilotId;
  final int lapNumber;
  final double lapTimeSeconds;
  final double topSpeedKmh;
  final int gatesMissed;
  final bool crashed;

  const LapResult({
    required this.pilotId,
    required this.lapNumber,
    required this.lapTimeSeconds,
    this.topSpeedKmh = 0,
    this.gatesMissed = 0,
    this.crashed = false,
  });

  Map<String, dynamic> toMap() => {
    'pilotId': pilotId,
    'lapNumber': lapNumber,
    'lapTimeSeconds': lapTimeSeconds,
    'topSpeedKmh': topSpeedKmh,
    'gatesMissed': gatesMissed,
    'crashed': crashed,
  };
}
