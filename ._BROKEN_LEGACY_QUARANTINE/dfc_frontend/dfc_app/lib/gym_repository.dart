import '../../api_service.dart';
import '../models/gym_model.dart';

class GymRepository {
  final ApiService apiService;

  GymRepository({required this.apiService});

  Future<GymModel> getGymProfile(String gymId) async {
    final data = await apiService.callFunction('getGymProfile', {
      'gymId': gymId,
    });
    return GymModel.fromJson(data);
  }
}
