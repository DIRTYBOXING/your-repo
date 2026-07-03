import '../../api_service.dart';
import '../models/growth_model.dart';

class GrowthRepository {
  final ApiService api;
  GrowthRepository({required this.api});

  Future<GrowthDataModel> getGrowthData() async {
    final data = await api.callFunction("getGrowthData");
    return GrowthDataModel.fromJson(data);
  }

  Future<void> claimMissionReward(String missionId) async {
    await api.callFunction("claimMissionReward", {"missionId": missionId});
  }
}
