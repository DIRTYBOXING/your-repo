import '../../api_service.dart';
import '../models/pickem_model.dart';

class PickemRepository {
  final ApiService api;
  PickemRepository({required this.api});

  Future<List<PickemModel>> getPickems() async {
    final data = await api.callFunction("getPickems");
    final list = data["pickems"] as List<dynamic>? ?? [];
    return list
        .map((e) => PickemModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> submitPickem(String pickemId, String selection) async {
    await api.callFunction("submitPickem", {
      "pickemId": pickemId,
      "selection": selection,
    });
  }
}
