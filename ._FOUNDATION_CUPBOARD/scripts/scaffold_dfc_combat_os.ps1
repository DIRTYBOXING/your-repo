param(
  [string]$Root = "."
)

$ErrorActionPreference = "Stop"

function Ensure-Directory {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Write-IfMissing {
  param(
    [string]$Path,
    [string]$Content
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    $parent = Split-Path -Parent $Path
    Ensure-Directory -Path $parent
    Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
    Write-Host "CREATED: $Path"
  } else {
    Write-Host "SKIPPED (exists): $Path"
  }
}

$dirs = @(
  "lib/domain/entities",
  "lib/domain/repositories",
  "lib/domain/usecases",
  "lib/features/maps/screens",
  "lib/features/maps/widgets",
  "lib/features/maps/controllers",
  "lib/features/maps/services",
  "lib/features/gyms/screens",
  "lib/features/gyms/widgets",
  "lib/features/gyms/controllers",
  "lib/features/gyms/services",
  "lib/features/rankings/screens",
  "lib/features/rankings/widgets",
  "lib/features/rankings/controllers",
  "lib/features/rankings/services",
  "lib/features/prediction/screens",
  "lib/features/prediction/widgets",
  "lib/features/prediction/controllers",
  "lib/features/prediction/services",
  "lib/features/health/screens",
  "lib/features/health/widgets",
  "lib/features/health/controllers",
  "lib/features/health/services",
  "lib/features/devices/screens",
  "lib/features/devices/controllers",
  "lib/features/devices/services",
  "lib/features/ai/screens",
  "lib/features/ai/widgets",
  "lib/features/ai/controllers",
  "lib/features/ai/services"
)

Push-Location -Path $Root
try {
  foreach ($dir in $dirs) {
    Ensure-Directory -Path $dir
  }

  Write-IfMissing -Path "lib/domain/entities/fighter.dart" -Content @'
class Fighter {
  Fighter({
    required this.id,
    required this.name,
    required this.rankScore,
    required this.pastPerformanceScore,
    required this.styleMatchupScore,
    required this.healthScore,
    required this.trainingCampScore,
  });

  final String id;
  final String name;
  final double rankScore;
  final double pastPerformanceScore;
  final double styleMatchupScore;
  final double healthScore;
  final double trainingCampScore;
}
'@

  Write-IfMissing -Path "lib/domain/entities/event.dart" -Content @'
class Event {
  Event({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
  });

  final String id;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
}
'@

  Write-IfMissing -Path "lib/domain/entities/prediction.dart" -Content @'
class Prediction {
  Prediction({
    required this.eventId,
    required this.fighterAId,
    required this.fighterBId,
    required this.probabilityA,
    required this.probabilityB,
    required this.confidence,
    required this.modelVersion,
  });

  final String eventId;
  final String fighterAId;
  final String fighterBId;
  final double probabilityA;
  final double probabilityB;
  final double confidence;
  final String modelVersion;
}
'@

  Write-IfMissing -Path "lib/domain/entities/health_metric.dart" -Content @'
class HealthMetric {
  HealthMetric({
    required this.fighterId,
    required this.readiness,
    required this.recovery,
    required this.injuryRisk,
    required this.recordedAt,
  });

  final String fighterId;
  final double readiness;
  final double recovery;
  final double injuryRisk;
  final DateTime recordedAt;
}
'@

  Write-IfMissing -Path "lib/domain/entities/ranking.dart" -Content @'
class Ranking {
  Ranking({
    required this.fighterId,
    required this.division,
    required this.position,
    required this.rating,
  });

  final String fighterId;
  final String division;
  final int position;
  final double rating;
}
'@

  Write-IfMissing -Path "lib/domain/entities/ranking_snapshot.dart" -Content @'
class RankingSnapshot {
  RankingSnapshot({
    required this.fighterId,
    required this.oldPosition,
    required this.newPosition,
    required this.timestamp,
  });

  final String fighterId;
  final int oldPosition;
  final int newPosition;
  final DateTime timestamp;
}
'@

  Write-IfMissing -Path "lib/domain/entities/gym.dart" -Content @'
class Gym {
  Gym({
    required this.id,
    required this.name,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String city;
  final String country;
  final double latitude;
  final double longitude;
}
'@

  Write-IfMissing -Path "lib/domain/entities/gym_style.dart" -Content @'
class GymStyle {
  GymStyle({required this.gymId, required this.primaryStyle, required this.secondaryStyle});

  final String gymId;
  final String primaryStyle;
  final String secondaryStyle;
}
'@

  Write-IfMissing -Path "lib/domain/repositories/prediction_repository.dart" -Content @'
import '../entities/fighter.dart';

abstract class PredictionRepository {
  Future<List<Fighter>> getFightersForEvent(String eventId);
  Future<Map<String, double>> getStatsForEvent(String eventId);
}
'@

  Write-IfMissing -Path "lib/domain/repositories/rankings_repository.dart" -Content @'
import '../entities/ranking.dart';

abstract class RankingsRepository {
  Future<List<Ranking>> getDivisionRankings(String division);
  Future<void> saveDivisionRankings(String division, List<Ranking> rankings);
}
'@

  Write-IfMissing -Path "lib/domain/repositories/gym_repository.dart" -Content @'
import '../entities/gym.dart';

abstract class GymRepository {
  Future<List<Gym>> listGyms();
  Future<List<Gym>> searchGyms(String query);
}
'@

  Write-IfMissing -Path "lib/domain/repositories/event_repository.dart" -Content @'
import '../entities/event.dart';

abstract class EventRepository {
  Future<List<Event>> listUpcomingEvents();
}
'@

  Write-IfMissing -Path "lib/domain/repositories/health_repository.dart" -Content @'
import '../entities/health_metric.dart';

abstract class HealthRepository {
  Future<HealthMetric?> getLatestMetric(String fighterId);
  Future<void> saveMetric(HealthMetric metric);
}
'@

  Write-IfMissing -Path "lib/domain/usecases/calculate_prediction.dart" -Content @'
import '../entities/event.dart';
import '../entities/prediction.dart';
import '../repositories/prediction_repository.dart';

class CalculatePrediction {
  CalculatePrediction(this.repository);

  final PredictionRepository repository;

  Future<Prediction> call(Event event) async {
    final fighters = await repository.getFightersForEvent(event.id);
    final stats = await repository.getStatsForEvent(event.id);

    if (fighters.length < 2) {
      throw StateError('Prediction requires exactly two fighters.');
    }

    final scoreA = _score(fighters[0], stats);
    final scoreB = _score(fighters[1], stats);
    final total = (scoreA + scoreB).clamp(0.0001, double.infinity);

    final probabilityA = scoreA / total;
    final probabilityB = scoreB / total;
    final confidence = (probabilityA - probabilityB).abs();

    return Prediction(
      eventId: event.id,
      fighterAId: fighters[0].id,
      fighterBId: fighters[1].id,
      probabilityA: probabilityA,
      probabilityB: probabilityB,
      confidence: confidence,
      modelVersion: 'dfc-predictor-v1',
    );
  }

  double _score(dynamic fighter, Map<String, double> stats) {
    final pace = stats['pace'] ?? 0.5;
    final defense = stats['defense'] ?? 0.5;
    final consistency = stats['consistency'] ?? 0.5;

    return (
      (fighter.rankScore * 0.28) +
      (fighter.pastPerformanceScore * 0.24) +
      (fighter.styleMatchupScore * 0.18) +
      (fighter.healthScore * 0.18) +
      (fighter.trainingCampScore * 0.12)
    ) * (0.5 + (pace * 0.2) + (defense * 0.15) + (consistency * 0.15));
  }
}
'@

  Write-IfMissing -Path "lib/domain/usecases/update_rankings.dart" -Content @'
import '../entities/ranking.dart';

class UpdateRankings {
  List<Ranking> call(List<Ranking> current, Map<String, double> fightDeltaByFighterId) {
    final updated = current
        .map((r) => Ranking(
              fighterId: r.fighterId,
              division: r.division,
              position: r.position,
              rating: r.rating + (fightDeltaByFighterId[r.fighterId] ?? 0),
            ))
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    for (var i = 0; i < updated.length; i++) {
      updated[i] = Ranking(
        fighterId: updated[i].fighterId,
        division: updated[i].division,
        position: i + 1,
        rating: updated[i].rating,
      );
    }

    return updated;
  }
}
'@

  Write-IfMissing -Path "lib/domain/usecases/compute_p4p_ladder.dart" -Content @'
import '../entities/ranking.dart';

class ComputeP4pLadder {
  List<Ranking> call(List<Ranking> divisionalLeaders, Map<String, double> qualityOfCompetition) {
    final scored = divisionalLeaders
        .map((r) => Ranking(
              fighterId: r.fighterId,
              division: 'P4P',
              position: r.position,
              rating: (r.rating * 0.7) + ((qualityOfCompetition[r.fighterId] ?? 0) * 0.3),
            ))
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    for (var i = 0; i < scored.length; i++) {
      scored[i] = Ranking(
        fighterId: scored[i].fighterId,
        division: scored[i].division,
        position: i + 1,
        rating: scored[i].rating,
      );
    }

    return scored;
  }
}
'@

  Write-IfMissing -Path "lib/domain/usecases/map_events_and_gyms.dart" -Content @'
import '../entities/event.dart';
import '../entities/gym.dart';

class MapEventsAndGyms {
  Map<String, dynamic> call(List<Event> events, List<Gym> gyms) {
    return {
      'eventCount': events.length,
      'gymCount': gyms.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
'@

  Write-IfMissing -Path "lib/features/maps/services/maps_service.dart" -Content @'
class MapsService {
  Future<List<Map<String, dynamic>>> loadEventMarkers() async {
    return <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> loadGymMarkers() async {
    return <Map<String, dynamic>>[];
  }
}
'@

  Write-IfMissing -Path "lib/features/maps/controllers/maps_controller.dart" -Content @'
import '../services/maps_service.dart';

class MapsController {
  MapsController(this.service);

  final MapsService service;

  Future<Map<String, List<Map<String, dynamic>>>> load() async {
    final events = await service.loadEventMarkers();
    final gyms = await service.loadGymMarkers();
    return {'events': events, 'gyms': gyms};
  }
}
'@

  Write-IfMissing -Path "lib/features/maps/screens/event_map_screen.dart" -Content @'
import 'package:flutter/material.dart';

class EventMapScreen extends StatelessWidget {
  const EventMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Event Map Screen')),
    );
  }
}
'@

  Write-IfMissing -Path "lib/features/gyms/services/gym_service.dart" -Content @'
class GymService {
  Future<List<Map<String, dynamic>>> search(String query) async {
    return <Map<String, dynamic>>[];
  }
}
'@

  Write-IfMissing -Path "lib/features/gyms/controllers/gym_controller.dart" -Content @'
import '../services/gym_service.dart';

class GymController {
  GymController(this.service);

  final GymService service;

  Future<List<Map<String, dynamic>>> search(String query) => service.search(query);
}
'@

  Write-IfMissing -Path "lib/features/gyms/screens/gym_directory_screen.dart" -Content @'
import 'package:flutter/material.dart';

class GymDirectoryScreen extends StatelessWidget {
  const GymDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Gym Directory Screen')),
    );
  }
}
'@

  Write-IfMissing -Path "lib/features/rankings/services/rankings_service.dart" -Content @'
class RankingsService {
  Future<List<Map<String, dynamic>>> loadDivision(String division) async {
    return <Map<String, dynamic>>[];
  }
}
'@

  Write-IfMissing -Path "lib/features/rankings/controllers/rankings_controller.dart" -Content @'
import '../services/rankings_service.dart';

class RankingsController {
  RankingsController(this.service);

  final RankingsService service;

  Future<List<Map<String, dynamic>>> load(String division) => service.loadDivision(division);
}
'@

  Write-IfMissing -Path "lib/features/rankings/screens/rankings_dashboard_screen.dart" -Content @'
import 'package:flutter/material.dart';

class RankingsDashboardScreen extends StatelessWidget {
  const RankingsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Rankings Dashboard')),
    );
  }
}
'@

  Write-IfMissing -Path "lib/features/prediction/services/prediction_service.dart" -Content @'
class PredictionService {
  Future<Map<String, dynamic>> loadPrediction(String eventId) async {
    return {
      'eventId': eventId,
      'probabilityA': 0.5,
      'probabilityB': 0.5,
      'confidence': 0.0,
    };
  }
}
'@

  Write-IfMissing -Path "lib/features/prediction/controllers/prediction_controller.dart" -Content @'
import '../services/prediction_service.dart';

class PredictionController {
  PredictionController(this.service);

  final PredictionService service;

  Future<Map<String, dynamic>> load(String eventId) => service.loadPrediction(eventId);
}
'@

  Write-IfMissing -Path "lib/features/prediction/screens/prediction_dashboard_screen.dart" -Content @'
import 'package:flutter/material.dart';

class PredictionDashboardScreen extends StatelessWidget {
  const PredictionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Prediction Dashboard')),
    );
  }
}
'@

  Write-IfMissing -Path "lib/features/health/services/health_service.dart" -Content @'
