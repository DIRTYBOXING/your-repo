import 'dart:convert';
import 'package:http/http.dart' as http;

class CoachService {
  static Map<String, dynamic>? _cachedAdvice;

  static Future<Map<String, dynamic>> fetchAdvice(
    String fighterId, {
    bool forceRefresh = false,
  }) async {
    if (_cachedAdvice != null && !forceRefresh) {
      return _cachedAdvice!;
    }

    final uri = Uri.parse("http://localhost:8000/api/coach_ai/coach/advice");

    final resp = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"fighter_id": fighterId, "days": 7}),
    );

    final data = jsonDecode(resp.body);

    _cachedAdvice = {
      "readiness": (data["readiness"] as num).toDouble(),
      "advice": List<Map<String, String>>.from(
        (data["advice"] as List).map(
          (a) => {
            "title": a["title"] as String,
            "message": a["message"] as String,
          },
        ),
      ),
    };

    return _cachedAdvice!;
  }
}
