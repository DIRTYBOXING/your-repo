import 'package:flutter/foundation.dart';
import '../repositories/fighter_repository.dart';
import 'fighter_state.dart';

class FighterController extends ChangeNotifier {
  final FighterRepository repository;

  FighterController({required this.repository});

  FighterState _state = FighterInitial();
  FighterState get state => _state;

  Future<void> fetchFighters() async {
    _state = FighterLoading();
    notifyListeners();

    try {
      final data = await repository.getFighters();
      _state = FighterLoaded(data);
    } catch (e) {
      _state = FighterError(e.toString());
    } finally {
      notifyListeners();
    }
  }
}
