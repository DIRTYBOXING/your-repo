import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import 'media_upload_service.dart';
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

  // UI-facing transient state
  String? _error;
  bool _isLoading = false;
  bool _emergencyLocalSessionActive = false;

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

  // ─── ROLE & ADMIN GETTERS ───
  bool get isAdmin => _userModel?.role == UserRole.admin;
  String get userRole => _userModel?.role.name ?? 'fan';
  String get authDisabledMessage => isAuthTemporarilyDisabled
      ? 'Authentication is temporarily disabled. Please try again later.'
      : '';

  // ─── UI STATE GETTERS ───
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthTemporarilyDisabled => false;
  bool get isOwner => _userModel?.role == UserRole.admin;
  bool get isDemoUser => _emergencyLocalSessionActive;
  static const String demoUserId = 'demo_user';

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
      return const Err(Failure('Login failed. No user returned.'));
    } on FirebaseAuthException catch (e) {
      return Err(Failure(_mapAuthErrorCode(e.code), code: e.code));
    } catch (e) {
      return Err(Failure('An unexpected error occurred.', exception: e));
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
          createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
          updatedAt: (data['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
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

  /// Mark onboarding as completed locally (without server sync).
  /// Useful for offline scenarios or when server write is deferred.
  Future<void> markOnboardingCompletedLocally() async {
    if (_firebaseUser == null) return;
    try {
      // Update local state immediately
      if (_userModel != null) {
        _userModel = UserModel(
          id: _userModel!.id,
          email: _userModel!.email,
          displayName: _userModel!.displayName,
          role: _userModel!.role,
          createdAt: _userModel!.createdAt,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      // Also attempt server write (best effort)
      await _db.collection('users').doc(_firebaseUser!.uid).set({
        'onboardingCompleted': true,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to mark onboarding completed locally: $e');
    }
  }

  // Refresh user model after onboarding is complete
  Future<void> refreshUser() async {
    if (_firebaseUser != null) {
      await _fetchUserModel(_firebaseUser!.uid);
      notifyListeners();
    }
  }

  // ─── UI STATE HELPERS ───
  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  bool shouldUseEmergencyLocalSession() => _emergencyLocalSessionActive;

  void enableEmergencyLocalSession({String? emailHint}) {
    _emergencyLocalSessionActive = true;
    notifyListeners();
  }

  // ─── Password / email management ───
  /// Send a password reset email to the specified address.
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return true;
    } catch (e) {
      debugPrint('Failed to send password reset email: $e');
      _error = e is FirebaseAuthException
          ? _mapAuthErrorCode(e.code)
          : e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseUser;
    if (user == null || user.email == null) return false;
    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      return true;
    } catch (e) {
      debugPrint('Failed to update password: $e');
      return false;
    }
  }

  Future<bool> updateEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final user = _firebaseUser;
    if (user == null || user.email == null) return false;
    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.verifyBeforeUpdateEmail(newEmail);
      return true;
    } catch (e) {
      debugPrint('Failed to update email: $e');
      return false;
    }
  }

  // ─── COMPAT: named sign-in returning the User (or null) ───
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    final result = await loginWithEmail(email, password);
    _isLoading = false;
    if (result is Success<User>) {
      _error = null;
      notifyListeners();
      return result.value;
    }
    final err = (result as Err<User>).error;
    _error = err is Failure ? err.message : err.toString();
    notifyListeners();
    return null;
  }

  // ─── COMPAT: rich profile registration returning the User (or null) ───
  Future<User?> registerWithProfile({
    required String email,
    required String password,
    String? displayName,
    UserRole? role,
    String? sex,
    String? country,
    String? city,
    String? postcode,
    DateTime? dateOfBirth,
  }) async {
    _isLoading = true;
    notifyListeners();
    final result = await registerWithEmail(email, password);
    _isLoading = false;
    if (result is Success<User>) {
      final user = result.value;
      try {
        await _db.collection('users').doc(user.uid).set({
          if (displayName != null) 'displayName': displayName,
          if (role != null) 'role': role.name,
          if (sex != null) 'sex': sex,
          if (country != null) 'country': country,
          if (city != null) 'city': city,
          if (postcode != null) 'postcode': postcode,
          if (dateOfBirth != null)
            'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Failed to persist profile fields: $e');
      }
      _error = null;
      notifyListeners();
      return user;
    }
    final err = (result as Err<User>).error;
    _error = err is Failure ? err.message : err.toString();
    notifyListeners();
    return null;
  }

  // ─── Consent logging ───
  Future<void> recordRequiredConsents({required String version}) async {
    if (_firebaseUser == null) return;
    try {
      await _db.collection('users').doc(_firebaseUser!.uid).set({
        'consents': {
          'version': version,
          'acceptedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to record consents: $e');
    }
  }

  /// Record a specific consent action (e.g., privacy policy acceptance).
  Future<void> recordConsent({
    required Object consentType,
    bool isGranted = true,
    String? version,
  }) async {
    if (_firebaseUser == null) return;
    try {
      final typeKey = consentType is String
          ? consentType
          : consentType.toString();
      await _db.collection('users').doc(_firebaseUser!.uid).set({
        'consents': {
          typeKey: {
            'accepted': isGranted,
            'acceptedAt': FieldValue.serverTimestamp(),
            if (version != null) 'version': version,
          },
        },
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to record consent: $e');
    }
  }

  // ─── Profile metadata ───
  Future<void> updateProfileMetadata(Map<String, dynamic> data) async {
    if (_firebaseUser == null) return;
    try {
      await _db
          .collection('users')
          .doc(_firebaseUser!.uid)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to update profile metadata: $e');
    }
  }

  /// Refresh alias used by profile/onboarding screens.
  Future<void> refreshUserProfile() => refreshUser();

  /// Update core profile fields.
  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? username,
  }) async {
    if (_firebaseUser == null) return;
    try {
      await _db.collection('users').doc(_firebaseUser!.uid).set({
        if (displayName != null) 'displayName': displayName,
        if (bio != null) 'bio': bio,
        if (username != null) 'username': username,
      }, SetOptions(merge: true));
      await refreshUser();
    } catch (e) {
      debugPrint('Failed to update profile: $e');
    }
  }

  /// Update the user's role.
  Future<void> updateUserRole(UserRole role) async {
    if (_firebaseUser == null) return;
    try {
      await _db.collection('users').doc(_firebaseUser!.uid).set({
        'role': role.name,
      }, SetOptions(merge: true));
      await refreshUser();
    } catch (e) {
      debugPrint('Failed to update role: $e');
    }
  }

  /// Pick an image and upload it as the user's profile photo. Returns the URL.
  Future<String?> pickAndUploadProfilePhoto({
    required ImageSource source,
  }) async {
    if (_firebaseUser == null) return null;
    try {
      final picked = await ImagePicker().pickImage(source: source);
      if (picked == null) return null;
      final result = await MediaUploadService().uploadImageFile(
        file: File(picked.path),
        userId: _firebaseUser!.uid,
        type: MediaUploadType.profile,
      );
      if (result.success && result.url != null) {
        await _db.collection('users').doc(_firebaseUser!.uid).set({
          'photoUrl': result.url,
        }, SetOptions(merge: true));
        await refreshUser();
        return result.url;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to upload profile photo: $e');
      return null;
    }
  }

  // ─── Social sign-in ───
  // OAuth providers require configuration in the Firebase console before use.
  // Until configured, these return null with an informative error rather than
  // silently faking a successful session.
  bool get isGoogleSignInConfigured => false;

  Future<User?> signInWithGoogle({UserRole? defaultRole}) async {
    _error = 'Google sign-in is not configured yet.';
    notifyListeners();
    return null;
  }

  Future<User?> signInWithFacebook() async {
    _error = 'Facebook sign-in is not configured yet.';
    notifyListeners();
    return null;
  }

  Future<User?> signInWithApple() async {
    _error = 'Apple sign-in is not configured yet.';
    notifyListeners();
    return null;
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
