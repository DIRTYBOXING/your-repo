import '../models/event_model.dart';
import '../models/community/community_models.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FEED PRIORITIZATION SERVICE — Paid Subscribers Get Front Row 💎
/// ═══════════════════════════════════════════════════════════════════════════
///
/// 🎯 PRIORITY HIERARCHY (DFC = Pay to Play):
/// 1. Premium Promoters with Events (0-50 points) — MAXIMUM EXPOSURE
/// 2. Subscribers/Premium Users (0-30 points) — Front-row visibility
/// 3. Time Proximity (0-15 points) — Fight day urgency
/// 4. Location Match (0-10 points) — Local discovery
///
/// 💡 Philosophy: Those who pay get maximum reach. Paid promoters with shows
///    ALWAYS lead the feed. Regular users/events get smaller feeds.
///
/// ═══════════════════════════════════════════════════════════════════════════
class FeedPrioritizationService {
  /// Calculate priority score for an event (0.0 - 100.0)
  ///
  /// SCORING MODEL:
  /// • Premium Promoter: 0-50 points (PRIMARY — you pay, you get front row)
  /// • Subscriber Status: 0-30 points (SECONDARY — paying members win)
  /// • Time Proximity: 0-15 points (TERTIARY — urgency factor)
  /// • Location Match: 0-10 points (QUATERNARY — local discovery)
  double calculateEventPriority({
    required EventModel event,
    required DateTime currentTime,
    String? userPostcode,
    String? userCity,
    String? userState,
    String? userCountry,
    bool isSubscriber = false,
    bool isPremiumPromoter = false,
  }) {
    double score = 0.0;

    // ══════════════════════════════════════════════════════════════════════
    // TIER 1: PREMIUM PROMOTER STATUS (0-50 points) — HIGHEST PRIORITY
    // ══════════════════════════════════════════════════════════════════════
    // Paid promoters with upcoming shows get MAXIMUM exposure.
    // This ensures subscribers always lead the feed over free users.
    if (isPremiumPromoter) {
      score += 50.0; // 🏆 Front-row stage time — you pay, you shine
    }

    // ══════════════════════════════════════════════════════════════════════
    // TIER 2: SUBSCRIBER STATUS (0-30 points) — SECONDARY PRIORITY
    // ══════════════════════════════════════════════════════════════════════
    // All paying members (subscribers, premium fighters, etc.) get boosted
    // visibility over free-tier users.
    if (isSubscriber && !isPremiumPromoter) {
      // Subscriber but not premium promoter (avoid double-counting)
      score += 30.0; // 💎 Premium member visibility
    }

    // ══════════════════════════════════════════════════════════════════════
    // TIER 3: TIME PROXIMITY (0-15 points) — TERTIARY FACTOR
    // ══════════════════════════════════════════════════════════════════════
    // Events happening sooner get a boost, but this is now SECONDARY to
    // premium status. A paid event in 2 weeks beats a free event today.
    final timeScore = _calculateTimeProximityScore(
      eventDate: event.eventDate,
      currentTime: currentTime,
    );
    score += timeScore;

    // ══════════════════════════════════════════════════════════════════════
    // TIER 4: LOCATION MATCH (0-10 points) — QUATERNARY FACTOR
    // ══════════════════════════════════════════════════════════════════════
    // Local events get a small boost for discovery, but again, this is
    // TERTIARY — a paid promoter from another state still outranks you.
    final locationScore = _calculateLocationScore(
      eventCity: event.city,
      eventState: event.state,
      eventCountry: event.country,
      userCity: userCity,
      userState: userState,
      userCountry: userCountry,
    );
    score += locationScore;

    return score.clamp(0.0, 100.0);
  }

