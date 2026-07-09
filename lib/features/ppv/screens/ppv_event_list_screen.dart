import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/image_assets.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/ppv_model.dart';
import '../../../shared/services/ppv_service.dart';
import '../widgets/dfc_ppv_event_card.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV EVENT LIST SCREEN — Premium Marketplace Grid
/// ═══════════════════════════════════════════════════════════════════════════
///
/// The DFC PPV storefront. Premium grid layout showcasing:
///
///   • Featured events carousel at top
///   • Live & Upcoming events grid
///   • Presale events section
///   • Replay events section
///   • Responsive 2-column grid for mobile/tablet/web
///   • Social proof (purchase counts, trending badges)
///   • Filter & search functionality
///
/// Built to compete with Kayo, DAZN, ESPN+. DFC experience.
/// ═══════════════════════════════════════════════════════════════════════════

class PpvEventListScreen extends StatefulWidget {
  const PpvEventListScreen({super.key});

  @override
  State<PpvEventListScreen> createState() => _PpvEventListScreenState();
}

class _PpvEventListScreenState extends State<PpvEventListScreen> {
  final PPVService _ppvService = PPVService();

  List<PPVEvent> _allEvents = [];
  List<PPVEvent> _filteredEvents = [];
  bool _loading = true;
  String _activeFilter = 'all'; // all, live, upcoming, presale, replay
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);

    // Load PPV events from service
    final events = await _ppvService.getAllPPVEvents();

    if (mounted) {
      setState(() {
        _allEvents = events;
        _loading = false;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    final query = _searchCtrl.text.toLowerCase().trim();
    List<PPVEvent> filtered = _allEvents;

    // Filter by status
    if (_activeFilter != 'all') {
      filtered = filtered.where((e) {
        return switch (_activeFilter) {
          'live' => e.isLive,
          'upcoming' => e.status == PPVStatus.onSale && !e.isLive,
          'presale' => e.status == PPVStatus.presale,
          'replay' => e.status == PPVStatus.replay,
          _ => true,
        };
      }).toList();
    }

    // Filter by search query
    if (query.isNotEmpty) {
      filtered = filtered.where((e) {
        return e.title.toLowerCase().contains(query) ||
            (e.subtitle?.toLowerCase().contains(query) ?? false) ||
            e.promotion.toLowerCase().contains(query);
      }).toList();
    }

    // Sort: live first, then by date
    filtered.sort((a, b) {
      if (a.isLive != b.isLive) return a.isLive ? -1 : 1;
      return a.eventDate.compareTo(b.eventDate);
    });

    setState(() => _filteredEvents = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: _loading
          ? _buildLoadingState()
          : _filteredEvents.isEmpty
          ? _buildEmptyState()
          : CustomScrollView(
              slivers: [
                // ── Header + Search ──
                SliverAppBar(
                  backgroundColor: DesignTokens.bgPrimary,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  floating: true,
                  pinned: true,
                  title: const Text(
                    'PPV Events',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                // Search bar
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  sliver: SliverToBoxAdapter(child: _buildSearchBar()),
                ),
                // Filter pills
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  sliver: SliverToBoxAdapter(child: _buildFilterPills()),
                ),
                // Featured carousel (top event only)
                if (_filteredEvents.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 16),
                    sliver: SliverToBoxAdapter(child: _buildFeaturedSection()),
                  ),
                // Events grid
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getGridColumns(context),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.55,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final event = _filteredEvents[index];
                      return DFCPPVEventCard.standard(
                        event: event,
                        entranceIndex: index,
                        onTap: () => context.push(
                          '/ppv/event/${event.id}',
                          extra: event,
                        ),
                      );
                    }, childCount: _filteredEvents.length),
                  ),
                ),
              ],
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILDERS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.neonCyan),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading events...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_mma_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No events found',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back soon for upcoming PPV events',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchCtrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search events...',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        prefixIcon: Icon(
          Icons.search,
          color: Colors.white.withValues(alpha: 0.5),
        ),
        suffixIcon: _searchCtrl.text.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  _applyFilters();
                },
                child: Icon(
                  Icons.clear,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: DesignTokens.neonCyan,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildFilterPills() {
    final filters = [
      ('all', 'All Events'),
      ('live', 'Live Now'),
      ('upcoming', 'Upcoming'),
      ('presale', 'Presale'),
      ('replay', 'Replays'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final (key, label) = filter;
          final isActive = _activeFilter == key;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _activeFilter = key);
                _applyFilters();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? DesignTokens.neonCyan.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isActive
                        ? DesignTokens.neonCyan.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? DesignTokens.neonCyan
                        : Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    if (_filteredEvents.isEmpty) return const SizedBox.shrink();

    final featured = _filteredEvents.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Featured',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DesignTokens.neonGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: DesignTokens.neonGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'TOP PICK',
                  style: TextStyle(
                    color: DesignTokens.neonGreen,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DFCPPVEventCard.featured(
            event: featured,
            onTap: () =>
                context.push('/ppv/event/${featured.id}', extra: featured),
          ),
        ),
      ],
    );
  }

  int _getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }
}
