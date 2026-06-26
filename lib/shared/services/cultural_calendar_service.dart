import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/world_cultures_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CULTURAL CALENDAR SERVICE — Global Holiday & Tradition Awareness
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Powers:
///   - Greetings for upcoming cultural/religious events
///   - Event scheduling conflict detection (holy days)
///   - Fasting period awareness for training adjustments
///   - Martial arts tradition data by region
///   - User cultural preference management

final _firestore = FirebaseFirestore.instance;

class CulturalCalendarService with ChangeNotifier {
  static final CulturalCalendarService _instance =
      CulturalCalendarService._internal();
  factory CulturalCalendarService() => _instance;
  CulturalCalendarService._internal();

  bool _initialized = false;
  UserCulturalPreferences? _userPrefs;

  bool get initialized => _initialized;
  UserCulturalPreferences? get userPrefs => _userPrefs;

  Future<void> initialize(String? userId) async {
    if (_initialized) return;
    if (userId != null) {
      await _loadUserPreferences(userId);
    }
    _initialized = true;
    notifyListeners();
  }

  // ── User Preferences ────────────────────────────────────────────────────

  Future<void> _loadUserPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection('user_cultural_prefs')
          .doc(userId)
          .get();
      if (doc.exists) {
        _userPrefs = UserCulturalPreferences.fromMap(doc.data()!, userId);
      }
    } catch (e) {
      debugPrint('CulturalCalendarService: load prefs failed: $e');
    }
  }

  Future<void> saveUserPreferences(UserCulturalPreferences prefs) async {
    try {
      await _firestore
          .collection('user_cultural_prefs')
          .doc(prefs.userId)
          .set(prefs.toMap());
      _userPrefs = prefs;
      notifyListeners();
    } catch (e) {
      debugPrint('CulturalCalendarService: save prefs failed: $e');
    }
  }

  // ── Cultural Events / Holy Days ─────────────────────────────────────────

  /// Get events happening this month (or a specific month)
  List<CulturalEvent> getEventsForMonth(
    int month, {
    WorldRegion? region,
    WorldReligion? religion,
  }) {
    var events = _allCulturalEvents.where((e) => e.month == month);
    if (region != null) {
      events = events.where((e) => e.regions.contains(region));
    }
    if (religion != null) {
      events = events.where((e) => e.religions.contains(religion));
    }
    return events.toList();
  }

  /// Get upcoming events (current month + next month)
  List<CulturalEvent> getUpcomingEvents() {
    final now = DateTime.now();
    final thisMonth = getEventsForMonth(now.month);
    final nextMonth = getEventsForMonth((now.month % 12) + 1);
    return [...thisMonth, ...nextMonth];
  }

  /// Get events relevant to a specific user's preferences
  List<CulturalEvent> getPersonalizedEvents() {
    if (_userPrefs == null) return getUpcomingEvents();
    final now = DateTime.now();
    return _allCulturalEvents.where((e) {
      if (e.month != now.month && e.month != (now.month % 12) + 1) return false;
      // Show if matches user's religion or region
      if (_userPrefs!.religion != null &&
          e.religions.contains(_userPrefs!.religion)) {
        return true;
      }
      if (_userPrefs!.homeRegion != null &&
          e.regions.contains(_userPrefs!.homeRegion)) {
        return true;
      }
      // Show major global events to everyone
      if (e.regions.length >= 3) return true;
      return false;
    }).toList();
  }

  /// Check if a date conflicts with a major cultural/religious event
  bool hasSchedulingConflict(DateTime date) {
    return _allCulturalEvents.any(
      (e) =>
          e.eventSchedulingSensitive &&
          e.month == date.month &&
          (e.day == null || e.day == date.day),
    );
  }

  /// Get active fasting periods for the current month
  List<CulturalEvent> getActiveFastingPeriods() {
    final now = DateTime.now();
    return _allCulturalEvents
        .where((e) => e.fasting && e.month == now.month)
        .toList();
  }

  /// Get greeting text for a cultural event (if any active today)
  String? getActiveGreeting() {
    final now = DateTime.now();
    final todayEvents = _allCulturalEvents.where((e) {
      if (e.greeting == null) return false;
      if (e.month != now.month) return false;
      if (e.day != null && e.day != now.day) return false;
      // For user-personalized greetings
      if (_userPrefs?.religion != null) {
        return e.religions.contains(_userPrefs!.religion);
      }
      return e.regions.length >= 3; // Only show global greetings to everyone
    });
    return todayEvents.isNotEmpty ? todayEvents.first.greeting : null;
  }

  // ── Martial Arts Traditions ─────────────────────────────────────────────

  List<MartialArtsTradition> getTraditionsByRegion(WorldRegion region) {
    return _allMartialArtsTraditions.where((t) => t.region == region).toList();
  }

  List<MartialArtsTradition> get allTraditions => _allMartialArtsTraditions;

  MartialArtsTradition? getTraditionById(String id) {
    try {
      return _allMartialArtsTraditions.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SEED DATA — World Cultural Events & Holy Days
// ═══════════════════════════════════════════════════════════════════════════════

const _allCulturalEvents = <CulturalEvent>[
  // ── Islam ────────────────────────────────────────────────────────────────
  CulturalEvent(
    id: 'ramadan',
    name: 'Ramadan',
    description:
        'Holy month of fasting, reflection, and community. Muslims fast from dawn to sunset.',
    type: CulturalEventType.fastingPeriod,
    religions: [WorldReligion.islam],
    regions: [
      WorldRegion.middleEast,
      WorldRegion.southAsia,
      WorldRegion.southeastAsia,
      WorldRegion.northAfrica,
      WorldRegion.westAfrica,
      WorldRegion.eastAfrica,
    ],
    month: 3, // Approximate — shifts yearly on Islamic lunar calendar
    isLunarCalendar: true,
    durationDays: 30,
    greeting: 'Ramadan Mubarak 🌙',
    fasting: true,
    eventSchedulingSensitive: true,
  ),
  CulturalEvent(
    id: 'eid_al_fitr',
    name: 'Eid al-Fitr',
    description:
        'Festival of Breaking the Fast. Celebration marking the end of Ramadan.',
    type: CulturalEventType.religiousHoliday,
    religions: [WorldReligion.islam],
    regions: [
      WorldRegion.middleEast,
      WorldRegion.southAsia,
      WorldRegion.southeastAsia,
      WorldRegion.northAfrica,
      WorldRegion.westAfrica,
    ],
    month: 4,
    isLunarCalendar: true,
    durationDays: 3,
    greeting: 'Eid Mubarak! ✨🌙',
    eventSchedulingSensitive: true,
  ),
  CulturalEvent(
    id: 'eid_al_adha',
    name: 'Eid al-Adha',
    description:
        'Festival of Sacrifice. One of the holiest celebrations in Islam.',
    type: CulturalEventType.religiousHoliday,
    religions: [WorldReligion.islam],
    regions: [
      WorldRegion.middleEast,
      WorldRegion.southAsia,
      WorldRegion.northAfrica,
      WorldRegion.westAfrica,
    ],
    month: 6,
    isLunarCalendar: true,
    durationDays: 4,
    greeting: 'Eid Mubarak! 🐑✨',
    eventSchedulingSensitive: true,
  ),

  // ── Christianity ────────────────────────────────────────────────────────
  CulturalEvent(
    id: 'christmas',
    name: 'Christmas',
    description:
        'Celebration of the birth of Jesus Christ. Major global holiday.',
    type: CulturalEventType.religiousHoliday,
    religions: [WorldReligion.christianity],
    regions: [
      WorldRegion.northAmerica,
      WorldRegion.southAmerica,
      WorldRegion.westernEurope,
      WorldRegion.easternEurope,
      WorldRegion.oceania,
      WorldRegion.southernAfrica,
      WorldRegion.pacific,
    ],
    month: 12,
    day: 25,
    greeting: 'Merry Christmas! 🎄',
    eventSchedulingSensitive: true,
  ),
  CulturalEvent(
    id: 'easter',
    name: 'Easter',
    description: 'Celebration of the resurrection of Jesus Christ.',
    type: CulturalEventType.religiousHoliday,
    religions: [WorldReligion.christianity],
    regions: [
      WorldRegion.northAmerica,
      WorldRegion.southAmerica,
      WorldRegion.westernEurope,
      WorldRegion.easternEurope,
      WorldRegion.oceania,
    ],
    month: 4,
    isLunarCalendar: true,
    greeting: 'Happy Easter! 🐣',
    eventSchedulingSensitive: true,
  ),
  CulturalEvent(
    id: 'orthodox_christmas',
    name: 'Orthodox Christmas',
    description: 'Christmas celebrated by Orthodox Christians on January 7.',
    type: CulturalEventType.religiousHoliday,
    religions: [WorldReligion.christianity],
    regions: [WorldRegion.easternEurope],
    countries: ['RU', 'UA', 'GE', 'ET', 'RS', 'EG'],
    month: 1,
    day: 7,
    greeting: 'Merry Orthodox Christmas! ✝️',
  ),

  // ── Hinduism ────────────────────────────────────────────────────────────
  CulturalEvent(
    id: 'diwali',
    name: 'Diwali',
    description:
        'Festival of Lights. Celebrates the triumph of light over darkness.',
    type: CulturalEventType.religiousHoliday,
    religions: [
      WorldReligion.hinduism,
      WorldReligion.sikhism,
      WorldReligion.jainism,
    ],
    regions: [WorldRegion.southAsia, WorldRegion.southeastAsia],
    month: 10,
    isLunarCalendar: true,
    durationDays: 5,
    greeting: 'Happy Diwali! 🪔✨',
    eventSchedulingSensitive: true,
  ),
  CulturalEvent(
    id: 'holi',
    name: 'Holi',
    description:
        'Festival of Colors. Celebrates the arrival of spring and love.',
    type: CulturalEventType.culturalFestival,
    religions: [WorldReligion.hinduism],
    regions: [WorldRegion.southAsia],
    month: 3,
    isLunarCalendar: true,
    greeting: 'Happy Holi! 🎨',
  ),
  CulturalEvent(
    id: 'navratri',
    name: 'Navratri',
    description: 'Nine Nights festival honouring the divine feminine.',
    type: CulturalEventType.religiousHoliday,
    religions: [WorldReligion.hinduism],
    regions: [WorldRegion.southAsia],
    month: 10,
    isLunarCalendar: true,
    durationDays: 9,
    fasting: true,
  ),

  // ── Buddhism ────────────────────────────────────────────────────────────
  CulturalEvent(
    id: 'vesak',
    name: 'Vesak (Buddha Day)',
    description: 'Celebrates the birth, enlightenment, and death of Buddha.',
    type: CulturalEventType.religiousHoliday,
    religions: [WorldReligion.buddhism],
    regions: [
      WorldRegion.southAsia,
      WorldRegion.southeastAsia,
      WorldRegion.eastAsia,
    ],
    month: 5,
    isLunarCalendar: true,
    greeting: 'Happy Vesak! ☸️',
    eventSchedulingSensitive: true,
  ),
  CulturalEvent(
    id: 'songkran',
    name: 'Songkran (Thai New Year)',
    description:
        'Thai New Year water festival. Major celebration in Thailand and southeast Asia.',
    type: CulturalEventType.culturalFestival,
    religions: [WorldReligion.buddhism],
    regions: [WorldRegion.southeastAsia],
    countries: ['TH', 'LA', 'MM', 'KH'],
    month: 4,
    day: 13,
    durationDays: 3,
    greeting: 'Happy Songkran! 💦🐘',
  ),

  // ── Judaism ─────────────────────────────────────────────────────────────
  CulturalEvent(
    id: 'rosh_hashanah',
    name: 'Rosh Hashanah',
    description: 'Jewish New Year. A time of reflection and renewal.',
    type: CulturalEventType.religiousHoliday,
    religions: [WorldReligion.judaism],
    regions: [
      WorldRegion.middleEast,
      WorldRegion.northAmerica,
      WorldRegion.westernEurope,
    ],
    month: 9,
    isLunarCalendar: true,
    durationDays: 2,
    greeting: 'Shanah Tovah! 🍎🍯',
    eventSchedulingSensitive: true,
  ),
  CulturalEvent(
    id: 'yom_kippur',
    name: 'Yom Kippur',
    description: 'Day of Atonement. The holiest day in Judaism.',
    type: CulturalEventType.religiousHoliday,
    religions: [WorldReligion.judaism],
    regions: [
      WorldRegion.middleEast,
      WorldRegion.northAmerica,
      WorldRegion.westernEurope,
    ],
    month: 9,
    isLunarCalendar: true,
    fasting: true,
    eventSchedulingSensitive: true,
  ),
  CulturalEvent(
    id: 'hanukkah',
    name: 'Hanukkah',
    description: 'Festival of Lights. Eight-day celebration.',
    type: CulturalEventType.religiousHoliday,
    religions: [WorldReligion.judaism],
    regions: [
      WorldRegion.middleEast,
      WorldRegion.northAmerica,
      WorldRegion.westernEurope,
    ],
    month: 12,
    isLunarCalendar: true,
    durationDays: 8,
    greeting: 'Happy Hanukkah! 🕎',
  ),

  // ── Sikhism ─────────────────────────────────────────────────────────────
  CulturalEvent(
    id: 'vaisakhi',
    name: 'Vaisakhi',
    description:
        'Sikh New Year and harvest festival. Marks the founding of the Khalsa.',
    type: CulturalEventType.religiousHoliday,
    religions: [WorldReligion.sikhism],
    regions: [WorldRegion.southAsia],
    month: 4,
    day: 14,
    greeting: 'Happy Vaisakhi! 🌾',
  ),
  CulturalEvent(
    id: 'guru_nanak_jayanti',
    name: 'Guru Nanak Jayanti',
    description: 'Birthday of Guru Nanak Dev Ji, founder of Sikhism.',
    type: CulturalEventType.religiousHoliday,
    religions: [WorldReligion.sikhism],
    regions: [WorldRegion.southAsia],
    month: 11,
    isLunarCalendar: true,
    greeting: 'Happy Gurpurab! 🙏',
  ),

  // ── Shinto / Japanese ───────────────────────────────────────────────────
  CulturalEvent(
    id: 'shogatsu',
    name: 'Shōgatsu (Japanese New Year)',
    description:
        'The most important holiday in Japan. Shrine visits and family gatherings.',
    type: CulturalEventType.culturalFestival,
    religions: [WorldReligion.shinto, WorldReligion.buddhism],
    regions: [WorldRegion.eastAsia],
    countries: ['JP'],
    month: 1,
    day: 1,
    durationDays: 3,
    greeting: 'あけましておめでとう！🎍',
    eventSchedulingSensitive: true,
  ),
  CulturalEvent(
    id: 'obon',
    name: 'Obon',
    description: 'Japanese Buddhist festival honouring ancestors.',
    type: CulturalEventType.religiousHoliday,
    religions: [WorldReligion.buddhism],
    regions: [WorldRegion.eastAsia],
    countries: ['JP'],
    month: 8,
    day: 15,
    durationDays: 3,
  ),

  // ── East Asia ───────────────────────────────────────────────────────────
  CulturalEvent(
    id: 'lunar_new_year',
    name: 'Lunar New Year',
    description:
        'Major celebration across East and Southeast Asia. Family reunions and feasting.',
    type: CulturalEventType.culturalFestival,
    regions: [WorldRegion.eastAsia, WorldRegion.southeastAsia],
    countries: ['CN', 'TW', 'KR', 'VN', 'SG', 'MY', 'ID', 'TH'],
    month: 1,
    isLunarCalendar: true,
    durationDays: 15,
    greeting: 'Happy Lunar New Year! 🧧🐉',
    eventSchedulingSensitive: true,
  ),
  CulturalEvent(
    id: 'chuseok',
    name: 'Chuseok (Korean Thanksgiving)',
    description:
        'Korean harvest festival. Three-day holiday celebrating family and ancestors.',
    type: CulturalEventType.culturalFestival,
    regions: [WorldRegion.eastAsia],
    countries: ['KR'],
    month: 9,
    isLunarCalendar: true,
    durationDays: 3,
    greeting: '추석 잘 보내세요! 🌕',
    eventSchedulingSensitive: true,
  ),

  // ── Indigenous / Pacific ────────────────────────────────────────────────
  CulturalEvent(
    id: 'matariki',
    name: 'Matariki (Māori New Year)',
    description:
        'Māori New Year marked by the rising of the Matariki star cluster (Pleiades).',
    type: CulturalEventType.culturalFestival,
    religions: [WorldReligion.indigenous],
    regions: [WorldRegion.oceania, WorldRegion.pacific],
    countries: ['NZ'],
    month: 6,
    isLunarCalendar: true,
    greeting: 'Mānawatia a Matariki! ✨',
    eventSchedulingSensitive: true,
  ),
  CulturalEvent(
    id: 'naidoc_week',
    name: 'NAIDOC Week',
    description:
        'Celebrates the history, culture, and achievements of Aboriginal and Torres Strait Islander peoples.',
    type: CulturalEventType.culturalFestival,
    religions: [WorldReligion.indigenous],
    regions: [WorldRegion.oceania],
    countries: ['AU'],
    month: 7,
    durationDays: 7,
  ),

  // ── Africa ──────────────────────────────────────────────────────────────
  CulturalEvent(
    id: 'kwanzaa',
    name: 'Kwanzaa',
    description:
        'African-American and pan-African cultural celebration of community and heritage.',
    type: CulturalEventType.culturalFestival,
    regions: [
      WorldRegion.northAmerica,
      WorldRegion.westAfrica,
      WorldRegion.eastAfrica,
    ],
    month: 12,
    day: 26,
    durationDays: 7,
    greeting: 'Happy Kwanzaa! 🕯️',
  ),

  // ── Global / Secular ────────────────────────────────────────────────────
  CulturalEvent(
    id: 'new_years_day',
    name: "New Year's Day",
    description: 'Global celebration of the new calendar year.',
    type: CulturalEventType.seasonalCelebration,
    regions: [
      WorldRegion.northAmerica,
      WorldRegion.southAmerica,
      WorldRegion.westernEurope,
      WorldRegion.easternEurope,
      WorldRegion.oceania,
      WorldRegion.eastAsia,
    ],
    month: 1,
    day: 1,
    greeting: 'Happy New Year! 🎉',
  ),
  CulturalEvent(
    id: 'nowruz',
    name: 'Nowruz (Persian New Year)',
    description:
        'Persian New Year celebrated at the spring equinox. Over 3,000 years old.',
    type: CulturalEventType.culturalFestival,
    religions: [WorldReligion.zoroastrianism],
    regions: [WorldRegion.middleEast, WorldRegion.centralAsia],
    countries: ['IR', 'AF', 'TJ', 'UZ', 'KZ', 'AZ', 'TR', 'IQ'],
    month: 3,
    day: 20,
    durationDays: 13,
    greeting: 'Nowruz Mubarak! 🌸',
  ),

  // ── Muay Thai / Combat Sport Traditions ─────────────────────────────────
  CulturalEvent(
    id: 'wai_kru',
    name: 'Wai Kru (Teacher Appreciation)',
    description:
        'Thai tradition of honouring teachers and trainers. Sacred in Muay Thai culture.',
    type: CulturalEventType.sportingTradition,
    regions: [WorldRegion.southeastAsia],
    countries: ['TH'],
    month: 6,
    isLunarCalendar: true,
  ),
  CulturalEvent(
    id: 'naadam',
    name: 'Naadam Festival',
    description:
        "Mongolia's biggest sporting festival. Wrestling, archery, and horse racing.",
    type: CulturalEventType.sportingTradition,
    regions: [WorldRegion.eastAsia, WorldRegion.centralAsia],
    countries: ['MN'],
    month: 7,
    day: 11,
    durationDays: 3,
    greeting: 'Happy Naadam! 🏹🐎',
  ),
];

// ═══════════════════════════════════════════════════════════════════════════════
// SEED DATA — World Martial Arts Traditions
// ═══════════════════════════════════════════════════════════════════════════════

const _allMartialArtsTraditions = <MartialArtsTradition>[
  // ── East Asia ───────────────────────────────────────────────────────────
  MartialArtsTradition(
    id: 'karate',
    name: 'Karate',
    originCountry: 'Japan',
    region: WorldRegion.eastAsia,
    description:
        'Japanese striking art originating from Okinawa. Emphasizes punches, kicks, and kata.',
    relatedStyles: ['Shotokan', 'Kyokushin', 'Goju-Ryu', 'Wado-Ryu'],
    culturalSignificance:
        'Deeply rooted in Bushido philosophy and Okinawan culture.',
    isOlympicSport: true,
  ),
  MartialArtsTradition(
    id: 'judo',
    name: 'Judo',
    originCountry: 'Japan',
    region: WorldRegion.eastAsia,
    description:
        'The gentle way. Japanese grappling art focused on throws and ground control.',
    relatedStyles: ['Kodokan Judo', 'Freestyle Judo'],
    culturalSignificance:
        'Founded by Jigoro Kano in 1882. First martial art in the Olympics.',
    isOlympicSport: true,
  ),
  MartialArtsTradition(
    id: 'sumo',
    name: 'Sumo',
    originCountry: 'Japan',
    region: WorldRegion.eastAsia,
    description:
        'Ancient Japanese wrestling with deep Shinto roots. 1,500+ year tradition.',
    culturalSignificance:
        'Sacred sport tied to Shinto purification rituals and Japanese identity.',
  ),
  MartialArtsTradition(
    id: 'taekwondo',
    name: 'Taekwondo',
    originCountry: 'South Korea',
    region: WorldRegion.eastAsia,
    description:
        'Korean martial art emphasizing head-height kicks, spinning kicks, and fast footwork.',
    relatedStyles: ['WTF/WT', 'ITF'],
    culturalSignificance:
        'National sport of South Korea. Means "the way of the foot and fist".',
    isOlympicSport: true,
  ),
  MartialArtsTradition(
    id: 'kung_fu',
    name: 'Kung Fu (Wushu)',
    originCountry: 'China',
    region: WorldRegion.eastAsia,
    description:
        'Chinese martial arts encompassing hundreds of styles over thousands of years.',
    relatedStyles: ['Wing Chun', 'Shaolin', 'Tai Chi', 'Sanda', 'Baguazhang'],
    culturalSignificance:
        'Central to Chinese culture, philosophy, and medicine for millennia.',
  ),
  MartialArtsTradition(
    id: 'mongolian_wrestling',
    name: 'Bökh (Mongolian Wrestling)',
    originCountry: 'Mongolia',
    region: WorldRegion.eastAsia,
    description:
        'Traditional Mongolian wrestling. One of the "three manly skills" alongside archery and horse racing.',
    culturalSignificance:
        'Core element of the Naadam Festival. Traces back to the era of Genghis Khan.',
  ),

  // ── Southeast Asia ──────────────────────────────────────────────────────
  MartialArtsTradition(
    id: 'muay_thai',
    name: 'Muay Thai',
    originCountry: 'Thailand',
    region: WorldRegion.southeastAsia,
    description: 'Art of Eight Limbs. Uses fists, elbows, knees, and shins.',
    relatedStyles: ['Muay Boran', 'Lethwei crossover'],
    culturalSignificance:
        'National sport of Thailand. The Wai Kru dance honours teachers before every fight.',
  ),
  MartialArtsTradition(
    id: 'pencak_silat',
    name: 'Pencak Silat',
    originCountry: 'Indonesia',
    region: WorldRegion.southeastAsia,
    description:
        'Malay archipelago martial art with striking, grappling, and weapon techniques.',
    relatedStyles: ['Silat Melayu', 'Silat Minangkabau'],
    culturalSignificance:
        'UNESCO Intangible Cultural Heritage. Deeply tied to Malay identity.',
  ),
  MartialArtsTradition(
    id: 'lethwei',
    name: 'Lethwei',
    originCountry: 'Myanmar',
    region: WorldRegion.southeastAsia,
    description:
        'Burmese bare-knuckle boxing. Allows headbutts. One of the most brutal striking arts.',
    culturalSignificance:
        'Ancient Burmese tradition dating back over 1,000 years.',
  ),
  MartialArtsTradition(
    id: 'arnis',
    name: 'Arnis (Eskrima/Kali)',
    originCountry: 'Philippines',
    region: WorldRegion.southeastAsia,
    description: 'Filipino martial art emphasizing stick and blade fighting.',
    relatedStyles: ['Eskrima', 'Kali', 'Modern Arnis'],
    culturalSignificance: 'National martial art of the Philippines.',
  ),

  // ── South Asia ──────────────────────────────────────────────────────────
  MartialArtsTradition(
    id: 'kalaripayattu',
    name: 'Kalaripayattu',
    originCountry: 'India',
    region: WorldRegion.southAsia,
    description:
        'One of the oldest martial arts in existence. From Kerala, India.',
    culturalSignificance:
        'Often called the mother of all martial arts. Over 3,000 years old.',
  ),
  MartialArtsTradition(
    id: 'kushti',
    name: 'Kushti (Pehlwani)',
    originCountry: 'India/Pakistan',
    region: WorldRegion.southAsia,
    description:
        'Traditional South Asian wrestling practiced in akharas (wrestling pits).',
    culturalSignificance:
        'Ancient tradition central to Indian and Pakistani sporting culture.',
  ),

  // ── Middle East ─────────────────────────────────────────────────────────
  MartialArtsTradition(
    id: 'pahlevani',
    name: 'Pahlevani & Zurkhaneh',
    originCountry: 'Iran',
    region: WorldRegion.middleEast,
    description:
        'Persian martial art combining wrestling, calisthenics, and spiritual discipline.',
    culturalSignificance:
        'UNESCO Intangible Cultural Heritage. Zurkhaneh means "house of strength".',
  ),

  // ── Americas ────────────────────────────────────────────────────────────
  MartialArtsTradition(
    id: 'bjj',
    name: 'Brazilian Jiu-Jitsu',
    originCountry: 'Brazil',
    region: WorldRegion.southAmerica,
    description:
        'Ground fighting art developed by the Gracie family from Japanese Jiu-Jitsu.',
    relatedStyles: ['Gracie Jiu-Jitsu', 'No-Gi', 'Luta Livre'],
    culturalSignificance:
        'Revolutionized MMA. Foundation of modern ground fighting worldwide.',
  ),
  MartialArtsTradition(
    id: 'capoeira',
    name: 'Capoeira',
    originCountry: 'Brazil',
    region: WorldRegion.southAmerica,
    description:
        'Afro-Brazilian martial art combining fight, dance, acrobatics, and music.',
    culturalSignificance:
        'UNESCO Intangible Cultural Heritage. Born from enslaved African resistance.',
  ),
  MartialArtsTradition(
    id: 'boxing',
    name: 'Boxing',
    originCountry: 'Global',
    region: WorldRegion.northAmerica,
    description:
        'The sweet science. Fist fighting with centuries of tradition worldwide.',
    relatedStyles: ['Western Boxing', 'Olympic Boxing'],
    culturalSignificance:
        'One of the oldest organized sports in human history.',
    isOlympicSport: true,
  ),
  MartialArtsTradition(
    id: 'wrestling_folkstyle',
    name: 'Folkstyle Wrestling',
    originCountry: 'USA',
    region: WorldRegion.northAmerica,
    description:
        'American collegiate wrestling style focused on control and riding time.',
    relatedStyles: ['Freestyle Wrestling', 'Greco-Roman'],
    isOlympicSport: true,
  ),

  // ── Europe ──────────────────────────────────────────────────────────────
  MartialArtsTradition(
    id: 'sambo',
    name: 'Sambo',
    originCountry: 'Russia',
    region: WorldRegion.easternEurope,
    description:
        'Soviet martial art combining judo, wrestling, and striking. Combat Sambo allows all strikes.',
    relatedStyles: ['Sport Sambo', 'Combat Sambo'],
    culturalSignificance:
        'Developed for the Soviet military. Produced many MMA champions.',
  ),
  MartialArtsTradition(
    id: 'savate',
    name: 'Savate',
    originCountry: 'France',
    region: WorldRegion.westernEurope,
    description: 'French kickboxing. Elegant foot-fighting art using shoes.',
    culturalSignificance:
        'One of the few European martial arts with an unbroken tradition.',
  ),
  MartialArtsTradition(
    id: 'glima',
    name: 'Glíma',
    originCountry: 'Iceland',
    region: WorldRegion.northernEurope,
    description: 'Viking wrestling tradition. Still practiced in Iceland.',
    culturalSignificance: 'Over 1,100 years old. Referenced in Norse sagas.',
  ),

  // ── Africa ──────────────────────────────────────────────────────────────
  MartialArtsTradition(
    id: 'dambe',
    name: 'Dambe',
    originCountry: 'Nigeria',
    region: WorldRegion.westAfrica,
    description:
        'Hausa boxing tradition. Lead hand wrapped, emphasizing powerful punches and kicks.',
    culturalSignificance:
        'Ancient Hausa warrior tradition, now a professional sport.',
  ),
  MartialArtsTradition(
    id: 'laamb',
    name: 'Laamb (Senegalese Wrestling)',
    originCountry: 'Senegal',
    region: WorldRegion.westAfrica,
    description:
        'National sport of Senegal. Wrestling with striking in major stadium events.',
    culturalSignificance:
        'Bigger than football in Senegal. Wrestlers are national heroes.',
  ),
  MartialArtsTradition(
    id: 'engolo',
    name: 'Engolo',
    originCountry: 'Angola',
    region: WorldRegion.centralAfrica,
    description: 'Angolan martial art believed to be the ancestor of Capoeira.',
    culturalSignificance:
        'Part of the rite of passage from boyhood to manhood.',
  ),

  // ── Oceania ─────────────────────────────────────────────────────────────
  MartialArtsTradition(
    id: 'mau_rakau',
    name: 'Mau Rākau',
    originCountry: 'New Zealand',
    region: WorldRegion.oceania,
    description:
        'Māori weaponry art using taiaha (staff), mere (club), and patu.',
    culturalSignificance:
        'Sacred warrior tradition of the Māori people. Te mana o te toa.',
  ),
  MartialArtsTradition(
    id: 'limalama',
    name: 'Lima Lama',
    originCountry: 'Samoa',
    region: WorldRegion.pacific,
    description: 'Polynesian martial art originating from Samoan warriors.',
    culturalSignificance:
        'Carries the strength and spirit of Polynesian warrior culture.',
  ),
];
