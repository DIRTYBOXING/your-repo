import 'package:flutter/foundation.dart';
import '../../api_service.dart';
import '../state/gym_state.dart';
import '../models/gym_model.dart';

class GymController extends ChangeNotifier {
  final ApiService apiService;

  GymController({required this.apiService});

  GymState _state = GymInitial();
  GymState get state => _state;

  Future<void> loadGymProfile(String gymId) async {
    _state = GymLoading();
    notifyListeners();

    try {
      final response = await apiService.callFunction('getGymProfile', {
        'gymId': gymId,
      });
      final data = GymModel.fromJson(response);
      _state = GymLoaded(data);
    } catch (e) {
      _state = GymError(e.toString());
    } finally {
      notifyListeners();
    }
  }
}
