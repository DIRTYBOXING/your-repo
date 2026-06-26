import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_logos.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GLOBAL FIGHT MAP — DataFightCentral
// Live worldwide combat sports event visualiser
// Like FlightRadar24 — but for fighters
// ═══════════════════════════════════════════════════════════════════════════════

class GlobalFightMapScreen extends StatefulWidget {
  const GlobalFightMapScreen({super.key});

  @override
  State<GlobalFightMapScreen> createState() => _GlobalFightMapScreenState();
}

class _GlobalFightMapScreenState extends State<GlobalFightMapScreen>
    with TickerProviderStateMixin {
  Widget _globalPainMapOverlay() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _red.withValues(alpha: 0.15),
            _amber.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _red.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.healing, color: _red, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'GLOBAL PAIN INDEX',
                  style: TextStyle(
                    color: _red,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tracking injury patterns across 147 countries — 12.4K fighters monitored in real-time',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _painStat('ACL', '18%', _red),
                    const SizedBox(width: 8),
                    _painStat('Concussion', '12%', _amber),
                    const SizedBox(width: 8),
                    _painStat('Hand', '24%', _cyan),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _painStat(String label, String pct, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label $pct',
        style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w700),
      ),
    );
  }

  late AnimationController _pulseCtrl;
  late AnimationController _debrisCtrl;
  late TabController _mainTab;
  // ignore: unused_field
  GoogleMapController? _gMapController;

  // DFC dark map style
  static const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#0a1628"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8a92b8"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#0a1628"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#1a2a42"}]},
  {"featureType": "administrative.country", "elementType": "labels.text.fill", "stylers": [{"color": "#00d4ff"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0f1d33"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#4a6a8a"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#1a2a42"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#0f1d33"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#1a2a42"}]}
]
  ''';

  String _activeFilter = 'ALL';
  int _selectedRegion = -1;
  bool _johnScidaOnly = true;

  static const _cyan = Color(0xFF00E5FF);
  static const _red = Color(0xFFFF1744);
  static const _amber = Color(0xFFFFD600);
  static const _green = Color(0xFF00E676);
  static const _purple = Color(0xFF9C6FFF);
  static const _bg = Color(0xFF030810);
  static const _card = Color(0xFF0A1628);

  static const _filters = [
    'ALL',
    'MMA',
    'BOXING',
    'MUAY THAI',
    'BJJ',
    'KICKBOXING',
  ];

  static const String _johnScidaRegionName = 'Australia / Oceania';
  static const String _johnScidaAddress = 'Constance Street, St Albans, VIC';
  static const String _ultimateLegendsEventBase =
      'Melbourne Pavilion, Kensington, VIC';

  bool _isRegionVisible(_Region region) {
    if (_johnScidaOnly && region.name != _johnScidaRegionName) {
      return false;
    }
    if (_activeFilter == 'ALL') return true;
    final target = _activeFilter.toUpperCase();
    return region.disciplines.any((d) => d.toUpperCase() == target);
  }

  List<_Region> get _visibleRegions =>
      _regions.where(_isRegionVisible).toList(growable: false);

  static const _disciplines = {
    'ALL': Color(0xFF00E5FF),
    'MMA': Color(0xFFFF1744),
    'BOXING': Color(0xFFFFD600),
    'MUAY THAI': Color(0xFFFF6D00),
    'BJJ': Color(0xFF9C6FFF),
    'KICKBOXING': Color(0xFF00E676),
  };

  static const _regions = [
    _Region(
      name: 'North America',
      flag: '🇺🇸',
      events: 847,
      liveNow: 12,
      fighters: 24800,
      topPromo: 'UFC / PFL / Bellator',
      disciplines: ['MMA', 'Boxing', 'Kickboxing', 'Wrestling'],
      color: Color(0xFF00E5FF),
      dx: 0.18,
      dy: 0.32,
      lat: 39.8,
      lng: -98.5,
    ),
    _Region(
      name: 'Brazil',
      flag: '🇧🇷',
      events: 412,
      liveNow: 6,
      fighters: 18200,
      topPromo: 'UFC Brasil / SHOOTO BR',
      disciplines: ['MMA', 'BJJ', 'Muay Thai', 'Boxing'],
      color: Color(0xFF00E676),
      dx: 0.28,
      dy: 0.62,
      lat: -14.2,
      lng: -51.9,
    ),
    _Region(
      name: 'United Kingdom',
      flag: '🇬🇧',
      events: 318,
      liveNow: 4,
      fighters: 9400,
      topPromo: 'Cage Titans / MTK Global',
      disciplines: ['Boxing', 'MMA', 'Kickboxing'],
      color: Color(0xFFFF6D00),
      dx: 0.46,
      dy: 0.22,
      lat: 51.5,
      lng: -0.1,
    ),
    _Region(
      name: 'Europe',
      flag: '🇪🇺',
      events: 524,
      liveNow: 8,
      fighters: 15700,
      topPromo: 'KSW / FEN / Glory Kickboxing',
      disciplines: ['Kickboxing', 'MMA', 'Boxing', 'Muay Thai'],
      color: Color(0xFFFFD600),
      dx: 0.50,
      dy: 0.26,
      lat: 48.9,
      lng: 10.4,
    ),
    _Region(
      name: 'Japan',
      flag: '🇯🇵',
      events: 392,
      liveNow: 5,
      fighters: 12100,
      topPromo: 'RIZIN / Pancrase / DEEP',
      disciplines: ['MMA', 'Kickboxing', 'K-1', 'BJJ'],
      color: Color(0xFFFF1744),
      dx: 0.83,
      dy: 0.28,
      lat: 36.2,
      lng: 138.3,
    ),
    _Region(
      name: 'Thailand',
      flag: '🇹🇭',
      events: 680,
      liveNow: 14,
      fighters: 31400,
      topPromo: 'ONE Championship / Lumpinee',
      disciplines: ['Muay Thai', 'MMA', 'Kickboxing'],
      color: Color(0xFFFF6D00),
      dx: 0.75,
      dy: 0.44,
      lat: 15.9,
      lng: 100.9,
    ),
    _Region(
      name: 'UAE / Middle East',
      flag: '🇦🇪',
      events: 198,
      liveNow: 3,
      fighters: 6800,
      topPromo: 'UAE Warriors / KHK MMA',
      disciplines: ['MMA', 'Boxing', 'Grappling'],
      color: Color(0xFF9C6FFF),
      dx: 0.60,
      dy: 0.40,
      lat: 25.3,
      lng: 55.3,
    ),
    _Region(
      name: 'Australia / Oceania',
      flag: '🇦🇺',
      events: 224,
      liveNow: 3,
      fighters: 7200,
      topPromo: 'Team Ultimate / Ultimate Legends',
      disciplines: ['MMA', 'Boxing', 'Muay Thai'],
      color: Color(0xFF00E5FF),
      dx: 0.83,
      dy: 0.72,
      lat: -25.3,
      lng: 133.8,
    ),
  ];

  static const _liveTicker = [
    '📣 DFC excited to announce IBC III — first global rollout wave complete',
    '🎥 Fighters spotlight: proud effort from every athlete on the IBC III card',
    '🌍 Global push active: AU · NZ · USA · UK · Europe · Asia · Middle East',
    '🔴 LIVE — Bellator 324 · Madison Square Garden · 4 bouts remaining',
    '🔴 LIVE — ONE Friday Fights 98 · Bangkok · Muay Thai main event now',
    '🔴 LIVE — KSW 97 · Warsaw · Heavyweight title bout in progress',
    '⚡ NEXT — UFC on ESPN 62 · Las Vegas · Main card in 2h 14m',
    '🔴 LIVE — RIZIN 52 · Saitama Super Arena · 3 bouts remaining',
    '⚡ NEXT — Glory 101 · Rotterdam · Super Bantamweight title bout',
    '🔴 LIVE — UAE Warriors 48 · Abu Dhabi · 5 active bouts',
    '⚡ RESULTS — Cage Titans 178 · London · Main event decision: Souza wins',
  ];

  final int _tickerIndex = 0;

  @override
  void initState() {
    super.initState();
    _mainTab = TabController(length: 4, vsync: this);
    _debrisCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _mainTab.dispose();
    _debrisCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 4),
            _buildLiveTicker(),
            _buildPromotionEngineBanner(),
            _buildGlobalStats(),
            _buildFilters(),
            _buildMainTabBar(),
            Expanded(
              child: TabBarView(
                controller: _mainTab,
                children: [
                  // TAB 1 — MAP
                  Column(
                    children: [
                      Expanded(child: _buildWorldMap(context)),
                      if (_selectedRegion >= 0) _buildRegionPanel(),
                    ],
                  ),
                  // TAB 2 — ANALYTICS
                  _buildAnalyticsTab(),
                  // TAB 3 — MARKETING
                  _buildMarketingTab(),
                  // TAB 4 — EARTH HEALTH
                  _buildEarthHealthTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(color: _cyan.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white70,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Globe icon
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, _) => Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF0A3060), Color(0xFF030810)],
                ),
                border: Border.all(
                  color: _cyan.withValues(alpha: 0.5 + 0.5 * _pulseCtrl.value),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _cyan.withValues(alpha: 0.3 * _pulseCtrl.value),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.public, color: _cyan, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GLOBAL FIGHT MAP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  _johnScidaOnly
                      ? 'Ultimate Legends · Founded by John Scida · Promotion Lane Active'
                      : 'Promotion engine behind global events - 2026',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Live indicator
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _red.withValues(alpha: 0.4 + 0.4 * _pulseCtrl.value),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _red.withValues(
                        alpha: 0.6 + 0.4 * _pulseCtrl.value,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: _red,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
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

  // ── LIVE TICKER ────────────────────────────────────────────────────────────
  Widget _buildLiveTicker() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cyan.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _cyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'TICKER',
              style: TextStyle(
                color: _cyan,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _liveTicker[_tickerIndex],
                key: ValueKey(_tickerIndex),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionEngineBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_red.withValues(alpha: 0.18), _cyan.withValues(alpha: 0.14)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cyan.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DFC ROLLOUT MODE — IBC III FIRST WAVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'DFC works from the back to push and promote. Promoters hold the spotlight. Fighters get lights, camera, action — every event, every country.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── GLOBAL STATS ───────────────────────────────────────────────────────────
  Widget _buildGlobalStats() {
    final visible = _visibleRegions;
    final fighters = visible.fold<int>(0, (s, r) => s + r.fighters);
    final liveNow = visible.fold<int>(0, (s, r) => s + r.liveNow);
    final events = visible.fold<int>(0, (s, r) => s + r.events);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          _statBox('$events', 'EVENTS', _cyan),
          const SizedBox(width: 8),
          _statBox('$liveNow', 'LIVE NOW', _red),
          const SizedBox(width: 8),
          _statBox(
            fighters.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]},',
            ),
            'FIGHTERS',
            _green,
          ),
          const SizedBox(width: 8),
          _statBox('${visible.length}', 'REGIONS', _amber),
          const SizedBox(width: 8),
          _statBox(_johnScidaOnly ? '1' : '147', 'COUNTRIES', _purple),
        ],
      ),
    );
  }

  Widget _statBox(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FILTERS ────────────────────────────────────────────────────────────────
  Widget _buildFilters() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          GestureDetector(
            onTap: () => setState(() {
              _johnScidaOnly = !_johnScidaOnly;
              _selectedRegion = _johnScidaOnly
                  ? _regions.indexWhere((r) => r.name == _johnScidaRegionName)
                  : -1;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _johnScidaOnly
                    ? _purple.withValues(alpha: 0.24)
                    : const Color(0xFF0A1628),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _johnScidaOnly ? _purple : Colors.white12,
                  width: _johnScidaOnly ? 1.5 : 1,
                ),
              ),
              child: Text(
                'ULTIMATE LEGENDS',
                style: TextStyle(
                  color: _johnScidaOnly ? _purple : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          ..._filters.map((f) {
            final active = _activeFilter == f;
            final color = _disciplines[f] ?? _cyan;
            return GestureDetector(
              onTap: () => setState(() {
                _activeFilter = f;
                _selectedRegion = -1;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? color.withValues(alpha: 0.2)
                      : const Color(0xFF0A1628),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? color : Colors.white12,
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    color: active ? color : Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── WORLD MAP (Real Google Map) ─────────────────────────────────────────
  Set<Marker> _buildRegionMarkers() {
    final visible = _visibleRegions;
    final markers = <Marker>{};

    for (final r in visible) {
      final idx = _regions.indexOf(r);
      markers.add(
        Marker(
          markerId: MarkerId('region_${r.name}'),
          position: LatLng(r.lat, r.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            r.color == _cyan
                ? BitmapDescriptor.hueCyan
                : r.color == _red
                    ? BitmapDescriptor.hueRed
                    : r.color == _amber
                        ? BitmapDescriptor.hueYellow
                        : r.color == _green
                            ? BitmapDescriptor.hueGreen
                            : r.color == _purple
                                ? BitmapDescriptor.hueViolet
                                : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: '${r.flag} ${r.name}',
            snippet:
                '${r.events} events · ${r.liveNow} live · ${r.topPromo}',
          ),
          onTap: () => setState(() => _selectedRegion = idx),
        ),
      );
    }

    // John Scida / Team Ultimate marker
    if (_johnScidaOnly) {
      markers.add(
        Marker(
          markerId: const MarkerId('john_scida_hq'),
          position: const LatLng(-37.7430, 144.8100),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow,
          ),
          infoWindow: const InfoWindow(
            title: '⭐ TEAM ULTIMATE HQ',
            snippet: _johnScidaAddress,
          ),
        ),
      );
      markers.add(
        Marker(
          markerId: const MarkerId('ultimate_legends_events'),
          position: const LatLng(-37.7876, 144.9278),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow,
          ),
          infoWindow: const InfoWindow(
            title: '🏆 ULTIMATE LEGENDS EVENTS',
            snippet: _ultimateLegendsEventBase,
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildWorldMap(BuildContext context) {
    final markers = _buildRegionMarkers();
    // When focused on Ultimate Legends, zoom to Melbourne
    final camTarget = _johnScidaOnly
        ? const LatLng(-37.76, 144.87)
        : const LatLng(15.0, 20.0);
    final camZoom = _johnScidaOnly ? 9.0 : 2.0;

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: camTarget,
            zoom: camZoom,
          ),
          markers: markers,
          style: _darkMapStyle,
          onMapCreated: (controller) {
            _gMapController = controller;
          },
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          compassEnabled: false,
          onTap: (_) => setState(() => _selectedRegion = -1),
        ),
        // DFC logo overlay
        Positioned(
          right: 14,
          top: 14,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _cyan.withValues(alpha: 0.45),
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              AppLogos.icon,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.shield,
                color: _cyan,
                size: 18,
              ),
            ),
          ),
        ),
        // LIVE badge
        Positioned(
          left: 14,
          top: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _red.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: _red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'LIVE MAP',
                  style: TextStyle(
                    color: _red,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── REGION DETAIL PANEL ────────────────────────────────────────────────────
  Widget _buildRegionPanel() {
    final r = _regions[_selectedRegion];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: r.color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: r.color.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(r.flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name.toUpperCase(),
                      style: TextStyle(
                        color: r.color,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      r.topPromo,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedRegion = -1),
                child: const Icon(Icons.close, color: Colors.white38, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _panelStat('${r.events}', 'EVENTS', r.color),
              _panelStat('${r.liveNow}', 'LIVE', _red),
              _panelStat(
                '${(r.fighters / 1000).toStringAsFixed(1)}k',
                'FIGHTERS',
                _green,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: r.disciplines
                .map(
                  (d) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: (_disciplines[d.toUpperCase()] ?? _cyan)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (_disciplines[d.toUpperCase()] ?? _cyan)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      d,
                      style: TextStyle(
                        color: _disciplines[d.toUpperCase()] ?? _cyan,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => context.push(
              _johnScidaOnly ? '/events?promoter=ultimate-legends' : '/events',
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: r.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: r.color.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.center,
              child: Text(
                _johnScidaOnly
                    ? 'ULTIMATE LEGENDS · GET TICKETS →'
                    : 'VIEW ${r.name.toUpperCase()} EVENTS →',
                style: TextStyle(
                  color: r.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── MAIN TAB BAR ───────────────────────────────────────────────────────────
  Widget _buildMainTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cyan.withValues(alpha: 0.15)),
      ),
      child: TabBar(
        controller: _mainTab,
        indicator: BoxDecoration(
          color: _cyan.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _cyan.withValues(alpha: 0.4)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: _cyan,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.public, size: 14), text: 'MAP'),
          Tab(icon: Icon(Icons.bar_chart, size: 14), text: 'ANALYTICS'),
          Tab(icon: Icon(Icons.campaign, size: 14), text: 'MARKETING'),
          Tab(icon: Icon(Icons.eco, size: 14), text: 'EARTH'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TAB 4 — EARTH HEALTH (Atmosphere + Solar + Personal + Planet)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildEarthHealthTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
      children: [
        // ── Fighters' Heart Banner ──────────────────────────────────────────
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_red.withAlpha(30), _green.withAlpha(20)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _green.withAlpha(40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.volunteer_activism, color: _green, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'FIGHTERS: HEARTS & HEROES',
                    style: TextStyle(
                      color: _green,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Fighters have bigger hearts and souls. We come from struggle, we care more than most. Fighting and caring for our planet is our duty—because it carries our children’s future. A better planet is a better place for them. Let’s end conflict and violence, one fighter or hero at a time.',
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        // ── Global Pain Map ───────────────────────────────────────────────
        _sectionHeader(
          Icons.warning_amber_rounded,
          'GLOBAL PAIN MAP — VIOLENCE, SUICIDE & ABUSE',
          _red,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _red.withAlpha(60)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Every minute, someone is lost to violence, suicide, or abuse. This map visualizes global pain — not to shock, but to drive action. Data is anonymized, sourced from public health, and survivor stories. Our mission: make the invisible visible, and stop the suffering before it happens.',
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              _globalPainMapOverlay(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // ── Solar System / Orbital Debris Viewer ──────────────────────────
        _sectionHeader(
          Icons.satellite_alt,
          'ORBITAL DEBRIS FIELD — LIVE SIMULATION',
          _cyan,
        ),
        const SizedBox(height: 8),
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: const Color(0xFF01050F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cyan.withValues(alpha: 0.18)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _debrisCtrl,
                  builder: (_, _) => CustomPaint(
                    painter: _SolarSystemPainter(
                      t: _debrisCtrl.value,
                      pulseT: _pulseCtrl.value,
                    ),
                    size: const Size(double.infinity, 300),
                  ),
                ),
                // Overlay labels
                const Positioned(
                  top: 10,
                  left: 14,
                  child: Text(
                    'ORBITAL DEBRIS SIMULATION',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Positioned(
                  top: 24,
                  left: 14,
                  child: Text(
                    '~13,000 tracked objects  •  LEO / MEO / GEO',
                    style: TextStyle(color: Colors.white30, fontSize: 8),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _red.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _red.withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      '⚠ KESSLER SYNDROME RISK ZONE',
                      style: TextStyle(
                        color: Color(0xFFFF1744),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Debris stats row
        Row(
          children: [
            _earthStatChip('13,000+', 'Tracked\nObjects', _red),
            _earthStatChip('27,000', 'km/h', _amber),
            _earthStatChip('LEO', 'Most\nCrowded', _cyan),
            _earthStatChip('128', 'Nations\nImpacted', _green),
            _earthStatChip('1957', 'Since\nSputnik', _purple),
          ],
        ),
        const SizedBox(height: 16),

        // ── Atmospheric Layers ───────────────────────────────────────────────
        _sectionHeader(Icons.air, 'ATMOSPHERIC HEALTH LAYERS', _green),
        const SizedBox(height: 8),
        _atmosphericLayers(),
        const SizedBox(height: 16),

        // ── Ecological Determinants of Health ───────────────────────────────
        _sectionHeader(
          Icons.favorite_border,
          'ECOLOGICAL DETERMINANTS OF HEALTH',
          _red,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _red.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Human-caused changes to Earth systems directly drive health impacts — from infectious disease to mental health. DFC tracks the intersection of planetary and fighter wellness.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _ecoDetermGrid(),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Planetary Health Metrics ─────────────────────────────────────────
        _sectionHeader(Icons.public, 'PLANETARY HEALTH METRICS 2026', _cyan),
        const SizedBox(height: 8),
        _planetaryMetrics(),
        const SizedBox(height: 16),

        // ── Personal Health Integrations ────────────────────────────────────
        _sectionHeader(
          Icons.watch_outlined,
          'PERSONAL HEALTH INTEGRATIONS',
          _amber,
        ),
        const SizedBox(height: 8),
        _personalHealthIntegrations(),
        const SizedBox(height: 16),

        // ── Google / AI / App Health ─────────────────────────────────────────
        _sectionHeader(
          Icons.hub_outlined,
          'ALL-HEALTH INTELLIGENCE HUB',
          _purple,
        ),
        const SizedBox(height: 8),
        _allHealthHub(),
        const SizedBox(height: 16),

        // ── Climate Impact on Combat Sports ─────────────────────────────────
        _sectionHeader(
          Icons.thermostat,
          'CLIMATE × FIGHTER PERFORMANCE',
          _orange,
        ),
        const SizedBox(height: 8),
        _climateImpactSection(),
        const SizedBox(height: 16),

        // ── Atmospheric Gases & Pressure ─────────────────────────────────────
        _sectionHeader(
          Icons.bubble_chart,
          'ATMOSPHERIC GASES & PRESSURE CHART',
          _cyan,
        ),
        const SizedBox(height: 8),
        _atmosphericGasesPanel(),
        const SizedBox(height: 16),

        // ── Ozone Layer & UV Radiation ───────────────────────────────────────
        _sectionHeader(
          Icons.wb_sunny_outlined,
          'OZONE LAYER HEALTH & UV RADIATION',
          const Color(0xFFFFD600),
        ),
        const SizedBox(height: 8),
        _ozoneUVPanel(),
        const SizedBox(height: 16),

        // ── Solar Radiation & Space Weather ──────────────────────────────────
        _sectionHeader(
          Icons.flare,
          'SUN RADIATION & SPACE WEATHER DANGERS',
          const Color(0xFFFF6D00),
        ),
        const SizedBox(height: 8),
        _solarRadiationPanel(),
        const SizedBox(height: 16),

        // ── Global Conflict Heat Map ──────────────────────────────────────────
        _sectionHeader(Icons.dangerous, 'GLOBAL CONFLICT & WAR HEAT MAP', _red),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _red.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _red.withValues(alpha: 0.2)),
          ),
          child: Text(
            'DFC was built to REPOWER HUMANITY — one person at a time. Every fighter we lift up is one less soul lost to war, poverty, and despair. Understanding global conflict is the first step to healing it.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _globalConflictHeatmap(),
        const SizedBox(height: 16),

        // ── Pollution Heat Map ────────────────────────────────────────────────
        _sectionHeader(
          Icons.smoke_free,
          'GLOBAL POLLUTION HEAT MAP',
          const Color(0xFFFF6D00),
        ),
        const SizedBox(height: 8),
        _pollutionHeatmap(),
        const SizedBox(height: 20),

        // ── Rocket Launches & Space Emissions ────────────────────────────────────
        _sectionHeader(
          Icons.rocket_launch,
          'ROCKET LAUNCHES & EMISSION TRACKER',
          _cyan,
        ),
        const SizedBox(height: 8),
        _rocketLaunchesPanel(),
        const SizedBox(height: 16),

        // ── Donations Hub ─────────────────────────────────────────────────────────
        _sectionHeader(
          Icons.volunteer_activism,
          'SAVE HUMANITY — DONATE NOW',
          _green,
        ),
        const SizedBox(height: 8),
        _donationsHub(),
        const SizedBox(height: 20),

        // ── Repower Humanity Banner ────────────────────────────────────────────
        _repowerHumanityBanner(),
      ],
    );
  }

  // ── Atmospheric Layers Visualiser ─────────────────────────────────────────
  Widget _atmosphericLayers() {
    final layers = [
      const _AtmoLayer(
        'EXOSPHERE',
        '10,000 km+',
        'Satellites + debris, no weather',
        Color(0xFF001133),
        0.06,
      ),
      const _AtmoLayer(
        'THERMOSPHERE',
        '80–10,000 km',
        'Aurora, ISS orbit, X-ray absorption',
        Color(0xFF002255),
        0.10,
      ),
      const _AtmoLayer(
        'MESOSPHERE',
        '50–80 km',
        'Meteors burn up here, coldest layer',
        Color(0xFF003377),
        0.14,
      ),
      const _AtmoLayer(
        'STRATOSPHERE',
        '12–50 km',
        'Ozone layer — UV protection — aviation',
        Color(0xFF0044AA),
        0.18,
      ),
      const _AtmoLayer(
        'TROPOSPHERE',
        '0–12 km',
        'Weather, climate, all life exists here',
        Color(0xFF1A5FAA),
        0.38,
      ),
    ];
    return Column(
      children: layers.map((l) {
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: l.color.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showComingSoon(
                title: 'Atmospheric layer details',
                message:
                    'Detailed telemetry and live readings are in development.',
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            l.altitude,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        l.desc,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 9,
                          height: 1.3,
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: l.health),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Ecological Determinants Grid ──────────────────────────────────────────
  Widget _ecoDetermGrid() {
    final items = [
      ('Climate Change', Icons.thermostat, _red, 'CO₂ 424ppm'),
      (
        'Pollution',
        Icons.smoke_free,
        const Color(0xFFFF6D00),
        'Air/Soil/Water',
      ),
      ('Biodiversity Loss', Icons.eco, _green, '1M species at risk'),
      (
        'Resource Scarcity',
        Icons.water_drop_outlined,
        _cyan,
        'Freshwater stress',
      ),
      ('Land Use Change', Icons.landscape_outlined, _amber, '+2.4M ha/yr lost'),
      ('Marine Degradation', Icons.waves, _blue, '30% reefs bleached'),
      ('Nutrient Overload', Icons.science_outlined, _purple, 'N+P imbalance'),
      ('Novel Entities', Icons.dangerous_outlined, _pink, 'Micro/nanoplastics'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 3.0,
      children: items
          .map(
            (item) => Container(
              decoration: BoxDecoration(
                color: item.$3.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: item.$3.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Icon(item.$2, color: item.$3, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: TextStyle(
                            color: item.$3,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          item.$4,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Planetary Health Metrics ───────────────────────────────────────────────
  Widget _planetaryMetrics() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(_cyan),
      child: Column(
        children: [
          _earthMetricRow(
            Icons.thermostat,
            'Global Temperature Anomaly',
            '+1.54°C',
            _red,
            0.77,
          ),
          _earthMetricRow(
            Icons.co2,
            'Atmospheric CO₂',
            '424 ppm',
            const Color(0xFFFF6D00),
            0.85,
          ),
          _earthMetricRow(
            Icons.ac_unit,
            'Arctic Sea Ice',
            '-13% per decade',
            _cyan,
            0.35,
          ),
          _earthMetricRow(
            Icons.waves,
            'Sea Level Rise',
            '+4.2mm/yr',
            _blue,
            0.60,
          ),
          _earthMetricRow(
            Icons.forest,
            'Forest Cover Remaining',
            '68.1%',
            _green,
            0.68,
          ),
          _earthMetricRow(
            Icons.water,
            'Ocean Acidification pH',
            '8.04 (-0.11)',
            _amber,
            0.45,
          ),
          _earthMetricRow(
            Icons.air,
            'Global AQI Average',
            '62 (Moderate)',
            const Color(0xFFFF6D00),
            0.62,
          ),
          _earthMetricRow(
            Icons.energy_savings_leaf,
            'Renewable Energy Share',
            '34.6%',
            _green,
            0.35,
          ),
        ],
      ),
    );
  }

  Widget _earthMetricRow(
    IconData icon,
    String label,
    String val,
    Color col,
    double frac,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(icon, color: col, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      val,
                      style: TextStyle(
                        color: col,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: frac,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation(col),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Personal Health Integrations ──────────────────────────────────────────
  Widget _personalHealthIntegrations() {
    final platforms = [
      const _HealthPlatform(
        'Google Fit',
        Icons.favorite,
        _red,
        'Steps / Heart Rate / Sleep / Activity',
        true,
        ['12,480 steps', 'HR: 62 bpm', 'Sleep: 7h 14m', 'Active: 58min'],
      ),
      const _HealthPlatform(
        'Apple Health',
        Icons.apple,
        Colors.white,
        'HealthKit · iOS + Apple Watch',
        true,
        ['SpO2: 98%', 'HRV: 52ms', 'ECG: Normal', 'BP: 120/78'],
      ),
      const _HealthPlatform(
        'Fitbit / Google',
        Icons.watch,
        Color(0xFF00B0FF),
        'Charge 6 · Premium data sync',
        true,
        ['Body battery: 82%', 'Stress: Low', 'Skin Temp: +0.2°C', 'VO₂: 48'],
      ),
      const _HealthPlatform(
        'Garmin Connect',
        Icons.sports_motorsports,
        _blue,
        'Tactical / Endurance metrics',
        false,
        ['Training Load: 892', 'Recovery: 24h', 'VO₂max: 52', 'Altitude HR'],
      ),
      const _HealthPlatform(
        'WHOOP 4.0',
        Icons.loop,
        _purple,
        'Strain · Recovery · Sleep Coach',
        false,
        ['Recovery: 87%', 'Strain: 14.2', 'HRV trend: ↑', 'RHR: 44'],
      ),
      const _HealthPlatform(
        'Polar H10',
        Icons.monitor_heart,
        _red,
        'Chest strap ECG-grade accuracy',
        false,
        ['Pure HR zone', 'ECG stream', 'Running Cadence', 'Swim HR'],
      ),
      const _HealthPlatform(
        'Samsung Health',
        Icons.phone_android,
        Color(0xFF1428A0),
        'Galaxy Watch · BioActive sensor',
        false,
        ['Body composition', 'Blood Glucose', 'Snore detect', 'Stress'],
      ),
      const _HealthPlatform(
        'Oura Ring',
        Icons.circle_outlined,
        _amber,
        'Gen 4 · Readiness + Recovery',
        false,
        ['Readiness: 78', 'Temp trend', 'Deep sleep: 1h54m', 'Resilience'],
      ),
    ];

    return Column(
      children: platforms
          .map(
            (p) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: (p.connected ? _green : Colors.white24).withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(p.icon, color: p.color, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: TextStyle(
                                color: p.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              p.subtitle,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (p.connected ? _green : Colors.white24)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (p.connected ? _green : Colors.white24)
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          p.connected ? 'CONNECTED' : 'CONNECT',
                          style: TextStyle(
                            color: p.connected ? _green : Colors.white54,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (p.connected) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: p.metrics
                          .map(
                            (m) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: p.color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: p.color.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                m,
                                style: TextStyle(
                                  color: p.color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ── All-Health Intelligence Hub ───────────────────────────────────────────
  Widget _allHealthHub() {
    return Column(
      children: [
        // App health
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDeco(_purple),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(Icons.rocket_launch, 'DFC APP HEALTH', _purple),
              const SizedBox(height: 10),
              Row(
                children: [
                  _earthStatChip('99.9%', 'Uptime', _green),
                  _earthStatChip('<80ms', 'API\nLatency', _cyan),
                  _earthStatChip('124K', 'DAU', _amber),
                  _earthStatChip('0', 'Errors', _green),
                  _earthStatChip('v3.1', 'Live', _purple),
                ],
              ),
              const SizedBox(height: 12),
              _sectionHeader(
                Icons.psychology,
                'AI HEALTH MODELS ACTIVE',
                _cyan,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _aiChip('Neural Coach', _cyan),
                  _aiChip('Injury Predictor', _red),
                  _aiChip('Fight Recommender', _amber),
                  _aiChip('Nutrition AI', _green),
                  _aiChip('Sleep Coach', _purple),
                  _aiChip('Stress Analyser', const Color(0xFFFF6D00)),
                  _aiChip('Dehydration Alert', _cyan),
                  _aiChip('BP Watch (TGA)', _red),
                  _aiChip('Fight Camp Planner', _amber),
                  _aiChip('Mental Health Bot', _pink),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Google Health Connection
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDeco(_blue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.favorite,
                    color: Color(0xFFEA4335),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'GOOGLE HEALTH CONNECT',
                    style: TextStyle(
                      color: Color(0xFFEA4335),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'SYNCING',
                      style: TextStyle(
                        color: _green,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Health Connect bridges DFC with Google Fit, Fitbit, Samsung Health, Polar, and all Android health platforms. All permissions scoped to read-only, HIPAA-aligned, and revocable at any time.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _permChip('READ Steps', _green),
                  _permChip('READ Heart Rate', _red),
                  _permChip('READ Sleep', _blue),
                  _permChip('READ SpO2', _cyan),
                  _permChip('READ Nutrition', _amber),
                  _permChip('READ Body Mass', _purple),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Climate × Fighter Performance ─────────────────────────────────────────
  Widget _climateImpactSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(_orange),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Climate change isn\'t abstract — it directly affects your performance, recovery, and safety as a fighter.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          _climateRow(
            Icons.thermostat,
            '+1.54°C avg temp',
            'Extended recovery windows needed. Core temp regulation harder in hot camps.',
            _red,
          ),
          _climateRow(
            Icons.water_drop,
            'Drought × Dehydration',
            'Water scarcity in training regions increases heat stroke risk by 34%.',
            _cyan,
          ),
          _climateRow(
            Icons.air,
            'Air Quality Events',
            'Wildfire smoke AQI >150 = skip outdoor training. DFC alerts auto-trigger.',
            const Color(0xFFFF6D00),
          ),
          _climateRow(
            Icons.sick,
            'Disease Vector Spread',
            'Warmer climates expand range of dengue, malaria. Fighter travel briefings updated.',
            _green,
          ),
          _climateRow(
            Icons.psychology,
            'Mental Health + Heat',
            'Studies show 0.9% increase in mental health crises per +1°C. Camp planning affected.',
            _purple,
          ),
          _climateRow(
            Icons.flash_on,
            'Extreme Weather Events',
            'Event cancellations up 28% since 2020 due to climate-linked weather.',
            _amber,
          ),
        ],
      ),
    );
  }

  Widget _climateRow(IconData icon, String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 13),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Atmospheric Gases & Pressure Panel ────────────────────────────────────
  Widget _atmosphericGasesPanel() {
    final gases = [
      (
        'Nitrogen  N₂',
        78.09,
        _blue,
        'Inert backbone — vital for protein synthesis',
      ),
      (
        'Oxygen  O₂',
        20.95,
        _cyan,
        'Life support — drops dangerously at altitude',
      ),
      ('Argon  Ar', 0.93, _purple, 'Noble gas — non-reactive, climate neutral'),
      (
        'CO₂',
        0.042,
        const Color(0xFFFF1744),
        '↑424 ppm — primary climate driver +51% since 1800',
      ),
      (
        'Methane  CH₄',
        0.00018,
        _amber,
        'Livestock + fossil fuels — 87× CO₂ warming potency',
      ),
      (
        'Ozone  O₃',
        0.00006,
        const Color(0xFFFFD600),
        'Stratospheric UV shield — depleting over Antarctica',
      ),
      (
        'N₂O',
        0.00003,
        _pink,
        'Laughing gas — 273× CO₂ global warming potential',
      ),
      (
        'Water Vapour',
        1.00,
        const Color(0xFF80DEEA),
        'Varies 0–4% — humidity, clouds, weather engine',
      ),
    ];
    final monthCo2 = [
      ('J', 422.3),
      ('F', 422.7),
      ('M', 423.1),
      ('A', 424.9),
      ('M', 424.1),
      ('J', 422.5),
      ('J', 421.8),
      ('A', 422.0),
      ('S', 422.6),
      ('O', 423.4),
      ('N', 423.9),
      ('D', 424.1),
    ];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDeco(_cyan),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'COMPOSITION AT SEA LEVEL',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              ...gases.map((g) {
                final bar = (g.$2 > 1 ? g.$2 / 100.0 : (g.$2 / 80.0)).clamp(
                  0.003,
                  1.0,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              g.$1,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${g.$2}%',
                            style: TextStyle(
                              color: g.$3,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              g.$4,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Colors.white24,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: bar,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [g.$3.withValues(alpha: 0.5), g.$3],
                                ),
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  BoxShadow(
                                    color: g.$3.withValues(alpha: 0.45),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDeco(_purple),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ATMOSPHERIC PRESSURE BY ALTITUDE',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              ...[
                (
                  'Sea Level',
                  '101,325 Pa',
                  'Human baseline — 1 atm',
                  1.00,
                  _green,
                ),
                (
                  '1,000 m',
                  '89,875 Pa',
                  'Mountain training — mild altitude',
                  0.89,
                  _green,
                ),
                (
                  '3,000 m',
                  '70,109 Pa',
                  'Altitude camp — VO₂max drops ~6%',
                  0.69,
                  _amber,
                ),
                (
                  '5,000 m',
                  '54,048 Pa',
                  'Everest base — serious hypoxia risk',
                  0.53,
                  _orange,
                ),
                (
                  '8,849 m',
                  '31,673 Pa',
                  'Everest summit — 31% of sea level',
                  0.31,
                  _red,
                ),
                (
                  '12,000 m',
                  '19,400 Pa',
                  'Commercial aviation pressurised cabin',
                  0.19,
                  _red,
                ),
                (
                  '50,000 m',
                  '80 Pa',
                  'Stratopause — ozone layer peak',
                  0.003,
                  _pink,
                ),
                (
                  '100,000 m',
                  '0.032 Pa',
                  'Kármán line — space begins here',
                  0.0001,
                  _purple,
                ),
              ].map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 76,
                        child: Text(
                          r.$1,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 88,
                        child: Text(
                          r.$2,
                          style: TextStyle(
                            color: r.$5,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.$3,
                              style: const TextStyle(
                                color: Colors.white24,
                                fontSize: 8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: r.$4.clamp(0.0, 1.0),
                                minHeight: 4,
                                backgroundColor: Colors.white10,
                                valueColor: AlwaysStoppedAnimation(r.$5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDeco(_red),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'CO₂ CONCENTRATION TREND 2025',
                      style: TextStyle(
                        color: Color(0xFFFF1744),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _red.withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      '↑ 424.1 ppm',
                      style: TextStyle(
                        color: Color(0xFFFF1744),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 72,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: monthCo2.map((m) {
                    final h = ((m.$2 - 421.0) / 4.0).clamp(0.05, 1.0);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: 56 * h,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [_red.withValues(alpha: 0.5), _red],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _red.withValues(alpha: 0.35),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              m.$1,
                              style: const TextStyle(
                                color: Colors.white30,
                                fontSize: 7,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Mauna Loa Observatory, NOAA 2025  •  Pre-industrial: 280 ppm  •  +51.5% rise',
                style: TextStyle(color: Colors.white30, fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Ozone & UV Panel ──────────────────────────────────────────────────────
  Widget _ozoneUVPanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D0020), Color(0xFF1A0035)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFD600).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD600).withValues(alpha: 0.06),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFFFFD600),
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'OZONE LAYER STATUS 2026',
                    style: TextStyle(
                      color: Color(0xFFFFD600),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _amber.withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      'RECOVERING ↑',
                      style: TextStyle(
                        color: Color(0xFFFFAB00),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...[
                (
                  'Antarctic Ozone Hole',
                  '23.2M km²',
                  'Peak Sep 2025 — still 4× size of Australia',
                  0.65,
                  _red,
                ),
                (
                  'Dobson Units (global)',
                  '298 DU',
                  'Healthy = 300+ DU. Dropped -2 DU vs 2024',
                  0.72,
                  _amber,
                ),
                (
                  'Arctic Ozone',
                  '310 DU',
                  'Recovering — Montreal Protocol working ✓',
                  0.82,
                  _green,
                ),
                (
                  'Tropical Belt',
                  '255 DU',
                  'Lower naturally — UV highest at equator',
                  0.55,
                  _orange,
                ),
                (
                  'CFC Reduction',
                  '-67%',
                  'Since 1990 ban. Greatest env. success story',
                  0.67,
                  _green,
                ),
              ].map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          r.$1,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 62,
                        child: Text(
                          r.$2,
                          style: TextStyle(
                            color: r.$5,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.$3,
                              style: const TextStyle(color: Colors.white24),
                            ),
                            const SizedBox(height: 2),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: r.$4,
                                minHeight: 3,
                                backgroundColor: Colors.white10,
                                valueColor: AlwaysStoppedAnimation(r.$5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDeco(const Color(0xFFFFD600)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'UV INDEX DANGER SCALE — FIGHTER HEALTH GUIDE',
                style: TextStyle(
                  color: Color(0xFFFFD600),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              ...[
                (
                  'UV 0–2',
                  'LOW',
                  _green,
                  'Safe. Train outdoors freely. No protection needed.',
                ),
                (
                  'UV 3–5',
                  'MODERATE',
                  const Color(0xFFFFD600),
                  'Use SPF 30+. Wear hat + shades. Avoid peak noon.',
                ),
                (
                  'UV 6–7',
                  'HIGH',
                  _orange,
                  'SPF 50+. Limit 10am–2pm training. Reapply every 90 min.',
                ),
                (
                  'UV 8–10',
                  'VERY HIGH',
                  _red,
                  '⚠ Seek shade. Burns in 20 min. Cancel outdoor camp.',
                ),
                (
                  'UV 11+',
                  'EXTREME',
                  _pink,
                  '🚨 DO NOT train outdoors. Damage in <10 min. Gamma overlap zone.',
                ),
              ].map(
                (u) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: u.$3.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: u.$3.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: u.$3.withValues(alpha: 0.06),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 38,
                        decoration: BoxDecoration(
                          color: u.$3,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: u.$3.withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 48,
                        child: Text(
                          u.$1,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 8,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: u.$3.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          u.$2,
                          style: TextStyle(
                            color: u.$3,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          u.$4,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 9,
                            height: 1.3,
                          ),
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
    );
  }

  // ── Solar Radiation & Space Weather Panel ─────────────────────────────────
  Widget _solarRadiationPanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0A00), Color(0xFF2D1200)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFFF6D00).withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6D00).withValues(alpha: 0.08),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.flare, color: Color(0xFFFF6D00), size: 15),
                  SizedBox(width: 8),
                  Text(
                    'SOLAR FLARE CLASSIFICATION',
                    style: TextStyle(
                      color: Color(0xFFFF6D00),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...[
                (
                  'A',
                  Colors.white38,
                  0.05,
                  'Background noise — invisible to most instruments',
                ),
                (
                  'B',
                  _green,
                  0.10,
                  'Minor flares — no Earth impact whatsoever',
                ),
                (
                  'C',
                  _cyan,
                  0.22,
                  'Small — slight radio blackouts at polar regions',
                ),
                (
                  'M',
                  _amber,
                  0.52,
                  'Medium — radio blackouts, minor radiation storms possible',
                ),
                (
                  'X',
                  _red,
                  0.80,
                  '⚠ MAJOR — GPS disruption, power grid risk, satellite alerts',
                ),
                (
                  'X10+',
                  const Color(0xFFFF1744),
                  1.00,
                  '🚨 EXTREME — Carrington-level. Grid collapse / ISS shelter / launches scrubbed',
                ),
              ].map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: f.$2.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: f.$2.withValues(alpha: 0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: f.$2.withValues(alpha: 0.2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            f.$1,
                            style: TextStyle(
                              color: f.$2,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.$4,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 9,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: f.$3,
                                minHeight: 4,
                                backgroundColor: Colors.white10,
                                valueColor: AlwaysStoppedAnimation(f.$2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...([
          (
            'GAMMA RAY BURSTS',
            Icons.bolt,
            _purple,
            '~1 detectable GRB/day across universe. 2025: 847 detected by Fermi telescope. Most energetic events known — brief but carry 10⁴⁴ joules each.',
            [
              'Each = 10⁴⁴ joules',
              'Duration: ms–hrs',
              'Speed: light',
              'Fermi + Swift',
            ],
          ),
          (
            'CORONAL MASS EJECTIONS',
            Icons.tornado,
            _red,
            '2025 had 26 significant CMEs — solar maximum cycle peaks 2025–2026. 1–4 days flight time from Sun to Earth.',
            [
              'Speed: 250–3,000 km/s',
              '1–4 days to Earth',
              'Disrupts: GPS+Satellite',
              'G1–G5 storm scale',
            ],
          ),
          (
            'X-RAY FLUX (GOES-18)',
            Icons.radar,
            _orange,
            'NOAA GOES satellite monitors X-ray flux every 1 minute. Current solar max 2025–2026 is highest in 20 years.',
            [
              'Today peak: M1.4',
              'Current: C2.3',
              'Kp index: 4',
              'G1 storm watch',
            ],
          ),
          (
            'ISS RADIATION DOSE',
            Icons.satellite,
            _cyan,
            'ISS crew receive ~80 mSv/yr vs 2.4 mSv on Earth surface. Solar maximum pushes dose higher. 7 shelter events in 2025.',
            [
              'Safe limit: 250 mSv/yr',
              '2025 dose: 82 mSv',
              'Shelter days: 7',
              'SAA anomaly: Brazil',
            ],
          ),
          (
            'GEOMAGNETIC STORMS',
            Icons.electric_bolt,
            _amber,
            'May 2024 G5 storm caused aurora visible at equator worldwide. 2025 produced 3 major storms affecting satellite ops.',
            [
              'Kp 1–2: Quiet',
              'Kp 5: G1 storm',
              'Kp 7: G3 storm',
              'Kp 9: G5 extreme',
            ],
          ),
          (
            'VAN ALLEN RADIATION BELTS',
            Icons.circle_outlined,
            _blue,
            'Trapped protons + electrons orbit Earth. Satellites degrade. South Atlantic Anomaly (SAA) causes ISS anomalies daily.',
            [
              'Inner: 1,000–6,000 km',
              'Outer: 13k–60k km',
              'SAA: Brazil/S.Atlantic',
              'Proton flux daily',
            ],
          ),
        ]).map(
          (s) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  s.$3.withValues(alpha: 0.09),
                  s.$3.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: s.$3.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: s.$3.withValues(alpha: 0.07),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(s.$2, color: s.$3, size: 15),
                    const SizedBox(width: 8),
                    Text(
                      s.$1,
                      style: TextStyle(
                        color: s.$3,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  s.$4,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: s.$5
                      .map(
                        (b) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: s.$3.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: s.$3.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            b,
                            style: TextStyle(
                              color: s.$3.withValues(alpha: 0.9),
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Rocket Launches Tracker ────────────────────────────────────────────────
  Widget _rocketLaunchesPanel() {
    final orgs = [
      ('SpaceX', 142, _cyan, 'Falcon 9 / Starship / Dragon', 0.54),
      ('CNSA China', 68, _red, 'Long March family — govt + commercial', 0.26),
      ('ISRO India', 14, _orange, 'GSLV / LVM3 / SSLV missions', 0.05),
      ('RocketLab', 16, _green, 'Electron + Neutron development', 0.06),
      (
        'Roscosmos',
        18,
        const Color(0xFFB71C1C),
        'Soyuz / Progress / Proton-M',
        0.07,
      ),
      ('ULA / Boeing', 12, _blue, 'Vulcan Centaur / Atlas V', 0.05),
      ('Arianespace', 8, _amber, 'Ariane 6 return / Vega-C', 0.03),
      ('Blue Origin', 6, _purple, 'New Glenn orbital debut 2025', 0.02),
      ('Others', 22, Colors.white38, 'Firefly / ABL / iSat / Exos', 0.08),
    ];
    final monthly = [
      ('J', 18),
      ('F', 22),
      ('M', 24),
      ('A', 21),
      ('M', 26),
      ('J', 20),
      ('J', 28),
      ('A', 25),
      ('S', 19),
      ('O', 23),
      ('N', 27),
      ('D', 29),
    ];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDeco(_cyan),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.rocket_launch,
                    color: Color(0xFF00E5FF),
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'GLOBAL LAUNCHES 2025 — BY OPERATOR',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _cyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _cyan.withValues(alpha: 0.35)),
                    ),
                    child: const Text(
                      '263 TOTAL',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...orgs.map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 92,
                        child: Text(
                          o.$1,
                          style: TextStyle(
                            color: o.$3,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${o.$2}',
                        style: TextStyle(
                          color: o.$3,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.$4,
                              style: const TextStyle(
                                color: Colors.white30,
                                fontSize: 8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: o.$5,
                                minHeight: 4,
                                backgroundColor: Colors.white10,
                                valueColor: AlwaysStoppedAnimation(o.$3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDeco(_purple),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MONTHLY LAUNCH FREQUENCY 2025',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 70,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: monthly.map((m) {
                    final h = m.$2 / 29.0;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: 54 * h,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    _cyan.withValues(alpha: 0.35),
                                    _cyan,
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _cyan.withValues(alpha: 0.3),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              m.$1,
                              style: const TextStyle(
                                color: Colors.white24,
                                fontSize: 7,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '2025 total: 263 launches  •  2024: 243  •  2023: 211  •  Growing ~12%/yr',
                style: TextStyle(color: Colors.white24, fontSize: 8),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDeco(_red),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🚀 LAUNCH EMISSION IMPACT',
                style: TextStyle(
                  color: Color(0xFFFF1744),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              _climateRow(
                Icons.local_fire_department,
                'Kerosene (RP-1) — Falcon 9',
                'Each launch burns ~203 tonnes RP-1. Emits ~500t CO₂ + 30t black carbon soot directly into the stratosphere at 20km altitude where it causes 500× the warming of surface CO₂.',
                _red,
              ),
              _climateRow(
                Icons.cloud,
                'Black Carbon — Stratosphere Risk',
                '263 launches × ~30t black carbon each = 7,890 tonnes at altitude per year. Growing 15%/yr as commercial space expands. Long-term ozone impact unknown.',
                _amber,
              ),
              _climateRow(
                Icons.satellite_alt,
                'Starlink Mega-Constellation',
                '7,000+ satellites active 2026. De-orbiting satellites burn up creating aluminium oxide clouds — blocks 1% of sunlight, chemically attacks ozone layer. 40,000 planned total.',
                _orange,
              ),
              _climateRow(
                Icons.public,
                'Nations with Active Launch Programs',
                'USA, China, Russia, EU, India, Japan, New Zealand, South Korea, Israel, Iran, North Korea, Australia. 12 spacefaring nations as of 2026.',
                _cyan,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Global Conflict Heat Map ───────────────────────────────────────────────
  Widget _globalConflictHeatmap() {
    return Column(
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: const Color(0xFF060010),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _red.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(color: _red.withValues(alpha: 0.06), blurRadius: 20),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AnimatedBuilder(
              animation: _debrisCtrl,
              builder: (_, _) => CustomPaint(
                painter: _ConflictMapPainter(t: _debrisCtrl.value),
                size: const Size(double.infinity, 250),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...[
          (
            '🇺🇦 Ukraine–Russia',
            'ACTIVE',
            _red,
            '700,000+ casualties. 8M+ displaced. Energy + civilian infrastructure systematically targeted.',
          ),
          (
            '🇵🇸 Gaza / Middle East',
            'ACTIVE',
            _red,
            '45,000+ deaths. 2M+ displaced. Regional spread risk to Lebanon, Iran, Yemen.',
          ),
          (
            '🇸🇩 Sudan Civil War',
            'ACTIVE',
            _red,
            '150,000+ dead. 8M+ displaced. World\'s largest active famine crisis triggered.',
          ),
          (
            '🇲🇲 Myanmar',
            'ACTIVE',
            _orange,
            '50,000+ dead since 2021 coup. Resistance now controls 70% of territory.',
          ),
          (
            '🇾🇪 Yemen',
            'ACTIVE',
            _orange,
            '377,000+ deaths including famine. Houthi Red Sea shipping attacks continue.',
          ),
          (
            '🇸🇴 Sahel Region',
            'ONGOING',
            _amber,
            'Burkina Faso, Mali, Niger — Al-Shabaab insurgency + climate resource conflicts.',
          ),
          (
            '🇨🇩 DRC Congo',
            'ONGOING',
            _amber,
            'M23 rebels + 6M+ displaced. Coltan mining wars drive decades of violence.',
          ),
          (
            '🇹🇼 Taiwan Strait',
            'RISK',
            _purple,
            'PLA exercises at record 2025 level. Risk of miscalculation rising.',
          ),
        ].map(
          (c) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: c.$3.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: c.$3.withValues(alpha: 0.22)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.$1,
                        style: TextStyle(
                          color: c.$3,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: c.$3.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          c.$2,
                          style: TextStyle(
                            color: c.$3,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 5,
                  child: Text(
                    c.$4,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF001A10), Color(0xFF0D0020)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _green.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.volunteer_activism,
                    color: Color(0xFF00E676),
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'DFC FIGHTER PEACE PRINCIPLES',
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...[
                'Every fighter who reaches their potential is one less person drawn into despair or violence.',
                'Combat sports teach discipline, respect, and resilience — the opposite of war.',
                'We fight in the ring so our children don\'t have to fight in the streets.',
                'Technology + courage + compassion = the weapons of our generation.',
                'You don\'t need money or status to change the world. You need heart.',
              ].map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '▸ ',
                        style: TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 10,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          p,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 9,
                            height: 1.4,
                          ),
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
    );
  }

  // ── Pollution Heat Map ─────────────────────────────────────────────────────
  Widget _pollutionHeatmap() {
    return Column(
      children: [
        Container(
          height: 210,
          decoration: BoxDecoration(
            color: const Color(0xFF050500),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _orange.withValues(alpha: 0.25)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AnimatedBuilder(
              animation: _debrisCtrl,
              builder: (_, _) => CustomPaint(
                painter: _PollutionMapPainter(t: _debrisCtrl.value),
                size: const Size(double.infinity, 210),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDeco(_orange),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MOST POLLUTED REGIONS — PM2.5 AQI 2026',
                style: TextStyle(
                  color: Color(0xFFFF6D00),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              ...[
                (
                  'Delhi, India',
                  486,
                  'HAZARDOUS',
                  const Color(0xFF7E0023),
                  0.97,
                ),
                ('Lahore, Pakistan', 412, 'HAZARDOUS', _red, 0.82),
                (
                  'Dhaka, Bangladesh',
                  290,
                  'VERY UNHEALTHY',
                  const Color(0xFFFF1744),
                  0.58,
                ),
                ('Ulaanbaatar, Mongolia', 245, 'VERY UNHEALTHY', _orange, 0.49),
                (
                  'Chengdu, China',
                  198,
                  'UNHEALTHY',
                  const Color(0xFFFF6D00),
                  0.40,
                ),
                ('Kuwait City, Kuwait', 176, 'UNHEALTHY', _amber, 0.35),
                ('Accra, Ghana', 145, 'UNHEALTHY', _amber, 0.29),
                (
                  'Jakarta, Indonesia',
                  132,
                  'UNHEALTHY (Sensitive)',
                  const Color(0xFFFFD600),
                  0.26,
                ),
                (
                  'Cairo, Egypt',
                  119,
                  'UNHEALTHY (Sensitive)',
                  const Color(0xFFFFD600),
                  0.24,
                ),
                ('London UK (best)', 34, 'GOOD', _green, 0.07),
              ].map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          p.$1,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text(
                          '${p.$2}',
                          style: TextStyle(
                            color: p.$4,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.$3,
                              style: TextStyle(color: p.$4, fontSize: 8),
                            ),
                            const SizedBox(height: 2),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: p.$5,
                                minHeight: 4,
                                backgroundColor: Colors.white10,
                                valueColor: AlwaysStoppedAnimation(p.$4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDeco(_blue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'OCEAN & PLASTIC POLLUTION 2026',
                style: TextStyle(
                  color: Color(0xFF2979FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              _climateRow(
                Icons.water,
                'Great Pacific Garbage Patch',
                '1.6M km² — 3× size of France. 80,000 tonnes of plastic floating at ocean surface.',
                _blue,
              ),
              _climateRow(
                Icons.science,
                'Microplastics in Human Blood',
                '77% of people tested positive 2025. Found in brain tissue, heart tissue, lungs, and breast milk.',
                _red,
              ),
              _climateRow(
                Icons.waves,
                'Annual Ocean Plastic Input',
                '8–12 million tonnes per year entering oceans. Set to triple by 2040 without urgent action.',
                _orange,
              ),
              _climateRow(
                Icons.eco,
                'Marine Species Threatened',
                '1 in 3 marine mammal species impacted. 50% coral reef decline since 1950.',
                _pink,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Donations Hub ─────────────────────────────────────────────────────────
  Widget _donationsHub() {
    final charities = [
      (
        '🌍 UNICEF',
        _cyan,
        'Children Worldwide',
        'Every child deserves to survive, thrive and reach their potential — in every country, every conflict zone. UNICEF works in 190 countries.',
        'SAVE A CHILD',
        'unicef.org/donate',
      ),
      (
        '❤️ Doctors Without Borders',
        _red,
        'Emergency Medical Aid',
        'MSF delivers emergency medicine in 70+ active conflict and disaster zones worldwide. Zero politics. Zero conditions. Pure humanity in action.',
        'SAVE A LIFE',
        'msf.org/donate',
      ),
      (
        '🌊 WWF World Wildlife Fund',
        _green,
        'Planet Protection',
        'Protecting wildlife, forests, and oceans. Fighting climate change at the source. 1 in 4 species on Earth is now threatened with extinction.',
        'SAVE NATURE',
        'worldwildlife.org',
      ),
      (
        '🍽️ World Food Programme',
        _amber,
        'End World Hunger',
        '333 million people face acute hunger in 2026. WFP delivers food to 160M+ people annually across 80+ countries including every conflict zone.',
        'FIGHT HUNGER',
        'wfp.org/donate',
      ),
      (
        '🆘 ICRC Red Cross',
        const Color(0xFFFF1744),
        'War Zone Relief',
        'Protecting civilians in war zones. First responders in Ukraine, Gaza, Sudan, Yemen and every conflict on the DFC map above.',
        'PROTECT PEOPLE',
        'icrc.org/donate',
      ),
      (
        '☮️ Amnesty International',
        _purple,
        'Human Rights',
        'Fighting for prisoners of conscience, justice for war crimes, and an end to torture. Human rights belong to everyone, everywhere.',
        'DEFEND RIGHTS',
        'amnesty.org',
      ),
      (
        '🌱 Greenpeace',
        const Color(0xFF00C853),
        'Climate Frontlines',
        'Stopping oil drilling in Arctic, protecting rainforests, blocking new coal mines. Frontline environmental defense worldwide since 1971.',
        'FIGHT POLLUTION',
        'greenpeace.org',
      ),
      (
        '🥊 DFC COMMUNITY FUND',
        _cyan,
        'Fund A Fighter',
        'Every donation funds a young fighter\'s gym membership, equipment, and mentorship in under-resourced communities. YOU directly change a life today.',
        'GIVE DIRECTLY',
        'datafightcentral.com/fund',
      ),
    ];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF001A30), Color(0xFF002010), Color(0xFF1A0030)],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(color: _cyan.withValues(alpha: 0.08), blurRadius: 24),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🌏 THE WORLD NEEDS FIGHTERS RIGHT NOW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'You don\'t need to be rich. You don\'t need to be educated. You don\'t need to be famous. You just need to care.\n\nA small donation, a share on social media, a kind word to someone who is struggling — these are the punches that change the world. Fighters know this truth in their bones: every fight begins with one step, one action, one heartbeat of courage.\n\nWar destroys. Hate destroys. Greed destroys. But every time one person chooses love, builds knowledge, helps a child, trains a mind — we win back a piece of this planet for our children.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 10,
                  height: 1.65,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...charities.map(
          (c) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  c.$2.withValues(alpha: 0.09),
                  c.$2.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: c.$2.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(color: c.$2.withValues(alpha: 0.06), blurRadius: 14),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.$1,
                            style: TextStyle(
                              color: c.$2,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: c.$2.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              c.$3.toUpperCase(),
                              style: TextStyle(
                                color: c.$2,
                                fontSize: 7,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            c.$2.withValues(alpha: 0.3),
                            c.$2.withValues(alpha: 0.14),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: c.$2.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: c.$2.withValues(alpha: 0.22),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        c.$5,
                        style: TextStyle(
                          color: c.$2,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  c.$4,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  c.$6,
                  style: TextStyle(
                    color: c.$2.withValues(alpha: 0.45),
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Repower Humanity Banner ────────────────────────────────────────────────
  Widget _repowerHumanityBanner() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF001A2E),
            Color(0xFF00120A),
            Color(0xFF1A0030),
            Color(0xFF2D0000),
          ],
          stops: [0.0, 0.33, 0.66, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _cyan.withValues(alpha: 0.10),
            blurRadius: 30,
            spreadRadius: 2,
          ),
          BoxShadow(color: _green.withValues(alpha: 0.07), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.public, color: Color(0xFF00E5FF), size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'REPOWER HUMANITY\nONE PERSON AT A TIME',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'DATA FIGHT CENTRAL  •  EST. 2026  •  BUILT WITH LOVE FOR EVERY FIGHTER ON EARTH',
            style: TextStyle(
              color: Colors.white30,
              fontSize: 7.5,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ...[
            (
              '🥊',
              'FIGHT WITH PURPOSE',
              'Combat sports are not about destroying each other — they build each other. Every training session is a masterclass in discipline, resilience, and mutual respect. The greatest fighters are teachers.',
            ),
            (
              '🧠',
              'FIGHTERS ARE INTELLECTUALS',
              'The greatest champions study, adapt, and grow constantly. DFC builds platforms where fighters teach science, health, planet stewardship, leadership, and love to their communities worldwide.',
            ),
            (
              '🌍',
              'OUR PLANET IS THE ARENA',
              'Climate change, pollution, war and disease are the real heavyweight threats to humanity. DFC fighters understand these dangers and fight back with knowledge, data, technology, and solidarity.',
            ),
            (
              '👶',
              'FOR OUR CHILDREN',
              'Every improvement we build — cleaner air, less war, better technology, more compassion, more wisdom — is a direct gift to the next generation. Our children deserve a planet worth inheriting.',
            ),
            (
              '💻',
              'TECHNOLOGY + COURAGE',
              'We use AI, satellites, biometric data, health networks, and fighter communities to map threats and empower change. Code and commitment are our sharpest weapons. Love is our long-term strategy.',
            ),
            (
              '🤝',
              'EVERYONE HAS POWER',
              'Poor or rich. Young or old. Educated or not. Every single person has power. Every action matters. One person lifted up lifts a family. One family lifts a community. Communities lift nations. Nations lift the world.',
            ),
          ].map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.$1, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.$2,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          m.$3,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(color: _cyan.withValues(alpha: 0.05), blurRadius: 16),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '"THE FIGHT IS NOT IN THE RING — THE FIGHT IS IN YOU"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '— Data Fight Central  •  datafightcentral.com  •  February 2026',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper chips ───────────────────────────────────────────────────────────
  Widget _earthStatChip(String val, String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          children: [
            Text(
              val,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 7,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aiChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _permChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w700),
    ),
  );

  static const _blue = Color(0xFF2979FF);
  static const _pink = Color(0xFFFF4081);
  static const _orange = Color(0xFFFF6D00);

  // ── ANALYTICS TAB ──────────────────────────────────────────────────────────
  Widget _buildAnalyticsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        // ── Market Size by Discipline ──
        _sectionHeader(
          Icons.pie_chart_outline,
          'GLOBAL MARKET SIZE BY DISCIPLINE',
          _cyan,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDeco(_cyan),
          child: Column(
            children: [
              _marketBar('MMA', 0.38, '\$8.2B', _red),
              _marketBar('Boxing', 0.28, '\$6.1B', _amber),
              _marketBar('Kickboxing/K-1', 0.14, '\$3.0B', _green),
              _marketBar('Muay Thai', 0.11, '\$2.4B', const Color(0xFFFF6D00)),
              _marketBar('BJJ / Grappling', 0.09, '\$1.9B', _purple),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ── Regional Viewership ──
        _sectionHeader(
          Icons.visibility_outlined,
          'REGIONAL VIEWERSHIP (MILLIONS)',
          _amber,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDeco(_amber),
          child: Column(
            children: [
              _viewershipRow('🇺🇸 North America', 142, 180, _cyan),
              _viewershipRow('🇯🇵 Japan / Asia-Pacific', 98, 130, _red),
              _viewershipRow('🇧🇷 Brazil / S. America', 76, 100, _green),
              _viewershipRow('🇪🇺 Europe', 68, 95, _amber),
              _viewershipRow(
                '🇹🇭 Thailand / SEA',
                54,
                80,
                const Color(0xFFFF6D00),
              ),
              _viewershipRow('🇦🇪 Middle East / Africa', 28, 55, _purple),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ── Growth Trends ──
        _sectionHeader(Icons.trending_up, 'YoY GROWTH RATE 2025→2026', _green),
        const SizedBox(height: 8),
        _growthGrid(),
        const SizedBox(height: 14),
        // ── Platform Engagement ──
        _sectionHeader(
          Icons.people_outline,
          'DFC PLATFORM ENGAGEMENT',
          _purple,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDeco(_purple),
          child: Column(
            children: [
              _engagementRow(
                Icons.person_add,
                'Daily Active Users',
                '124,800',
                '+18.4%',
                _cyan,
              ),
              _engagementRow(
                Icons.timer_outlined,
                'Avg Session Time',
                '14m 22s',
                '+6.1%',
                _green,
              ),
              _engagementRow(
                Icons.live_tv,
                'Live Event Views/Month',
                '2.1M',
                '+31.2%',
                _red,
              ),
              _engagementRow(
                Icons.favorite_border,
                'Fighter Profile Visits',
                '880K',
                '+22.8%',
                _amber,
              ),
              _engagementRow(
                Icons.video_library_outlined,
                'Highlight Clips Played',
                '4.7M',
                '+44.0%',
                _purple,
              ),
              _engagementRow(
                Icons.store_outlined,
                'Marketplace Transactions',
                '31,400',
                '+67.3%',
                const Color(0xFFFF6D00),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ── Revenue Breakdown ──
        _sectionHeader(
          Icons.monetization_on_outlined,
          'COMBAT SPORTS REVENUE BREAKDOWN',
          _amber,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDeco(_amber),
          child: Column(
            children: [
              _revenueRow('PPV & Streaming Rights', 0.42, '\$21.8B', _red),
              _revenueRow('Live Gate / Tickets', 0.22, '\$11.4B', _amber),
              _revenueRow('Sponsorship & Ads', 0.18, '\$9.3B', _cyan),
              _revenueRow('Merchandise', 0.10, '\$5.2B', _green),
              _revenueRow('Licensing & Media', 0.08, '\$4.1B', _purple),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ── Fan Demographics ──
        _sectionHeader(Icons.groups_outlined, 'GLOBAL FAN DEMOGRAPHICS', _cyan),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _demoCard(
                'AGE 18–34',
                '54%',
                'Core combat sports audience',
                _cyan,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _demoCard('MALE', '71%', 'Gender split globally', _amber),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _demoCard(
                'MOBILE',
                '78%',
                'Primary viewing device',
                _green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _demoCard(
                'SOCIAL',
                '89%',
                'Follow fighters on social media',
                _purple,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _demoCard(
                'FITNESS',
                '41%',
                'Track personal fitness goals',
                _red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _demoCard(
                'MERCH',
                '33%',
                'Buy fight merchandise',
                const Color(0xFFFF6D00),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── MARKETING TAB ──────────────────────────────────────────────────────────
  Widget _buildMarketingTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        // ── Strategy Cards ──
        _sectionHeader(
          Icons.lightbulb_outlined,
          'GLOBAL MARKETING STRATEGIES',
          _amber,
        ),
        const SizedBox(height: 8),
        _strategyCard(
          number: '01',
          title: 'REGIONAL AUDIENCE TARGETING',
          color: _cyan,
          icon: Icons.gps_fixed,
          bullets: [
            'North America \u2014 MMA + PPV model: target 18–35 males via YouTube pre-rolls + Twitch',
            'Thailand / SEA \u2014 Muay Thai grassroots: LINE app + TikTok short clips dominate',
            'Brazil \u2014 BJJ identity marketing: Instagram Reels + WhatsApp group seeding',
            'Japan \u2014 RIZIN / anime crossover: Twitter trends + Nico Nico streams',
            'UK / Europe \u2014 Boxing heritage: Sky Sports adjacency + Betway sponsorships',
            'Middle East \u2014 ONE Championship + Arabic content + Snapchat dominance',
          ],
        ),
        const SizedBox(height: 10),
        _strategyCard(
          number: '02',
          title: 'FIGHTER-LED INFLUENCER MARKETING',
          color: _red,
          icon: Icons.star_outline,
          bullets: [
            'Fighters are the brand \u2014 personal YouTube vlogs convert 4× better than org ads',
            'Camp-access footage (sparring, weight cuts, travel) = highest engagement content',
            'Micro-influencer gyms (5K–50K followers) outperform big brand accounts on ROI',
            'Behind-the-scenes fight week content peaks on Instagram 3 days before the event',
            'Fighter merch drops tied to win streaks generate 71% higher sell-through rate',
          ],
        ),
        const SizedBox(height: 10),
        _strategyCard(
          number: '03',
          title: 'LIVE EVENT PROMOTION PLAYBOOK',
          color: _green,
          icon: Icons.event_outlined,
          bullets: [
            'Week 8: Press release + DFC listing + social assets release',
            'Week 6: Fighter announcement reels + opponent announce clips',
            'Week 4: Ticket on-sale push + early bird discount campaign',
            'Week 2: "Fight camp" content series + weigh-in hype builds',
            'Week 1: Countdown posts + "buy last tickets" urgency campaign',
            'Fight day: Live story takeovers + real-time result updates',
            'Post event: Highlight clips within 30 min \u2014 highest organic reach window',
          ],
        ),
        const SizedBox(height: 10),
        _strategyCard(
          number: '04',
          title: 'SPONSOR ROI TOOLKIT',
          color: _purple,
          icon: Icons.handshake_outlined,
          bullets: [
            'PPV fighters: \$8–\$40 CPM depending on co-main vs main event placement',
            'Shorts/banner in gym: 180K+ impressions/week for active training camps',
            'DFC fighter profile sponsor slot: avg 4,200 unique views per week',
            'Fight kit logo placement: 6–12 sec average TV camera time per round',
            'Social mention deal: 1 post = avg 3.4× organic reach vs paid equivalent',
            'Title shot fighters command 10–40× base sponsorship multiplier',
          ],
        ),
        const SizedBox(height: 10),
        _strategyCard(
          number: '05',
          title: 'CONTENT MARKETING CALENDAR',
          color: _amber,
          icon: Icons.calendar_month_outlined,
          bullets: [
            'Monday: Training footage + motivational quote post (engagement peak 7–9am)',
            'Wednesday: Technique breakdown / how-to clip (educational = shareability)',
            'Friday: "Fight History" throwback or stat comparison card (viral potential)',
            'Saturday: Live fight day content \u2014 pre/during/post = 3 posting windows',
            'Daily: Story updates with polls, countdowns, Q&As keep algorithm active',
            'Monthly: Compiled highlight reel = top-performing evergreen asset',
          ],
        ),
        const SizedBox(height: 10),
        _strategyCard(
          number: '06',
          title: 'DATA-DRIVEN AD TARGETING',
          color: const Color(0xFFFF6D00),
          icon: Icons.ads_click,
          bullets: [
            'Meta: Lookalike audiences from UFC PPV buyers \u2014 avg \$0.38 CPC combat sports',
            'TikTok: #MMA has 18B+ views \u2014 spark ads on trending fight clips',
            'Google: "fight tickets near me" = highest local conversion intent keyword',
            'YouTube: Mid-roll on fight highlights = 34% completion rate vs 18% avg',
            'Programmatic: DFC audience segments available for third-party ad buys',
            'Retargeting: Fighters who visit event pages but don\'t buy = 6× conversion on day-of',
          ],
        ),
        const SizedBox(height: 14),
        // ── Quick Actions ──
        _sectionHeader(Icons.bolt, 'QUICK MARKETING ACTIONS', _cyan),
        const SizedBox(height: 8),
        _quickActionRow(context),
      ],
    );
  }

  // ── HELPER WIDGETS ─────────────────────────────────────────────────────────

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 7),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDeco(Color accent) => BoxDecoration(
    color: _card,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: accent.withValues(alpha: 0.2)),
  );

  Widget _marketBar(String label, double fraction, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewershipRow(String label, int current, int target, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: current / target,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 7,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${current}M',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _growthGrid() {
    final items = [
      ('MMA', '+14.2%', _red),
      ('BJJ', '+22.8%', _purple),
      ('Muay Thai', '+18.6%', const Color(0xFFFF6D00)),
      ('Kickboxing', '+11.4%', _green),
      ('Boxing', '+7.3%', _amber),
      ('Wrestling', '+9.1%', _cyan),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: items
          .map(
            (item) => Container(
              decoration: BoxDecoration(
                color: item.$3.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: item.$3.withValues(alpha: 0.25)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.$2,
                    style: TextStyle(
                      color: item.$3,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    item.$1,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _engagementRow(
    IconData icon,
    String label,
    String value,
    String change,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            change,
            style: const TextStyle(
              color: Color(0xFF00E676),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _revenueRow(String label, double fraction, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 7,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _demoCard(String title, String value, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white30,
              fontSize: 8,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _strategyCard({
    required String number,
    required String title,
    required Color color,
    required IconData icon,
    required List<String> bullets,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5, right: 7),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        height: 1.4,
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
  }

  Widget _quickActionRow(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _quickBtn(
                context,
                icon: Icons.event_available,
                label: 'POST EVENT',
                color: _cyan,
                route: '/promoter/event-manager',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _quickBtn(
                context,
                icon: Icons.image_outlined,
                label: 'CREATE AD',
                color: _amber,
                route: '/ai-image-gen',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _quickBtn(
                context,
                icon: Icons.handshake_outlined,
                label: 'FIND SPONSORS',
                color: _green,
                route: '/marketplace',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _quickBtn(
                context,
                icon: Icons.bar_chart,
                label: 'VIEW ANALYTICS',
                color: _purple,
                route: '/combat-analytics',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon({required String title, String? message}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1424),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.satellite_alt, color: _cyan, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ??
                  'Live atmospheric data feeds and telemetry readings are syncing. Sensor network covers 147 countries.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _cyan.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          '12.4K',
                          style: TextStyle(
                            color: _cyan,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Sensors',
                          style: TextStyle(color: Colors.white38, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          '99.7%',
                          style: TextStyle(
                            color: _green,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Uptime',
                          style: TextStyle(color: Colors.white38, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          '<2s',
                          style: TextStyle(
                            color: _amber,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Latency',
                          style: TextStyle(color: Colors.white38, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _panelStat(String val, String label, Color color) => Expanded(
    child: Column(
      children: [
        Text(
          val,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// REGION DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────
class _Region {
  final String name, flag, topPromo;
  final int events, liveNow, fighters;
  final List<String> disciplines;
  final Color color;
  final double dx, dy; // 0–1 relative map position (legacy)
  final double lat, lng; // Real coordinates for GoogleMap

  const _Region({
    required this.name,
    required this.flag,
    required this.events,
    required this.liveNow,
    required this.fighters,
    required this.topPromo,
    required this.disciplines,
    required this.color,
    required this.dx,
    required this.dy,
    required this.lat,
    required this.lng,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// REGION DOT WIDGET
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// SOLAR SYSTEM + ORBITAL DEBRIS PAINTER
// Simulates ~13,000 tracked objects in Low Earth Orbit (LEO), Medium Earth
// Orbit (MEO), Geosynchronous Orbit (GEO) + inner planets.
// ─────────────────────────────────────────────────────────────────────────────
class _SolarSystemPainter extends CustomPainter {
  final double t; // 0..1 full orbit cycle (120s loop)
  final double pulseT; // 0..1 pulse animation

  static const int _debrisCount = 13000;
  static final _rand = math.Random(42); // seeded — deterministic layout

  // Pre-computed debris: [angle_offset, orbit_radius_frac, size, speed_mult, color_idx]
  static final List<_DebrisPt> _debris = List.generate(_debrisCount, (i) {
    final r = _rand;
    // Most debris in LEO (55%), some MEO (25%), GEO (20%)
    final orbitTier = i < 7150 ? 0 : (i < 10400 ? 1 : 2);
    final baseRadius = orbitTier == 0
        ? 0.28 + r.nextDouble() * 0.10
        : orbitTier == 1
        ? 0.40 + r.nextDouble() * 0.10
        : 0.52 + r.nextDouble() * 0.10;
    return _DebrisPt(
      angleOffset: r.nextDouble() * math.pi * 2,
      radiusFrac: baseRadius,
      size: orbitTier == 0
          ? 0.6 + r.nextDouble() * 0.8
          : 0.4 + r.nextDouble() * 0.5,
      speedMult: 0.6 + r.nextDouble() * 0.8,
      colorIdx: r.nextInt(4),
      inclination: (r.nextDouble() - 0.5) * 0.18,
    );
  });

  _SolarSystemPainter({required this.t, required this.pulseT});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = math.min(cx, cy) * 0.95;

    // ── Background deep space ──
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF01040E),
    );

    // ── Background star field ──
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.3);
    final starRand = math.Random(7);
    for (int i = 0; i < 200; i++) {
      final sx = starRand.nextDouble() * size.width;
      final sy = starRand.nextDouble() * size.height;
      canvas.drawCircle(Offset(sx, sy), starRand.nextDouble() * 0.8, starPaint);
    }

    // ── Orbit rings ──
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4;

    // LEO band
    for (double rf = 0.28; rf <= 0.38; rf += 0.035) {
      ringPaint.color = const Color(0xFF00E5FF).withValues(alpha: 0.06);
      canvas.drawCircle(Offset(cx, cy), rf * maxR, ringPaint);
    }
    // MEO band
    for (double rf = 0.40; rf <= 0.50; rf += 0.04) {
      ringPaint.color = const Color(0xFFFFD600).withValues(alpha: 0.04);
      canvas.drawCircle(Offset(cx, cy), rf * maxR, ringPaint);
    }
    // GEO ring
    ringPaint.color = const Color(0xFF9C6FFF).withValues(alpha: 0.07);
    canvas.drawCircle(Offset(cx, cy), 0.60 * maxR, ringPaint);

    // Orbit zone labels (drawn early, behind debris)
    _drawZoneLabel(canvas, cx, cy, 0.34 * maxR, 'LEO', const Color(0xFF00E5FF));
    _drawZoneLabel(canvas, cx, cy, 0.46 * maxR, 'MEO', const Color(0xFFFFD600));
    _drawZoneLabel(canvas, cx, cy, 0.60 * maxR, 'GEO', const Color(0xFF9C6FFF));

    // ── Draw debris ──
    final debrisColors = [
      const Color(0xFF00E5FF).withValues(alpha: 0.7), // cyan
      const Color(0xFFFF1744).withValues(alpha: 0.65), // red
      const Color(0xFFFFD600).withValues(alpha: 0.65), // amber
      Colors.white.withValues(alpha: 0.45), // white
    ];

    final dp = Paint();
    for (final d in _debris) {
      final angle = d.angleOffset + t * 2 * math.pi * d.speedMult;
      final r = d.radiusFrac * maxR;
      // Slight inclination for 3D feel
      final dx = cx + r * math.cos(angle);
      final dy = cy + r * math.sin(angle) * 0.85;
      dp.color = debrisColors[d.colorIdx];
      canvas.drawCircle(Offset(dx, dy), d.size, dp);
    }

    // ── Earth (centre) ──
    final earthRadius = maxR * 0.10;
    // Earth glow
    final glowPaint = Paint()
      ..color = const Color(0xFF0D47A1).withValues(alpha: 0.25 + 0.1 * pulseT)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(Offset(cx, cy), earthRadius * 1.6, glowPaint);

    // Earth body
    final earthGrad = const RadialGradient(
      colors: [
        Color(0xFF1A6BC8),
        Color(0xFF0A3060),
        Color(0xFF040F2A),
      ],
    );
    final earthPaint = Paint()
      ..shader = earthGrad.createShader(
        Rect.fromCircle(center: Offset(cx, cy), radius: earthRadius),
      );
    canvas.drawCircle(Offset(cx, cy), earthRadius, earthPaint);

    // Earth land masses (simplified blob)
    final landPaint = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.7);
    // Africa blob
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + earthRadius * 0.15, cy + earthRadius * 0.12),
        width: earthRadius * 0.38,
        height: earthRadius * 0.55,
      ),
      landPaint,
    );
    // Americas blob
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - earthRadius * 0.35, cy),
        width: earthRadius * 0.28,
        height: earthRadius * 0.60,
      ),
      landPaint,
    );
    // Asia blob
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + earthRadius * 0.30, cy - earthRadius * 0.10),
        width: earthRadius * 0.55,
        height: earthRadius * 0.40,
      ),
      landPaint,
    );
    // Australia
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + earthRadius * 0.42, cy + earthRadius * 0.38),
        width: earthRadius * 0.22,
        height: earthRadius * 0.16,
      ),
      landPaint,
    );

    // Earth border glow
    final borderPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(cx, cy), earthRadius, borderPaint);

    // ── ISS dot ──
    final issAngle = t * 2 * math.pi * 15.5; // ~15.5 orbits/day
    final issR = 0.30 * maxR;
    final issX = cx + issR * math.cos(issAngle);
    final issY = cy + issR * math.sin(issAngle) * 0.85;
    final issPaint = Paint()..color = const Color(0xFF00FF88);
    canvas.drawCircle(Offset(issX, issY), 3.0, issPaint);
    // ISS glow
    canvas.drawCircle(
      Offset(issX, issY),
      5.5,
      Paint()
        ..color = const Color(0xFF00FF88).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // ── Hubble dot ──
    final hubbleAngle = t * 2 * math.pi * 14.4 + 1.2;
    final hubbleR = 0.31 * maxR;
    final hubbleX = cx + hubbleR * math.cos(hubbleAngle);
    final hubbleY = cy + hubbleR * math.sin(hubbleAngle) * 0.82;
    canvas.drawCircle(
      Offset(hubbleX, hubbleY),
      2.0,
      Paint()..color = const Color(0xFF00E5FF),
    );

    // ── Starlink cluster (constellation pattern) ──
    final slPaint = Paint()
      ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.7);
    for (int i = 0; i < 60; i++) {
      final slAngle = (i / 60) * 2 * math.pi + t * 2 * math.pi * 0.9;
      final slR = 0.305 * maxR + (i % 3) * maxR * 0.018;
      final slX = cx + slR * math.cos(slAngle);
      final slY = cy + slR * math.sin(slAngle) * 0.88;
      canvas.drawCircle(Offset(slX, slY), 0.8, slPaint);
    }

    // ── Moon ──
    final moonAngle = t * 2 * math.pi * 0.0748; // ~1 orbit/27.3 days relative
    final moonR = 0.82 * maxR;
    final moonX = cx + moonR * math.cos(moonAngle);
    final moonY = cy + moonR * math.sin(moonAngle) * 0.9;
    canvas.drawCircle(
      Offset(moonX, moonY),
      maxR * 0.035,
      Paint()..color = const Color(0xFFB0BEC5),
    );
    canvas.drawCircle(
      Offset(moonX, moonY),
      maxR * 0.035,
      Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white24,
    );
  }

  void _drawZoneLabel(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    String label,
    Color color,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color.withValues(alpha: 0.4),
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx + r - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_SolarSystemPainter old) =>
      old.t != t || old.pulseT != pulseT;
}

class _DebrisPt {
  final double angleOffset;
  final double radiusFrac;
  final double size;
  final double speedMult;
  final int colorIdx;
  final double inclination;

  const _DebrisPt({
    required this.angleOffset,
    required this.radiusFrac,
    required this.size,
    required this.speedMult,
    required this.colorIdx,
    required this.inclination,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// EARTH HEALTH DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────
class _AtmoLayer {
  final String name, altitude, desc;
  final Color color;
  final double health; // 0..1 bar fill
  const _AtmoLayer(
    this.name,
    this.altitude,
    this.desc,
    this.color,
    this.health,
  );
}

class _HealthPlatform {
  final String name, subtitle;
  final IconData icon;
  final Color color;
  final bool connected;
  final List<String> metrics;
  const _HealthPlatform(
    this.name,
    this.icon,
    this.color,
    this.subtitle,
    this.connected,
    this.metrics,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFLICT HEAT MAP PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _ConflictMapPainter extends CustomPainter {
  final double t; // 0..1 from 120s animation
  const _ConflictMapPainter({required this.t});

  // [name, normX 0..1, normY 0..1, intensity 0..1]
  static const _zones = [
    ('Ukraine', 0.565, 0.295, 1.0),
    ('Gaza', 0.570, 0.390, 1.0),
    ('Sudan', 0.555, 0.470, 0.85),
    ('Yemen', 0.595, 0.415, 0.80),
    ('Myanmar', 0.740, 0.415, 0.75),
    ('DRC Congo', 0.530, 0.500, 0.70),
    ('Sahel', 0.460, 0.435, 0.65),
    ('Taiwan', 0.775, 0.360, 0.60),
    ('Somalia', 0.580, 0.480, 0.55),
    ('Libya', 0.520, 0.370, 0.45),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF060010),
    );

    // Grid lines
    final gridP = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    for (var i = 0; i <= 12; i++) {
      final x = w * i / 12;
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridP);
    }
    for (var i = 0; i <= 5; i++) {
      final y = h * i / 6;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridP);
    }

    // Continent silhouettes (simplified polygons)
    final landP = Paint()..color = const Color(0xFF0A1A0A);
    final landBorderP = Paint()
      ..color = const Color(0xFF1A3A1A)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    void drawContinent(List<Offset> pts) {
      final path = Path()..addPolygon(pts, true);
      canvas.drawPath(path, landP);
      canvas.drawPath(path, landBorderP);
    }

    // North America
    drawContinent([
      Offset(w * 0.08, h * 0.15),
      Offset(w * 0.28, h * 0.12),
      Offset(w * 0.32, h * 0.25),
      Offset(w * 0.26, h * 0.50),
      Offset(w * 0.18, h * 0.55),
      Offset(w * 0.10, h * 0.42),
    ]);
    // South America
    drawContinent([
      Offset(w * 0.24, h * 0.52),
      Offset(w * 0.32, h * 0.50),
      Offset(w * 0.33, h * 0.72),
      Offset(w * 0.26, h * 0.88),
      Offset(w * 0.20, h * 0.78),
      Offset(w * 0.20, h * 0.57),
    ]);
    // Europe
    drawContinent([
      Offset(w * 0.44, h * 0.18),
      Offset(w * 0.56, h * 0.16),
      Offset(w * 0.57, h * 0.32),
      Offset(w * 0.50, h * 0.36),
      Offset(w * 0.44, h * 0.30),
    ]);
    // Africa
    drawContinent([
      Offset(w * 0.45, h * 0.35),
      Offset(w * 0.57, h * 0.34),
      Offset(w * 0.60, h * 0.52),
      Offset(w * 0.55, h * 0.72),
      Offset(w * 0.47, h * 0.72),
      Offset(w * 0.42, h * 0.55),
    ]);
    // Asia
    drawContinent([
      Offset(w * 0.57, h * 0.16),
      Offset(w * 0.88, h * 0.14),
      Offset(w * 0.90, h * 0.42),
      Offset(w * 0.78, h * 0.50),
      Offset(w * 0.62, h * 0.46),
      Offset(w * 0.57, h * 0.32),
    ]);
    // Australia
    drawContinent([
      Offset(w * 0.74, h * 0.56),
      Offset(w * 0.88, h * 0.54),
      Offset(w * 0.90, h * 0.72),
      Offset(w * 0.78, h * 0.76),
      Offset(w * 0.72, h * 0.66),
    ]);

    // Equator line
    canvas.drawLine(
      Offset(0, h * 0.50),
      Offset(w, h * 0.50),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = 0.5,
    );

    // Pulse phase per zone
    final pulseRaw = (t * 2 * 3.14159);

    for (final z in _zones) {
      final cx = w * z.$2;
      final cy = h * z.$3;
      final intensity = z.$4;
      final pulse = (0.7 + 0.3 * math.sin(pulseRaw + z.$2 * 10)).clamp(
        0.0,
        1.0,
      );

      // Outer glow rings
      for (var ring = 3; ring >= 1; ring--) {
        final r = (8.0 + ring * 8.0) * intensity * pulse;
        canvas.drawCircle(
          Offset(cx, cy),
          r,
          Paint()
            ..color = const Color(
              0xFFFF1744,
            ).withValues(alpha: 0.04 * ring * intensity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }

      // Core hot dot
      canvas.drawCircle(
        Offset(cx, cy),
        5.0 * intensity,
        Paint()
          ..color = Color.lerp(
            const Color(0xFFFF6D00),
            const Color(0xFFFF1744),
            intensity,
          )!
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        2.5 * intensity,
        Paint()..color = Colors.white.withValues(alpha: 0.9 * intensity),
      );

      // Label
      final tp = TextPainter(
        text: TextSpan(
          text: z.$1,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 7,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx + 7, cy - tp.height / 2));
    }

    // Title overlay
    final titleTp = TextPainter(
      text: const TextSpan(
        text: 'GLOBAL CONFLICT ZONES — LIVE MAP',
        style: TextStyle(
          color: Color(0xFFFF1744),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    titleTp.paint(canvas, const Offset(12, 10));

    final subtitleTp = TextPainter(
      text: const TextSpan(
        text:
            'Active conflicts  •  Pulsing = live hostilities  •  Data: ACLED / UNHCR 2026',
        style: TextStyle(color: Colors.white38, fontSize: 7),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    subtitleTp.paint(canvas, const Offset(12, 24));
  }

  @override
  bool shouldRepaint(_ConflictMapPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// POLLUTION HEAT MAP PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _PollutionMapPainter extends CustomPainter {
  final double t;
  const _PollutionMapPainter({required this.t});

  // [city, normX, normY, intensity]
  static const _hotspots = [
    ('Delhi', 0.670, 0.360, 1.00),
    ('Lahore', 0.648, 0.350, 0.88),
    ('Dhaka', 0.714, 0.388, 0.78),
    ('Chengdu', 0.762, 0.370, 0.68),
    ('Ulaanbaatar', 0.762, 0.280, 0.65),
    ('Kuwait', 0.596, 0.388, 0.58),
    ('Cairo', 0.555, 0.375, 0.52),
    ('Accra', 0.468, 0.445, 0.45),
    ('Jakarta', 0.758, 0.480, 0.42),
    ('Beijing', 0.770, 0.315, 0.60),
    ('Karachi', 0.640, 0.382, 0.55),
    ('Tehran', 0.605, 0.340, 0.48),
    ('Moscow', 0.568, 0.235, 0.30),
    ('London', 0.488, 0.240, 0.08),
    ('NY/East US', 0.195, 0.310, 0.18),
    ('LA', 0.120, 0.340, 0.22),
    ('Amazon', 0.268, 0.500, 0.25),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF050500),
    );

    // Grid
    final gridP = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;
    for (var i = 0; i <= 12; i++) {
      canvas.drawLine(Offset(w * i / 12, 0), Offset(w * i / 12, h), gridP);
    }
    for (var i = 0; i <= 5; i++) {
      canvas.drawLine(Offset(0, h * i / 5), Offset(w, h * i / 5), gridP);
    }

    // Continent outlines (same shapes, darker tone for pollution map)
    final landP = Paint()..color = const Color(0xFF0A0800);
    final borderP = Paint()
      ..color = const Color(0xFF2A2010)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    void drawC(List<Offset> pts) {
      final path = Path()..addPolygon(pts, true);
      canvas.drawPath(path, landP);
      canvas.drawPath(path, borderP);
    }

    drawC([
      Offset(w * .08, h * .15),
      Offset(w * .28, h * .12),
      Offset(w * .32, h * .25),
      Offset(w * .26, h * .50),
      Offset(w * .18, h * .55),
      Offset(w * .10, h * .42),
    ]);
    drawC([
      Offset(w * .24, h * .52),
      Offset(w * .32, h * .50),
      Offset(w * .33, h * .72),
      Offset(w * .26, h * .88),
      Offset(w * .20, h * .78),
      Offset(w * .20, h * .57),
    ]);
    drawC([
      Offset(w * .44, h * .18),
      Offset(w * .56, h * .16),
      Offset(w * .57, h * .32),
      Offset(w * .50, h * .36),
      Offset(w * .44, h * .30),
    ]);
    drawC([
      Offset(w * .45, h * .35),
      Offset(w * .57, h * .34),
      Offset(w * .60, h * .52),
      Offset(w * .55, h * .72),
      Offset(w * .47, h * .72),
      Offset(w * .42, h * .55),
    ]);
    drawC([
      Offset(w * .57, h * .16),
      Offset(w * .88, h * .14),
      Offset(w * .90, h * .42),
      Offset(w * .78, h * .50),
      Offset(w * .62, h * .46),
      Offset(w * .57, h * .32),
    ]);
    drawC([
      Offset(w * .74, h * .56),
      Offset(w * .88, h * .54),
      Offset(w * .90, h * .72),
      Offset(w * .78, h * .76),
      Offset(w * .72, h * .66),
    ]);

    // Pollution glow blobs
    final baseAlpha = 0.55 + 0.15 * math.sin(t * 2 * 3.14159);
    for (final hs in _hotspots) {
      final cx = w * hs.$2;
      final cy = h * hs.$3;
      final intensity = hs.$4;
      final r = 28.0 * intensity;
      final color = Color.lerp(
        const Color(0xFFFFD600),
        const Color(0xFFFF1744),
        intensity,
      )!;
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = color.withValues(alpha: baseAlpha * intensity * 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.8),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        3.0 * intensity,
        Paint()..color = color.withValues(alpha: 0.9),
      );
    }

    // Legend
    final tp = TextPainter(
      text: const TextSpan(
        text:
            'AIR POLLUTION DENSITY  •  PM2.5 AQI  •  Red = Hazardous  •  Yellow = Unhealthy  •  Source: IQAir 2026',
        style: TextStyle(color: Colors.white30, fontSize: 7),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(8, h - 16));
  }

  @override
  bool shouldRepaint(_PollutionMapPainter old) => old.t != t;
}
