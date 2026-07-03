import 'package:firebase_auth/firebase_auth.dart';
import '../models/auth_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<AuthUser?> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred.user != null) {
        return AuthUser(id: cred.user!.uid, email: cred.user!.email ?? email);
      }
    } catch (e) {
      throw Exception("Login failed: ${e.toString()}");
    }
    return null;
  }

  Future<AuthUser?> register(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred.user != null) {
        return AuthUser(id: cred.user!.uid, email: cred.user!.email ?? email);
      }
    } catch (e) {
      throw Exception("Registration failed: ${e.toString()}");
    }
    return null;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
