import '../../api_service.dart';
import '../models/training_content_model.dart';

class TrainingContentRepository {
  final ApiService api;
  TrainingContentRepository({required this.api});

  Future<List<TrainingContentModel>> getTrainingVault(String creatorId) async {
    final data = await api.callFunction("getTrainingVault", {"creatorId": creatorId});
    final list = data["content"] as List<dynamic>? ?? [];
    return list.map((e) => TrainingContentModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}