/// Content rating & parental controls for combat sport content.
///
/// Enforces age-gated access, content labels, and user-configurable
/// restriction levels. Ratings follow a combat-sports-specific scheme
/// that maps to standard app store classifications (IARC / PEGI / ESRB).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Rating Enums ──────────────────────────────────────────────────────────

/// Content rating levels — loosely mapped to IARC.
enum ContentRating {
  general('G', 'General Audience', 0, 'Suitable for all ages'),
  pg('PG', 'Parental Guidance', 10, 'Mild combat content'),
  teen('T', 'Teen', 13, 'Moderate combat, light blood'),
  mature('M', 'Mature', 16, 'Intense combat, blood, strong language'),
  adult('A', 'Adult Only', 18, 'Extreme violence, graphic injuries');

  final String code;
  final String label;
  final int minAge;
  final String description;
  const ContentRating(this.code, this.label, this.minAge, this.description);
}

/// Content warning tags that can be attached to any event/post/video.
enum ContentTag {
  violence('Violence', '🥊'),
  blood('Blood', '🩸'),
  language('Strong Language', '🤬'),
  injury('Injury Content', '🏥'),
  gambling('Gambling References', '🎰'),
  alcohol('Alcohol Sponsorship', '🍺'),
  knockout('Knockout Footage', '💥'),
  submission('Submission Holds', '🔒');

  final String label;
  final String icon;
  const ContentTag(this.label, this.icon);
}

/// User-selected restriction level.
enum RestrictionLevel {
  off('Off', 'No content restrictions'),
  moderate('Moderate', 'Hide adult-only content'),
  strict('Strict', 'Family-safe — general + PG only');

  final String label;
  final String description;
  const RestrictionLevel(this.label, this.description);
}

// ── Rated Content Model ─────────────────────────────────────────────────

class RatedContent {
  final String contentId;
  final ContentRating rating;
  final Set<ContentTag> tags;

  const RatedContent({
    required this.contentId,
    required this.rating,
    this.tags = const {},
  });

  /// Whether this content is allowed under [level].
  bool isAllowedAt(RestrictionLevel level) {
    switch (level) {
      case RestrictionLevel.off:
        return true;
      case RestrictionLevel.moderate:
        return rating != ContentRating.adult;
      case RestrictionLevel.strict:
        return rating == ContentRating.general || rating == ContentRating.pg;
    }
  }

  /// Default rating for PPV combat events.
  static const ppvDefault = RatedContent(
    contentId: '',
    rating: ContentRating.mature,
    tags: {ContentTag.violence, ContentTag.knockout},
  );

  /// Default for social feed posts.
  static const feedDefault = RatedContent(
    contentId: '',
    rating: ContentRating.pg,
  );
}

// ── Service ─────────────────────────────────────────────────────────────

class ContentRatingService extends ChangeNotifier {
  ContentRatingService._();
  static final ContentRatingService _instance = ContentRatingService._();
  factory ContentRatingService() => _instance;

  final _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> _getPpvEventData(String eventId) async {
    final directDoc = await _firestore
        .collection('ppv_events')
        .doc(eventId)
        .get();
    if (directDoc.exists) {
      return directDoc.data();
    }

    final eventIdSnapshot = await _firestore
        .collection('ppv_events')
        .where('eventId', isEqualTo: eventId)
        .limit(1)
        .get();
    if (eventIdSnapshot.docs.isNotEmpty) {
      return eventIdSnapshot.docs.first.data();
    }

    return null;
  }

  RestrictionLevel _level = RestrictionLevel.off;
  bool _pinRequired = false;
  String _pin = '';
  bool _initialized = false;

  RestrictionLevel get restrictionLevel => _level;
  bool get pinRequired => _pinRequired;
  bool get isInitialized => _initialized;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── Init ──────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final levelIndex = prefs.getInt('content_restriction_level') ?? 0;
    _level = RestrictionLevel.values[levelIndex.clamp(0, 2)];
    _pinRequired = prefs.getBool('content_pin_required') ?? false;
    _pin = prefs.getString('content_pin') ?? '';

    _initialized = true;
    notifyListeners();
  }

  // ── Settings ──────────────────────────────────────────────────────────

  /// Update restriction level. Requires PIN if one is set.
  Future<bool> setRestrictionLevel(
    RestrictionLevel level, {
    String? pin,
  }) async {
    if (_pinRequired && pin != _pin) return false;

    _level = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('content_restriction_level', level.index);

    // Sync to Firestore profile
    final uid = _uid;
    if (uid != null) {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'contentRestrictionLevel': level.name})
          .catchError((_) {});
    }

    notifyListeners();
    return true;
  }

  /// Set or update the parental PIN.
  Future<void> setPin(String newPin) async {
    _pin = newPin;
    _pinRequired = newPin.isNotEmpty;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('content_pin', newPin);
    await prefs.setBool('content_pin_required', _pinRequired);
    notifyListeners();
  }

  /// Verify PIN for access.
  bool verifyPin(String attempt) => !_pinRequired || attempt == _pin;

  // ── Content Filtering ─────────────────────────────────────────────────

  /// Whether [content] should be shown at the current restriction level.
  bool isAllowed(RatedContent content) => content.isAllowedAt(_level);

  /// Filter a list to only allowed content.
  List<T> filterContent<T>(List<T> items, RatedContent Function(T) ratingOf) =>
      items.where((item) => ratingOf(item).isAllowedAt(_level)).toList();

  /// Get the rating for a PPV event from Firestore (or return default).
  Future<RatedContent> getEventRating(String eventId) async {
    final data = await _getPpvEventData(eventId);

    if (data == null || !data.containsKey('contentRating')) {
      return RatedContent.ppvDefault;
    }

    final ratingStr = data['contentRating'] as String? ?? 'mature';
    final tagList = (data['contentTags'] as List<dynamic>?) ?? [];

    final rating = ContentRating.values.firstWhere(
      (r) => r.name == ratingStr,
      orElse: () => ContentRating.mature,
    );

    final tags = tagList
        .map((t) => ContentTag.values.where((ct) => ct.name == t).firstOrNull)
        .whereType<ContentTag>()
        .toSet();

    return RatedContent(contentId: eventId, rating: rating, tags: tags);
  }
}
