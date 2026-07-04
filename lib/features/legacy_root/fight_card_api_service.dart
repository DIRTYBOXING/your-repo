import 'dart:convert';
import 'package:http/http.dart' as http;
import 'fight_model.dart';

class FightCardApiService {
  static const String baseUrl = 'http://localhost:8080';

  Future<List<FightModel>> getFights(String eventId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/events/$eventId/fights'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => FightModel.fromJson(json)).toList();
    } else {
      // Return empty list if no fights exist yet
      if (response.statusCode == 404) return [];
      throw Exception('Failed to load fights. Status: ${response.statusCode}');
    }
  }

  Future<FightModel> addFight(String eventId, FightModel fight) async {
    final response = await http.post(
      Uri.parse('$baseUrl/events/$eventId/fights'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(fight.toJson()),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return FightModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add fight. Status: ${response.statusCode}');
    }
  }

  Future<void> updateFightOrders(
    String eventId,
    List<FightModel> fights,
  ) async {
    // Create a payload of just the IDs and their new order
    final payload = fights
        .map((f) => {'id': f.id, 'fight_order': f.fightOrder})
        .toList();

    final response = await http.put(
      Uri.parse('$baseUrl/events/$eventId/fights/reorder'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fights': payload}),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to update fight orders. Status: ${response.statusCode}',
      );
    }
  }
}
