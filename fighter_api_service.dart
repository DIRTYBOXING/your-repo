import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fighter_model.dart';

class FighterApiService {
  // Replace with your actual deployed backend URL or emulator
  static const String baseUrl = 'http://localhost:8080';

  Future<List<FighterModel>> getFighters() async {
    final response = await http.get(Uri.parse('$baseUrl/fighters'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => FighterModel.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load fighters. Status: ${response.statusCode}',
      );
    }
  }

  Future<FighterModel> createFighter(FighterModel fighter) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fighters'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(fighter.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return FighterModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to create fighter. Status: ${response.statusCode}',
      );
    }
  }
}
