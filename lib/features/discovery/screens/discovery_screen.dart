import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/location_service.dart';
import '../../../shared/models/gym_model.dart';

/// DISCOVER - Premium Gym & Training Hub v3.0
/// DesignTokens - Animated - Search - Filter - Location
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late LocationService _locationService;
  late Future<List<GymModel>> _gymsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  bool _depsInitialized = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<String> _filters = [
    'All',
    'MMA',
    'Boxing',
    'BJJ',
    'Muay Thai',
    'Wrestling',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsInitialized) {
      _depsInitialized = true;
      _locationService = context.read<LocationService>();
      _gymsFuture = _locationService.getNearbyGyms(37.427, -122.085);
    }
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildSearchHeader(),
              _buildFilterChips(),
              Expanded(
                child: FutureBuilder<List<GymModel>>(
                  future: _gymsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: DesignTokens.neonCyan,
                        ),
                      );
                    }

                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    final gyms = _filterGyms(snapshot.data!);

                    return ListView(
                      padding: const EdgeInsets.all(DesignTokens.spacingL),
                      children: [
                        _buildQuickActions(),
                        const SizedBox(height: DesignTokens.spacingXXL),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Nearby Training Centers',
                              style: TextStyle(
                                color: DesignTokens.textPrimary,
                                fontSize: DesignTokens.fontSizeTitle,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${gyms.length} found',
                              style: const TextStyle(
                                color: DesignTokens.neonCyan,
                                fontSize: DesignTokens.fontSizeSubtitle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DesignTokens.spacingL),
                        ...gyms.map(
                          (gym) => _GymCard(
                            gym: gym,
                            onViewDetails: () => _showGymDetails(gym),
                            onBookTrial: () => _showBookTrialDialog(gym),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.explore, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DISCOVER',
                      style: TextStyle(
                        color: DesignTokens.textPrimary,
                        fontSize: DesignTokens.fontSizeTitle,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'Find gyms, coaches & training partners',
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeCaption,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingL),
          Container(
            decoration: BoxDecoration(
              color: DesignTokens.bgSecondary,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              border: Border.all(
                color: DesignTokens.neonCyan.withValues(alpha: 0.2),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: DesignTokens.fontSizeBody,
              ),
              decoration: InputDecoration(
                hintText: 'Search gyms, fighters, events...',
                hintStyle: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeBody,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: DesignTokens.neonCyan,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune, color: DesignTokens.textMuted),
                  onPressed: _showFilterPanel,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingL),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                      : DesignTokens.bgCard,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                  border: Border.all(
                    color: isSelected
                        ? DesignTokens.neonCyan
                        : DesignTokens.textDisabled,
                    width: DesignTokens.borderThin,
                  ),
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected
                          ? DesignTokens.neonCyan
                          : DesignTokens.textMuted,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: DesignTokens.fontSizeSubtitleLarge,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.storefront,
            title: 'Marketplace',
            subtitle: 'Find opportunities',
            color: DesignTokens.neonCyan,
            onTap: () => context.push('/marketplace'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.handshake,
            title: 'Partner Portal',
            subtitle: 'Brand collaborations',
            color: DesignTokens.neonMagenta,
            onTap: () => context.push('/partner'),
          ),
        ),
      ],
    );
  }

  void _showFilterPanel() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Discovery',
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeTitle,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingM),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _selectedFilter = filter);
                        Navigator.of(context).pop();
                      },
                      selectedColor: DesignTokens.neonCyan.withValues(
                        alpha: 0.2,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? DesignTokens.neonCyan
                            : DesignTokens.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? DesignTokens.neonCyan
                            : DesignTokens.textDisabled,
                      ),
                      backgroundColor: DesignTokens.bgSecondary,
                    );
                  }).toList(),
                ),
                const SizedBox(height: DesignTokens.spacingL),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedFilter = 'All';
                        _searchController.clear();
                      });
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DesignTokens.neonCyan,
                      side: const BorderSide(color: DesignTokens.neonCyan),
                    ),
                    child: const Text('Reset Filters'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGymDetails(GymModel gym) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gym.name,
                    style: const TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: DesignTokens.fontSizeTitle,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    gym.fullAddress.isNotEmpty
                        ? gym.fullAddress
                        : 'Address unavailable',
                    style: const TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: DesignTokens.fontSizeBody,
                    ),
                  ),
                  if (gym.description != null &&
                      gym.description!.isNotEmpty) ...[
                    const SizedBox(height: DesignTokens.spacingM),
                    Text(
                      gym.description!,
                      style: const TextStyle(color: DesignTokens.textSecondary),
                    ),
                  ],
                  const SizedBox(height: DesignTokens.spacingM),
                  const Text(
                    'Sports',
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: gym.sportTypes
                        .map(
                          (sport) => Chip(
                            label: Text(sport),
                            labelStyle: const TextStyle(
                              color: DesignTokens.neonCyan,
                            ),
                            backgroundColor: DesignTokens.neonCyan.withValues(
                              alpha: 0.1,
                            ),
                            side: BorderSide.none,
                          ),
                        )
                        .toList(),
                  ),
                  if (gym.amenities.isNotEmpty) ...[
                    const SizedBox(height: DesignTokens.spacingM),
                    const Text(
                      'Amenities',
                      style: TextStyle(
                        color: DesignTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      gym.amenities.join(' • '),
                      style: const TextStyle(color: DesignTokens.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showBookTrialDialog(GymModel gym) async {
    final nameController = TextEditingController();
    final contactController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: DesignTokens.bgCard,
          title: Text(
            'Book Trial: ${gym.name}',
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: DesignTokens.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Your name',
                  labelStyle: TextStyle(color: DesignTokens.textMuted),
                ),
              ),
              TextField(
                controller: contactController,
                style: const TextStyle(color: DesignTokens.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Phone or email',
                  labelStyle: TextStyle(color: DesignTokens.textMuted),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final contact = contactController.text.trim();
                if (name.isEmpty || contact.isEmpty) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter your name and contact to continue.'),
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Trial request sent to ${gym.name}. We will notify you when they respond.',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.neonCyan,
                foregroundColor: Colors.black,
              ),
              child: const Text('Send Request'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    contactController.dispose();
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: DesignTokens.textMuted),
          SizedBox(height: 16),
          Text(
            'No gyms found nearby',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeBody,
            ),
          ),
        ],
      ),
    );
  }

  List<GymModel> _filterGyms(List<GymModel> gyms) {
    var filtered = gyms;
    if (_selectedFilter != 'All') {
      filtered = filtered.where((gym) {
        return gym.sportTypes.any(
          (sport) =>
              sport.toLowerCase().contains(_selectedFilter.toLowerCase()),
        );
      }).toList();
    }
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((gym) {
        return gym.name.toLowerCase().contains(query) ||
            (gym.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    return filtered;
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: DesignTokens.fontSizeBody,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: DesignTokens.fontSizeCaption,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _GymCard extends StatelessWidget {
  const _GymCard({
    required this.gym,
    required this.onViewDetails,
    required this.onBookTrial,
  });

  final GymModel gym;
  final VoidCallback onViewDetails;
  final VoidCallback onBookTrial;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingL),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.1),
          width: DesignTokens.borderThin,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  DesignTokens.neonCyan.withValues(alpha: 0.08),
                  DesignTokens.neonMagenta.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DesignTokens.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      gym.name.isNotEmpty ? gym.name[0].toUpperCase() : 'G',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: DesignTokens.fontSizeStatLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gym.name,
                        style: const TextStyle(
                          color: DesignTokens.textPrimary,
                          fontSize: DesignTokens.fontSizeTitle,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: DesignTokens.neonCyan,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              gym.address ?? 'Las Vegas, NV',
                              style: const TextStyle(
                                color: DesignTokens.textMuted,
                                fontSize: DesignTokens.fontSizeSubtitle,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
                        'Verified',
                        style: TextStyle(
                          color: DesignTokens.neonGreen,
                          fontSize: DesignTokens.fontSizeCaption,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingL,
              vertical: DesignTokens.spacingM,
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: gym.sportTypes.take(4).map((sport) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusPill,
                    ),
                    border: Border.all(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    sport,
                    style: const TextStyle(
                      color: DesignTokens.neonCyan,
                      fontSize: DesignTokens.fontSizeSubtitle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (gym.description != null && gym.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingL,
              ),
              child: Text(
                gym.description!,
                style: const TextStyle(
                  color: DesignTokens.textSecondary,
                  fontSize: DesignTokens.fontSizeSubtitleLarge,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DesignTokens.neonCyan,
                      side: const BorderSide(color: DesignTokens.neonCyan),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusSmall,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onBookTrial,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Book Trial'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.neonCyan,
                      foregroundColor: DesignTokens.bgPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusSmall,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
}
