import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/theme/design_tokens.dart';

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

  static const String _darkMapStyle = '''
    [
      {"elementType": "geometry", "stylers": [{"color": "#0A0A12"}]},
      {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
      {"elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
      {"elementType": "labels.text.stroke", "stylers": [{"color": "#212121"}]},
      {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#000000"}]}
    ]
  ''';

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _fetchRealTimeEvents();
  }

  void _fetchRealTimeEvents() {
    FirebaseFirestore.instance
        .collection('events')
        .orderBy('eventDate', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
          final newMarkers = <Marker>{};
          for (var doc in snapshot.docs) {
            final data = doc.data();
            if (data['latitude'] != null && data['longitude'] != null) {
              final marker = Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(data['latitude'], data['longitude']),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueCyan,
                ),
                infoWindow: InfoWindow(
                  title: data['title'] ?? 'Live Event',
                  snippet:
                      'Buy Tickets \$${data['ticketPrice']} | ${data['broadcaster']}',
                ),
              );
              newMarkers.add(marker);
            }
          }
          if (mounted) {
            setState(() {
              _markers.clear();
              _markers.addAll(newMarkers);
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
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
}
