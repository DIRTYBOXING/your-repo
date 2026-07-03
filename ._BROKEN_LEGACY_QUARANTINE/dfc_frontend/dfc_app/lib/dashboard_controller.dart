import 'package:flutter/foundation.dart';
import '../models/dashboard_item_model.dart';
import '../services/dashboard_service.dart';

class DashboardController extends ChangeNotifier {
  final _service = DashboardService();
  DashboardData? data;

  Future<void> loadDashboard() async {
    data = await _service.fetchDashboard();
    notifyListeners();
  }
}