import 'dart:convert';
import 'package:http/http.dart' as http;

class WeightCutService {
  static Future<List<Map<String, dynamic>>> fetchTimeline(
    String fighterId,
    String campId,
  ) async {
    final uri = Uri.parse(
      "http://localhost:8000/api/weight_cut/weight/timeline",
    );

    final resp = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "fighter_id": fighterId,
        "camp_id": campId,
        "days": 28,
      }),
    );

    final data = jsonDecode(resp.body);
    final metrics = data["metrics"] as List;

    return metrics
        .map(
          (m) => {
            "weight": (m["weight"] as num).toDouble(),
            "target_weight": (m["target_weight"] as num).toDouble(),
            "stress_level": (m["stress_level"] as num).toDouble(),
          },
        )
        .toList();
  }
}
