import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/image_assets.dart';
import '../models/ppv_model.dart';
import 'canonical_event_graph_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV SERVICE — Pay-Per-View Engine for DFC
/// ═══════════════════════════════════════════════════════════════════════════
///
/// DFC IS THE PROMOTIONAL ENGINE.
/// PPV is how promoters monetize their events through our platform.
///
/// Flow:
///   1. Promoter creates event → optionally attaches PPV
///   2. PPV goes through lifecycle: announced → presale → onSale → live → replay → expired
///   3. Fans purchase via Stripe/Apple Pay/Google Pay
///   4. DFC takes 15% platform fee, promoter gets 85%
///   5. On event day: stream URL goes live, predictions open, chat enabled
///   6. Post-event: replay available for premium/VIP purchasers
///
/// Firestore collections:
///   ppv_events/{ppvId}          — PPV event data
///   ppv_purchases/{purchaseId}  — Individual purchase records
///   ppv_events/{ppvId}/chat     — Live chat messages during stream
///
/// ═══════════════════════════════════════════════════════════════════════════
class PPVService with ChangeNotifier {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  late final CanonicalEventGraphService _canonicalEventGraphService =
      CanonicalEventGraphService(firestore: _firestore);

  static const Map<String, String> _knownPpvPosterKeys = {
    'ppv-ufc-perth-2026': 'ppv-ufc-perth-2026',
    'ufc-perth-2026': 'ppv-ufc-perth-2026',
    'ppv-ibc-03': 'ppv-ibc-03',
    'ibc-03-gold-coast': 'ppv-ibc-03',
    'ppv-eternal-80': 'ppv-eternal-80',
    'eternal-mma-perth-80': 'ppv-eternal-80',
    'ppv-elite-fs-cairns': 'ppv-elite-fs-cairns',
    'elite-fight-series-cairns': 'ppv-elite-fs-cairns',
    'ppv-ultimate-legends-apr-2026': 'ppv-ultimate-legends-apr-2026',
    'ultimate-legends-apr-2026': 'ppv-ultimate-legends-apr-2026',
    'ppv-ufc-327': 'ppv-ufc-327',
    'ufc-327': 'ppv-ufc-327',
    'ppv-ufc-328': 'ppv-ufc-328',
    'ufc-328': 'ppv-ufc-328',
    'ppv-pfl-pittsburgh-2026': 'ppv-pfl-pittsburgh-2026',
    'pfl-pittsburgh-2026': 'ppv-pfl-pittsburgh-2026',
    'ppv-bkfc-72': 'ppv-bkfc-72',
    'bkfc-72': 'ppv-bkfc-72',
    'ppv-one-170': 'ppv-one-170',
    'one-170': 'ppv-one-170',
    'ppv-hex-25': 'ppv-hex-25',
    'hex-25': 'ppv-hex-25',
    'ppv-bkfc-townsville-hepi': 'ppv-bkfc-townsville-hepi',
    'bkfc-fight-night-australia': 'ppv-bkfc-townsville-hepi',
    'ppv-bkfc-newcastle': 'ppv-bkfc-newcastle',
    'bkfc-newcastle': 'ppv-bkfc-newcastle',
    'ppv-ifma-antalyacup': 'ppv-ifma-antalyacup',
    'ifma-antalyacup': 'ppv-ifma-antalyacup',
    'ppv-legends45': 'ppv-legends45',
    'legends45': 'ppv-legends45',
    'ppv-eternal88': 'ppv-eternal88',
    'eternal88': 'ppv-eternal88',
    'ppv-adelaide-cs12': 'ppv-adelaide-cs12',
    'adelaide-cs12': 'ppv-adelaide-cs12',
    'ppv-ufc-paramount-fightnight': 'ppv-ufc-paramount-fightnight',
    'ufc-paramount-fightnight': 'ppv-ufc-paramount-fightnight',
    'ppv-brisbane-bonanza': 'ppv-brisbane-bonanza',
    'brisbane-bonanza': 'ppv-brisbane-bonanza',
    'ppv-westcoast-warriors33': 'ppv-westcoast-warriors33',
    'westcoast-warriors33': 'ppv-westcoast-warriors33',
  };

  // ── State ──
  List<PPVEvent> _upcomingPPVs = [];
  List<PPVEvent> _livePPVs = [];
  List<PPVPurchase> _userPurchases = [];
  bool _isLoading = false;
  String? _error;

  bool get _allowSyntheticPpvContent =>
      AppConstants.webDemoMode || AppConstants.syntheticContentEnabled;

  bool get _allowSyntheticPpvSeeding =>
      _allowSyntheticPpvContent &&
      (AppConstants.useFirebaseEmulator || AppConstants.allowLiveAutoSeed);

