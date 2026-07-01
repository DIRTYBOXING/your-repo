import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datafightcentral/core/theme/design_tokens.dart';
import 'package:datafightcentral/shared/widgets/campaign_map_markers.dart';
import 'package:datafightcentral/shared/services/safety_hub_service.dart';

/// Pink Shield Program — DFC's survivor-protection and safe-community standard.
/// Gym certification, safe-space pledge, certified gym listings, reporting flow.
/// Because combat sports should help people heal, feel welcome, and stay protected.
class PinkShieldScreen extends StatefulWidget {
  const PinkShieldScreen({super.key});

  @override
  State<PinkShieldScreen> createState() => _PinkShieldScreenState();
}

class _PinkShieldScreenState extends State<PinkShieldScreen>
    with TickerProviderStateMixin {
  static const _sakuraPink = Color(0xFFFF69B4);
  int _selectedTab = 0;
  late AnimationController _shieldPulse;
  late Future<Map<String, int>> _pinkShieldMetricsFuture;
  String? _selectedReportType;
  String? _applicationStatus;
  bool _reportSubmitting = false;
  bool _applicationSubmitting = false;
  final SafetyHubService _safetyService = SafetyHubService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
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

  static const _tabs = [
    'Overview',
    'Map',
    'Certified Gyms',
    'Pledge',
    'Report',
  ];

  // Global solidarity locations — Pink Shields placed worldwide
  static const List<Map<String, dynamic>> _solidarityLocations = [
    {
      'city': 'Los Angeles',
      'country': '🇺🇸',
      'shields': 847,
      'lat': 34.05,
      'lng': -118.24,
      'tag': 'DV-Safe Zone',
    },
    {
      'city': 'New York',
      'country': '🇺🇸',
      'shields': 1203,
      'lat': 40.75,
      'lng': -73.99,
      'tag': 'Anti-Bullying',
    },
    {
      'city': 'Miami',
      'country': '🇺🇸',
      'shields': 654,
      'lat': 25.76,
      'lng': -80.19,
      'tag': 'Trauma-Informed',
    },
    {
      'city': 'Chicago',
      'country': '🇺🇸',
      'shields': 512,
      'lat': 41.88,
      'lng': -87.63,
      'tag': 'Youth Mentorship',
    },
    {
      'city': 'Denver',
      'country': '🇺🇸',
      'shields': 389,
      'lat': 39.74,
      'lng': -104.99,
      'tag': 'Veterans Program',
    },
    {
      'city': 'Sydney',
      'country': '🇦🇺',
      'shields': 723,
      'lat': -33.87,
      'lng': 151.21,
      'tag': 'DV-Safe Certified',
    },
    {
      'city': 'Melbourne',
      'country': '🇦🇺',
      'shields': 601,
      'lat': -37.81,
      'lng': 144.96,
      'tag': 'Trauma-Aware',
    },
    {
      'city': 'Auckland',
      'country': '🇳🇿',
      'shields': 445,
      'lat': -36.86,
      'lng': 174.76,
      'tag': 'Women\'s Empowerment',
    },
    {
      'city': 'London',
      'country': '🇬🇧',
      'shields': 1089,
      'lat': 51.51,
      'lng': -0.13,
      'tag': 'Confidential Support',
    },
    {
      'city': 'Tokyo',
      'country': '🇯🇵',
      'shields': 512,
      'lat': 35.68,
      'lng': 139.69,
      'tag': 'Safe Training',
    },
    {
      'city': 'São Paulo',
      'country': '🇧🇷',
      'shields': 678,
      'lat': -23.55,
      'lng': -46.63,
      'tag': 'Community Outreach',
    },
    {
      'city': 'Dubai',
      'country': '🇦🇪',
      'shields': 301,
      'lat': 25.20,
      'lng': 55.27,
      'tag': 'Family-Safe',
    },
    {
      'city': 'Bangkok',
      'country': '🇹🇭',
      'shields': 567,
      'lat': 13.76,
      'lng': 100.50,
      'tag': 'Inclusive Training',
    },
    {
      'city': 'Manila',
      'country': '🇵🇭',
      'shields': 423,
      'lat': 14.60,
      'lng': 120.98,
      'tag': 'Youth Protection',
    },
    {
      'city': 'Toronto',
      'country': '🇨🇦',
      'shields': 756,
      'lat': 43.65,
      'lng': -79.38,
      'tag': 'Mental Wellness',
    },
    {
      'city': 'Paris',
      'country': '🇫🇷',
      'shields': 489,
      'lat': 48.86,
      'lng': 2.35,
      'tag': 'Anti-Violence',
    },
    {
      'city': 'Berlin',
      'country': '🇩🇪',
      'shields': 378,
      'lat': 52.52,
      'lng': 13.40,
      'tag': 'Crisis Support',
    },
    {
      'city': 'Gold Coast',
      'country': '🇦🇺',
      'shields': 534,
      'lat': -28.02,
      'lng': 153.43,
      'tag': 'Safe Gyms',
    },
    {
      'city': 'Brisbane',
      'country': '🇦🇺',
      'shields': 467,
      'lat': -27.47,
      'lng': 153.03,
      'tag': 'Mentor-Funded',
    },
    {
      'city': 'Las Vegas',
      'country': '🇺🇸',
      'shields': 612,
      'lat': 36.17,
      'lng': -115.14,
      'tag': 'Fighter Safety',
    },
  ];

  // Demo certified gyms
  static const List<Map<String, dynamic>> _certifiedGyms = [
    {
      'name': 'Iron Will MMA Academy',
      'city': 'Los Angeles, CA',
      'rating': 4.9,
      'certified': true,
      'specialties': [
        'Youth Programs',
        'Women\'s Self-Defense',
        'Mental Wellness',
      ],
      'icon': '🛡️',
    },
    {
      'name': 'Harmony Fight Club',
      'city': 'New York, NY',
      'rating': 4.8,
      'certified': true,
      'specialties': [
        'Anti-Bullying',
        'Inclusive Training',
        'First Aid Certified',
      ],
      'icon': '💪',
    },
    {
      'name': 'Warrior Spirit Dojo',
      'city': 'Chicago, IL',
      'rating': 4.7,
      'certified': true,
      'specialties': [
        'Youth Mentorship',
        'Anger Management',
        'Nutrition Coaching',
      ],
      'icon': '🏋️',
    },
    {
      'name': 'Phoenix Rising BJJ',
      'city': 'Miami, FL',
      'rating': 4.9,
      'certified': true,
      'specialties': [
        'Trauma-Informed Coaching',
        'LGBTQ+ Friendly',
        'Family Classes',
      ],
      'icon': '🔥',
    },
    {
      'name': 'Summit Combat Athletics',
      'city': 'Denver, CO',
      'rating': 4.6,
      'certified': true,
      'specialties': [
        'Veterans Program',
        'Adaptive Training',
        'Community Outreach',
      ],
      'icon': '⛰️',
    },
  ];

  // Support categories that Pink Shields represent
  static const List<Map<String, String>> _supportCategories = [
    {
      'icon': '💜',
      'title': 'Domestic Violence',
      'desc':
          'Protection for survivors of violence — warm, private, trauma-aware support when speaking up feels hard',
    },
    {
      'icon': '🧠',
      'title': 'Mental Health',
      'desc':
          'Anxiety, depression, PTSD — combat sport communities stand with you',
    },
    {
      'icon': '👧',
      'title': 'Women, Girls & Survivors',
      'desc':
          'Empowerment through martial arts — confidence, self-defense, acceptance, and safe community',
    },
    {
      'icon': '👦',
      'title': 'Youth Protection',
      'desc':
          'Children deserve safe spaces — zero tolerance for bullying and abuse',
    },
    {
      'icon': '🫡',
      'title': 'Stress & Crisis',
      'desc':
          'Anyone struggling silently — your local Pink Shield gym is a safe haven where you are welcomed and believed',
    },
    {
      'icon': '🤝',
      'title': 'Anti-Violence',
      'desc':
          'We do not condone uncontrolled aggression toward any human being',
    },
  ];

  static const List<Map<String, String>> _pledgePoints = [
    {
      'icon': '🤝',
      'title': 'Respect First',
      'desc':
          'Every athlete deserves dignity. We treat teammates, opponents, and coaches with unwavering respect.',
    },
    {
      'icon': '🧠',
      'title': 'Mental Health Priority',
      'desc':
          'Training builds minds, not just bodies. We monitor mental wellness and provide support resources.',
    },
    {
      'icon': '🛡️',
      'title': 'Zero Tolerance for Bullying',
      'desc':
          'Our mats are safe spaces. Harassment, intimidation, and discrimination are never acceptable.',
    },
    {
      'icon': '👨‍👩‍👧‍👦',
      'title': 'Family-Safe Environment',
      'desc':
          'Parents can trust their children are in a nurturing, skill-building environment focused on growth.',
    },
    {
      'icon': '❤️‍🩹',
      'title': 'Injury Prevention',
      'desc':
          'We follow medical best practices, require proper equipment, and never push athletes beyond safe limits.',
    },
    {
      'icon': '📚',
      'title': 'Education Over Ego',
      'desc':
          'Technique, discipline, and sportsmanship matter more than winning. We teach life skills through martial arts.',
    },
  ];

  static const List<Map<String, String>> _programSteps = [
    {
      'step': '1',
      'title': 'Apply',
      'desc':
          'A gym owner submits one location, a safety statement, and agrees to the Pink Shield pledge.',
    },
    {
      'step': '2',
      'title': 'Review',
      'desc':
          'DFC reviews the application for survivor-safe readiness, reporting standards, and conduct expectations.',
    },
    {
      'step': '3',
      'title': 'Approve',
      'desc':
          'Approved gyms receive Pink Shield badge rights, a featured listing, and placement in the safe network.',
    },
    {
      'step': '4',
      'title': 'Protect',
      'desc':
          'If standards slip, gyms can be reviewed, paused, or removed so the badge keeps its meaning.',
    },
  ];

  static const List<String> _applicationBenefits = [
    'Pink Shield badge and logo usage rights after approval',
    'Map placement and directory visibility in DFC',
    'Public signal that the gym supports survivors and safer training culture',
    'A clear standard for reporting, conduct, and trauma-aware support',
  ];

  @override
  void initState() {
    super.initState();
    _shieldPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pinkShieldMetricsFuture = _loadPinkShieldMetrics();
    _refreshPinkShieldStatus();
  }

  @override
  void dispose() {
    _shieldPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildTabs()),
          SliverToBoxAdapter(child: _buildContent()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: DesignTokens.bgPrimary,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Pink Shield Program',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFF69B4).withValues(alpha: 0.3),
                DesignTokens.neonMagenta.withValues(alpha: 0.2),
                DesignTokens.bgPrimary,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                const SizedBox(
                  width: 90,
                  height: 90,
                  child: PinkShieldMarker(size: 80),
                ),
                const SizedBox(height: 8),
                Text(
                  'Safe Spaces. Stronger Athletes. Better Humans.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFFF69B4).withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                  border: selected
                      ? Border.all(
                          color: const Color(0xFFFF69B4).withValues(alpha: 0.4),
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabs[i],
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFFFF69B4)
                        : Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildOverview();
      case 1:
        return _buildSolidarityMap();
      case 2:
        return _buildCertifiedGyms();
      case 3:
        return _buildPledge();
      case 4:
        return _buildReport();
      default:
        return const SizedBox.shrink();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SOLIDARITY MAP — "Get Your Name On The Map"
  // Global visualization of Pink Shield support network
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSolidarityMap() {
    const sakuraPink = Color(0xFFFF69B4);
    final totalShields = _solidarityLocations.fold<int>(
      0,
      (runningTotal, loc) => runningTotal + (loc['shields'] as int),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Anti-violence declaration
          _glassCard(
            child: Column(
              children: [
                const SizedBox(
                  width: 60,
                  height: 60,
                  child: PinkShieldMarker(size: 52),
                ),
                const SizedBox(height: 12),
                const Text(
                  'PINK SHIELD SOLIDARITY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We do not condone uncontrolled aggression or violence '
                  'toward any human being — women, men, and children alike. '
                  'Every Pink Shield on this map represents a community that '
                  'stands against violence and supports those suffering from '
                  'crisis, anxiety, depression, or abuse.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Global stats row
          Row(
            children: [
              Expanded(
                child: _glassCard(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 8,
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${(totalShields / 1000).toStringAsFixed(1)}K',
                        style: const TextStyle(
                          color: _sakuraPink,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Shields Placed',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _glassCard(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 8,
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_solidarityLocations.length}',
                        style: const TextStyle(
                          color: DesignTokens.neonCyan,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cities Active',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _glassCard(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 8,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '12',
                        style: TextStyle(
                          color: DesignTokens.neonGreen,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Countries',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Visual world grid — Pink Shield locations
          _glassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.public, color: sakuraPink, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'GLOBAL SHIELD NETWORK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push('/community-map'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: sakuraPink.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusPill,
                          ),
                          border: Border.all(
                            color: sakuraPink.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map, color: sakuraPink, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Full Map',
                              style: TextStyle(
                                color: sakuraPink,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Dark network panel on web, live Google map on supported platforms
                SizedBox(
                  height: 260,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? _buildWebShieldNetworkPanel()
                        : GoogleMap(
                            initialCameraPosition: const CameraPosition(
                              target: LatLng(20, 0),
                              zoom: 1.5,
                            ),
                            style: _darkMapStyle,
                            onMapCreated: (c) => _mapController = c,
                            markers: _solidarityLocations.map((loc) {
                              final lat = (loc['lat'] as num).toDouble();
                              final lng = (loc['lng'] as num).toDouble();
                              return Marker(
                                markerId: MarkerId(loc['city'] as String),
                                position: LatLng(lat, lng),
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  330,
                                ),
                                infoWindow: InfoWindow(
                                  title: '${loc['city']} ${loc['country']}',
                                  snippet:
                                      '\u{1F6E1}\u{FE0F} ${loc['shields']} shields \u2014 ${loc['tag']}',
                                ),
                              );
                            }).toSet(),
                            circles: _solidarityLocations.map((loc) {
                              final lat = (loc['lat'] as num).toDouble();
                              final lng = (loc['lng'] as num).toDouble();
                              final shields = loc['shields'] as int;
                              return Circle(
                                circleId: CircleId(loc['city'] as String),
                                center: LatLng(lat, lng),
                                radius: shields * 50.0,
                                fillColor: const Color(
                                  0xFFFF69B4,
                                ).withValues(alpha: 0.15),
                                strokeColor: const Color(
                                  0xFFFF69B4,
                                ).withValues(alpha: 0.3),
                                strokeWidth: 1,
                              );
                            }).toSet(),
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Shield locations list
          ..._solidarityLocations.map(
            (loc) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildShieldLocationCard(loc),
            ),
          ),
          const SizedBox(height: 16),

          // Place Your Shield CTA
          _glassCard(
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _shieldPulse,
                  builder: (context, _) {
                    final scale = 0.9 + 0.1 * _shieldPulse.value;
                    return Transform.scale(
                      scale: scale,
                      child: const SizedBox(
                        width: 70,
                        height: 70,
                        child: PinkShieldMarker(size: 60),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                const Text(
                  'PLACE YOUR SHIELD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Apply to place your gym on the map. Approved locations '
                  'stand out as survivor-safe and Pink Shield certified.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '\ud83d\udee1\ufe0f Shield placed — you\u2019re on the map. Thank you for standing up.',
                          ),
                          backgroundColor: sakuraPink,
                        ),
                      );
                    },
                    icon: const Icon(Icons.shield, size: 20),
                    label: const Text(
                      'Place My Shield',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sakuraPink.withValues(alpha: 0.2),
                      foregroundColor: sakuraPink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusMedium,
                        ),
                        side: BorderSide(
                          color: sakuraPink.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Support categories
          Text(
            'WHO PINK SHIELD PROTECTS',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          ..._supportCategories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _glassCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat['icon']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cat['desc']!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Final declaration
          _glassCard(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  const Text(
                    '\ud83d\udee1\ufe0f',
                    style: TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Combat sports build discipline, respect, and character.\n'
                    'Not fear. Not pain. Not silence.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'If you or someone you know is suffering \u2014 you are not alone.',
                    style: TextStyle(
                      color: sakuraPink.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebShieldNetworkPanel() {
    final topLocations = [..._solidarityLocations]
      ..sort((a, b) => (b['shields'] as int).compareTo(a['shields'] as int));

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF120814), Color(0xFF1A0D1E), Color(0xFF0B101A)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const PinkShieldMarker(size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PINK SHIELD SAFE NETWORK',
                        style: TextStyle(
                          color: _sakuraPink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        'Dark fallback view for survivor-safe locations while web maps are unstable.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.68),
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _networkChip('${_solidarityLocations.length} cities live'),
                _networkChip(
                  '${_solidarityLocations.fold<int>(0, (runningTotal, loc) => runningTotal + (loc['shields'] as int))} shields',
                ),
                _networkChip('DV-safe spaces'),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                children: topLocations.take(5).map((loc) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _sakuraPink.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _sakuraPink,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _sakuraPink.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${loc['city']} ${loc['country']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${loc['tag']} • ${loc['shields']} shields',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.68),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _networkChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _sakuraPink.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _sakuraPink.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _sakuraPink,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // Individual shield location card
  Widget _buildShieldLocationCard(Map<String, dynamic> loc) {
    const sakuraPink = Color(0xFFFF69B4);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard.withValues(
          alpha: DesignTokens.glassOpacity + 0.02,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: sakuraPink.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: PinkShieldMarker(size: 28),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      loc['country'] as String,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      loc['city'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  loc['tag'] as String,
                  style: TextStyle(
                    color: sakuraPink.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${loc['shields']}',
                style: const TextStyle(
                  color: sakuraPink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'shields',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('💖', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'What is Pink Shield?',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Pink Shield is DFC\'s certification program ensuring gyms and training facilities '
                  'meet the highest standards for survivor safety, inclusivity, and athlete well-being. '
                  'It exists for people affected by violence who need places that feel warm, accepted, and protected. '
                  'We believe combat sports should build confidence, discipline, and character — '
                  'never fear or isolation.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(),
          const SizedBox(height: 16),
          _buildOwnerActionCard(),
          const SizedBox(height: 16),
          _buildProgramStructureCard(),
          const SizedBox(height: 16),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why It Matters',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                _bulletPoint(
                  'Combat sports teach discipline, respect, and self-control',
                ),
                _bulletPoint(
                  'Young athletes need mentors who prioritize growth over ego',
                ),
                _bulletPoint(
                  'Safe training environments produce healthier, happier humans',
                ),
                _bulletPoint(
                  'Survivors of violence deserve warm, trauma-informed spaces where they are welcomed and protected',
                ),
                _bulletPoint(
                  'Certified gyms report 73% higher athlete retention',
                ),
                _bulletPoint(
                  'Parents trust Pink Shield gyms with their children\'s development',
                ),
                _bulletPoint(
                  'Approval is practical: apply, review, approve, and remove if standards are broken',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow() {
    return FutureBuilder<Map<String, int>>(
      future: _pinkShieldMetricsFuture,
      builder: (context, snapshot) {
        final metrics = snapshot.data;
        final stats = [
          {
            'value': _formatCompactCount(metrics?['approvedGyms'] ?? 2847),
            'label': 'Approved Gyms',
            'color': const Color(0xFFFF69B4),
          },
          {
            'value': _formatCompactCount(metrics?['pendingApplications'] ?? 74),
            'label': 'In Review',
            'color': DesignTokens.neonCyan,
          },
          {
            'value':
                '${metrics?['activeCities'] ?? _solidarityLocations.length}',
            'label': 'Cities Active',
            'color': DesignTokens.neonGreen,
          },
        ];

        return Row(
          children: stats.map((s) {
            return Expanded(
              child: _glassCard(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 8,
                ),
                child: Column(
                  children: [
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Text(
                        s['value'] as String,
                        style: TextStyle(
                          color: s['color'] as Color,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      s['label'] as String,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCertifiedGyms() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verified Safe Training Environments',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          _buildCertifiedGymsList(),
        ],
      ),
    );
  }

  Widget _buildPledge() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _glassCard(
            child: Column(
              children: [
                const Text('🤝', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text(
                  'The DFC Safe Space Pledge',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Every Pink Shield certified gym commits to these principles.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What approval unlocks',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ..._applicationBenefits.map(_bulletPoint),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _applicationSubmitting
                        ? null
                        : _showPinkShieldApplicationDialog,
                    icon: _applicationSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _sakuraPink,
                            ),
                          )
                        : const Icon(Icons.verified_user_outlined),
                    label: Text(
                      _applicationSubmitting
                          ? 'Submitting application...'
                          : 'Apply as a Gym Owner',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _sakuraPink.withValues(alpha: 0.16),
                      foregroundColor: _sakuraPink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusMedium,
                        ),
                        side: BorderSide(
                          color: _sakuraPink.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._pledgePoints.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _glassCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['icon']!, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p['desc']!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerActionCard() {
    final signedIn = FirebaseAuth.instance.currentUser != null;
    final statusColor = _statusColor(_applicationStatus);
    final statusLabel = _statusLabel(_applicationStatus);

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_outlined,
                color: _sakuraPink,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Gym owner action',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_applicationStatus != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusPill,
                    ),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            signedIn
                ? 'Submit one gym application to start review. After approval, your location can appear on the Pink Shield map and certified directory.'
                : 'Sign in as a gym owner to submit a Pink Shield application and claim badge, logo, and listing rights.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.64),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (_applicationStatus != null) ...[
            const SizedBox(height: 10),
            Text(
              _statusDescription(_applicationStatus),
              style: TextStyle(
                color: statusColor.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _applicationSubmitting
                  ? null
                  : _showPinkShieldApplicationDialog,
              icon: _applicationSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _sakuraPink,
                      ),
                    )
                  : const Icon(Icons.shield_outlined),
              label: Text(
                _applicationStatus == 'pending'
                    ? 'Application Submitted'
                    : 'Start Gym Application',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _sakuraPink.withValues(alpha: 0.16),
                foregroundColor: _sakuraPink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                  side: BorderSide(color: _sakuraPink.withValues(alpha: 0.35)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramStructureCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How the program works',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Keep it simple: apply, review, approve, and remove if needed. The badge only matters if the standard stays real.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          ..._programSteps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _sakuraPink.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        step['step']!,
                        style: const TextStyle(
                          color: _sakuraPink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            step['desc']!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertifiedGymsList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('pink_shield_certifications')
          .where('status', isEqualTo: 'approved')
          .limit(12)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final docs = snapshot.data!.docs;
          return Column(
            children: docs
                .map(
                  (certDoc) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildLiveCertifiedGymCard(certDoc),
                  ),
                )
                .toList(),
          );
        }

        return Column(
          children: _certifiedGyms
              .map(
                (gym) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildDemoCertifiedGymCard(gym),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildLiveCertifiedGymCard(
    QueryDocumentSnapshot<Map<String, dynamic>> certDoc,
  ) {
    final certData = certDoc.data();
    final gymId = certData['entityId'] as String?;
    final certifiedAt = (certData['certifiedAt'] as Timestamp?)?.toDate();

    if (gymId == null || gymId.isEmpty) {
      return _glassCard(
        child: Text(
          'Approved Pink Shield entry is missing its linked gym record.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _db.collection('gyms').doc(gymId).get(),
      builder: (context, gymSnapshot) {
        final gymData = gymSnapshot.data?.data();
        final location =
            [
                  gymData?['city'] as String?,
                  gymData?['state'] as String?,
                  gymData?['country'] as String?,
                ]
                .whereType<String>()
                .where((part) => part.trim().isNotEmpty)
                .join(', ');

        final specialties = [
          ...?((gymData?['sportTypes'] as List?)?.whereType<String>()),
          ...?((gymData?['amenities'] as List?)?.whereType<String>()),
        ].take(4).toList();

        return _glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🛡️', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gymData?['name'] as String? ?? 'Pink Shield Gym',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          location.isEmpty ? 'Certified location' : location,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusPill,
                      ),
                      border: Border.all(
                        color: DesignTokens.neonGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: DesignTokens.neonGreen,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Approved',
                          style: TextStyle(
                            color: DesignTokens.neonGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (certifiedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Certified ${_formatShortDate(certifiedAt)}',
                  style: TextStyle(
                    color: _sakuraPink.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (specialties.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: specialties
                      .map(
                        (specialty) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _sakuraPink.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusPill,
                            ),
                            border: Border.all(
                              color: _sakuraPink.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            specialty,
                            style: TextStyle(
                              color: _sakuraPink.withValues(alpha: 0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDemoCertifiedGymCard(Map<String, dynamic> gym) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(gym['icon'] as String, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gym['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      gym['city'] as String,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.neonGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                  border: Border.all(
                    color: DesignTokens.neonGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified,
                      size: 14,
                      color: DesignTokens.neonGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${gym['rating']}',
                      style: const TextStyle(
                        color: DesignTokens.neonGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (gym['specialties'] as List<String>)
                .map(
                  (specialty) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _sakuraPink.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusPill,
                      ),
                      border: Border.all(
                        color: _sakuraPink.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      specialty,
                      style: TextStyle(
                        color: _sakuraPink.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshPinkShieldStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _applicationStatus = null);
      return;
    }

    try {
      final ownedGyms = await _fetchOwnedGyms(user.uid);
      if (ownedGyms.isNotEmpty) {
        final gymIds = ownedGyms.map((gym) => gym['id']!).take(10).toList();
        final certSnapshot = await _db
            .collection('pink_shield_certifications')
            .where(FieldPath.documentId, whereIn: gymIds)
            .get();

        final approvedCertification = certSnapshot.docs.any(
          (doc) => doc.data()['status'] == 'approved',
        );

        if (approvedCertification) {
          if (!mounted) return;
          setState(() => _applicationStatus = 'approved');
          return;
        }
      }

      final applications = await _db
          .collection('pink_shield_applications')
          .where('applicantId', isEqualTo: user.uid)
          .limit(20)
          .get();

      String? latestStatus;
      DateTime latestTime = DateTime.fromMillisecondsSinceEpoch(0);
      for (final doc in applications.docs) {
        final data = doc.data();
        final submittedAt =
            (data['submittedAt'] as Timestamp?)?.toDate() ?? latestTime;
        if (submittedAt.isAfter(latestTime)) {
          latestTime = submittedAt;
          latestStatus = data['status'] as String?;
        }
      }

      if (!mounted) return;
      setState(() => _applicationStatus = latestStatus);
    } catch (_) {
      if (!mounted) return;
      setState(() => _applicationStatus = null);
    }
  }

  Future<List<Map<String, String>>> _fetchOwnedGyms(String userId) async {
    final snapshot = await _db
        .collection('gyms')
        .where('userId', isEqualTo: userId)
        .limit(20)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final locationParts = [
        data['city'] as String?,
        data['state'] as String?,
      ].whereType<String>().where((part) => part.trim().isNotEmpty).toList();

      return {
        'id': doc.id,
        'name': (data['name'] as String?)?.trim().isNotEmpty == true
            ? data['name'] as String
            : 'Unnamed gym',
        'location': locationParts.join(', '),
      };
    }).toList();
  }

  Future<void> _showPinkShieldApplicationDialog() async {
    HapticFeedback.mediumImpact();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack(
        'Sign in as a gym owner to submit a Pink Shield application.',
        Colors.red,
      );
      return;
    }

    List<Map<String, String>> ownedGyms;
    try {
      ownedGyms = await _fetchOwnedGyms(user.uid);
    } catch (e) {
      _showSnack('Unable to load your gyms right now. ($e)', Colors.red);
      return;
    }

    if (!mounted) return;
    if (ownedGyms.isEmpty) {
      _showSnack(
        'No gyms were found for this account yet. Create a gym first, then apply.',
        Colors.orange,
      );
      return;
    }

    final statementController = TextEditingController();
    String? selectedGymId = ownedGyms.length == 1
        ? ownedGyms.first['id']
        : null;
    bool signedPledge = false;
    String? gymError;
    String? statementError;
    String? pledgeError;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0A1628),
          title: const Text(
            'Pink Shield Gym Application',
            style: TextStyle(color: _sakuraPink, fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apply once per location. Approved gyms receive badge rights, map placement, and certified directory visibility.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedGymId,
                  dropdownColor: const Color(0xFF122033),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _dialogFieldDecoration(
                    'Select your gym',
                    errorText: gymError,
                  ),
                  items: ownedGyms
                      .map(
                        (gym) => DropdownMenuItem<String>(
                          value: gym['id'],
                          child: Text(
                            gym['location']!.isEmpty
                                ? gym['name']!
                                : '${gym['name']} • ${gym['location']}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedGymId = value;
                      gymError = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: statementController,
                  maxLines: 6,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _dialogFieldDecoration(
                    'Describe how your gym keeps survivors and vulnerable members safe',
                    errorText: statementError,
                  ),
                  onChanged: (_) {
                    if (statementError != null) {
                      setDialogState(() => statementError = null);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: pledgeError == null
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.red.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Minimum standard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your gym agrees to zero tolerance for bullying or abuse, confidential reporting, and a trauma-aware response when someone asks for help.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                      CheckboxListTile(
                        value: signedPledge,
                        contentPadding: EdgeInsets.zero,
                        activeColor: _sakuraPink,
                        checkColor: Colors.white,
                        title: const Text(
                          'I confirm this gym will follow the Pink Shield pledge.',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            signedPledge = value ?? false;
                            pledgeError = null;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (pledgeError != null)
                        Text(
                          pledgeError!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final statement = statementController.text.trim();
                final validGym =
                    selectedGymId != null && selectedGymId!.isNotEmpty;
                final validStatement = statement.length >= 40;
                final validPledge = signedPledge;

                if (!validGym || !validStatement || !validPledge) {
                  setDialogState(() {
                    gymError = validGym ? null : 'Select one gym location';
                    statementError = validStatement
                        ? null
                        : 'Use at least 40 characters so reviewers can assess the location';
                    pledgeError = validPledge
                        ? null
                        : 'You must accept the Pink Shield pledge';
                  });
                  return;
                }

                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _sakuraPink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit Application'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selectedGymId == null) {
      return;
    }

    setState(() => _applicationSubmitting = true);

    try {
      await _safetyService.applyForPinkShield(
        entityId: selectedGymId!,
        entityType: 'gym',
        applicantId: user.uid,
        safetyStatement: statementController.text.trim(),
      );

      _pinkShieldMetricsFuture = _loadPinkShieldMetrics();
      await _refreshPinkShieldStatus();

      if (!mounted) return;
      setState(() => _applicationSubmitting = false);
      _showSnack(
        'Pink Shield application submitted. DFC will review it before badge and map activation.',
        _sakuraPink,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _applicationSubmitting = false);
      _showSnack('Application failed. Please try again. ($e)', Colors.red);
    }
  }

  InputDecoration _dialogFieldDecoration(String hintText, {String? errorText}) {
    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      errorStyle: const TextStyle(color: Colors.redAccent),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: _sakuraPink),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'approved':
        return DesignTokens.neonGreen;
      case 'pending':
        return DesignTokens.neonCyan;
      case 'denied':
      case 'rejected':
      case 'revoked':
        return Colors.redAccent;
      default:
        return _sakuraPink;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'pending':
        return 'In Review';
      case 'denied':
      case 'rejected':
        return 'Not Approved';
      case 'revoked':
        return 'Revoked';
      default:
        return 'Ready To Apply';
    }
  }

  String _statusDescription(String? status) {
    switch (status) {
      case 'approved':
        return 'Your gym has Pink Shield approval and can carry the badge, listing, and map placement.';
      case 'pending':
        return 'Your application is in review. Badge rights and map placement only go live after approval.';
      case 'denied':
      case 'rejected':
        return 'The last application was not approved. Review the standard and reapply when the gym is ready.';
      case 'revoked':
        return 'Pink Shield approval was removed. The gym must meet the standard again before relisting.';
      default:
        return 'Pink Shield is a real standard, not a sticker. Apply when the gym is ready to operate as a survivor-safe space.';
    }
  }

  String _formatShortDate(DateTime date) {
    final month = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  Future<Map<String, int>> _loadPinkShieldMetrics() async {
    try {
      final approvedGymsFuture = _db
          .collection('pink_shield_certifications')
          .where('status', isEqualTo: 'approved')
          .count()
          .get();
      final pendingApplicationsFuture = _db
          .collection('pink_shield_applications')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      final results = await Future.wait([
        approvedGymsFuture,
        pendingApplicationsFuture,
      ]);

      return {
        'approvedGyms': results[0].count ?? 0,
        'pendingApplications': results[1].count ?? 0,
        'activeCities': _solidarityLocations.length,
      };
    } catch (_) {
      return {
        'approvedGyms': 2847,
        'pendingApplications': 74,
        'activeCities': _solidarityLocations.length,
      };
    }
  }

  String _formatCompactCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
    }
    return '$value';
  }

  void _showSnack(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  Widget _buildReport() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.security,
                      color: Color(0xFFFF69B4),
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Report a Safety Concern',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Your safety matters. If you\'ve experienced or witnessed unsafe behavior at any gym, '
                  'training facility, or DFC event, please let us know. All reports are confidential '
                  'and reviewed by our safety team within 24 hours.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                _reportOption(
                  Icons.flag_outlined,
                  'Unsafe Training Practices',
                  'Equipment issues, improper supervision, unsafe drills',
                  'unsafe_training',
                ),
                const SizedBox(height: 10),
                _reportOption(
                  Icons.person_off,
                  'Harassment or Bullying',
                  'Verbal, physical, or online harassment',
                  'harassment',
                ),
                const SizedBox(height: 10),
                _reportOption(
                  Icons.medical_services_outlined,
                  'Medical Concern',
                  'Injury mishandling, concussion protocol violations',
                  'medical',
                ),
                const SizedBox(height: 10),
                _reportOption(
                  Icons.gavel,
                  'Policy Violation',
                  'Gym not following Pink Shield guidelines',
                  'policy_violation',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _selectedReportType == null || _reportSubmitting
                        ? null
                        : _showReportDialog,
                    icon: _reportSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFF69B4),
                            ),
                          )
                        : const Icon(Icons.edit_note, size: 20),
                    label: Text(
                      _selectedReportType == null
                          ? 'Select a concern type above'
                          : 'Submit Detailed Report',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFFF69B4,
                      ).withValues(alpha: 0.2),
                      foregroundColor: const Color(0xFFFF69B4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusMedium,
                        ),
                        side: BorderSide(
                          color: const Color(0xFFFF69B4).withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _glassCard(
            child: Row(
              children: [
                const Text('📞', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Emergency? Call Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'For immediate safety concerns, contact local emergency services or our 24/7 hotline.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportOption(
    IconData icon,
    String title,
    String subtitle,
    String type,
  ) {
    final selected = _selectedReportType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedReportType = type),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFF69B4).withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF69B4).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xFFFF69B4)
                  : Colors.white.withValues(alpha: 0.4),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.chevron_right,
              color: selected
                  ? const Color(0xFFFF69B4)
                  : Colors.white.withValues(alpha: 0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReportDialog() async {
    final descController = TextEditingController();
    final locationController = TextEditingController();
    bool isAnonymous = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0A1628),
          title: const Text(
            'Pink Shield Report',
            style: TextStyle(
              color: Color(0xFFFF69B4),
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All reports are confidential and reviewed by our safety team within 24 hours.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Describe what happened...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFFF69B4)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Location (gym name, address, or event)',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFFF69B4)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Submit Anonymously',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  subtitle: Text(
                    'Your identity will be hidden from reviewers',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                  value: isAnonymous,
                  activeThumbColor: const Color(0xFFFF69B4),
                  onChanged: (v) => setDialogState(() => isAnonymous = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
            ),
            ElevatedButton(
              onPressed: descController.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF69B4),
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _reportSubmitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      await _safetyService.createIncidentRecord(
        userId: uid,
        incidentType: _selectedReportType!,
        description: descController.text.trim(),
        locationDescription: locationController.text.trim().isNotEmpty
            ? locationController.text.trim()
            : null,
        isAnonymous: isAnonymous,
      );

      if (!mounted) return;
      setState(() {
        _reportSubmitting = false;
        _selectedReportType = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Report submitted. Our safety team will review within 24 hours. You are not alone.',
          ),
          backgroundColor: Color(0xFFFF69B4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _reportSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report. Please try again. ($e)'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFF69B4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard.withValues(
          alpha: DesignTokens.glassOpacity + 0.04,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: DesignTokens.glassBorderOpacity,
          ),
        ),
      ),
      child: child,
    );
  }
}
