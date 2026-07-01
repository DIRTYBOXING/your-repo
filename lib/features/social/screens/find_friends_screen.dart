import 'dart:async';

import 'package:flutter/material.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../core/config/router_config.dart' as rc;
import '../../../core/utils/app_logger.dart';
import '../../../shared/models/friend_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/enhanced_friends_service.dart';
import '../../../shared/services/friend_service.dart';
import '../../../core/theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIND FRIENDS SCREEN — Fighter Discovery & Connection Hub
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Features:
/// - Text search with live results
/// - AI-powered fighter recommendations
/// - Pending friend requests inbox
/// - Filter by style, skill level, gym proximity
/// - Mutual connections display
/// - One-tap connection requests
///
/// Layout:
/// 1. Search bar + filters
/// 2. Pending requests section (if any)
/// 3. Friend suggestions carousel
/// 4. Search results grid

class FindFriendsScreen extends StatefulWidget {
  const FindFriendsScreen({super.key});

  @override
  State<FindFriendsScreen> createState() => _FindFriendsScreenState();
}

// ═══════════════════════════════════════════════════════════════════════════
// NEARBY TAB — Geo-Location Based Fighter Discovery
// ═══════════════════════════════════════════════════════════════════════════

class _NearbyTab extends StatefulWidget {
  final FriendService friendService;

  const _NearbyTab({required this.friendService});

  @override
  State<_NearbyTab> createState() => _NearbyTabState();
}

class _NearbyTabState extends State<_NearbyTab> {
  static const String _logTag = 'FindFriendsNearbyTab';
  List<Map<String, dynamic>> _nearbyFighters = [];
  bool _isLoading = false;
  bool _hasPermission = false;
  String? _errorMessage;
  Position? _currentPosition;
  double _radiusKm = 10.0;

  @override
  void initState() {
    super.initState();
    AppLogger.debug('initState -> checkLocationPermission', tag: _logTag);
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    AppLogger.debug('checkLocationPermission:start', tag: _logTag);
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppLogger.warning('location services disabled', tag: _logTag);
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Location services are disabled';
        _hasPermission = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    AppLogger.debug('permission status=$permission', tag: _logTag);
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      AppLogger.debug('permission requested -> $permission', tag: _logTag);
      if (permission == LocationPermission.denied) {
        AppLogger.warning('location permission denied', tag: _logTag);
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Location permission denied';
          _hasPermission = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      AppLogger.warning('location permission denied forever', tag: _logTag);
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Location permissions are permanently denied';
        _hasPermission = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() => _hasPermission = true);
    AppLogger.debug(
      'permission granted -> loading nearby fighters',
      tag: _logTag,
    );
    _loadNearbyFighters();
  }

