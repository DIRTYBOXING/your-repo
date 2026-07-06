import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/config/router_config.dart' as app_router;
import '../../../core/constants/image_assets.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/services/event_service.dart';
import '../../../shared/widgets/event_cards.dart';

/// FIGHT EVENTS - TrillerTV-style Event Hub v3.0
/// DesignTokens - Animated - Live/Featured/Upcoming - Search
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key, this.focusPromoterId});

  final String? focusPromoterId;

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  late final EventService _eventService;
  final PageController _featuredController = PageController(
    viewportFraction: 0.92,
  );

  List<EventModel> _featuredEvents = [];
  List<EventModel> _liveEvents = [];
  List<EventModel> _upcomingEvents = [];
  bool _isLoading = true;
  int _currentPage = 0;
  bool _depsInitialized = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<String> _categories = [
    'All',
    'MMA',
    'Boxing',
    'BKFC',
    'Kickboxing',
    'Pro Wrestling',
    'Muay Thai',
  ];
  String _selectedCategory = 'All';

  String? get _normalizedPromoterFilter {
    final raw = widget.focusPromoterId?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw.toLowerCase();
  }

  List<EventModel> _applyPromoterFilter(List<EventModel> events) {
    final promoterFilter = _normalizedPromoterFilter;
    if (promoterFilter == null) {
      return events;
    }

    return events
        .where((event) => event.promoterId.toLowerCase() == promoterFilter)
        .toList();
  }

  DateTime _eventStartTime(EventModel event) =>
      event.mainCardTime ?? event.eventDate;

  EventStatus _derivedLifecycleStatus(EventModel event) {
    switch (event.status) {
      case EventStatus.canceled:
      case EventStatus.archived:
      case EventStatus.completed:
      case EventStatus.results:
        return event.status;
      case EventStatus.draft:
      case EventStatus.announced:
      case EventStatus.onSale:
      case EventStatus.upcoming:
      case EventStatus.live:
        final now = DateTime.now();
        final scheduledStart = _eventStartTime(event);
        final liveWindowStart = scheduledStart.subtract(
          const Duration(minutes: 45),
        );
        final liveWindowEnd = scheduledStart.add(const Duration(hours: 6));

        if (now.isAfter(liveWindowEnd)) {
          return EventStatus.completed;
        }

        if (!now.isBefore(liveWindowStart) && !now.isAfter(liveWindowEnd)) {
          return EventStatus.live;
        }

        return EventStatus.upcoming;
    }
  }

  EventModel _copyWithStatus(EventModel event, EventStatus status) {
    return EventModel(
      id: event.id,
      promoterId: event.promoterId,
      name: event.name,
      description: event.description,
      venue: event.venue,
      city: event.city,
      state: event.state,
      country: event.country,
      eventDate: event.eventDate,
      mainCardTime: event.mainCardTime,
      sportType: event.sportType,
      status: status,
      posterUrl: event.posterUrl,
      broadcastInfo: event.broadcastInfo,
      ticketUrl: event.ticketUrl,
      isFeatured: event.isFeatured,
      fightIds: event.fightIds,
      promotionName: event.promotionName,
      source: event.source,
      imageIds: event.imageIds,
      sponsors: event.sponsors,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
    );
  }

  List<EventModel> _normalizeEvents(
    List<EventModel> events, {
    Set<EventStatus>? keepStatuses,
  }) {
    final normalized = events
        .map((event) => _copyWithStatus(event, _derivedLifecycleStatus(event)))
        .toList();

    if (keepStatuses == null) {
      return normalized;
    }

    return normalized
        .where((event) => keepStatuses.contains(event.status))
        .toList();
  }

  int _launchPriorityRank(EventModel event) {
    final promoter = event.promoterId.toLowerCase();
    final name = event.name.toLowerCase();
    final description = (event.description ?? '').toLowerCase();
    final sport = (event.sportType ?? '').toLowerCase();

    final isUltimate =
        promoter.contains('ultimate-legends') ||
        promoter.contains('team-ultimate') ||
        name.contains('ultimate legends') ||
        name.contains('team ultimate') ||
        description.contains('ultimate legends') ||
        description.contains('team ultimate');
    if (isUltimate) {
      return 0;
    }

    final isIbc =
        promoter == 'ibc' ||
        name.contains('ibc') ||
        description.contains('international brawling championship');
    if (isIbc) {
      return 1;
    }

    final isStrikingEvent =
        sport.contains('kickboxing') ||
        sport.contains('k1') ||
        sport.contains('muay thai') ||
        sport.contains('boxing') ||
        name.contains('kickboxing') ||
        name.contains('k1') ||
        name.contains('muay thai');
    if (isStrikingEvent) {
      return 2;
    }

    return 3;
  }

  List<EventModel> _prioritizeLaunchEvents(List<EventModel> events) {
    final indexed = events.indexed.toList();
    indexed.sort((a, b) {
      final rankCompare = _launchPriorityRank(
        a.$2,
      ).compareTo(_launchPriorityRank(b.$2));
      if (rankCompare != 0) {
        return rankCompare;
      }
      // Preserve original order within the same priority tier.
      return a.$1.compareTo(b.$1);
    });
    return indexed.map((entry) => entry.$2).toList();
  }

  // ── Replay data with real event names + images ─────────────────
  static const _replayData = <(String, String, Color, String)>[
    (
      'UFC 313: Pereira vs Ankalaev',
      'Main Card · Mar 8 2025',
      Color(0xFF00F5FF),
      'assets/dfc_backgrounds/dfc_and_back_ground.png',
    ),
    (
      'Serrano vs Taylor II: MSG',
      'Women\'s Boxing · Nov 2025',
      Color(0xFFFF0080),
      'assets/dfc_backgrounds/new_dfc_image_1.png',
    ),
    (
      'ONE Friday Fights 68: Bangkok',
      'Muay Thai · Feb 2026',
      Color(0xFFFF0080),
      'assets/dfc_backgrounds/dfc2_image_.png',
    ),
    (
      'BKFC KnuckleMania V: Tampa',
      'Full Replay · Jan 2026',
      Color(0xFFFF8800),
      'assets/dfc_backgrounds/dfc2_image.png',
    ),
    (
      'UFC Fight Night: Moreno vs Albazi',
      'ESPN+ · Feb 2026',
      Color(0xFF00F5FF),
      'assets/dfc_backgrounds/datafight_central_with_logo.png',
    ),
    (
      'PFL Champions vs Bellator Champions',
      'Super Card · Dec 2025',
      Color(0xFFFF9100),
      'assets/dfc_backgrounds/datafightlogo.png',
    ),
    (
      'UFC 314: Makhachev vs Oliveira 2',
      'ESPN+ PPV · Apr 2026',
      Color(0xFF00F5FF),
      'assets/dfc_backgrounds/dfc_logo_resized.png',
    ),
    (
      'GLORY 92: Heavyweight GP Rotterdam',
      'Kickboxing · Mar 2026',
      Color(0xFF2979FF),
      'assets/dfc_backgrounds/dfc_logo_resized.png',
    ),
    (
      'Inoue vs Goodman: Tokyo Dome',
      'Boxing · Apr 2026',
      Color(0xFFE040FB),
      'assets/dfc_backgrounds/new_dfc_image_1.png',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsInitialized) {
      _depsInitialized = true;
      _eventService = context.read<EventService>();
      _loadEvents();
    }
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Demo fallback data (used when Firestore is empty) ───────────
  static final _demoFeatured = [
    EventModel(
      id: 'ufc-314',
      promoterId: 'ufc',
      name: 'UFC 314: Makhachev vs Oliveira 2',
      venue: 'T-Mobile Arena',
      city: 'Las Vegas',
      country: 'USA',
      eventDate: DateTime.now().add(const Duration(days: 42)),
      mainCardTime: DateTime.now().add(const Duration(days: 42, hours: 22)),
      sportType: 'mma',
      isFeatured: true,
      broadcastInfo: 'ESPN+ PPV',
      fightIds: [],
      posterUrl: 'assets/dfc_backgrounds/dfc_logo_resized.png',
    ),
    EventModel(
      id: 'canelo-vs-benavidez',
      promoterId: 'pbc',
      name: 'Canelo Alvarez vs David Benavidez',
      venue: 'T-Mobile Arena',
      city: 'Las Vegas',
      country: 'USA',
      eventDate: DateTime.now().add(const Duration(days: 56)),
      sportType: 'boxing',
      isFeatured: true,
      broadcastInfo: 'Amazon Prime PPV',
      fightIds: [],
      posterUrl: 'assets/dfc_backgrounds/datafightlogo.png',
    ),
    EventModel(
      id: 'one-fight-night-30',
      promoterId: 'one',
      name: 'ONE Fight Night 30: Superbon vs Grigorian',
      venue: 'Impact Arena',
      city: 'Bangkok',
      country: 'Thailand',
      eventDate: DateTime.now().add(const Duration(days: 14)),
      sportType: 'mma',
      isFeatured: true,
      broadcastInfo: 'Amazon Prime Video',
      fightIds: [],
      posterUrl: 'assets/dfc_backgrounds/dfc2_image.png',
    ),
  ];

  static final _demoLive = [
    EventModel(
      id: 'ufc-fight-night-live',
      promoterId: 'ufc',
      name: 'UFC Fight Night: Strickland vs Du Plessis 2',
      venue: 'UFC APEX',
      city: 'Las Vegas',
      country: 'USA',
      eventDate: DateTime.now(),
      sportType: 'mma',
      status: EventStatus.live,
      broadcastInfo: 'ESPN+',
      fightIds: [],
      posterUrl: 'assets/dfc_backgrounds/datafight_central_with_logo.png',
    ),
    EventModel(
      id: 'one-friday-fights-live',
      promoterId: 'one',
      name: 'ONE Friday Fights 71: Bangkok',
      venue: 'Lumpinee Boxing Stadium',
      city: 'Bangkok',
      country: 'Thailand',
      eventDate: DateTime.now(),
      sportType: 'muay thai',
      status: EventStatus.live,
      broadcastInfo: 'YouTube / ONE App',
      fightIds: [],
      posterUrl: 'assets/dfc_backgrounds/dfc_and_back_ground.png',
    ),
  ];

  static final _demoUpcoming = [
    // ── UFC (source: espn.com/mma/schedule) ──
    EventModel(
      id: 'ufc-fn-march-15',
      promoterId: 'ufc',
      name: 'UFC Fight Night: Allen vs Imavov',
      venue: 'UFC APEX',
      city: 'Las Vegas',
      country: 'USA',
      eventDate: DateTime.now().add(const Duration(days: 10)),
      sportType: 'mma',
      broadcastInfo: 'ESPN+',
      fightIds: [],
      posterUrl: ImageAssets.bgAction,
    ),
    EventModel(
      id: 'ufc-fn-march-22',
      promoterId: 'ufc',
      name: 'UFC Fight Night: Moreno vs Royval 2',
      venue: 'UFC APEX',
      city: 'Las Vegas',
      country: 'USA',
      eventDate: DateTime.now().add(const Duration(days: 17)),
      sportType: 'mma',
      broadcastInfo: 'ESPN+',
      fightIds: [],
      posterUrl: ImageAssets.bgAction,
    ),
    EventModel(
      id: 'ufc-314-april',
      promoterId: 'ufc',
      name: 'UFC 314: Makhachev vs Oliveira 2',
      venue: 'T-Mobile Arena',
      city: 'Las Vegas',
      country: 'USA',
      eventDate: DateTime.now().add(const Duration(days: 42)),
      sportType: 'mma',
      isFeatured: true,
      broadcastInfo: 'ESPN+ PPV',
      fightIds: [],
      posterUrl: ImageAssets.bgAction,
    ),
    EventModel(
      id: 'ufc-315-may',
      promoterId: 'ufc',
      name: 'UFC 315: Pereira vs Ankalaev 2',
      venue: 'Jeunesse Arena',
      city: 'Rio de Janeiro',
      country: 'Brazil',
      eventDate: DateTime.now().add(const Duration(days: 70)),
      sportType: 'mma',
      broadcastInfo: 'ESPN+ PPV',
      fightIds: [],
      posterUrl: ImageAssets.bgAction,
    ),
    // ── Boxing (source: boxingscene.com/schedule) ──
    EventModel(
      id: 'canelo-benavidez',
      promoterId: 'pbc',
      name: 'Canelo Alvarez vs David Benavidez',
      venue: 'T-Mobile Arena',
      city: 'Las Vegas',
      country: 'USA',
      eventDate: DateTime.now().add(const Duration(days: 56)),
      sportType: 'boxing',
      isFeatured: true,
      broadcastInfo: 'Amazon Prime PPV',
      fightIds: [],
      posterUrl: ImageAssets.bgEvent,
    ),
    EventModel(
      id: 'inoue-goodman',
      promoterId: 'toprank',
      name: 'Naoya Inoue vs TJ Doheny',
      venue: 'Tokyo Dome',
      city: 'Tokyo',
      country: 'Japan',
      eventDate: DateTime.now().add(const Duration(days: 49)),
      sportType: 'boxing',
      broadcastInfo: 'ESPN+ / WOWOW',
      fightIds: [],
      posterUrl: ImageAssets.bgEvent,
    ),
    EventModel(
      id: 'crawford-madrimov',
      promoterId: 'tr',
      name: 'Terence Crawford vs Israil Madrimov',
      venue: 'Madison Square Garden',
      city: 'New York',
      country: 'USA',
      eventDate: DateTime.now().add(const Duration(days: 35)),
      sportType: 'boxing',
      broadcastInfo: 'ESPN+ PPV',
      fightIds: [],
      posterUrl: ImageAssets.bgEvent,
    ),
    // ── ONE Championship (source: mmanews.com/events) ──
    EventModel(
      id: 'one-fight-night-30',
      promoterId: 'one',
      name: 'ONE Fight Night 30: Superbon vs Grigorian',
      venue: 'Impact Arena',
      city: 'Bangkok',
      country: 'Thailand',
      eventDate: DateTime.now().add(const Duration(days: 14)),
      sportType: 'mma',
      broadcastInfo: 'Amazon Prime Video',
      fightIds: [],
      posterUrl: ImageAssets.bgAction,
    ),
    EventModel(
      id: 'one-friday-fights-72',
      promoterId: 'one',
      name: 'ONE Friday Fights 72: Lumpinee',
      venue: 'Lumpinee Boxing Stadium',
      city: 'Bangkok',
      country: 'Thailand',
      eventDate: DateTime.now().add(const Duration(days: 9)),
      sportType: 'muay thai',
      broadcastInfo: 'YouTube / ONE Super App',
      fightIds: [],
      posterUrl: ImageAssets.bgCentral,
    ),
    // ── PFL (source: mmanews.com/events) ──
    EventModel(
      id: 'pfl-2-2026',
      promoterId: 'pfl',
      name: 'PFL 2: 2026 Season — Heavyweights & Featherweights',
      venue: 'Seminole Hard Rock',
      city: 'Hollywood',
      state: 'FL',
      country: 'USA',
      eventDate: DateTime.now().add(const Duration(days: 21)),
      sportType: 'mma',
      broadcastInfo: 'ESPN / ESPN+',
      fightIds: [],
      posterUrl: ImageAssets.bgAction,
    ),
    // ── Kickboxing ──
    EventModel(
      id: 'glory-92',
      promoterId: 'glory',
      name: 'GLORY 92: Rotterdam — Heavyweight Grand Prix',
      venue: 'Rotterdam Ahoy',
      city: 'Rotterdam',
      country: 'Netherlands',
      eventDate: DateTime.now().add(const Duration(days: 28)),
      sportType: 'kickboxing',
      broadcastInfo: 'GLORY Fights App',
      fightIds: [],
      posterUrl: ImageAssets.bgPromo,
    ),
    EventModel(
      id: 'k1-gp-2026',
      promoterId: 'k1',
      name: 'K-1 World Grand Prix 2026: Quarterfinals',
      venue: 'Saitama Super Arena',
      city: 'Saitama',
      country: 'Japan',
      eventDate: DateTime.now().add(const Duration(days: 60)),
      sportType: 'kickboxing',
      broadcastInfo: 'K-1 App / ABEMA',
      fightIds: [],
      posterUrl: ImageAssets.bgPromo,
    ),
    // ── Aussie / NZ Events (source: fight.com.au) ──
    EventModel(
      id: 'hex-27-brisbane',
      promoterId: 'hex',
      name: 'Hex Fight Series 27: Collision',
      venue: 'Brisbane Convention Centre',
      city: 'Brisbane',
      country: 'Australia',
      eventDate: DateTime.now().add(const Duration(days: 10)),
      sportType: 'mma',
      broadcastInfo: 'UFC Fight Pass',
      fightIds: [],
      posterUrl: ImageAssets.bgAction,
    ),
    EventModel(
      id: 'rajadamnern-gp',
      promoterId: 'rajadamnern',
      name: 'Rajadamnern World Series: GP Finals',
      venue: 'Rajadamnern Stadium',
      city: 'Bangkok',
      country: 'Thailand',
      eventDate: DateTime.now().add(const Duration(days: 10)),
      sportType: 'muay thai',
      broadcastInfo: 'YouTube / ONE Super App',
      fightIds: [],
      posterUrl: ImageAssets.bgCentral,
    ),
    EventModel(
      id: 'demo-ckb-open',
      promoterId: 'ckb',
      name: 'Summit Fight Academy Open: Auckland',
      venue: 'Spark Arena',
      city: 'Auckland',
      country: 'New Zealand',
      eventDate: DateTime.now().add(const Duration(days: 11)),
      sportType: 'mma',
      broadcastInfo: 'Sky Sport NZ',
      fightIds: [],
      posterUrl: ImageAssets.bgAction,
    ),
    // ── Australian Muay Thai 2026 (source: ausmuaythai.com.au, wbcmuaythai.com) ──
    EventModel(
      id: 'destiny-muaythai-30',
      promoterId: 'destiny-mt',
      name: 'Destiny Muay Thai 30',
      venue: 'TBA',
      city: 'Gold Coast',
      state: 'QLD',
      country: 'Australia',
      eventDate: DateTime.now().add(const Duration(days: 24)),
      sportType: 'muay thai',
      broadcastInfo: 'PPV / Aus Muay Thai',
      fightIds: [],
      posterUrl: ImageAssets.bgCentral,
    ),
    EventModel(
      id: 'mt-super-series-4',
      promoterId: 'mtss',
      name: 'Muay Thai Super Series 4',
      venue: 'TBA',
      city: 'Sydney',
      state: 'NSW',
      country: 'Australia',
      eventDate: DateTime.now().add(const Duration(days: 32)),
      sportType: 'muay thai',
      broadcastInfo: 'PPV / Aus Muay Thai',
      fightIds: [],
      posterUrl: ImageAssets.bgCentral,
    ),
    EventModel(
      id: 'infinity-fight-series',
      promoterId: 'infinity',
      name: 'Infinity Fight Series: Perth',
      venue: 'RAC Arena',
      city: 'Perth',
      state: 'WA',
      country: 'Australia',
      eventDate: DateTime.now().add(const Duration(days: 38)),
      sportType: 'muay thai',
      broadcastInfo: 'PPV',
      fightIds: [],
      posterUrl: ImageAssets.bgCentral,
    ),
    EventModel(
      id: 'ufc-perth-2026',
      promoterId: 'ufc',
      name: 'UFC Fight Night: Della Maddalena vs Prates',
      description:
          'First-ever UFC Fight Night in Perth. WA\'s Jack Della Maddalena headlines against Carlos Prates at RAC Arena.',
      venue: 'RAC Arena',
      city: 'Perth',
      state: 'WA',
      country: 'Australia',
      eventDate: DateTime.now().add(const Duration(days: 57)),
      sportType: 'mma',
      isFeatured: true,
      broadcastInfo: 'ESPN+ / Kayo Sports',
      fightIds: [],
      posterUrl: ImageAssets.bgAction,
    ),
    EventModel(
      id: 'eternal-mma-perth-80',
      promoterId: 'eternal',
      name: 'Eternal MMA 80: Perth',
      description:
          'Australia\'s premier MMA promotion brings a stacked 16-fight card to Perth. WA vs QLD superfight series.',
      venue: 'HBF Stadium',
      city: 'Perth',
      state: 'WA',
      country: 'Australia',
      eventDate: DateTime.now().add(const Duration(days: 44)),
      sportType: 'mma',
      broadcastInfo: 'UFC Fight Pass',
      fightIds: [],
      posterUrl: ImageAssets.bgAction,
    ),
    EventModel(
      id: 'ibc-03-gold-coast',
      promoterId: 'ibc',
      name: 'IBC 03: International Brawling Championship',
      description:
          'Australia\'s fastest-growing combat sport returns to the Gold Coast. Closed-fist hybrid format — no grappling, all action. Danny Mac\'s \$1B brawling dream.',
      venue: 'Gold Coast Sports & Leisure Centre',
      city: 'Gold Coast',
      state: 'QLD',
      country: 'Australia',
      eventDate: DateTime(2026, 3, 7, 19),
      sportType: 'brawling',
      isFeatured: true,
      broadcastInfo: 'TrillerTV+ / Kayo Sports PPV',
      fightIds: [],
      posterUrl: ImageAssets.bgSquare,
    ),
    EventModel(
      id: 'ibc-04-las-vegas',
      promoterId: 'ibc',
      name: 'IBC 04: Las Vegas (Announced)',
      description:
          'The International Brawling Championship goes global — first international event in Las Vegas. Danny Mac\'s vision takes on the fight capital of the world.',
      venue: 'TBA',
      city: 'Las Vegas',
      state: 'NV',
      country: 'USA',
      eventDate: DateTime.now().add(const Duration(days: 120)),
      sportType: 'brawling',
      broadcastInfo: 'TrillerTV+ PPV',
      fightIds: [],
      posterUrl: ImageAssets.bgSquare,
    ),
    EventModel(
      id: 'elite-fight-series-cairns',
      promoterId: 'efs',
      name: 'Elite Fight Series: Cairns',
      description:
          'North QLD\'s premier fight show livestreamed by Cairns Post. Explosive MMA, Muay Thai & Boxing action from Far North Queensland.',
      venue: 'Cairns Convention Centre',
      city: 'Cairns',
      state: 'QLD',
      country: 'Australia',
      eventDate: DateTime.now().add(const Duration(days: 30)),
      sportType: 'mma',
      broadcastInfo: 'Cairns Post Livestream',
      fightIds: [],
      posterUrl: ImageAssets.bgAction,
    ),
    EventModel(
      id: 'adrenalyn-mfc-8',
      promoterId: 'mfc',
      name: 'Adrenalyn Fight Circuit: MFC 8',
      description:
          'Muay Thai, Boxing & MMA from Brisbane\'s southside. Logan\'s grassroots combat sports showcase returns with 16 bouts.',
      venue: 'Logan Metro Sports Centre',
      city: 'Logan',
      state: 'QLD',
      country: 'Australia',
      eventDate: DateTime.now().add(const Duration(days: 16)),
      sportType: 'mma',
      broadcastInfo: 'Live Only',
      fightIds: [],
      posterUrl: ImageAssets.bgAction,
    ),
    EventModel(
      id: 'empire-fight-series-5',
      promoterId: 'empire',
      name: 'Empire Fight Series: Inception 5',
      description:
          'WA vs QLD national Muay Thai showdown at Claremont Showground. Cian Lougheed (WA) vs Jaga Chan headline.',
      venue: 'Claremont Showground',
      city: 'Perth',
      state: 'WA',
      country: 'Australia',
      eventDate: DateTime.now().add(const Duration(days: 100)),
      sportType: 'muay thai',
      broadcastInfo: 'PPV',
      fightIds: [],
      posterUrl: ImageAssets.bgCentral,
    ),
    EventModel(
      id: 'west-coast-fight-shows-12',
      promoterId: 'wcfs',
      name: 'West Coast Fight Shows 12',
      description:
          'Perth\'s grassroots combat sports showcase — Muay Thai, MMA, and Boxing triple header at Metro City.',
      venue: 'Metro City',
      city: 'Perth',
      state: 'WA',
      country: 'Australia',
      eventDate: DateTime.now().add(const Duration(days: 79)),
      sportType: 'mma',
      broadcastInfo: 'Live Only',
      fightIds: [],
      posterUrl: ImageAssets.bgAction,
    ),
    // ── Korakuen Hall, Tokyo — IBF World Atom + Title Fights (source: boxrec.com) ──
    EventModel(
      id: 'korakuen-apr-2026',
      promoterId: 'jbc',
      name: 'Korakuen Hall: IBF World Atomweight Title',
      description:
          'Six-bout all-title card headlined by IBF World Atomweight Title (vacant). '
          'Sumire Yamanaka (9-1-0) vs Nao Ugawa (6-0-0). '
          'Plus WBO Asia Pacific Atom, OPBF Atom, JBC Japanese Bantam, '
          'WBO Asia Pacific Minimum. Korakuen Hall, Tokyo.',
      venue: 'Korakuen Hall',
      city: 'Tokyo',
      state: 'Tokyo',
      country: 'Japan',
      eventDate: DateTime(2026, 4, 7, 18),
      sportType: 'boxing',
      status: EventStatus.live,
      isFeatured: true,
      broadcastInfo: 'DAZN Japan',
      fightIds: [],
      posterUrl: ImageAssets.bgEvent,
    ),
    EventModel(
      id: 'pfl-australia-2026',
      promoterId: 'pfl',
      name: 'PFL Australia: Wilkinson vs TBA',
      description:
          'PFL expands to Australia featuring Rob Wilkinson, Sean Gauci, and local MMA stars.',
      venue: 'ICC Sydney',
      city: 'Sydney',
      state: 'NSW',
      country: 'Australia',
      eventDate: DateTime.now().add(const Duration(days: 50)),
      sportType: 'mma',
      broadcastInfo: 'ESPN / ESPN+',
      fightIds: [],
      posterUrl: ImageAssets.bgAction,
    ),
    EventModel(
      id: 'opetaia-defense-2026',
      promoterId: 'matchroom',
      name: 'Jai Opetaia IBF Cruiserweight Title Defense',
      description:
          'Australia\'s IBF Cruiserweight champion Jai Opetaia defends his title on home soil.',
      venue: 'Qudos Bank Arena',
      city: 'Sydney',
      state: 'NSW',
      country: 'Australia',
      eventDate: DateTime.now().add(const Duration(days: 45)),
      sportType: 'boxing',
      broadcastInfo: 'DAZN / Kayo Sports',
      fightIds: [],
      posterUrl: ImageAssets.bgEvent,
    ),
    // ── Ultimate Legends — WBC Silver Australian Title (source: ultimatelegends.com.au, boxrec.com) ──
    EventModel(
      id: 'ultimate-legends-apr-2026',
      promoterId: 'ultimate-legends',
      name: 'Ultimate Legends Fight Night: WBC Silver Australian Title',
      description:
          'Melbourne\'s premier combat sports event since 1992. WBC Silver Australian Title headlines an action-packed card of professional Boxing, K1, Kickboxing & Muay Thai. Official hub: ultimatelegends.com.au. Main Event: Jordan Roesler. Livestream via Live Combat Sports. Buy early and lock your seats.',
      venue: 'Melbourne Pavilion',
      city: 'Melbourne',
      state: 'VIC',
      country: 'Australia',
      eventDate: DateTime(2026, 4, 24, 18),
      sportType: 'boxing',
      isFeatured: true,
      broadcastInfo: 'Live Combat Sports / Livestream',
      fightIds: [],
      ticketUrl: 'https://ultimatelegends.com.au',
      posterUrl: ImageAssets.ppvUltimateLegends2026Hero,
    ),
  ];

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    final featured = await _eventService.getFeaturedEvents();
    final live = await _eventService.getLiveEvents();
    final upcoming = await _eventService.getUpcomingEvents(
      sportType: _selectedCategory == 'All' ? null : _selectedCategory,
    );

    // Use live data; fall back to demo only when Firestore returns nothing
    final effectiveFeatured = featured.isNotEmpty ? featured : _demoFeatured;
    final effectiveLive = live.isNotEmpty ? live : _demoLive;
    final effectiveUpcoming = upcoming.isNotEmpty
        ? upcoming
        : (_selectedCategory == 'All'
              ? _demoUpcoming
              : _demoUpcoming
                    .where(
                      (e) =>
                          (e.sportType ?? '').toLowerCase() ==
                          _selectedCategory.toLowerCase(),
                    )
                    .toList());

    final featuredEvents = _normalizeEvents(
      _applyPromoterFilter(effectiveFeatured),
      keepStatuses: {EventStatus.upcoming, EventStatus.live},
    );
    final liveEvents = _normalizeEvents(
      _applyPromoterFilter(effectiveLive),
      keepStatuses: {EventStatus.live},
    );
    final upcomingEvents = _normalizeEvents(
      _applyPromoterFilter(effectiveUpcoming),
      keepStatuses: {EventStatus.upcoming},
    );

    setState(() {
      _featuredEvents = _prioritizeLaunchEvents(featuredEvents);
      _liveEvents = _prioritizeLaunchEvents(liveEvents);
      _upcomingEvents = _prioritizeLaunchEvents(upcomingEvents);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push(app_router.RouteConstants.eventsCreatePath),
        backgroundColor: DesignTokens.neonCyan,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'CREATE EVENT',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: _isLoading ? _buildLoading() : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.neonCyan),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadEvents,
      color: DesignTokens.neonCyan,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: DesignTokens.bgPrimary,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
                    ),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusSmall,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.live_tv,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'FIGHT EVENTS',
                      style: TextStyle(
                        color: DesignTokens.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      'Live & Upcoming',
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.search,
                  color: DesignTokens.textSecondary,
                ),
                onPressed: _showSearch,
              ),
              IconButton(
                icon: const Icon(
                  Icons.calendar_month,
                  color: DesignTokens.textSecondary,
                ),
                onPressed: _showSchedule,
              ),
            ],
          ),

          // Live Events Banner
          if (_liveEvents.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                children: _liveEvents
                    .map(
                      (e) =>
                          LiveEventStrip(event: e, onTap: () => _openEvent(e)),
                    )
                    .toList(),
              ),
            ),

          SliverToBoxAdapter(child: _buildRolloutAnnouncementBanner()),

          // Featured Events Carousel
          if (_featuredEvents.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: DesignTokens.spacingXL),
                  SizedBox(
                    height: 280,
                    child: PageView.builder(
                      controller: _featuredController,
                      itemCount: _featuredEvents.length,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemBuilder: (context, index) {
                        return FeaturedEventCard(
                          event: _featuredEvents[index],
                          onTap: () => _openEvent(_featuredEvents[index]),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _featuredEvents.length,
                      (i) => Container(
                        width: _currentPage == i ? 20 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? DesignTokens.neonCyan
                              : DesignTokens.textDisabled,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ══════════════════════════════════════════════════════════════
          // EVENT CONVEYOR BELT — Living timeline
          // New events build up → approaching glow → LIVE pulse →
          // finished events fade out
          // ══════════════════════════════════════════════════════════════
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingL,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: DesignTokens.neonMagenta.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.conveyor_belt,
                          color: DesignTokens.neonMagenta,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EVENT CONVEYOR',
                              style: TextStyle(
                                color: DesignTokens.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'Building up \u2192 Live \u2192 Fading out',
                              style: TextStyle(
                                color: DesignTokens.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                EventConveyorBelt(
                  events: [..._liveEvents, ..._upcomingEvents],
                  onEventTap: _openEvent,
                ),
              ],
            ),
          ),

          // Category Filter
          SliverToBoxAdapter(
            child: Container(
              height: 50,
              margin: const EdgeInsets.only(top: DesignTokens.spacingXXL),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingL,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      _loadEvents();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                            : DesignTokens.bgCard,
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusPill,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? DesignTokens.neonCyan
                              : DesignTokens.textDisabled,
                          width: DesignTokens.borderThin,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected
                              ? DesignTokens.neonCyan
                              : DesignTokens.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: DesignTokens.fontSizeSubtitleLarge,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          SliverToBoxAdapter(child: _buildFightersRespectBanner()),

          // Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.spacingL,
                DesignTokens.spacingXXL,
                DesignTokens.spacingL,
                DesignTokens.spacingM,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Top Live & Upcoming',
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: DesignTokens.fontSizeTitle,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _showSchedule,
                    child: const Text(
                      'Schedule',
                      style: TextStyle(
                        color: DesignTokens.neonCyan,
                        fontSize: DesignTokens.fontSizeSubtitleLarge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Upcoming Events Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingL,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: DesignTokens.spacingM,
                mainAxisSpacing: DesignTokens.spacingM,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index >= _upcomingEvents.length) return null;
                return EventCard(
                  event: _upcomingEvents[index],
                  onTap: () => _openEvent(_upcomingEvents[index]),
                );
              }, childCount: _upcomingEvents.length),
            ),
          ),

          // Replays Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.spacingL,
                32,
                DesignTokens.spacingL,
                DesignTokens.spacingM,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Replays',
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: DesignTokens.fontSizeTitle,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Loading full replay library...'),
                          backgroundColor: DesignTokens.neonCyan.withValues(
                            alpha: 0.9,
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text(
                      'More Replays',
                      style: TextStyle(
                        color: DesignTokens.neonCyan,
                        fontSize: DesignTokens.fontSizeSubtitleLarge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Replays horizontal list
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: Builder(
                builder: (context) {
                  // All sanctioned replays shown — BKFC is combat sport.
                  final replays = _replayData;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingL,
                    ),
                    itemCount: replays.length,
                    itemBuilder: (context, index) {
                      final replay = replays[index];
                      return GestureDetector(
                        onTap: () => _openReplayEvent(replay.$1),
                        child: Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: DesignTokens.bgCard,
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusSmall,
                            ),
                            border: Border.all(
                              color: replay.$3.withValues(alpha: 0.15),
                              width: DesignTokens.borderThin,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 100,
                                clipBehavior: Clip.antiAlias,
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(
                                      DesignTokens.radiusSmall,
                                    ),
                                  ),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (replay.$4.isNotEmpty)
                                      ImageAssets.isLocalAsset(replay.$4)
                                          ? Image.asset(
                                              replay.$4,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          replay.$3.withValues(
                                                            alpha: 0.25,
                                                          ),
                                                          DesignTokens.bgCard,
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                            )
                                          : DfcNetworkImage(url: replay.$4)
                                    else
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              replay.$3.withValues(alpha: 0.25),
                                              DesignTokens.bgCard,
                                            ],
                                          ),
                                        ),
                                      ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.5),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.4,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.play_arrow,
                                          color: replay.$3,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      replay.$2,
                                      style: TextStyle(
                                        color: replay.$3.withValues(alpha: 0.7),
                                        fontSize: DesignTokens.fontSizeMicro,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      replay.$1,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: DesignTokens.textPrimary,
                                        fontSize: DesignTokens.fontSizeSubtitle,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildRolloutAnnouncementBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        DesignTokens.spacingL,
        DesignTokens.spacingL,
        DesignTokens.spacingL,
        0,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF0000), Color(0xFF00D4FF)],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4FF).withValues(alpha: 0.22),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DFC IS EXCITED TO ANNOUNCE IBC III',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'First rollout: DFC powers promotion from the back while Danny Mac and IBC hold center stage. This is our model for all events going forward.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Global push: Australia • New Zealand • USA • UK • Europe • Asia • Middle East • Africa • Latin America',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 10,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFightersRespectBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        DesignTokens.spacingL,
        DesignTokens.spacingL,
        DesignTokens.spacingL,
        0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.3),
          width: DesignTokens.borderThin,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events,
            color: DesignTokens.neonCyan,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Lights. Camera. Action. Respect to every fighter for proud effort and amazing work — every card, every country, every event.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openEvent(EventModel event) {
    context.push(
      '${app_router.RouteConstants.eventDetailsBasePath}/${event.id}',
    );
  }

  void _openReplayEvent(String replayTitle) {
    final all = [..._featuredEvents, ..._liveEvents, ..._upcomingEvents];
    final replay = replayTitle.toLowerCase();

    for (final event in all) {
      final name = event.name.toLowerCase();
      if (name == replay || name.contains(replay) || replay.contains(name)) {
        _openEvent(event);
        return;
      }
    }

    _showSchedule();
  }

  void _showSearch() {
    showSearch(context: context, delegate: EventSearchDelegate(_eventService));
  }

  void _showSchedule() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final all = [..._featuredEvents, ..._upcomingEvents];
        all.sort((a, b) => a.eventDate.compareTo(b.eventDate));
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          builder: (ctx, ctrl) => ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'FULL SCHEDULE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${all.length} upcoming events',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              ...all.map(
                (e) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${e.eventDate.day}',
                              style: const TextStyle(
                                color: DesignTokens.neonCyan,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              _monthAbbr(e.eventDate.month),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${e.venue}, ${e.city}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (e.broadcastInfo != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.neonCyan.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            e.broadcastInfo!,
                            style: const TextStyle(
                              color: DesignTokens.neonCyan,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _monthAbbr(int m) {
    const months = [
      '',
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[m.clamp(1, 12)];
  }
}

/// Event Search Delegate
class EventSearchDelegate extends SearchDelegate<EventModel?> {
  final EventService eventService;

  EventSearchDelegate(this.eventService);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: DesignTokens.bgPrimary,
      appBarTheme: const AppBarTheme(
        backgroundColor: DesignTokens.bgPrimary,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: DesignTokens.textMuted),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: DesignTokens.textDisabled),
            SizedBox(height: 16),
            Text(
              'Search for events, promotions, fighters...',
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeBody,
              ),
            ),
          ],
        ),
      );
    }
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<EventModel>>(
      future: eventService.getUpcomingEvents(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: DesignTokens.neonCyan),
          );
        }

        final events = snapshot.data!
            .where((e) => e.name.toLowerCase().contains(query.toLowerCase()))
            .toList();

        if (events.isEmpty) {
          return const Center(
            child: Text(
              'No events found',
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeBody,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.event, color: DesignTokens.neonCyan),
              ),
              title: Text(
                event.name,
                style: const TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeBody,
                ),
              ),
              subtitle: Text(
                '${event.sportType} \u2022 ${event.fullLocation}',
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeSubtitle,
                ),
              ),
              onTap: () => close(context, event),
            );
          },
        );
      },
    );
  }
}
