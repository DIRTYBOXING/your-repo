import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/design_tokens.dart';

class EarthMapView extends StatefulWidget {
  final double? height;
  final double initialZoom;

  const EarthMapView({super.key, this.height, this.initialZoom = 3.0});

  @override
  State<EarthMapView> createState() => _EarthMapViewState();
}

class _EarthMapViewState extends State<EarthMapView> {
  GoogleMapController? mapController;
  final LatLng _center = const LatLng(-37.8213, 144.9785);
  final Set<Marker> _markers = {};
  final Set<Marker> _eventMarkers = {};
  final Set<Marker> _pinkShieldGymMarkers = {};
  bool _mapError = false;
  bool _mapReady = false;
  Timer? _timeoutTimer;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _eventSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _pinkShieldGymSub;

  @override
  void initState() {
    super.initState();
    // On web, Google Maps JS API can silently fail (AppCheck, key issues).
    // If onMapCreated doesn't fire within 8 seconds, show fallback.
    if (kIsWeb) {
      _timeoutTimer = Timer(const Duration(seconds: 8), () {
        if (!_mapReady && mounted) {
          setState(() => _mapError = true);
          debugPrint('[EarthMapView] Map load timed out — showing fallback');
        }
      });
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _eventSub?.cancel();
    _pinkShieldGymSub?.cancel();
    super.dispose();
  }

  static const String _darkMapStyle = '''
    [
      {"elementType": "geometry", "stylers": [{"color": "#0A0A12"}]},
      {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
      {"elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
      {"elementType": "labels.text.stroke", "stylers": [{"color": "#212121"}]},
      {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#000000"}]}
    ]
  ''';

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  void _syncMarkers() {
    _markers
      ..clear()
      ..addAll(_eventMarkers)
      ..addAll(_pinkShieldGymMarkers);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapReady = true;
    _timeoutTimer?.cancel();
    mapController = controller;
    _fetchRealTimeEvents();
    _fetchPinkShieldGyms();
  }

  void _fetchRealTimeEvents() {
    _eventSub?.cancel();
    _eventSub = FirebaseFirestore.instance
        .collection('events')
        .orderBy('eventDate', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
          final newMarkers = <Marker>{};
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final lat = _asDouble(data['latitude'] ?? data['lat']);
            final lng = _asDouble(data['longitude'] ?? data['lng']);
            if (lat == 0 || lng == 0) continue;

            newMarkers.add(
              Marker(
                markerId: MarkerId('event_${doc.id}'),
                position: LatLng(lat, lng),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueCyan,
                ),
                infoWindow: InfoWindow(
                  title: (data['title'] ?? data['name'] ?? 'Live Event')
                      .toString(),
                  snippet:
                      'Buy Tickets \$${data['ticketPrice'] ?? 'N/A'} | ${data['broadcaster'] ?? 'Unknown'}',
                ),
              ),
            );
          }

          if (mounted) {
            setState(() {
              _eventMarkers
                ..clear()
                ..addAll(newMarkers);
              _syncMarkers();
            });
          }
        });
  }

  void _fetchPinkShieldGyms() {
    _pinkShieldGymSub?.cancel();
    _pinkShieldGymSub = FirebaseFirestore.instance
        .collection('gyms')
        .where('status', isEqualTo: 'active')
        .limit(200)
        .snapshots()
        .listen((snapshot) {
          final gymMarkers = <Marker>{};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final pinkShieldStatus = data['pinkShieldStatus'];
            if (pinkShieldStatus == null ||
                pinkShieldStatus.toString().trim().isEmpty) {
              continue;
            }

            final lat = _asDouble(data['latitude'] ?? data['lat']);
            final lng = _asDouble(data['longitude'] ?? data['lng']);
            if (lat == 0 || lng == 0) continue;

            gymMarkers.add(
              Marker(
                markerId: MarkerId('gym_${doc.id}'),
                position: LatLng(lat, lng),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRose,
                ),
                infoWindow: InfoWindow(
                  title: (data['name'] ?? 'Safe Gym').toString(),
                  snippet: 'Pink Shield Certified',
                ),
              ),
            );
          }

          if (mounted) {
            setState(() {
              _pinkShieldGymMarkers
                ..clear()
                ..addAll(gymMarkers);
              _syncMarkers();
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    if (_mapError) {
      return _buildFallback();
    }

    final map = Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgPrimary,
        border: Border.all(color: DesignTokens.neonCyan, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: widget.initialZoom,
        ),
        mapType: MapType.satellite,
        style: _darkMapStyle,
        markers: _markers,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
      ),
    );
    if (widget.height != null) {
      return SizedBox(height: widget.height, child: map);
    }
    return map;
  }

  Widget _buildFallback() {
    final fallback = Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgPrimary,
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A12), Color(0xFF0D1B2A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              color: DesignTokens.neonCyan.withValues(alpha: 0.55),
              size: 44,
            ),
            const SizedBox(height: 12),
            const Text(
              'Google Maps unavailable',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Check the web Maps key, allowed origin, or App Check trust.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.48),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
    if (widget.height != null) {
      return SizedBox(height: widget.height, child: fallback);
    }
    return fallback;
  }
}
