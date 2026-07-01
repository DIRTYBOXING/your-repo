import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gym_model.dart';

class GymApiService {
  static const String baseUrl = 'http://localhost:8080';

  Future<List<GymModel>> getGyms() async {
    final response = await http.get(Uri.parse('$baseUrl/gyms'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => GymModel.fromJson(json)).toList();
    } else {
      // Return fallback data if endpoint isn't fully wired yet
      return [
        GymModel(
          id: 'g_001',
          name: 'Launceston Combat Club',
          city: 'Launceston',
          country: 'Australia',
          logoUrl: '',
        ),
        GymModel(
          id: 'g_002',
          name: 'Brisbane Fight Lab',
          city: 'Brisbane',
          country: 'Australia',
          logoUrl: '',
        ),
      ];
    }
  }

  Future<GymModel> createGym(GymModel gym) async {
    final response = await http.post(
      Uri.parse('$baseUrl/gyms'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(gym.toJson()),
    );

    // Optimistic fallback for development
    return gym;
  }
}
