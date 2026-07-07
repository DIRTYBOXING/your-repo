import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../core/logic/result.dart';
import '../../core/logic/failure.dart';
import '../../core/constants/app_constants.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// AUTH ENGINE (BLUE TIER)
/// Manages Firebase Sessions, User Models, and Routing State.
/// ═══════════════════════════════════════════════════════════════════════════
class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _firebaseUser;
  UserModel? _userModel;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  bool _authDisabled = false;
  String? _authDisabledMessage;
  bool _emergencyLocalSession = false;
  StreamSubscription<User?>? _authStateSub;

  AuthService() {
    _init();
  }

  void _init() {
    _authStateSub = _firebaseAuth.authStateChanges().listen((User? user) async {
      _firebaseUser = user;
      if (user != null) {
        await _fetchUserModel(user.uid);
      } else {
        _userModel = null;
      }
      _isInitialized = true;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authStateSub?.cancel();
    super.dispose();
  }

  // ─── STATE GETTERS ──────────────────────────────────────────────────────────
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthTemporarilyDisabled => _authDisabled;
  String? get authDisabledMessage => _authDisabledMessage;
  bool get isEmergencyLocalSession =>
      _emergencyLocalSession || AppConstants.guestMode;
  User? get currentUser => _firebaseUser;
  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;

  // ─── PLATFORM OWNER IDENTITY ────────────────────────────────────────────────
  // The developer / platform owner always gets full access regardless of
  // Firestore role. This is verified against the Firebase Auth email.
  static const String _ownerEmail = 'ausstrainsnetwork@gmail.com';

  bool get _isOwnerEmail =>
      _firebaseUser?.email?.toLowerCase() == _ownerEmail.toLowerCase();

  // ─── ROLE / PERMISSION GETTERS ──────────────────────────────────────────────
  bool get needsOnboarding =>
      isAuthenticated && _userModel == null && !_isOwnerEmail;

  String get userRole {
    if (_isOwnerEmail) return 'owner';
    return _userModel?.role.name ?? 'fan';
  }

  bool get isAdmin {
    if (_isOwnerEmail) return true;
    final role = _userModel?.role.name ?? '';
    return role == 'admin' || role == 'superadmin' || role == 'owner';
  }

  bool get isOwner {
    if (_isOwnerEmail) return true;
    return _userModel?.role.name == 'owner' ||
        _userModel?.role.name == 'superadmin';
  }

  bool get isDeveloper => _isOwnerEmail;

  bool get isDemoUser => AppConstants.guestMode || _emergencyLocalSession;

  String get demoUserId => 'demo_user_${_firebaseUser?.uid ?? "guest"}';

  // ─── AUTH STATE HELPERS ─────────────────────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }

  bool shouldUseEmergencyLocalSession() {
    return _emergencyLocalSession;
  }

  void enableEmergencyLocalSession() {
    _emergencyLocalSession = true;
    notifyListeners();
  }

  // ─── LOGIN LOGIC ────────────────────────────────────────────────────────────
  Future<Result<User>> loginWithEmail(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (userCredential.user != null) {
        await _fetchUserModel(userCredential.user!.uid);
        _isLoading = false;
        notifyListeners();
        return Success(userCredential.user!);
      }
      _error = 'Login failed. No user returned.';
      _isLoading = false;
      notifyListeners();
      return const Err(Failure('Login failed. No user returned.'));
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthErrorCode(e.code);
      _isLoading = false;
      notifyListeners();
      return Err(Failure(_mapAuthErrorCode(e.code), code: e.code));
    } catch (e) {
      _error = 'An unexpected error occurred.';
      _isLoading = false;
      notifyListeners();
      return Err(Failure('An unexpected error occurred.', exception: e));
    }
  }

  /// Alias for loginWithEmail.
  Future<Result<User>> signInWithEmail(String email, String password) =>
      loginWithEmail(email, password);

  // ─── REGISTRATION LOGIC ───
  Future<Result<User>> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        // 1. Create the base 'users' document in Firestore instantly
        await _db.collection('users').doc(userCredential.user!.uid).set({
          'email': email.trim(),
          'role': 'fan', // Default role until onboarding is complete
          'createdAt': FieldValue.serverTimestamp(),
          'onboardingCompleted': false,
        });

        await _fetchUserModel(userCredential.user!.uid);
        return Success(userCredential.user!);
      }
      return const Err(Failure('Registration failed. No user returned.'));
    } on FirebaseAuthException catch (e) {
      return Err(Failure(_mapAuthErrorCode(e.code), code: e.code));
    } catch (e) {
      return Err(Failure('An unexpected error occurred.', exception: e));
    }
  }

  // ─── LOGOUT LOGIC ───
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _userModel = null;
    notifyListeners();
  }

  /// Alias for logout() for compatibility.
  Future<void> signOut() => logout();

  // ─── INTERNAL DATA SYNC ───
  Future<void> _fetchUserModel(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data();

      // Platform owner always gets a synthetic owner model — no onboarding required.
      if (_isOwnerEmail) {
        final email = _firebaseUser?.email ?? _ownerEmail;
        final existingName = data?['displayName'];
        _userModel = UserModel(
          id: uid,
          email: email,
          displayName: existingName ?? 'DFC Owner',
          role: UserRole.admin,
          createdAt: DateTime(2024),
          updatedAt: DateTime.now(),
        );
        // Ensure Firestore reflects owner role
        await _db.collection('users').doc(uid).set({
          'email': email,
          'role': 'owner',
          'displayName': existingName ?? 'DFC Owner',
          'onboardingCompleted': true,
          'isPlatformOwner': true,
          'isDeveloper': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return;
      }

      if (doc.exists && data != null && data['onboardingCompleted'] == true) {
        _userModel = UserModel(
          id: doc.id,
          email: data['email'] ?? '',
          displayName: data['displayName'] ?? 'Fighter',
          role: UserRole.fromString(data['role'] ?? 'fan'),
          createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
          updatedAt: (data['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
        );
      } else {
        _userModel = null;
      }
    } catch (e) {
      debugPrint('Failed to fetch user model: $e');
      _userModel = null;
    }
  }

  // ─── PASSWORD RESET ──────────────────────────────────────────────────────────
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthErrorCode(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to send reset email. Try again.';
      notifyListeners();
      return false;
    }
  }

  // ─── REFRESH USER PROFILE ────────────────────────────────────────────────────
  /// Re-fetches the user model from Firestore and notifies listeners.
  Future<void> refreshUserProfile() async {
    if (_firebaseUser != null) {
      await _fetchUserModel(_firebaseUser!.uid);
      notifyListeners();
    }
  }

  // ─── ONBOARDING LOGIC ───
  Future<void> completeOnboarding() async {
    if (_firebaseUser == null) return;
    try {
      await _db.collection('users').doc(_firebaseUser!.uid).update({
        'onboardingCompleted': true,
      });
      // Refresh the model to instantly trigger GoRouter to dismiss the onboarding screens
      await refreshUser();
    } catch (e) {
      debugPrint('Failed to complete onboarding: $e');
    }
  }

  // Refresh user model after onboarding is complete
  Future<void> refreshUser() async {
    if (_firebaseUser != null) {
      await _fetchUserModel(_firebaseUser!.uid);
      notifyListeners();
    }
  }

  // ─── ERROR MAPPING ───
  String _mapAuthErrorCode(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The email is already registered.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password provided is too weak.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
