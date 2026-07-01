// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Pink Diamond Mentor Network Map — Interactive mentor discovery
class PinkDiamondMentorMapScreen extends StatefulWidget {
  const PinkDiamondMentorMapScreen({super.key});

  @override
  State<PinkDiamondMentorMapScreen> createState() =>
      _PinkDiamondMentorMapScreenState();
}

class _PinkDiamondMentorMapScreenState extends State<PinkDiamondMentorMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  int _selectedMentor = -1;
  // ignore: unused_field
  GoogleMapController? _mapController;

  static const _darkMapStyle =
      '[{"elementType":"geometry","stylers":[{"color":"#0a1628"}]},'
      '{"elementType":"geometry.stroke","stylers":[{"color":"#1a2a42"}]},'
      '{"elementType":"labels.text.fill","stylers":[{"color":"#8899aa"}]},'
      '{"elementType":"labels.text.stroke","stylers":[{"color":"#0a1628"}]},'
      '{"featureType":"road","elementType":"geometry","stylers":[{"color":"#121e33"}]},'
      '{"featureType":"water","elementType":"geometry","stylers":[{"color":"#060d18"}]},'
      '{"featureType":"poi","stylers":[{"visibility":"off"}]}]';

  static const _pink = Color(0xFFFF69B4);

  static const _mentors = [
    _Mentor(
      name: 'Coach Sarah Chen',
      city: 'Brisbane',
      country: '🇦🇺',
      specialty: 'Boxing / Conditioning',
      students: 48,
      rating: 4.9,
      tier: 'Pink Diamond',
      dx: 0.89,
      dy: 0.70,
      lat: -27.47,
      lng: 153.03,
      isOnline: true,
    ),
    _Mentor(
      name: 'Sensei Tomoko Arai',
      city: 'Auckland',
      country: '🇳🇿',
      specialty: 'Karate / Self-Defense',
      students: 62,
      rating: 4.8,
      tier: 'Pink Diamond',
      dx: 0.91,
      dy: 0.76,
      lat: -36.86,
      lng: 174.76,
      isOnline: true,
    ),
    _Mentor(
      name: 'Maria Souza',
      city: 'São Paulo',
      country: '🇧🇷',
      specialty: 'BJJ / Yoga',
      students: 85,
      rating: 4.9,
      tier: 'Pink Diamond',
      dx: 0.28,
      dy: 0.62,
      lat: -23.55,
      lng: -46.63,
      isOnline: false,
    ),
    _Mentor(
      name: 'Coach Priya Singh',
      city: 'London',
      country: '🇬🇧',
      specialty: 'MMA / S&C',
      students: 34,
      rating: 4.7,
      tier: 'Gold Diamond',
      dx: 0.47,
      dy: 0.22,
      lat: 51.51,
      lng: -0.13,
      isOnline: true,
    ),
    _Mentor(
      name: 'Kru Nong',
      city: 'Phuket',
      country: '🇹🇭',
      specialty: 'Muay Thai',
      students: 120,
      rating: 4.9,
      tier: 'Pink Diamond',
      dx: 0.73,
      dy: 0.50,
      lat: 7.88,
      lng: 98.39,
      isOnline: false,
    ),
    _Mentor(
      name: 'Jessica Watts',
      city: 'Wellington',
      country: '🇳🇿',
      specialty: 'Kickboxing / Wellness',
      students: 28,
      rating: 4.6,
      tier: 'Gold Diamond',
      dx: 0.92,
      dy: 0.78,
      lat: -41.29,
      lng: 174.78,
      isOnline: true,
    ),
    _Mentor(
      name: 'Coach Mia Torres',
      city: 'Los Angeles',
      country: '🇺🇸',
      specialty: 'Boxing / Nutrition',
      students: 73,
      rating: 4.8,
      tier: 'Pink Diamond',
      dx: 0.11,
      dy: 0.37,
      lat: 34.05,
      lng: -118.24,
      isOnline: true,
    ),
    _Mentor(
      name: 'Dra. Andrea Castillo',
      city: 'Gold Coast',
      country: '🇦🇺',
      specialty: 'Sports Psychology',
      students: 41,
      rating: 4.9,
      tier: 'Pink Diamond',
      dx: 0.89,
      dy: 0.71,
      lat: -28.00,
      lng: 153.43,
      isOnline: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: const Text(
          'PINK DIAMOND MENTOR MAP',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, _) => Icon(
                Icons.diamond,
                color: _pink.withValues(alpha: 0.5 + _pulseCtrl.value * 0.5),
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF0D1120),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('MENTORS', '${_mentors.length}', _pink),
                _stat(
                  'ONLINE',
                  '${_mentors.where((m) => m.isOnline).length}',
                  const Color(0xFF00E676),
                ),
                _stat('COUNTRIES', '6', const Color(0xFF00E5FF)),
                _stat(
                  'STUDENTS',
                  '${_mentors.fold<int>(0, (s, m) => s + m.students)}',
                  const Color(0xFFFFD600),
                ),
              ],
            ),
          ),
          // Map
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(5, 80),
                zoom: 2.0,
              ),
              style: _darkMapStyle,
              onMapCreated: (c) => _mapController = c,
              markers: _mentors.asMap().entries.map((e) {
                final m = e.value;
                final i = e.key;
                final color = m.tier == 'Pink Diamond'
                    ? BitmapDescriptor.hueRose
                    : BitmapDescriptor.hueYellow;
                return Marker(
                  markerId: MarkerId(m.name),
                  position: LatLng(m.lat, m.lng),
                  icon: BitmapDescriptor.defaultMarkerWithHue(color),
                  onTap: () => setState(
                    () => _selectedMentor = _selectedMentor == i ? -1 : i,
                  ),
                  infoWindow: InfoWindow(
                    title: '${m.name} ${m.country}',
                    snippet: '${m.specialty} \u2022 \u2B50 ${m.rating}',
                  ),
                );
              }).toSet(),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
          // Detail panel
          if (_selectedMentor >= 0)
            _buildMentorPanel(_mentors[_selectedMentor]),
          // Mentor list
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _mentors.length,
              itemBuilder: (_, i) {
                final m = _mentors[i];
                return GestureDetector(
                  onTap: () => setState(() => _selectedMentor = i),
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1120),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _pink.withValues(
                          alpha: i == _selectedMentor ? 0.5 : 0.1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (m.isOnline)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00E676),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if (m.isOnline) const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                m.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.specialty,
                          style: TextStyle(
                            color: _pink.withValues(alpha: 0.6),
                            fontSize: 9,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${m.city} ${m.country}',
                          style: const TextStyle(
                            color: Colors.white30,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorMarker(_Mentor m, int index) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final x = constraints.maxWidth * m.dx;
        final y = constraints.maxHeight * m.dy;
        final isSelected = index == _selectedMentor;
        final color = m.tier == 'Pink Diamond'
            ? _pink
            : const Color(0xFFFFD600);
        return Positioned(
          left: x - (isSelected ? 12 : 8),
          top: y - (isSelected ? 12 : 8),
          child: GestureDetector(
            onTap: () => setState(
              () => _selectedMentor = _selectedMentor == index ? -1 : index,
            ),
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, _) {
                final glow = m.isOnline ? _pulseCtrl.value * 0.3 : 0.0;
                return Container(
                  width: isSelected ? 24 : 16,
                  height: isSelected ? 24 : 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.5 + glow),
                    border: Border.all(color: color, width: isSelected ? 2 : 1),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3 + glow),
                        blurRadius: isSelected ? 12 : 6,
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.diamond, size: 12, color: Colors.white)
                      : null,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMentorPanel(_Mentor m) {
    final color = m.tier == 'Pink Diamond' ? _pink : const Color(0xFFFFD600);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1120),
        border: Border(top: BorderSide(color: color.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.diamond, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        m.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (m.isOnline)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF00E676,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ONLINE',
                          style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${m.specialty} · ${m.city} ${m.country}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '⭐ ${m.rating}',
                      style: const TextStyle(color: Colors.amber, fontSize: 10),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '👥 ${m.students} students',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        m.tier.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // FREE 1-WEEK TRIAL CTA
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '💎 Free trial request sent to ${m.name}!',
                        ),
                        backgroundColor: const Color(0xFFFFD700),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.celebration,
                          color: Color(0xFFFFD700),
                          size: 13,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'CLAIM FREE 1-WEEK MENTORSHIP TRIAL',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
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

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.5),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _Mentor {
  final String name, city, country, specialty, tier;
  final int students;
  final double rating, dx, dy, lat, lng;
  final bool isOnline;
  const _Mentor({
    required this.name,
    required this.city,
    required this.country,
    required this.specialty,
    required this.students,
    required this.rating,
    required this.tier,
    required this.dx,
    required this.dy,
    required this.lat,
    required this.lng,
    required this.isOnline,
  });
}