class HealthService {
  Future<Map<String, dynamic>> loadCampReadiness(String fighterId) async {
    return {
      'fighterId': fighterId,
      'readiness': 0.0,
      'recovery': 0.0,
      'injuryRisk': 0.0,
    };
  }
}
'@

  Write-IfMissing -Path "lib/features/health/controllers/health_controller.dart" -Content @'
import '../services/health_service.dart';

class HealthController {
  HealthController(this.service);

  final HealthService service;

  Future<Map<String, dynamic>> load(String fighterId) => service.loadCampReadiness(fighterId);
}
'@

  Write-IfMissing -Path "lib/features/devices/services/device_service.dart" -Content @'
class DeviceService {
  Future<List<Map<String, dynamic>>> listLinkedDevices() async {
    return <Map<String, dynamic>>[];
  }
}
'@

  Write-IfMissing -Path "lib/features/ai/services/ai_service.dart" -Content @'
class AiService {
  Future<String> ask(String prompt) async {
    if (prompt.trim().isEmpty) {
      return 'No prompt provided.';
    }
    return 'AI response placeholder for: $prompt';
  }
}
'@

  Write-IfMissing -Path "lib/features/ai/controllers/ai_controller.dart" -Content @'
import '../services/ai_service.dart';

class AiController {
  AiController(this.service);

  final AiService service;

  Future<String> ask(String prompt) => service.ask(prompt);
}
'@

  Write-IfMissing -Path "lib/features/ai/screens/ai_interaction_hub_screen.dart" -Content @'
import 'package:flutter/material.dart';

class AiInteractionHubScreen extends StatelessWidget {
  const AiInteractionHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('AI Interaction Hub')),
    );
  }
}
'@

  Write-Host "Scaffold complete."
} finally {
  Pop-Location
}
