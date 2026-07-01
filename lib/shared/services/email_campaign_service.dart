import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// EmailCampaignService — Sends campaigns via SendGrid Cloud Functions.
class EmailCampaignService {
  static final _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );

  /// Send a campaign email to a list of recipients.
  Future<Map<String, dynamic>> sendCampaignEmail({
    required String subject,
    required String htmlBody,
    required List<Map<String, String>> recipients,
    String? fromName,
  }) async {
    try {
      final result = await _functions.httpsCallable('sendCampaignEmail').call({
        'subject': subject,
        'htmlBody': htmlBody,
        'recipients': recipients,
        'fromName': ?fromName,
      });
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e) {
      debugPrint('EmailCampaignService.sendCampaignEmail error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Manage the gym email contact list (add, remove, list).
  Future<Map<String, dynamic>> manageEmailList({
    required String action,
    List<Map<String, String>>? contacts,
  }) async {
    try {
      final result = await _functions.httpsCallable('manageEmailList').call({
        'action': action,
        'contacts': ?contacts,
      });
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e) {
      debugPrint('EmailCampaignService.manageEmailList error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
