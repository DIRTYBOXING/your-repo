import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Analytics service for tracking user behavior and app events
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Log a custom event
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// Set user ID for analytics
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      debugPrint('Analytics error setting user ID: $e');
    }
  }

  /// Set user properties
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Analytics error setting user property: $e');
    }
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      debugPrint('Analytics error logging screen view: $e');
    }
  }

  /// Log user login
  Future<void> logLogin({String? method}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      debugPrint('Analytics error logging login: $e');
    }
  }

  /// Log user sign up
  Future<void> logSignUp({String? method}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method ?? 'email');
    } catch (e) {
      debugPrint('Analytics error logging sign up: $e');
    }
  }

  /// Log content view
  Future<void> logContentView({
    required String contentType,
    required String contentId,
  }) async {
    await logEvent(
      name: 'content_view',
      parameters: {'content_type': contentType, 'content_id': contentId},
    );
  }

  /// Log fighter profile view
  Future<void> logFighterProfileView(String fighterId) async {
    await logEvent(
      name: 'fighter_profile_view',
      parameters: {'fighter_id': fighterId},
    );
  }

  /// Log event view
  Future<void> logEventView(String eventId) async {
    await logEvent(name: 'event_view', parameters: {'event_id': eventId});
  }

  /// Log gym view
  Future<void> logGymView(String gymId) async {
    await logEvent(name: 'gym_view', parameters: {'gym_id': gymId});
  }

  /// Log fight view
  Future<void> logFightView(String fightId) async {
    await logEvent(name: 'fight_view', parameters: {'fight_id': fightId});
  }

  /// Log post creation
  Future<void> logPostCreated({
    required String postId,
    required String authorType,
    bool hasMedia = false,
  }) async {
    await logEvent(
      name: 'post_created',
      parameters: {
        'post_id': postId,
        'author_type': authorType,
        'has_media': hasMedia,
      },
    );
  }

  /// Log post like
  Future<void> logPostLike(String postId) async {
    await logEvent(name: 'post_like', parameters: {'post_id': postId});
  }

  /// Log post share
  Future<void> logPostShare(String postId) async {
    await logEvent(name: 'post_share', parameters: {'post_id': postId});
  }

  /// Log search
  Future<void> logSearch({required String searchTerm, String? category}) async {
    try {
      await _analytics.logSearch(
        searchTerm: searchTerm,
        parameters: category != null ? {'category': category} : null,
      );
    } catch (e) {
      debugPrint('Analytics error logging search: $e');
    }
  }

  /// Log fighter follow
  Future<void> logFighterFollow(String fighterId) async {
    await logEvent(
      name: 'fighter_follow',
      parameters: {'fighter_id': fighterId},
    );
  }

  /// Log gym follow
  Future<void> logGymFollow(String gymId) async {
    await logEvent(name: 'gym_follow', parameters: {'gym_id': gymId});
  }

  /// Log event registration
  Future<void> logEventRegistration(String eventId) async {
    await logEvent(
      name: 'event_registration',
      parameters: {'event_id': eventId},
    );
  }

  /// Log job application
  Future<void> logJobApplication(String jobId) async {
    await logEvent(name: 'job_application', parameters: {'job_id': jobId});
  }

  /// Log role change
  Future<void> logRoleChange({
    required String fromRole,
    required String toRole,
  }) async {
    await logEvent(
      name: 'role_change',
      parameters: {'from_role': fromRole, 'to_role': toRole},
    );
  }

  /// Log fighter stock transaction
  Future<void> logStockTransaction({
    required String fighterId,
    required String type,
    required double quantity,
    required double price,
  }) async {
    await logEvent(
      name: 'stock_transaction',
      parameters: {
        'fighter_id': fighterId,
        'transaction_type': type,
        'quantity': quantity,
        'price': price,
      },
    );
  }

  /// Log news article view
  Future<void> logNewsView(String articleId) async {
    await logEvent(name: 'news_view', parameters: {'article_id': articleId});
  }

  /// Log consent given
  Future<void> logConsentGiven({
    required String consentType,
    required String version,
  }) async {
    await logEvent(
      name: 'consent_given',
      parameters: {'consent_type': consentType, 'version': version},
    );
  }

  /// Log consent revoked
  Future<void> logConsentRevoked({required String consentType}) async {
    await logEvent(
      name: 'consent_revoked',
      parameters: {'consent_type': consentType},
    );
  }

  /// Log data export request
  Future<void> logDataExportRequest() async {
    await logEvent(name: 'data_export_request');
  }

  /// Log data deletion request
  Future<void> logDataDeletionRequest() async {
    await logEvent(name: 'data_deletion_request');
  }

  /// Log error
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? screenName,
  }) async {
    await logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        'screen_name': ?screenName,
      },
    );
  }

  /// Log app open
  Future<void> logAppOpen() async {
    try {
      await _analytics.logAppOpen();
    } catch (e) {
      debugPrint('Analytics error logging app open: $e');
    }
  }

  /// Reset analytics data (for GDPR compliance)
  Future<void> resetAnalyticsData() async {
    try {
      await _analytics.resetAnalyticsData();
    } catch (e) {
      debugPrint('Analytics error resetting data: $e');
    }
  }

  /// Set analytics collection enabled
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(enabled);
    } catch (e) {
      debugPrint('Analytics error setting collection enabled: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // PERFORMANCE TRACES — Custom traces for critical user flows
  // (Firebase Performance replaces Kayo's New Relic setup)
  // ══════════════════════════════════════════════════════════════

  /// Start a named performance trace. Call [Trace.stop()] when done.
  Trace startTrace(String name) {
    final trace = FirebasePerformance.instance.newTrace(name);
    trace.start();
    return trace;
  }

  /// Track a referral link click — fires the [referral_click] custom event.
  Future<void> trackReferralClick({
    required String refCode,
    String? eventId,
    String medium = 'share',
  }) => logEvent(
    name: 'referral_click',
    parameters: <String, Object>{
      'ref': refCode,
      'event_id': eventId ?? '',
      'medium': medium,
    },
  );

  /// Trace PPV purchase flow (checkout → confirmation)
  Future<T> tracePpvPurchase<T>(Future<T> Function() operation) async {
    final trace = startTrace('ppv_purchase');
    try {
      final result = await operation();
      trace.putAttribute('status', 'success');
      return result;
    } catch (e) {
      trace.putAttribute('status', 'error');
      trace.putAttribute(
        'error',
        e.toString().substring(0, e.toString().length.clamp(0, 100)),
      );
      rethrow;
    } finally {
      trace.stop();
    }
  }

  /// Trace feed load (initial + paginated)
  Future<T> traceFeedLoad<T>(
    Future<T> Function() operation, {
    String feedType = 'main',
  }) async {
    final trace = startTrace('feed_load_$feedType');
    try {
      final result = await operation();
      trace.putAttribute('status', 'success');
      return result;
    } catch (e) {
      trace.putAttribute('status', 'error');
      rethrow;
    } finally {
      trace.stop();
    }
  }

  /// Log PPV purchase as Firebase Analytics e-commerce event
  Future<void> logPpvPurchase({
    required String eventId,
    required String eventName,
    required double price,
    String currency = 'USD',
  }) async {
    await logEvent(
      name: 'purchase',
      parameters: {
        'transaction_id': 'ppv_$eventId',
        'value': price,
        'currency': currency,
        'items':
            '[{"item_id":"$eventId","item_name":"$eventName","item_category":"PPV","price":$price}]',
      },
    );
  }
}
