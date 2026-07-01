import 'package:flutter/material.dart';
import 'package:datafightcentral/shared/models/stats/combat_stats.dart';
import 'package:datafightcentral/shared/services/services.dart' as perf;

class DashboardProvider with ChangeNotifier {
  final perf.PerformanceService _performanceService;

  DashboardProvider(this._performanceService);

  Future<CombatStats> getFighterStats(String fighterId) {
    return _performanceService.getFighterStats(fighterId);
  }
}