  /// Calculate time-based priority score (closer events score higher)
  /// REDUCED to 0-15 points — now TERTIARY factor (premium status matters more)
  double _calculateTimeProximityScore({
    required DateTime eventDate,
    required DateTime currentTime,
  }) {
    final daysUntilEvent = eventDate.difference(currentTime).inDays;

    if (daysUntilEvent < 0) {
      // Event passed
      return 0.0;
    } else if (daysUntilEvent == 0) {
      // IT'S FIGHT TIME! Urgency boost
      return 15.0;
    } else if (daysUntilEvent <= 1) {
      // Tomorrow — building hype
      return 13.0;
    } else if (daysUntilEvent <= 3) {
      // This week — moderate urgency
      return 10.0;
    } else if (daysUntilEvent <= 7) {
      // Next 7 days
      return 8.0;
    } else if (daysUntilEvent <= 14) {
      // Next 2 weeks
      return 6.0;
    } else if (daysUntilEvent <= 30) {
      // Within a month
      return 4.0;
    } else if (daysUntilEvent <= 60) {
      // Within two months
      return 2.0;
    } else {
      // Far future
      return 1.0;
    }
  }

  /// Calculate location matching score (closer = higher)
  /// REDUCED to 0-10 points — now QUATERNARY factor (premium matters most)
  double _calculateLocationScore({
    required String eventCity,
    String? eventState,
    required String eventCountry,
    String? userCity,
    String? userState,
    String? userCountry,
  }) {
    double score = 0.0;

    final eventCityLower = eventCity.toLowerCase().trim();
    final eventStateLower = (eventState ?? '').toLowerCase().trim();
    final eventCountryLower = eventCountry.toLowerCase().trim();

    final userCityLower = (userCity ?? '').toLowerCase().trim();
    final userStateLower = (userState ?? '').toLowerCase().trim();
    final userCountryLower = (userCountry ?? '').toLowerCase().trim();

    // ── City Match (10 points) — Local event discovery ──
    if (userCityLower.isNotEmpty && eventCityLower.contains(userCityLower)) {
      return 10.0;
    }

    // ── State/Province Match (7 points) — Regional event ──
    if (userStateLower.isNotEmpty && eventStateLower.contains(userStateLower)) {
      score += 7.0;
    }

    // ── Country Match (4 points) — National event ──
    if (userCountryLower.isNotEmpty &&
        eventCountryLower.contains(userCountryLower)) {
      score += 4.0;
    }

    return score;
  }

  /// Generate AI Buffer-style hype message based on time to event
  String generateHypeMessage({
    required EventModel event,
    required DateTime currentTime,
  }) {
    final daysUntilEvent = event.eventDate.difference(currentTime).inDays;
    final hoursUntilEvent = event.eventDate.difference(currentTime).inHours;

    if (daysUntilEvent < 0) {
      return '📺 Results available';
    } else if (hoursUntilEvent <= 0) {
      return '🔴 LIVE NOW!';
    } else if (hoursUntilEvent <= 6) {
      return '⏰ FIGHT TIME IN ${hoursUntilEvent}H!';
    } else if (daysUntilEvent == 0) {
      return '🚨 IT\'S FIGHT DAY!';
    } else if (daysUntilEvent == 1) {
      return '⚡ TOMORROW NIGHT!';
    } else if (daysUntilEvent <= 3) {
      return '🔥 $daysUntilEvent DAYS TO GO!';
    } else if (daysUntilEvent <= 7) {
      return '📢 FIGHT WEEK!';
    } else if (daysUntilEvent <= 14) {
      return '🥊 2 Weeks Out';
    } else if (daysUntilEvent <= 30) {
      return '📅 Coming Soon';
    } else {
      return '🗓️ Save the Date';
    }
  }

