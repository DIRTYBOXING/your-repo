import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/user_settings_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// User Settings Service — Firestore-backed account preferences
/// Mirrors Facebook/Instagram settings: notifications, privacy, security
/// Collection: user_settings/{userId}
/// ═══════════════════════════════════════════════════════════════════════════
class UserSettingsService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'user_settings';

  UserSettingsModel? _settings;
  UserSettingsModel? get settings => _settings;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  StreamSubscription<DocumentSnapshot>? _subscription;

  // ═══════════════════════════════════════════════════════════════════════
  //  LOAD & STREAM
  // ═══════════════════════════════════════════════════════════════════════

  /// Load settings for a user. Creates defaults if none exist.
  Future<void> loadSettings(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final doc = await _db.collection(_collection).doc(userId).get();

      if (doc.exists) {
        _settings = UserSettingsModel.fromFirestore(doc);
      } else {
        // First time — create default settings
        _settings = UserSettingsModel(
          userId: userId,
          updatedAt: DateTime.now(),
        );
        await _db.collection(_collection).doc(userId).set(
          _settings!.toFirestore(),
        );
      }

      // Start real-time sync
      _startListening(userId);
    } catch (e) {
      _error = 'Failed to load settings: $e';
      debugPrint('UserSettingsService: $_error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _startListening(String userId) {
    _subscription?.cancel();
    _subscription = _db
        .collection(_collection)
        .doc(userId)
        .snapshots()
        .listen(
          (doc) {
            if (doc.exists) {
              _settings = UserSettingsModel.fromFirestore(doc);
              notifyListeners();
            }
          },
          onError: (e) {
            debugPrint('UserSettingsService: stream error $e');
          },
        );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  NOTIFICATION PREFERENCES
  // ═══════════════════════════════════════════════════════════════════════

  Future<bool> updateNotificationPreferences(
    NotificationPreferences prefs,
  ) async {
    if (_settings == null) return false;
    try {
      _settings = _settings!.copyWith(notifications: prefs);
      await _db.collection(_collection).doc(_settings!.userId).update({
        'notifications': prefs.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update notifications: $e';
      debugPrint('UserSettingsService: $_error');
      return false;
    }
  }

  /// Toggle a single notification preference by key name
  Future<bool> toggleNotification(String key, bool value) async {
    if (_settings == null) return false;
    final current = _settings!.notifications;
    late NotificationPreferences updated;

    switch (key) {
      case 'pushEnabled':
        updated = current.copyWith(pushEnabled: value);
      case 'fightAlerts':
        updated = current.copyWith(fightAlerts: value);
      case 'trainingReminders':
        updated = current.copyWith(trainingReminders: value);
      case 'socialMentions':
        updated = current.copyWith(socialMentions: value);
      case 'campaignWins':
        updated = current.copyWith(campaignWins: value);
      case 'marketplace':
        updated = current.copyWith(marketplace: value);
      case 'weightReminders':
        updated = current.copyWith(weightReminders: value);
      case 'coachMessages':
        updated = current.copyWith(coachMessages: value);
      case 'aiTips':
        updated = current.copyWith(aiTips: value);
      case 'fightWire':
        updated = current.copyWith(fightWire: value);
      case 'achievements':
        updated = current.copyWith(achievements: value);
      case 'promotions':
        updated = current.copyWith(promotions: value);
      case 'community':
        updated = current.copyWith(community: value);
      case 'emailNotifications':
        updated = current.copyWith(emailNotifications: value);
      default:
        return false;
    }
    return updateNotificationPreferences(updated);
  }

  /// Update quiet hours
  Future<bool> updateQuietHours({
    required bool enabled,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) async {
    if (_settings == null) return false;
    return updateNotificationPreferences(
      _settings!.notifications.copyWith(
        quietHoursEnabled: enabled,
        quietStartHour: startHour,
        quietStartMinute: startMinute,
        quietEndHour: endHour,
        quietEndMinute: endMinute,
      ),
    );
  }

  /// Update email digest frequency
  Future<bool> updateEmailDigest(String frequency) async {
    if (_settings == null) return false;
    return updateNotificationPreferences(
      _settings!.notifications.copyWith(emailDigest: frequency),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  PRIVACY SETTINGS
  // ═══════════════════════════════════════════════════════════════════════

  Future<bool> updatePrivacySettings(PrivacySettings prefs) async {
    if (_settings == null) return false;
    try {
      _settings = _settings!.copyWith(privacy: prefs);
      await _db.collection(_collection).doc(_settings!.userId).update({
        'privacy': prefs.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update privacy: $e';
      debugPrint('UserSettingsService: $_error');
      return false;
    }
  }

  /// Toggle a single privacy setting by key name
  Future<bool> togglePrivacy(String key, bool value) async {
    if (_settings == null) return false;
    final current = _settings!.privacy;
    late PrivacySettings updated;

    switch (key) {
      case 'showOnlineStatus':
        updated = current.copyWith(showOnlineStatus: value);
      case 'allowFriendRequests':
        updated = current.copyWith(allowFriendRequests: value);
      case 'allowMessagesFromStrangers':
        updated = current.copyWith(allowMessagesFromStrangers: value);
      case 'showInSearchResults':
        updated = current.copyWith(showInSearchResults: value);
      case 'showFightRecord':
        updated = current.copyWith(showFightRecord: value);
      case 'allowTagging':
        updated = current.copyWith(allowTagging: value);
      case 'showLocation':
        updated = current.copyWith(showLocation: value);
      case 'shareTrainingData':
        updated = current.copyWith(shareTrainingData: value);
      default:
        return false;
    }
    return updatePrivacySettings(updated);
  }

  /// Update profile visibility: 'public', 'friends', 'private'
  Future<bool> setProfileVisibility(String visibility) async {
    if (_settings == null) return false;
    return updatePrivacySettings(
      _settings!.privacy.copyWith(profileVisibility: visibility),
    );
  }

  /// Update activity visibility: 'public', 'friends', 'private'
  Future<bool> setActivityVisibility(String visibility) async {
    if (_settings == null) return false;
    return updatePrivacySettings(
      _settings!.privacy.copyWith(activityVisibility: visibility),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  SECURITY SETTINGS
  // ═══════════════════════════════════════════════════════════════════════

  Future<bool> updateSecuritySettings(SecuritySettings prefs) async {
    if (_settings == null) return false;
    try {
      _settings = _settings!.copyWith(security: prefs);
      await _db.collection(_collection).doc(_settings!.userId).update({
        'security': prefs.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update security: $e';
      debugPrint('UserSettingsService: $_error');
      return false;
    }
  }

  /// Set recovery email
  Future<bool> setRecoveryEmail(String email) async {
    if (_settings == null) return false;
    return updateSecuritySettings(
      _settings!.security.copyWith(recoveryEmail: email),
    );
  }

  /// Set recovery phone
  Future<bool> setRecoveryPhone(String phone) async {
    if (_settings == null) return false;
    return updateSecuritySettings(
      _settings!.security.copyWith(recoveryPhone: phone),
    );
  }

  /// Toggle login alerts
  Future<bool> setLoginAlerts(bool enabled) async {
    if (_settings == null) return false;
    return updateSecuritySettings(
      _settings!.security.copyWith(loginAlertsEnabled: enabled),
    );
  }

  /// Add trusted device
  Future<bool> addTrustedDevice(String deviceId) async {
    if (_settings == null) return false;
    final devices = List<String>.from(_settings!.security.trustedDevices);
    if (devices.contains(deviceId)) return true;
    devices.add(deviceId);
    return updateSecuritySettings(
      _settings!.security.copyWith(trustedDevices: devices),
    );
  }

  /// Remove trusted device
  Future<bool> removeTrustedDevice(String deviceId) async {
    if (_settings == null) return false;
    final devices = List<String>.from(_settings!.security.trustedDevices)
      ..remove(deviceId);
    return updateSecuritySettings(
      _settings!.security.copyWith(trustedDevices: devices),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  GENERAL SETTINGS
  // ═══════════════════════════════════════════════════════════════════════

  /// Set content mode: 'family' or '18plus'
  Future<bool> setContentMode(String mode) async {
    if (_settings == null) return false;
    try {
      _settings = _settings!.copyWith(contentMode: mode);
      await _db.collection(_collection).doc(_settings!.userId).update({
        'contentMode': mode,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update content mode: $e';
      return false;
    }
  }

  /// Set language
  Future<bool> setLanguage(String language) async {
    if (_settings == null) return false;
    try {
      _settings = _settings!.copyWith(language: language);
      await _db.collection(_collection).doc(_settings!.userId).update({
        'language': language,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update language: $e';
      return false;
    }
  }

  /// Set timezone
  Future<bool> setTimezone(String timezone) async {
    if (_settings == null) return false;
    try {
      _settings = _settings!.copyWith(timezone: timezone);
      await _db.collection(_collection).doc(_settings!.userId).update({
        'timezone': timezone,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update timezone: $e';
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  CLEANUP
  // ═══════════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
