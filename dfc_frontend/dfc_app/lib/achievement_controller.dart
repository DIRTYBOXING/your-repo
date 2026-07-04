import 'package:flutter/foundation.dart';

import 'achievement_repository.dart';
import 'achievement_state.dart';

class AchievementController extends ChangeNotifier {
  final AchievementRepository repo;
  AchievementState _state = AchievementInitial();
  AchievementState get state => _state;

  AchievementController({required this.repo});

  Future<void> loadAchievements() async {
    _state = AchievementLoading();
    notifyListeners();
    try {
      final data = await repo.getAchievements();
      _state = AchievementLoaded(data);
    } catch (e) {
      _state = AchievementError(e.toString());
    }
    notifyListeners();
  }
}
