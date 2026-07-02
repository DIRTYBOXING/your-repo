import '../entities/event.dart';
import '../entities/gym.dart';

class MapEventsAndGyms {
  Map<String, dynamic> call(List<Event> events, List<Gym> gyms) {
    return {
      'eventCount': events.length,
      'gymCount': gyms.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
