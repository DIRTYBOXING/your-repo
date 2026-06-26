import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datafightcentral/shared/services/discovery_service.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../../../shared/widgets/dfc_state_panel.dart';
import '../../../shared/widgets/dfc_tab_intro_header.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/enhanced_friends_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// EXPLORE SCREEN - Multi-Role Discovery Feed
/// Users find fighters, gyms, events, and other users to connect with
/// ═══════════════════════════════════════════════════════════════════════════
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late DiscoveryService _discoveryService;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  Map<String, List<DiscoveryResult>> _results = {
    'fighters': [],
    'gyms': [],
    'events': [],
  };

  // Earth globe map state
  bool _showEarthMap = true;
  GoogleMapController? _earthMapController;
  Set<Marker> _eventMarkers = {};
  bool _mapTimedOut = false;
  int _liveEventCount = 0;
  int _totalEventCount = 0;

  // Filter state
  String? _selectedSport;
  String? _selectedLocation;
  String? _selectedSkillLevel;
  String? _selectedWeightClass;
  static const _sports = [
    'MMA',
    'Boxing',
    'Muay Thai',
    'BKFC',
    'Bare Knuckle',
    'Brawling',
    'BJJ',
    'Kickboxing',
    'Wrestling',
  ];
  static const _locations = [
    'Global',
    'Australia & NZ',
    'Asia-Pacific',
    'Americas',
    'Europe',
    'Africa',
  ];
  static const _skillLevels = [
    'Beginner',
    'Amateur',
    'Semi-Pro',
    'Professional',
    'Elite',
  ];
  static const _weightClasses = [
    'Strawweight',
    'Flyweight',
    'Bantamweight',
    'Featherweight',
    'Lightweight',
    'Welterweight',
    'Middleweight',
    'Light Heavyweight',
    'Heavyweight',
    'Super Heavyweight',
  ];

  void _goBackSafely() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadDiscovery();
    _loadEventMarkers();
    // Web timeout: if map doesn't load in 10s, hide it
    if (kIsWeb) {
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _earthMapController == null) {
          setState(() => _mapTimedOut = true);
        }
      });
    }
  }

  void _onTabChanged() {
    setState(() {});
  }

  Future<void> _loadDiscovery() async {
    if (!mounted) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      _discoveryService = context.read<DiscoveryService>();
      final feed = await _discoveryService.getDiscoveryFeed();
      if (!mounted) {
        return;
      }
      setState(() {
        _results = feed;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _results = DiscoveryService.getDemoFeed();
        _isLoading = false;
      });
    }
  }

  /// Load global event markers from Firestore for the Earth satellite view
  Future<void> _loadEventMarkers() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('events')
          .orderBy('eventDate', descending: false)
          .limit(50)
          .get();

      final markers = <Marker>{};
      int live = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;
        final title =
            data['title'] as String? ?? data['name'] as String? ?? 'Event';
        final isLive = data['isLive'] == true;
        if (isLive) live++;
        markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: title),
            icon: isLive
                ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
                : BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueCyan,
                  ),
          ),
        );
      }
      if (mounted) {
        setState(() {
          _eventMarkers = markers;
          _liveEventCount = live;
          _totalEventCount = snap.docs.length;
        });
      }
    } catch (_) {
      // Non-blocking — map still shows without markers
    }
  }

  /// Dark satellite map style for the Earth globe view
  static const _darkMapStyle = '''[
    {"elementType":"geometry","stylers":[{"color":"#0d1117"}]},
    {"elementType":"labels","stylers":[{"visibility":"off"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#050a14"}]},
    {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#0d1a2d"}]},
    {"featureType":"road","stylers":[{"visibility":"off"}]},
    {"featureType":"poi","stylers":[{"visibility":"off"}]},
    {"featureType":"transit","stylers":[{"visibility":"off"}]},
    {"featureType":"administrative.country","elementType":"geometry.stroke","stylers":[{"color":"#1a3a5c"},{"weight":0.5}]},
    {"featureType":"administrative.country","elementType":"labels","stylers":[{"visibility":"on"},{"color":"#2a5a8c"}]}
  ]''';

  /// Build the Earth satellite globe section
  Widget _buildEarthGlobe() {
    if (_mapTimedOut && !_showEarthMap) return const SizedBox.shrink();

    return Column(
      children: [
        // Toggle header
        GestureDetector(
          onTap: () => setState(() => _showEarthMap = !_showEarthMap),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  DesignTokens.neonCyan.withValues(alpha: 0.08),
                  DesignTokens.neonMagenta.withValues(alpha: 0.04),
                ],
              ),
              border: Border.all(
                color: DesignTokens.neonCyan.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.public,
                  color: DesignTokens.neonCyan,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'GLOBAL EVENTS ',
                          style: TextStyle(
                            color: DesignTokens.neonCyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        TextSpan(
                          text:
                              '$_totalEventCount events · $_liveEventCount live',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(
                  _showEarthMap ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        // Earth map
        if (_showEarthMap && !_mapTimedOut)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DesignTokens.neonCyan.withValues(alpha: 0.2),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(20.0, 10.0), // Global view centered
                    zoom: 1.8,
                  ),
                  style: _darkMapStyle,
                  mapType: MapType.satellite,
                  markers: _eventMarkers,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  onMapCreated: (controller) {
                    _earthMapController = controller;
                  },
                ),
                // Top-left legend
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
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
                        const SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: DesignTokens.neonCyan,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Upcoming',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom-right gym finder button
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => context.push('/gym-map-command'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: DesignTokens.neonCyan.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fitness_center,
                              color: Colors.black,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Find Gyms',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
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
          ),
        if (_mapTimedOut && _showEarthMap)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0A1628).withValues(alpha: 0.9),
                  const Color(0xFF0A1628).withValues(alpha: 0.7),
                ],
              ),
              border: Border.all(
                color: DesignTokens.neonCyan.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.public_off,
                        color: DesignTokens.neonCyan,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EARTH VIEW FALLBACK ACTIVE',
                            style: TextStyle(
                              color: DesignTokens.neonCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Global discovery data is still live. Open the full DFC Earth Network or gym command map while this embed is unavailable.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.push('/google-earth'),
                      icon: const Icon(Icons.public, size: 16),
                      label: const Text('Open Earth Network'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DesignTokens.neonCyan,
                        side: BorderSide(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => context.push('/gym-map-command'),
                      icon: const Icon(Icons.fitness_center, size: 16),
                      label: const Text('Open Gym Command'),
                      style: FilledButton.styleFrom(
                        backgroundColor: DesignTokens.neonCyan,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      _loadDiscovery();
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      _discoveryService = context.read<DiscoveryService>();
      final searchResults = await _discoveryService.searchAll(query);
      if (!mounted) {
        return;
      }

      setState(() {
        _results = {
          'fighters': searchResults.where((r) => r.type == 'fighter').toList(),
          'gyms': searchResults.where((r) => r.type == 'gym').toList(),
          'events': searchResults.where((r) => r.type == 'event').toList(),
        };
        _isLoading = false;
      });
    } catch (e) {
      // Fallback: filter demo data by query
      final q = query.toLowerCase();
      final demo = DiscoveryService.getDemoFeed();
      if (!mounted) {
        return;
      }
      setState(() {
        _results = {
          'fighters': (demo['fighters'] ?? [])
              .where(
                (r) =>
                    r.name.toLowerCase().contains(q) ||
                    (r.description?.toLowerCase().contains(q) ?? false),
              )
              .toList(),
          'gyms': (demo['gyms'] ?? [])
              .where(
                (r) =>
                    r.name.toLowerCase().contains(q) ||
                    (r.description?.toLowerCase().contains(q) ?? false),
              )
              .toList(),
          'events': (demo['events'] ?? [])
              .where(
                (r) =>
                    r.name.toLowerCase().contains(q) ||
                    (r.description?.toLowerCase().contains(q) ?? false),
              )
              .toList(),
        };
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final useShellV2 = AppConstants.featureShellV2;
    return Scaffold(
      backgroundColor: useShellV2
          ? DesignTokens.shellBackground
          : AppTheme.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            DFCTabIntroHeader(
              title: 'Explore',
              subtitle:
                  'Scout roster talent, training centers, and partner events across the DFC platform.',
              icon: Icons.travel_explore_rounded,
              accent: useShellV2 ? DesignTokens.ppvAccent : AppTheme.neonCyan,
              leading: context.canPop()
                  ? IconButton(
                      tooltip: 'Back',
                      onPressed: _goBackSafely,
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: useShellV2
                            ? DesignTokens.shellText
                            : Colors.white,
                        size: 18,
                      ),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: _buildPlatformSummary(useShellV2: useShellV2),
            ),
            // ── Earth Globe — Global Events Satellite View ──
            _buildEarthGlobe(),
            // ── Search Bar ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: useShellV2
                      ? DesignTokens.shellSurface
                      : AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: useShellV2
                        ? DesignTokens.shellBorder
                        : AppTheme.neonCyan.withValues(alpha: 0.24),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _search,
                  style: const TextStyle(
                    color: DesignTokens.shellText,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search roster, venues, and events',
                    hintStyle: TextStyle(
                      color: useShellV2
                          ? DesignTokens.shellTextSubtle
                          : AppTheme.neonCyan.withValues(alpha: 0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: useShellV2
                          ? DesignTokens.shellTextMuted
                          : AppTheme.neonCyan.withValues(alpha: 0.7),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _loadDiscovery();
                            },
                            child: Icon(
                              Icons.clear,
                              color: useShellV2
                                  ? DesignTokens.shellTextSubtle
                                  : AppTheme.neonCyan.withValues(alpha: 0.7),
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            // ── Filter Bar ──────────────────────────────────────────────────
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip(
                    label: _selectedSport ?? 'Sport',
                    icon: Icons.sports_mma,
                    isActive: _selectedSport != null,
                    onTap: _showSportFilter,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: _selectedLocation ?? 'Location',
                    icon: Icons.location_on,
                    isActive: _selectedLocation != null,
                    onTap: _showLocationFilter,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: _selectedSkillLevel ?? 'Skill Level',
                    icon: Icons.bar_chart,
                    isActive: _selectedSkillLevel != null,
                    onTap: _showSkillLevelFilter,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: _selectedWeightClass ?? 'Weight Class',
                    icon: Icons.fitness_center,
                    isActive: _selectedWeightClass != null,
                    onTap: _showWeightClassFilter,
                  ),
                  if (_selectedSport != null ||
                      _selectedLocation != null ||
                      _selectedSkillLevel != null ||
                      _selectedWeightClass != null) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedSport = null;
                          _selectedLocation = null;
                          _selectedSkillLevel = null;
                          _selectedWeightClass = null;
                        });
                        _loadDiscovery();
                      },
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text(
                        'Clear',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: useShellV2
                            ? DesignTokens.ppvAccent
                            : AppTheme.neonCyan,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Tabs ────────────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              decoration: BoxDecoration(
                color: useShellV2
                    ? DesignTokens.shellSurface
                    : AppTheme.secondaryBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: useShellV2
                      ? DesignTokens.shellBorder
                      : AppTheme.neonCyan.withValues(alpha: 0.16),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Fighters'),
                  Tab(text: 'Gyms'),
                  Tab(text: 'Events'),
                ],
                labelColor: useShellV2
                    ? DesignTokens.shellText
                    : AppTheme.neonCyan,
                unselectedLabelColor: useShellV2
                    ? DesignTokens.shellTextSubtle
                    : Colors.grey,
                indicatorColor: useShellV2
                    ? DesignTokens.ppvAccent
                    : AppTheme.neonCyan,
                dividerColor: Colors.transparent,
              ),
            ),

            // ── Content ─────────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: DFCStatePanel.loading(
                          title: 'Loading discovery',
                          message:
                              'Finding fighters, gyms, and events for this view.',
                        ),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAllTab(),
                        _buildListTab('fighters'),
                        _buildListTab('gyms'),
                        _buildListTab('events'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformSummary({required bool useShellV2}) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryTile(
            label: 'Fighters',
            value: '${_results['fighters']?.length ?? 0}',
            accent: useShellV2 ? DesignTokens.ppvAccent : AppTheme.neonCyan,
            useShellV2: useShellV2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryTile(
            label: 'Gyms',
            value: '${_results['gyms']?.length ?? 0}',
            accent: useShellV2 ? DesignTokens.shellAccent : AppTheme.neonGreen,
            useShellV2: useShellV2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryTile(
            label: 'Events',
            value: '${_results['events']?.length ?? 0}',
            accent: useShellV2
                ? DesignTokens.shellAccentSoft
                : AppTheme.neonCyan,
            useShellV2: useShellV2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryTile(
            label: 'Filters',
            value: '${_activeFilterCount()}',
            accent: useShellV2 ? DesignTokens.shellTextMuted : Colors.white70,
            useShellV2: useShellV2,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryTile({
    required String label,
    required String value,
    required Color accent,
    required bool useShellV2,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: useShellV2 ? DesignTokens.shellSurface : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: useShellV2
              ? DesignTokens.shellBorder
              : accent.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: useShellV2 ? DesignTokens.shellText : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  int _activeFilterCount() {
    var count = 0;
    if (_selectedSport != null) count++;
    if (_selectedLocation != null) count++;
    if (_selectedSkillLevel != null) count++;
    if (_selectedWeightClass != null) count++;
    return count;
  }

  Widget _buildAllTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (_results['fighters']!.isNotEmpty) ...[
          _buildSectionHeader(
            title: 'Global Fighters',
            icon: Icons.sports_mma,
            count: _results['fighters']!.length,
          ),
          ..._results['fighters']!.take(3).map(_buildResultCard),
          const SizedBox(height: 16),
        ],
        if (_results['gyms']!.isNotEmpty) ...[
          _buildSectionHeader(
            title: 'Global Training Centers',
            icon: Icons.fitness_center,
            count: _results['gyms']!.length,
          ),
          ..._results['gyms']!.take(3).map(_buildResultCard),
          const SizedBox(height: 16),
        ],
        if (_results['events']!.isNotEmpty) ...[
          _buildSectionHeader(
            title: 'Global Events',
            icon: Icons.celebration,
            count: _results['events']!.length,
          ),
          ..._results['events']!.take(3).map(_buildResultCard),
        ],
        if (_results['fighters']!.isEmpty &&
            _results['gyms']!.isEmpty &&
            _results['events']!.isEmpty)
          _buildEmptyState(),
      ],
    );
  }

  Widget _buildListTab(String type) {
    final items = _results[type] ?? [];
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: items.map(_buildResultCard).toList(),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required int count,
  }) {
    final useShellV2 = AppConstants.featureShellV2;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: useShellV2 ? DesignTokens.ppvAccent : AppTheme.neonCyan,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: useShellV2 ? DesignTokens.shellText : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            '$count found',
            style: TextStyle(
              color: useShellV2
                  ? DesignTokens.shellTextMuted
                  : AppTheme.neonCyan,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(DiscoveryResult result) {
    final friendsService = context.read<EnhancedFriendsService>();
    final useShellV2 = AppConstants.featureShellV2;

    return FutureBuilder<RelationshipStatus>(
      future: friendsService.getRelationshipStatus(result.id),
      builder: (context, snapshot) {
        final status = snapshot.data ?? RelationshipStatus.none;

        return GestureDetector(
          onTap: () => context.push('/user/${result.id}'),
          child: Card(
            color: useShellV2
                ? DesignTokens.shellSurface
                : AppTheme.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: useShellV2
                    ? DesignTokens.shellBorder
                    : AppTheme.neonCyan.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Profile Photo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: useShellV2
                            ? DesignTokens.shellBorder
                            : AppTheme.neonCyan,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: result.photoUrl != null
                          ? DfcNetworkImage(
                              url: result.photoUrl!,
                            )
                          : Icon(
                              Icons.person,
                              size: 30,
                              color: useShellV2
                                  ? DesignTokens.shellTextMuted
                                  : AppTheme.neonCyan,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              result.name,
                              style: TextStyle(
                                color: useShellV2
                                    ? DesignTokens.shellText
                                    : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (result.metadata['isVerified'] == true) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified,
                                size: 16,
                                color: useShellV2
                                    ? DesignTokens.ppvAccent
                                    : AppTheme.neonCyan,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        _buildTypePill(result.type, useShellV2: useShellV2),
                        const SizedBox(height: 6),
                        // Location: City, Country with flag
                        if (result.metadata['city'] != null ||
                            result.metadata['country'] != null)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: useShellV2
                                    ? DesignTokens.shellTextMuted
                                    : AppTheme.neonCyan,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${result.metadata['city'] ?? ''}${result.metadata['city'] != null && result.metadata['country'] != null ? ', ' : ''}${result.metadata['country'] ?? ''}',
                                  style: TextStyle(
                                    color: useShellV2
                                        ? DesignTokens.shellTextMuted
                                        : AppTheme.neonCyan,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        else if (result.distance != null)
                          Text(
                            '${result.distance!.toStringAsFixed(1)} km away',
                            style: TextStyle(
                              color: useShellV2
                                  ? DesignTokens.shellTextMuted
                                  : AppTheme.neonCyan,
                              fontSize: 13,
                            ),
                          ),
                        if (result.description != null)
                          Text(
                            result.description!,
                            style: TextStyle(
                              color: useShellV2
                                  ? DesignTokens.shellTextMuted
                                  : Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Follow/Connect Button
                  _buildActionButton(status, result.id),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isActive,
    bool comingSoon = false,
    required VoidCallback onTap,
  }) {
    final useShellV2 = AppConstants.featureShellV2;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? (useShellV2
                        ? DesignTokens.ppvAccent.withValues(alpha: 0.12)
                        : AppTheme.neonCyan.withValues(alpha: 0.2))
                  : (useShellV2
                        ? DesignTokens.shellSurface
                        : AppTheme.cardBackground),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? (useShellV2 ? DesignTokens.ppvAccent : AppTheme.neonCyan)
                    : (useShellV2
                          ? DesignTokens.shellBorder
                          : AppTheme.neonCyan.withValues(alpha: 0.3)),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isActive
                      ? (useShellV2
                            ? DesignTokens.ppvAccent
                            : AppTheme.neonCyan)
                      : (useShellV2
                            ? DesignTokens.shellTextMuted
                            : Colors.white70),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? (useShellV2
                              ? DesignTokens.ppvAccent
                              : AppTheme.neonCyan)
                        : (useShellV2
                              ? DesignTokens.shellTextMuted
                              : Colors.white70),
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (comingSoon)
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Text(
                  'SOON',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showSportFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.featureShellV2
          ? DesignTokens.shellOverlay
          : AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(
        context,
        title: 'Filter by Sport',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _sports.map((sport) {
            final isSelected = _selectedSport == sport;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedSport = sport);
                Navigator.pop(context);
                _loadDiscovery();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (AppConstants.featureShellV2
                            ? DesignTokens.ppvAccent
                            : AppTheme.neonCyan)
                      : (AppConstants.featureShellV2
                            ? DesignTokens.shellSurface
                            : AppTheme.primaryBackground),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppConstants.featureShellV2
                        ? DesignTokens.shellBorder
                        : AppTheme.neonCyan,
                  ),
                ),
                child: Text(
                  sport,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showLocationFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.featureShellV2
          ? DesignTokens.shellOverlay
          : AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(
        context,
        title: 'Filter by Location',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _locations.map((location) {
            final isSelected = _selectedLocation == location;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedLocation = location);
                Navigator.pop(context);
                _loadDiscovery();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (AppConstants.featureShellV2
                            ? DesignTokens.ppvAccent.withValues(alpha: 0.12)
                            : AppTheme.neonCyan.withValues(alpha: 0.2))
                      : (AppConstants.featureShellV2
                            ? DesignTokens.shellSurface
                            : AppTheme.primaryBackground),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (AppConstants.featureShellV2
                              ? DesignTokens.ppvAccent
                              : AppTheme.neonCyan)
                        : (AppConstants.featureShellV2
                              ? DesignTokens.shellBorder
                              : Colors.grey[800]!),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: isSelected
                          ? (AppConstants.featureShellV2
                                ? DesignTokens.ppvAccent
                                : AppTheme.neonCyan)
                          : (AppConstants.featureShellV2
                                ? DesignTokens.shellTextMuted
                                : Colors.white70),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          color: isSelected
                              ? (AppConstants.featureShellV2
                                    ? DesignTokens.ppvAccent
                                    : AppTheme.neonCyan)
                              : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSkillLevelFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.featureShellV2
          ? DesignTokens.shellOverlay
          : AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(
        context,
        title: 'Filter by Skill Level',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _skillLevels.map((level) {
            final isSelected = _selectedSkillLevel == level;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedSkillLevel = level);
                Navigator.pop(context);
                _loadDiscovery();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (AppConstants.featureShellV2
                            ? DesignTokens.ppvAccent
                            : AppTheme.neonCyan)
                      : (AppConstants.featureShellV2
                            ? DesignTokens.shellSurface
                            : AppTheme.primaryBackground),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppConstants.featureShellV2
                        ? DesignTokens.shellBorder
                        : AppTheme.neonCyan,
                  ),
                ),
                child: Text(
                  level,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showWeightClassFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.featureShellV2
          ? DesignTokens.shellOverlay
          : AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(
        context,
        title: 'Filter by Weight Class',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _weightClasses.map((wc) {
            final isSelected = _selectedWeightClass == wc;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedWeightClass = wc);
                Navigator.pop(context);
                _loadDiscovery();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (AppConstants.featureShellV2
                            ? DesignTokens.ppvAccent
                            : AppTheme.neonCyan)
                      : (AppConstants.featureShellV2
                            ? DesignTokens.shellSurface
                            : AppTheme.primaryBackground),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppConstants.featureShellV2
                        ? DesignTokens.shellBorder
                        : AppTheme.neonCyan,
                  ),
                ),
                child: Text(
                  wc,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterSheet(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final useShellV2 = AppConstants.featureShellV2;
    final mediaQuery = MediaQuery.of(context);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.8),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + mediaQuery.viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: useShellV2
                      ? DesignTokens.shellText
                      : AppTheme.neonCyan,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(RelationshipStatus status, String userId) {
    final useShellV2 = AppConstants.featureShellV2;
    if (status == RelationshipStatus.none) {
      return ElevatedButton(
        onPressed: () {
          final friendsService = context.read<EnhancedFriendsService>();
          friendsService.sendFriendRequest(recipientId: userId);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: useShellV2
              ? DesignTokens.ppvAccent
              : AppTheme.neonCyan,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Text('Connect'),
      );
    } else if (status == RelationshipStatus.pending) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: useShellV2
              ? DesignTokens.shellSurfaceRaised
              : Colors.grey,
          foregroundColor: DesignTokens.shellTextMuted,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Text('Requested'),
      );
    } else if (status == RelationshipStatus.friend) {
      return ElevatedButton(
        onPressed: () => context.push('/messaging'),
        style: ElevatedButton.styleFrom(
          backgroundColor: useShellV2
              ? DesignTokens.shellSurfaceRaised
              : Colors.grey[800],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Text('Message'),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTypePill(String type, {required bool useShellV2}) {
    final label = switch (type) {
      'fighter' => 'Fighter profile',
      'gym' => 'Training center',
      'event' => 'Event listing',
      _ => 'Directory entry',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: useShellV2
            ? DesignTokens.shellSurfaceRaised
            : AppTheme.neonCyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: useShellV2
              ? DesignTokens.shellBorder
              : AppTheme.neonCyan.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: useShellV2 ? DesignTokens.shellTextMuted : AppTheme.neonCyan,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: DFCStatePanel(
          title: 'No results found',
          message:
              'Try broadening the roster search or resetting the active filters.',
          icon: Icons.search_off_rounded,
          accent: AppConstants.featureShellV2
              ? DesignTokens.ppvAccent
              : AppTheme.neonCyan,
        ),
      ),
    );
  }
}
