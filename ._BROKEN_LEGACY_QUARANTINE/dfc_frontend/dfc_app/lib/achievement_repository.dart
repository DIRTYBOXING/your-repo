ck list and tick off completetion heres your next list word for word dot for dot no errorsimport '../../api_service.dart';
import '../models/achievement_model.dart';

class AchievementRepository {
  final ApiService api;
  AchievementRepository({required this.api});

  Future<List<AchievementModel>> getAchievements() async {
    final data = await api.callFunction("getAchievements");
    final list = data as List<dynamic>? ?? [];
    return list.map((e) => AchievementModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> unlock(String id, String title, {String? description, String? icon}) async {
    await api.callFunction("unlockAchievement", {
      "id": id,
      "title": title,
      "description": description,
      "icon": icon,
    });
  }

  Future<void> increment(String id, int amount) async {
    await api.callFunction("incrementAchievementProgress", {
      "id": id,
      "amount": amount,
    });
  }
}