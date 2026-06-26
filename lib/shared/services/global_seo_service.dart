/// GlobalSeoService — auto-generates SEO metadata (title, description, OpenGraph, keywords)
/// for fighter, gym, and event pages. Wire to HTML head injection via web interop.
class GlobalSeoService {
  static final GlobalSeoService _instance = GlobalSeoService._internal();
  factory GlobalSeoService() => _instance;
  GlobalSeoService._internal();

  static const String _siteName = 'Data Fight Central';
  static const String _baseUrl = 'https://datafightcentral.com';
  static const String _defaultImage =
      'https://datafightcentral.com/assets/og-default.jpg';

  // ── Fighter pages ──────────────────────────────────────────────────────────

  SeoMeta forFighter({
    required String name,
    required String weightClass,
    required String sport,
    required int wins,
    required int losses,
    String? countryCode,
    String? imageUrl,
    String? fighterId,
  }) {
    final record = '$wins-$losses';
    final country = countryCode != null ? ' · $countryCode' : '';
    return SeoMeta(
      title: '$name — $sport $weightClass Fighter$country | $_siteName',
      description:
          '$name is a $sport $weightClass competitor with a $record record$country. '
          'Track their rankings, highlights, and upcoming fights on $_siteName.',
      keywords: [
        name,
        sport,
        weightClass,
        'fighter',
        'MMA',
        'boxing',
        'combat sports',
        _siteName,
        ?countryCode,
      ],
      ogTitle: '$name ($record) — $_siteName',
      ogDescription: '$sport $weightClass · $record record$country',
      ogImage: imageUrl ?? _defaultImage,
      canonicalUrl: fighterId != null
          ? '$_baseUrl/fighters/$fighterId'
          : '$_baseUrl/fighters',
    );
  }

  // ── Gym pages ──────────────────────────────────────────────────────────────

  SeoMeta forGym({
    required String gymName,
    required String city,
    required String country,
    List<String> sports = const [],
    String? gymId,
    String? imageUrl,
  }) {
    final sportsStr = sports.isNotEmpty ? sports.join(', ') : 'combat sports';
    return SeoMeta(
      title: '$gymName — $sportsStr Gym in $city, $country | $_siteName',
      description:
          '$gymName is a $sportsStr training facility in $city, $country. '
          'Find coaches, fighters, and events at $_siteName.',
      keywords: [
        gymName,
        city,
        country,
        'gym',
        'training',
        ...sports,
        _siteName,
      ],
      ogTitle: '$gymName — $_siteName',
      ogDescription: '$sportsStr · $city, $country',
      ogImage: imageUrl ?? _defaultImage,
      canonicalUrl: gymId != null ? '$_baseUrl/gyms/$gymId' : '$_baseUrl/gyms',
    );
  }

  // ── Event pages ────────────────────────────────────────────────────────────

  SeoMeta forEvent({
    required String eventName,
    required String promoter,
    required DateTime date,
    required String location,
    String? eventId,
    String? posterUrl,
    List<String> headliners = const [],
  }) {
    final dateStr = '${date.day}/${date.month}/${date.year}';
    final headlineStr = headliners.isNotEmpty
        ? ' — Featuring ${headliners.take(2).join(' vs ')}'
        : '';
    return SeoMeta(
      title: '$eventName — $dateStr | $_siteName',
      description:
          '$promoter presents $eventName on $dateStr in $location$headlineStr. '
          'Full card, tickets, and PPV on $_siteName.',
      keywords: [
        eventName,
        promoter,
        location,
        'fight card',
        'PPV',
        'combat sports event',
        ...headliners,
        _siteName,
      ],
      ogTitle: '$eventName | $_siteName',
      ogDescription: '$promoter · $dateStr · $location',
      ogImage: posterUrl ?? _defaultImage,
      canonicalUrl: eventId != null
          ? '$_baseUrl/events/$eventId'
          : '$_baseUrl/events',
    );
  }

  // ── Generic page ───────────────────────────────────────────────────────────

  SeoMeta defaults() => const SeoMeta(
    title: 'Data Fight Central — Global Combat Sports Platform',
    description:
        'The world\'s most powerful combat sports platform. '
        'Find fighters, gyms, events, and live PPV — globally.',
    keywords: [
      'combat sports',
      'MMA',
      'boxing',
      'BKFC',
      'bare knuckle',
      'muay thai',
      'fighters',
      'gyms',
      'events',
      'PPV',
      'Data Fight Central',
    ],
    ogTitle: 'Data Fight Central',
    ogDescription: 'Global Combat Sports OS',
    ogImage: _defaultImage,
    canonicalUrl: _baseUrl,
  );
}

/// Immutable SEO metadata bundle. Inject into HTML `<head>` via web interop.
class SeoMeta {
  final String title;
  final String description;
  final List<String> keywords;
  final String ogTitle;
  final String ogDescription;
  final String ogImage;
  final String canonicalUrl;

  const SeoMeta({
    required this.title,
    required this.description,
    required this.keywords,
    required this.ogTitle,
    required this.ogDescription,
    required this.ogImage,
    required this.canonicalUrl,
  });

  String get keywordsString => keywords.join(', ');
}
