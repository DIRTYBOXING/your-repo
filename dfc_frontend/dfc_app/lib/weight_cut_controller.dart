import 'package:flutter/foundation.dart';
import '../state/weight_cut_state.dart';
import '../repositories/weight_cut_repository.dart';
import '../models/weight_cut_model.dart';

/// V12 CONTROLLER: WEIGHT CUT ENGINE
class WeightCutController extends ChangeNotifier {
  final WeightCutRepository repository;

  WeightCutController({required this.repository});

  WeightCutState _state = WeightCutInitial();
  WeightCutState get state => _state;

  Future<void> loadTelemetry() async {
    _state = WeightCutLoading();
    notifyListeners();

    try {
      final data = await repository.getWeightCutTelemetry();
      _state = WeightCutLoaded(data);
    } catch (e) {
      _state = WeightCutError(e.toString());
    } finally {
      notifyListeners();
    }
  }

  /// OPTIMISTIC UI UPDATE: Instant state mutation, async backend sync
  Future<void> adjustWaterIntake(double amount) async {
    if (_state is WeightCutLoaded) {
      final currentData = (_state as WeightCutLoaded).data;

      final updatedIntake = currentData.waterIntake + amount;
      final newIntake = updatedIntake < 0 ? 0.0 : updatedIntake;

      // Immediately show the result in the UI without waiting for network
      _state = WeightCutLoaded(
        WeightCutModel(
          currentWeight: currentData.currentWeight,
          targetWeight: currentData.targetWeight,
          waterIntake: newIntake,
          waterTarget: currentData.waterTarget,
          carbsLimit: currentData.carbsLimit,
          sodiumLimit: currentData.sodiumLimit,
          phase: currentData.phase,
        ),
      );
      notifyListeners();

      // Silently sync with backend
      await repository.updateWaterIntake(newIntake);
    }
  }
}
