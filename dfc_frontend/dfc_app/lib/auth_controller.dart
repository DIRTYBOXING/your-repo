import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/auth_user.dart';

class AuthController extends ChangeNotifier {
  final _service = AuthService();
  AuthUser? currentUser;

  bool get isAuthenticated => currentUser != null;

  AuthController() {
    _checkSession();
  }

  void _checkSession() {
    // Auto-login persistence using Firebase Auth state
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        currentUser = AuthUser(id: user.uid, email: user.email ?? '');
        notifyListeners();
      }
    });
  }

  Future<void> login(String email, String password) async {
    currentUser = await _service.login(email, password);
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    currentUser = await _service.register(email, password);
    notifyListeners();
  }

  Future<void> logout() async {
    await _service.logout();
    currentUser = null;
    notifyListeners();
  }
}

// Global instance to bind to GoRouter
final authController = AuthController();