  List<PPVEvent> get upcomingPPVs => _upcomingPPVs;
  List<PPVEvent> get livePPVs => _livePPVs;
  List<PPVPurchase> get userPurchases => _userPurchases;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static bool _isRemotePosterUrl(String? url) {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) return false;
    return trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('gs://');
  }

  static bool _isLocalAssetPosterUrl(String? url) {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) return false;
    if (trimmed.startsWith('assets/')) return true;
    if (trimmed.startsWith('asset:')) return true;
    return ImageAssets.isGenericPosterAsset(trimmed) ||
        ImageAssets.isSpecificEventPosterAsset(trimmed);
  }

  Future<PPVEvent> _normalizedPosterEvent(PPVEvent event) async {
    final currentPoster = event.posterUrl?.trim();
    final posterKey =
        _knownPpvPosterKeys[event.id] ?? _knownPpvPosterKeys[event.eventId];

    final canonicalPosterRaw = await _canonicalEventGraphService
        .resolvePpvPosterUrl(event, preferThumb: true);
    final canonicalPoster = canonicalPosterRaw?.trim();

    final mappedPoster = _allowSyntheticPpvContent
        ? ImageAssets.posterAssetForEventMetadata(
            eventId: posterKey ?? event.eventId,
            title: event.title,
            promoter: event.promotion,
            eventDate: event.eventDate,
            streamUrl: event.streamUrl,
            ticketUrl: event.ticketUrl,
            preferThumb: true,
          )
        : null;

    String? resolvedPoster;
    if (_isRemotePosterUrl(canonicalPoster)) {
      resolvedPoster = canonicalPoster;
    } else if (_isRemotePosterUrl(currentPoster)) {
      resolvedPoster = currentPoster;
    } else if (_allowSyntheticPpvContent) {
      if (canonicalPoster != null && canonicalPoster.isNotEmpty) {
        resolvedPoster = canonicalPoster;
      } else {
        resolvedPoster = mappedPoster;
      }

      resolvedPoster ??= ImageAssets.isSpecificEventPosterAsset(currentPoster)
          ? currentPoster
          : null;
    }

    if (resolvedPoster != null && resolvedPoster.trim().isNotEmpty) {
      final isRemote = _isRemotePosterUrl(resolvedPoster);
      return event.copyWith(
        posterUrl: resolvedPoster,
        isFinalPoster: isRemote,
        posterAssetKind: isRemote
            ? 'finalPoster'
            : (event.posterAssetKind ?? 'syntheticPoster'),
      );
    }

    if (currentPoster == null ||
        currentPoster.isEmpty ||
        _isLocalAssetPosterUrl(currentPoster)) {
      return event.copyWith(
        isFinalPoster: false,
        posterAssetKind: event.posterAssetKind ?? 'missingPoster',
      );
    }

    return event.copyWith(
      isFinalPoster: event.isFinalPoster && _isRemotePosterUrl(currentPoster),
      posterAssetKind: event.posterAssetKind ?? 'finalPoster',
    );
  }

  Future<List<PPVEvent>> _normalizePosterEvents(Iterable<PPVEvent> events) {
    return Future.wait(events.map(_normalizedPosterEvent));
  }

  // ── Demo PPV Data (until Firestore is populated) ──

  static final List<PPVEvent> demoPPVEvents = [
    // ── Korakuen Hall, Tokyo — IBF World Atom + Title Fights (source: boxrec.com) ──
    PPVEvent(
      id: 'ppv-korakuen-apr-2026',
      eventId: 'korakuen-apr-2026',
      promoterId: 'jbc',
      title: 'KORAKUEN HALL: IBF WORLD ATOM TITLE',
      subtitle: 'Yamanaka vs Ugawa — Tokyo, Japan',
      description:
          'Six-bout card headlined by the vacant IBF World Atomweight Title. '
          'Sumire Yamanaka (9-1-0) vs Nao Ugawa (6-0-0). '
          'Plus WBO Asia Pacific Atom, OPBF Atom, JBC Japanese Bantam, '
          'and WBO Asia Pacific Minimum title fights. '
          'Korakuen Hall, Tokyo.',
      posterUrl: ImageAssets.bgEvent,
      eventDate: DateTime(2026, 4, 7, 18),
      presaleStart: DateTime(2026, 3),
      onSaleStart: DateTime(2026, 3, 15),
      status: PPVStatus.live,
      standardPriceCents: 1999,
      currency: 'JPY',
      sport: 'Boxing',
      promotion: 'JBC / Korakuen Hall',
      streamPlatforms: ['DAZN Japan'],
      fightCard: [
        const PPVFight(
          fightId: 'kor1',
          fighter1Name: 'Sumire Yamanaka',
          fighter2Name: 'Nao Ugawa',
          weightClass: 'Atomweight — IBF World (vacant)',
          rounds: 10,
          isMainEvent: true,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'kor2',
          fighter1Name: 'Shiori Yotsumoto',
          fighter2Name: 'Mao Kamada',
          weightClass: 'Atomweight — WBO Asia Pacific (vacant)',
          rounds: 10,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'kor3',
          fighter1Name: 'Honoka Kano',
          fighter2Name: 'Komi Sato',
          weightClass: 'Atomweight — OPBF',
          rounds: 10,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'kor4',
          fighter1Name: 'Nana Yamashita',
          fighter2Name: 'Terumi Nuki',
          weightClass: 'Bantamweight — JBC Japanese + OPBF',
          rounds: 10,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'kor5',
          fighter1Name: 'Nanako Suzuki',
          fighter2Name: 'Riyuna Yoshikawa',
          weightClass: 'Minimumweight — WBO Asia Pacific (vacant)',
          rounds: 10,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'kor6',
          fighter1Name: 'Rin Fukui',
          fighter2Name: 'Miki Matsui',
          weightClass: 'Super Bantamweight',
          rounds: 4,
        ),
      ],
      createdAt: DateTime(2026, 3, 20),
    ),

    PPVEvent(
      id: 'ppv-ufc-perth-2026',
      eventId: 'ufc-perth-2026',
      promoterId: 'ufc',
      title: 'UFC FIGHT NIGHT: PERTH',
      subtitle: 'Della Maddalena vs Prates',
      description:
          'Australia\'s rising star Robert Whittaker headlines UFC\'s return to Perth at RAC Arena. '
          'Featuring Jack Della Maddalena in the co-main event.',
      posterUrl:
          'https://ufc.com/images/styles/background_image_md/s3/2026-03/041826-ufc-fight-night-burns-vs-malott-EVENT-ART.jpg?h=d1cb525d&itok=y4GAeNeN',
      eventDate: DateTime(2026, 5, 2, 18),
      presaleStart: DateTime(2026, 3),
      onSaleStart: DateTime(2026, 3, 15),
      status: PPVStatus.onSale,
      standardPriceCents: 5999,
      earlyBirdPriceCents: 4499,
      premiumPriceCents: 7999,
      vipPriceCents: 12999,
      streamPlatforms: ['Kayo', 'Main Event', 'Thrillx', 'ESPN+'],
      purchaseCount: 12450,
      totalRevenueCents: 74575050,
      multiCamEnabled: true,
      fightCard: [
        const PPVFight(
          fightId: 'f1',
          fighter1Name: 'Robert Whittaker',
          fighter2Name: 'Dricus du Plessis',
          weightClass: 'Middleweight',
          rounds: 5,
          isMainEvent: true,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'f2',
          fighter1Name: 'Jack Della Maddalena',
          fighter2Name: 'Michel Pereira Prates',
          weightClass: 'Welterweight',
          rounds: 5,
        ),
        const PPVFight(
          fightId: 'f3',
          fighter1Name: 'Tai Tuivasa',
          fighter2Name: 'Jairzinho Rozenstruik',
          weightClass: 'Heavyweight',
        ),
        const PPVFight(
          fightId: 'f4',
          fighter1Name: 'Jimmy Crute',
          fighter2Name: 'Alonzo Menifield',
          weightClass: 'Light Heavyweight',
        ),
        const PPVFight(
          fightId: 'f5',
          fighter1Name: 'Casey O\'Neill',
          fighter2Name: 'Maycee Barber',
          weightClass: 'Flyweight',
        ),
      ],
      createdAt: DateTime(2026, 2, 15),
      sponsors: [
        {'name': 'Monster Energy'},
        {'name': 'Modelo'},
        {'name': 'DraftKings'},
      ],
    ),
    PPVEvent(
      id: 'ppv-ibc-03',
      eventId: 'ibc-03-gold-coast',
      promoterId: 'ibc',
      title: 'IBC 03: GOLD COAST BRAWL',
      subtitle: 'Potter vs Perceval — MW Title',
      description:
          'International Brawling Championship returns to the Gold Coast. '
          'Danny Mac\'s vision comes alive with bare-knuckle action on TrillerTV+.',
      posterUrl:
          'https://bkfc-cdn.gigcasters.com/a/881f5d0d-02d9-493b-b7ba-bced0210f9d9/39d1e984-6f40-4d73-a661-ad11c69477db/1744055909/o/1800x685-generic-action.jpg?1744055909',
      eventDate: DateTime(2026, 3, 7, 19),
      presaleStart: DateTime(2026, 2),
      onSaleStart: DateTime(2026, 2, 15),
      status: PPVStatus.replay,
      replayAvailable: true,
      standardPriceCents: 2999,
      earlyBirdPriceCents: 1999,
      premiumPriceCents: 4999,
      vipPriceCents: 7999,
      streamPlatforms: ['TrillerTV+', 'Kayo', 'Thrillx'],
      purchaseCount: 3200,
      totalRevenueCents: 9593600,
      fightCard: [
        const PPVFight(
          fightId: 'ibc1',
          fighter1Name: 'Callan Potter',
          fighter2Name: 'Steve Perceval',
          weightClass: 'Middleweight',
          rounds: 5,
          isMainEvent: true,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'ibc2',
          fighter1Name: 'Kit Dale',
          fighter2Name: 'Mitch Clarke',
          weightClass: 'Welterweight',
        ),
        const PPVFight(
          fightId: 'ibc3',
          fighter1Name: 'Janay Harding',
          fighter2Name: 'Jessica-Rose Clark',
          weightClass: 'Flyweight',
        ),
        const PPVFight(
          fightId: 'ibc4',
          fighter1Name: 'Brentin Mumford',
          fighter2Name: 'Joel Brunker',
          weightClass: 'Lightweight',
        ),
        const PPVFight(
          fightId: 'ibc5',
          fighter1Name: 'Justin Tafa',
          fighter2Name: 'Isi Fitikefu',
          weightClass: 'Heavyweight',
        ),
      ],
      createdAt: DateTime(2026, 1, 20),
      sponsors: [
        {'name': 'TrillerTV+'},
        {'name': 'Everlast'},
      ],
    ),
    PPVEvent(
      id: 'ppv-eternal-80',
      eventId: 'eternal-mma-perth-80',
      promoterId: 'eternal_mma',
      title: 'ETERNAL MMA 80',
      subtitle: 'Redfern vs Ramirez — Bantamweight Title',
      description:
          'Eternal MMA\'s flagship event at HBF Stadium Perth. '
          'Australia\'s premier MMA promotion delivers another stacked card.',
      posterUrl:
          'https://eternalmma.com/wp-content/uploads/2025/03/ETERNAL-MMA-WHITE-NO-BLEED.png',
      eventDate: DateTime(2026, 4, 12, 18, 30),
      presaleStart: DateTime(2026, 3),
      onSaleStart: DateTime(2026, 3, 10),
      status: PPVStatus.presale,
      standardPriceCents: 2499,
      earlyBirdPriceCents: 1499,
      premiumPriceCents: 3999,
      streamPlatforms: ['UFC Fight Pass'],
      purchaseCount: 890,
      totalRevenueCents: 1332110,
      fightCard: [
        const PPVFight(
          fightId: 'e1',
          fighter1Name: 'Ben Redfern',
          fighter2Name: 'Carlos Ramirez',
          weightClass: 'Bantamweight',
          rounds: 5,
          isMainEvent: true,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'e2',
          fighter1Name: 'Jake Matthews',
          fighter2Name: 'Mitch Ramirez',
          weightClass: 'Welterweight',
        ),
        const PPVFight(
          fightId: 'e3',
          fighter1Name: 'Amber Kitchen',
          fighter2Name: 'Jade Masson-Wong',
          weightClass: 'Flyweight',
        ),
      ],
      createdAt: DateTime(2026, 2, 20),
    ),
    PPVEvent(
      id: 'ppv-elite-fs-cairns',
      eventId: 'elite-fight-series-cairns',
      promoterId: 'elite_fight_series',
      title: 'ELITE FIGHT SERIES: CAIRNS',
      subtitle: 'Queensland\'s Rising Stars',
      description:
          'North Queensland\'s premier combat sports showcase at Cairns Convention Centre.',
      posterUrl: ImageAssets.ppvEliteFsCairnsHero,
      eventDate: DateTime(2026, 4, 26, 18),
      presaleStart: DateTime(2026, 3, 15),
      onSaleStart: DateTime(2026, 4),
      standardPriceCents: 1999,
      earlyBirdPriceCents: 1499,
      streamPlatforms: ['DFC', 'Thrillx', 'Kayo'],
      fightCard: [
        const PPVFight(
          fightId: 'efs1',
          fighter1Name: 'Jayden Cole',
          fighter2Name: 'Marcus Browne',
          weightClass: 'Welterweight',
          rounds: 5,
          isMainEvent: true,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'efs2',
          fighter1Name: 'Riley Taukamo',
          fighter2Name: 'Sam Patterson',
          weightClass: 'Lightweight',
        ),
        const PPVFight(
          fightId: 'efs3',
          fighter1Name: 'Zara Nguyen',
          fighter2Name: 'Lily Crook',
          weightClass: 'Strawweight',
        ),
      ],
      createdAt: DateTime(2026, 3),
    ),
    // ── Ultimate Legends — WBC Silver Australian Title ──
    PPVEvent(
      id: 'ppv-ultimate-legends-apr-2026',
      eventId: 'ultimate-legends-apr-2026',
      promoterId: 'ultimate_legends',
      title: 'ULTIMATE LEGENDS: WBC SILVER AUSTRALIAN TITLE',
      subtitle: 'Melbourne Pavilion — Jordan Roesler Main Event',
      description:
          'Melbourne\'s premier combat sports event — 30+ years strong! Founded by John Scida in 1992, co-promoted by Joey Demicoli. WBC Silver Australian Title headlines a stacked card of professional Boxing, K1, Kickboxing & Muay Thai. Livestream via Live Combat Sports. Sponsored by Palmerbet.',
      posterUrl: ImageAssets.ppvUltimateLegends2026Hero,
      eventDate: DateTime(2026, 4, 24, 18),
      presaleStart: DateTime(2026, 3, 10),
      onSaleStart: DateTime(2026, 3, 20),
      status: PPVStatus.onSale,
      standardPriceCents: 2499,
      earlyBirdPriceCents: 1999,
      premiumPriceCents: 4999,
      vipPriceCents: 9999,
      streamPlatforms: ['Live Combat Sports', 'DFC', 'Thrillx'],
      fightCard: [
        const PPVFight(
          fightId: 'ul1',
          fighter1Name: 'Jordan Roesler',
          fighter2Name: 'Conor Wallace',
          weightClass: 'Super Welterweight',
          rounds: 10,
          isMainEvent: true,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'ul2',
          fighter1Name: 'Karim Maatalla',
          fighter2Name: 'Goran Babic',
          weightClass: 'Boxing',
          rounds: 6,
        ),
        const PPVFight(
          fightId: 'ul3',
          fighter1Name: 'Stephanie Lee Cutting',
          fighter2Name: 'Jittamat Phomta',
          weightClass: 'Boxing',
          rounds: 6,
        ),
        const PPVFight(
          fightId: 'ul4',
          fighter1Name: 'Brandon Scerri',
          fighter2Name: 'Jhon Cortejos',
          weightClass: 'Boxing',
          rounds: 4,
        ),
        const PPVFight(
          fightId: 'ul5',
          fighter1Name: 'Nathan Silver',
          fighter2Name: 'Lovepreet',
          weightClass: 'Boxing',
          rounds: 4,
        ),
        const PPVFight(
          fightId: 'ul6',
          fighter1Name: 'Rhys Evans',
          fighter2Name: 'Jason Medawar',
          weightClass: 'Boxing',
          rounds: 4,
        ),
        const PPVFight(
          fightId: 'ul7',
          fighter1Name: 'Dylan Birdo',
          fighter2Name: 'Suttipoj Pitiyanovath',
          weightClass: 'K1 Kickboxing',
        ),
        const PPVFight(
          fightId: 'ul8',
          fighter1Name: 'Ranjeet Singh',
          fighter2Name: 'TBA',
          weightClass: 'Boxing',
          rounds: 4,
        ),
        const PPVFight(
          fightId: 'ul9',
          fighter1Name: 'Jack Stevens',
          fighter2Name: 'Puttarapum Thong-In',
          weightClass: 'K1 Kickboxing',
        ),
        const PPVFight(
          fightId: 'ul10',
          fighter1Name: 'Alex Coombe',
          fighter2Name: 'Christian Petrevski',
          weightClass: 'Boxing',
          rounds: 4,
        ),
        const PPVFight(
          fightId: 'ul11',
          fighter1Name: 'Youssef Khaled',
          fighter2Name: 'Victor Adis-Iosifidis',
          weightClass: 'Boxing',
          rounds: 4,
        ),
        const PPVFight(
          fightId: 'ul12',
          fighter1Name: 'Joshy Bomber Richards',
          fighter2Name: 'TBA',
          weightClass: 'Boxing',
          rounds: 4,
        ),
      ],
      createdAt: DateTime(2026, 3, 5),
    ),

    // ── UFC 327 — Prochazka vs Ulberg ──
    PPVEvent(
      id: 'ppv-ufc-327',
      eventId: 'ufc-327',
      promoterId: 'ufc',
      title: 'UFC 327: PROCHAZKA vs ULBERG',
      subtitle: 'Light Heavyweight Showdown',
      description:
          'Jiri Prochazka faces rising Kiwi contender Carlos Ulberg in a '
          'light heavyweight clash at T-Mobile Arena, Las Vegas.',
      posterUrl:
          'https://ufc.com/images/styles/background_image_md/s3/2026-03/041126-ufc-327-prochazka-vs-ulberg-EVENT-ART.jpg?h=d1cb525d&itok=dsfkQByi',
      eventDate: DateTime(2026, 4, 11, 22),
      presaleStart: DateTime(2026, 2, 20),
      onSaleStart: DateTime(2026, 3, 5),
      status: PPVStatus.onSale,
      standardPriceCents: 7999,
      earlyBirdPriceCents: 6499,
      premiumPriceCents: 9999,
      vipPriceCents: 14999,
      currency: 'USD',
      streamPlatforms: ['ESPN+', 'Kayo'],
      purchaseCount: 28500,
      totalRevenueCents: 227857500,
      multiCamEnabled: true,
      fightCard: [
        const PPVFight(
          fightId: 'u327-1',
          fighter1Name: 'Jiri Prochazka',
          fighter2Name: 'Carlos Ulberg',
          weightClass: 'Light Heavyweight',
          rounds: 5,
          isMainEvent: true,
        ),
        const PPVFight(
          fightId: 'u327-2',
          fighter1Name: 'Merab Dvalishvili',
          fighter2Name: 'Umar Nurmagomedov',
          weightClass: 'Bantamweight',
          rounds: 5,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'u327-3',
          fighter1Name: 'Shavkat Rakhmonov',
          fighter2Name: 'Kamaru Usman',
          weightClass: 'Welterweight',
        ),
        const PPVFight(
          fightId: 'u327-4',
          fighter1Name: 'Movsar Evloev',
          fighter2Name: 'Yair Rodriguez',
          weightClass: 'Featherweight',
        ),
      ],
      createdAt: DateTime(2026, 2, 10),
    ),

    // ── UFC 328 — Chimaev vs Strickland ──
    PPVEvent(
      id: 'ppv-ufc-328',
      eventId: 'ufc-328',
      promoterId: 'ufc',
      title: 'UFC 328: CHIMAEV vs STRICKLAND',
      subtitle: 'Middleweight No. 1 Contender',
      description:
          'Undefeated Khamzat Chimaev faces Sean Strickland at O2 Arena, London. '
          'Winner gets the next shot at the MW title.',
      posterUrl:
          'https://ufc.com/images/styles/background_image_md/s3/2026-03/050926-ufc-328-chimaev-vs-strickland-TEMP-HERO.jpg?h=d1cb525d&itok=4dxKgwvp',
      eventDate: DateTime(2026, 5, 9, 18),
      presaleStart: DateTime(2026, 3, 15),
      onSaleStart: DateTime(2026, 4),
      status: PPVStatus.presale,
      standardPriceCents: 7999,
      earlyBirdPriceCents: 6499,
      premiumPriceCents: 9999,
      vipPriceCents: 14999,
      currency: 'USD',
      streamPlatforms: ['ESPN+', 'TNT Sports'],
      purchaseCount: 5200,
      totalRevenueCents: 41579200,
      multiCamEnabled: true,
      fightCard: [
        const PPVFight(
          fightId: 'u328-1',
          fighter1Name: 'Khamzat Chimaev',
          fighter2Name: 'Sean Strickland',
          weightClass: 'Middleweight',
          rounds: 5,
          isMainEvent: true,
        ),
        const PPVFight(
          fightId: 'u328-2',
          fighter1Name: 'Tom Aspinall',
          fighter2Name: 'Ciryl Gane',
          weightClass: 'Heavyweight',
          rounds: 5,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'u328-3',
          fighter1Name: 'Paddy Pimblett',
          fighter2Name: 'Dan Hooker',
          weightClass: 'Lightweight',
        ),
        const PPVFight(
          fightId: 'u328-4',
          fighter1Name: 'Leon Edwards',
          fighter2Name: 'Jack Della Maddalena',
          weightClass: 'Welterweight',
          rounds: 5,
        ),
      ],
      createdAt: DateTime(2026, 3),
    ),

    // ── PFL 2026 Season — Pittsburgh ──
    PPVEvent(
      id: 'ppv-pfl-pittsburgh-2026',
      eventId: 'pfl-pittsburgh-2026',
      promoterId: 'pfl',
      title: 'PFL SUPER FIGHTS: PITTSBURGH',
      subtitle: 'Eblen vs Battle — MW Championship',
      description:
          'PFL returns to Pittsburgh with Johnny Eblen defending the middleweight '
          'title against Josh Battle. Plus AJ McKee in co-main.',
      posterUrl: ImageAssets.ppvPflPittsburgh2026Hero,
      eventDate: DateTime(2026, 3, 28, 20),
      presaleStart: DateTime(2026, 2, 15),
      onSaleStart: DateTime(2026, 3),
      status: PPVStatus.replay,
      replayAvailable: true,
      standardPriceCents: 4999,
      earlyBirdPriceCents: 3499,
      premiumPriceCents: 6999,
      vipPriceCents: 9999,
      currency: 'USD',
      streamPlatforms: ['ESPN+'],
      purchaseCount: 8900,
      totalRevenueCents: 44461100,
      fightCard: [
        const PPVFight(
          fightId: 'pfl1',
          fighter1Name: 'Johnny Eblen',
          fighter2Name: 'Josh Battle',
          weightClass: 'Middleweight',
          rounds: 5,
          isMainEvent: true,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'pfl2',
          fighter1Name: 'AJ McKee',
          fighter2Name: 'Paul Hughes',
          weightClass: 'Lightweight',
        ),
        const PPVFight(
          fightId: 'pfl3',
          fighter1Name: 'Anthony Pettis',
          fighter2Name: 'Clay Collard',
          weightClass: 'Featherweight',
        ),
      ],
      createdAt: DateTime(2026, 2, 5),
    ),

    // ── BKFC 72 — Bare Knuckle World Title ──
    PPVEvent(
      id: 'ppv-bkfc-72',
      eventId: 'bkfc-72',
      promoterId: 'bkfc',
      title: 'BKFC 72: BARE KNUCKLE WORLD TITLE',
      subtitle: 'Perry vs Mundell — Cruiserweight',
      description:
          'Mike Perry puts his BKFC cruiserweight title on the line at Knucklemania '
          'in Hollywood, Florida. Full stacked card of bare knuckle action.',
      posterUrl:
          'https://bkfc-cdn.gigcasters.com/a/881f5d0d-02d9-493b-b7ba-bced0210f9d9/39d1e984-6f40-4d73-a661-ad11c69477db/1768508652/o/BKFC_Hawaii_Teaser_NEW_no_text_web_1800x685.jpg?1768508652',
      eventDate: DateTime(2026, 4, 5, 21),
      presaleStart: DateTime(2026, 2, 20),
      onSaleStart: DateTime(2026, 3, 10),
      status: PPVStatus.onSale,
      standardPriceCents: 3999,
      earlyBirdPriceCents: 2999,
      premiumPriceCents: 5999,
      vipPriceCents: 8999,
      currency: 'USD',
      streamPlatforms: ['BKFC App'],
      purchaseCount: 15600,
      totalRevenueCents: 62384400,
      fightCard: [
        const PPVFight(
          fightId: 'bk1',
          fighter1Name: 'Mike Perry',
          fighter2Name: 'Luke Mundell',
          weightClass: 'Cruiserweight',
          rounds: 5,
          isMainEvent: true,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'bk2',
          fighter1Name: 'Lorenzo Hunt',
          fighter2Name: 'Alan Belcher',
          weightClass: 'Heavyweight',
          rounds: 5,
        ),
        const PPVFight(
          fightId: 'bk3',
          fighter1Name: 'Christine Ferea',
          fighter2Name: 'Britain Hart Beltran',
          weightClass: 'Flyweight',
          rounds: 5,
        ),
      ],
      createdAt: DateTime(2026, 2, 12),
    ),

    // ── ONE Championship 170 — Bangkok ──
    PPVEvent(
      id: 'ppv-one-170',
      eventId: 'one-170-bangkok',
      promoterId: 'one_championship',
      title: 'ONE 170: BANGKOK',
      subtitle: 'Stamp Fairtex vs Ham Seo Hee',
      description:
          'ONE Championship returns to Impact Arena Bangkok with a stacked card '
          'of Muay Thai, kickboxing, and MMA world title fights.',
      posterUrl:
          'https://cdn.onefc.com/wp-content/uploads/2025/01/250124-BKK-ONE170-1800x1200px-1200x800.jpg',
      eventDate: DateTime(2026, 4, 18, 19),
      presaleStart: DateTime(2026, 3),
      onSaleStart: DateTime(2026, 3, 15),
      status: PPVStatus.onSale,
      standardPriceCents: 2999,
      earlyBirdPriceCents: 1999,
      premiumPriceCents: 4999,
      vipPriceCents: 7999,
      currency: 'USD',
      streamPlatforms: ['Prime Video', 'ONE App'],
      purchaseCount: 22000,
      totalRevenueCents: 65978000,
      multiCamEnabled: true,
      fightCard: [
        const PPVFight(
          fightId: 'one1',
          fighter1Name: 'Stamp Fairtex',
          fighter2Name: 'Ham Seo Hee',
          weightClass: 'Atomweight MMA',
          rounds: 5,
          isMainEvent: true,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'one2',
          fighter1Name: 'Rodtang Jitmuangnon',
          fighter2Name: 'Superlek Kiatmoo9',
          weightClass: 'Flyweight Muay Thai',
          rounds: 5,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'one3',
          fighter1Name: 'Marcus Almeida',
          fighter2Name: 'Oumar Kane',
          weightClass: 'Heavyweight MMA',
        ),
        const PPVFight(
          fightId: 'one4',
          fighter1Name: 'Tawanchai PK Saenchai',
          fighter2Name: 'Sitthichai Sitsongpeenong',
          weightClass: 'Featherweight Kickboxing',
          rounds: 5,
          isTitleFight: true,
        ),
      ],
      createdAt: DateTime(2026, 2, 18),
    ),

    // ── Hex Fight Series 25 — Melbourne ──
    PPVEvent(
      id: 'ppv-hex-25',
      eventId: 'hex-25-melbourne',
      promoterId: 'hex',
      title: 'HEX FIGHT SERIES 25',
      subtitle: 'Melbourne — Australian MMA Championships',
      description:
          'Australia\'s premier hexagonal cage event returns to Melbourne '
          'Convention Centre with a loaded card of the best local talent.',
      posterUrl: ImageAssets.ppvHex25Hero,
      eventDate: DateTime(2026, 5, 16, 18, 30),
      presaleStart: DateTime(2026, 3, 20),
      onSaleStart: DateTime(2026, 4, 5),
      standardPriceCents: 1999,
      earlyBirdPriceCents: 1499,
      premiumPriceCents: 3499,
      streamPlatforms: ['UFC Fight Pass', 'Thrillx'],
      fightCard: [
        const PPVFight(
          fightId: 'hex1',
          fighter1Name: 'Jacob Malkoun',
          fighter2Name: 'Shannon Ross',
          weightClass: 'Middleweight',
          rounds: 5,
          isMainEvent: true,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'hex2',
          fighter1Name: 'JP Buys',
          fighter2Name: 'Shane Canney',
          weightClass: 'Flyweight',
        ),
        const PPVFight(
          fightId: 'hex3',
          fighter1Name: 'Loma Lookboonmee',
          fighter2Name: 'Nyrene Crowley',
          weightClass: 'Strawweight',
        ),
      ],
      createdAt: DateTime(2026, 3, 10),
    ),

    // ── BKFC Fight Night Australia — Townsville (Hepi vs Wisniewski II) ──
    PPVEvent(
      id: 'ppv-bkfc-townsville-hepi',
      eventId: 'demo_event_15',
      promoterId: 'bkfc',
      title: 'BKFC FIGHT NIGHT AUSTRALIA: HEPI EDITION',
      subtitle: 'Hepi vs Wisniewski II — Heavyweight Rematch',
      description:
          'BKFC makes its Australian debut in Townsville! MAIN EVENT: Haze "The Huntsman" Hepi (3-1) '
          'vs Krzysztof "The Big Man" Wisniewski (3-0) — the heavyweight rematch from BKFC 83 Rome. '
          'Doctor stoppage R3 last time. Both demanded the rematch. CO-MAIN: Mark "Bam Bam" Flanagan '
          '(24-7, 17KOs boxing) makes his bare-knuckle debut — former WBA cruiserweight title challenger. '
          'Plus Sam Soliman, BK Bau, and a stacked undercard of Aussie talent.',
      posterUrl:
          'https://bkfc-cdn.gigcasters.com/a/881f5d0d-02d9-493b-b7ba-bced0210f9d9/39d1e984-6f40-4d73-a661-ad11c69477db/1773161203/o/BKFC_FN_Australia_Hepi_vs_Wisniewski_no_text_web_1800x685.jpg?1773161203',
      eventDate: DateTime(2026, 4, 18, 19),
      presaleStart: DateTime(2026, 3),
      onSaleStart: DateTime(2026, 3, 15),
      status: PPVStatus.onSale,
      standardPriceCents: 2999,
      earlyBirdPriceCents: 1999,
      premiumPriceCents: 4999,
      vipPriceCents: 7999,
      streamUrl: 'https://watch.bkfc.com/videos/697',
      streamPlatforms: ['BKFC App', 'Thrillx'],
      purchaseCount: 1850,
      totalRevenueCents: 5543150,
      fightCard: [
        const PPVFight(
          fightId: 'hepi1',
          fighter1Name: 'Haze Hepi',
          fighter2Name: 'Krzysztof Wisniewski',
          weightClass: 'Heavyweight',
          rounds: 5,
          isMainEvent: true,
        ),
        const PPVFight(
          fightId: 'hepi2',
          fighter1Name: 'Mark Flanagan',
          fighter2Name: 'Daniel Ammann',
          weightClass: 'Cruiserweight',
          rounds: 5,
        ),
        const PPVFight(
          fightId: 'hepi3',
          fighter1Name: 'Sam Soliman',
          fighter2Name: 'Jake Peacock',
          weightClass: 'Middleweight',
          rounds: 5,
        ),
        const PPVFight(
          fightId: 'hepi4',
          fighter1Name: 'BK Bau',
          fighter2Name: 'Brentin Mumford',
          weightClass: 'Heavyweight',
          rounds: 5,
        ),
        const PPVFight(
          fightId: 'hepi5',
          fighter1Name: 'Joel Brunker',
          fighter2Name: 'Jake Hepi',
          weightClass: 'Welterweight',
          rounds: 5,
        ),
        const PPVFight(
          fightId: 'hepi6',
          fighter1Name: 'Shannon Ross',
          fighter2Name: 'Tyson Morris',
          weightClass: 'Lightweight',
          rounds: 5,
        ),
      ],
      createdAt: DateTime(2026, 3, 5),
    ),

    // ── BKFC Newcastle ──
    PPVEvent(
      id: 'ppv-bkfc-newcastle',
      eventId: 'bkfc-newcastle',
      promoterId: 'bkfc',
      title: 'BKFC NEWCASTLE',
      subtitle: 'Hunter Valley Bare Knuckle Showdown',
      description:
          'BKFC hits Newcastle Entertainment Centre with a stacked card '
          'of bare-knuckle action from the Hunter Valley.',
      posterUrl:
          'https://bkfc-cdn.gigcasters.com/a/881f5d0d-02d9-493b-b7ba-bced0210f9d9/39d1e984-6f40-4d73-a661-ad11c69477db/1771956312/o/BKFC_FN_Clearwater_3_Warren_vs_Cooke_web_1800x685.jpg?1771956312',
      eventDate: DateTime(2026, 6, 14, 19),
      presaleStart: DateTime(2026, 4, 15),
      onSaleStart: DateTime(2026, 5),
      standardPriceCents: 2999,
      earlyBirdPriceCents: 1999,
      premiumPriceCents: 4999,
      streamPlatforms: ['BKFC App', 'Thrillx'],
      fightCard: [
        const PPVFight(
          fightId: 'bknc1',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Welterweight',
          rounds: 5,
          isMainEvent: true,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'bknc2',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Middleweight',
          rounds: 5,
        ),
        const PPVFight(
          fightId: 'bknc3',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Lightweight',
          rounds: 5,
        ),
      ],
      createdAt: DateTime(2026, 3, 27),
    ),

    // ── IFMA Muaythai International EMF Open Cup — Antalya ──
    PPVEvent(
      id: 'ppv-ifma-antalyacup',
      eventId: 'ifma-antalyacup',
      promoterId: 'ifma',
      title: '13TH IFMA MUAYTHAI INTERNATIONAL EMF OPEN CUP',
      subtitle: 'Antalya, Turkey — Multi-Nation Championship',
      description:
          'The 13th edition of the IFMA European Muaythai Federation Open Cup '
          'brings top amateur and professional Muay Thai fighters to Antalya.',
      posterUrl:
          'https://cdn.onefc.com/wp-content/uploads/2025/01/250124-BKK-ONE170-1800x1200px-1200x800.jpg',
      eventDate: DateTime(2026, 5, 22, 10),
      presaleStart: DateTime(2026, 4),
      onSaleStart: DateTime(2026, 4, 15),
      standardPriceCents: 1499,
      earlyBirdPriceCents: 999,
      premiumPriceCents: 2999,
      currency: 'USD',
      streamPlatforms: ['DFC'],
      fightCard: [
        const PPVFight(
          fightId: 'ifma1',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Welterweight',
          rounds: 5,
          isMainEvent: true,
        ),
        const PPVFight(
          fightId: 'ifma2',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Lightweight',
        ),
        const PPVFight(
          fightId: 'ifma3',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Featherweight',
        ),
      ],
      createdAt: DateTime(2026, 3, 27),
    ),

    // ── Ultimate Legends: Fight Night — Melbourne Pavilion, Apr 24 2026 ──
    // Real event: Joey Demicoli & John Scida — Legends Promotions
    PPVEvent(
      id: 'ppv-legends45',
      eventId: 'legends45',
      promoterId: 'legends_fight_show',
      title: 'ULTIMATE LEGENDS: FIGHT NIGHT',
      subtitle: 'Melbourne Pavilion — 30+ Years Strong',
      description:
          'Legends Promotions presents Ultimate Legends Fight Night at '
          'Melbourne Pavilion, Kensington. WBC Silver Australian Title on '
          'the line — Jordan Roesler headlines. Full card: Boxing, K1 '
          'Kickboxing & Muay Thai. Matchmaker: Joey Demicoli. '
          'Livestream via Live Combat Sports.',
      posterUrl: ImageAssets.ppvUltimateLegends2026Hero,
      eventDate: DateTime(2026, 4, 24, 18),
      presaleStart: DateTime(2026, 3),
      onSaleStart: DateTime(2026, 3, 15),
      status: PPVStatus.onSale,
      standardPriceCents: 2499,
      earlyBirdPriceCents: 1499,
      premiumPriceCents: 3999,
      streamPlatforms: ['DFC', 'Live Combat'],
      ticketUrl: 'https://www.ultimatelegends.com.au',
      fightCard: [
        const PPVFight(
          fightId: 'leg1',
          fighter1Name: 'Jordan Roesler',
          fighter2Name: 'Conor Wallace',
          weightClass: 'Super Welterweight',
          rounds: 10,
          isMainEvent: true,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'leg2',
          fighter1Name: 'Karim Maatalla',
          fighter2Name: 'Goran Babic',
          weightClass: 'Boxing',
          rounds: 6,
        ),
        const PPVFight(
          fightId: 'leg3',
          fighter1Name: 'Stephanie Lee Cutting',
          fighter2Name: 'Jittamat Phomta',
          weightClass: 'Boxing',
          rounds: 6,
        ),
        const PPVFight(
          fightId: 'leg4',
          fighter1Name: 'Brandon Scerri',
          fighter2Name: 'Jhon Cortejos',
          weightClass: 'Boxing',
          rounds: 4,
        ),
        const PPVFight(
          fightId: 'leg5',
          fighter1Name: 'Nathan Silver',
          fighter2Name: 'Lovepreet',
          weightClass: 'Boxing',
          rounds: 4,
        ),
        const PPVFight(
          fightId: 'leg6',
          fighter1Name: 'Rhys Evans',
          fighter2Name: 'Jason Medawar',
          weightClass: 'Boxing',
          rounds: 4,
        ),
        const PPVFight(
          fightId: 'leg7',
          fighter1Name: 'Dylan Birdo',
          fighter2Name: 'Suttipoj Pitiyanovath',
          weightClass: 'K1 Kickboxing',
        ),
        const PPVFight(
          fightId: 'leg8',
          fighter1Name: 'Ranjeet Singh',
          fighter2Name: 'TBA',
          weightClass: 'Boxing',
          rounds: 4,
        ),
        const PPVFight(
          fightId: 'leg9',
          fighter1Name: 'Jack Stevens',
          fighter2Name: 'Puttarapum Thong-In',
          weightClass: 'K1 Kickboxing',
        ),
        const PPVFight(
          fightId: 'leg10',
          fighter1Name: 'Alex Coombe',
          fighter2Name: 'Christian Petrevski',
          weightClass: 'Boxing',
          rounds: 4,
        ),
        const PPVFight(
          fightId: 'leg11',
          fighter1Name: 'Youssef Khaled',
          fighter2Name: 'Victor Adis-Iosifidis',
          weightClass: 'Boxing',
          rounds: 4,
        ),
        const PPVFight(
          fightId: 'leg12',
          fighter1Name: 'Joshy Bomber Richards',
          fighter2Name: 'TBA',
          weightClass: 'Boxing',
          rounds: 4,
        ),
      ],
      createdAt: DateTime(2026, 3, 15),
      sponsors: [
        {'name': 'PalmerBet'},
        {'name': 'Live Combat'},
        {'name': 'KG Auto Sales'},
        {'name': 'Master Plaster'},
        {'name': 'Cerra Concrete'},
      ],
    ),

    // ── Eternal MMA 88 — Sydney ──
    PPVEvent(
      id: 'ppv-eternal88',
      eventId: 'eternal88',
      promoterId: 'eternal_mma',
      title: 'ETERNAL MMA 88',
      subtitle: 'Sydney — Fight Night',
      description:
          'Eternal MMA returns to Sydney with a loaded card of local and '
          'international MMA talent.',
      posterUrl:
          'https://eternalmma.com/wp-content/uploads/2025/03/ETERNAL-MMA-WHITE-NO-BLEED.png',
      eventDate: DateTime(2026, 6, 6, 18, 30),
      presaleStart: DateTime(2026, 4, 20),
      onSaleStart: DateTime(2026, 5, 5),
      standardPriceCents: 2499,
      earlyBirdPriceCents: 1499,
      premiumPriceCents: 3999,
      streamPlatforms: ['UFC Fight Pass', 'Thrillx'],
      fightCard: [
        const PPVFight(
          fightId: 'et88-1',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Welterweight',
          rounds: 5,
          isMainEvent: true,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'et88-2',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Bantamweight',
        ),
        const PPVFight(
          fightId: 'et88-3',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Flyweight',
        ),
      ],
      createdAt: DateTime(2026, 3, 27),
    ),

    // ── Adelaide Combat Series 12 ──
    PPVEvent(
      id: 'ppv-adelaide-cs12',
      eventId: 'adelaide-cs12',
      promoterId: 'adelaide_combat_series',
      title: 'ADELAIDE COMBAT SERIES 12',
      subtitle: 'South Australia\'s Premier Fight Night',
      description:
          'Adelaide Combat Series 12 brings MMA, Muay Thai, and kickboxing '
          'to the Adelaide Entertainment Centre.',
      posterUrl: ImageAssets.ppvAdelaideCs12Hero,
      eventDate: DateTime(2026, 5, 16, 18),
      presaleStart: DateTime(2026, 4),
      onSaleStart: DateTime(2026, 4, 20),
      standardPriceCents: 1999,
      earlyBirdPriceCents: 1499,
      streamPlatforms: ['DFC', 'Thrillx', 'Kayo'],
      fightCard: [
        const PPVFight(
          fightId: 'acs1',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Welterweight',
          rounds: 5,
          isMainEvent: true,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'acs2',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Middleweight',
        ),
        const PPVFight(
          fightId: 'acs3',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Strawweight',
        ),
      ],
      createdAt: DateTime(2026, 3, 27),
    ),

    // ── UFC Fight Night — LIVE on Paramount+ ──
    PPVEvent(
      id: 'ppv-ufc-paramount-fightnight',
      eventId: 'ufc-paramount-fightnight',
      promoterId: 'ufc',
      title: 'UFC FIGHT NIGHT — LIVE ON PARAMOUNT+',
      subtitle: 'Las Vegas — Fight Night Special',
      description:
          'UFC Fight Night live from the UFC APEX in Las Vegas, '
          'streaming on Paramount+ and ESPN+.',
      posterUrl:
          'https://ufc.com/images/styles/background_image_md/s3/2026-03/041126-ufc-327-prochazka-vs-ulberg-EVENT-ART.jpg?h=d1cb525d&itok=dsfkQByi',
      eventDate: DateTime(2026, 5, 30, 22),
      presaleStart: DateTime(2026, 4, 15),
      onSaleStart: DateTime(2026, 5),
      standardPriceCents: 4999,
      earlyBirdPriceCents: 3499,
      premiumPriceCents: 6999,
      vipPriceCents: 9999,
      currency: 'USD',
      streamPlatforms: ['Paramount+', 'ESPN+'],
      multiCamEnabled: true,
      fightCard: [
        const PPVFight(
          fightId: 'ufcpn1',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Welterweight',
          rounds: 5,
          isMainEvent: true,
        ),
        const PPVFight(
          fightId: 'ufcpn2',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Middleweight',
        ),
        const PPVFight(
          fightId: 'ufcpn3',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Lightweight',
        ),
      ],
      createdAt: DateTime(2026, 3, 27),
    ),

    // ── Brisbane Boxing Bonanza ──
    PPVEvent(
      id: 'ppv-brisbane-bonanza',
      eventId: 'brisbane-bonanza',
      promoterId: 'brisbane_boxing',
      title: 'BRISBANE BOXING BONANZA',
      subtitle: 'Brisbane Convention Centre — Apr 4',
      description:
          'A night of professional boxing at the Brisbane Convention and '
          'Exhibition Centre featuring Queensland\'s best boxers.',
      posterUrl: ImageAssets.ppvBrisbaneBonanzaHero,
      eventDate: DateTime(2026, 4, 4, 18),
      presaleStart: DateTime(2026, 3, 10),
      onSaleStart: DateTime(2026, 3, 20),
      status: PPVStatus.live,
      standardPriceCents: 2499,
      earlyBirdPriceCents: 1999,
      premiumPriceCents: 3999,
      streamPlatforms: ['DFC', 'Thrillx', 'Kayo'],
      fightCard: [
        const PPVFight(
          fightId: 'bb1',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Super Welterweight',
          rounds: 10,
          isMainEvent: true,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'bb2',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Middleweight',
          rounds: 8,
        ),
        const PPVFight(
          fightId: 'bb3',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Lightweight',
          rounds: 6,
        ),
      ],
      createdAt: DateTime(2026, 3, 27),
    ),

    // ── West Coast Warriors 33 — Perth ──
    PPVEvent(
      id: 'ppv-westcoast-warriors33',
      eventId: 'westcoast-warriors33',
      promoterId: 'west_coast_warriors',
      title: 'WEST COAST WARRIORS 33',
      subtitle: 'Perth — WA\'s Toughest Night',
      description:
          'West Coast Warriors brings MMA back to HBF Stadium Perth '
          'with a stacked card of local and international talent.',
      posterUrl: ImageAssets.ppvWestcoastWarriors33Hero,
      eventDate: DateTime(2026, 5, 30, 18),
      presaleStart: DateTime(2026, 4, 15),
      onSaleStart: DateTime(2026, 5),
      standardPriceCents: 1999,
      earlyBirdPriceCents: 1499,
      premiumPriceCents: 3499,
      streamPlatforms: ['DFC', 'Thrillx'],
      fightCard: [
        const PPVFight(
          fightId: 'wcw1',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Welterweight',
          rounds: 5,
          isMainEvent: true,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'wcw2',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Middleweight',
        ),
        const PPVFight(
          fightId: 'wcw3',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Flyweight',
        ),
      ],
      createdAt: DateTime(2026, 3, 27),
    ),

    // ═══════════════════════════════════════════════════════════════════
    // REAL EVENTS — April 2026 (sourced from Foxtel Main Event,
    // TrillerTV, LiveCombatSports, Paramount+)
    // ═══════════════════════════════════════════════════════════════════

    // ── Chisora vs Wilder — DAZN / Main Event ──
    PPVEvent(
      id: 'ppv-chisora-wilder-2026',
      eventId: 'chisora-wilder-2026',
      promoterId: 'dazn',
      title: 'CHISORA vs WILDER',
      subtitle: 'An Icon Will Fall',
      sport: 'Boxing',
      promotion: 'DAZN',
      description:
          'Two heavyweight icons enjoy their 50th professional boxing contests, '
          'as British legend Derek \'War\' Chisora (36-13) takes on former WBC '
          'champion Deontay Wilder (44-4-1) in a London superfight.',
      posterUrl:
          'https://bkfc-cdn.gigcasters.com/a/881f5d0d-02d9-493b-b7ba-bced0210f9d9/39d1e984-6f40-4d73-a661-ad11c69477db/1744055909/o/1800x685-generic-action.jpg?1744055909',
      eventDate: DateTime(2026, 4, 5, 4), // 4am AEST
      presaleStart: DateTime(2026, 3, 10),
      onSaleStart: DateTime(2026, 3, 20),
      status: PPVStatus.onSale,
      standardPriceCents: 4999,
      earlyBirdPriceCents: 3999,
      premiumPriceCents: 6999,
      streamPlatforms: ['DAZN', 'Main Event', 'Kayo', 'Thrillx'],
      purchaseCount: 18200,
      totalRevenueCents: 90981800,
      fightCard: [
        const PPVFight(
          fightId: 'cw1',
          fighter1Name: 'Derek Chisora',
          fighter2Name: 'Deontay Wilder',
          weightClass: 'Heavyweight',
          rounds: 12,
          isMainEvent: true,
        ),
        const PPVFight(
          fightId: 'cw2',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Super Middleweight',
          rounds: 10,
        ),
      ],
      createdAt: DateTime(2026, 3, 15),
    ),

    // ── Tszyu vs Nurja — Main Event ──
    PPVEvent(
      id: 'ppv-tszyu-nurja-2026',
      eventId: 'tszyu-nurja-2026',
      promoterId: 'no_limit_boxing',
      title: 'TSZYU vs NURJA',
      subtitle: 'WBO International Middleweight Title',
      sport: 'Boxing',
      promotion: 'No Limit Boxing',
      description:
          'Tim Tszyu looks to continue his boxing resurgence as he takes on '
          'Albanian Denis Nurja for the WBO International Middleweight Title.',
      posterUrl: ImageAssets.bgAction,
      eventDate: DateTime(2026, 4, 5, 11), // 11am AEST
      presaleStart: DateTime(2026, 3, 10),
      onSaleStart: DateTime(2026, 3, 20),
      status: PPVStatus.onSale,
      standardPriceCents: 5999,
      earlyBirdPriceCents: 4999,
      premiumPriceCents: 7999,
      streamPlatforms: ['Main Event', 'Kayo'],
      purchaseCount: 22000,
      totalRevenueCents: 131978000,
      fightCard: [
        const PPVFight(
          fightId: 'tn1',
          fighter1Name: 'Tim Tszyu',
          fighter2Name: 'Denis Nurja',
          weightClass: 'Middleweight',
          rounds: 12,
          isMainEvent: true,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'tn2',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Super Welterweight',
          rounds: 10,
        ),
      ],
      createdAt: DateTime(2026, 3, 15),
    ),

    // ── AEW Dynasty — TrillerTV+ / Main Event ──
    PPVEvent(
      id: 'ppv-aew-dynasty-2026',
      eventId: 'aew-dynasty-2026',
      promoterId: 'aew',
      title: 'AEW DYNASTY',
      subtitle: 'AEW World Tag Team Championship — FTR vs Cage & Cope',
      sport: 'Wrestling',
      promotion: 'AEW',
      description:
          'All Elite Wrestling is back in British Columbia for one of the biggest '
          'nights of the year, with AEW Dynasty featuring the World Tag Team Championship.',
      posterUrl: ImageAssets.bgAction,
      eventDate: DateTime(2026, 4, 13, 10), // 10am AEST
      presaleStart: DateTime(2026, 3),
      onSaleStart: DateTime(2026, 3, 15),
      status: PPVStatus.onSale,
      standardPriceCents: 4999,
      earlyBirdPriceCents: 3999,
      premiumPriceCents: 6999,
      streamPlatforms: ['TrillerTV+', 'Main Event', 'Kayo'],
      purchaseCount: 35000,
      totalRevenueCents: 174965000,
      fightCard: [
        const PPVFight(
          fightId: 'aew1',
          fighter1Name: 'FTR (Dax & Cash)',
          fighter2Name: 'Cage & Cope',
          weightClass: 'Tag Team',
          rounds: 1,
          isMainEvent: true,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'aew2',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'AEW World Title',
          rounds: 1,
        ),
      ],
      createdAt: DateTime(2026, 3, 10),
    ),

    // ── BKFC 88: Denver ──
    PPVEvent(
      id: 'ppv-bkfc-88-denver',
      eventId: 'bkfc-88-denver',
      promoterId: 'bkfc',
      title: 'BKFC 88: DENVER',
      subtitle: 'Camozzi vs Rodriguez — Interim Cruiserweight Title',
      sport: 'BKFC',
      promotion: 'BKFC',
      description:
          'Former BKFC Cruiserweight World Champion Chris Camozzi returns to '
          'his hometown of Denver to battle Esteban Rodriguez for the Interim '
          'Cruiserweight Title.',
      posterUrl:
          'https://bkfc-cdn.gigcasters.com/a/881f5d0d-02d9-493b-b7ba-bced0210f9d9/39d1e984-6f40-4d73-a661-ad11c69477db/1772555792/o/BKFC88_Denver_Camozzi_vs_Rodriguez_no_text_web_1800x685.jpg?1772555792',
      eventDate: DateTime(2026, 4, 18, 10), // 10am AEST
      presaleStart: DateTime(2026, 3, 15),
      onSaleStart: DateTime(2026, 3, 25),
      status: PPVStatus.onSale,
      standardPriceCents: 3999,
      earlyBirdPriceCents: 2999,
      premiumPriceCents: 5999,
      currency: 'USD',
      streamPlatforms: ['BKFC App', 'Main Event'],
      purchaseCount: 8500,
      totalRevenueCents: 33991500,
      fightCard: [
        const PPVFight(
          fightId: 'bk88-1',
          fighter1Name: 'Chris Camozzi',
          fighter2Name: 'Esteban Rodriguez',
          weightClass: 'Cruiserweight',
          rounds: 5,
          isMainEvent: true,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'bk88-2',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Welterweight',
          rounds: 5,
        ),
        const PPVFight(
          fightId: 'bk88-3',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Lightweight',
          rounds: 5,
        ),
      ],
      createdAt: DateTime(2026, 3, 20),
    ),

    // ── BKFC Australia ──
    PPVEvent(
      id: 'ppv-bkfc-australia-apr2026',
      eventId: 'bkfc-australia-apr2026',
      promoterId: 'bkfc',
      title: 'BKFC AUSTRALIA',
      subtitle: 'International Expansion — Australian Debut Card',
      sport: 'BKFC',
      promotion: 'BKFC',
      description:
          'BKFC continues its international expansion and makes its highly '
          'anticipated first event on Australian soil.',
      posterUrl:
          'https://bkfc-cdn.gigcasters.com/a/881f5d0d-02d9-493b-b7ba-bced0210f9d9/39d1e984-6f40-4d73-a661-ad11c69477db/1773161203/o/BKFC_FN_Australia_Hepi_vs_Wisniewski_no_text_web_1800x685.jpg?1773161203',
      eventDate: DateTime(2026, 4, 18, 20), // 8pm AEST
      presaleStart: DateTime(2026, 3, 15),
      onSaleStart: DateTime(2026, 3, 25),
      status: PPVStatus.onSale,
      standardPriceCents: 2999,
      earlyBirdPriceCents: 1999,
      premiumPriceCents: 4999,
      streamPlatforms: ['BKFC App', 'Main Event'],
      purchaseCount: 4200,
      totalRevenueCents: 12595800,
      fightCard: [
        const PPVFight(
          fightId: 'bkau1',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Heavyweight',
          rounds: 5,
          isMainEvent: true,
        ),
        const PPVFight(
          fightId: 'bkau2',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Welterweight',
          rounds: 5,
        ),
        const PPVFight(
          fightId: 'bkau3',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Lightweight',
          rounds: 5,
        ),
      ],
      createdAt: DateTime(2026, 3, 20),
    ),

    // ── XRUMBLE Fighting Championships — TrillerTV PPV ──
    PPVEvent(
      id: 'ppv-xrumble-2026',
      eventId: 'xrumble-2026',
      promoterId: 'xrumble',
      title: 'XRUMBLE FIGHTING CHAMPIONSHIPS',
      subtitle: 'Zenith Zion vs Chrisean Rock — Celebrity Boxing',
      sport: 'Boxing',
      promotion: 'XRUMBLE',
      description:
          'Official Celebrity Boxing — XRUMBLE Fighting Championships featuring '
          'Zenith Zion vs Holy Hands Chrisean, plus Marcial vs Mayweather undercard.',
      posterUrl:
          'https://bkfc-cdn.gigcasters.com/a/881f5d0d-02d9-493b-b7ba-bced0210f9d9/39d1e984-6f40-4d73-a661-ad11c69477db/1744055909/o/1800x685-generic-action.jpg?1744055909',
      eventDate: DateTime(2026, 4, 26, 9, 30), // 9:30 AM
      presaleStart: DateTime(2026, 3, 20),
      onSaleStart: DateTime(2026, 4),
      status: PPVStatus.onSale,
      standardPriceCents: 3999,
      earlyBirdPriceCents: 2999,
      currency: 'USD',
      streamPlatforms: ['TrillerTV+'],
      purchaseCount: 6800,
      totalRevenueCents: 27193200,
      fightCard: [
        const PPVFight(
          fightId: 'xr1',
          fighter1Name: 'Zenith Zion',
          fighter2Name: 'Chrisean Rock',
          weightClass: 'Celebrity Boxing',
          rounds: 6,
          isMainEvent: true,
        ),
        const PPVFight(
          fightId: 'xr2',
          fighter1Name: 'Marcial',
          fighter2Name: 'Mayweather',
          weightClass: 'Exhibition',
          rounds: 4,
        ),
      ],
      createdAt: DateTime(2026, 3, 25),
    ),

    // ── GCW Maniac 2026 — TrillerTV ──
    PPVEvent(
      id: 'ppv-gcw-maniac-2026',
      eventId: 'gcw-maniac-2026',
      promoterId: 'gcw',
      title: 'GCW: MANIAC 2026',
      subtitle: 'Game Changer Wrestling',
      sport: 'Wrestling',
      promotion: 'GCW',
      description:
          'Game Changer Wrestling presents Maniac 2026 — Pro Wrestling at its most extreme.',
      posterUrl: ImageAssets.bgAction,
      eventDate: DateTime(2026, 4, 5, 13), // 1pm
      presaleStart: DateTime(2026, 3, 15),
      onSaleStart: DateTime(2026, 3, 25),
      status: PPVStatus.onSale,
      standardPriceCents: 1999,
      earlyBirdPriceCents: 1499,
      currency: 'USD',
      streamPlatforms: ['TrillerTV+'],
      purchaseCount: 3200,
      totalRevenueCents: 6396800,
      fightCard: [
        const PPVFight(
          fightId: 'gcw1',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Deathmatch',
          rounds: 1,
          isMainEvent: true,
        ),
        const PPVFight(
          fightId: 'gcw2',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Tag Team',
          rounds: 1,
        ),
      ],
      createdAt: DateTime(2026, 3, 25),
    ),

    // ── HYPE Brazil: Tsarukyan vs Dillon Danis — TrillerTV ──
    PPVEvent(
      id: 'ppv-hype-brazil-2026',
      eventId: 'hype-brazil-2026',
      promoterId: 'integrated_sports',
      title: 'HYPE BRAZIL: TSARUKYAN vs DILLON DANIS',
      subtitle: 'Integrated Sports — Boxing',
      sport: 'Boxing',
      promotion: 'Integrated Sports',
      description:
          'HYPE Brazil presents Arman Tsarukyan vs Dillon Danis in a crossover boxing event.',
      posterUrl: ImageAssets.bgAction,
      eventDate: DateTime(2026, 4, 9, 9, 30),
      presaleStart: DateTime(2026, 3, 15),
      onSaleStart: DateTime(2026, 3, 25),
      status: PPVStatus.onSale,
      standardPriceCents: 2999,
      earlyBirdPriceCents: 1999,
      currency: 'USD',
      streamPlatforms: ['TrillerTV+'],
      purchaseCount: 11000,
      totalRevenueCents: 32989000,
      fightCard: [
        const PPVFight(
          fightId: 'hyp1',
          fighter1Name: 'Arman Tsarukyan',
          fighter2Name: 'Dillon Danis',
          weightClass: 'Lightweight Boxing',
          rounds: 8,
          isMainEvent: true,
        ),
        const PPVFight(
          fightId: 'hyp2',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Welterweight',
          rounds: 6,
        ),
      ],
      createdAt: DateTime(2026, 3, 25),
    ),

    // ── BKFC Fight Night Honolulu — TrillerTV ──
    PPVEvent(
      id: 'ppv-bkfc-honolulu-2026',
      eventId: 'bkfc-honolulu-2026',
      promoterId: 'bkfc',
      title: 'BKFC FIGHT NIGHT HONOLULU',
      subtitle: 'Maki Pitolo vs Doug "Coldred" Coltrane',
      sport: 'BKFC',
      promotion: 'BKFC',
      description:
          'BKFC Fight Night comes to Honolulu with Maki Pitolo vs Doug Coltrane headlining.',
      posterUrl:
          'https://bkfc-cdn.gigcasters.com/a/881f5d0d-02d9-493b-b7ba-bced0210f9d9/39d1e984-6f40-4d73-a661-ad11c69477db/1768508652/o/BKFC_Hawaii_Teaser_NEW_no_text_web_1800x685.jpg?1768508652',
      eventDate: DateTime(2026, 4, 12, 13),
      presaleStart: DateTime(2026, 3, 15),
      onSaleStart: DateTime(2026, 3, 25),
      status: PPVStatus.onSale,
      standardPriceCents: 3999,
      earlyBirdPriceCents: 2999,
      currency: 'USD',
      streamPlatforms: ['BKFC App', 'TrillerTV+'],
      purchaseCount: 5600,
      totalRevenueCents: 22394400,
      fightCard: [
        const PPVFight(
          fightId: 'bkhl1',
          fighter1Name: 'Maki Pitolo',
          fighter2Name: 'Doug Coltrane',
          weightClass: 'Middleweight',
          rounds: 5,
          isMainEvent: true,
        ),
        const PPVFight(
          fightId: 'bkhl2',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Welterweight',
          rounds: 5,
        ),
      ],
      createdAt: DateTime(2026, 3, 25),
    ),

    // ── Empire Legacy — LiveCombatSports.com.au ──
    PPVEvent(
      id: 'ppv-empire-legacy-2026',
      eventId: 'empire-legacy-2026',
      promoterId: 'empire_legacy',
      title: 'EMPIRE LEGACY',
      subtitle: 'Melbourne — Live Combat Sports',
      sport: 'Boxing',
      promotion: 'Empire Legacy',
      description:
          'Empire Legacy — professional boxing and combat sports event streamed live on LiveCombatSports.com.au.',
      posterUrl: ImageAssets.bgEvent,
      eventDate: DateTime(2026, 4, 4, 19),
      presaleStart: DateTime(2026, 3, 10),
      onSaleStart: DateTime(2026, 3, 20),
      status: PPVStatus.onSale,
      standardPriceCents: 2499,
      earlyBirdPriceCents: 1999,
      streamPlatforms: ['Live Combat Sports'],
      purchaseCount: 850,
      totalRevenueCents: 2124150,
      fightCard: [
        const PPVFight(
          fightId: 'el1',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Super Welterweight',
          rounds: 8,
          isMainEvent: true,
        ),
        const PPVFight(
          fightId: 'el2',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Middleweight',
          rounds: 6,
        ),
      ],
      createdAt: DateTime(2026, 3, 25),
    ),

    // ── Neutral Corner — LiveCombatSports.com.au ──
    PPVEvent(
      id: 'ppv-neutral-corner-2026',
      eventId: 'neutral-corner-2026',
      promoterId: 'neutral_corner',
      title: 'NEUTRAL CORNER',
      subtitle: 'Kyd Sparks vs Zeke Latin',
      sport: 'Boxing',
      promotion: 'Neutral Corner',
      description:
          'Neutral Corner boxing event — Kyd Sparks vs Zeke Latin — streamed on LiveCombatSports.com.au.',
      posterUrl: ImageAssets.bgEvent,
      eventDate: DateTime(2026, 4, 4, 19),
      presaleStart: DateTime(2026, 3, 10),
      onSaleStart: DateTime(2026, 3, 20),
      status: PPVStatus.onSale,
      standardPriceCents: 2499,
      earlyBirdPriceCents: 1999,
      streamPlatforms: ['Live Combat Sports'],
      purchaseCount: 620,
      totalRevenueCents: 1548780,
      fightCard: [
        const PPVFight(
          fightId: 'nc1',
          fighter1Name: 'Kyd Sparks',
          fighter2Name: 'Zeke Latin',
          weightClass: 'Middleweight',
          rounds: 8,
          isMainEvent: true,
        ),
        const PPVFight(
          fightId: 'nc2',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Lightweight',
          rounds: 6,
        ),
      ],
      createdAt: DateTime(2026, 3, 25),
    ),

    // ── Melbourne Fight Series — LiveCombatSports.com.au ──
    PPVEvent(
      id: 'ppv-melbourne-fight-series-2026',
      eventId: 'melbourne-fight-series-2026',
      promoterId: 'melbourne_fight_series',
      title: 'MELBOURNE FIGHT SERIES',
      subtitle: 'MFS — Combat Sports Showcase',
      sport: 'MMA',
      promotion: 'Melbourne Fight Series',
      description:
          'Melbourne Fight Series — MMA and combat sports showcase streamed on LiveCombatSports.com.au.',
      posterUrl: ImageAssets.bgEvent,
      eventDate: DateTime(2026, 4, 5, 18, 30),
      presaleStart: DateTime(2026, 3, 10),
      onSaleStart: DateTime(2026, 3, 20),
      status: PPVStatus.onSale,
      standardPriceCents: 1999,
      earlyBirdPriceCents: 1499,
      streamPlatforms: ['Live Combat Sports'],
      purchaseCount: 480,
      totalRevenueCents: 959520,
      fightCard: [
        const PPVFight(
          fightId: 'mfs1',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Welterweight',
          rounds: 5,
          isMainEvent: true,
        ),
        const PPVFight(
          fightId: 'mfs2',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Lightweight',
        ),
      ],
      createdAt: DateTime(2026, 3, 25),
    ),

    // ── VABL Berwick — LiveCombatSports.com.au ──
    PPVEvent(
      id: 'ppv-vabl-berwick-2026',
      eventId: 'vabl-berwick-2026',
      promoterId: 'vabl',
      title: 'VABL BERWICK',
      subtitle: 'Victorian Amateur Boxing League',
      sport: 'Boxing',
      promotion: 'VABL',
      description:
          'Victorian Amateur Boxing League Berwick edition — amateur boxing live on LiveCombatSports.com.au.',
      posterUrl: ImageAssets.bgEvent,
      eventDate: DateTime(2026, 4, 5, 13),
      presaleStart: DateTime(2026, 3, 10),
      onSaleStart: DateTime(2026, 3, 20),
      status: PPVStatus.onSale,
      standardPriceCents: 999,
      earlyBirdPriceCents: 0,
      streamPlatforms: ['Live Combat Sports'],
      purchaseCount: 320,
      totalRevenueCents: 319680,
      fightCard: [
        const PPVFight(
          fightId: 'vabl1',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Middleweight',
          isMainEvent: true,
        ),
        const PPVFight(
          fightId: 'vabl2',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'Lightweight',
        ),
      ],
      createdAt: DateTime(2026, 3, 25),
    ),

    // ── AEW Dynamite — TrillerTV ──
    PPVEvent(
      id: 'ppv-aew-dynamite-ep1326',
      eventId: 'aew-dynamite-ep1326',
      promoterId: 'aew',
      title: 'AEW: DYNAMITE',
      subtitle: 'Episode 13-26 — Weekly Wrestling',
      sport: 'Wrestling',
      promotion: 'AEW',
      description:
          'All Elite Wrestling Dynamite — weekly flagship show on TrillerTV+ and TBS.',
      posterUrl: ImageAssets.bgAction,
      eventDate: DateTime(2026, 4, 2, 11),
      status: PPVStatus.onSale,
      standardPriceCents: 0, // Free with subscription
      currency: 'USD',
      streamPlatforms: ['TrillerTV+', 'AEW Plus'],
      predictionsEnabled: false,
      fightCard: [
        const PPVFight(
          fightId: 'aewd1',
          fighter1Name: 'TBA',
          fighter2Name: 'TBA',
          weightClass: 'AEW World Title',
          rounds: 1,
          isMainEvent: true,
        ),
      ],
      createdAt: DateTime(2026, 3, 30),
    ),
  ];

  // ── Fetch PPV Events ──

  Future<void> loadUpcomingPPVs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('ppv_events')
          .where('status', whereIn: ['announced', 'presale', 'onSale'])
          .orderBy('eventDate')
          .limit(20)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _upcomingPPVs = await _normalizePosterEvents(
          snapshot.docs.map(PPVEvent.fromFirestore),
        );
      } else if (_allowSyntheticPpvContent) {
        // Demo-only fallback (sandbox lanes only).
        _upcomingPPVs = await _normalizePosterEvents(
          demoPPVEvents.where(
            (e) => e.status != PPVStatus.live && e.status != PPVStatus.expired,
          ),
        );
        if (_allowSyntheticPpvSeeding) {
          _seedDemoEventsToFirestore();
        }
      } else {
        // Real mode: no synthetic fallback.
        _upcomingPPVs = [];
      }
    } catch (e) {
      debugPrint('PPVService.loadUpcomingPPVs error: $e');
      _error = e.toString();
      _upcomingPPVs = _allowSyntheticPpvContent
          ? await _normalizePosterEvents(demoPPVEvents)
          : [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadLivePPVs() async {
    try {
      final snapshot = await _firestore
          .collection('ppv_events')
          .where('status', isEqualTo: 'live')
          .limit(20)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _livePPVs = await _normalizePosterEvents(
          snapshot.docs.map(PPVEvent.fromFirestore),
        );
      } else if (_allowSyntheticPpvContent) {
        _livePPVs = await _normalizePosterEvents(
          demoPPVEvents.where((e) => e.status == PPVStatus.live),
        );
      } else {
        _livePPVs = [];
      }
    } catch (e) {
      debugPrint('PPVService.loadLivePPVs error: $e');
      _error = e.toString();
      _livePPVs = _allowSyntheticPpvContent
          ? await _normalizePosterEvents(
              demoPPVEvents.where((e) => e.status == PPVStatus.live),
            )
          : [];
    }
    notifyListeners();
  }

  /// Seed demo PPV events to Firestore so purchase flow has real docs
  Future<void> _seedDemoEventsToFirestore() async {
    if (!_allowSyntheticPpvSeeding) return;

    try {
      final batch = _firestore.batch();
      final normalizedEvents = await _normalizePosterEvents(demoPPVEvents);
      for (final ppv in normalizedEvents) {
        final ref = _firestore.collection('ppv_events').doc(ppv.id);
        batch.set(ref, ppv.toFirestore(), SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint(
        'PPVService: Seeded ${demoPPVEvents.length} demo events to Firestore',
      );
    } catch (e) {
      debugPrint('PPVService._seedDemoEventsToFirestore error: $e');
    }
  }

  /// Get a single PPV event by ID
  Future<PPVEvent?> getPPVEvent(String ppvId) async {
    final demo = _allowSyntheticPpvContent
        ? demoPPVEvents
              .where((e) => e.id == ppvId || e.eventId == ppvId)
              .firstOrNull
        : null;

    try {
      final doc = await _firestore.collection('ppv_events').doc(ppvId).get();
      if (doc.exists) {
        return _normalizedPosterEvent(PPVEvent.fromFirestore(doc));
      }

      final eventIdSnapshot = await _firestore
          .collection('ppv_events')
          .where('eventId', isEqualTo: ppvId)
          .limit(1)
          .get();
      if (eventIdSnapshot.docs.isNotEmpty) {
        return _normalizedPosterEvent(
          PPVEvent.fromFirestore(eventIdSnapshot.docs.first),
        );
      }
    } catch (e) {
      debugPrint('PPVService.getPPVEvent error: $e');
    }

    if (!_allowSyntheticPpvContent) return null;
    return demo == null ? null : _normalizedPosterEvent(demo);
  }

  Future<String?> _resolvePpvDocumentId(String ppvId) async {
    try {
      final directDoc = await _firestore
          .collection('ppv_events')
          .doc(ppvId)
          .get();
      if (directDoc.exists) {
        return directDoc.id;
      }

      final eventIdSnapshot = await _firestore
          .collection('ppv_events')
          .where('eventId', isEqualTo: ppvId)
          .limit(1)
          .get();
      if (eventIdSnapshot.docs.isNotEmpty) {
        return eventIdSnapshot.docs.first.id;
      }
    } catch (e) {
      debugPrint('PPVService._resolvePpvDocumentId error: $e');
    }

    if (!_allowSyntheticPpvContent) return null;
    final demo = demoPPVEvents
        .where((e) => e.id == ppvId || e.eventId == ppvId)
        .firstOrNull;
    return demo?.id;
  }

  Future<Set<String>> _resolvePpvLookupIds(String ppvId) async {
    final ids = <String>{};
    final canonicalDocId = await _resolvePpvDocumentId(ppvId);
    if (canonicalDocId != null && canonicalDocId.isNotEmpty) {
      ids.add(canonicalDocId);
    }

    ids.add(ppvId);

    final event = await getPPVEvent(ppvId);
    if (event != null) {
      if (event.id.isNotEmpty) {
        ids.add(event.id);
      }
      if (event.eventId.isNotEmpty) {
        ids.add(event.eventId);
      }
    }

    ids.removeWhere((value) => value.isEmpty);
    return ids;
  }

  /// Stream a PPV event (for live updates during event)
  Stream<PPVEvent?> streamPPVEvent(String ppvId) async* {
    final resolvedPpvDocId = await _resolvePpvDocumentId(ppvId);
    if (resolvedPpvDocId == null || resolvedPpvDocId.isEmpty) {
      yield null;
      return;
    }

    yield* _firestore
        .collection('ppv_events')
        .doc(resolvedPpvDocId)
        .snapshots()
        .asyncMap(
          (doc) async => doc.exists
              ? _normalizedPosterEvent(PPVEvent.fromFirestore(doc))
              : null,
        )
        .handleError((e) {
          debugPrint('PPVService.streamPPVEvent error: $e');
          return null;
        });
  }

  // ── Purchases ──

  static DateTime? _readPurchaseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static DateTime _bestPurchaseTimestamp(Map<String, dynamic> data) {
    return _readPurchaseDate(data['purchasedAt']) ??
        _readPurchaseDate(data['paidAt']) ??
        _readPurchaseDate(data['completedAt']) ??
        _readPurchaseDate(data['createdAt']) ??
        _readPurchaseDate(data['updatedAt']) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  static bool _isAuthoritativeCheckoutSession(Map<String, dynamic> data) {
    final status = data['status']?.toString().toLowerCase();
    final paymentStatus = data['paymentStatus']?.toString().toLowerCase();

    return data['accessGranted'] == true ||
        data['isActive'] == true ||
        status == 'complete' ||
        status == 'completed' ||
        paymentStatus == 'succeeded' ||
        paymentStatus == 'paid';
  }

  static String _purchaseIdentityFromMap(
    Map<String, dynamic> data,
    String fallbackId,
  ) {
    final userId = data['userId']?.toString() ?? '';
    final ppvId =
        data['ppvEventId']?.toString() ??
        data['ppvId']?.toString() ??
        data['eventId']?.toString() ??
        fallbackId;
    return '$userId::$ppvId';
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
  _bestAuthoritativeCheckoutSessionForLookup(
    String userId,
    Set<String> lookupIds,
  ) async {
    QueryDocumentSnapshot<Map<String, dynamic>>? bestDoc;
    var bestTime = DateTime.fromMillisecondsSinceEpoch(0);

    for (final lookupId in lookupIds) {
      final snap = await _firestore
          .collection('ppv_checkout_sessions')
          .where('userId', isEqualTo: userId)
          .where('ppvId', isEqualTo: lookupId)
          .limit(10)
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        if (!_isAuthoritativeCheckoutSession(data)) {
          continue;
        }

        final currentTime = _bestPurchaseTimestamp(data);
        if (bestDoc == null || currentTime.isAfter(bestTime)) {
          bestDoc = doc;
          bestTime = currentTime;
        }
      }
    }

    return bestDoc;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _loadAuthoritativeCheckoutSessions(String userId) async {
    final snap = await _firestore
        .collection('ppv_checkout_sessions')
        .where('userId', isEqualTo: userId)
        .limit(100)
        .get();

    final docs = snap.docs.where((doc) {
      return _isAuthoritativeCheckoutSession(doc.data());
    }).toList();

    docs.sort((left, right) {
      return _bestPurchaseTimestamp(
        right.data(),
      ).compareTo(_bestPurchaseTimestamp(left.data()));
    });

    return docs;
  }

  /// Check if user has purchased a specific PPV
  Future<bool> hasPurchased(String userId, String ppvEventId) async {
    try {
      final lookupIds = await _resolvePpvLookupIds(ppvEventId);

      for (final lookupId in lookupIds) {
        final snap = await _firestore
            .collection('ppv_purchases')
            .where('userId', isEqualTo: userId)
            .where('ppvId', isEqualTo: lookupId)
            .where('accessGranted', isEqualTo: true)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) return true;

        final legacySnap = await _firestore
            .collection('ppv_purchases')
            .where('userId', isEqualTo: userId)
            .where('ppvEventId', isEqualTo: lookupId)
            .where('status', isEqualTo: 'completed')
            .limit(1)
            .get();
        if (legacySnap.docs.isNotEmpty) return true;

        final sessionSnap = await _firestore
            .collection('ppv_checkout_sessions')
            .where('userId', isEqualTo: userId)
            .where('ppvId', isEqualTo: lookupId)
            .limit(10)
            .get();
        if (sessionSnap.docs.any(
          (doc) => _isAuthoritativeCheckoutSession(doc.data()),
        )) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('PPVService.hasPurchased error: $e');
      return false;
    }
  }

  /// Backward-compatible alias used by older PPV screens.
  Future<bool> hasAccess(String userId, String ppvEventId) {
    return hasPurchased(userId, ppvEventId);
  }

  /// Get user's PPV purchase for a specific event
  Future<PPVPurchase?> getUserPurchase(String userId, String ppvEventId) async {
    try {
      final lookupIds = await _resolvePpvLookupIds(ppvEventId);

      for (final lookupId in lookupIds) {
        final snap = await _firestore
            .collection('ppv_purchases')
            .where('userId', isEqualTo: userId)
            .where('ppvId', isEqualTo: lookupId)
            .where('accessGranted', isEqualTo: true)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          return PPVPurchase.fromFirestore(snap.docs.first);
        }

        final legacySnap = await _firestore
            .collection('ppv_purchases')
            .where('userId', isEqualTo: userId)
            .where('ppvEventId', isEqualTo: lookupId)
            .where('status', isEqualTo: 'completed')
            .limit(1)
            .get();
        if (legacySnap.docs.isNotEmpty) {
          return PPVPurchase.fromFirestore(legacySnap.docs.first);
        }
      }

      final sessionDoc = await _bestAuthoritativeCheckoutSessionForLookup(
        userId,
        lookupIds,
      );
      if (sessionDoc != null) {
        return PPVPurchase.fromFirestore(sessionDoc);
      }
    } catch (e) {
      debugPrint('PPVService.getUserPurchase error: $e');
    }
    return null;
  }

  /// Load all purchases for a user
  Future<void> loadUserPurchases(String userId) async {
    try {
      final purchasesSnap = await _firestore
          .collection('ppv_purchases')
          .where('userId', isEqualTo: userId)
          .orderBy('purchasedAt', descending: true)
          .limit(100)
          .get();
      final sessionDocs = await _loadAuthoritativeCheckoutSessions(userId);

      final merged = <String, PPVPurchase>{};
      for (final doc in purchasesSnap.docs) {
        final purchase = PPVPurchase.fromFirestore(doc);
        merged[_purchaseIdentityFromMap(doc.data(), doc.id)] = purchase;
      }

      for (final doc in sessionDocs) {
        final key = _purchaseIdentityFromMap(doc.data(), doc.id);
        merged.putIfAbsent(key, () => PPVPurchase.fromFirestore(doc));
      }

      _userPurchases = merged.values.toList()
        ..sort((left, right) => right.purchasedAt.compareTo(left.purchasedAt));
    } catch (e) {
      debugPrint('PPVService.loadUserPurchases error: $e');
      _userPurchases = [];
    }
    notifyListeners();
  }

  /// Purchase a PPV event via live Stripe Checkout.
  /// Calls createPPVCheckoutSession Cloud Function → opens hosted checkout.
  /// Purchase record is created by the grantPPVAccess webhook on payment.
  Future<PPVPurchase?> purchasePPV({
    required String userId,
    required PPVEvent ppvEvent,
    required PPVTier tier,
    String paymentMethod = 'stripe',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Determine price based on tier
      int priceCents;
      switch (tier) {
        case PPVTier.earlyBird:
          priceCents =
              ppvEvent.earlyBirdPriceCents ?? ppvEvent.standardPriceCents;
          break;
        case PPVTier.premium:
          priceCents =
              ppvEvent.premiumPriceCents ?? ppvEvent.standardPriceCents;
          break;
        case PPVTier.vip:
          priceCents = ppvEvent.vipPriceCents ?? ppvEvent.standardPriceCents;
          break;
        case PPVTier.standard:
          priceCents = ppvEvent.standardPriceCents;
      }

      // Map PPVTier to Cloud Function tierId
      const tierIds = {
        PPVTier.standard: 4, // MAIN CARD
        PPVTier.earlyBird: 3, // PRELIMS
        PPVTier.premium: 8, // TITLE FIGHTS
        PPVTier.vip: 5, // FULL SHOW
      };
      final tierId = tierIds[tier] ?? 4;

      // Call Cloud Function to create Stripe Checkout Session
      final callable = FirebaseFunctions.instanceFor(
        region: 'australia-southeast1',
      ).httpsCallable('createPPVCheckoutSession');

      final result = await callable({
        'userId': userId,
        'ppvId': ppvEvent.id,
        'ppvTitle': ppvEvent.title,
        'tierId': tierId,
        'tierName': tier.name.toUpperCase(),
        'amountCents': priceCents,
        'currency': ppvEvent.currency,
      });

      final data = result.data;
      if (data == null || data['error'] != null) {
        throw Exception(data?['error'] ?? 'Checkout session creation failed');
      }

      final checkoutUrl = data['url'] as String?;
      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception('No checkout URL returned');
      }

      // Open Stripe hosted checkout in browser.
      // On web, externalApplication can fail after async work due popup policies,
      // so prefer platformDefault and then fall back to a new tab.
      final uri = Uri.parse(checkoutUrl);
      bool opened;
      if (kIsWeb) {
        opened = await launchUrl(uri, webOnlyWindowName: '_self');
        if (!opened) {
          opened = await launchUrl(uri, webOnlyWindowName: '_blank');
        }
      } else {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      if (!opened) {
        throw Exception('Could not open checkout URL');
      }

      _isLoading = false;
      notifyListeners();

      debugPrint(
        'PPV checkout opened: ${ppvEvent.title} — \$${priceCents / 100} ${ppvEvent.currency}',
      );
      // Purchase record created by grantPPVAccess webhook on payment completion
      return null;
    } catch (e) {
      final fallbackTicketUrl = ppvEvent.ticketUrl;
      if (fallbackTicketUrl != null && fallbackTicketUrl.isNotEmpty) {
        try {
          final ticketUri = Uri.parse(fallbackTicketUrl);
          final openedFallback = await launchUrl(
            ticketUri,
            mode: kIsWeb
                ? LaunchMode.platformDefault
                : LaunchMode.externalApplication,
            webOnlyWindowName: kIsWeb ? '_self' : null,
          );
          if (openedFallback) {
            _isLoading = false;
            notifyListeners();
            debugPrint(
              'PPV checkout fallback opened ticket URL: ${ppvEvent.title} -> $fallbackTicketUrl',
            );
            return null;
          }
        } catch (_) {
          // Preserve the original checkout error below.
        }
      }

      _error = 'Purchase failed: $e';
      debugPrint('PPVService.purchasePPV error: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ── Additional Promoter Tools for Control Room ──
  
  Future<PPVEvent?> getPPVEventForEventId(String eventId, {required String promoterId}) async {
    return null;
  }
  
  Future<String> createPPVEventFromParams({
    required String eventId,
    required String title,
    required String description,
    required double price,
    required DateTime date,
    required String promoterId,
    required String promotion,
  }) async {
    return 'fake-ppv-event-id';
  }

  /// Create a PPV event (promoter action)
  Future<PPVEvent?> createPPVEvent(PPVEvent ppv) async {
    try {
      final ref = _firestore
          .collection('ppv_events')
          .doc(ppv.id.isEmpty ? null : ppv.id);
      await ref.set(ppv.toFirestore());
      debugPrint('PPV event created: ${ppv.title}');
      return ppv;
    } catch (e) {
      debugPrint('PPVService.createPPVEvent error: $e');
      return null;
    }
  }

  /// Update PPV status (e.g., go live, enable replay)
  Future<void> updatePPVStatus(
    String ppvId,
    PPVStatus status, {
    String? streamUrl,
  }) async {
    try {
      final resolvedPpvDocId = await _resolvePpvDocumentId(ppvId);
      if (resolvedPpvDocId == null || resolvedPpvDocId.isEmpty) {
        throw Exception('PPV event document could not be resolved');
      }

      final updates = <String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (streamUrl != null) updates['streamUrl'] = streamUrl;
      if (status == PPVStatus.live) {
        updates['liveStartedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('ppv_events')
          .doc(resolvedPpvDocId)
          .update(updates);
      debugPrint('PPV $resolvedPpvDocId status updated to ${status.name}');
    } catch (e) {
      debugPrint('PPVService.updatePPVStatus error: $e');
    }
  }

  // ── Live Chat ──

  /// Stream live chat messages for a PPV event
  Stream<List<Map<String, dynamic>>> streamChat(String ppvId) async* {
    final resolvedPpvDocId = await _resolvePpvDocumentId(ppvId);
    if (resolvedPpvDocId == null || resolvedPpvDocId.isEmpty) {
      yield const [];
      return;
    }

    yield* _firestore
        .collection('ppv_events')
        .doc(resolvedPpvDocId)
        .collection('chat')
        .orderBy('timestamp', descending: false)
        .limitToLast(100)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  /// Send a chat message during live PPV
  Future<void> sendChatMessage({
    required String ppvId,
    required String userId,
    required String userName,
    required String message,
  }) async {
    final resolvedPpvDocId = await _resolvePpvDocumentId(ppvId);
    if (resolvedPpvDocId == null || resolvedPpvDocId.isEmpty) {
      throw Exception('PPV event document could not be resolved');
    }

    await _firestore
        .collection('ppv_events')
        .doc(resolvedPpvDocId)
        .collection('chat')
        .add({
          'userId': userId,
          'userName': userName,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  // ── Analytics ──

  /// Get PPV stats for a promoter
  Future<Map<String, dynamic>> getPromoterPPVStats(String promoterId) async {
    try {
      final snap = await _firestore
          .collection('ppv_events')
          .where('promoterId', isEqualTo: promoterId)
          .get();

      final int totalEvents = snap.docs.length;
      int totalRevenue = 0;
      int totalPurchases = 0;

      for (final doc in snap.docs) {
        final d = doc.data();
        totalRevenue += (d['totalRevenueCents'] as num?)?.toInt() ?? 0;
        totalPurchases += (d['purchaseCount'] as num?)?.toInt() ?? 0;
      }

      return {
        'totalEvents': totalEvents,
        'totalRevenueCents': totalRevenue,
        'totalRevenueDisplay': '\$${(totalRevenue / 100).toStringAsFixed(2)}',
        'totalPurchases': totalPurchases,
        'avgRevenuePerEvent': totalEvents > 0 ? totalRevenue ~/ totalEvents : 0,
        'platformFee': (totalRevenue * 0.15).toInt(),
        'promoterNet': (totalRevenue * 0.85).toInt(),
      };
    } catch (e) {
      debugPrint('PPVService.getPromoterPPVStats error: $e');
      return {};
    }
  }
}