  /// Generate location badge (e.g., "🏠 Local", "📍 Victoria", "🇦🇺 Australia")
  String generateLocationBadge({
    required EventModel event,
    String? userCity,
    String? userState,
    String? userCountry,
  }) {
    final eventCityLower = event.city.toLowerCase().trim();
    final eventStateLower = (event.state ?? '').toLowerCase().trim();
    final eventCountryLower = event.country.toLowerCase().trim();

    final userCityLower = (userCity ?? '').toLowerCase().trim();
    final userStateLower = (userState ?? '').toLowerCase().trim();
    final userCountryLower = (userCountry ?? '').toLowerCase().trim();

    if (userCityLower.isNotEmpty && eventCityLower.contains(userCityLower)) {
      return '🏠 Local Event';
    }

    if (userStateLower.isNotEmpty && eventStateLower.contains(userStateLower)) {
      return '📍 ${event.state}';
    }

    if (userCountryLower.isNotEmpty &&
        eventCountryLower.contains(userCountryLower)) {
      // Map country to flag emoji
      final flag = _countryToFlag(event.country);
      return '$flag ${event.country}';
    }

    return '🌍 ${event.country}';
  }

  /// Sort mixed content feed (events + posts) by priority
  List<dynamic> prioritizeFeed({
    required List<EventModel> events,
    required List<Post> posts,
    required DateTime currentTime,
    String? userPostcode,
    String? userCity,
    String? userState,
    String? userCountry,
    Map<String, bool> subscriberMap = const {},
    Map<String, bool> premiumPromoterMap = const {},
  }) {
    // Score all events
    final scoredEvents = events.map((event) {
      final score = calculateEventPriority(
        event: event,
        currentTime: currentTime,
        userPostcode: userPostcode,
        userCity: userCity,
        userState: userState,
        userCountry: userCountry,
        isSubscriber: subscriberMap[event.promoterId] ?? false,
        isPremiumPromoter: premiumPromoterMap[event.promoterId] ?? false,
      );
      return {'item': event, 'score': score, 'type': 'event'};
    }).toList();

    // Score all posts (simple recency-based for now)
    final scoredPosts = posts.map((post) {
      final ageInHours = currentTime.difference(post.createdAt).inHours;
      final score = 50.0 - (ageInHours * 0.5); // Decay over time
      return {'item': post, 'score': score.clamp(0.0, 50.0), 'type': 'post'};
    }).toList();

    // Combine and sort by score
    final allItems = [...scoredEvents, ...scoredPosts];
    allItems.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );

    // Extract items
    return allItems.map((scored) => scored['item']).toList();
  }

  /// Map country name to flag emoji
  String _countryToFlag(String country) {
    final countryLower = country.toLowerCase().trim();
    if (countryLower.contains('australia')) return '🇦🇺';
    if (countryLower.contains('usa') ||
        countryLower.contains('united states')) {
      return '🇺🇸';
    }
    if (countryLower.contains('uk') ||
        countryLower.contains('united kingdom')) {
      return '🇬🇧';
    }
    if (countryLower.contains('canada')) return '🇨🇦';
    if (countryLower.contains('brazil')) return '🇧🇷';
    if (countryLower.contains('thailand')) return '🇹🇭';
    if (countryLower.contains('japan')) return '🇯🇵';
    if (countryLower.contains('china')) return '🇨🇳';
    if (countryLower.contains('mexico')) return '🇲🇽';
    if (countryLower.contains('ireland')) return '🇮🇪';
    if (countryLower.contains('new zealand')) return '🇳🇿';
    if (countryLower.contains('philippines')) return '🇵🇭';
    return '🌍';
  }

  /// Get urgency level for UI styling (0 = low, 1 = medium, 2 = high, 3 = critical)
  int getUrgencyLevel({
    required EventModel event,
    required DateTime currentTime,
  }) {
    final daysUntilEvent = event.eventDate.difference(currentTime).inDays;

    if (daysUntilEvent < 0) return 0; // Past
    if (daysUntilEvent == 0) return 3; // TODAY - CRITICAL
    if (daysUntilEvent <= 3) return 2; // High urgency
    if (daysUntilEvent <= 7) return 1; // Medium urgency
    return 0; // Low urgency
  }
}
