import '../models/smart_coach_model.dart';
import '../../api_service.dart';

class SmartCoachRepository {
  final ApiService apiService;

  SmartCoachRepository({required this.apiService});

  Future<SmartCoachModel> getSmartCoachData() async {
    // V12 Execution: Fetching directly from the GOLD layer
    final response = await apiService.callFunction('getSmartCoach');
    return SmartCoachModel.fromJson(response);
  }
}
