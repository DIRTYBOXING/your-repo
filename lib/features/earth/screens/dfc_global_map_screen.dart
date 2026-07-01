import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/maps_config_service.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../../../shared/services/dfc_map_marker_icon_service.dart';
import '../../../shared/services/map_marker_service.dart';
import '../../maps/cluster_helper.dart';
import '../../maps/cluster_icon_loader.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DFC GLOBAL MAP — Service-Driven Dynamic Markers
// Gyms, Events, Campaigns, Mentors worldwide via MapMarkerService
// API Key configured in web/index.html
// ═══════════════════════════════════════════════════════════════════════════════

class DFCGlobalMapScreen extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String initialFilter;

  const DFCGlobalMapScreen({
    super.key,
    this.title = 'DFC GLOBAL MAP',
    this.subtitle,
    this.initialFilter = 'ALL',
  });

  @override
  State<DFCGlobalMapScreen> createState() => _DFCGlobalMapScreenState();
}

class _DFCGlobalMapScreenState extends State<DFCGlobalMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  String _activeFilter = 'ALL';
  MapMarkerData? _selectedMarker;
  double _currentZoom = 2.0;
  Timer? _cameraDebounce;
  Timer? _mapTimeout;
  StreamSubscription<List<MapMarkerData>>? _markerSub;
  bool _mapError = false;
  bool _serviceReady = false;
  bool _mapReady = false;
  bool _mapTimedOut = false;
  Timer? _mapTimeoutTimer;

  final _service = MapMarkerService.instance;
  final _iconService = DfcMapMarkerIconService.instance;

  // DFC Dark theme colors
  static const _bg = Color(0xFF0A0A12);
  static const _card = Color(0xFF12121A);
  static const _cyan = Color(0xFF00E5FF);
  static const _pink = Color(0xFFFF69B4);
  static const _gold = Color(0xFFFFD700);
  static const _green = Color(0xFF00E676);

  static const _filters = ['ALL', 'GYMS', 'EVENTS', 'CAMPAIGNS', 'MENTORS'];

  static const _filterToType = {
    'GYMS': MarkerType.gym,
    'EVENTS': MarkerType.event,
    'CAMPAIGNS': MarkerType.campaign,
    'MENTORS': MarkerType.mentor,
  };

  // Dark map style matching DFC theme
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
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#6a7a9a"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#0f1d33"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#5a6a8a"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#1a2a42"}]}
]
  ''';

  @override
  void initState() {
    super.initState();
    if (_filters.contains(widget.initialFilter)) {
      _activeFilter = widget.initialFilter;
    }
    if (kIsWeb && !MapsConfigService.isConfigured) {
      // Avoid a blank/white map when the JS key was not injected for this run.
      _mapError = true;
    } else if (kIsWeb) {
      _mapTimeout = Timer(const Duration(seconds: 8), () {
        if (!_mapReady && mounted) {
          setState(() => _mapError = true);
        }
      });
    }
    _initService();
    if (kIsWeb) {
      _mapTimeoutTimer = Timer(const Duration(seconds: 8), () {
        if (!_mapReady && mounted) {
          setState(() => _mapTimedOut = true);
        }
      });
    }
  }

  Future<void> _initService() async {
    await _service.initialize();
    if (!mounted) return;
    setState(() => _serviceReady = true);
    _markerSub = _service.markerStream.listen((_) {
      if (mounted) _buildMarkers();
    });
    _buildMarkers();
  }

  @override
  void dispose() {
    _mapTimeoutTimer?.cancel();
    _cameraDebounce?.cancel();
    _mapTimeout?.cancel();
    _markerSub?.cancel();
    super.dispose();
  }

  /// Get service data filtered by the active chip.
  List<MapMarkerData> get _filteredData {
    if (_activeFilter == 'ALL') return _service.allMarkers;
    final type = _filterToType[_activeFilter];
    if (type == null) return _service.allMarkers;
    return _service.query(MarkerFilter(types: {type}));
  }

  void _onCameraMove(CameraPosition pos) {
    _cameraDebounce?.cancel();
    _cameraDebounce = Timer(const Duration(milliseconds: 200), () {
      if (_currentZoom != pos.zoom) {
        _currentZoom = pos.zoom;
        _buildMarkers();
      }
    });
  }

  Future<void> _buildMarkers() async {
    final data = _filteredData;

    // Convert to ClusterItems
    final clusterItems = data.map((m) {
      return ClusterItem(
        id: m.id,
        lat: m.coordinate.lat,
        lng: m.coordinate.lng,
        data: m.toMap(),
      );
    }).toList();

    final clusters = clusterMarkers(items: clusterItems, zoom: _currentZoom);

    final Set<Marker> newMarkers = {};
    for (final cluster in clusters) {
      if (cluster.isCluster) {
        final icon = await ClusterIconLoader.instance.forCount(cluster.count);
        newMarkers.add(
          Marker(
            markerId: MarkerId('cluster_${cluster.lat}_${cluster.lng}'),
            position: LatLng(cluster.lat, cluster.lng),
            icon: icon,
            onTap: () {
              final targetZoom = min(_currentZoom + 2.0, 21.0);
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(cluster.lat, cluster.lng),
                  targetZoom,
                ),
              );
            },
          ),
        );
      } else {
        final item = cluster.items.first;
        final marker = data.firstWhere((m) => m.id == item.id);
        final icon = await _iconService.iconForMarker(
          marker,
          highlighted: _selectedMarker?.id == marker.id,
        );
        newMarkers.add(
          Marker(
            markerId: MarkerId(marker.id),
            position: LatLng(marker.coordinate.lat, marker.coordinate.lng),
            icon: icon,
            infoWindow: InfoWindow(
              title: marker.name,
              snippet:
                  '${marker.coordinate.countryFlag ?? ''} ${marker.coordinate.displayLocation}',
            ),
            onTap: () => _showMarkerDetail(marker),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _markers = newMarkers);
    }
  }

  void _showMarkerDetail(MapMarkerData marker) {
    setState(() => _selectedMarker = marker);
    _buildMarkers();
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(marker.coordinate.lat, marker.coordinate.lng),
        12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final useFallbackView = _mapError || _mapTimedOut;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ─── GOOGLE MAP ───
          if (useFallbackView)
            _buildFallbackView()
          else
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(20.0, 0.0),
                zoom: 2.0,
              ),
              markers: _markers,
              style: _darkMapStyle,
              onMapCreated: (controller) {
                _mapReady = true;
                _mapTimeoutTimer?.cancel();
                _mapController = controller;
              },
              onCameraMove: _onCameraMove,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              onTap: (_) => setState(() => _selectedMarker = null),
            ),

          // Loading indicator
          if (!_serviceReady)
            const Center(child: CircularProgressIndicator(color: _cyan)),

          // ─── TOP BAR ───
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const SizedBox(height: 8),
                _buildFilterChips(),
              ],
            ),
          ),

          // ─── STATS OVERLAY ───
          Positioned(
            bottom: _selectedMarker != null ? 200 : 16,
            left: 16,
            child: _buildStatsOverlay(),
          ),

          // ─── LOCATION DETAIL PANEL ───
          if (_selectedMarker != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildDetailPanel(_selectedMarker!),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackView() {
    final filtered = _filteredData;
    final bottomPadding = _selectedMarker != null ? 220.0 : 112.0;
    final diagnostic = _mapError
        ? (MapsConfigService.configError ??
              'Interactive Earth view is unavailable in this session.')
        : 'Earth view took too long to load, so DFC switched to list mode.';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF08101C), Color(0xFF0A0A12), Color(0xFF120915)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 112, 16, bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFallbackBanner(diagnostic),
              const SizedBox(height: 16),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyFallbackState()
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return _buildFallbackCard(filtered[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackBanner(String diagnostic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card.withAlpha(235),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cyan.withAlpha(70)),
        boxShadow: [
          BoxShadow(
            color: _pink.withAlpha(20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _cyan.withAlpha(22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _mapError ? Icons.public_off : Icons.radar,
              color: _cyan,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'DFC EARTH NETWORK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _gold.withAlpha(24),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _gold.withAlpha(70)),
                      ),
                      child: const Text(
                        'LIST MODE',
                        style: TextStyle(
                          color: _gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  diagnostic,
                  style: TextStyle(
                    color: Colors.white.withAlpha(185),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Gyms, live events, campaigns, and mentors remain fully operational with imagery, filters, and location details.',
                  style: TextStyle(
                    color: Colors.white.withAlpha(135),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFallbackState() {
    return Container(
      decoration: BoxDecoration(
        color: _card.withAlpha(220),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.public_off, color: _cyan, size: 44),
              const SizedBox(height: 12),
              const Text(
                'No locations match this filter yet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Try another lane to inspect gyms, events, campaigns, or mentors across the DFC network.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(150),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackCard(MapMarkerData marker) {
    final isSelected = _selectedMarker?.id == marker.id;
    Color accentColor;
    IconData typeIcon;
    String kicker;

    switch (marker.type) {
      case MarkerType.gym:
        accentColor = Colors.red;
        typeIcon = Icons.fitness_center;
        kicker = marker.isVerified ? 'VERIFIED GYM' : marker.tierLabel;
      case MarkerType.event:
        accentColor = marker.isLive ? _green : _cyan;
        typeIcon = Icons.sports_mma;
        kicker = marker.isLive ? 'LIVE EVENT' : marker.tierLabel;
      case MarkerType.campaign:
        accentColor = marker.campaignKind == CampaignKind.pinkShield
            ? _pink
            : _gold;
        typeIcon = Icons.volunteer_activism;
        kicker = marker.tierLabel;
      case MarkerType.mentor:
        accentColor = marker.mentorTier == MentorTier.pinkDiamond
            ? _pink
            : _gold;
        typeIcon = Icons.psychology_alt;
        kicker = marker.tierLabel;
    }

    final visual = marker.imageUrl != null && marker.imageUrl!.trim().isNotEmpty
        ? DfcNetworkImage(
            url: marker.imageUrl!,
            width: 112,
            borderRadius: BorderRadius.circular(16),
          )
        : Container(
            width: 112,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accentColor.withAlpha(120), const Color(0xFF101826)],
              ),
            ),
            child: Icon(typeIcon, color: Colors.white.withAlpha(210), size: 34),
          );

    final summary = marker.description?.trim().isNotEmpty == true
        ? marker.description!.trim()
        : (marker.disciplines.isNotEmpty
              ? marker.disciplines.take(3).join(' · ')
              : 'DFC network location');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _showMarkerDetail(marker),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? _card.withAlpha(245) : _card.withAlpha(224),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? accentColor.withAlpha(180) : Colors.white12,
              width: isSelected ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withAlpha(isSelected ? 30 : 14),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 112, height: 132, child: visual),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha(28),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: accentColor.withAlpha(90),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(typeIcon, size: 12, color: accentColor),
                              const SizedBox(width: 6),
                              Text(
                                kicker,
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_outward,
                          size: 18,
                          color: Colors.white.withAlpha(130),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      marker.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          marker.coordinate.countryFlag ?? '🌍',
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            marker.coordinate.displayLocation,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withAlpha(170),
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withAlpha(145),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildCardSignalChip(
                          label: marker.type == MarkerType.event && marker.isPPV
                              ? 'PPV'
                              : marker.tierLabel,
                          color: accentColor,
                        ),
                        if (marker.type == MarkerType.gym &&
                            marker.rating != null)
                          _buildCardSignalChip(
                            label: '★ ${marker.rating!.toStringAsFixed(1)}',
                            color: _gold,
                          ),
                        if (marker.type == MarkerType.event &&
                            marker.eventDate != null)
                          _buildCardSignalChip(
                            label:
                                '${marker.eventDate!.day}/${marker.eventDate!.month}/${marker.eventDate!.year}',
                            color: Colors.white70,
                          ),
                      ],
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

  Widget _buildCardSignalChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _card.withAlpha(230),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cyan.withAlpha(50)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.public, color: _cyan, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle!,
                    style: TextStyle(
                      color: Colors.white.withAlpha(150),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _green.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _green.withAlpha(100)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_service.liveEventCount} LIVE',
                  style: const TextStyle(
                    color: _green,
                    fontSize: 11,
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

  Widget _buildFilterChips() {
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final filter = _filters[i];
          final isActive = _activeFilter == filter;
          return GestureDetector(
            onTap: () {
              setState(() => _activeFilter = filter);
              _buildMarkers();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? _cyan : _card.withAlpha(200),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isActive ? _cyan : Colors.white24),
              ),
              alignment: Alignment.center,
              child: Text(
                filter,
                style: TextStyle(
                  color: isActive ? _bg : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsOverlay() {
    final stats = _service.stats;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card.withAlpha(230),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cyan.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _statRow('🥊', '${stats['gyms']} Gyms', Colors.red),
          const SizedBox(height: 6),
          _statRow('📍', '${stats['events']} Events', _cyan),
          const SizedBox(height: 6),
          _statRow('🛡️', '${stats['campaigns']} Campaigns', _pink),
          const SizedBox(height: 6),
          _statRow('🔴', '${stats['liveNow']} Live Now', _green),
          const SizedBox(height: 6),
          _statRow('🌍', '${stats['countries']} Countries', _gold),
        ],
      ),
    );
  }

  Widget _statRow(String emoji, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailPanel(MapMarkerData m) {
    Color accentColor;
    String typeLabel;
    IconData typeIcon;

    switch (m.type) {
      case MarkerType.gym:
        accentColor = Colors.red;
        typeLabel = m.tierLabel;
        typeIcon = Icons.fitness_center;
      case MarkerType.event:
        accentColor = m.isLive ? _green : _cyan;
        typeLabel = m.isLive ? '🔴 LIVE' : m.tierLabel;
        typeIcon = Icons.event;
      case MarkerType.campaign:
        accentColor = m.campaignKind == CampaignKind.pinkShield ? _pink : _gold;
        typeLabel = m.tierLabel;
        typeIcon = Icons.favorite;
      case MarkerType.mentor:
        accentColor = m.mentorTier == MentorTier.pinkDiamond ? _pink : _gold;
        typeLabel = m.mentorTier == MentorTier.pinkDiamond
            ? '💎 PINK DIAMOND'
            : '💎 GOLD DIAMOND';
        typeIcon = Icons.person;
    }

    final displayCity = m.coordinate.displayLocation;
    final desc =
        m.description ??
        (m.disciplines.isNotEmpty ? m.disciplines.join(' · ') : '');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: accentColor.withAlpha(100), width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
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

          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withAlpha(100)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(typeIcon, color: accentColor, size: 14),
                const SizedBox(width: 6),
                Text(
                  typeLabel,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Name
          Text(
            m.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),

          // Location
          Row(
            children: [
              Text(
                m.coordinate.countryFlag ?? '',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayCity,
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description / disciplines
          if (desc.isNotEmpty)
            Text(
              desc,
              style: TextStyle(
                color: Colors.white.withAlpha(150),
                fontSize: 13,
                height: 1.4,
              ),
            ),

          // Rating for gyms
          if (m.type == MarkerType.gym && m.rating != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: _gold, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${m.rating!.toStringAsFixed(1)} (${m.reviewCount ?? 0} reviews)',
                  style: TextStyle(
                    color: Colors.white.withAlpha(170),
                    fontSize: 12,
                  ),
                ),
                if (m.isVerified) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.verified, color: _cyan, size: 16),
                  const SizedBox(width: 4),
                  const Text(
                    'VERIFIED',
                    style: TextStyle(
                      color: _cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ],

          // Event date
          if (m.type == MarkerType.event && m.eventDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: _cyan, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${m.eventDate!.day}/${m.eventDate!.month}/${m.eventDate!.year}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(170),
                    fontSize: 12,
                  ),
                ),
                if (m.isPPV) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.withAlpha(100)),
                    ),
                    child: const Text(
                      'PPV',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],

          const SizedBox(height: 16),

          // ── FREE TRIAL OFFER (gym + mentor) ──────────────────────
          if (m.type == MarkerType.gym || m.type == MarkerType.mentor) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _gold.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _gold.withAlpha(70)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.celebration, color: _gold, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      m.type == MarkerType.gym
                          ? 'FREE 1-WEEK TRAINING TRIAL at this gym for DFC members'
                          : 'FREE 1-WEEK MENTORSHIP TRIAL — first session no charge',
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            m.type == MarkerType.gym
                                ? '🥊 Trial request sent to ${m.name}!'
                                : '💎 Mentor trial request sent to ${m.name}!',
                          ),
                          backgroundColor: _gold,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _gold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'CLAIM',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(m.coordinate.lat, m.coordinate.lng),
                        15,
                      ),
                    );
                  },
                  icon: const Icon(Icons.zoom_in, size: 18),
                  label: const Text('ZOOM IN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _selectedMarker = null),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('CLOSE'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
