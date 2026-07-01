import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Legacy compatibility wrapper that routes automation through Firebase Functions.
class WorkflowAutomationClient {
  WorkflowAutomationClient([String? ignoredBaseUrl])
    : _functions = FirebaseFunctions.instanceFor(
        region: 'australia-southeast1',
      );

  final FirebaseFunctions _functions;

  /// Helper to get the current Firebase user ID safely
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;
  String? get _currentUserEmail => FirebaseAuth.instance.currentUser?.email;

  Future<Map<String, dynamic>> _triggerWorkflow({
    required String workflowType,
    required Map<String, dynamic> payload,
    bool expectCallback = false,
  }) async {
    final callable = _functions.httpsCallable('triggerN8N');
    final response = await callable.call<Map<String, dynamic>>({
      'workflowType': workflowType,
      'payload': payload,
      'expectCallback': expectCallback,
    });

    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['status'] == 'error') {
      throw Exception(data['message'] ?? 'Workflow trigger failed');
    }

    return data;
  }

  /// 1. Triggered via your `/ppv-event` webhook
  Future<void> createPpvEvent({
    required String eventId,
    required String eventName,
    required String eventDate,
    required List<String> fighters,
    required double price,
    required String posterUrl,
  }) async {
    await _triggerWorkflow(
      workflowType: 'ppv_event',
      payload: {
        'eventId': eventId,
        'eventName': eventName,
        'eventDate': eventDate,
        'fighters': fighters,
        'price': price,
        'posterUrl': posterUrl,
        'action': 'create',
      },
    );
  }

  /// 2. Triggered via your `/user-register` webhook
  Future<void> registerUser({
    required String userId,
    required String email,
    required String name,
    required String phone,
  }) async {
    await _triggerWorkflow(
      workflowType: 'user_register',
      payload: {'userId': userId, 'email': email, 'name': name, 'phone': phone},
    );
  }

  /// 3. Triggered via your `/payment` webhook (NOW INCLUDES USER INFO)
  Future<void> processPayment({
    required String eventId,
    required double amount,
    required String currency,
    required String paymentMethod,
  }) async {
    // Stop unauthenticated purchases
    if (_currentUserId == null) throw Exception('User not logged in');

    await _triggerWorkflow(
      workflowType: 'payment',
      payload: {
        'userId': _currentUserId, // Essential for sending highlights later!
        'email': _currentUserEmail,
        'eventId': eventId,
        'amount': amount,
        'currency': currency,
        'paymentMethod': paymentMethod,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 4. Triggered via the Interactive Hype Quiz (NOW INCLUDES USER INFO)
  Future<void> submitPrediction({
    required String ppvTitle,
    required Map<int, String> answers,
  }) async {
    // If not logged in, we can't pay them out later!
    if (_currentUserId == null) {
      throw Exception('Must be logged in to predict & earn DFC tokens');
    }

    await _triggerWorkflow(
      workflowType: 'prediction',
      payload: {
        'userId': _currentUserId, // Essential for paying out DFC Tokens!
        'email': _currentUserEmail,
        'ppvTitle': ppvTitle,
        'answers': answers,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Keep the old promotion generator just in case you use it directly
  Future<String> generatePost({required String webInput}) async {
    final response = await _triggerWorkflow(
      workflowType: 'content_brain',
      payload: {
        'webInput': webInput,
        'platform': 'all',
        'postType': 'text',
        'brandTone': 'hype',
        'audienceType': 'fans',
        'niche': 'general',
        'objective': 'engagement',
      },
    );

    return jsonEncode(response);
  }
}

@Deprecated('Use WorkflowAutomationClient')
typedef N8nBackendClient = WorkflowAutomationClient;
