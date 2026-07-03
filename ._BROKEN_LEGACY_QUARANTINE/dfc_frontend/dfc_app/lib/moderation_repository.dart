import '../../api_service.dart';
import '../models/moderation_model.dart';

class ModerationRepository {
  final ApiService api;
  ModerationRepository({required this.api});

  Future<List<ReportModel>> getReportedItems() async {
    final data = await api.callFunction("getReportedItems");
    final list = data["reports"] as List<dynamic>? ?? [];
    return list
        .map((e) => ReportModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> resolveReport(
    String reportId,
    String action,
    String targetId,
    String type,
  ) async {
    await api.callFunction("resolveReport", {
      "reportId": reportId,
      "action": action,
      "targetId": targetId,
      "type": type,
    });
  }
}
