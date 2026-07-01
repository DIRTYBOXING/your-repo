import '../models/event_model.dart';
import '../../api_service.dart';

class EventRepository {
  final ApiService apiService;
  EventRepository({required this.apiService});

  Future<List<EventModel>> getEvents() async {
    final data = await apiService.callFunction('getEvents');
    final List<dynamic> eventsList = data['events'] ?? [];
    return eventsList
        .map((e) => EventModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<String> createEvent(String name, String date, String location) async {
    final data = await apiService.callFunction("createEvent", {
      "name": name,
      "date": date,
      "location": location,
    });
    return data["id"];
  }

  Future<void> updateEvent(String id, Map<String, dynamic> update) async {
    await apiService.callFunction("updateEvent", {"id": id, "update": update});
  }
}
