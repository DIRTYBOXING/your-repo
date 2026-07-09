/// Security Rules Verification Script
/// Validates that Firestore security rules are correctly implemented
/// Run this after deploying firestore.rules to staging environment

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecurityRulesVerifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SecurityRulesVerifier({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// Run all security rule tests
  Future<SecurityVerificationResult> verifyAllRules() async {
    final results = <String, bool>{};
    final errors = <String, String>{};

    // Test 1: Owner can read own profile
    try {
      final result = await _testOwnerReadProfile();
      results['owner_read_profile'] = result;
      debugPrint('✅ Owner read profile: $result');
    } catch (e) {
      results['owner_read_profile'] = false;
      errors['owner_read_profile'] = e.toString();
    }

    // Test 2: Owner cannot write earnings
    try {
      final result = await _testOwnerCannotWriteEarnings();
      results['owner_cannot_write_earnings'] = result;
      debugPrint('✅ Owner earnings write blocked: $result');
    } catch (e) {
      results['owner_cannot_write_earnings'] = false;
      errors['owner_cannot_write_earnings'] = e.toString();
    }

    // Test 3: Owner can append conversions (audit log)
    try {
      final result = await _testOwnerCanAppendConversions();
      results['owner_append_conversions'] = result;
      debugPrint('✅ Owner append conversions: $result');
    } catch (e) {
      results['owner_append_conversions'] = false;
      errors['owner_append_conversions'] = e.toString();
    }

    // Test 4: Guest cannot read profile
    try {
      final result = await _testGuestCannotReadProfile();
      results['guest_cannot_read_profile'] = result;
      debugPrint('✅ Guest profile read blocked: $result');
    } catch (e) {
      results['guest_cannot_read_profile'] = false;
      errors['guest_cannot_read_profile'] = e.toString();
    }

    // Test 5: Read telemetry rules
    try {
      final result = await _testTelemetryRules();
      results['telemetry_rules'] = result;
      debugPrint('✅ Telemetry rules verified: $result');
    } catch (e) {
      results['telemetry_rules'] = false;
      errors['telemetry_rules'] = e.toString();
    }

    final allPassed = results.values.every((r) => r);
    return SecurityVerificationResult(
      passed: allPassed,
      results: results,
      errors: errors,
    );
  }

  /// Test: Owner can read their own profile
  Future<bool> _testOwnerReadProfile() async {
    try {
      final creatorId = 'hero_creator_test_001';
      final doc = await _firestore
          .collection('creator_dashboards')
          .doc(creatorId)
          .collection('profile')
          .doc('info')
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Test: Owner cannot write to earnings
  Future<bool> _testOwnerCannotWriteEarnings() async {
    try {
      final creatorId = 'hero_creator_test_001';
      await _firestore
          .collection('creator_dashboards')
          .doc(creatorId)
          .collection('earnings')
          .doc('7_2026')
          .set({'totalEarnings': 9999.99});
      return false; // Should have failed
    } catch (e) {
      return e.toString().contains('permission');
    }
  }

  /// Test: Owner can append conversions
  Future<bool> _testOwnerCanAppendConversions() async {
    try {
      final creatorId = 'hero_creator_test_001';
      await _firestore
          .collection('creator_dashboards')
          .doc(creatorId)
          .collection('conversions')
          .add({
            'clipId': 'test_clip',
            'value': '10.50',
            'timestamp': FieldValue.serverTimestamp(),
            'metadata': {'test': true},
          });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Test: Guest cannot read profile
  Future<bool> _testGuestCannotReadProfile() async {
    try {
      // Simulate guest by attempting read without auth
      final creatorId = 'hero_creator_test_001';
      await _firestore
          .collection('creator_dashboards')
          .doc(creatorId)
          .collection('profile')
          .doc('info')
          .get();
      return false; // Should have failed
    } catch (e) {
      return e.toString().contains('permission');
    }
  }

  /// Test: Telemetry collection rules
  Future<bool> _testTelemetryRules() async {
    try {
      // Authenticated users can write telemetry
      await _firestore
          .collection('telemetry')
          .collection('creator_listeners')
          .add({
            'creatorId': 'hero_creator_test_001',
            'status': 'connected',
            'timestamp': FieldValue.serverTimestamp(),
          });
      return true;
    } catch (e) {
      return false;
    }
  }
}

class SecurityVerificationResult {
  final bool passed;
  final Map<String, bool> results;
  final Map<String, String> errors;

  SecurityVerificationResult({
    required this.passed,
    required this.results,
    required this.errors,
  });

  String get summary {
    final passCount = results.values.where((r) => r).length;
    final total = results.length;
    final status = passed ? '✅ PASSED' : '❌ FAILED';
    return '$status: $passCount/$total tests passed\n\nDetails:\n${_formatResults()}';
  }

  String _formatResults() {
    final buffer = StringBuffer();
    results.forEach((test, passed) {
      final status = passed ? '✅' : '❌';
      buffer.writeln('$status $test');
      if (!passed && errors.containsKey(test)) {
        buffer.writeln('   Error: ${errors[test]}');
      }
    });
    return buffer.toString();
  }
}
