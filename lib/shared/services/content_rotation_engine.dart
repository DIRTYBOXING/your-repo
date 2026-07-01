import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CONTENT ROTATION ENGINE — 6-Hour Auto-Swap
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Automatically rotates headline articles, featured cards, and event
/// spotlights every 6 hours so the app always feels fresh.
///
/// Rotation windows:
///   Window A  00:00 – 05:59
///   Window B  06:00 – 11:59
///   Window C  12:00 – 17:59
///   Window D  18:00 – 23:59
///
/// Each window selects a different slice of content from the master pool.
/// Within each window, cards shuffle once so every session looks different.
///
/// The engine also enriches content with real event sources —
/// Lumpinee, ONE Championship, UFC, GLORY, BKFC, DFC Promotions,
/// Hex Fight Series, Bellator, PFL, K-1, and regional Australian promotions.
/// ═══════════════════════════════════════════════════════════════════════════

class ContentRotationEngine extends ChangeNotifier {
  ContentRotationEngine._();
  static final ContentRotationEngine _instance = ContentRotationEngine._();
  factory ContentRotationEngine() => _instance;

  Timer? _rotationTimer;
  String _currentWindow = '';
  int _rotationEpoch = 0;
  static const int _windowHours = 6;

  /// Current 6-hour window identifier (e.g. "2026-03-05_A")
  String get currentWindow => _currentWindow;

  /// Increments every time a new window fires
  int get rotationEpoch => _rotationEpoch;

  // ── Public API ──────────────────────────────────────────────────────────

  /// Start the rotation clock. Call once at app boot (e.g. in main.dart).
  void start() {
    _updateWindow();
    _scheduleNextRotation();
  }

  /// Force a rotation now (admin override).
  void forceRotate() {
    _rotationEpoch++;
    _updateWindow();
    notifyListeners();
    debugPrint('[ContentRotation] Force-rotated → window $_currentWindow');
  }

