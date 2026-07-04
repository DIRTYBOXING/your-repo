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
  StreamSubscription<User?>? _authStateSub;

  AuthService() {
    _init();
  }

  void _init() {
    // Listen to Firebase Auth state changes automatically
    _authStateSub = _firebaseAuth.authStateChanges().listen((User? user) async {
      _firebaseUser = user;
      if (user != null) {
        await _fetchUserModel(user.uid);
      } else {
        _userModel = null;
      }
      _isInitialized = true;
      notifyListeners(); // This triggers GoRouter to re-evaluate redirects
    });
  }

  @override
  void dispose() {
    _authStateSub?.cancel();
    super.dispose();
  }

  // ─── STATE GETTERS ───
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _firebaseUser != null;
  User? get currentUser => _firebaseUser;
  UserModel? get userModel => _userModel;

  // If the user document doesn't exist or is missing crucial setup info, they need onboarding
  bool get needsOnboarding => isAuthenticated && _userModel == null;

  bool get isEmergencyLocalSession => AppConstants.guestMode;

  // ─── LOGIN LOGIC ───
  Future<Result<User>> loginWithEmail(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        await _fetchUserModel(userCredential.user!.uid);
        return Success(userCredential.user!);
      }
      return const Error(Failure('Login failed. No user returned.'));
    } on FirebaseAuthException catch (e) {
      return Error(Failure(_mapAuthErrorCode(e.code), code: e.code));
    } catch (e) {
      return Error(Failure('An unexpected error occurred.', exception: e));
    }
  }

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
      return const Error(Failure('Registration failed. No user returned.'));
    } on FirebaseAuthException catch (e) {
      return Error(Failure(_mapAuthErrorCode(e.code), code: e.code));
    } catch (e) {
      return Error(Failure('An unexpected error occurred.', exception: e));
    }
  }

  // ─── LOGOUT LOGIC ───
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _userModel = null;
    notifyListeners();
  }

  // ─── INTERNAL DATA SYNC ───
  Future<void> _fetchUserModel(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data();

      // Only populate _userModel if onboarding is complete, maintaining your router logic
      if (doc.exists && data != null && data['onboardingCompleted'] == true) {
        // Assuming UserModel has a fromMap or fromFirestore factory
        // _userModel = UserModel.fromMap(data, doc.id);

        // Fallback stub until UserModel is finalized
        _userModel = UserModel(
          id: doc.id,
          email: data['email'] ?? '',
          displayName: data['displayName'] ?? 'Fighter',
          role: UserRole.fromString(data['role'] ?? 'fan'),
        );
      } else {
        _userModel = null; // Needs onboarding
      }
    } catch (e) {
      debugPrint('Failed to fetch user model: $e');
      _userModel = null;
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
