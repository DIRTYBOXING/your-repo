import 'package:flutter/foundation.dart';
import '../repositories/pickem_repository.dart';
import '../state/pickem_state.dart';

class PickemController extends ChangeNotifier {
  final PickemRepository repo;

  PickemState _state = PickemInitial();
  PickemState get state => _state;

  PickemController({required this.repo});

  Future<void> loadPickems() async {
    _state = PickemLoading();
    notifyListeners();

    try {
      final pickems = await repo.getPickems();
      _state = PickemLoaded(pickems);
    } catch (e) {
      _state = PickemError(e.toString());
    } finally {
      notifyListeners();
    }
  }

  Future<void> submitPick(String pickemId, String selection) async {
    try {
      await repo.submitPickem(pickemId, selection);
      await loadPickems(); // Refresh state immediately
    } catch (e) {}
  }
}