  /// Stop the rotation timer (e.g. on dispose).
  void stop() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
  }

  // ── Window Logic ────────────────────────────────────────────────────────

  void _updateWindow() {
    final now = DateTime.now();
    final windowIndex = now.hour ~/ _windowHours; // 0..3
    final windowLetter = String.fromCharCode('A'.codeUnitAt(0) + windowIndex);
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final newWindow = '${dateStr}_$windowLetter';

    if (newWindow != _currentWindow) {
      _currentWindow = newWindow;
      _rotationEpoch++;
      debugPrint(
        '[ContentRotation] New window: $_currentWindow (epoch $_rotationEpoch)',
      );
    }
  }

  void _scheduleNextRotation() {
    _rotationTimer?.cancel();
    final now = DateTime.now();
    // Next boundary is every 6 hours (00, 06, 12, 18)
    final currentBucket = now.hour ~/ _windowHours;
    final nextHour = (currentBucket + 1) * _windowHours;
    final nextBoundary = nextHour >= 24
        ? DateTime(now.year, now.month, now.day + 1)
        : DateTime(now.year, now.month, now.day, nextHour);
    final delay = nextBoundary.difference(now);

    _rotationTimer = Timer(delay, () {
      _updateWindow();
      notifyListeners();
      _scheduleNextRotation(); // Schedule the one after
    });

    debugPrint('[ContentRotation] Next rotation in ${delay.inMinutes} minutes');
  }

  // ── Content Slicing Helpers ─────────────────────────────────────────────

  /// Given a master list, returns the slice for the current 6-hour window.
  /// Each window gets a different quarter of the pool. Items within the slice
  /// are shuffled deterministically per window so they stay stable within
  /// the same 6-hour period.
  List<T> rotateContent<T>(List<T> masterPool, {int? maxItems}) {
    if (masterPool.isEmpty) return [];

    // Seed based on window string so shuffle is stable within the window
    final seed = _currentWindow.hashCode;
    final rng = math.Random(seed);

    // Split pool into 4 windows via deterministic shuffle
    final shuffled = List<T>.from(masterPool)..shuffle(rng);

    const totalWindows = 24 ~/ _windowHours; // 4
    final chunkSize = (shuffled.length / totalWindows).ceil();
    final suffix = _currentWindow.contains('_')
        ? _currentWindow.split('_').last
        : 'A';
    final windowIndex = (suffix.codeUnitAt(0) - 'A'.codeUnitAt(0)).clamp(
      0,
      totalWindows - 1,
    );
    final start = windowIndex * chunkSize;
    final end = math.min(start + chunkSize, shuffled.length);
    final slice = start < shuffled.length
        ? shuffled.sublist(start, end)
        : <T>[];

    // If the other half is smaller (odd count), combine to avoid empty feeds
    if (slice.isEmpty) return shuffled;

    // Re-shuffle the slice for presentation order
    slice.shuffle(math.Random(seed + 1));

    if (maxItems != null && slice.length > maxItems) {
      return slice.take(maxItems).toList();
    }
    return slice;
  }

  /// Returns a subset of items that should be "featured" this window.
  /// Always returns 3-5 items max for hero cards / top stories.
  List<T> featuredSlice<T>(List<T> pool) {
    return rotateContent(pool, maxItems: 5);
  }

  /// Returns a subset for the secondary feed (scrollable list).
  List<T> feedSlice<T>(List<T> pool, {int max = 20}) {
    return rotateContent(pool, maxItems: max);
  }

  // ── Real Event Sources ──────────────────────────────────────────────────

  /// Master list of real combat sports content sources.
  /// These rotate into the FightWire and news feeds.
  static const List<EventSource> globalEventSources = [
    // ── MUAY THAI ──
    EventSource(
      name: 'Lumpinee Boxing Stadium',
      code: 'LUMPINEE',
      sport: 'Muay Thai',
      region: 'Bangkok, Thailand',
      frequency: 'Weekly (Tuesday & Friday)',
      feedUrl: 'https://www.muaythaiauthority.com',
      tier: SourceTier.legendary,
    ),
    EventSource(
      name: 'Rajadamnern Stadium',
      code: 'RAJA',
      sport: 'Muay Thai',
      region: 'Bangkok, Thailand',
      frequency: 'Weekly (Monday, Wednesday, Thursday, Sunday)',
      feedUrl: 'https://www.rajadamnern.com',
      tier: SourceTier.legendary,
    ),
    EventSource(
      name: 'ONE Championship',
      code: 'ONE',
      sport: 'MMA / Muay Thai / Kickboxing',
      region: 'Global (Singapore HQ)',
      frequency: 'Weekly (Friday Fights + monthly main cards)',
      feedUrl: 'https://www.onefc.com',
      tier: SourceTier.major,
    ),
    EventSource(
      name: 'ONE Samurai',
      code: 'ONE-SAMURAI',
      sport: 'MMA / Muay Thai',
      region: 'Japan (U-NEXT)',
      frequency: 'Monthly',
      feedUrl: 'https://www.onefc.com/samurai',
      tier: SourceTier.major,
    ),

    // ── UFC ──
    EventSource(
      name: 'UFC',
      code: 'UFC',
      sport: 'MMA',
      region: 'Global (Las Vegas HQ)',
      frequency: 'Weekly (Fight Night + PPV)',
      feedUrl: 'https://www.ufc.com',
      tier: SourceTier.major,
    ),
    EventSource(
      name: 'UFC Performance Institute',
      code: 'UFC-PI',
      sport: 'MMA Training',
      region: 'Las Vegas / Shanghai / Brisbane',
      frequency: 'Continuous',
      feedUrl: 'https://www.ufc.com/pi',
      tier: SourceTier.major,
    ),

    // ── BOXING ──
    EventSource(
      name: 'Ring Magazine / RingTV',
      code: 'RING',
      sport: 'Boxing',
      region: 'Global',
      frequency: 'Continuous',
      feedUrl: 'https://www.ringtv.com',
      tier: SourceTier.major,
    ),
    EventSource(
      name: 'BoxingScene',
      code: 'BOXSCENE',
      sport: 'Boxing',
      region: 'Global',
      frequency: 'Daily',
      feedUrl: 'https://www.boxingscene.com',
      tier: SourceTier.major,
    ),
    EventSource(
      name: 'DAZN Boxing',
      code: 'DAZN',
      sport: 'Boxing',
      region: 'Global',
      frequency: 'Weekly',
      feedUrl: 'https://www.dazn.com',
      tier: SourceTier.major,
    ),

    // ── KICKBOXING ──
    EventSource(
      name: 'GLORY Kickboxing',
      code: 'GLORY',
      sport: 'Kickboxing',
      region: 'Global (Netherlands HQ)',
      frequency: 'Monthly',
      feedUrl: 'https://www.glorykickboxing.com',
      tier: SourceTier.major,
    ),
    EventSource(
      name: 'K-1 World Grand Prix',
      code: 'K1',
      sport: 'Kickboxing',
      region: 'Japan / Global',
      frequency: 'Quarterly',
      feedUrl: 'https://www.k-1.co.jp/en/',
      tier: SourceTier.major,
    ),

    // ── MMA PROMOTIONS ──
    EventSource(
      name: 'Bellator MMA',
      code: 'BELLATOR',
      sport: 'MMA',
      region: 'Global',
      frequency: 'Bi-weekly',
      feedUrl: 'https://www.bellator.com',
      tier: SourceTier.major,
    ),
    EventSource(
      name: 'PFL (Professional Fighters League)',
      code: 'PFL',
      sport: 'MMA',
      region: 'Global',
      frequency: 'Season-based + PPV',
      feedUrl: 'https://www.pflmma.com',
      tier: SourceTier.major,
    ),

    // ── BARE KNUCKLE ──
    EventSource(
      name: 'BKFC (Bare Knuckle Fighting Championship)',
      code: 'BKFC',
      sport: 'Bare Knuckle Boxing',
      region: 'USA / Global expansion',
      frequency: 'Monthly',
      feedUrl: 'https://www.bareknuckle.tv',
      tier: SourceTier.major,
    ),

    // ── AUSTRALIAN PROMOTIONS ──
    EventSource(
      name: 'DFC Promotions — Legends Series',
      code: 'ULT-LEGENDS',
      sport: 'Boxing / Kickboxing',
      region: 'Melbourne, Australia',
      frequency: 'Quarterly',
      feedUrl: 'https://www.ultimatepromotions.com.au',
      tier: SourceTier.regional,
    ),
    EventSource(
      name: 'Hex Fight Series',
      code: 'HEX',
      sport: 'MMA',
      region: 'Australia',
      frequency: 'Monthly',
      feedUrl: 'https://www.hexfightseries.com',
      tier: SourceTier.regional,
    ),
    EventSource(
      name: 'Eternal MMA',
      code: 'ETERNAL',
      sport: 'MMA',
      region: 'Australia',
      frequency: 'Monthly',
      feedUrl: 'https://www.eternalmma.com',
      tier: SourceTier.regional,
    ),
    EventSource(
      name: 'Cage Titans (Oceania)',
      code: 'CW-OC',
      sport: 'MMA',
      region: 'Australia / NZ',
      frequency: 'Quarterly',
      feedUrl: 'https://www.cagewarriors.com',
      tier: SourceTier.regional,
    ),
    EventSource(
      name: 'Brace MMA',
      code: 'BRACE',
      sport: 'MMA',
      region: 'Victoria, Australia',
      frequency: 'Monthly',
      feedUrl: 'https://www.bracemma.com.au',
      tier: SourceTier.regional,
    ),
    EventSource(
      name: 'Spartan Fight League',
      code: 'SPARTAN',
      sport: 'MMA / Kickboxing',
      region: 'Queensland, Australia',
      frequency: 'Bi-monthly',
      feedUrl: 'https://www.spartanfightleague.com',
      tier: SourceTier.regional,
    ),
    EventSource(
      name: 'Capital Fight Group',
      code: 'CFG',
      sport: 'MMA / Boxing',
      region: 'Canberra, Australia',
      frequency: 'Quarterly',
      feedUrl: 'https://www.capitalfightgroup.com',
      tier: SourceTier.regional,
    ),
    EventSource(
      name: 'Gray Mercy Gym — DFC Home',
      code: 'GMG',
      sport: 'Boxing / MMA / Muay Thai',
      region: 'Woodridge, QLD, Australia',
      frequency: 'Continuous (training & amateur cards)',
      feedUrl: 'https://datafightcentral.web.app',
      tier: SourceTier.home,
    ),

    // ── MEDIA ──
    EventSource(
      name: 'ESPN MMA',
      code: 'ESPN',
      sport: 'MMA / Boxing',
      region: 'Global',
      frequency: 'Daily',
      feedUrl: 'https://www.espn.com/mma/',
      tier: SourceTier.media,
    ),
    EventSource(
      name: 'MMA Fighting',
      code: 'MMAF',
      sport: 'MMA',
      region: 'Global',
      frequency: 'Daily',
      feedUrl: 'https://www.mmafighting.com',
      tier: SourceTier.media,
    ),
    EventSource(
      name: 'International Kickboxer Magazine',
      code: 'IKM',
      sport: 'Kickboxing / Muay Thai',
      region: 'Australia / Global',
      frequency: 'Monthly issues + daily web',
      feedUrl: 'https://www.internationalkickboxer.com',
      tier: SourceTier.media,
    ),
    EventSource(
      name: 'Sherdog',
      code: 'SHERDOG',
      sport: 'MMA',
      region: 'Global',
      frequency: 'Daily',
      feedUrl: 'https://www.sherdog.com',
      tier: SourceTier.media,
    ),
    EventSource(
      name: 'MMA Junkie',
      code: 'JUNKIE',
      sport: 'MMA',
      region: 'Global',
      frequency: 'Daily',
      feedUrl: 'https://mmajunkie.usatoday.com',
      tier: SourceTier.media,
    ),
    EventSource(
      name: 'The Fight Site',
      code: 'TFS',
      sport: 'MMA / Boxing',
      region: 'Global',
      frequency: 'Weekly analysis',
      feedUrl: 'https://www.thefightsite.com',
      tier: SourceTier.media,
    ),

    // ── GOVERNING BODIES ──
    EventSource(
      name: 'WBC (World Boxing Council)',
      code: 'WBC',
      sport: 'Boxing',
      region: 'Global',
      frequency: 'Monthly rankings + events',
      feedUrl: 'https://www.wbcboxing.com',
      tier: SourceTier.governing,
    ),
    EventSource(
      name: 'IBF (International Boxing Federation)',
      code: 'IBF',
      sport: 'Boxing',
      region: 'Global',
      frequency: 'Monthly rankings',
      feedUrl: 'https://www.ibf-usba-boxing.com',
      tier: SourceTier.governing,
    ),
    EventSource(
      name: 'WBA (World Boxing Association)',
      code: 'WBA',
      sport: 'Boxing',
      region: 'Global',
      frequency: 'Monthly rankings',
      feedUrl: 'https://www.wbaboxing.com',
      tier: SourceTier.governing,
    ),
    EventSource(
      name: 'WBO (World Boxing Organization)',
      code: 'WBO',
      sport: 'Boxing',
      region: 'Global',
      frequency: 'Monthly rankings',
      feedUrl: 'https://www.wboboxing.com',
      tier: SourceTier.governing,
    ),
    EventSource(
      name: 'Australian Combat Sports Commission',
      code: 'ACSC',
      sport: 'All combat sports',
      region: 'Australia',
      frequency: 'Quarterly updates',
      feedUrl: 'https://www.sportintegrity.gov.au',
      tier: SourceTier.governing,
    ),
  ];

  /// Get sources filtered by tier
  List<EventSource> sourcesByTier(SourceTier tier) =>
      globalEventSources.where((s) => s.tier == tier).toList();

  /// Get sources filtered by sport keyword
  List<EventSource> sourcesBySport(String sport) => globalEventSources
      .where((s) => s.sport.toLowerCase().contains(sport.toLowerCase()))
      .toList();

  /// Get Australian regional promotions
  List<EventSource> get australianSources => globalEventSources
      .where(
        (s) =>
            s.region.toLowerCase().contains('australia') ||
            s.tier == SourceTier.home,
      )
      .toList();
}

// ── Models ────────────────────────────────────────────────────────────────

enum SourceTier {
  legendary, // Lumpinee, Rajadamnern
  major, // UFC, ONE, GLORY, Bellator, PFL, BKFC
  regional, // Hex, Eternal, DFC Promotions
  home, // Gray Mercy Gym / DFC
  media, // ESPN, MMA Fighting, Ring Magazine
  governing, // WBC, IBF, WBA, WBO, ACSC
}

class EventSource {
  final String name;
  final String code;
  final String sport;
  final String region;
  final String frequency;
  final String feedUrl;
  final SourceTier tier;

  const EventSource({
    required this.name,
    required this.code,
    required this.sport,
    required this.region,
    required this.frequency,
    required this.feedUrl,
    required this.tier,
  });
}
