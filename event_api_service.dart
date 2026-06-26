import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';

class EventApiService {
  static const String baseUrl = 'http://localhost:8080';

  Future<List<EventModel>> getEvents() async {
    final response = await http.get(Uri.parse('$baseUrl/events'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => EventModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load events. Status: ${response.statusCode}');
    }
  }

  Future<EventModel> createEvent(EventModel event) async {
    final response = await http.post(
      Uri.parse('$baseUrl/events'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(event.toJson()),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return EventModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create event. Status: ${response.statusCode}');
    }
  }
}
