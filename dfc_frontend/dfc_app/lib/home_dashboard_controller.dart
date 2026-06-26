import 'package:flutter/foundation.dart';
import 'blue/state/dashboard_state.dart';
import 'blue/repositories/dashboard_repository.dart';
import 'blue/models/dashboard_models.dart';

/// V4 CONTROLLER: THE AGGREGATOR
/// Handles parallel data fetching, strict state mutation, and error isolation.
class HomeDashboardController extends ChangeNotifier {
  final DashboardRepository repository;

  HomeDashboardController({required this.repository});

  DashboardState _state = DashboardInitial();
  DashboardState get state => _state;

  /// Fires all necessary fetches concurrently for maximum speed.
  Future<void> loadDashboard() async {
    // 1. Lock state to Loading
    _state = DashboardLoading();
    notifyListeners();

    try {
      // 2. V12 Execution: Single streamlined fetch
      final data = await repository.getDashboard();

      // 3. Lock state to Loaded with typed data
      _state = DashboardLoaded(data);
    } catch (e) {
      // 4. Lock state to Error
      _state = DashboardError(e.toString());
    } finally {
      // 5. Broadcast to the GREEN layer
      notifyListeners();
    }
  }
}
