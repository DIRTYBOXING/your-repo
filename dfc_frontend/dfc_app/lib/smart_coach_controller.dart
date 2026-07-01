import 'package:flutter/foundation.dart';
import '../state/smart_coach_state.dart';
import '../repositories/smart_coach_repository.dart';

/// V12 CONTROLLER: SMART COACH ENGINE
class SmartCoachController extends ChangeNotifier {
  final SmartCoachRepository repository;

  SmartCoachController({required this.repository});

  SmartCoachState _state = SmartCoachInitial();
  SmartCoachState get state => _state;

  Future<void> loadSmartCoach() async {
    _state = SmartCoachLoading();
    notifyListeners();

    try {
      // Fetch from the repository which pulls from your GOLD function
      final data = await repository.getSmartCoachData();

      _state = SmartCoachLoaded(data);
    } catch (e) {
      _state = SmartCoachError(e.toString());
    } finally {
      notifyListeners();
    }
  }
}
