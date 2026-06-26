import '../models/weight_cut_model.dart';
import '../../api_service.dart';

class WeightCutRepository {
  final ApiService apiService;

  WeightCutRepository({required this.apiService});

  Future<WeightCutModel> getWeightCutTelemetry() async {
    // Simulated V12 network fetch
    // In production: final response = await apiService.callFunction('getWeightCutTelemetry');
    await Future.delayed(const Duration(milliseconds: 600));

    return WeightCutModel(
      currentWeight: 164.2,
      targetWeight: 155.0,
      waterIntake: 1.5,
      waterTarget: 3.0,
      carbsLimit: 30,
      sodiumLimit: 500,
      phase: 'Water Loading (Day 3)',
    );
  }

  Future<void> updateWaterIntake(double amount) async {
    // Pushes the exact new water intake value to GOLD / Firestore
    // await apiService.callFunction('logWaterIntake', {'amount': amount});
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
