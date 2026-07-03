import 'package:flutter/foundation.dart';
import '../repositories/event_repository.dart';
import '../state/event_state.dart';
import '../models/event_model.dart';

class EventController extends ChangeNotifier {
  final EventRepository repository;

  EventState _state = EventInitial();
  EventState get state => _state;

  EventController({required this.repository});

  Future<void> loadEvents() async {
    _state = EventLoading();
    notifyListeners();

    try {
      final events = await repository.getEvents();
      _state = EventLoaded(events);
    } catch (e) {
      _state = EventError(e.toString());
    } finally {
      notifyListeners();
    }
  }

  Future<void> createEvent(String name, String date, String location) async {
    try {
      await repository.createEvent(name, date, location);
      await loadEvents(); // Refresh data
    } catch (e) {
      _state = EventError("Failed to create event: $e");
      notifyListeners();
    }
  }

  Future<void> updateEvent(String id, Map<String, dynamic> updates) async {
    try {
      await repository.updateEvent(id, updates);
      await loadEvents(); // Refresh data
    } catch (e) {
      _state = EventError("Failed to update event: $e");
      notifyListeners();
    }
  }

  Future<void> addFightToEvent(
    String eventId,
    List<FightModel> existingFights,
    FightModel newFight,
  ) async {
    try {
      final updatedFights = [
        ...existingFights,
        newFight,
      ].map((f) => f.toJson()).toList();
      await repository.updateEvent(eventId, {'fights': updatedFights});
      await loadEvents(); // Refresh data
    } catch (e) {
      _state = EventError("Failed to add fight: $e");
      notifyListeners();
    }
  }
}
