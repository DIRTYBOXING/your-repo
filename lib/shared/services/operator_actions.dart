import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

class OperatorActions {
  /// Calls a secure Cloud Function to trigger an operator action.
  ///
  /// The request is signed with HMAC using the operator's secret key.
  static Future<Map<String, dynamic>> callOperatorAction({
    required String functionUrl,
    required String operatorId,
    required String action,
    required Map<String, dynamic> params,
    required String apiKey,
  }) async {
    final body = jsonEncode({
      'operatorId': operatorId,
      'action': action,
      'params': params,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });

    final hmac = Hmac(sha256, utf8.encode(apiKey));
    final sig = hmac.convert(utf8.encode(body)).toString();

    final res = await http.post(
      Uri.parse(functionUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-Operator-Id': operatorId,
        'X-Operator-Signature': sig,
      },
      body: body,
    );

    if (res.statusCode != 200) {
      throw Exception('Operator action failed: ${res.statusCode} ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
