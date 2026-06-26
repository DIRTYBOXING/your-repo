// lib/features/auth/services/social_auth_service.dart
// Social login integration — delegates to the main AuthService

import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/services/auth_service.dart';

/// Thin wrapper around AuthService for social login flows.
/// Google, Facebook, and Apple Sign-In are all handled via Firebase Auth.
class SocialAuthService {
  final AuthService _authService = AuthService();

  /// Google Sign-In — uses Firebase Auth provider flow.
  Future<UserCredential?> signInWithGoogle() async {
    return await _authService.signInWithGoogle();
  }

  /// Facebook Sign-In — uses flutter_facebook_auth + Firebase credential.
  Future<UserCredential?> signInWithFacebook() async {
    return await _authService.signInWithFacebook();
  }

  /// Apple Sign-In — uses sign_in_with_apple + Firebase credential.
  Future<UserCredential?> signInWithApple() async {
    return await _authService.signInWithApple();
  }
}
