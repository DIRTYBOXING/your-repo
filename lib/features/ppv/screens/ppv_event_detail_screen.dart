import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/image_assets.dart';
import '../../../core/utils/web_route_test_hook.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/ppv_model.dart';
import '../../../shared/models/ppv_presentation_model.dart';
import '../../../shared/services/ppv_service.dart';
import '../../../shared/widgets/regional_where_to_watch.dart';
import '../../../shared/services/n8n_service.dart';
import '../widgets/fight_card_poster.dart';
import '../widgets/ppv_buy_button_dom_overlay.dart';
import '../widgets/ppv_checkout_sheet.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV EVENT DETAIL SCREEN — GLOBE ZOOM + PREMIUM FIGHT CARD
/// ═══════════════════════════════════════════════════════════════════════════
///
/// The ULTIMATE PPV presentation page. When users tap on a PPV event,
/// this screen delivers a cinematic experience:
///
///   1. GLOBE ZOOM — Earth zooms to event location (Melbourne, Manila, etc.)
///   2. FIGHT CARD — Premium VS-style fighter matchups
///   3. COUNTDOWN — Live timer to event start
///   4. PRICING TIERS — Singles, Main Card, Full Card
///   5. PAYMENT OPTIONS — Stripe, Afterpay, Zip, PayPal
///   6. PROMO CONTENT — Ring girls, highlights, region targeting
///
/// Built to compete with UFC, DAZN, and Triller. DFC style.
/// ═══════════════════════════════════════════════════════════════════════════

class PPVEventDetailScreen extends StatefulWidget {
  final String ppvId;
  final PPVEvent? preloadedEvent;

  const PPVEventDetailScreen({
    super.key,
    required this.ppvId,
    this.preloadedEvent,
  });

  @override
  State<PPVEventDetailScreen> createState() => _PPVEventDetailScreenState();
}

