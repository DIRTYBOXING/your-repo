import 'package:flutter/foundation.dart';
import '../repositories/growth_repository.dart';
import '../state/growth_state.dart';

class GrowthController extends ChangeNotifier {
  final GrowthRepository repo;

  GrowthState _state = GrowthInitial();
  GrowthState get state => _state;

  GrowthController({required this.repo});

  Future<void> loadGrowthData() async {
    _state = GrowthLoading();
    notifyListeners();
    try {
      final data = await repo.getGrowthData();
      _state = GrowthLoaded(data);
    } catch (e) {
      _state = GrowthError(e.toString());
    } finally {
      notifyListeners();
    }
  }

  Future<void> claimReward(String missionId) async {
    try {
      await repo.claimMissionReward(missionId);
      await loadGrowthData(); // Refresh the missions and token balances
    } catch (e) {
      // Silently fail or log in V12
    }
  }
}
