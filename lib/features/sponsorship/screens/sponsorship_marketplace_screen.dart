import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/sponsorship_model.dart';
import '../../../shared/services/sponsorship_service.dart';
import '../../../shared/widgets/dfc_network_image.dart';

/// Sponsorship Marketplace — Browse & apply for brand deals
class SponsorshipMarketplaceScreen extends StatefulWidget {
  const SponsorshipMarketplaceScreen({super.key});

  @override
  State<SponsorshipMarketplaceScreen> createState() =>
      _SponsorshipMarketplaceScreenState();
}

class _SponsorshipMarketplaceScreenState
    extends State<SponsorshipMarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  SponsorshipCategory? _selectedCategory;
  double? _minValue;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<SponsorshipService>();

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [AppTheme.neonCyan, AppTheme.neonMagenta],
          ).createShader(b),
          child: const Text(
            'SPONSORSHIP DEALS',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppTheme.neonCyan),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.neonCyan,
          labelColor: AppTheme.neonCyan,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'BROWSE'),
            Tab(text: 'MY APPLIED'),
            Tab(text: 'ACTIVE'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.15),
              ),
            ),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search deals...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppTheme.neonCyan.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Filters
          if (_showFilters) _buildFilterPanel(),
          // Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBrowseTab(service),
                _buildAppliedTab(service),
                _buildActiveTab(service),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _categoryChip('All', null),
              ...SponsorshipCategory.values.map(
                (cat) => _categoryChip(
                  cat.toString().split('.').last.toUpperCase(),
                  cat,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Minimum Value',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Slider(
              value: _minValue ?? 0,
              max: 10000,
              divisions: 20,
              activeColor: AppTheme.neonCyan,
              onChanged: (v) => setState(() => _minValue = v),
            ),
          ),
          Text(
            '\$${(_minValue ?? 0).toStringAsFixed(0)}/month minimum',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, SponsorshipCategory? category) {
    final selected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.neonCyan.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.neonCyan.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.neonCyan : Colors.white70,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBrowseTab(SponsorshipService service) {
    return FutureBuilder<List<Sponsorship>>(
      future: service.getOpenSponsorships(
        categoryFilter: _selectedCategory,
        minValue: _minValue,
      ),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.neonCyan),
          );
        }

        if (!snap.hasData || snap.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 12),
                Text(
                  'No deals available',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final deals = snap.data!;
        final filtered = _searchCtrl.text.isEmpty
            ? deals
            : deals
                  .where(
                    (d) =>
                        d.title.toLowerCase().contains(
                          _searchCtrl.text.toLowerCase(),
                        ) ||
                        d.brandName.toLowerCase().contains(
                          _searchCtrl.text.toLowerCase(),
                        ),
                  )
                  .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (_, i) => _sponsorshipCard(filtered[i], context),
        );
      },
    );
  }

  Widget _buildAppliedTab(SponsorshipService service) {
    // Fighter ID from auth — using placeholder until auth wired
    return FutureBuilder<List<Sponsorship>>(
      future: service.getFighterApplications(fighterId: 'current_fighter_id'),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.neonCyan),
          );
        }

        if (!snap.hasData || snap.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No applications yet',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snap.data!.length,
          itemBuilder: (_, i) => _sponsorshipCard(snap.data![i], context),
        );
      },
    );
  }

  Widget _buildActiveTab(SponsorshipService service) {
    // Fighter ID from auth — using placeholder until auth wired
    return FutureBuilder<List<Sponsorship>>(
      future: service.getFighterSponsorships(fighterId: 'current_fighter_id'),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.neonCyan),
          );
        }

        if (!snap.hasData || snap.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.handshake_outlined,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No active sponsorships',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final active = snap.data!.where((s) => s.isActive).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: active.length,
          itemBuilder: (_, i) => _sponsorshipCard(active[i], context),
        );
      },
    );
  }

  Widget _sponsorshipCard(Sponsorship deal, BuildContext context) {
    final categoryColor = deal.isVerified
        ? AppTheme.neonGreen
        : AppTheme.neonCyan;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: categoryColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand header
          Row(
            children: [
              DfcCircleAvatar(
                imageUrl: deal.brandLogo,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                fallbackIcon: Icons.storefront,
                fallbackIconColor: categoryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deal.brandName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    if (deal.isVerified)
                      Row(
                        children: [
                          const Icon(
                            Icons.verified,
                            size: 12,
                            color: AppTheme.neonGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${deal.rating.toStringAsFixed(1)}⭐',
                            style: const TextStyle(
                              color: AppTheme.neonGreen,
                              fontSize: 11,
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
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  deal.category.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    color: categoryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Deal title
          Text(
            deal.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          // Description
          Text(
            deal.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          // Value + Duration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${deal.valueUSD.toStringAsFixed(0)}/mo',
                    style: const TextStyle(
                      color: AppTheme.neonCyan,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${deal.durationMonths} months',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              if (deal.applicantCount != null && deal.applicantCount! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.neonMagenta.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${deal.applicantCount} applied',
                    style: const TextStyle(
                      color: AppTheme.neonMagenta,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // Apply logic — brand reviews profile
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Applied! Brand will review your profile.'),
                  ),
                );
              },
              child: const Text(
                'APPLY NOW',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
