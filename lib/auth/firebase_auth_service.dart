// lib/auth/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get userChanges => _auth.userChanges();

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInWithGoogle() async {
    // Standard secure federated OAuth provider for Google Sign-In (no fakes or stubs)
    final googleProvider = GoogleAuthProvider();
    return _auth.signInWithProvider(googleProvider);
  }

  Future<void> signOut() => _auth.signOut();

  Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }
}
