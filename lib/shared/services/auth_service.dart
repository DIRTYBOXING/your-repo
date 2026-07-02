import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';
import 'result.dart';
import 'failure.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// AUTH ENGINE (BLUE TIER)
/// Manages Firebase Sessions, User Models, and Routing State.
/// ═══════════════════════════════════════════════════════════════════════════
class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  User? _firebaseUser;
  UserModel? _userModel;
  bool _isInitialized = false;
  String? _error;
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
  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  String? get error => _error;

  /// True when running without a live Firebase-backed account (guest/demo
  /// sandbox lane), meaning writes should be skipped rather than sent to
  /// Firestore for a session that isn't really persisted.
  bool get isDemoUser =>
      AppConstants.guestMode || !AppConstants.authEnabled || _firebaseUser == null;

  // If the user document doesn't exist or is missing crucial setup info, they need onboarding
  bool get needsOnboarding => isAuthenticated && _userModel == null;

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
        _userModel = UserModel.fromFirestore(doc);
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

  /// Alias used by profile screens to re-sync the cached [userModel] after
  /// an edit, e.g. after [updateProfile]/[updateProfileMetadata] complete.
  Future<void> refreshUserProfile() => refreshUser();

  // ─── PROFILE EDITING ───

  /// Updates core profile fields on the `users` Firestore document.
  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? username,
  }) async {
    if (_firebaseUser == null) return;
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (displayName != null) updates['displayName'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (username != null) updates['username'] = username;

      await _db.collection('users').doc(_firebaseUser!.uid).update(updates);
      await refreshUser();
      _error = null;
    } catch (e) {
      _error = 'Failed to update profile. Please try again.';
      debugPrint('Failed to update profile: $e');
    }
  }

  /// Updates the user's platform role (fighter/coach/gym/promoter/etc).
  Future<void> updateUserRole(UserRole role) async {
    if (_firebaseUser == null) return;
    try {
      await _db.collection('users').doc(_firebaseUser!.uid).update({
        'role': role.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await refreshUser();
      _error = null;
    } catch (e) {
      _error = 'Failed to update role. Please try again.';
      debugPrint('Failed to update user role: $e');
    }
  }

  /// Merges extended profile metadata (location, gym, physical stats) into
  /// the `metadata` map on the user's Firestore document.
  Future<void> updateProfileMetadata(Map<String, dynamic> metadata) async {
    if (_firebaseUser == null) return;
    try {
      final existing = _userModel?.metadata ?? <String, dynamic>{};
      final merged = {...existing, ...metadata};
      await _db.collection('users').doc(_firebaseUser!.uid).update({
        'metadata': merged,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await refreshUser();
      _error = null;
    } catch (e) {
      _error = 'Failed to update profile details. Please try again.';
      debugPrint('Failed to update profile metadata: $e');
    }
  }

  /// Picks a photo from [source], uploads it to Firebase Storage under
  /// `profile_photos/{uid}.jpg`, and stores the resulting URL on the user's
  /// Firestore document. Returns the uploaded URL, or null if the pick was
  /// cancelled or the upload failed (see [error] for the failure message).
  Future<String?> pickAndUploadProfilePhoto({
    required ImageSource source,
  }) async {
    if (_firebaseUser == null) return null;
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked == null) return null;

      final ref = _storage.ref().child(
        'profile_photos/${_firebaseUser!.uid}.jpg',
      );
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();

      await _db.collection('users').doc(_firebaseUser!.uid).update({
        'photoUrl': url,
        'photoURL': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await refreshUser();
      _error = null;
      return url;
    } catch (e) {
      _error = 'Failed to upload photo. Please try again.';
      debugPrint('Failed to upload profile photo: $e');
      return null;
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
