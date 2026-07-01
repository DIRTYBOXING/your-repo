import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/promoter_model.dart';

class PromoterApiService {
  static const String baseUrl = 'http://localhost:8080';

  Future<List<PromoterModel>> getPromoters() async {
    final response = await http.get(Uri.parse('$baseUrl/promoters'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map(PromoterModel.fromJson).toList();
    } else {
      throw Exception(
        'Failed to load promoters. Status: ${response.statusCode}',
      );
    }
  }

  Future<PromoterModel> createPromoter(PromoterModel promoter) async {
    final response = await http.post(
      Uri.parse('$baseUrl/promoters'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(promoter.toJson()),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return PromoterModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to create promoter. Status: ${response.statusCode}',
      );
    }
  }
}
