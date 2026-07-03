import '../models/dashboard_models.dart';
import '../../api_service.dart';

class DashboardRepository {
  final ApiService apiService;

  DashboardRepository({required this.apiService});

  Future<DashboardModel> getDashboard() async {
    final response = await apiService.callFunction('getDashboard');
    return DashboardModel.fromJson(response);
  }
}