  Future<void> _loadNearbyFighters() async {
    if (!_hasPermission) return;

    AppLogger.debug(
      'loadNearbyFighters:start radiusKm=${_radiusKm.toStringAsFixed(1)}',
      tag: _logTag,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      AppLogger.debug(
        'position lat=${_currentPosition!.latitude} lng=${_currentPosition!.longitude}',
        tag: _logTag,
      );

      // Update user's location in Firestore
      await widget.friendService.updateUserLocation(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      // Get nearby fighters
      final nearby = await widget.friendService.getNearbyFighters(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusKm: _radiusKm,
      );
      AppLogger.debug('nearby results=${nearby.length}', tag: _logTag);

      if (mounted) {
        setState(() {
          _nearbyFighters = nearby;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('loadNearbyFighters:failed', tag: _logTag, error: e);
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading nearby fighters: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return _buildPermissionPrompt();
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.neonCyan),
            SizedBox(height: 16),
            Text(
              'Finding nearby fighters...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_nearbyFighters.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Radius Selector
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.tune, color: AppTheme.neonCyan, size: 20),
              const SizedBox(width: 8),
              Text(
                'Radius: ${_radiusKm.toInt()} km',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              Expanded(
                child: Slider(
                  value: _radiusKm,
                  min: 1.0,
                  max: 50.0,
                  divisions: 49,
                  activeColor: AppTheme.neonCyan,
                  inactiveColor: Colors.grey[700],
                  onChanged: (value) {
                    setState(() => _radiusKm = value);
                  },
                  onChangeEnd: (_) => _loadNearbyFighters(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppTheme.neonCyan),
                onPressed: _loadNearbyFighters,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),

        // Nearby Fighters List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _nearbyFighters.length,
            itemBuilder: (context, index) {
              final data = _nearbyFighters[index];
              final user = data['user'] as UserModel;
              final distance = data['distance'] as double;
              final distanceStr = data['distanceFormatted'] as String;

              return _NearbyFighterCard(
                user: user,
                distance: distance,
                distanceFormatted: distanceStr,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off,
              size: 80,
              color: AppTheme.neonMagenta,
            ),
            const SizedBox(height: 24),
            const Text(
              'Location Access Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Enable location to find nearby fighters',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _checkLocationPermission,
              icon: const Icon(Icons.location_on),
              label: const Text('Enable Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadNearbyFighters,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonCyan,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_searching, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              'No Fighters Nearby',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No fighters found within ${_radiusKm.toInt()} km',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _radiusKm = (_radiusKm + 10).clamp(1, 50));
                _loadNearbyFighters();
              },
              icon: const Icon(Icons.zoom_out_map),
              label: const Text('Increase Radius'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonCyan,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NEARBY FIGHTER CARD
// ═══════════════════════════════════════════════════════════════════════════

class _NearbyFighterCard extends StatelessWidget {
  final UserModel user;
  final double distance;
  final String distanceFormatted;

  const _NearbyFighterCard({
    required this.user,
    required this.distance,
    required this.distanceFormatted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.neonCyan.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Profile Picture
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: user.photoUrl != null
                ? DfcNetworkImage(
                    url: user.photoUrl!,
                    width: 60,
                    height: 60,
                  )
                : _buildDefaultAvatar(),
          ),
          const SizedBox(width: 12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'Fighter',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppTheme.neonMagenta,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      distanceFormatted,
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Connect Button
          ElevatedButton.icon(
            onPressed: () => _sendFriendRequest(context),
            icon: const Icon(Icons.person_add, size: 16),
            label: const Text('Connect'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 60,
      height: 60,
      color: AppTheme.neonCyan.withValues(alpha: 0.3),
      child: const Center(
        child: Icon(Icons.person, size: 32, color: AppTheme.neonCyan),
      ),
    );
  }

  Future<void> _sendFriendRequest(BuildContext context) async {
    try {
      await context.read<EnhancedFriendsService>().sendFriendRequest(
        recipientId: user.id,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to ${user.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _FindFriendsScreenState extends State<FindFriendsScreen>
    with SingleTickerProviderStateMixin {
  static const String _logTag = 'FindFriendsScreen';
  final FriendService _friendService = FriendService();
  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;

  List<UserModel> _searchResults = [];
  List<Map<String, dynamic>> _suggestions = []; // Changed to hold {user, score}
  bool _usingFallbackContent = false;
  bool _isSearching = false;
  bool _isLoadingSuggestions = true;
  Timer? _searchDebounce;

  List<Map<String, dynamic>> _fallbackSuggestions() {
    final now = DateTime.now();
    final fighters = <UserModel>[
      UserModel(
        id: 'demo_fighter_1',
        email: 'leila.storm@dfc.demo',
        displayName: 'Leila Storm',
        username: 'leilastorm',
        role: UserRole.fighter,
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        id: 'demo_fighter_2',
        email: 'marcus.iron@dfc.demo',
        displayName: 'Marcus Iron',
        username: 'marcusiron',
        role: UserRole.fighter,
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        id: 'demo_fighter_3',
        email: 'nina.viper@dfc.demo',
        displayName: 'Nina Viper',
        username: 'ninaviper',
        role: UserRole.fighter,
        createdAt: now,
        updatedAt: now,
      ),
      UserModel(
        id: 'demo_fighter_4',
        email: 'kai.hammer@dfc.demo',
        displayName: 'Kai Hammer',
        username: 'kaihammer',
        role: UserRole.fighter,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    return [
      {'user': fighters[0], 'score': 96},
      {'user': fighters[1], 'score': 91},
      {'user': fighters[2], 'score': 87},
      {'user': fighters[3], 'score': 82},
    ];
  }

  List<UserModel> _fallbackSearch(String query) {
    final q = query.trim().toLowerCase();
    final all = _fallbackSuggestions().map((e) => e['user'] as UserModel);
    return all.where((u) {
      final name = (u.displayName ?? '').toLowerCase();
      final username = (u.username ?? '').toLowerCase();
      return name.contains(q) || username.contains(q);
    }).toList();
  }

  bool _isPermissionDenied(Object e) {
    return e is FirebaseException && e.code == 'permission-denied';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    AppLogger.debug('initState -> prep discovery index', tag: _logTag);
    unawaited(_friendService.upsertCurrentUserDiscoveryIndex());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadSuggestions();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      _performSearch(query);
    });
  }

  Future<void> _loadSuggestions() async {
    AppLogger.debug('loadSuggestions:start', tag: _logTag);
    if (!mounted) return;
    setState(() => _isLoadingSuggestions = true);
    try {
      final suggestions = await _friendService.getFriendSuggestionsWithScores(
        
      );
      AppLogger.debug(
        'loadSuggestions:results=${suggestions.length}',
        tag: _logTag,
      );
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _usingFallbackContent = false;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      AppLogger.error('loadSuggestions:failed', tag: _logTag, error: e);
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
          _usingFallbackContent = true;
          _suggestions = _fallbackSuggestions();
        });
        final msg = _isPermissionDenied(e)
            ? 'Showing demo fighters while database access is being set up.'
            : 'Showing demo fighters for now.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  Future<void> _performSearch(String query) async {
    AppLogger.debug('search:start query="${query.trim()}"', tag: _logTag);
    if (query.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() => _isSearching = true);

    try {
      final results = await _friendService.searchUsers(query);
      AppLogger.debug('search:results=${results.length}', tag: _logTag);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _usingFallbackContent = false;
          _isSearching = false;
        });
      }
    } catch (e) {
      AppLogger.error('search:failed', tag: _logTag, error: e);
      if (mounted) {
        setState(() {
          _isSearching = false;
          _usingFallbackContent = true;
          _searchResults = _fallbackSearch(query);
        });
        final msg = _isPermissionDenied(e)
            ? 'Database read is restricted. Showing demo search results.'
            : 'Search service unavailable. Showing demo results.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('Find Fighters'),
        backgroundColor: AppTheme.primaryBackground,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.neonCyan,
          labelColor: AppTheme.neonCyan,
          unselectedLabelColor: Colors.grey[400],
          tabs: const [
            Tab(text: 'Suggestions', icon: Icon(Icons.recommend, size: 20)),
            Tab(text: 'Nearby', icon: Icon(Icons.location_on, size: 20)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildDfcPromoQuickLaunch(),
          if (_usingFallbackContent)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.neonCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.neonCyan.withValues(alpha: 0.4),
                ),
              ),
              child: const Text(
                'Demo content mode: connect/search UI is live while Firestore permissions are configured.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          // ═══════════════════════════════════════════════════════════════════
          // SEARCH BAR
          // ═══════════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search fighters by name...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.neonMagenta,
                ),
                filled: true,
                fillColor: AppTheme.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.neonCyan.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.neonCyan,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          // ═══════════════════════════════════════════════════════════════════
          // PENDING REQUESTS SECTION
          // ═══════════════════════════════════════════════════════════════════
          StreamBuilder<List<FriendRequest>>(
            stream: context
                .read<EnhancedFriendsService>()
                .streamPendingRequests(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }

              final requests = snapshot.data!;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.neonMagenta),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.person_add,
                          color: AppTheme.neonMagenta,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Friend Requests (${requests.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...requests.take(3).map((request) {
                      return _PendingRequestCard(request: request);
                    }),
                    if (requests.length > 3)
                      TextButton(
                        onPressed: () => context.push('/friend-requests'),
                        child: const Text(
                          'View all requests',
                          style: TextStyle(color: AppTheme.neonCyan),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),

          // ═══════════════════════════════════════════════════════════════════
          // MAIN CONTENT
          // ═══════════════════════════════════════════════════════════════════
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _searchController.text.isNotEmpty
                  ? _buildSearchResults()
                  : TabBarView(
                      key: const ValueKey('find_friends_tabs'),
                      controller: _tabController,
                      children: [
                        _buildSuggestions(),
                        _NearbyTab(friendService: _friendService),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH RESULTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        key: ValueKey('search_loading'),
        child: CircularProgressIndicator(color: AppTheme.neonCyan),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        key: const ValueKey('search_empty'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No fighters found',
              style: TextStyle(color: Colors.grey[400], fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different search terms',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      key: const ValueKey('search_results'),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _FighterCard(user: _searchResults[index]);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUGGESTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSuggestions() {
    if (_isLoadingSuggestions) {
      return _buildSuggestionsSkeleton();
    }

    if (_suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No suggestions yet',
              style: TextStyle(color: Colors.grey[400], fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect with fighters to get recommendations',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSuggestions,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Suggestions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonCyan,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Suggested Fighters',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: _suggestions.length,
          itemBuilder: (context, index) {
            final data = _suggestions[index];
            final user = data['user'] as UserModel;
            final score = (data['score'] as num).round();
            return _FighterCard(user: user, compatibilityScore: score);
          },
        ),
      ],
    );
  }

  Widget _buildDfcPromoQuickLaunch() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            AppTheme.neonMagenta.withValues(alpha: 0.16),
            AppTheme.neonCyan.withValues(alpha: 0.16),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DFC Promotional Advantage',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Launch fight visibility, social amplification, and promo assets in one flow.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickActionChip(
                'FightWire',
                Icons.bolt,
                () => context.push(rc.RouterConfig.fightWirePath),
              ),
              _quickActionChip(
                'Social Queue',
                Icons.campaign,
                () => context.push(rc.RouterConfig.socialQueuePath),
              ),
              _quickActionChip(
                'Promo Tools',
                Icons.rocket_launch,
                () => context.push(rc.RouterConfig.eventPromotionPath),
              ),
              _quickActionChip(
                'Toolkit',
                Icons.auto_awesome,
                () => context.push(rc.RouterConfig.socialMediaToolkitPath),
              ),
              _quickActionChip(
                'Genius',
                Icons.psychology_alt,
                () => context.push('/genie'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSkeleton() {
    return GridView.builder(
      key: const ValueKey('suggestions_skeleton'),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      width: 90,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 60,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 28,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _quickActionChip(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.neonCyan),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FIGHTER CARD WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class _FighterCard extends StatelessWidget {
  final UserModel user;
  final int? compatibilityScore;

  const _FighterCard({required this.user, this.compatibilityScore});

  String get _compatibilityGrade {
    final score = compatibilityScore ?? 0;
    if (score >= 90) return 'A+';
    if (score >= 80) return 'A';
    if (score >= 70) return 'B+';
    if (score >= 60) return 'B';
    return 'C';
  }

  Color get _compatibilityColor {
    final score = compatibilityScore ?? 0;
    if (score >= 80) return AppTheme.neonMagenta;
    if (score >= 60) return AppTheme.neonCyan;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/user/${user.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                (compatibilityScore != null
                        ? _compatibilityColor
                        : AppTheme.neonCyan)
                    .withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Picture with Compatibility Badge
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: user.photoUrl != null
                        ? DfcNetworkImage(
                            url: user.photoUrl!,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : _buildDefaultAvatar(),
                  ),
                  // Compatibility Badge (only show if score available)
                  if (compatibilityScore != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _compatibilityColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _compatibilityColor.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _compatibilityGrade,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // User Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? 'Fighter',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (compatibilityScore != null)
                    Row(
                      children: [
                        Icon(
                          Icons.psychology,
                          size: 12,
                          color: _compatibilityColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$compatibilityScore% Match',
                          style: TextStyle(
                            color: _compatibilityColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      user.email,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),

                  // Connect Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _sendFriendRequest(context),
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Connect'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: compatibilityScore != null
                            ? _compatibilityColor
                            : AppTheme.neonCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppTheme.neonCyan.withValues(alpha: 0.3),
      child: const Center(
        child: Icon(Icons.person, size: 48, color: AppTheme.neonCyan),
      ),
    );
  }

  Future<void> _sendFriendRequest(BuildContext context) async {
    try {
      await context.read<EnhancedFriendsService>().sendFriendRequest(
        recipientId: user.id,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to ${user.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final denied = e is FirebaseException && e.code == 'permission-denied';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              denied
                  ? 'Connection requests need Firestore permissions. UI is ready; backend access is pending.'
                  : 'Error: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PENDING REQUEST CARD
// ═══════════════════════════════════════════════════════════════════════════

class _PendingRequestCard extends StatelessWidget {
  final FriendRequest request;

  const _PendingRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push('/user/${request.senderId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Avatar
            DfcCircleAvatar(
              imageUrl: request.senderPhotoUrl,
              radius: 24,
              backgroundColor: AppTheme.neonCyan.withValues(alpha: 0.18),
              borderColor: AppTheme.neonCyan.withValues(alpha: 0.35),
              borderWidth: 1,
              fallbackIconColor: AppTheme.neonCyan,
            ),
            const SizedBox(width: 12),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.senderName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'wants to connect',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Row(
              children: [
                IconButton(
                  onPressed: () => _acceptRequest(context),
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  tooltip: 'Accept',
                ),
                IconButton(
                  onPressed: () => _declineRequest(context),
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  tooltip: 'Decline',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptRequest(BuildContext context) async {
    try {
      await context.read<EnhancedFriendsService>().acceptFriendRequest(
        request.id,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are now connected with ${request.senderName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _declineRequest(BuildContext context) async {
    try {
      await context.read<EnhancedFriendsService>().rejectFriendRequest(
        request.id,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request declined'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
