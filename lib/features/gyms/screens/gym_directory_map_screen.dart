import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class GymDirectoryMapScreen extends StatefulWidget {
  const GymDirectoryMapScreen({super.key});

  @override
  State<GymDirectoryMapScreen> createState() => _GymDirectoryMapScreenState();
}

class _GymDirectoryMapScreenState extends State<GymDirectoryMapScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  
  // Default camera position: Center of the world or specific city
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-37.8136, 144.9631), // Melbourne as example
    zoom: 12,
  );

  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Boxing', 'MMA', 'BJJ', 'Muay Thai'];

  // Hardcoded placeholders
  final List<Map<String, dynamic>> _allGyms = [
    {
      'id': '1',
      'name': 'Neon Striker Gym',
      'type': 'MMA',
      'lat': -37.8136,
      'lng': 144.9631,
      'address': '123 Fight Ave, Melbourne',
      'rating': 4.9,
    },
    {
      'id': '2',
      'name': 'Iron Boxing Club',
      'type': 'Boxing',
      'lat': -37.8050,
      'lng': 144.9500,
      'address': '45 Punch St, West Melbourne',
      'rating': 4.7,
    },
    {
      'id': '3',
      'name': 'Submission Studio',
      'type': 'BJJ',
      'lat': -37.8200,
      'lng': 144.9800,
      'address': '88 Roll Blvd, East Melbourne',
      'rating': 4.8,
    },
  ];

  Map<String, dynamic>? _selectedGym;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _updateMarkers();
  }

  void _updateMarkers() {
    final filtered = _selectedFilter == 'All'
        ? _allGyms
        : _allGyms.where((g) => g['type'] == _selectedFilter).toList();

    setState(() {
      _markers = filtered.map((g) {
        return Marker(
          markerId: MarkerId(g['id'] as String),
          position: LatLng(g['lat'] as double, g['lng'] as double),
          onTap: () {
            setState(() {
              _selectedGym = g;
            });
          },
          // TODO: Use custom neon bitmapped markers later
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getHueForType(g['type'] as String),
          ),
        );
      }).toSet();
    });
  }

  double _getHueForType(String type) {
    switch (type) {
      case 'Boxing': return BitmapDescriptor.hueRed;
      case 'MMA': return BitmapDescriptor.hueCyan;
      case 'BJJ': return BitmapDescriptor.hueViolet;
      default: return BitmapDescriptor.hueOrange;
    }
  }

  // Neon Dark Map Style
  final String _mapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#242f3e"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#242f3e"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#746855"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#38414e"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#212a37"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#17263c"}]
    }
  ]
  ''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020810),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            style: _mapStyle,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            onTap: (_) {
              if (_selectedGym != null) {
                setState(() {
                  _selectedGym = null;
                });
              }
            },
          ),

          // Top App Bar / Filters
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                bottom: 15,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF020810).withValues(alpha: 0.9),
                    const Color(0xFF020810).withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/');
                          }
                        },
                      ),
                      const Text(
                        'GLOBAL DIRECTORY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilter = filter;
                                _selectedGym = null;
                                _updateMarkers();
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? AppTheme.neonCyan.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected 
                                      ? AppTheme.neonCyan 
                                      : Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sheet
          if (_selectedGym != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildGymCard(_selectedGym!),
            ),
        ],
      ),
    );
  }

  Widget _buildGymCard(Map<String, dynamic> gym) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  gym['name'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.neonMagenta.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.neonMagenta),
                ),
                child: Text(
                  gym['type'] as String,
                  style: const TextStyle(
                    color: AppTheme.neonMagenta,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: AppTheme.neonCyan, size: 16),
              const SizedBox(width: 4),
              Text(
                '${gym['rating']}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Icon(Icons.location_on, color: Colors.white.withValues(alpha: 0.5), size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  gym['address'] as String,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Navigate to gym detail or schedule
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'VIEW GYM',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
