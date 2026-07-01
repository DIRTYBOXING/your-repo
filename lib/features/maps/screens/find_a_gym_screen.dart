import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/web_route_test_hook.dart';
import '../../../shared/services/gym_finder_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// 🏟️ FIND A GYM — Elite Combat Gym Discovery
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Makes UFC Gym's basic "Find a Gym" page look ancient:
///  • Glassmorphic search bar with live filtering
///  • Discipline chip strip (14 combat sports)
///  • Tier-badged gym cards with neon accents
///  • "OPEN NOW" / verified badges
///  • Top fighters listed per gym
///  • Coach count, fighter count, rating, distance
///  • Sort by rating / distance / fighters / name
///  • One-tap call, website, directions, trial booking
///  • Full gym detail bottom sheet
///
/// ═══════════════════════════════════════════════════════════════════════════
class FindAGymScreen extends StatefulWidget {
  const FindAGymScreen({super.key});

  @override
  State<FindAGymScreen> createState() => _FindAGymScreenState();
}

class _FindAGymScreenState extends State<FindAGymScreen>
    with SingleTickerProviderStateMixin {
  final _service = GymFinderService();
  final _searchCtrl = TextEditingController();
  late AnimationController _shimmerCtrl;
  GymSortMode _sort = GymSortMode.rating;
  bool _verifiedOnly = false;

  @override
  void initState() {
    super.initState();
    setWebRouteTestHook('gym-card-list');
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _fetchUserLocationThenSearch();
    _service.addListener(_onUpdate);
  }

  Future<void> _fetchUserLocationThenSearch() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.denied &&
          perm != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
        _service.setUserLocation(pos.latitude, pos.longitude);
      }
    } catch (_) {
      // Fall back to default (Las Vegas)
    }
    _service.search();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onUpdate);
    _searchCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  void _doSearch() {
    _service.search(
      query: _searchCtrl.text.trim(),
      discipline: _service.activeDiscipline,
      sort: _sort,
      verifiedOnly: _verifiedOnly,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'data-test=gym-card-list',
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Semantics(
                label: 'data-test=gym-finder',
                child: const SizedBox(width: 1, height: 1),
              ),
            ),
            CustomScrollView(
              slivers: [
                _buildAppBar(),
                _buildSearchBar(),
                _buildDisciplineChips(),
                _buildSortRow(),
                if (_service.loading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.neonCyan,
                      ),
                    ),
                  )
                else if (_service.results.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState())
                else
                  _buildGymList(),
                const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.bg,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.neonCyan),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1628), Color(0xFF060A14), Color(0xFF0F1B33)],
            ),
          ),
          child: Stack(
            children: [
              // Grid overlay
              Positioned.fill(child: CustomPaint(painter: _GridPainter())),
              // Title
              Positioned(
                bottom: 60,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.neonCyan, AppColors.neonBlue],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FIND A GYM',
                                style: TextStyle(
                                  color: AppColors.neonCyan,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                              Text(
                                'Global Combat Sports Directory',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.neonCyan.withValues(alpha: 0.15),
            ),
          ),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search gyms, cities, or fighters...',
              hintStyle: TextStyle(
                color: AppColors.textTertiary.withValues(alpha: 0.7),
              ),
              prefixIcon: const Icon(Icons.search, color: AppColors.neonCyan),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppColors.textTertiary,
                      ),
                      onPressed: () {
                        _searchCtrl.clear();
                        _doSearch();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onSubmitted: (_) => _doSearch(),
            onChanged: (_) => _doSearch(),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DISCIPLINE CHIPS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDisciplineChips() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 48,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          itemCount: GymFinderService.disciplines.length,
          itemBuilder: (context, i) {
            final d = GymFinderService.disciplines[i];
            final active = _service.activeDiscipline == d;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  _service.search(
                    query: _searchCtrl.text.trim(),
                    discipline: d,
                    sort: _sort,
                    verifiedOnly: _verifiedOnly,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: active
                        ? const LinearGradient(
                            colors: [AppColors.neonCyan, AppColors.neonBlue],
                          )
                        : null,
                    color: active ? null : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active
                          ? Colors.transparent
                          : AppColors.border.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        color: active ? Colors.black : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SORT ROW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSortRow() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Text(
              '${_service.results.length} gyms found',
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            // Verified toggle
            GestureDetector(
              onTap: () {
                _verifiedOnly = !_verifiedOnly;
                _doSearch();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _verifiedOnly
                      ? AppColors.neonCyan.withValues(alpha: 0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _verifiedOnly
                        ? AppColors.neonCyan.withValues(alpha: 0.5)
                        : AppColors.border.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified,
                      size: 14,
                      color: _verifiedOnly
                          ? AppColors.neonCyan
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(
                        color: _verifiedOnly
                            ? AppColors.neonCyan
                            : AppColors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Sort dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.3),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<GymSortMode>(
                  value: _sort,
                  isDense: true,
                  dropdownColor: AppColors.elevated,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  icon: const Icon(
                    Icons.sort,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: GymSortMode.rating,
                      child: Text('Top Rated'),
                    ),
                    DropdownMenuItem(
                      value: GymSortMode.distance,
                      child: Text('Nearest'),
                    ),
                    DropdownMenuItem(
                      value: GymSortMode.fighters,
                      child: Text('Most Fighters'),
                    ),
                    DropdownMenuItem(
                      value: GymSortMode.name,
                      child: Text('A – Z'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      _sort = v;
                      _doSearch();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GYM LIST
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildGymList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _GymCard(
              gym: _service.results[i],
              onTap: () => _showGymDetail(_service.results[i]),
            ),
          ),
          childCount: _service.results.length,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No gyms found',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or filters',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GYM DETAIL BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════════════════

  void _showGymDetail(GymFinderResult gym) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GymDetailSheet(gym: gym),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GYM CARD
// ═══════════════════════════════════════════════════════════════════════════

class _GymCard extends StatelessWidget {
  final GymFinderResult gym;
  final VoidCallback onTap;

  const _GymCard({required this.gym, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'data-test=gym-card-${gym.id}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: gym.tier == GymTier.diamond
                  ? AppColors.neonCyan.withValues(alpha: 0.25)
                  : AppColors.border.withValues(alpha: 0.2),
            ),
            boxShadow: [
              if (gym.tier == GymTier.diamond)
                BoxShadow(
                  color: AppColors.neonCyan.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with tier badge
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    // Gym icon / initials
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            gym.tier.color.withValues(alpha: 0.8),
                            gym.tier.color.withValues(alpha: 0.4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          gym.name.isNotEmpty
                              ? gym.name
                                    .split(' ')
                                    .where(
                                      (w) =>
                                          w.isNotEmpty &&
                                          w[0] == w[0].toUpperCase() &&
                                          w != '—',
                                    )
                                    .take(2)
                                    .map((w) => w[0])
                                    .join()
                              : '?',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name & location
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  gym.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (gym.isVerified) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified,
                                  color: AppColors.neonCyan,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                gym.countryFlag,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  gym.locationLabel,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Badges column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Tier badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: gym.tier.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: gym.tier.color.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                gym.tier.icon,
                                size: 12,
                                color: gym.tier.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                gym.tier.label.toUpperCase(),
                                style: TextStyle(
                                  color: gym.tier.color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Open/closed badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: gym.isOpen
                                ? AppColors.neonGreen.withValues(alpha: 0.12)
                                : AppColors.neonRed.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            gym.isOpen ? 'OPEN' : 'CLOSED',
                            style: TextStyle(
                              color: gym.isOpen
                                  ? AppColors.neonGreen
                                  : AppColors.neonRed,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Discipline chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: gym.disciplines.take(5).map((d) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        d,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Stats row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    _StatChip(
                      icon: Icons.star,
                      label: '${gym.rating}',
                      color: AppColors.neonAmber,
                    ),
                    const SizedBox(width: 6),
                    _StatChip(
                      icon: Icons.rate_review_outlined,
                      label: '${gym.reviewCount}',
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    _StatChip(
                      icon: Icons.sports_mma,
                      label: '${gym.fighterCount}',
                      color: AppColors.neonOrange,
                    ),
                    const SizedBox(width: 6),
                    _StatChip(
                      icon: Icons.school,
                      label: '${gym.coachCount} coaches',
                      color: AppColors.neonPurple,
                    ),
                    const Spacer(),
                    if (gym.distanceKm > 0)
                      Text(
                        gym.distanceLabel,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),

              // Top fighters (if any)
              if (gym.topFighters.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.military_tech,
                        size: 14,
                        color: AppColors.neonAmber.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          gym.topFighters.take(3).join(' · '),
                          style: TextStyle(
                            color: AppColors.neonAmber.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // Trial badge & CTA
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Row(
                  children: [
                    if (gym.trialAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.neonCyan, AppColors.neonBlue],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flash_on, size: 13, color: Colors.black),
                            SizedBox(width: 4),
                            Text(
                              'FREE TRIAL',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neonCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.neonCyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'VIEW DETAILS',
                            style: TextStyle(
                              color: AppColors.neonCyan,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 10,
                            color: AppColors.neonCyan,
                          ),
                        ],
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
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GYM DETAIL BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _GymDetailSheet extends StatelessWidget {
  final GymFinderResult gym;

  const _GymDetailSheet({required this.gym});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: EdgeInsets.zero,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Hero header
              _buildHeroHeader(),

              // Quick actions
              _buildQuickActions(context),

              // Description
              if (gym.description.isNotEmpty)
                _buildSection('About', gym.description),

              // Top fighters
              if (gym.topFighters.isNotEmpty) _buildFighterChips(),

              // Disciplines
              _buildDisciplineGrid(),

              // Amenities
              if (gym.amenities.isNotEmpty) _buildAmenityGrid(),

              // Operating hours
              if (gym.operatingHours.isNotEmpty) _buildHoursSection(),

              // Contact info
              _buildContactSection(),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gym.tier.color.withValues(alpha: 0.12),
            AppColors.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gym.tier.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Large gym icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      gym.tier.color,
                      gym.tier.color.withValues(alpha: 0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    gym.name
                        .split(' ')
                        .where(
                          (w) =>
                              w.isNotEmpty &&
                              w[0] == w[0].toUpperCase() &&
                              w != '—',
                        )
                        .take(2)
                        .map((w) => w[0])
                        .join(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            gym.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (gym.isVerified) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.verified,
                            color: AppColors.neonCyan,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          gym.countryFlag,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            gym.locationLabel,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _DetailStat(
                icon: Icons.star,
                value: '${gym.rating}',
                label: '${gym.reviewCount} reviews',
                color: AppColors.neonAmber,
              ),
              _DetailStat(
                icon: Icons.sports_mma,
                value: '${gym.fighterCount}',
                label: 'Fighters',
                color: AppColors.neonOrange,
              ),
              _DetailStat(
                icon: Icons.school,
                value: '${gym.coachCount}',
                label: 'Coaches',
                color: AppColors.neonPurple,
              ),
              _DetailStat(
                icon: gym.tier.icon,
                value: gym.tier.label,
                label: 'Tier',
                color: gym.tier.color,
              ),
            ],
          ),

          // Open/closed + trial
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: gym.isOpen
                      ? AppColors.neonGreen.withValues(alpha: 0.12)
                      : AppColors.neonRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      gym.isOpen ? Icons.check_circle : Icons.cancel,
                      size: 14,
                      color: gym.isOpen
                          ? AppColors.neonGreen
                          : AppColors.neonRed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      gym.isOpen ? 'OPEN NOW' : 'CLOSED',
                      style: TextStyle(
                        color: gym.isOpen
                            ? AppColors.neonGreen
                            : AppColors.neonRed,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (gym.trialAvailable) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.neonCyan, AppColors.neonBlue],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flash_on, size: 14, color: Colors.black),
                      SizedBox(width: 4),
                      Text(
                        'FREE TRIAL AVAILABLE',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          if (gym.phone.isNotEmpty)
            Expanded(
              child: _ActionButton(
                icon: Icons.call,
                label: 'CALL',
                gradient: const [AppColors.neonGreen, Color(0xFF00C853)],
                onTap: () => _launchUrl('tel:${gym.phone}'),
              ),
            ),
          if (gym.phone.isNotEmpty) const SizedBox(width: 8),
          if (gym.website.isNotEmpty)
            Expanded(
              child: _ActionButton(
                icon: Icons.language,
                label: 'WEBSITE',
                gradient: const [AppColors.neonCyan, AppColors.neonBlue],
                onTap: () => _launchUrl(gym.website),
              ),
            ),
          if (gym.website.isNotEmpty) const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              icon: Icons.directions,
              label: 'DIRECTIONS',
              gradient: const [AppColors.neonOrange, AppColors.neonPink],
              onTap: () => _launchUrl(
                'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(gym.address)}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.neonCyan,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFighterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NOTABLE FIGHTERS',
            style: TextStyle(
              color: AppColors.neonCyan,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: gym.topFighters.map((f) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.neonAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.neonAmber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.military_tech,
                      size: 14,
                      color: AppColors.neonAmber,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      f,
                      style: const TextStyle(
                        color: AppColors.neonAmber,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDisciplineGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DISCIPLINES',
            style: TextStyle(
              color: AppColors.neonCyan,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: gym.disciplines.map((d) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.neonCyan.withValues(alpha: 0.1),
                      AppColors.neonBlue.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  d,
                  style: const TextStyle(
                    color: AppColors.neonCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AMENITIES',
            style: TextStyle(
              color: AppColors.neonCyan,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: gym.amenities.map((a) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_amenityIcon(a), size: 14, color: AppColors.neonGreen),
                    const SizedBox(width: 6),
                    Text(
                      a,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _amenityIcon(String amenity) {
    final key = amenity.toLowerCase();
    if (key.contains('cage')) return Icons.sports_mma;
    if (key.contains('ring')) return Icons.sports_kabaddi;
    if (key.contains('weight')) return Icons.fitness_center;
    if (key.contains('cardio')) return Icons.directions_run;
    if (key.contains('sauna')) return Icons.hot_tub;
    if (key.contains('ice') || key.contains('cryo')) return Icons.ac_unit;
    if (key.contains('recovery')) return Icons.healing;
    if (key.contains('shop')) return Icons.store;
    if (key.contains('juice') || key.contains('bar')) return Icons.local_bar;
    if (key.contains('locker') || key.contains('shower')) return Icons.shower;
    if (key.contains('parking')) return Icons.local_parking;
    if (key.contains('kid')) return Icons.child_care;
    if (key.contains('women')) return Icons.female;
    if (key.contains('mat')) return Icons.layers;
    if (key.contains('sparring')) return Icons.sports_kabaddi;
    if (key.contains('housing')) return Icons.home;
    if (key.contains('heavy') || key.contains('bag')) return Icons.sports;
    if (key.contains('speed')) return Icons.speed;
    return Icons.check_circle_outline;
  }

  Widget _buildHoursSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OPERATING HOURS',
            style: TextStyle(
              color: AppColors.neonCyan,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: gym.operatingHours.entries.map((e) {
                final isClosed = e.value.toLowerCase() == 'closed';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          e.key,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        e.value,
                        style: TextStyle(
                          color: isClosed
                              ? AppColors.neonRed.withValues(alpha: 0.7)
                              : AppColors.textPrimary,
                          fontSize: 13,
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
    );
  }

  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONTACT',
            style: TextStyle(
              color: AppColors.neonCyan,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                if (gym.address.isNotEmpty)
                  _ContactRow(icon: Icons.location_on, text: gym.address),
                if (gym.phone.isNotEmpty)
                  _ContactRow(
                    icon: Icons.phone,
                    text: gym.phone,
                    onTap: () => _launchUrl('tel:${gym.phone}'),
                  ),
                if (gym.website.isNotEmpty)
                  _ContactRow(
                    icon: Icons.language,
                    text: gym.website
                        .replaceAll('https://', '')
                        .replaceAll('http://', ''),
                    onTap: () => _launchUrl(gym.website),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _DetailStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 10),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.black),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _ContactRow({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.neonCyan),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: onTap != null
                      ? AppColors.neonCyan
                      : AppColors.textSecondary,
                  fontSize: 13,
                  decoration: onTap != null ? TextDecoration.underline : null,
                  decorationColor: AppColors.neonCyan,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRID PAINTER (background)
// ═══════════════════════════════════════════════════════════════════════════

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neonCyan.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    const spacing = 30.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