class _PPVEventDetailScreenState extends State<PPVEventDetailScreen>
    with TickerProviderStateMixin {
  final PPVService _ppvService = PPVService();

  // ── Animation Controllers ──
  late AnimationController _globeZoomCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _cardRevealCtrl;
  late Animation<double> _globeOpacity;
  late Animation<double> _pulse;

  // ── State ──
  PPVEvent? _event;
  PPVPresentationModel? _presentation;
  bool _loading = true;
  bool _globeAnimComplete = false;
  Duration _countdown = Duration.zero;
  Timer? _countdownTimer;
  int _selectedTier = 1; // 0=Single, 1=Main Card, 2=Full Card
  String _selectedPayment = 'stripe';
  Timer? _globeMapTimer;
  bool _automationPurchaseTriggered = false;
  bool _hasEntitlement = false;
  bool _purchasePendingConfirmation = false;

  @override
  void initState() {
    super.initState();
    setWebRouteTestHook('event-poster');
    _initAnimations();
    _loadEvent();
    _startCountdown();
  }

  void _initAnimations() {
    // Globe zoom animation - 2.5 seconds (controls fade-out timing)
    _globeZoomCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _globeOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _globeZoomCtrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _globeZoomCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _globeAnimComplete = true);
        _cardRevealCtrl.forward();
      }
    });

    // Pulse animation for live indicators
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulse = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Card reveal animation
    _cardRevealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  Future<void> _loadEvent() async {
    // Use preloaded event or load from service
    if (widget.preloadedEvent != null) {
      final event = widget.preloadedEvent!;
      setState(() {
        _event = event;
        _presentation = PPVPresentationModel.fromEvent(event);
        _loading = false;
      });
      _refreshEntitlementState();
      _startGlobeTimeout();
      _maybeTriggerAutomationPurchase();

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _globeZoomCtrl.forward();
        }
      });
      return;
    }

    final loadedEvent = await _ppvService.getPPVEvent(widget.ppvId);
    if (loadedEvent != null) {
      if (mounted) {
        setState(() {
          _event = loadedEvent;
          _presentation = PPVPresentationModel.fromEvent(loadedEvent);
          _loading = false;
        });
        _refreshEntitlementState();
        _startGlobeTimeout();
        _maybeTriggerAutomationPurchase();

        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _globeZoomCtrl.forward();
          }
        });
      }
      return;
    }

    // Fallback demo event
    await Future.delayed(const Duration(milliseconds: 500));
    final demoEvent = PPVEvent(
      id: widget.ppvId,
      eventId: 'event-001',
      promoterId: 'dfc',
      title: 'IBC III: GOLD COAST BRAWL',
      subtitle: 'Cutler vs Modini — LHW Title',
      description:
          'International Brawling Championship returns to the Gold Coast with '
          'Jay Cutler vs Luke Modini headlining a five-round light heavyweight title fight.',
      eventDate: DateTime.now().add(const Duration(days: 7, hours: 3)),
      presaleStart: DateTime.now().subtract(const Duration(days: 7)),
      onSaleStart: DateTime.now().subtract(const Duration(days: 3)),
      status: PPVStatus.onSale,
      standardPriceCents: 2999,
      earlyBirdPriceCents: 1999,
      premiumPriceCents: 4999,
      vipPriceCents: 7999,
      streamPlatforms: ['DFC', 'TrillerTV+', 'Kayo'],
      purchaseCount: 4850,
      fightCard: [
        const PPVFight(
          fightId: 'f1',
          fighter1Name: 'Jay Cutler',
          fighter2Name: 'Luke Modini',
          weightClass: 'Light Heavyweight',
          rounds: 5,
          isMainEvent: true,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'f2',
          fighter1Name: 'Isaac Hardman',
          fighter2Name: 'Jonathan Tuhu',
          weightClass: 'Championship',
          rounds: 5,
          isTitleFight: true,
        ),
        const PPVFight(
          fightId: 'f3',
          fighter1Name: 'Emma Stone',
          fighter2Name: 'Sarah King',
          weightClass: 'Strawweight',
        ),
        const PPVFight(
          fightId: 'f4',
          fighter1Name: 'Danny Mac',
          fighter2Name: 'Ratu Vunipola',
          weightClass: 'Heavyweight',
        ),
      ],
    );

    if (mounted) {
      setState(() {
        _event = demoEvent;
        _presentation = PPVPresentationModel.fromEvent(demoEvent);
        _loading = false;
      });
      _refreshEntitlementState();
      _startGlobeTimeout();
      _maybeTriggerAutomationPurchase();

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _globeZoomCtrl.forward();
        }
      });
    }
  }

  Future<void> _refreshEntitlementState() async {
    final user = FirebaseAuth.instance.currentUser;
    final eventId = _event?.id ?? widget.ppvId;
    if (user == null || eventId.isEmpty) {
      if (mounted) {
        setState(() {
          _hasEntitlement = false;
        });
      }
      return;
    }

    try {
      final hasAccess = await _ppvService.hasPurchased(user.uid, eventId);
      if (mounted) {
        setState(() {
          _hasEntitlement = hasAccess;
          if (hasAccess) {
            _purchasePendingConfirmation = false;
          }
        });
      }
    } catch (_) {
      // Keep current state on temporary entitlement check failures.
    }
  }

  bool get _shouldAutoOpenCheckout {
    if (!kIsWeb || _automationPurchaseTriggered) {
      return false;
    }

    final mode = _ppvAutomationQueryParams()['ppvAction']?.toLowerCase();
    return mode == 'buy' || mode == 'checkout';
  }

  Map<String, String> _ppvAutomationQueryParams() {
    final directParams = Uri.base.queryParameters;
    if (directParams.isNotEmpty) {
      return directParams;
    }

    final fragment = Uri.base.fragment;
    final queryStart = fragment.indexOf('?');
    if (queryStart == -1 || queryStart == fragment.length - 1) {
      return const {};
    }

    return Uri.splitQueryString(fragment.substring(queryStart + 1));
  }

  void _maybeTriggerAutomationPurchase() {
    if (!_shouldAutoOpenCheckout || !mounted) {
      return;
    }

    _automationPurchaseTriggered = true;
    debugPrint(
      'PPV automation: auto-buy fired for ${widget.ppvId} with ${_ppvAutomationQueryParams()}',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _handlePurchase();
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_event == null) return;
      final diff = _event!.eventDate.difference(DateTime.now());
      if (mounted) {
        setState(() {
          _countdown = diff.isNegative ? Duration.zero : diff;
        });
      }
    });
  }

  @override
  void dispose() {
    _globeZoomCtrl.dispose();
    _pulseCtrl.dispose();
    _cardRevealCtrl.dispose();
    _countdownTimer?.cancel();
    _globeMapTimer?.cancel();
    super.dispose();
  }

  void _shareEvent() {
    if (_event == null) return;
    final title = _event!.title;
    final subtitle = _event!.subtitle ?? '';
    final text =
        'Check out $title${subtitle.isNotEmpty ? ' - $subtitle' : ''} on DFC PPV!';
    Share.share(text, subject: 'Watch $title on Data Fight Central');
  }

  void _playTrailer() {
    if (_event?.trailerUrl == null) return;
    // Launch trailer in browser or video player
    HapticFeedback.lightImpact();
    // TODO: Implement trailer playback (YouTube player integration)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trailer playback coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Real lat/lng coordinates for Google Maps satellite view
  static const Map<String, LatLng> _locationLatLng = {
    // 🇺🇸 UNITED STATES
    'las vegas': LatLng(36.1699, -115.1398),
    'new york': LatLng(40.7128, -74.0060),
    'los angeles': LatLng(34.0522, -118.2437),
    'la': LatLng(34.0522, -118.2437),
    'miami': LatLng(25.7617, -80.1918),
    'chicago': LatLng(41.8781, -87.6298),
    'houston': LatLng(29.7604, -95.3698),
    'dallas': LatLng(32.7767, -96.7970),
    'denver': LatLng(39.7392, -104.9903),
    'atlanta': LatLng(33.7490, -84.3880),
    'boston': LatLng(42.3601, -71.0589),
    'philadelphia': LatLng(39.9526, -75.1652),
    'phoenix': LatLng(33.4484, -112.0740),
    'washington': LatLng(38.9072, -77.0369),
    'dc': LatLng(38.9072, -77.0369),
    'seattle': LatLng(47.6062, -122.3321),
    'san francisco': LatLng(37.7749, -122.4194),
    'san diego': LatLng(32.7157, -117.1611),
    'detroit': LatLng(42.3314, -83.0458),
    'minneapolis': LatLng(44.9778, -93.2650),
    'new orleans': LatLng(29.9511, -90.0715),
    'nashville': LatLng(36.1627, -86.7816),
    'charlotte': LatLng(35.2271, -80.8431),
    'sacramento': LatLng(38.5816, -121.4944),
    'orlando': LatLng(28.5383, -81.3792),
    'tampa': LatLng(27.9506, -82.4572),
    'atlantic city': LatLng(39.3643, -74.4229),
    // 🇨🇦 CANADA
    'toronto': LatLng(43.6532, -79.3832),
    'vancouver': LatLng(49.2827, -123.1207),
    'montreal': LatLng(45.5017, -73.5673),
    'calgary': LatLng(51.0447, -114.0719),
    'edmonton': LatLng(53.5461, -113.4938),
    'ottawa': LatLng(45.4215, -75.6972),
    'winnipeg': LatLng(49.8951, -97.1384),
    // 🇲🇽 MEXICO & LATIN AMERICA
    'mexico city': LatLng(19.4326, -99.1332),
    'guadalajara': LatLng(20.6597, -103.3496),
    'cancun': LatLng(21.1619, -86.8515),
    'monterrey': LatLng(25.6866, -100.3161),
    'tijuana': LatLng(32.5149, -117.0382),
    'sao paulo': LatLng(-23.5505, -46.6333),
    'rio de janeiro': LatLng(-22.9068, -43.1729),
    'rio': LatLng(-22.9068, -43.1729),
    'buenos aires': LatLng(-34.6037, -58.3816),
    'bogota': LatLng(4.7110, -74.0721),
    'lima': LatLng(-12.0464, -77.0428),
    'santiago': LatLng(-33.4489, -70.6693),
    // 🇬🇧 UNITED KINGDOM
    'london': LatLng(51.5074, -0.1278),
    'manchester': LatLng(53.4808, -2.2426),
    'birmingham': LatLng(52.4862, -1.8904),
    'liverpool': LatLng(53.4084, -2.9916),
    'glasgow': LatLng(55.8642, -4.2518),
    'cardiff': LatLng(51.4816, -3.1791),
    'newcastle': LatLng(54.9783, -1.6178),
    'leeds': LatLng(53.8008, -1.5491),
    'nottingham': LatLng(52.9548, -1.1581),
    'sheffield': LatLng(53.3811, -1.4701),
    'belfast': LatLng(54.5973, -5.9301),
    // 🇮🇪 IRELAND
    'dublin': LatLng(53.3498, -6.2603),
    'cork': LatLng(51.8985, -8.4756),
    // 🇪🇺 CONTINENTAL EUROPE
    'paris': LatLng(48.8566, 2.3522),
    'berlin': LatLng(52.5200, 13.4050),
    'amsterdam': LatLng(52.3676, 4.9041),
    'rotterdam': LatLng(51.9244, 4.4777),
    'madrid': LatLng(40.4168, -3.7038),
    'barcelona': LatLng(41.3874, 2.1686),
    'rome': LatLng(41.9028, 12.4964),
    'milan': LatLng(45.4642, 9.1900),
    'munich': LatLng(48.1351, 11.5820),
    'frankfurt': LatLng(50.1109, 8.6821),
    'hamburg': LatLng(53.5511, 9.9937),
    'cologne': LatLng(50.9375, 6.9603),
    'warsaw': LatLng(52.2297, 21.0122),
    'krakow': LatLng(50.0647, 19.9450),
    'stockholm': LatLng(59.3293, 18.0686),
    'copenhagen': LatLng(55.6761, 12.5683),
    'oslo': LatLng(59.9139, 10.7522),
    'helsinki': LatLng(60.1699, 24.9384),
    'vienna': LatLng(48.2082, 16.3738),
    'prague': LatLng(50.0755, 14.4378),
    'budapest': LatLng(47.4979, 19.0402),
    'zurich': LatLng(47.3769, 8.5417),
    'geneva': LatLng(46.2044, 6.1432),
    'brussels': LatLng(50.8503, 4.3517),
    'lisbon': LatLng(38.7223, -9.1393),
    'athens': LatLng(37.9838, 23.7275),
    'moscow': LatLng(55.7558, 37.6173),
    'st petersburg': LatLng(59.9311, 30.3609),
    // 🇦🇪 MIDDLE EAST
    'dubai': LatLng(25.2048, 55.2708),
    'abu dhabi': LatLng(24.4539, 54.3773),
    'riyadh': LatLng(24.7136, 46.6753),
    'jeddah': LatLng(21.4858, 39.1925),
    'doha': LatLng(25.2854, 51.5310),
    'bahrain': LatLng(26.0667, 50.5577),
    'tel aviv': LatLng(32.0853, 34.7818),
    // 🇵🇰 PAKISTAN
    'karachi': LatLng(24.8607, 67.0011),
    'lahore': LatLng(31.5204, 74.3587),
    'islamabad': LatLng(33.6844, 73.0479),
    'rawalpindi': LatLng(33.5651, 73.0169),
    'peshawar': LatLng(34.0151, 71.5249),
    'faisalabad': LatLng(31.4504, 73.1350),
    'multan': LatLng(30.1575, 71.5249),
    // 🇮🇳 INDIA
    'mumbai': LatLng(19.0760, 72.8777),
    'delhi': LatLng(28.7041, 77.1025),
    'new delhi': LatLng(28.6139, 77.2090),
    'bangalore': LatLng(12.9716, 77.5946),
    'bengaluru': LatLng(12.9716, 77.5946),
    'chennai': LatLng(13.0827, 80.2707),
    'kolkata': LatLng(22.5726, 88.3639),
    'hyderabad': LatLng(17.3850, 78.4867),
    'pune': LatLng(18.5204, 73.8567),
    'ahmedabad': LatLng(23.0225, 72.5714),
    'jaipur': LatLng(26.9124, 75.7873),
    'lucknow': LatLng(26.8467, 80.9462),
    'goa': LatLng(15.2993, 74.1240),
    // 🇦🇺 AUSTRALIA — DFC Home Base
    'melbourne': LatLng(-37.8136, 144.9631),
    'sydney': LatLng(-33.8688, 151.2093),
    'gold coast': LatLng(-28.0167, 153.4000),
    'brisbane': LatLng(-27.4698, 153.0251),
    'townsville': LatLng(-19.2590, 146.8169),
    'perth': LatLng(-31.9505, 115.8605),
    'adelaide': LatLng(-34.9285, 138.6007),
    'canberra': LatLng(-35.2809, 149.1300),
    'darwin': LatLng(-12.4634, 130.8456),
    'hobart': LatLng(-42.8821, 147.3272),
    // 🇳🇿 NEW ZEALAND
    'auckland': LatLng(-36.8485, 174.7633),
    'wellington': LatLng(-41.2865, 174.7762),
    'christchurch': LatLng(-43.5321, 172.6362),
    // 🇯🇵 JAPAN
    'tokyo': LatLng(35.6762, 139.6503),
    'osaka': LatLng(34.6937, 135.5023),
    'nagoya': LatLng(35.1815, 136.9066),
    'sapporo': LatLng(43.0618, 141.3545),
    'fukuoka': LatLng(33.5904, 130.4017),
    'yokohama': LatLng(35.4437, 139.6380),
    // 🇰🇷 SOUTH KOREA
    'seoul': LatLng(37.5665, 126.9780),
    'busan': LatLng(35.1796, 129.0756),
    'incheon': LatLng(37.4563, 126.7052),
    // 🇨🇳 CHINA
    'beijing': LatLng(39.9042, 116.4074),
    'shanghai': LatLng(31.2304, 121.4737),
    'shenzhen': LatLng(22.5431, 114.0579),
    'guangzhou': LatLng(23.1291, 113.2644),
    'hong kong': LatLng(22.3193, 114.1694),
    'macau': LatLng(22.1987, 113.5439),
    'chengdu': LatLng(30.5728, 104.0668),
    'hangzhou': LatLng(30.2741, 120.1551),
    // 🇵🇭 PHILIPPINES
    'manila': LatLng(14.5995, 120.9842),
    'cebu': LatLng(10.3157, 123.8854),
    'davao': LatLng(7.1907, 125.4553),
    'quezon city': LatLng(14.6760, 121.0437),
    // 🇹🇭 THAILAND
    'bangkok': LatLng(13.7563, 100.5018),
    'pattaya': LatLng(12.9236, 100.8825),
    'phuket': LatLng(7.8804, 98.3923),
    'chiang mai': LatLng(18.7883, 98.9853),
    // 🇸🇬 🇲🇾 🇮🇩 SOUTHEAST ASIA
    'singapore': LatLng(1.3521, 103.8198),
    'kuala lumpur': LatLng(3.1390, 101.6869),
    'kl': LatLng(3.1390, 101.6869),
    'jakarta': LatLng(-6.2088, 106.8456),
    'bali': LatLng(-8.3405, 115.0920),
    'ho chi minh': LatLng(10.8231, 106.6297),
    'saigon': LatLng(10.8231, 106.6297),
    'hanoi': LatLng(21.0278, 105.8342),
    // 🇰🇿 CENTRAL ASIA
    'almaty': LatLng(43.2220, 76.8512),
    'nur-sultan': LatLng(51.1694, 71.4491),
    'astana': LatLng(51.1694, 71.4491),
    'tashkent': LatLng(41.2995, 69.2401),
    'baku': LatLng(40.4093, 49.8671),
    // 🇿🇦 AFRICA
    'johannesburg': LatLng(-26.2041, 28.0473),
    'cape town': LatLng(-33.9249, 18.4241),
    'durban': LatLng(-29.8587, 31.0218),
    'pretoria': LatLng(-25.7479, 28.2293),
    'lagos': LatLng(6.5244, 3.3792),
    'cairo': LatLng(30.0444, 31.2357),
    'casablanca': LatLng(33.5731, -7.5898),
    'nairobi': LatLng(-1.2921, 36.8219),
    // DEFAULT
    'default': LatLng(0, 0),
  };

  LatLng _getEventLatLng() {
    if (_event == null) return _locationLatLng['default']!;
    final searchText =
        '${_event!.title} ${_event!.subtitle ?? ''} ${_event!.description}'
            .toLowerCase();
    for (final loc in _locationLatLng.keys) {
      if (searchText.contains(loc)) return _locationLatLng[loc]!;
    }
    return _locationLatLng['default']!;
  }

  void _startGlobeTimeout() {
    _globeMapTimer?.cancel();
    _globeMapTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && !_globeAnimComplete) {
        _globeZoomCtrl.forward();
      }
    });
  }

  void _onGlobeMapCreated(GoogleMapController controller) {
    _globeMapTimer?.cancel();
    final target = _getEventLatLng();
    // Animate camera from world view to event location
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 12, tilt: 45),
        ),
      );
    });
    // Start fade-out after camera animation
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && !_globeAnimComplete) {
        _globeZoomCtrl.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'data-test=event-poster',
      child: Scaffold(
        backgroundColor: const Color(0xFF030810),
        body: Stack(
          children: [
            if (_loading)
              _buildLoading()
            else
              Stack(
                children: [
                  // Globe zoom background
                  if (!_globeAnimComplete) _buildGlobeZoom(),

                  // Main content (revealed after globe zoom)
                  AnimatedOpacity(
                    opacity: _globeAnimComplete ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: _buildMainContent(),
                  ),

                  if (_globeAnimComplete)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildStickyPurchaseBar(),
                    ),

                  // Top bar (always visible)
                  _buildTopBar(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(DesignTokens.neonCyan),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'LOADING EVENT...',
            style: TextStyle(
              color: DesignTokens.neonCyan,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GLOBE ZOOM ANIMATION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGlobeZoom() {
    final targetLatLng = _getEventLatLng();

    return AnimatedBuilder(
      animation: _globeZoomCtrl,
      builder: (context, _) {
        return Opacity(
          opacity: _globeOpacity.value.clamp(0.0, 1.0),
          child: Container(
            color: const Color(0xFF030810),
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(20, 0),
                    zoom: 1.5,
                  ),
                  mapType: MapType.satellite,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  myLocationButtonEnabled: false,
                  onMapCreated: _onGlobeMapCreated,
                  markers: {
                    Marker(
                      markerId: const MarkerId('event_location'),
                      position: targetLatLng,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                    ),
                  },
                ),
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: DesignTokens.neonRed,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _extractLocation(
                              '${_event?.title ?? ''} ${_event?.description ?? ''}',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _extractLocation(String title) {
    final locations = [
      'MELBOURNE',
      'SYDNEY',
      'GOLD COAST',
      'TOWNSVILLE',
      'PERTH',
      'AUCKLAND',
      'MANILA',
      'TOKYO',
      'SINGAPORE',
      'DUBAI',
      'LAS VEGAS',
      'NEW YORK',
      'LONDON',
    ];
    for (final loc in locations) {
      if (title.toUpperCase().contains(loc)) return loc;
    }
    return 'AUSTRALIA';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const Spacer(),
            // Live indicator
            if (_event?.status == PPVStatus.live)
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, _) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2 * _pulse.value),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: _pulse.value),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 12),
            // Share button
            GestureDetector(
              onTap: _shareEvent,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.share, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareEvent() {
    HapticFeedback.mediumImpact();
    if (_event == null) return;
    final e = _event!;
    final mainFight = e.fightCard.isNotEmpty
        ? e.fightCard.firstWhere(
            (f) => f.isMainEvent,
            orElse: () => e.fightCard.first,
          )
        : null;
    context.push(
      '/promoter/poster-generator'
      '?event=${Uri.encodeComponent(e.title)}'
      '&f1=${Uri.encodeComponent(mainFight?.fighter1Name ?? '')}'
      '&f2=${Uri.encodeComponent(mainFight?.fighter2Name ?? '')}'
      '&venue=${Uri.encodeComponent(e.streamPlatforms.join(', '))}'
      '&date=${Uri.encodeComponent(e.eventDate.toString().split(' ').first)}'
      '&sport=${Uri.encodeComponent(e.sport ?? 'MMA')}',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAIN CONTENT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMainContent() {
    final presentation =
        _presentation ??
        (_event == null ? null : PPVPresentationModel.fromEvent(_event!));

    return CustomScrollView(
      slivers: [
        // Collapsible poster hero (SliverAppBar)
        SliverAppBar(
          expandedHeight: 300.0,
          pinned: true,
          stretch: true,
          backgroundColor: const Color(0xFF030810),
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: presentation != null && presentation.hasPoster
                ? Image(
                    image: ImageAssets.resolveImage(presentation.posterUrl!),
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: const Color(0xFF1A0A2E),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.red),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF1A0A2E), Colors.black],
                        ),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/logos/dfc_hex_badge.png',
                          width: 80,
                          height: 80,
                          opacity: const AlwaysStoppedAnimation(0.4),
                        ),
                      ),
                    ),
                  )
                : (_event != null && _event!.fightCard.isNotEmpty)
                ? FightCardPoster(event: _event!, presentation: presentation)
                : _buildPosterFallback(presentation),
          ),
        ),

        // Hero metadata strip under the poster
        SliverToBoxAdapter(child: _buildHeroSection(presentation)),

        // Countdown timer
        SliverToBoxAdapter(child: _buildCountdown()),

        // Fight card
        SliverToBoxAdapter(child: _buildFightCardSection()),

        // Stream platform chooser — region-aware
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: RegionalWhereToWatch(
              eventPlatforms: _event?.streamPlatforms ?? const ['DFC'],
            ),
          ),
        ),

        // Pricing tiers
        SliverToBoxAdapter(child: _buildPricingTiers()),

        // Payment options
        SliverToBoxAdapter(child: _buildPaymentOptions()),

        // Buy button
        SliverToBoxAdapter(child: _buildBuyButton()),

        // AI Promote button
        SliverToBoxAdapter(child: _buildPromoteWithAI()),

        // Competitor comparison
        SliverToBoxAdapter(child: _buildCompetitorComparison()),

        // Promo content
        SliverToBoxAdapter(child: _buildPromoContent()),

        // Bottom spacing
        const SliverToBoxAdapter(child: SizedBox(height: 156)),
      ],
    );
  }

  Widget _buildHeroSection(PPVPresentationModel? presentation) {
    final showEventIdentity =
        presentation == null ||
        presentation.posterMode == PosterRenderMode.embeddedArtwork;

    return Container(
      constraints: BoxConstraints(minHeight: showEventIdentity ? 320 : 208),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A0A2E),
            DesignTokens.neonMagenta.withValues(alpha: 0.15),
            const Color(0xFF030810),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern overlay
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _HeroPatternPainter()),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                showEventIdentity ? 60 : 28,
                20,
                20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          DesignTokens.neonMagenta,
                          DesignTokens.neonRed,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _event?.statusLabel ?? 'PPV EVENT',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: showEventIdentity ? 16 : 14),
                  if (showEventIdentity) ...[
                    Text(
                      _event?.title ?? 'DFC PPV EVENT',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        height: 1.1,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _event?.subtitle ?? '',
                      style: const TextStyle(
                        color: DesignTokens.neonCyan,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    Text(
                      'Event overview',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  // Stats row
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildStatChip(
                        Icons.people,
                        '${_event?.purchaseCount ?? 0}',
                        'BUYERS',
                      ),
                      _buildStatChip(
                        Icons.sports_mma,
                        '${_event?.fightCard.length ?? 0}',
                        'FIGHTS',
                      ),
                      _buildStatChip(
                        Icons.stream,
                        _heroPlatformSummary(),
                        'STREAM',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action buttons row: Share + Trailer
                  Row(
                    children: [
                      // Share button
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _shareEvent,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.share,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'SHARE',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Trailer button (if available)
                      if (_event?.trailerUrl != null)
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _playTrailer,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: DesignTokens.neonCyan.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: DesignTokens.neonCyan.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.play_circle,
                                      size: 14,
                                      color: DesignTokens.neonCyan,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'TRAILER',
                                      style: TextStyle(
                                        color: DesignTokens.neonCyan,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterFallback(PPVPresentationModel? presentation) {
    final eventSubtitle = _event?.subtitle;
    final title = _event?.title ?? 'DFC PPV LIVE';
    final subtitle = (eventSubtitle != null && eventSubtitle.isNotEmpty)
        ? eventSubtitle
        : 'Premium fight night presentation while the live event artwork syncs.';
    final platforms = _heroPlatformSummary();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF060B14),
            DesignTokens.neonMagenta.withValues(alpha: 0.22),
            DesignTokens.neonCyan.withValues(alpha: 0.14),
            const Color(0xFF030810),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _HeroPatternPainter()),
            ),
          ),
          Positioned(
            top: 34,
            right: -18,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DesignTokens.neonMagenta.withValues(alpha: 0.10),
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.neonMagenta.withValues(alpha: 0.18),
                    blurRadius: 48,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: -22,
            bottom: 24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DesignTokens.neonCyan.withValues(alpha: 0.10),
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.20),
                    blurRadius: 44,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.black.withValues(alpha: 0.28),
                    border: Border.all(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Text(
                    'DFC LIVE EVENT MODE',
                    style: TextStyle(
                      color: DesignTokens.neonCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black.withValues(alpha: 0.24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/logos/dfc_hex_badge.png',
                          width: 38,
                          height: 38,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              height: 1.06,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildFallbackBadge(
                      Icons.stream,
                      platforms,
                      DesignTokens.neonCyan,
                    ),
                    _buildFallbackBadge(
                      Icons.local_fire_department,
                      _event?.statusLabel ?? 'PREMIUM ACCESS',
                      DesignTokens.neonRed,
                    ),
                    _buildFallbackBadge(
                      Icons.replay,
                      'REPLAY READY',
                      DesignTokens.neonMagenta,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(minWidth: 92, maxWidth: 150),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: DesignTokens.neonCyan, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _heroPlatformSummary() {
    final platforms = _event?.streamPlatforms ?? const <String>[];
    if (platforms.isEmpty) return 'DFC';
    if (platforms.length == 1) return platforms.first;
    return '${platforms.first} +${platforms.length - 1}';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COUNTDOWN TIMER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCountdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.neonRed.withValues(alpha: 0.12),
            DesignTokens.neonMagenta.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignTokens.neonRed.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.neonRed.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.3, end: 0.7),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOut,
              onEnd: () {
                // Loop animation
                setState(() {});
              },
              builder: (context, value, child) {
                return Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: DesignTokens.neonRed.withValues(
                        alpha: value * 0.3,
                      ),
                      width: 1,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, _) => Icon(
                        Icons.access_time_filled,
                        color: DesignTokens.neonRed.withValues(
                          alpha: _pulse.value,
                        ),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'EVENT STARTS IN',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimeUnit(
                      _countdown.inDays.toString().padLeft(2, '0'),
                      'DAYS',
                    ),
                    _buildTimeSeparator(),
                    _buildTimeUnit(
                      (_countdown.inHours % 24).toString().padLeft(2, '0'),
                      'HRS',
                    ),
                    _buildTimeSeparator(),
                    _buildTimeUnit(
                      (_countdown.inMinutes % 60).toString().padLeft(2, '0'),
                      'MIN',
                    ),
                    _buildTimeSeparator(),
                    _buildTimeUnit(
                      (_countdown.inSeconds % 60).toString().padLeft(2, '0'),
                      'SEC',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: DesignTokens.neonCyan,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: TextStyle(
          color: DesignTokens.neonRed,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIGHT CARD SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFightCardSection() {
    final fights = _event?.fightCard ?? [];
    if (fights.isEmpty) return _buildFightCardFallbackSection();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.sports_mma,
                  color: DesignTokens.neonMagenta,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'FIGHT CARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonMagenta.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${fights.length} BOUTS',
                    style: const TextStyle(
                      color: DesignTokens.neonMagenta,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: fights.length,
            itemBuilder: (context, index) {
              return _buildFightCard(fights[index], index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFightCardFallbackSection() {
    final accessCards = [
      (
        Icons.bolt,
        'LIVE SIGNAL',
        'Neon-grade PPV lane is active even while the live bout sheet syncs.',
        DesignTokens.neonCyan,
      ),
      (
        Icons.verified,
        'CARD DROPS HERE',
        'Main event, undercard, and title-fight tiles populate as event data lands.',
        DesignTokens.neonMagenta,
      ),
      (
        Icons.movie_filter,
        'REPLAY + ACCESS',
        'Pricing, replay windows, and platform coverage are already live below.',
        DesignTokens.neonRed,
      ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.05),
            DesignTokens.neonMagenta.withValues(alpha: 0.08),
            DesignTokens.neonCyan.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.grid_view_rounded,
                color: DesignTokens.neonMagenta,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'EVENT INTEL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This event is live in DFC mode. Rich bout cards appear here as soon as the promotion payload completes.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: accessCards.map((card) {
              return SizedBox(
                width: 220,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: card.$4.withValues(alpha: 0.32)),
                    boxShadow: [
                      BoxShadow(
                        color: card.$4.withValues(alpha: 0.12),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(card.$1, color: card.$4, size: 18),
                      const SizedBox(height: 10),
                      Text(
                        card.$2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        card.$3,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.60),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFightCard(PPVFight fight, int index) {
    final isMain = fight.isMainEvent;
    final isTitle = fight.isTitleFight;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: isMain
            ? LinearGradient(
                colors: [
                  DesignTokens.neonRed.withValues(alpha: 0.2),
                  DesignTokens.neonMagenta.withValues(alpha: 0.1),
                ],
              )
            : null,
        color: isMain ? null : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMain
              ? DesignTokens.neonRed.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.08),
          width: isMain ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header badges
          if (isMain || isTitle)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isMain) ...[
                    const Icon(
                      Icons.star,
                      color: DesignTokens.neonAmber,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'MAIN EVENT',
                      style: TextStyle(
                        color: DesignTokens.neonAmber,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                  if (isMain && isTitle) const SizedBox(width: 12),
                  if (isTitle) ...[
                    const Icon(
                      Icons.emoji_events,
                      color: DesignTokens.neonGold,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'TITLE FIGHT',
                      style: TextStyle(
                        color: DesignTokens.neonGold,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          // VS layout
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Fighter 1
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              DesignTokens.neonRed,
                              DesignTokens.neonRed.withValues(alpha: 0.5),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: DesignTokens.neonRed.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        fight.fighter1Name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMain ? 14 : 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // VS
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DesignTokens.neonMagenta.withValues(alpha: 0.3),
                        DesignTokens.neonCyan.withValues(alpha: 0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'VS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${fight.rounds}RDS',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                // Fighter 2
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              DesignTokens.neonCyan,
                              DesignTokens.neonCyan.withValues(alpha: 0.5),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: DesignTokens.neonCyan.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        fight.fighter2Name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMain ? 14 : 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Weight class
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                fight.weightClass.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRICING TIERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPricingTiers() {
    // ═══════════════════════════════════════════════════════════════════════════
    // MICRO-PACKAGING SYSTEM — Buy Bulk, Sell Small
    // ═══════════════════════════════════════════════════════════════════════════
    // Like a shop: buy wholesale, break into retail packages
    // Every viewer can afford SOMETHING - capture every dollar
    // ═══════════════════════════════════════════════════════════════════════════

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───
          const Row(
            children: [
              Icon(Icons.shopping_bag, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                'CHOOSE YOUR PACKAGE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'From micro to macro — pay only for what you want',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),

          // ─── MICRO PACKAGES (Entry Level) ───
          _buildPackageSection(
            'MICRO PACKAGES',
            'Perfect for casual viewers',
            Icons.grain,
            [
              const _PackageTier(
                id: 0,
                name: 'SINGLE ROUND',
                price: 1.99,
                desc: 'Any 1 round of any fight',
                icon: Icons.looks_one,
                color: DesignTokens.neonGreen,
              ),
              const _PackageTier(
                id: 1,
                name: 'HIGHLIGHTS',
                price: 3.99,
                desc: 'KOs, subs & finishes only',
                icon: Icons.flash_on,
                color: DesignTokens.neonAmber,
              ),
              const _PackageTier(
                id: 2,
                name: 'SINGLE FIGHT',
                price: 9.99,
                desc: 'Pick any 1 full bout',
                icon: Icons.sports_mma,
                color: DesignTokens.neonCyan,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─── STANDARD PACKAGES (Most Popular) ───
          _buildPackageSection(
            'STANDARD PACKAGES',
            'Best value for fight fans',
            Icons.local_fire_department,
            [
              const _PackageTier(
                id: 3,
                name: 'PRELIMS',
                price: 14.99,
                desc: 'All undercard fights',
                icon: Icons.list,
                color: DesignTokens.neonCyan,
              ),
              _PackageTier(
                id: 4,
                name: 'MAIN CARD',
                price: _event?.standardPrice ?? 29.99,
                desc: 'Top 5 fights + replay',
                icon: Icons.star,
                color: DesignTokens.neonMagenta,
                isPopular: true,
              ),
              _PackageTier(
                id: 5,
                name: 'FULL SHOW',
                price: _event?.premiumPrice ?? 49.99,
                desc: 'Everything + 7-day replay',
                icon: Icons.all_inclusive,
                color: DesignTokens.neonGold,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─── PREMIUM BUNDLES (High Value) ───
          _buildPackageSection(
            'PREMIUM BUNDLES',
            'For the hardcore fan',
            Icons.diamond,
            [
              const _PackageTier(
                id: 6,
                name: 'FIGHTER PASS',
                price: 19.99,
                desc: 'All fights with 1 fighter',
                icon: Icons.person,
                color: DesignTokens.neonMagenta,
                badge: 'PICK ANY',
              ),
              const _PackageTier(
                id: 7,
                name: 'REGION BUNDLE',
                price: 24.99,
                desc: 'All AUSSIE fighter bouts',
                icon: Icons.flag,
                color: DesignTokens.neonAmber,
                badge: 'DFC',
              ),
              const _PackageTier(
                id: 8,
                name: 'TITLE FIGHTS',
                price: 39.99,
                desc: 'Every championship bout',
                icon: Icons.emoji_events,
                color: DesignTokens.neonGold,
                badge: 'GOLD',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─── DFC CREDITS (Bulk Buy System) ───
          _buildCreditsSection(),
        ],
      ),
    );
  }

  Widget _buildPackageSection(
    String title,
    String subtitle,
    IconData headerIcon,
    List<_PackageTier> tiers,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(headerIcon, color: Colors.white38, size: 14),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 9,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: tiers.map((tier) {
            final selected = _selectedTier == tier.id;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTier = tier.id);
                },
                child: Container(
                  margin: EdgeInsets.only(
                    left: tier == tiers.first ? 0 : 4,
                    right: tier == tiers.last ? 0 : 4,
                  ),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              tier.color.withValues(alpha: 0.3),
                              tier.color.withValues(alpha: 0.1),
                            ],
                          )
                        : null,
                    color: selected
                        ? null
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? tier.color
                          : Colors.white.withValues(alpha: 0.1),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Badge (POPULAR, PICK ANY, etc.)
                      if (tier.isPopular || tier.badge != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tier.isPopular
                                ? DesignTokens.neonMagenta
                                : tier.color.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tier.isPopular ? 'POPULAR' : tier.badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      Icon(tier.icon, color: tier.color, size: 20),
                      const SizedBox(height: 6),
                      Text(
                        tier.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${tier.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: tier.color,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        tier.desc,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 8,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// DFC Credits - Buy in bulk, spend on any content
  /// ═══════════════════════════════════════════════════════════════════════════
  /// BUSINESS MATH:
  /// Base rate: 10 Credits = $1.00 (1C = $0.10)
  /// Bulk buyers save 15-33% vs retail - incentivizes commitment
  /// ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCreditsSection() {
    // Credit packs with bulk discounts
    // Format: credits, price, bonus, savings%
    final creditPacks = [
      {'credits': 100, 'price': 10, 'bonus': 0, 'save': '0%'}, // Base rate
      {'credits': 300, 'price': 27, 'bonus': 30, 'save': '18%'}, // 330C for $27
      {
        'credits': 700,
        'price': 60,
        'bonus': 100,
        'save': '25%',
      }, // 800C for $60
      {
        'credits': 1500,
        'price': 120,
        'bonus': 300,
        'save': '33%',
      }, // 1800C for $120
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.neonGold.withValues(alpha: 0.15),
            DesignTokens.neonAmber.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DesignTokens.neonGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.monetization_on,
                color: DesignTokens.neonGold,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'DFC CREDITS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DesignTokens.neonGold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'BULK SAVINGS',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Buy credits in bulk → Spend on any fight, replay, or highlight',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: creditPacks.map((pack) {
              final credits = pack['credits'] as int;
              final price = pack['price'] as int;
              final bonus = pack['bonus'] as int;
              final save = pack['save'] as String;
              final isTopValue = pack == creditPacks.last;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    left: pack == creditPacks.first ? 0 : 3,
                    right: pack == creditPacks.last ? 0 : 3,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isTopValue
                          ? Colors.greenAccent.withValues(alpha: 0.5)
                          : DesignTokens.neonGold.withValues(alpha: 0.2),
                      width: isTopValue ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Savings badge
                      if (save != '0%')
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SAVE $save',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      Text(
                        '${credits}C',
                        style: const TextStyle(
                          color: DesignTokens.neonGold,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (bonus > 0)
                        Text(
                          '+$bonus',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '\$$price',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      // Per-credit cost
                      Text(
                        '\$${(price / (credits + bonus)).toStringAsFixed(3)}/C',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 7,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          // Credit conversion rates (10C = $1.00 base rate)
          // Shows what each package costs in credits
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CREDIT COSTS (10C = \$1)',
                  style: TextStyle(
                    color: DesignTokens.neonGold.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildCreditRate('1 Round', '20C', '\$1.99'),
                    _buildCreditRate('Highlights', '40C', '\$3.99'),
                    _buildCreditRate('1 Fight', '100C', '\$9.99'),
                    _buildCreditRate('Main Card', '300C', '\$29.99'),
                    _buildCreditRate('Full Show', '500C', '\$49.99'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Savings example
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.savings, color: Colors.greenAccent, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'EXAMPLE: Buy 1500C pack (\$120) → Full Show costs 500C = \$33.33 (save \$16.66!)',
                    style: TextStyle(
                      color: Colors.greenAccent.withValues(alpha: 0.9),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditRate(String item, String credits, String retail) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            credits,
            style: const TextStyle(
              color: DesignTokens.neonGold,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '($retail)',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAYMENT OPTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPaymentOptions() {
    final payments = [
      {'id': 'stripe', 'name': 'Card', 'icon': Icons.credit_card},
      {'id': 'afterpay', 'name': 'Afterpay', 'icon': Icons.schedule},
      {'id': 'zip', 'name': 'Zip', 'icon': Icons.bolt},
      {'id': 'paypal', 'name': 'PayPal', 'icon': Icons.account_balance_wallet},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                'PAYMENT METHOD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: payments.map((p) {
              final selected = _selectedPayment == p['id'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedPayment = p['id'] as String);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? DesignTokens.neonCyan
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        p['icon'] as IconData,
                        color: selected
                            ? DesignTokens.neonCyan
                            : Colors.white54,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        p['name'] as String,
                        style: TextStyle(
                          color: selected
                              ? DesignTokens.neonCyan
                              : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedPayment == 'afterpay' || _selectedPayment == 'zip')
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '4 interest-free payments available',
                style: TextStyle(color: DesignTokens.neonGreen, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUY BUTTON
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBuyButton() {
    final prices = [
      9.99,
      _event?.standardPrice ?? 29.99,
      _event?.premiumPrice ?? 49.99,
    ];
    final selectedPrice = prices[_selectedTier];
    final automationLabel =
        'Buy PPV now for ${selectedPrice.toStringAsFixed(2)} AUD';

    if (_hasEntitlement) {
      return Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          children: [
            Semantics(
              label: 'data-test=entitlement-success-${widget.ppvId}',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.ppvSuccess.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: DesignTokens.ppvSuccess.withValues(alpha: 0.45),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: DesignTokens.ppvSuccess,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Entitlement confirmed. You are cleared for live stream and replay.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: Semantics(
                button: true,
                label: 'data-test=watch-now-${widget.ppvId}',
                child: ElevatedButton(
                  key: ValueKey('watch-now-${widget.ppvId}'),
                  onPressed: _openWatchNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.ppvSuccess,
                    foregroundColor: const Color(0xFF02140D),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'WATCH NOW',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.9,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Stack(
            children: [
              Semantics(
                button: true,
                label: 'data-test=buy-cta-${widget.ppvId}',
                hint: 'Opens the checkout options for this event',
                child: ElevatedButton(
                  key: const ValueKey('ppv-detail-buy-button'),
                  onPressed: _handlePurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.neonMagenta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 8,
                    shadowColor: DesignTokens.neonMagenta.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_open, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'SECURE CHECKOUT — \$${selectedPrice.toStringAsFixed(2)} AUD',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              buildPpvBuyButtonDomOverlay(
                onPressed: _handlePurchase,
                automationLabel: automationLabel,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_user,
                  size: 14,
                  color: DesignTokens.neonGreen,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Secure hosted checkout via Stripe. Access unlocks automatically once payment is confirmed.',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handlePurchase() {
    HapticFeedback.heavyImpact();

    // Get current user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please sign in to continue with secure checkout.',
          ),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'SIGN IN',
            textColor: Colors.white,
            onPressed: () => context.push('/login'),
          ),
        ),
      );
      return;
    }

    if (_event == null) return;

    // Show checkout sheet
    PPVCheckoutSheet.show(
      context: context,
      event: _event!,
      tierId: _selectedTier,
      paymentMethod: _selectedPayment,
      userId: user.uid,
    ).then((success) {
      if (success == true && mounted) {
        setState(() {
          _purchasePendingConfirmation = true;
        });
        _refreshEntitlementState();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Purchase initiated. Entitlement will unlock after payment confirmation.',
            ),
            backgroundColor: DesignTokens.neonGreen,
            action: SnackBarAction(
              label: 'WATCH',
              textColor: Colors.black,
              onPressed: _openWatchNow,
            ),
          ),
        );
      }
    });
  }

  void _openWatchNow() {
    context.push('/ppv/${widget.ppvId}/watch');
  }

  Widget _buildStickyPurchaseBar() {
    final prices = [
      9.99,
      _event?.standardPrice ?? 29.99,
      _event?.premiumPrice ?? 49.99,
    ];
    final selectedPrice = prices[_selectedTier];

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        decoration: BoxDecoration(
          color: DesignTokens.ppvSurface,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_purchasePendingConfirmation && !_hasEntitlement)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.ppvWarning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: DesignTokens.ppvWarning.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.hourglass_top,
                      size: 14,
                      color: DesignTokens.ppvWarning,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Waiting for payment confirmation and entitlement unlock.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _refreshEntitlementState,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: Semantics(
                button: true,
                label: _hasEntitlement
                    ? 'data-test=watch-now-${widget.ppvId}'
                    : 'data-test=buy-cta-${widget.ppvId}',
                child: ElevatedButton(
                  key: ValueKey(
                    _hasEntitlement
                        ? 'watch-now-${widget.ppvId}'
                        : 'buy-cta-${widget.ppvId}',
                  ),
                  onPressed: _hasEntitlement ? _openWatchNow : _handlePurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasEntitlement
                        ? DesignTokens.ppvSuccess
                        : DesignTokens.neonMagenta,
                    foregroundColor: _hasEntitlement
                        ? const Color(0xFF02140D)
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _hasEntitlement
                        ? 'WATCH NOW'
                        : 'SECURE CHECKOUT  \$${selectedPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROMOTE WITH AI — n8n Content Brain integration
  // ═══════════════════════════════════════════════════════════════════════════

  bool _isPromoting = false;

  Widget _buildPromoteWithAI() {
    if (_event == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: OutlinedButton.icon(
        onPressed: _isPromoting ? null : _handlePromoteWithAI,
        icon: _isPromoting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.auto_awesome, size: 18),
        label: Text(
          _isPromoting ? 'GENERATING AI PROMO...' : 'PROMOTE WITH AI',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: DesignTokens.neonCyan,
          side: BorderSide(color: DesignTokens.neonCyan.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePromoteWithAI() async {
    if (_event == null) return;

    setState(() => _isPromoting = true);
    HapticFeedback.mediumImpact();

    try {
      final n8n = N8nService();
      final fighters = _event!.fightCard
          .expand((f) => [f.fighter1Name, f.fighter2Name])
          .toList();

      final result = await n8n.promoteEventWithAI(
        eventTitle: _event!.title,
        fighters: fighters,
        sport: _event!.sport ?? 'MMA',
        promotion: _event!.promotion,
        eventId: _event!.id,
      );

      if (!mounted) return;

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('AI promo triggered — content incoming!'),
            backgroundColor: DesignTokens.neonCyan.withValues(alpha: 0.9),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Promo request failed — check n8n connection'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (context.mounted) setState(() => _isPromoting = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPETITOR COMPARISON — Why DFC is Different
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCompetitorComparison() {
    // Competitor data - subscription services vs DFC's pay-as-you-go model
    final competitors = [
      const _CompetitorInfo(
        name: 'KAYO',
        logo: '🟢',
        monthlyPrice: 29.99,
        model: 'Subscription',
        content: 'Sports bundle (AFL, NRL, Cricket)',
        fightContent: 'UFC maincard only',
        pros: ['All sports included', 'Same day replays'],
        cons: ['Monthly lock-in', 'No undercard', 'No indie events'],
        color: Color(0xFF00C853),
      ),
      const _CompetitorInfo(
        name: 'PARAMOUNT+',
        logo: '🔵',
        monthlyPrice: 13.99,
        model: 'Subscription',
        content: 'Movies, TV, some sports',
        fightContent: 'Bellator, limited UFC',
        pros: ['Low price', 'Entertainment included'],
        cons: ['Limited fight library', 'No live PPV', 'Delayed content'],
        color: Color(0xFF0064FF),
      ),
      const _CompetitorInfo(
        name: 'UFC PPV',
        logo: '🔴',
        monthlyPrice: 0,
        ppvPrice: 79.99,
        model: 'PPV Only',
        content: 'UFC events only',
        fightContent: 'Full UFC cards',
        pros: ['Premium UFC events', 'HD quality'],
        cons: ['\$80 per event!', 'UFC only', 'No micro-buy'],
        color: Color(0xFFD50000),
      ),
      const _CompetitorInfo(
        name: 'DAZN',
        logo: '⚫',
        monthlyPrice: 24.99,
        model: 'Subscription',
        content: 'Boxing focus',
        fightContent: 'Boxing, some MMA',
        pros: ['Good boxing library', 'No PPV fees'],
        cons: ['US-focused', 'Less MMA', 'Full monthly cost'],
        color: Color(0xFF1A1A1A),
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.compare_arrows,
                color: DesignTokens.neonCyan,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'WHY DFC?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [DesignTokens.neonMagenta, DesignTokens.neonCyan],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'PAY WHAT YOU WATCH',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Stop paying for content you don\'t watch',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),

          // DFC Card - Featured
          _buildDFCCard(),
          const SizedBox(height: 12),

          // Competitor cards - horizontal scroll
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: competitors.length,
              itemBuilder: (context, index) {
                return _buildCompetitorCard(competitors[index]);
              },
            ),
          ),
          const SizedBox(height: 16),

          // Quick comparison table
          _buildQuickComparison(),
        ],
      ),
    );
  }

  Widget _buildDFCCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.neonMagenta.withValues(alpha: 0.2),
            DesignTokens.neonCyan.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DesignTokens.neonMagenta.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.neonMagenta.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [DesignTokens.neonMagenta, DesignTokens.neonCyan],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'DFC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DATA FIGHT CENTRAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Pay-Per-View · Micro Packages · Credits',
                      style: TextStyle(color: Colors.white54, fontSize: 9),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: const Text(
                  '\$0/mo',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Key benefits
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildBenefit('No subscription', Icons.cancel),
              _buildBenefit('Buy single rounds \$1.99', Icons.timer),
              _buildBenefit('Aussie indie events', Icons.flag),
              _buildBenefit('Global coverage', Icons.public),
              _buildBenefit('Bulk credits save 33%', Icons.savings),
              _buildBenefit('UFC + Bellator + Local', Icons.sports_mma),
            ],
          ),
          const SizedBox(height: 10),
          // Price example
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calculate,
                  color: DesignTokens.neonGold,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                      children: [
                        TextSpan(text: 'Watch 1 fight/month: '),
                        TextSpan(
                          text: '\$9.99 ',
                          style: TextStyle(
                            color: DesignTokens.neonGold,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(text: 'vs Kayo '),
                        TextSpan(
                          text: '\$29.99',
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.greenAccent, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitorCard(_CompetitorInfo comp) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: comp.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: comp.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(comp.logo, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  comp.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Price
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: comp.color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              comp.ppvPrice != null
                  ? '\$${comp.ppvPrice!.toStringAsFixed(0)}/event'
                  : '\$${comp.monthlyPrice.toStringAsFixed(2)}/mo',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            comp.model,
            style: TextStyle(
              color: comp.color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            comp.fightContent,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 9,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          // Cons (issues)
          ...comp.cons
              .take(2)
              .map(
                (con) => Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.remove_circle,
                        color: Colors.redAccent,
                        size: 10,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          con,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 8,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildQuickComparison() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YEARLY COST COMPARISON',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          // Cost bars
          _buildCostBar('DFC (12 fights)', 120, DesignTokens.neonMagenta, true),
          _buildCostBar('Kayo Sports', 360, const Color(0xFF00C853), false),
          _buildCostBar(
            'UFC PPV (6 events)',
            480,
            const Color(0xFFD50000),
            false,
          ),
          _buildCostBar('DAZN', 300, const Color(0xFF555555), false),
          _buildCostBar('Paramount+', 168, const Color(0xFF0064FF), false),
          const SizedBox(height: 8),
          // Savings callout
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.greenAccent.withValues(alpha: 0.15),
                  Colors.greenAccent.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.greenAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.savings, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                      children: [
                        TextSpan(text: 'Casual fan watching '),
                        TextSpan(
                          text: '12 fights/year',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(text: ' saves up to '),
                        TextSpan(
                          text: '\$360',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.greenAccent,
                            fontSize: 12,
                          ),
                        ),
                        TextSpan(text: ' vs UFC PPV'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostBar(String label, double cost, Color color, bool highlight) {
    final maxCost = 480.0; // UFC PPV is the max for scale
    final width = (cost / maxCost).clamp(0.1, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: highlight ? Colors.white : Colors.white60,
                fontSize: 9,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: width,
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.6)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: highlight
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      '\$${cost.toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROMO CONTENT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPromoContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
              SizedBox(width: 8),
              Text(
                'EVENT HIGHLIGHTS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Highlight cards - Row 1
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildHighlightCard(
                  'WORLD-CLASS RING GIRLS',
                  'Australian Talent',
                  Icons.diamond,
                  DesignTokens.neonMagenta,
                ),
                _buildHighlightCard(
                  'LIVE COMMENTARY',
                  'Pro & Casual tracks',
                  Icons.mic,
                  DesignTokens.neonCyan,
                ),
                _buildHighlightCard(
                  'GLOBAL REACH',
                  '200+ Locations',
                  Icons.public,
                  DesignTokens.neonGreen,
                ),
                _buildHighlightCard(
                  '4K STREAMING',
                  'Crystal clear action',
                  Icons.hd,
                  DesignTokens.neonAmber,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Highlight cards - Row 2: Regional targeting
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRegionCard('🇺🇸', 'USA', 'Las Vegas · NYC · LA'),
                _buildRegionCard('🇬🇧', 'UK', 'London · Manchester'),
                _buildRegionCard('🇦🇺', 'AUSTRALIA', 'Melbourne · Sydney'),
                _buildRegionCard('🇵🇰', 'PAKISTAN', 'Karachi · Lahore'),
                _buildRegionCard('🇮🇳', 'INDIA', 'Mumbai · Delhi'),
                _buildRegionCard('🇵🇭', 'PHILIPPINES', 'Manila · Cebu'),
                _buildRegionCard('🇦🇪', 'MIDDLE EAST', 'Dubai · Abu Dhabi'),
                _buildRegionCard('🇪🇺', 'EUROPE', 'Paris · Berlin'),
                _buildRegionCard('🇯🇵', 'JAPAN', 'Tokyo · Osaka'),
                _buildRegionCard('🇧🇷', 'BRAZIL', 'São Paulo · Rio'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionCard(String flag, String region, String cities) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  region,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            cities,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 9,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PACKAGE TIER MODEL — For micro-packaging system
// ═══════════════════════════════════════════════════════════════════════════

class _PackageTier {
  final int id;
  final String name;
  final double price;
  final String desc;
  final IconData icon;
  final Color color;
  final bool isPopular;
  final String? badge;

  const _PackageTier({
    required this.id,
    required this.name,
    required this.price,
    required this.desc,
    required this.icon,
    required this.color,
    this.isPopular = false,
    this.badge,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// COMPETITOR INFO MODEL — For comparison section
// ═══════════════════════════════════════════════════════════════════════════

class _CompetitorInfo {
  final String name;
  final String logo;
  final double monthlyPrice;
  final double? ppvPrice;
  final String model;
  final String content;
  final String fightContent;
  final List<String> pros;
  final List<String> cons;
  final Color color;

  const _CompetitorInfo({
    required this.name,
    required this.logo,
    required this.monthlyPrice,
    this.ppvPrice,
    required this.model,
    required this.content,
    required this.fightContent,
    required this.pros,
    required this.cons,
    required this.color,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════════════

class _HeroPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Diagonal lines
    for (int i = -10; i < 20; i++) {
      canvas.drawLine(
        Offset(i * 40.0, 0),
        Offset(i * 40.0 + 200, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
