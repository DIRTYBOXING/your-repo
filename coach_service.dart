import 'dart:convert';
import 'package:http/http.dart' as http;

class CoachService {
  static const String baseUrl = "http://localhost:8003"; // coach-ai-service

  static Future<String> fetchAdvice(String fighterId) async {
    try {
      final url = Uri.parse("$baseUrl/advice/$fighterId");
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data["advice"] ?? "No advice available.";
      } else {
        return "Unable to fetch advice.";
      }
    } catch (e) {
      return "Coach AI is currently analyzing data. Check back shortly.";
    }
  }
}
