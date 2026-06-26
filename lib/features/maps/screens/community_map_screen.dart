import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/web_route_test_hook.dart';
import '../../../shared/services/dfc_map_marker_icon_service.dart';
import '../../../shared/services/map_marker_service.dart';
import '../../../shared/widgets/campaign_map_markers.dart';
import '../cluster_helper.dart';
import '../cluster_icon_loader.dart';

/// DFC Community Network Map
/// - Gyms, Events, Mentors, Sponsors on Google Maps
/// - Real-time event tracking with live indicators
/// - Filter by discipline
/// - Interactive markers with detail panels

class CommunityMapScreen extends StatefulWidget {
  final int initialTabIndex;
  final String title;
  final String subtitle;

  const CommunityMapScreen({
    super.key,
    this.initialTabIndex = 0,
    this.title = 'DFC COMMUNITY MAP',
    this.subtitle = 'Gyms · Events · Mentors · Campaigns',
  });

  @override
  State<CommunityMapScreen> createState() => _CommunityMapScreenState();
}

class _CommunityMapScreenState extends State<CommunityMapScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _pulseCtrl;
  GoogleMapController? _mapController;
  Timer? _cameraDebounce;
  String _activeFilter = 'ALL';
  final Set<Marker> _markers = {};
  MapMarkerData? _selectedItem;
  LatLng? _userLocation;
  final _markerService = MapMarkerService.instance;
  final _iconService = DfcMapMarkerIconService.instance;
  double _currentZoom = _initialPosition.zoom;
  int _markerBuildVersion = 0;

  // Web map timeout fallback
  bool _mapReady = false;
  bool _mapTimedOut = false;
  Timer? _mapTimeoutTimer;

  static const _filters = [
    'ALL',
    'MMA',
    'BOXING',
    'MUAY THAI',
    'BJJ',
    'KICKBOXING',
    'WRESTLING',
    'BARE KNUCKLE',
    'BKFC',
    'BRAWLING',
  ];

  // DFC Dark Map Style (Style ID: 551efef7ca3592f0c092eb43)
  static const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {"color": "#0a1628"}
    ]
  },
  {
    "elementType": "geometry.stroke",
    "stylers": [
      {"color": "#1a2a42"}
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#8a92b8"}
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {"color": "#0a1628"}
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [
      {"color": "#1a2a42"}
    ]
  },
  {
    "featureType": "administrative.country",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#00d4ff"}
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {"color": "#0f1d33"}
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#4a6a8a"}
    ]
  }
]
  ''';

  // Initial map position — centered on global view
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(20.0, 0.0), // Center of world
    zoom: 2.0,
    tilt: 45,
  );
  @override
  void initState() {
    super.initState();
    setWebRouteTestHook('map-community');
    _tabCtrl = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _initMarkerService();
    _requestUserLocation();

    // On web, Google Maps JS can silently fail. If onMapCreated
    // doesn't fire within 8s, fall back to the DFC list view.
    if (kIsWeb) {
      _mapTimeoutTimer = Timer(const Duration(seconds: 8), () {
        if (!_mapReady && mounted) {
          setState(() => _mapTimedOut = true);
          debugPrint('[CommunityMap] Map load timed out — showing fallback');
        }
      });
    }
  }

  Future<void> _initMarkerService() async {
    await _markerService.initialize();
    if (mounted) _updateMarkers();
  }

  Future<void> _requestUserLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      setState(() {
        _userLocation = LatLng(pos.latitude, pos.longitude);
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 10),
      );
    } catch (_) {
      // Permission denied or location unavailable — stay on default view
    }
  }

  @override
  void dispose() {
    _mapTimeoutTimer?.cancel();
    _tabCtrl.dispose();
    _pulseCtrl.dispose();
    _cameraDebounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _updateMarkers() async {
    final buildVersion = ++_markerBuildVersion;
    final typeFilter = switch (_tabCtrl.index) {
      0 => MarkerType.gym,
      1 => MarkerType.event,
      2 => MarkerType.mentor,
      3 => MarkerType.campaign,
      _ => null,
    };

    final disciplines = <String>{};
    if (_tabCtrl.index == 0 && _activeFilter != 'ALL') {
      disciplines.add(_activeFilter);
    }

    final data = _markerService.query(
      MarkerFilter(
        types: typeFilter != null ? {typeFilter} : {},
        disciplines: disciplines,
      ),
    );

    final clusterItems = data
        .map(
          (marker) => ClusterItem(
            id: marker.id,
            lat: marker.coordinate.lat,
            lng: marker.coordinate.lng,
          ),
        )
        .toList();
    final clusters = clusterMarkers(items: clusterItems, zoom: _currentZoom);

    final newMarkers = <Marker>{};
    for (final cluster in clusters) {
      if (buildVersion != _markerBuildVersion || !mounted) {
        return;
      }

      if (cluster.isCluster) {
        final icon = await ClusterIconLoader.instance.forCount(cluster.count);
        newMarkers.add(
          Marker(
            markerId: MarkerId(
              'cluster_${cluster.lat}_${cluster.lng}_${cluster.count}',
            ),
            position: LatLng(cluster.lat, cluster.lng),
            icon: icon,
            onTap: () {
              final targetZoom = math.min(_currentZoom + 2.0, 18.0);
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(cluster.lat, cluster.lng),
                  targetZoom,
                ),
              );
            },
          ),
        );
        continue;
      }

      final markerData = data.firstWhere(
        (item) => item.id == cluster.items.first.id,
      );
      final icon = await _iconService.iconForMarker(
        markerData,
        highlighted: _selectedItem?.id == markerData.id,
      );
      newMarkers.add(
        Marker(
          markerId: MarkerId(markerData.id),
          position: LatLng(
            markerData.coordinate.lat,
            markerData.coordinate.lng,
          ),
          icon: icon,
          infoWindow: InfoWindow(
            title: markerData.name,
            snippet: markerData.coordinate.displayLocation,
          ),
          onTap: () => _onMarkerTapped(markerData),
        ),
      );
    }

    if (!mounted || buildVersion != _markerBuildVersion) {
      return;
    }

    setState(() {
      _markers
        ..clear()
        ..addAll(newMarkers);
    });
  }

  void _onMarkerTapped(MapMarkerData m) {
    setState(() {
      _selectedItem = m;
    });
    _updateMarkers();
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(m.coordinate.lat, m.coordinate.lng),
        14,
      ),
    );
  }

  void _onCameraMove(CameraPosition position) {
    _cameraDebounce?.cancel();
    _cameraDebounce = Timer(const Duration(milliseconds: 180), () {
      if ((_currentZoom - position.zoom).abs() < 0.05) {
        return;
      }
      _currentZoom = position.zoom;
      _updateMarkers();
    });
  }

  Color _getGymColor(GymTier? tier) {
    switch (tier) {
      case GymTier.elite:
        return const Color(0xFFFFD600);
      case GymTier.premier:
        return AppColors.neonCyan;
      default:
        return const Color(0xFF00E676);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'data-test=map-canvas',
      child: Scaffold(
        backgroundColor: const Color(0xFF030810),
        body: SafeArea(
          child: Column(
            children: [
              Semantics(
                label: 'data-test=map-community',
                child: const SizedBox(width: 1, height: 1),
              ),
              _buildHeader(),
              _buildTabBar(),
              if (_tabCtrl.index == 0) _buildFilters(),
              Expanded(
                child: Stack(
                  children: [
                    _buildMapLayer(),
                    if (_selectedItem != null) _buildDetailPanel(),
                    Positioned(
                      right: 12,
                      bottom: _selectedItem != null ? 200 : 16,
                      child: FloatingActionButton.small(
                        heroTag: 'myLocation',
                        backgroundColor: const Color(0xFF0A1628),
                        onPressed: _requestUserLocation,
                        child: Icon(
                          _userLocation != null
                              ? Icons.my_location
                              : Icons.location_searching,
                          color: AppColors.neonCyan,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        border: Border(
          bottom: BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white54,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.public, color: AppColors.neonCyan, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  widget.subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          _buildLiveIndicator(),
        ],
      ),
    );
  }

  Widget _buildMapLayer() {
    // If the map timed out on web, show the fallback list
    if (_mapTimedOut) {
      return _buildWebMapFallback(
        reason:
            'Google Maps took too long to load. Showing DFC fallback map data.',
      );
    }

    return Semantics(
      label: 'data-test=map-canvas-community',
      child: GoogleMap(
        key: const ValueKey('map-canvas-community'),
        initialCameraPosition: _initialPosition,
        markers: _markers,
        style: _darkMapStyle,
        myLocationButtonEnabled: !kIsWeb,
        myLocationEnabled: !kIsWeb,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        onMapCreated: (controller) {
          _mapReady = true;
          _mapTimeoutTimer?.cancel();
          _mapController = controller;
          _updateMarkers();
        },
        onCameraMove: _onCameraMove,
        onTap: (_) {
          setState(() => _selectedItem = null);
          _updateMarkers();
        },
      ),
    );
  }

  Widget _buildWebMapFallback({String? reason}) {
    final tab = _tabCtrl.index;
    final stats = _markerService.stats;
    final totalLocations = _markerService.allMarkers.length;
    final liveEvents = stats['liveNow'] ?? 0;

    return Semantics(
      label: 'data-test=map-canvas-community-fallback',
      child: Container(
        color: const Color(0xFF030810),
        child: Column(
          children: [
            // ═══════════════════════════════════════════════════════════════════
            // GLOBE HERO — Visual global network display
            // ═══════════════════════════════════════════════════════════════════
            _buildGlobeHero(totalLocations, liveEvents),
            // ═══════════════════════════════════════════════════════════════════
            // DATA LIST — Scrollable list below
            // ═══════════════════════════════════════════════════════════════════
            if (tab == 3)
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: DonationThankYouTicker(donations: kDemoDonations),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  if (tab == 0) ..._buildGymFallbackCards(),
                  if (tab == 1) ..._buildEventFallbackCards(),
                  if (tab == 2) ..._buildMentorFallbackCards(),
                  if (tab == 3) ..._buildCampaignFallbackCards(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// ULTIMATE GLOBE COMMAND CENTER — The heart of DFC's global empire
  /// ═══════════════════════════════════════════════════════════════════════════
  Widget _buildGlobeHero(int totalLocations, int liveEvents) {
    final regions = _getRegionData();
    final stats = _markerService.stats;
    final eliteGyms = _markerService
        .query(
          const MarkerFilter(
            types: {MarkerType.gym},
            gymTiers: {GymTier.elite},
          ),
        )
        .length;

    return Container(
      height: 280,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF030810), Color(0xFF0A1628), Color(0xFF030810)],
        ),
      ),
      child: Stack(
        children: [
          // ═══ BACKGROUND GRID PATTERN ═══
          Positioned.fill(child: _buildGridPattern()),

          // ═══ EARTH VISUALIZATION ═══
          Center(child: _buildEarthVisualization(regions)),

          // ═══ NETWORK CONNECTION LINES ═══
          Positioned.fill(
            child: CustomPaint(
              painter: _NetworkLinesPainter(_pulseCtrl.value, regions),
            ),
          ),

          // ═══ REGION HOTSPOTS ═══
          ..._buildHotspots(regions),

          // ═══ LIVE ACTIVITY STREAM (Top) ═══
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildLiveActivityBar(liveEvents),
          ),

          // ═══ COMMAND CENTER STATS (Bottom) ═══
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildCommandStats(
              totalLocations,
              stats['totalMarkers'] ?? totalLocations,
              eliteGyms,
              regions.length,
            ),
          ),

          // ═══ CORNER BADGES ═══
          Positioned(
            top: 28,
            left: 8,
            child: _buildCornerBadge('🌏', 'GLOBAL OPS', AppColors.neonCyan),
          ),
          Positioned(
            top: 28,
            right: 8,
            child: _buildCornerBadge(
              '⚡',
              '${regions.length} REGIONS',
              const Color(0xFFFFD600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridPattern() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, _) {
        return CustomPaint(painter: _GridPatternPainter(_pulseCtrl.value));
      },
    );
  }

  Widget _buildEarthVisualization(Map<String, _RegionData> regions) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, _) {
        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.neonCyan.withValues(
                        alpha: 0.05 + _pulseCtrl.value * 0.03,
                      ),
                    ],
                  ),
                ),
              ),
              // Earth outline
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.3, -0.3),
                    radius: 0.8,
                    colors: [
                      Color(0xFF1A3A5C),
                      Color(0xFF0A1628),
                      Color(0xFF030810),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.neonCyan.withValues(
                      alpha: 0.25 + _pulseCtrl.value * 0.15,
                    ),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonCyan.withValues(
                        alpha: 0.15 + _pulseCtrl.value * 0.1,
                      ),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: CustomPaint(
                    painter: _ContinentsPainter(_pulseCtrl.value),
                    size: const Size(160, 160),
                  ),
                ),
              ),
              // Center pulse
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.neonCyan.withValues(
                        alpha: 0.4 + _pulseCtrl.value * 0.2,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.neonCyan,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonCyan.withValues(alpha: 0.8),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Orbital ring
              Transform.rotate(
                angle: _pulseCtrl.value * 0.5,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.neonCyan.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveActivityBar(int liveEvents) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF030810).withValues(alpha: 0.95),
            const Color(0xFF030810).withValues(alpha: 0.8),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          // Live indicator
          if (liveEvents > 0) ...[
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, _) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFFF1744,
                    ).withValues(alpha: 0.15 + _pulseCtrl.value * 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFFFF1744).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF1744),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$liveEvents LIVE NOW',
                        style: const TextStyle(
                          color: Color(0xFFFF1744),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
          ],
          // Status text
          const Expanded(
            child: Text(
              'DFC GLOBAL COMMAND',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          // Uptime indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF88).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF00FF88), size: 10),
                SizedBox(width: 4),
                Text(
                  'ONLINE',
                  style: TextStyle(
                    color: Color(0xFF00FF88),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandStats(
    int locations,
    int fighters,
    int eliteGyms,
    int regions,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFF030810).withValues(alpha: 0.9),
            const Color(0xFF030810),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatBox('$locations', 'LOCATIONS', AppColors.neonCyan),
          _buildStatDivider(),
          _buildStatBox('$fighters', 'FIGHTERS', const Color(0xFF00FF88)),
          _buildStatDivider(),
          _buildStatBox('$eliteGyms', 'ELITE GYMS', const Color(0xFFFFD600)),
          _buildStatDivider(),
          _buildStatBox(
            '${_markerService.stats['events'] ?? 0}',
            'EVENTS',
            const Color(0xFFFF6D00),
          ),
          _buildStatDivider(),
          _buildStatBox(
            '${_markerService.stats['mentors'] ?? 0}',
            'MENTORS',
            const Color(0xFFFF69B4),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 7,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildCornerBadge(String icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHotspots(Map<String, _RegionData> regions) {
    // Hotspot positions relative to center Earth (centered in 200x200 at screen center)
    final Map<String, Offset> hotspotPositions = {
      'NORTH AMERICA': const Offset(-60, -20),
      'SOUTH AMERICA': const Offset(-40, 50),
      'EUROPE': const Offset(20, -30),
      'AFRICA': const Offset(30, 20),
      'ASIA': const Offset(60, -15),
      'SE ASIA': const Offset(70, 20),
      'OCEANIA': const Offset(75, 55),
    };

    return regions.entries
        .where((e) => hotspotPositions.containsKey(e.key))
        .map((entry) {
          final offset = hotspotPositions[entry.key]!;
          final data = entry.value;
          final total = data.total;
          final size = 8.0 + (total * 0.6).clamp(0, 8);

          return Positioned(
            left: MediaQuery.of(context).size.width / 2 + offset.dx - size / 2,
            top: 140 + offset.dy - size / 2,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, _) {
                final baseColor = data.hasLive
                    ? const Color(0xFFFF1744)
                    : AppColors.neonCyan;
                return Container(
                  width: size + _pulseCtrl.value * 4,
                  height: size + _pulseCtrl.value * 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: baseColor.withValues(alpha: 0.7),
                    boxShadow: [
                      BoxShadow(
                        color: baseColor.withValues(
                          alpha: 0.5 + _pulseCtrl.value * 0.3,
                        ),
                        blurRadius: 10 + _pulseCtrl.value * 5,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        })
        .toList();
  }

  Map<String, _RegionData> _getRegionData() {
    final Map<String, _RegionData> regions = {};
    for (final m in _markerService.allMarkers) {
      final region = _getRegion(m.coordinate.lat, m.coordinate.lng);
      regions[region] ??= _RegionData(region);
      switch (m.type) {
        case MarkerType.gym:
          regions[region]!.gymCount++;
        case MarkerType.event:
          regions[region]!.eventCount++;
          if (m.isLive) regions[region]!.hasLive = true;
        case MarkerType.mentor:
          regions[region]!.mentorCount++;
        case MarkerType.campaign:
          regions[region]!.campaignCount++;
      }
    }
    return regions;
  }

  String _getRegion(double lat, double lng) {
    // Simple region classification
    if (lat > 25 && lng > -130 && lng < -60) return 'NORTH AMERICA';
    if (lat < 15 && lat > -55 && lng > -85 && lng < -35) return 'SOUTH AMERICA';
    if (lat > 35 && lng > -10 && lng < 60) return 'EUROPE';
    if (lat < 35 && lng > -20 && lng < 55) return 'AFRICA';
    if (lat > 10 && lng > 60 && lng < 150) return 'ASIA';
    if (lat < 0 && lng > 110 && lng < 180) return 'OCEANIA';
    if (lat > 10 && lat < 35 && lng > 90 && lng < 140) return 'SE ASIA';
    return 'GLOBAL';
  }

  List<Widget> _buildGymFallbackCards() {
    final disciplines = <String>{};
    if (_activeFilter != 'ALL') disciplines.add(_activeFilter);
    final gyms = _markerService.query(
      MarkerFilter(types: {MarkerType.gym}, disciplines: disciplines),
    );

    return gyms
        .map(
          (m) => _fallbackCard(
            title: m.name,
            subtitle:
                '${m.coordinate.displayLocation}  •  ${m.disciplines.take(2).join(" / ")}',
            trailing:
                '${m.coordinate.lat.toStringAsFixed(3)}, ${m.coordinate.lng.toStringAsFixed(3)}',
            accent: _getGymColor(m.gymTier),
            onTap: () => _onMarkerTapped(m),
          ),
        )
        .toList();
  }

  List<Widget> _buildEventFallbackCards() {
    final events = _markerService.query(
      const MarkerFilter(types: {MarkerType.event}),
    );
    return events
        .map(
          (m) => _fallbackCard(
            title: '${m.organization ?? ''} - ${m.name}',
            subtitle:
                '${m.coordinate.displayLocation}  •  ${m.eventStatus?.name.toUpperCase() ?? 'UPCOMING'}',
            trailing: m.isPPV ? 'PPV' : (m.eventDate ?? '').toString(),
            accent: m.isLive ? const Color(0xFFFF1744) : AppColors.neonCyan,
            onTap: () => _onMarkerTapped(m),
          ),
        )
        .toList();
  }

  List<Widget> _buildMentorFallbackCards() {
    final mentors = _markerService.query(
      const MarkerFilter(types: {MarkerType.mentor}),
    );
    return mentors
        .map(
          (m) => _fallbackCard(
            title: m.name,
            subtitle:
                '${m.mentorSpecialty ?? ''}  •  ${m.coordinate.displayLocation}',
            trailing: m.mentorTier?.name.toUpperCase() ?? '',
            accent: m.mentorTier == MentorTier.pinkDiamond
                ? const Color(0xFFFF69B4)
                : const Color(0xFFFFD600),
            onTap: () => _onMarkerTapped(m),
          ),
        )
        .toList();
  }

  Widget _fallbackCard({
    required String title,
    required String subtitle,
    required String trailing,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1628),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              trailing,
              style: TextStyle(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    final liveCount = _markerService.stats['liveEvents'] ?? 0;
    if (liveCount == 0) return const SizedBox();

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(
              0xFFFF1744,
            ).withValues(alpha: 0.1 + _pulseCtrl.value * 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(
                0xFFFF1744,
              ).withValues(alpha: 0.3 + _pulseCtrl.value * 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF1744),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$liveCount LIVE',
                style: const TextStyle(
                  color: Color(0xFFFF1744),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: AppColors.neonCyan,
        indicatorWeight: 2.5,
        labelColor: AppColors.neonCyan,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
        onTap: (_) => _updateMarkers(),
        tabs: const [
          Tab(text: 'GYMS'),
          Tab(text: 'EVENTS'),
          Tab(text: 'MENTORS'),
          Tab(text: 'CAMPAIGNS'),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _filters.map((f) {
          final active = f == _activeFilter;
          return GestureDetector(
            onTap: () {
              setState(() {
                _activeFilter = f;
                _selectedItem = null;
              });
              _updateMarkers();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.neonCyan.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active ? AppColors.neonCyan : Colors.white12,
                ),
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: active ? AppColors.neonCyan : Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailPanel() {
    if (_selectedItem == null) return const SizedBox();
    final m = _selectedItem!;

    Widget content;
    switch (m.type) {
      case MarkerType.gym:
        final color = _getGymColor(m.gymTier);
        content = _buildGymPanel(m, color);
      case MarkerType.event:
        final color = m.isLive ? const Color(0xFFFF1744) : AppColors.neonCyan;
        content = _buildEventPanel(m, color);
      case MarkerType.campaign:
        final color = switch (m.campaignKind) {
          CampaignKind.pinkShield => const Color(0xFFFF69B4),
          CampaignKind.coffeeNotCoffin => const Color(0xFF8D6E63),
          _ => const Color(0xFFFFD600),
        };
        content = _buildCampaignPanel(m, color);
      case MarkerType.mentor:
        final color = m.mentorTier == MentorTier.pinkDiamond
            ? const Color(0xFFFF69B4)
            : const Color(0xFFFFD600);
        content = _buildMentorPanel(m, color);
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () => setState(() => _selectedItem = null),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1628),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _buildGymPanel(MapMarkerData m, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.fitness_center, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m.coordinate.displayLocation,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (m.rating != null)
                        _chip('⭐ ${m.rating}', Colors.amber),
                      ...m.disciplines
                          .take(3)
                          .map((d) => _chip(d, color.withValues(alpha: 0.7))),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                m.tierLabel.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _panelAction(
                Icons.search,
                'FIND GYMS',
                color,
                () => context.push('/find-a-gym'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _panelAction(
                Icons.directions,
                'DIRECTIONS',
                Colors.white54,
                () =>
                    _openDirections(m.coordinate.lat, m.coordinate.lng, m.name),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventPanel(MapMarkerData m, Color color) {
    final statusLabel = m.eventStatus?.name.toUpperCase() ?? 'UPCOMING';
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            m.isLive ? Icons.live_tv : Icons.event,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (m.isLive) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF1744),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    m.organization ?? '',
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  if (m.isPPV) ...[
                    const SizedBox(width: 8),
                    const Text(
                      'PPV',
                      style: TextStyle(
                        color: Color(0xFFFFD600),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                m.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                m.coordinate.displayLocation,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMentorPanel(MapMarkerData m, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.school, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m.mentorSpecialty ?? '',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m.coordinate.displayLocation,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (m.rating != null)
                        _chip('⭐ ${m.rating}', Colors.amber),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${m.mentorTier?.name.toUpperCase() ?? ''} ◆',
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _panelAction(
                Icons.map,
                'MENTOR MAP',
                color,
                () => context.push('/mentor-map'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _panelAction(
                Icons.directions,
                'DIRECTIONS',
                Colors.white54,
                () =>
                    _openDirections(m.coordinate.lat, m.coordinate.lng, m.name),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCampaignPanel(MapMarkerData m, Color color) {
    final campaignName = m.campaignKind?.name ?? 'campaign';
    return Row(
      children: [
        if (m.campaignKind == CampaignKind.pinkShield)
          const SizedBox(
            width: 44,
            height: 44,
            child: PinkShieldMarker(size: 40),
          )
        else if (m.campaignKind == CampaignKind.coffeeNotCoffin)
          const SizedBox(
            width: 44,
            height: 44,
            child: CoffeeCampaignMarker(size: 40),
          )
        else
          const SizedBox(
            width: 44,
            height: 44,
            child: GoldCoinMarker(size: 40),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                campaignName.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                m.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                m.coordinate.displayLocation,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                m.description ?? '',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        if (m.tags.contains('verified'))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'VERIFIED',
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildCampaignFallbackCards() {
    final campaigns = _markerService.query(
      const MarkerFilter(types: {MarkerType.campaign}),
    );
    return campaigns.map((m) {
      final color = switch (m.campaignKind) {
        CampaignKind.pinkShield => const Color(0xFFFF69B4),
        CampaignKind.coffeeNotCoffin => const Color(0xFF8D6E63),
        _ => const Color(0xFFFFD600),
      };
      return _fallbackCard(
        title: '${m.campaignKind?.name ?? 'Campaign'}: ${m.name}',
        subtitle: '${m.coordinate.displayLocation} • ${m.description ?? ''}',
        trailing: m.tags.contains('verified') ? 'VERIFIED' : 'PENDING',
        accent: color,
        onTap: () => _onMarkerTapped(m),
      );
    }).toList();
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _panelAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDirections(double lat, double lng, String name) async {
    final encoded = Uri.encodeComponent(name);
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$encoded',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SUPPORTING MODELS
// ══════════════════════════════════════════════════════════════════════════════

/// Region aggregation data for globe hero display
class _RegionData {
  final String name;
  int gymCount = 0;
  int eventCount = 0;
  int mentorCount = 0;
  int campaignCount = 0;
  bool hasLive = false;

  _RegionData(this.name);

  int get total => gymCount + eventCount + mentorCount + campaignCount;
}

// ══════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS — Globe Command Center Graphics
// ══════════════════════════════════════════════════════════════════════════════

/// Grid pattern painter for background effect
class _GridPatternPainter extends CustomPainter {
  final double pulse;

  _GridPatternPainter(this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.03 + pulse * 0.02)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Vertical lines
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPatternPainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}

/// Continents painter - stylized world map silhouette
class _ContinentsPainter extends CustomPainter {
  final double pulse;

  _ContinentsPainter(this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.15 + pulse * 0.08)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.25 + pulse * 0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.45;

    // North America (simplified blob)
    final naPath = Path();
    naPath.moveTo(cx - r * 0.6, cy - r * 0.3);
    naPath.quadraticBezierTo(
      cx - r * 0.3,
      cy - r * 0.5,
      cx - r * 0.1,
      cy - r * 0.25,
    );
    naPath.quadraticBezierTo(
      cx - r * 0.2,
      cy + r * 0.1,
      cx - r * 0.5,
      cy + r * 0.05,
    );
    naPath.close();
    canvas.drawPath(naPath, paint);
    canvas.drawPath(naPath, strokePaint);

    // South America
    final saPath = Path();
    saPath.moveTo(cx - r * 0.35, cy + r * 0.15);
    saPath.quadraticBezierTo(
      cx - r * 0.2,
      cy + r * 0.25,
      cx - r * 0.25,
      cy + r * 0.6,
    );
    saPath.quadraticBezierTo(
      cx - r * 0.35,
      cy + r * 0.5,
      cx - r * 0.4,
      cy + r * 0.2,
    );
    saPath.close();
    canvas.drawPath(saPath, paint);
    canvas.drawPath(saPath, strokePaint);

    // Europe/Africa
    final euPath = Path();
    euPath.moveTo(cx + r * 0.0, cy - r * 0.35);
    euPath.quadraticBezierTo(
      cx + r * 0.2,
      cy - r * 0.3,
      cx + r * 0.15,
      cy - r * 0.1,
    );
    euPath.quadraticBezierTo(
      cx + r * 0.25,
      cy + r * 0.3,
      cx + r * 0.1,
      cy + r * 0.5,
    );
    euPath.quadraticBezierTo(
      cx - r * 0.05,
      cy + r * 0.2,
      cx + r * 0.0,
      cy - r * 0.35,
    );
    canvas.drawPath(euPath, paint);
    canvas.drawPath(euPath, strokePaint);

    // Asia/Australia
    final asPath = Path();
    asPath.moveTo(cx + r * 0.25, cy - r * 0.25);
    asPath.quadraticBezierTo(
      cx + r * 0.55,
      cy - r * 0.2,
      cx + r * 0.6,
      cy + r * 0.1,
    );
    asPath.quadraticBezierTo(
      cx + r * 0.5,
      cy + r * 0.25,
      cx + r * 0.3,
      cy + r * 0.15,
    );
    asPath.close();
    canvas.drawPath(asPath, paint);
    canvas.drawPath(asPath, strokePaint);

    // Australia
    final auPath = Path();
    auPath.addOval(
      Rect.fromCenter(
        center: Offset(cx + r * 0.55, cy + r * 0.45),
        width: r * 0.25,
        height: r * 0.15,
      ),
    );
    canvas.drawPath(auPath, paint);
    canvas.drawPath(auPath, strokePaint);
  }

  @override
  bool shouldRepaint(_ContinentsPainter oldDelegate) =>
      oldDelegate.pulse != pulse;
}

/// Network lines painter - connections between regions
class _NetworkLinesPainter extends CustomPainter {
  final double pulse;
  final Map<String, _RegionData> regions;

  _NetworkLinesPainter(this.pulse, this.regions);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.12 + pulse * 0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.05 + pulse * 0.03)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Hub positions (relative to center)
    final hubs = <String, Offset>{
      'NORTH AMERICA': Offset(cx - 60, cy - 20),
      'SOUTH AMERICA': Offset(cx - 40, cy + 50),
      'EUROPE': Offset(cx + 20, cy - 30),
      'ASIA': Offset(cx + 60, cy - 15),
      'SE ASIA': Offset(cx + 70, cy + 20),
      'OCEANIA': Offset(cx + 75, cy + 55),
      'AFRICA': Offset(cx + 30, cy + 20),
    };

    // Draw connections between active hubs
    final activeHubs = regions.keys.where(hubs.containsKey).toList();

    for (int i = 0; i < activeHubs.length; i++) {
      for (int j = i + 1; j < activeHubs.length; j++) {
        final p1 = hubs[activeHubs[i]]!;
        final p2 = hubs[activeHubs[j]]!;

        // Draw curved connection
        final midX = (p1.dx + p2.dx) / 2;
        final midY = (p1.dy + p2.dy) / 2 - 20; // Arc upward

        final path = Path();
        path.moveTo(p1.dx, p1.dy);
        path.quadraticBezierTo(midX, midY, p2.dx, p2.dy);

        canvas.drawPath(path, glowPaint);
        canvas.drawPath(path, paint);
      }
    }

    // Draw data pulse on lines
    final pulseOffset = pulse * 2 * math.pi;
    final pulsePaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < activeHubs.length && i < 3; i++) {
      final hubName = activeHubs[i];
      final p = hubs[hubName]!;

      // Orbiting pulse dots
      final angle = pulseOffset + (i * math.pi / 1.5);
      final orbitR = 25.0;
      final px = p.dx + math.cos(angle) * orbitR;
      final py = p.dy + math.sin(angle) * orbitR;

      canvas.drawCircle(Offset(px, py), 2, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(_NetworkLinesPainter oldDelegate) =>
      oldDelegate.pulse != pulse || oldDelegate.regions != regions;
}
