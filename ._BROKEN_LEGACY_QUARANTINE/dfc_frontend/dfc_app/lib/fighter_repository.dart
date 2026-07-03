import '../models/fighter_model.dart';
import '../services/api_service.dart';

class FighterRepository {
  final ApiService apiService;

  FighterRepository({required this.apiService});

  Future<List<FighterModel>> getFighters() async {
    try {
      final data = await apiService.callFunction('getFighters');
      final List<dynamic> fightersList = data['fighters'] ?? [];

      return fightersList
          .map((e) => FighterModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw Exception("Failed to fetch fighters: $e");
    }
  }
}
