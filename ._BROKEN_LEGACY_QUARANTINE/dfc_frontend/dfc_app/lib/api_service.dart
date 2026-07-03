import 'package:cloud_functions/cloud_functions.dart';

class ApiService {
  final FirebaseFunctions _functions;

  ApiService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'australia-southeast1');

  Future<Map<String, dynamic>> callFunction(String functionName, [Map<String, dynamic>? data]) async {
    try {
      final callable = _functions.httpsCallable(functionName);
      final result = await callable.call(data);
      
      // Safely cast to Map
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e) {
      throw Exception("Failed to execute $functionName: $e");
    }
  }
}