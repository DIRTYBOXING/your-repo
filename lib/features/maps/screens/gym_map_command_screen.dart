import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/web_route_test_hook.dart';
import '../../../core/config/router_config.dart' as rc;

/// ═══════════════════════════════════════════════════════════════════════════
/// GYM MAP COMMAND — Dense, content-rich global gym + event map viewer
///
/// Two-panel: live map view (top/left) + scrollable gym/event feed (bottom/right).
/// Discipline filters, region selector, live event indicators, gym verification
/// badges, distance sorting, and deep links to gym profiles/events.
/// ═══════════════════════════════════════════════════════════════════════════

class GymMapCommandScreen extends StatefulWidget {
  const GymMapCommandScreen({super.key});
  @override
  State<GymMapCommandScreen> createState() => _GymMapCommandScreenState();
}

class _GymMapCommandScreenState extends State<GymMapCommandScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _selectedFilter = 0;
  String _selectedRegion = 'ALL';
  final TextEditingController _searchCtrl = TextEditingController();
  GoogleMapController? _mapController; // ignore: unused_field
  bool _mapReady = false;
  bool _mapTimedOut = false;
  Timer? _mapTimeoutTimer;

  static const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0a1628"}]},
  {"elementType":"geometry.stroke","stylers":[{"color":"#1a2a42"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8a92b8"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0a1628"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#1a2a42"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0f1d33"}]}
]
  ''';

  static const _filters = [
    'ALL',
    'GYMS',
    'EVENTS',
    'TRAINING CAMPS',
    'OPEN MATS',
  ];
  static const _filterIcons = [
    Icons.public_rounded,
    Icons.fitness_center_rounded,
    Icons.event_rounded,
    Icons.sports_mma_rounded,
    Icons.groups_rounded,
  ];

  static const _regions = [
    'ALL',
    'AUSTRALIA',
    'USA',
    'THAILAND',
    'BRAZIL',
    'UK',
    'JAPAN',
    'IRELAND',
    'MEXICO',
    'PHILIPPINES',
    'INDONESIA',
  ];

  static const _disciplines = [
    'MMA',
    'Boxing',
    'Muay Thai',
    'Kickboxing',
    'BJJ',
    'Wrestling',
    'BKFC',
    'Brawling',
    'Karate',
    'Judo',
    'Taekwondo',
    'Sambo',
    'Capoeira',
    'Krav Maga',
  ];
  final Set<String> _activeDisciplines = {'MMA', 'Boxing', 'Muay Thai', 'BKFC'};

  // ── Firestore live data ─────────────────────────────────────────────────
  final List<Map<String, dynamic>> _firestoreGyms = [];
  final List<Map<String, dynamic>> _firestoreEvents = [];
  StreamSubscription<QuerySnapshot>? _gymSub;
  StreamSubscription<QuerySnapshot>? _eventSub;

  // ── Demo gym data ──────────────────────────────────────────────────────
  final List<_GymPin> _gyms = [
    const _GymPin(
      'Tiger Muay Thai',
      'Phuket, Thailand',
      'Muay Thai, MMA, BJJ',
      4.8,
      'ELITE',
      true,
      true,
      47,
      8,
      lat: 7.8804,
      lng: 98.3923,
    ),
    const _GymPin(
      'AKA Thailand',
      'Phuket, Thailand',
      'MMA, Wrestling, Boxing',
      4.7,
      'PRO',
      true,
      false,
      35,
      6,
      lat: 7.8950,
      lng: 98.3380,
    ),
    const _GymPin(
      'Jackson-Wink MMA',
      'Albuquerque, USA',
      'MMA, Boxing, Wrestling',
      4.9,
      'ELITE',
      true,
      true,
      62,
      12,
      lat: 35.0844,
      lng: -106.6504,
    ),
    const _GymPin(
      'Evolve MMA',
      'Singapore',
      'MMA, Muay Thai, BJJ',
      4.6,
      'ELITE',
      true,
      true,
      55,
      10,
      lat: 1.2800,
      lng: 103.8500,
    ),
    const _GymPin(
      'Fortis MMA',
      'Dallas, USA',
      'MMA, Wrestling',
      4.8,
      'PRO',
      true,
      false,
      28,
      5,
      lat: 32.7767,
      lng: -96.7970,
    ),
    const _GymPin(
      'City Kickboxing',
      'Auckland, New Zealand',
      'MMA, Kickboxing, Wrestling',
      4.9,
      'ELITE',
      true,
      true,
      40,
      7,
      lat: -36.8485,
      lng: 174.7633,
    ),
    const _GymPin(
      'ATT (American Top Team)',
      'Coconut Creek, USA',
      'MMA, BJJ, Boxing',
      4.7,
      'ELITE',
      true,
      true,
      80,
      15,
      lat: 26.2517,
      lng: -80.1790,
    ),
    const _GymPin(
      'Sanford MMA',
      'Deerfield Beach, USA',
      'MMA, Kickboxing',
      4.6,
      'PRO',
      true,
      false,
      30,
      6,
      lat: 26.3184,
      lng: -80.0998,
    ),
    const _GymPin(
      'Kings MMA',
      'Huntington Beach, USA',
      'MMA, Muay Thai',
      4.8,
      'PRO',
      true,
      false,
      22,
      4,
      lat: 33.6603,
      lng: -117.9992,
    ),
    const _GymPin(
      'SBG Ireland',
      'Dublin, Ireland',
      'MMA, Boxing, BJJ',
      4.5,
      'PRO',
      true,
      false,
      18,
      3,
      lat: 53.3498,
      lng: -6.2603,
    ),
    const _GymPin(
      'Dirty Boxing Gym',
      'Logan, Australia',
      'MMA, Boxing, BKFC, Brawling',
      4.9,
      'ELITE',
      true,
      true,
      25,
      5,
      lat: -27.6388,
      lng: 153.1094,
    ),
    const _GymPin(
      'Allegiance MMA',
      'Brisbane, Australia',
      'MMA, Muay Thai, BJJ',
      4.4,
      'STANDARD',
      false,
      false,
      15,
      3,
      lat: -27.4698,
      lng: 153.0251,
    ),
    const _GymPin(
      'UFC Performance Institute',
      'Las Vegas, USA',
      'MMA, All Disciplines',
      5.0,
      'ELITE',
      true,
      true,
      100,
      20,
      lat: 36.1699,
      lng: -115.1398,
    ),
    const _GymPin(
      'Fairtex Training Center',
      'Pattaya, Thailand',
      'Muay Thai, MMA',
      4.7,
      'ELITE',
      true,
      true,
      50,
      9,
      lat: 12.9236,
      lng: 100.8825,
    ),
    const _GymPin(
      'Nova União',
      'Rio de Janeiro, Brazil',
      'BJJ, MMA',
      4.6,
      'PRO',
      true,
      false,
      35,
      6,
      lat: -22.9068,
      lng: -43.1729,
    ),
  ];

  // ── Demo event data ────────────────────────────────────────────────────
  final List<_EventPin> _events = [
    const _EventPin(
      'BKFC 72: Brisbane Brawl',
      'Brisbane, Australia',
      '15 Nov 2026',
      true,
      'BKFC',
      8,
      lat: -27.4698,
      lng: 153.0251,
    ),
    const _EventPin(
      'UFC Fight Night',
      'Las Vegas, USA',
      '22 Nov 2026',
      false,
      'MMA',
      12,
      lat: 36.1699,
      lng: -115.1398,
    ),
    const _EventPin(
      'ONE Championship 180',
      'Singapore',
      '29 Nov 2026',
      false,
      'MMA',
      14,
      lat: 1.2900,
      lng: 103.8600,
    ),
    const _EventPin(
      'DFC: Logan Throwdown',
      'Logan, Australia',
      '6 Dec 2026',
      true,
      'MMA',
      6,
      lat: -27.6388,
      lng: 153.1094,
    ),
    const _EventPin(
      'Glory Kickboxing 94',
      'Rotterdam, Netherlands',
      '13 Dec 2026',
      false,
      'Kickboxing',
      10,
      lat: 51.9244,
      lng: 4.4777,
    ),
    const _EventPin(
      'Lumpinee World Title',
      'Bangkok, Thailand',
      '20 Dec 2026',
      false,
      'Muay Thai',
      12,
      lat: 13.7563,
      lng: 100.5018,
    ),
  ];

  @override
  void initState() {
    super.initState();
    setWebRouteTestHook('map-command');
    _tabCtrl = TabController(length: 2, vsync: this);
    if (kIsWeb) {
      _mapTimeoutTimer = Timer(const Duration(seconds: 8), () {
        if (!_mapReady && mounted) {
          setState(() => _mapTimedOut = true);
        }
      });
    }
    _subscribeFirestore();
  }

  void _subscribeFirestore() {
    _gymSub = FirebaseFirestore.instance
        .collection('gyms')
        .where('status', isEqualTo: 'active')
        .limit(200)
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          setState(() {
            _firestoreGyms
              ..clear()
              ..addAll(snap.docs.map((d) => {'id': d.id, ...d.data()}));
          });
        }, onError: (_) {});

    _eventSub = FirebaseFirestore.instance
        .collection('events')
        .orderBy('eventDate', descending: true)
        .limit(100)
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          setState(() {
            _firestoreEvents
              ..clear()
              ..addAll(snap.docs.map((d) => {'id': d.id, ...d.data()}));
          });
        }, onError: (_) {});
  }

  @override
  void dispose() {
    _mapTimeoutTimer?.cancel();
    _gymSub?.cancel();
    _eventSub?.cancel();
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    return Semantics(
      label: 'data-test=map-canvas',
      child: Scaffold(
        backgroundColor: DesignTokens.bgPrimary,
        appBar: AppBar(
          title: const Text('Gym Map Command', style: DFCTextStyles.title),
          backgroundColor: DesignTokens.bgSecondary,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.my_location_rounded,
                color: DesignTokens.neonCyan,
                size: 20,
              ),
              tooltip: 'My Location',
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(
                Icons.add_business_rounded,
                color: DesignTokens.neonGreen,
                size: 20,
              ),
              tooltip: 'Register Gym',
              onPressed: () => context.push(rc.RouterConfig.registerGymPath),
            ),
          ],
        ),
        body: Column(
          children: [
            _searchBar(),
            _filterStrip(),
            Expanded(child: wide ? _wideLayout() : _narrowLayout()),
          ],
        ),
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────
  Widget _searchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: _searchCtrl,
        style: DFCTextStyles.body.copyWith(color: DesignTokens.textPrimary),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search gyms, events, locations…',
          hintStyle: DFCTextStyles.caption.copyWith(
            color: DesignTokens.textMuted,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: DesignTokens.neonCyan,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  // ── Filter strip ───────────────────────────────────────────────────────
  Widget _filterStrip() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _filters.length,
        separatorBuilder: (e1, e2) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final sel = _selectedFilter == i;
          return ChoiceChip(
            avatar: Icon(
              _filterIcons[i],
              size: 14,
              color: sel ? Colors.black : DesignTokens.textMuted,
            ),
            label: Text(
              _filters[i],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: sel ? Colors.black : DesignTokens.textPrimary,
              ),
            ),
            selected: sel,
            selectedColor: DesignTokens.neonCyan,
            backgroundColor: DesignTokens.bgCard,
            side: BorderSide(
              color: sel ? DesignTokens.neonCyan : DesignTokens.borderSubtle,
            ),
            onSelected: (_) => setState(() => _selectedFilter = i),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }

  // ── Wide layout: map left, list right ──────────────────────────────────
  Widget _wideLayout() {
    return Row(
      children: [
        Expanded(flex: 3, child: _mapPanel()),
        const VerticalDivider(width: 1, color: DesignTokens.borderSubtle),
        SizedBox(width: 380, child: _listPanel()),
      ],
    );
  }

  // ── Narrow layout: map top, list bottom ────────────────────────────────
  Widget _narrowLayout() {
    return Column(
      children: [
        SizedBox(height: 240, child: _mapPanel()),
        const Divider(height: 1, color: DesignTokens.borderSubtle),
        Expanded(child: _listPanel()),
      ],
    );
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return false;
  }

  String _eventDateLabel(dynamic value) {
    if (value is Timestamp) {
      final dt = value.toDate();
      return '${dt.day}/${dt.month}/${dt.year}';
    }
    if (value is DateTime) {
      return '${value.day}/${value.month}/${value.year}';
    }
    return (value ?? 'TBA').toString();
  }

  _GymPin _gymFromFirestore(Map<String, dynamic> d) {
    final city = (d['city'] ?? '').toString().trim();
    final country = (d['country'] ?? d['region'] ?? '').toString().trim();
    final location = [
      city,
      country,
    ].where((part) => part.isNotEmpty).join(', ');
    final pinkShield = (d['pinkShieldStatus'] ?? '')
        .toString()
        .trim()
        .isNotEmpty;

    return _GymPin(
      (d['name'] ?? 'Gym').toString(),
      location.isEmpty ? 'Unknown Location' : location,
      (d['disciplines'] is List)
          ? (d['disciplines'] as List).map((e) => e.toString()).join(', ')
          : (d['disciplines'] ?? 'MMA').toString(),
      _asDouble(d['rating']) == 0 ? 4.5 : _asDouble(d['rating']),
      (d['tier'] ?? 'STANDARD').toString().toUpperCase(),
      _asBool(d['isVerified'] ?? d['verified']),
      _asBool(d['hasLiveEvent'] ?? d['liveEvent']),
      _asInt(d['fighters']) == 0 ? 20 : _asInt(d['fighters']),
      _asInt(d['coaches']) == 0 ? 4 : _asInt(d['coaches']),
      pinkShield: pinkShield,
      lat: _asDouble(d['latitude'] ?? d['lat']),
      lng: _asDouble(d['longitude'] ?? d['lng']),
    );
  }

  _EventPin _eventFromFirestore(Map<String, dynamic> d) {
    final city = (d['city'] ?? '').toString().trim();
    final country = (d['country'] ?? d['region'] ?? '').toString().trim();
    final location = [
      city,
      country,
    ].where((part) => part.isNotEmpty).join(', ');
    final status = (d['status'] ?? '').toString().toLowerCase();

    return _EventPin(
      (d['title'] ?? d['name'] ?? 'Fight Event').toString(),
      location.isEmpty ? 'Unknown Location' : location,
      _eventDateLabel(d['eventDate'] ?? d['date']),
      _asBool(d['isLive'] ?? d['live']) || status == 'live',
      (d['sport'] ?? d['discipline'] ?? 'MMA').toString(),
      _asInt(d['bouts']) == 0 ? 8 : _asInt(d['bouts']),
      lat: _asDouble(d['latitude'] ?? d['lat']),
      lng: _asDouble(d['longitude'] ?? d['lng']),
    );
  }

  List<_GymPin> get _activeGyms {
    if (_firestoreGyms.isNotEmpty) {
      return _firestoreGyms
          .where(
            (g) =>
                _asDouble(g['latitude'] ?? g['lat']) != 0 &&
                _asDouble(g['longitude'] ?? g['lng']) != 0,
          )
          .map(_gymFromFirestore)
          .toList();
    }
    return _gyms;
  }

  List<_EventPin> get _activeEvents {
    if (_firestoreEvents.isNotEmpty) {
      return _firestoreEvents
          .where(
            (e) =>
                _asDouble(e['latitude'] ?? e['lat']) != 0 &&
                _asDouble(e['longitude'] ?? e['lng']) != 0,
          )
          .map(_eventFromFirestore)
          .toList();
    }
    return _events;
  }

  // ── Map panel — real GoogleMap with gym & event markers ────────────────
  Widget _mapPanel() {
    final gyms = _activeGyms;
    final events = _activeEvents;
    final markers = <Marker>{};

    for (final g in gyms) {
      final hue = g.pinkShield
          ? BitmapDescriptor.hueRose
          : (g.tier == 'ELITE'
                ? BitmapDescriptor.hueCyan
                : BitmapDescriptor.hueAzure);
      markers.add(
        Marker(
          markerId: MarkerId('gym_${g.name}'),
          position: LatLng(g.lat, g.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: g.name,
            snippet: g.pinkShield
                ? '${g.location} • PINK SHIELD • ★${g.rating}'
                : '${g.location} • ${g.tier} • ★${g.rating}',
          ),
        ),
      );
    }

    for (final e in events) {
      markers.add(
        Marker(
          markerId: MarkerId('event_${e.name}'),
          position: LatLng(e.lat, e.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            e.isLive ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: e.name,
            snippet: '${e.location} • ${e.date}',
          ),
        ),
      );
    }

    return Stack(
      children: [
        if (_mapTimedOut)
          Container(
            color: const Color(0xFF0a1628),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.map_outlined,
                    color: DesignTokens.neonCyan,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Map loading timed out',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gym data available in list tab',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(15.0, 40.0),
              zoom: 2.0,
            ),
            markers: markers,
            onMapCreated: (controller) {
              _mapReady = true;
              _mapTimeoutTimer?.cancel();
              _mapController = controller;
              controller.setMapStyle(_darkMapStyle);
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            style: _darkMapStyle,
          ),
        // Region selector overlay
        Positioned(top: 8, left: 8, right: 8, child: _regionSelector()),
        // Discipline chips overlay
        Positioned(bottom: 8, left: 8, right: 8, child: _disciplineChips()),
        // Stats overlay
        Positioned(top: 8, right: 8, child: _mapStatsOverlay()),
      ],
    );
  }

  Widget _regionSelector() {
    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _regions.length,
        separatorBuilder: (e1, e2) => const SizedBox(width: 4),
        itemBuilder: (_, i) {
          final sel = _selectedRegion == _regions[i];
          return GestureDetector(
            onTap: () => setState(() => _selectedRegion = _regions[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: sel
                    ? DesignTokens.neonCyan.withValues(alpha: 0.2)
                    : Colors.black54,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: sel ? DesignTokens.neonCyan : Colors.white12,
                ),
              ),
              child: Text(
                _regions[i],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: sel ? DesignTokens.neonCyan : Colors.white54,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _disciplineChips() {
    return SizedBox(
      height: 26,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _disciplines.length,
        separatorBuilder: (e1, e2) => const SizedBox(width: 4),
        itemBuilder: (_, i) {
          final d = _disciplines[i];
          final active = _activeDisciplines.contains(d);
          return GestureDetector(
            onTap: () => setState(() {
              active ? _activeDisciplines.remove(d) : _activeDisciplines.add(d);
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: active
                    ? DesignTokens.neonGreen.withValues(alpha: 0.15)
                    : Colors.black45,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: active ? DesignTokens.neonGreen : Colors.white10,
                ),
              ),
              child: Text(
                d,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: active ? DesignTokens.neonGreen : Colors.white38,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _mapStatsOverlay() {
    final gyms = _activeGyms;
    final events = _activeEvents;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _statRow('Gyms', '${gyms.length}', DesignTokens.neonCyan),
          _statRow('Events', '${events.length}', DesignTokens.neonRed),
          _statRow('Regions', '${_regions.length - 1}', DesignTokens.neonGreen),
          _statRow(
            'Disciplines',
            '${_activeDisciplines.length}',
            DesignTokens.neonAmber,
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 9,
            ),
          ),
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

  // ── List panel ─────────────────────────────────────────────────────────
  Widget _listPanel() {
    return Column(
      children: [
        // Tab bar: Gyms / Events
        TabBar(
          controller: _tabCtrl,
          indicatorColor: DesignTokens.neonCyan,
          labelColor: DesignTokens.neonCyan,
          unselectedLabelColor: DesignTokens.textMuted,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          tabs: [
            Tab(text: 'GYMS (${_activeGyms.length})'),
            Tab(text: 'EVENTS (${_activeEvents.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [_gymsList(), _eventsList()],
          ),
        ),
      ],
    );
  }

  Widget _gymsList() {
    final query = _searchCtrl.text.toLowerCase();
    final source = _activeGyms;
    final filtered = source.where((g) {
      if (query.isNotEmpty &&
          !g.name.toLowerCase().contains(query) &&
          !g.location.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filtered.length,
      itemBuilder: (_, i) => _gymCard(filtered[i]),
    );
  }

  Widget _gymCard(_GymPin gym) {
    final tierColor = switch (gym.tier) {
      'ELITE' => DesignTokens.neonGold,
      'PRO' => DesignTokens.neonCyan,
      _ => DesignTokens.textMuted,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(color: tierColor.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        onTap: () => context.push(rc.RouterConfig.findAGymPath),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      gym.name,
                      style: DFCTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: tierColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      gym.tier,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: tierColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (gym.verified) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      color: DesignTokens.neonGreen,
                      size: 14,
                    ),
                  ],
                  if (gym.pinkShield) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF1493).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFFFF1493).withValues(alpha: 0.5),
                          width: 0.7,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: Color(0xFFFF1493),
                            size: 9,
                          ),
                          SizedBox(width: 2),
                          Text(
                            'PINK SHIELD',
                            style: TextStyle(
                              color: Color(0xFFFF1493),
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 12,
                    color: DesignTokens.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    gym.location,
                    style: DFCTextStyles.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                gym.disciplines,
                style: DFCTextStyles.caption.copyWith(
                  fontSize: 10,
                  color: DesignTokens.neonCyan.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _miniStat(
                    Icons.star_rounded,
                    '${gym.rating}',
                    DesignTokens.neonAmber,
                  ),
                  const SizedBox(width: 12),
                  _miniStat(
                    Icons.people_rounded,
                    '${gym.fighters}',
                    DesignTokens.neonCyan,
                  ),
                  const SizedBox(width: 12),
                  _miniStat(
                    Icons.school_rounded,
                    '${gym.coaches}',
                    DesignTokens.neonMagenta,
                  ),
                  const Spacer(),
                  if (gym.hasLiveEvent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.neonRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: DesignTokens.neonRed.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: DesignTokens.neonRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'LIVE EVENT',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: DesignTokens.neonRed,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (gym.openNow && !gym.hasLiveEvent)
                    const Text(
                      'OPEN NOW',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.neonGreen,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventsList() {
    final events = _activeEvents;
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: events.length,
      itemBuilder: (_, i) => _eventCard(events[i]),
    );
  }

  Widget _eventCard(_EventPin event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(
          color: event.isLive
              ? DesignTokens.neonRed.withValues(alpha: 0.4)
              : DesignTokens.borderSubtle,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        onTap: () => context.push(rc.RouterConfig.eventsPath),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (event.isLive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: DesignTokens.neonRed.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: DesignTokens.neonRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: DesignTokens.neonRed,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Expanded(
                    child: Text(
                      event.name,
                      style: DFCTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 12,
                    color: DesignTokens.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    event.location,
                    style: DFCTextStyles.caption.copyWith(fontSize: 11),
                  ),
                  const Spacer(),
                  Text(
                    event.date,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.neonAmber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.sport,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.neonCyan,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _miniStat(
                    Icons.sports_mma_rounded,
                    '${event.bouts} bouts',
                    DesignTokens.neonGreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════
class _GymPin {
  final String name;
  final String location;
  final String disciplines;
  final double rating;
  final String tier;
  final bool verified;
  final bool hasLiveEvent;
  final bool pinkShield;
  final int fighters;
  final int coaches;
  final double lat;
  final double lng;
  bool get openNow {
    final hour = DateTime.now().hour;
    return hour >= 6 && hour < 22;
  }

  const _GymPin(
    this.name,
    this.location,
    this.disciplines,
    this.rating,
    this.tier,
    this.verified,
    this.hasLiveEvent,
    this.fighters,
    this.coaches, {
    this.pinkShield = false,
    required this.lat,
    required this.lng,
  });
}

class _EventPin {
  final String name;
  final String location;
  final String date;
  final bool isLive;
  final String sport;
  final int bouts;
  final double lat;
  final double lng;
  const _EventPin(
    this.name,
    this.location,
    this.date,
    this.isLive,
    this.sport,
    this.bouts, {
    required this.lat,
    required this.lng,
  });
}
