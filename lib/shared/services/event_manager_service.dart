import 'package:flutter/foundation.dart';
import '../models/event_manager_model.dart';

/// EventManagerService
/// Manages the lineup/order of fights for a show (fight card)
class EventManagerService with ChangeNotifier {
  final List<FightCardEvent> _lineup = [];

  List<FightCardEvent> get lineup => List.unmodifiable(_lineup);

  void addFight(FightCardEvent event) {
    _lineup.add(event);
    _lineup.sort((a, b) => a.order.compareTo(b.order));
    notifyListeners();
  }

  void removeFight(int order) {
    _lineup.removeWhere((e) => e.order == order);
    notifyListeners();
  }

  void updateFight(int order, FightCardEvent updated) {
    final idx = _lineup.indexWhere((e) => e.order == order);
    if (idx != -1) {
      _lineup[idx] = updated;
      notifyListeners();
    }
  }

  void reorderFight(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _lineup.length ||
        newIndex < 0 ||
        newIndex >= _lineup.length) {
      return;
    }
    final fight = _lineup.removeAt(oldIndex);
    _lineup.insert(newIndex, fight);
    notifyListeners();
  }

  void clearLineup() {
    _lineup.clear();
    notifyListeners();
  }
}

/// Example usage:
/// final manager = EventManagerService();
/// manager.addFight(FightCardEvent(order: 1, label: 'Fight 1', fighterA: 'A', fighterB: 'B', type: 'Prelim'));
