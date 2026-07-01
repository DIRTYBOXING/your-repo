import 'dart:convert';
import 'package:http/http.dart' as http;

class CampService {
  static Future<List<double>> fetchTimeline(
    String fighterId,
    String campId,
  ) async {
    final uri = Uri.parse(
      "http://localhost:8000/api/camp_timeline/camp/timeline",
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

    return metrics.map((m) => (m["readiness"] as num).toDouble()).toList();
  }
}
