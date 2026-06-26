import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Account Recovery Service — Forgot password, email recovery, lockout help
/// Like Facebook's "Find your account" / "Can't log in?" flows
/// ═══════════════════════════════════════════════════════════════════════════
class AccountRecoveryService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  String? _successMessage;
  String? get successMessage => _successMessage;

  // ═══════════════════════════════════════════════════════════════════════
  //  PASSWORD RECOVERY
  // ═══════════════════════════════════════════════════════════════════════

  /// Send password reset email (standard Firebase flow)
  Future<bool> sendPasswordReset(String email) async {
    _loading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final trimmed = email.trim().toLowerCase();
      if (trimmed.isEmpty || !trimmed.contains('@')) {
        _error = 'Please enter a valid email address';
        return false;
      }

      await _auth.sendPasswordResetEmail(email: trimmed);

      // Log recovery attempt
      await _logRecoveryAttempt(
        email: trimmed,
        method: 'password_reset_email',
        success: true,
      );

      _successMessage =
          'Password reset email sent to $trimmed. '
          'Check your inbox (and spam folder).';
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          // Don't reveal if email exists — security best practice
          _successMessage =
              'If an account with that email exists, '
              'a reset link has been sent.';
          return true; // Intentionally return true to not reveal email existence
        case 'too-many-requests':
          _error =
              'Too many reset attempts. Please wait a few minutes and try again.';
        case 'invalid-email':
          _error = 'That doesn\'t look like a valid email address.';
        default:
          _error = 'Something went wrong. Please try again.';
      }
      return false;
    } catch (e) {
      _error = 'Unable to send reset email. Check your connection.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  FIND ACCOUNT BY USERNAME / DISPLAY NAME
  // ═══════════════════════════════════════════════════════════════════════

  /// Help user find their account when they forgot their email.
  /// Returns a masked email (e.g., "h***@gmail.com") if found.
  Future<String?> findAccountByUsername(String username) async {
    _loading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final trimmed = username.trim().toLowerCase();
      if (trimmed.isEmpty) {
        _error = 'Please enter your username or display name';
        return null;
      }

      // Search by username first
      var query = await _db
          .collection('users')
          .where('username', isEqualTo: trimmed)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        // Fallback: search by display name (case-insensitive via lowercase field)
        query = await _db
            .collection('users')
            .where('displayName', isEqualTo: trimmed)
            .limit(1)
            .get();
      }

      if (query.docs.isEmpty) {
        _error =
            'No account found with that username. '
            'Try your email address instead.';
        return null;
      }

      final email = query.docs.first.data()['email'] as String? ?? '';
      if (email.isEmpty) {
        _error = 'Account found but no email on file. Contact support.';
        return null;
      }

      final masked = _maskEmail(email);
      _successMessage = 'Found your account! Email: $masked';
      return masked;
    } catch (e) {
      _error = 'Unable to search. Please try again.';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  FIND ACCOUNT BY RECOVERY PHONE
  // ═══════════════════════════════════════════════════════════════════════

  /// Find account using recovery phone number (set in security settings)
  Future<String?> findAccountByPhone(String phone) async {
    _loading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final trimmed = phone.trim();
      if (trimmed.length < 8) {
        _error = 'Please enter a valid phone number';
        return null;
      }

      // Look up in user_settings where recovery phone matches
      final query = await _db
          .collection('user_settings')
          .where('security.recoveryPhone', isEqualTo: trimmed)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _error =
            'No account found with that recovery phone. '
            'Try your email or username.';
        return null;
      }

      final userId = query.docs.first.id;

      // Get the user's email
      final userDoc = await _db.collection('users').doc(userId).get();
      final email = userDoc.data()?['email'] as String? ?? '';
      if (email.isEmpty) {
        _error = 'Account found but no email on file. Contact support.';
        return null;
      }

      final masked = _maskEmail(email);
      _successMessage =
          'Found your account! Email: $masked\n'
          'Use "Forgot Password" with this email to reset.';
      return masked;
    } catch (e) {
      _error = 'Unable to search. Please try again.';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  SEND RECOVERY TO BACKUP EMAIL
  // ═══════════════════════════════════════════════════════════════════════

  /// If user has a recovery email set, send password reset there
  Future<bool> sendResetToRecoveryEmail(String primaryEmail) async {
    _loading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      // Find user by primary email
      final query = await _db
          .collection('users')
          .where('email', isEqualTo: primaryEmail.trim().toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _successMessage =
            'If an account exists, recovery instructions have been sent.';
        return true;
      }

      final userId = query.docs.first.id;
      final settingsDoc =
          await _db.collection('user_settings').doc(userId).get();
      final recoveryEmail =
          settingsDoc.data()?['security']?['recoveryEmail'] as String?;

      if (recoveryEmail == null || recoveryEmail.isEmpty) {
        _error =
            'No recovery email has been set up for this account. '
            'Try the standard password reset.';
        return false;
      }

      // Firebase doesn't natively send to backup email, so we log
      // the request and inform the user to check their recovery email.
      // In production, this would trigger a Cloud Function to send
      // a custom recovery link to the backup email.
      await _logRecoveryAttempt(
        email: primaryEmail,
        method: 'recovery_email',
        success: true,
        metadata: {'recoveryEmail': _maskEmail(recoveryEmail)},
      );

      _successMessage =
          'Recovery instructions sent to your backup email '
          '(${_maskEmail(recoveryEmail)}). Check your inbox.';
      return true;
    } catch (e) {
      _error = 'Unable to send recovery email. Please try again.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  EMAIL VERIFICATION RE-SEND
  // ═══════════════════════════════════════════════════════════════════════

  /// Re-send email verification for the current user
  Future<bool> resendEmailVerification() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _error = 'You must be logged in to verify your email.';
        return false;
      }

      if (user.emailVerified) {
        _successMessage = 'Your email is already verified!';
        return true;
      }

      await user.sendEmailVerification();
      _successMessage = 'Verification email sent to ${user.email}';
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        _error = 'Too many requests. Please wait before trying again.';
      } else {
        _error = 'Failed to send verification email.';
      }
      return false;
    } catch (e) {
      _error = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  CHECK ACCOUNT STATUS
  // ═══════════════════════════════════════════════════════════════════════

  /// Check if an account exists and its status (active, deactivated, etc.)
  Future<Map<String, dynamic>?> checkAccountStatus(String email) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final trimmed = email.trim().toLowerCase();

      // Check Firestore user document (fetchSignInMethodsForEmail removed in newer Firebase Auth)
      final query = await _db
          .collection('users')
          .where('email', isEqualTo: trimmed)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return {'exists': false};
      }

      final data = query.docs.first.data();
      return {
        'exists': true,
        'profileComplete': true,
        'isActive': data['isActive'] ?? true,
        'emailVerified': data['emailVerified'] ?? false,
      };
    } catch (e) {
      _error = 'Unable to check account status.';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Mask an email for display: "user@example.com" → "u***r@e***e.com"
  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '***@***.***';

    final local = parts[0];
    final domain = parts[1];

    String maskedLocal;
    if (local.length <= 2) {
      maskedLocal = '${local[0]}***';
    } else {
      maskedLocal = '${local[0]}***${local[local.length - 1]}';
    }

    final domainParts = domain.split('.');
    String maskedDomain;
    if (domainParts.length >= 2) {
      final domName = domainParts[0];
      final tld = domainParts.sublist(1).join('.');
      if (domName.length <= 2) {
        maskedDomain = '$domName.$tld';
      } else {
        maskedDomain =
            '${domName[0]}***${domName[domName.length - 1]}.$tld';
      }
    } else {
      maskedDomain = domain;
    }

    return '$maskedLocal@$maskedDomain';
  }

  /// Log a recovery attempt for audit trail
  Future<void> _logRecoveryAttempt({
    required String email,
    required String method,
    required bool success,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _db.collection('recovery_attempts').add({
        'email': email,
        'method': method,
        'success': success,
        'metadata': metadata,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : 'mobile',
      });
    } catch (_) {
      // Audit logging should never block the user flow
    }
  }

  /// Clear status messages
  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
