import 'dart:convert';
import 'package:http/http.dart' as http;

class SmartCoachApiService {
  static const String baseUrl = "http://localhost:8000/api/coach";

  static Future<String> sendMessage(String message) async {
    try {
      final resp = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": message}),
      );
      final data = jsonDecode(resp.body);
      return data["reply"] ?? "I'm recalibrating my strategy. Ask me again.";
    } catch (e) {
      // Return fallback for UI demo purposes if backend isn't connected
      await Future.delayed(const Duration(seconds: 2));
      return "Stay off the centerline and keep your hands up. We'll review the tape when the network connects.";
    }
  }
}
