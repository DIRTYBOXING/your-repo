import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/image_assets.dart';

class _SmartDeviceListing {
  final String name, subtitle, price, brand;
  final IconData icon;
  final Color accentColor;
  const _SmartDeviceListing(
    this.name,
    this.subtitle,
    this.price,
    this.icon,
    this.accentColor,
    this.brand,
  );
}

/// Returns a branded DFC image asset based on marketplace category.
String _marketplaceImageUrl(String category) {
  final cat = category.toLowerCase();
  if (cat.contains('equipment') ||
      cat.contains('glove') ||
      cat.contains('gear') ||
      cat.contains('apparel') ||
      cat.contains('guard') ||
      cat.contains('bag') ||
      cat.contains('wrap') ||
      cat.contains('accessori')) {
    return 'assets/dfc_backgrounds/new_dfc_image_1.png';
  }
  if (cat.contains('service') ||
      cat.contains('coaching') ||
      cat.contains('training') ||
      cat.contains('nutrition') ||
      cat.contains('recovery') ||
      cat.contains('media') ||
      cat.contains('massage') ||
      cat.contains('meal')) {
    return 'assets/dfc_backgrounds/dfc2_image.png';
  }
  if (cat.contains('fighter') ||
      cat.contains('sparring') ||
      cat.contains('mma')) {
    return 'assets/dfc_backgrounds/dfc_and_back_ground.png';
  }
  if (cat.contains('gym') || cat.contains('fitness')) {
    return 'assets/dfc_backgrounds/datafight_central_with_logo.png';
  }
  if (cat.contains('drone') ||
      cat.contains('tech') ||
      cat.contains('fpv') ||
      cat.contains('camera')) {
    return 'assets/dfc_backgrounds/dfc2_image_.png';
  }
  return ImageAssets.dfcBrandedPlaceholder;
}

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT MARKETPLACE — Buy/Sell Equipment, Services, Fighters, Everything Combat
/// Full commerce with analytics graphs and marketplace intelligence
/// ═══════════════════════════════════════════════════════════════════════════

class FightMarketplaceScreen extends StatefulWidget {
  const FightMarketplaceScreen({super.key});

  @override
  State<FightMarketplaceScreen> createState() => _FightMarketplaceScreenState();
}

class _FightMarketplaceScreenState extends State<FightMarketplaceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _sortBy = 'Popular';

  static const int _tabCount = 8;

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
    _tabController = TabController(length: _tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                _buildMarketStats(),
                _buildFilters(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllTab(),
                      _buildEquipmentTab(),
                      _buildServicesTab(),
                      _buildFightersTab(),
                      _buildGymsTab(),
                      _buildDronesTechTab(),
                      _buildSmartDevicesTab(),
                      _buildAnalyticsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'marketplace_fab',
        onPressed: _showCreateListing,
        backgroundColor: DesignTokens.neonCyan,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'Sell',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _goBackSafely,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [DesignTokens.neonAmber, DesignTokens.neonRed],
                  ).createShader(bounds),
                  child: const Text(
                    'FIGHT MARKETPLACE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Text(
                  'Buy · Sell · Train · Fight',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          _headerAction(Icons.shopping_cart_outlined, '3'),
          const SizedBox(width: 8),
          _headerAction(Icons.notifications_outlined, '7'),
        ],
      ),
    );
  }

  void _showProductSheet(
    String title,
    String price, {
    String? subtitle,
    Color? accent,
  }) {
    final c = accent ?? DesignTokens.neonCyan;
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              price,
              style: TextStyle(
                color: c,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$title added to cart!'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [c, c.withValues(alpha: 0.7)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ADD TO CART',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Saved $title to wishlist'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text(
                        'SAVE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _headerAction(IconData icon, String badge) {
    return GestureDetector(
      onTap: () {
        final label = icon == Icons.shopping_cart_outlined
            ? 'Cart'
            : 'Notifications';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label — browse listings below to get started!'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: DesignTokens.neonRed,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(
              Icons.search,
              color: Colors.white.withValues(alpha: 0.3),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search gloves, coaches, gym memberships...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 12,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (query) {
                  if (query.trim().isEmpty) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Searching "$query"...'),
                      backgroundColor: DesignTokens.neonCyan,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: DesignTokens.neonCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.tune, color: DesignTokens.neonCyan, size: 12),
                  SizedBox(width: 3),
                  Text(
                    'Filter',
                    style: TextStyle(
                      color: DesignTokens.neonCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
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

  Widget _buildMarketStats() {
    return Container(
      height: 60,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          _marketStat(
            'Listed',
            '2,847',
            DesignTokens.neonCyan,
            Icons.storefront,
          ),
          _marketStat(
            'Sold Today',
            '156',
            DesignTokens.neonGreen,
            Icons.check_circle,
          ),
          _marketStat(
            'Avg Price',
            '\$89',
            DesignTokens.neonAmber,
            Icons.attach_money,
          ),
          _marketStat(
            'Active Sellers',
            '934',
            DesignTokens.neonMagenta,
            Icons.people,
          ),
        ],
      ),
    );
  }

  Widget _marketStat(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 10),
                const SizedBox(width: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _filterChip(
            'Popular',
            _sortBy == 'Popular',
            () => setState(() => _sortBy = 'Popular'),
          ),
          _filterChip(
            'Newest',
            _sortBy == 'Newest',
            () => setState(() => _sortBy = 'Newest'),
          ),
          _filterChip(
            'Price ↓',
            _sortBy == 'Price ↓',
            () => setState(() => _sortBy = 'Price ↓'),
          ),
          _filterChip(
            'Price ↑',
            _sortBy == 'Price ↑',
            () => setState(() => _sortBy = 'Price ↑'),
          ),
          const Spacer(),
          _filterChip('All Prices', true, () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Showing all prices'),
                duration: Duration(seconds: 1),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? DesignTokens.neonCyan.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? DesignTokens.neonCyan.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? DesignTokens.neonCyan
                : Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: DesignTokens.neonAmber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: DesignTokens.neonAmber,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'ALL'),
          Tab(text: 'EQUIPMENT'),
          Tab(text: 'SERVICES'),
          Tab(text: 'FIGHTERS'),
          Tab(text: 'GYMS'),
          Tab(text: 'TRAINING & SPORTS'),
          Tab(text: 'SMART DEVICES'),
          Tab(text: 'ANALYTICS'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════
  // 🏋️ TRAINING & SPORTS TAB — Gear, Tech, Drones & Wholesale
  // ═══════════════════════════════════════════════════════
  Widget _buildDronesTechTab() {
    return DefaultTabController(
      length: 7,
      child: Column(
        children: [
          Container(
            color: const Color(0xFF0A0E18),
            child: const TabBar(
              isScrollable: true,
              indicatorColor: Color(0xFFFF6B00),
              labelColor: Color(0xFFFF6B00),
              unselectedLabelColor: Colors.white54,
              tabs: [
                Tab(text: 'ALL'),
                Tab(text: 'FIGHT GEAR'),
                Tab(text: 'TRAINING TECH'),
                Tab(text: 'RACE DRONES'),
                Tab(text: 'PARTS'),
                Tab(text: 'WHOLESALE'),
                Tab(text: 'CAMERAS'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTrainingSportsAllTab(),
                _buildFightGearTab(),
                _buildTrainingTechTab(),
                _buildRaceDronesTab(),
                _buildDronePartsTab(),
                _buildWholesaleTab(),
                _buildDroneCamerasTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingSportsAllTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hero wholesale banner
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B00), Color(0xFFFFD600)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.store, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'DFC DRONE WHOLESALE HUB',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Bulk pricing · Race-ready builds · Parts · FPV kits · Team orders',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _droneStatPill('840+ Products'),
                  const SizedBox(width: 8),
                  _droneStatPill('Wholesale from \$12'),
                  const SizedBox(width: 8),
                  _droneStatPill('24h Ship'),
                ],
              ),
            ],
          ),
        ),
        _sectionTitle('TOP SELLERS'),
        const SizedBox(height: 8),
        _droneCard(
          'DJI Avata 2 — FPV Combat',
          'Goggles 3 + RC Motion 3 combo',
          '\$799',
          '\$649 wholesale 5+',
          Icons.flight,
          const Color(0xFF00B4D8),
          hot: true,
        ),
        _droneCard(
          'iFlight Nazgul5 HD v4',
          '5" freestyle racer, F7 stack, 40A ESC',
          '\$289',
          '\$239 wholesale 3+',
          Icons.rocket_launch,
          const Color(0xFFFF6B00),
          hot: true,
        ),
        _droneCard(
          'BetaFPV Cetus Pro',
          'Micro brushless whoop — beginners to pros',
          '\$89',
          '\$69 wholesale 10+',
          Icons.flight_takeoff,
          const Color(0xFF00FF88),
        ),
        _droneCard(
          'Holybro Kakute H7',
          'F7 FC + 45A 4-in-1 ESC stack',
          '\$79',
          '\$62 wholesale 5+',
          Icons.developer_board,
          const Color(0xFF8338EC),
        ),
        _droneCard(
          'Eachine Falcon 250 Kit',
          'RTF 250mm race quad — complete kit',
          '\$119',
          '\$89 wholesale 5+',
          Icons.sports_motorsports,
          const Color(0xFFFFD600),
        ),
        _sectionTitle('AERIAL COVERAGE GEAR'),
        const SizedBox(height: 8),
        _droneCard(
          'Insta360 X4 — 360° Cam',
          'Full 360° fight coverage from the air',
          '\$499',
          '\$419 wholesale 3+',
          Icons.camera,
          const Color(0xFFF4A261),
        ),
        _droneCard(
          'DJI O3 Air Unit Pro',
          'Ultra-low latency 4K digital FPV',
          '\$229',
          '\$185 wholesale 5+',
          Icons.videocam,
          const Color(0xFF0077B6),
        ),
        _droneCard(
          'GoPro Hero 13 Black',
          'Best action cam for fight drone mounts',
          '\$349',
          '\$299 wholesale 3+',
          Icons.camera_alt,
          const Color(0xFF06D6A0),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildFightGearTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // DFC vs other apps banner
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF006E), Color(0xFFFF6B00)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FIGHTER-GRADE GEAR ON DFC',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Not Nike Training Club. Not BetterMe. This is gear built FOR fighters, BY fighters.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        _sectionTitle('BOXING & MUAY THAI'),
        const SizedBox(height: 8),
        _droneCard(
          'Rival RB1 Ultra Bag Gloves',
          '12–16oz, dual-layer foam, nappa leather',
          '\$159',
          '\$129 × 5+',
          Icons.sports_mma,
          const Color(0xFFFF006E),
          hot: true,
        ),
        _droneCard(
          'Twins Special BGVL-3 Gloves',
          'Thailand-made Muay Thai classic',
          '\$89',
          '\$71 × 10+',
          Icons.sports_mma,
          const Color(0xFFFF6B00),
          hot: true,
        ),
        _droneCard(
          'Fairtex HW2 Heavy Bag',
          '100lb Muay Thai banana bag — unfilled',
          '\$249',
          '\$199 × 3+',
          Icons.fitness_center,
          const Color(0xFF8338EC),
        ),
        _droneCard(
          'RDX Angle Boxing Bag',
          '4ft wall-mounted uppercut & hook trainer',
          '\$139',
          '\$109 × 5+',
          Icons.fitness_center,
          const Color(0xFF3A86FF),
        ),
        _droneCard(
          'Venum Contender Shin Guards',
          'Full shin + instep protection, MMA/MT',
          '\$59',
          '\$46 × 10+',
          Icons.security,
          const Color(0xFF00B4D8),
        ),
        _droneCard(
          'Rival RS11V Body Shield',
          'Curved pro-grade Thai pad — trainer use',
          '\$189',
          '\$149 × 5+',
          Icons.shield,
          const Color(0xFFFF006E),
        ),
        _sectionTitle('MMA & GRAPPLING'),
        const SizedBox(height: 8),
        _droneCard(
          'Hayabusa T3 MMA Gloves',
          '4oz competition glove — 3 colours',
          '\$79',
          '\$63 × 10+',
          Icons.sports_mma,
          const Color(0xFF06D6A0),
        ),
        _droneCard(
          'Tatami Fightwear Origin Gi',
          'Ultra-light 350g weave, IBJJF legal',
          '\$139',
          '\$109 × 5+',
          Icons.person,
          const Color(0xFF0077B6),
        ),
        _droneCard(
          'Fuji Sports All-Around Gi',
          'Perfect beginner BJJ gi — 4 colours',
          '\$89',
          '\$69 × 10+',
          Icons.checkroom,
          const Color(0xFFFFD600),
        ),
        _droneCard(
          'Shock Doctor Ultra Pro Mouthguard',
          'Gel-fit bone frame, dual layer',
          '\$39',
          '\$30 × 20+',
          Icons.security,
          const Color(0xFFFF6B00),
        ),
        _droneCard(
          'Nogi Sports Gorilla Rash Guard',
          '4-way stretch, antimicrobial, ADCC cut',
          '\$59',
          '\$46 × 10+',
          Icons.dry_cleaning,
          const Color(0xFF8338EC),
        ),
        _sectionTitle('STRENGTH & CONDITIONING'),
        const SizedBox(height: 8),
        _droneCard(
          'Onnit Kettlebell 32kg',
          'Chip-resistant iron, pro-grade handle',
          '\$79',
          '\$62 × 5+',
          Icons.fitness_center,
          const Color(0xFFFF006E),
        ),
        _droneCard(
          'Rogue Ohio Bar',
          '190,000 PSI tensile strength barbell',
          '\$299',
          '\$249 × 3+',
          Icons.fitness_center,
          const Color(0xFFE63946),
        ),
        _droneCard(
          'Battle Ropes 15m',
          '38mm manila battle rope + wall anchor',
          '\$119',
          '\$94 × 3+',
          Icons.loop,
          const Color(0xFF00FF88),
        ),
        _droneCard(
          'Gravity Fitness Parallettes',
          'Floor handstand bars, steel, rubber feet',
          '\$69',
          '\$54 × 5+',
          Icons.sports_gymnastics,
          const Color(0xFFFFD600),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildTrainingTechTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // DFC superiority banner
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8338EC), Color(0xFF3A86FF)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DFC BEATS THEM ALL',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Nike Training Club · WHOOP · Garmin · Runna · Pliability · FitBod · YogiFi — DFC integrates ALL of them',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    [
                          'Nike TC ✓',
                          'WHOOP ✓',
                          'Garmin ✓',
                          'Fitbit ✓',
                          'Runna ✓',
                          'Pliability ✓',
                          'FitBod ✓',
                          'Oura ✓',
                        ]
                        .map(
                          (a) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              a,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
        ),
        _sectionTitle('AI TRAINING SYSTEMS'),
        const SizedBox(height: 8),
        _droneCard(
          'RoboSpar V1 AI Pad System',
          'AI counter-striking pads — reacts to combos',
          '\$1,299',
          '\$1,049 × 3+',
          Icons.smart_toy,
          const Color(0xFFFF6B00),
          hot: true,
        ),
        _droneCard(
          'FightMetrics Sensor Kit',
          'Punch speed, kick force & combo tracking',
          '\$349',
          '\$279 × 3+',
          Icons.sensors,
          const Color(0xFF00FF88),
          hot: true,
        ),
        _droneCard(
          'DFC AI Coach Module',
          'Integrated Genie AI + biometric coaching',
          '\$199/yr',
          'Team pricing available',
          Icons.psychology,
          const Color(0xFF8338EC),
        ),
        _droneCard(
          'Corner 3 Smart Boxing Gloves',
          'Punch data in real time to DFC dashboard',
          '\$299',
          '\$239 × 5+',
          Icons.sports_mma,
          const Color(0xFFFF006E),
        ),
        _sectionTitle('FITNESS APP INTEGRATIONS'),
        const SizedBox(height: 8),
        _droneCard(
          'DFC × Nike Training Club Sync',
          'Pull NTC workouts into DFC training log',
          'FREE',
          'DFC Premium required',
          Icons.sync,
          const Color(0xFFFF6B00),
        ),
        _droneCard(
          'DFC × Runna Running Plans',
          'Import Runna plans into DFC periodisation',
          '\$9.99/mo',
          'Bundle with DFC Premium',
          Icons.directions_run,
          const Color(0xFF06D6A0),
        ),
        _droneCard(
          'DFC × Pliability Mobility',
          'Recovery & mobility sessions alongside fight training',
          '\$15.99/mo',
          'Bundle available',
          Icons.self_improvement,
          const Color(0xFF3A86FF),
        ),
        _droneCard(
          'DFC × FitBod Strength Plans',
          'AI strength programming synced to DFC HRV data',
          '\$12/mo',
          'Bundle available',
          Icons.fitness_center,
          const Color(0xFFFFD600),
        ),
        _droneCard(
          'DFC × Alo Wellness Club',
          'Yoga & mobility flows for fighter recovery',
          'FREE tier',
          'Alo Access included',
          Icons.spa,
          const Color(0xFFFF006E),
        ),
        _sectionTitle('WEARABLE ECOSYSTEM'),
        const SizedBox(height: 8),
        _droneCard(
          'DFC WHOOP Integration',
          'Fight readiness score from WHOOP HRV & strain',
          'FREE',
          'Connect in Smart Hub',
          Icons.monitor_heart,
          const Color(0xFF00FF88),
        ),
        _droneCard(
          'DFC Garmin Integration',
          'VO₂Max, Training Load, Sleep from Fenix/Forerunner',
          'FREE',
          'Connect in Smart Hub',
          Icons.gps_fixed,
          const Color(0xFF0077B6),
        ),
        _droneCard(
          'DFC Oura Ring Integration',
          'Readiness, deep sleep & temp trend in DFC',
          'FREE',
          'Connect in Smart Hub',
          Icons.circle,
          const Color(0xFFFFD600),
        ),
        _droneCard(
          'DFC Apple Health Sync',
          'Pull ECG, SpO2, Steps, Active Calories from Apple Watch',
          'FREE',
          'iOS 17+ required',
          Icons.watch,
          const Color(0xFF00B4D8),
        ),
        _droneCard(
          'DFC Fitbit / Google Fit Sync',
          'Steps, sleep & heart data into DFC Body Monitor',
          'FREE',
          'Connect in Smart Hub',
          Icons.directions_walk,
          const Color(0xFFFF6B00),
        ),
        _sectionTitle('VIDEO & ANALYSIS TOOLS'),
        const SizedBox(height: 8),
        _droneCard(
          'Coaches Eye Video Analysis',
          'Frame-by-frame technique review with telestration',
          '\$9.99/mo',
          'DFC video module',
          Icons.videocam,
          const Color(0xFF8338EC),
        ),
        _droneCard(
          'DJI Avata 2 + DFC Mount Kit',
          'Aerial training footage auto-tagged to session',
          '\$829',
          '\$679 × 3+',
          Icons.flight,
          const Color(0xFF00B4D8),
        ),
        _droneCard(
          'Hudl Technique App + DFC',
          'Biomechanics analysis integrated with DFC stats',
          '\$12/mo',
          'Bundle available',
          Icons.analytics,
          const Color(0xFFFF006E),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildRaceDronesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('RACING DRONES - COMPLETE BUILDS'),
        const SizedBox(height: 8),
        _droneCard(
          'iFlight Nazgul5 HD v4 5"',
          '4S/6S, 2306 1700KV, F7 stack, 40A ESC',
          '\$289',
          '\$239 × 3+',
          Icons.rocket_launch,
          const Color(0xFFFF6B00),
          hot: true,
        ),
        _droneCard(
          'Emax Hawk Apex 4"',
          '20×20 F7 FC, 15A BLHeli_32, 1404 motor',
          '\$159',
          '\$128 × 5+',
          Icons.flight,
          const Color(0xFF8338EC),
        ),
        _droneCard(
          'Flywoo Explorer LR 4" HD',
          'Long range 4" toothpick — O3 ready',
          '\$169',
          '\$135 × 3+',
          Icons.explore,
          const Color(0xFF00B4D8),
        ),
        _droneCard(
          'Diatone Roma F5 V2',
          '5" cinematic freestyle, 2507 1850KV',
          '\$219',
          '\$175 × 3+',
          Icons.sports_motorsports,
          const Color(0xFFFFD600),
        ),
        _droneCard(
          'GEPRC Cinelog35 HD',
          'Cinewhoop 3.5" — O3 AirUnit pre-fitted',
          '\$249',
          '\$199 × 3+',
          Icons.videocam,
          const Color(0xFF06D6A0),
        ),
        _droneCard(
          'BetaFPV Pavo25 Whoop',
          '2.5" brushless whoop — DJI HD ready',
          '\$119',
          '\$94 × 5+',
          Icons.flight_takeoff,
          const Color(0xFFFF006E),
        ),
        _droneCard(
          'Armattan Marmotte 5"',
          'Lifetime warranty race frame + ESC/FC',
          '\$189',
          '\$149 × 3+',
          Icons.security,
          const Color(0xFFF4A261),
        ),
        _droneCard(
          'DJI Avata 2 FPV System',
          'Complete DJI ecosystem FPV setup',
          '\$799',
          '\$649 × 5+',
          Icons.flight,
          const Color(0xFF0077B6),
        ),
        _droneCard(
          'Skyzone SKY04X Pro Goggles',
          'OLED FPV goggles — razor sharp',
          '\$449',
          '\$365 × 3+',
          Icons.visibility,
          const Color(0xFFE63946),
        ),
        _droneCard(
          'Radiomaster Boxer MAX',
          'ExpressLRS TX multiprotocol controller',
          '\$159',
          '\$125 × 5+',
          Icons.gamepad,
          const Color(0xFF3A86FF),
        ),
        _sectionTitle('ENDURANCE / LONG RANGE'),
        const SizedBox(height: 8),
        _droneCard(
          'GEPRC Crocodile Baby HD',
          'Long-range 5" — 25km+ capability',
          '\$259',
          '\$209 × 3+',
          Icons.gps_fixed,
          const Color(0xFF00FF88),
        ),
        _droneCard(
          'Flywoo SL5 Ultra',
          'Sub-250g 5" with O3 AirUnit',
          '\$229',
          '\$185 × 3+',
          Icons.air,
          const Color(0xFF8338EC),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildDronePartsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('FLIGHT CONTROLLERS & ESCS'),
        const SizedBox(height: 8),
        _droneCard(
          'Holybro Kakute H7 v2',
          'F7 FC — BetaFlight 4.4 ready',
          '\$49',
          '\$38 × 10+',
          Icons.developer_board,
          const Color(0xFF8338EC),
        ),
        _droneCard(
          'Speedybee F405 V4 Stack',
          'F4 FC + 55A 4-in-1 ESC combo',
          '\$69',
          '\$55 × 5+',
          Icons.electric_bolt,
          const Color(0xFFFFD600),
        ),
        _droneCard(
          'BLHeli_32 45A 4-in-1 ESC',
          'Telemetry, bi-direction DSHOT600',
          '\$39',
          '\$30 × 10+',
          Icons.electric_bolt,
          const Color(0xFFFF6B00),
        ),
        _droneCard(
          'Matek F405-CTR',
          'F4 FC with OSD, BEC, Baro',
          '\$42',
          '\$33 × 10+',
          Icons.memory,
          const Color(0xFF0077B6),
        ),
        _sectionTitle('MOTORS'),
        const SizedBox(height: 8),
        _droneCard(
          'Xing-E Pro 2306 2450KV',
          '4S freestyle motor — stainless shaft',
          '\$18',
          '\$12 × 20+',
          Icons.rotate_right,
          const Color(0xFFFF6B00),
          hot: true,
        ),
        _droneCard(
          'iFlight XING 2208 1800KV',
          '6S long-range motor — titanium shaft',
          '\$22',
          '\$16 × 20+',
          Icons.rotate_right,
          const Color(0xFF00B4D8),
        ),
        _droneCard(
          'BrotherHobby Tornado T2',
          '2306 2450KV — proven race motor',
          '\$16',
          '\$11 × 30+',
          Icons.cyclone,
          const Color(0xFF06D6A0),
        ),
        _droneCard(
          'Emax ECO II 2306',
          'Budget race motor — great efficiency',
          '\$14',
          '\$9 × 30+',
          Icons.electric_bolt,
          const Color(0xFFFFD600),
        ),
        _sectionTitle('FRAMES'),
        const SizedBox(height: 8),
        _droneCard(
          'ImpulseRC Apex 5"',
          'HD frame — Deadcat geometry',
          '\$59',
          '\$46 × 5+',
          Icons.crop_square,
          const Color(0xFF8338EC),
        ),
        _droneCard(
          'TBS Source One V5',
          'Open-source 5" race frame',
          '\$22',
          '\$15 × 10+',
          Icons.grid_on,
          const Color(0xFFFF6B00),
        ),
        _droneCard(
          'Armattan Rooster',
          '5" freestyle — lifetime warranty',
          '\$49',
          '\$38 × 5+',
          Icons.security,
          const Color(0xFFE63946),
        ),
        _droneCard(
          'GEPRC Mark5 HD',
          '5" freestyle HD carbon frame',
          '\$45',
          '\$35 × 5+',
          Icons.widgets,
          const Color(0xFF3A86FF),
        ),
        _sectionTitle('VTX & ANTENNAS'),
        const SizedBox(height: 8),
        _droneCard(
          'Rush Tank Ultimate Plus',
          '2.5W 5.8GHz VTX — Pit mode',
          '\$39',
          '\$30 × 10+',
          Icons.signal_cellular_alt,
          const Color(0xFFFF006E),
        ),
        _droneCard(
          'Lumenier AXII HD Antenna',
          '5.8GHz patch — crystal clear',
          '\$29',
          '\$22 × 10+',
          Icons.wifi,
          const Color(0xFF06D6A0),
        ),
        _droneCard(
          'TBS Crossfire Nano TX',
          'Ultra-long range ExpressLRS',
          '\$25',
          '\$18 × 10+',
          Icons.radar,
          const Color(0xFFFFD600),
        ),
        _sectionTitle('BATTERIES & CHARGERS'),
        const SizedBox(height: 8),
        _droneCard(
          'Tattu R-Line V3 1550mAh 6S',
          'Top race LiPo — XT60 connector',
          '\$35',
          '\$27 × 10+',
          Icons.battery_charging_full,
          const Color(0xFF00FF88),
        ),
        _droneCard(
          'CNHL Black Series 1300mAh 4S',
          'Budget 4S — great discharge',
          '\$18',
          '\$13 × 20+',
          Icons.battery_full,
          const Color(0xFF00B4D8),
        ),
        _droneCard(
          'ISDT Q6 Plus 300W Charger',
          '14A AC/DC balance charger',
          '\$55',
          '\$42 × 5+',
          Icons.power,
          const Color(0xFF8338EC),
        ),
        _droneCard(
          'Hota D6 Pro Dual Charger',
          'Dual 650W output — fast charge',
          '\$99',
          '\$79 × 3+',
          Icons.electrical_services,
          const Color(0xFFFFD600),
        ),
        _sectionTitle('GOGGLES & CONTROLLERS'),
        const SizedBox(height: 8),
        _droneCard(
          'DJI Goggles 3',
          'Micro OLED — DJI O4 system',
          '\$649',
          '\$529 × 3+',
          Icons.visibility,
          const Color(0xFF0077B6),
        ),
        _droneCard(
          'Skyzone SKY04X Pro',
          'OLED 5.8GHz analog FPV goggles',
          '\$449',
          '\$365 × 3+',
          Icons.remove_red_eye,
          const Color(0xFFFF6B00),
        ),
        _droneCard(
          'Radiomaster TX16S MKII Max',
          'Hall gimbals, ELRS, multiprotocol',
          '\$219',
          '\$175 × 3+',
          Icons.gamepad,
          const Color(0xFFE63946),
        ),
        _droneCard(
          'Radiomaster Boxer MAX',
          'Compact ELRS — ExpressLRS 2.4G',
          '\$159',
          '\$125 × 5+',
          Icons.sports_esports,
          const Color(0xFF3A86FF),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildWholesaleTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Wholesale CTA banner
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WHOLESALE ORDERING',
                style: TextStyle(
                  color: Color(0xFFFF6B00),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Club orders · Racing teams · Resellers · Event operators',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              const Text(
                '- MOQ from 3 units\n- Up to 35% off retail\n- Custom team branding available\n- DFC Verified Supplier badge for resellers\n- Net-30 payment terms for approved accounts',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Wholesale account request submitted! We\'ll be in touch within 48 hours.',
                      ),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B00), Color(0xFFFFD600)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'REQUEST WHOLESALE ACCOUNT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _sectionTitle('BULK RACE KITS'),
        const SizedBox(height: 8),
        _wholesaleCard(
          'Starter FPV Club Kit × 5',
          '5× Eachine Falcon 250 RTF + goggles + chargers + batteries',
          '\$1,199',
          'Save \$396 vs retail',
        ),
        _wholesaleCard(
          'Pro Race Team Bundle × 10',
          '10× iFlight Nazgul5 + Radiomaster TX16S + Tattu 6S packs',
          '\$3,490',
          'Save \$800 vs retail',
        ),
        _wholesaleCard(
          'Micro Whoop League Pack × 20',
          '20× BetaFPV Cetus Pro + BetaFPV LiteRadio 3 + goggles',
          '\$2,199',
          'Save \$580 vs retail',
        ),
        _wholesaleCard(
          'DJI FPV Team Pack × 5',
          '5× DJI Avata 2 + Goggles 3 + RC Motion 3 each',
          '\$5,750',
          'Save \$1,245 vs retail',
        ),
        _wholesaleCard(
          'Long Range Scout Pack × 3',
          '3× GEPRC Crocodile Baby + Crossfire TX + 6S LiPo × 9',
          '\$1,199',
          'Save \$340 vs retail',
        ),
        _sectionTitle('PARTS WHOLESALE LOTS'),
        const SizedBox(height: 8),
        _wholesaleCard(
          'Motor Lot × 100',
          'Xing-E Pro 2306 2450KV — assorted 4S/6S mix',
          '\$1,100',
          '\$11/unit — 39% off',
        ),
        _wholesaleCard(
          'ESC Stack Lot × 20',
          'Speedybee F405 V4 FC+ESC stack × 20 units',
          '\$960',
          '\$48/unit — 30% off',
        ),
        _wholesaleCard(
          'LiPo Battery Case × 50',
          'CNHL Black Series 1300mAh 4S × 50',
          '\$600',
          '\$12/unit — 33% off',
        ),
        _wholesaleCard(
          'FPV Camera Lot × 30',
          'RunCam Phoenix 2 Nano + mountkits × 30',
          '\$390',
          '\$13/unit — 35% off',
        ),
        _wholesaleCard(
          'Frame Lot × 15',
          'TBS Source One V5 5" frame × 15',
          '\$195',
          '\$13/unit — 41% off',
        ),
        _sectionTitle('RESELLER PROGRAMME'),
        const SizedBox(height: 8),
        _wholesaleCard(
          'Tier 1 Reseller — Starter',
          'Up to 20% margin, DFC badge, \$500 min order',
          'Apply',
          'Starter reseller account',
        ),
        _wholesaleCard(
          'Tier 2 Reseller — Pro',
          'Up to 28% margin, featured listing, dedicated account manager',
          'Apply',
          '\$5,000 quarterly min',
        ),
        _wholesaleCard(
          'Tier 3 Reseller — Elite',
          'Up to 35% margin, private label option, net-30 terms',
          'Apply',
          '\$20,000 quarterly min',
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildDroneCamerasTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('FPV CAMERAS'),
        const SizedBox(height: 8),
        _droneCard(
          'RunCam Phoenix 2 Nano',
          '1/2" CMOS, 0.0001 lux, incredible low-light',
          '\$39',
          '\$30 × 10+',
          Icons.camera_alt,
          const Color(0xFFFF6B00),
          hot: true,
        ),
        _droneCard(
          'DJI O3 Air Unit Pro',
          '4K/60fps ultra-low latency digital FPV',
          '\$229',
          '\$185 × 5+',
          Icons.videocam,
          const Color(0xFF0077B6),
          hot: true,
        ),
        _droneCard(
          'Caddx Nebula Pro Nano',
          'DJI digital HD micro FPV camera',
          '\$49',
          '\$38 × 10+',
          Icons.camera,
          const Color(0xFF06D6A0),
        ),
        _droneCard(
          'RunCam Nano 4',
          'Ultra compact 800TVL analog cam',
          '\$19',
          '\$13 × 20+',
          Icons.photo_camera,
          const Color(0xFF3A86FF),
        ),
        _droneCard(
          'Foxeer Razer Nano',
          '1200TVL, WDR, wide dynamic range',
          '\$22',
          '\$16 × 20+',
          Icons.camera_enhance,
          const Color(0xFFE63946),
        ),
        _sectionTitle('FULL-SIZE ACTION CAMERAS'),
        const SizedBox(height: 8),
        _droneCard(
          'GoPro Hero 13 Black',
          '5.3K60, HyperSmooth 7.0, ND filters',
          '\$349',
          '\$299 × 3+',
          Icons.videocam,
          const Color(0xFF00FF88),
        ),
        _droneCard(
          'Insta360 X4 — 360°',
          '8K 360°, invisible selfie stick tech',
          '\$499',
          '\$419 × 3+',
          Icons.camera_roll,
          const Color(0xFFF4A261),
        ),
        _droneCard(
          'DJI Osmo Action 5 Pro',
          '4K/240fps, 10-bit D-Log, 39m waterproof',
          '\$279',
          '\$229 × 3+',
          Icons.camera_alt,
          const Color(0xFF8338EC),
        ),
        _droneCard(
          'Insta360 Go 3S',
          'Tiny magnetic 4K — attaches anywhere',
          '\$349',
          '\$289 × 3+',
          Icons.camera_front,
          const Color(0xFFFFD600),
        ),
        _sectionTitle('AUDIO & ACCESSORIES'),
        const SizedBox(height: 8),
        _droneCard(
          'DJI MIC 2 Wireless',
          '32-bit float recording, 250m range',
          '\$299',
          '\$245 × 3+',
          Icons.mic,
          const Color(0xFF00B4D8),
        ),
        _droneCard(
          'Rode Wireless GO II',
          '200m range dual-channel mic system',
          '\$299',
          '\$245 × 3+',
          Icons.mic_external_on,
          const Color(0xFFFF6B00),
        ),
        _droneCard(
          'ND Filter Kit — 10-Pack',
          'CPL + ND4/8/16/32 for DJI/GoPro/Insta360',
          '\$39',
          '\$28 × 10+',
          Icons.filter,
          const Color(0xFFE63946),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _droneCard(
    String title,
    String subtitle,
    String retailPrice,
    String wholesalePrice,
    IconData icon,
    Color accent, {
    bool hot = false,
  }) {
    return GestureDetector(
      onTap: () => _showProductSheet(
        title,
        retailPrice,
        subtitle: subtitle,
        accent: accent,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accent.withValues(alpha: hot ? 0.45 : 0.2),
            width: hot ? 1.5 : 1,
          ),
          boxShadow: hot
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.12),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (hot)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFF6B00,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'HOT',
                            style: TextStyle(
                              color: Color(0xFFFF6B00),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        retailPrice,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        wholesalePrice,
                        style: const TextStyle(
                          color: Color(0xFF00FF88),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$title added to cart!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ORDER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wholesaleCard(
    String title,
    String subtitle,
    String price,
    String saving,
  ) {
    return GestureDetector(
      onTap: () => _showProductSheet(
        title,
        price,
        subtitle: subtitle,
        accent: const Color(0xFFFF6B00),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.inventory_2,
                color: Color(0xFFFF6B00),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    saving,
                    style: const TextStyle(
                      color: Color(0xFF00FF88),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              price,
              style: const TextStyle(
                color: Color(0xFFFFD600),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _droneStatPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // ⌚ SMART DEVICES TAB
  // ═══════════════════════════════════════════════════════
  Widget _buildSmartDevicesTab() {
    const items = [
      _SmartDeviceListing(
        'Apple Watch Ultra 2',
        'GPS + Cellular, crash detection, fight-grade HR',
        '\$799',
        Icons.watch,
        Color(0xFF00B4D8),
        'Apple',
      ),
      _SmartDeviceListing(
        'WHOOP 5.0',
        'HRV, strain, recovery & sleep coach for fighters',
        '\$239/yr',
        Icons.monitor_heart,
        Color(0xFF00FF88),
        'WHOOP',
      ),
      _SmartDeviceListing(
        'Oura Ring 4',
        '24/7 readiness, SpO2, skin temp & cycle insights',
        '\$349',
        Icons.circle,
        Color(0xFFFFD700),
        'Oura',
      ),
      _SmartDeviceListing(
        'Garmin Fenix 8',
        'Solar-powered multisport, VO₂Max, training load',
        '\$899',
        Icons.gps_fixed,
        Color(0xFF0077B6),
        'Garmin',
      ),
      _SmartDeviceListing(
        'Polar H10 Chest Strap',
        'Elite ECG chest strap — gold-standard accuracy',
        '\$89',
        Icons.favorite,
        Color(0xFFFF006E),
        'Polar',
      ),
      _SmartDeviceListing(
        'Corner 3 Smart Gloves',
        'Punch speed, force & combo tracking for boxing',
        '\$299',
        Icons.sports_mma,
        Color(0xFFFF6B35),
        'Corner3',
      ),
      _SmartDeviceListing(
        'FightSense Mouthguard',
        'Head impact G-force, rotation & CTE risk sensor',
        '\$449',
        Icons.security,
        Color(0xFFFF006E),
        'FightSense',
      ),
      _SmartDeviceListing(
        'Fitbit Charge 6',
        'ECG, EDA stress scan & Google integration',
        '\$159',
        Icons.watch,
        Color(0xFF06D6A0),
        'Fitbit',
      ),
      _SmartDeviceListing(
        'COROS PACE 3',
        'Ultralight GPS — endurance & strength analytics',
        '\$229',
        Icons.speed,
        Color(0xFFE63946),
        'COROS',
      ),
      _SmartDeviceListing(
        'Wahoo TICKR X',
        'Heart rate + running dynamics chest band',
        '\$79',
        Icons.monitor_heart,
        Color(0xFFF4A261),
        'Wahoo',
      ),
      _SmartDeviceListing(
        'Withings Body Comp Scale',
        'Weight, muscle mass, fat %, vascular age',
        '\$199',
        Icons.scale,
        Color(0xFF8338EC),
        'Withings',
      ),
      _SmartDeviceListing(
        'Xiaomi Mi Band 9 Pro',
        'Budget warrior — HR, SpO2, sleep stages',
        '\$49',
        Icons.watch,
        Color(0xFF3A86FF),
        'Xiaomi',
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hub Banner
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00B4D8), Color(0xFF8338EC)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.watch_outlined, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SMART DEVICES HUB',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'Connect wearables · track vitals · dominate your training',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ],
          ),
        ),
        for (final device in items)
          GestureDetector(
            onTap: () => _showProductSheet(
              device.name,
              device.price,
              subtitle: device.subtitle,
              accent: device.accentColor,
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DesignTokens.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: device.accentColor.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: device.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      device.icon,
                      color: device.accentColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(
                            color: DesignTokens.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          device.subtitle,
                          style: const TextStyle(
                            color: DesignTokens.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          device.brand,
                          style: TextStyle(
                            color: device.accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        device.price,
                        style: const TextStyle(
                          color: DesignTokens.neonGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${device.name} added to cart!'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                device.accentColor,
                                device.accentColor.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'BUY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 80),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // TAB 1 — ALL (Featured + trending)
  // ═══════════════════════════════════════════════════════

  Widget _buildAllTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Featured Deals'),
        const SizedBox(height: 6),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _featuredCard(
                'Hayabusa T3 Gloves',
                '\$149.99',
                '\$199.99',
                'Equipment',
                DesignTokens.neonRed,
                '25% OFF',
                4.8,
                234,
              ),
              _featuredCard(
                '1-on-1 Coaching Session',
                '\$75/hr',
                '',
                'Service',
                DesignTokens.neonGreen,
                'TOP RATED',
                4.9,
                156,
              ),
              _featuredCard(
                'FPV Micro Drone (FightCam Edition)',
                '\$199',
                '\$249',
                'Drones & Tech',
                DesignTokens.neonCyan,
                'NEW ANGLES',
                5.0,
                42,
              ),
              _featuredCard(
                'Fight Camp Package',
                '\$299/mo',
                '\$399/mo',
                'Bundle',
                DesignTokens.neonCyan,
                'BEST VALUE',
                4.7,
                89,
              ),
            ],
          ),
        ),
        // --- Future: AI-generated promotional cards ---
        const SizedBox(height: 16),
        _sectionTitle('Trending Now'),
        ..._trendingItems(),
        const SizedBox(height: 16),
        _sectionTitle('Recently Listed'),
        ..._recentItems(),
      ],
    );
  }

  Widget _featuredCard(
    String title,
    String price,
    String oldPrice,
    String category,
    Color color,
    String badge,
    double rating,
    int reviews,
  ) {
    return GestureDetector(
      onTap: () =>
          _showProductSheet(title, price, subtitle: category, accent: color),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image + badge
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                      child: Image.asset(
                        _marketplaceImageUrl(category),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: Icon(
                            Icons.sports_mma,
                            color: color.withValues(alpha: 0.3),
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (oldPrice.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          oldPrice,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 10,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            Icons.star,
                            size: 10,
                            color: i < rating.floor()
                                ? DesignTokens.neonGold
                                : Colors.white24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$rating ($reviews)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 9,
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
    );
  }

  List<Widget> _trendingItems() => [
    _listingTile(
      'Venum Elite Boxing Gloves',
      '\$69.99',
      'Equipment',
      'Boxing',
      4.6,
      342,
      DesignTokens.neonRed,
      Icons.sports_mma,
    ),
    _listingTile(
      'Pro Sparring Session (2 hrs)',
      '\$50',
      'Service',
      'MMA',
      4.8,
      78,
      DesignTokens.neonGreen,
      Icons.groups_2_outlined,
    ),
    _listingTile(
      'FPV Micro Drone (FightCam Edition)',
      '\$199',
      'Drones & Tech',
      'FPV',
      4.9,
      58,
      DesignTokens.neonCyan,
      Icons.flight,
    ),
    _listingTile(
      'Used Heavy Bag (100lb)',
      '\$120',
      'Equipment',
      'Boxing',
      4.3,
      45,
      DesignTokens.neonAmber,
      Icons.gps_fixed,
    ),
    _listingTile(
      'Online Fight Analysis',
      '\$35/fight',
      'Service',
      'Coaching',
      4.9,
      201,
      DesignTokens.neonCyan,
      Icons.analytics_outlined,
    ),
  ];

  List<Widget> _recentItems() => [
    _listingTile(
      'Hand Wraps (3 Pack)',
      '\$14.99',
      'Equipment',
      'Accessories',
      4.5,
      567,
      DesignTokens.neonAmber,
      Icons.linear_scale,
    ),
    _listingTile(
      'Fighter Available — 70 kg / 155 lbs',
      'Contact',
      'Fighter',
      'MMA',
      0,
      0,
      DesignTokens.neonRed,
      Icons.person,
    ),
    _listingTile(
      'Muay Thai Shorts (Custom)',
      '\$45',
      'Apparel',
      'Muay Thai',
      4.4,
      89,
      DesignTokens.neonMagenta,
      Icons.checkroom,
    ),
  ];

  Widget _listingTile(
    String title,
    String price,
    String type,
    String sport,
    double rating,
    int reviews,
    Color color,
    IconData fallbackIcon,
  ) {
    return GestureDetector(
      onTap: () => _showProductSheet(
        title,
        price,
        subtitle: '$type \u2022 $sport',
        accent: color,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  _marketplaceImageUrl(type),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Center(
                    child: Icon(fallbackIcon, color: color, size: 22),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: color,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        sport,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 10,
                        ),
                      ),
                      if (rating > 0) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.star,
                          color: DesignTokens.neonGold,
                          size: 10,
                        ),
                        Text(
                          ' $rating',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (reviews > 0)
                  Text(
                    '$reviews sold',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TAB 2 — EQUIPMENT
  // ═══════════════════════════════════════════════════════

  Widget _buildEquipmentTab() {
    final categories = [
      const _EqCat('Gloves', Icons.sports_mma, 423, DesignTokens.neonRed),
      const _EqCat('Pads & Mitts', Icons.gps_fixed, 187, DesignTokens.neonAmber),
      const _EqCat('Bags', Icons.fitness_center, 134, DesignTokens.neonGreen),
      const _EqCat('Headgear', Icons.security, 98, DesignTokens.neonCyan),
      const _EqCat('Wraps & Tape', Icons.linear_scale, 256, DesignTokens.neonMagenta),
      const _EqCat('Apparel', Icons.checkroom, 312, DesignTokens.neonAmber),
      const _EqCat('Mouth Guards', Icons.health_and_safety, 89, DesignTokens.neonGreen),
      const _EqCat('Shin Guards', Icons.shield_outlined, 67, Color(0xFF60A5FA)),
      const _EqCat('Training Gear', Icons.bolt, 201, DesignTokens.neonCyan),
      const _EqCat('Recovery', Icons.ac_unit, 145, DesignTokens.neonMagenta),
      const _EqCat('Supplements', Icons.medication, 178, DesignTokens.neonGreen),
      const _EqCat('Gym Equipment', Icons.sports_gymnastics, 92, DesignTokens.neonRed),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Categories'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map(_categoryChip).toList(),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Top Equipment'),
        _listingTile(
          'Winning MS-600 16oz',
          '\$389',
          'Gloves',
          'Boxing',
          4.9,
          1243,
          DesignTokens.neonGold,
          Icons.sports_mma,
        ),
        _listingTile(
          'Fairtex HG13 Headgear',
          '\$89',
          'Headgear',
          'Muay Thai',
          4.7,
          567,
          DesignTokens.neonCyan,
          Icons.shield_outlined,
        ),
        _listingTile(
          'RDX Heavy Bag 5ft',
          '\$149',
          'Bags',
          'MMA',
          4.5,
          234,
          DesignTokens.neonRed,
          Icons.gps_fixed,
        ),
        _listingTile(
          'Shock Doctor Gel Max',
          '\$24.99',
          'Guards',
          'All',
          4.6,
          890,
          DesignTokens.neonGreen,
          Icons.health_and_safety,
        ),
        _listingTile(
          'TITLE Speed Jumprope',
          '\$18',
          'Training',
          'Boxing',
          4.4,
          445,
          DesignTokens.neonAmber,
          Icons.bolt,
        ),
        _listingTile(
          'Therabody Theragun Mini',
          '\$199',
          'Recovery',
          'Rehab',
          4.8,
          678,
          DesignTokens.neonMagenta,
          Icons.ac_unit,
        ),
      ],
    );
  }

  Widget _categoryChip(_EqCat c) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Browsing ${c.name} \u2014 ${c.count} items'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: (MediaQuery.of(context).size.width - 56) / 3,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(c.icon, color: c.color, size: 22),
            const SizedBox(height: 4),
            Text(
              c.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${c.count} items',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TAB 3 — SERVICES
  // ═══════════════════════════════════════════════════════

  Widget _buildServicesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Coaching & Training'),
        _serviceTile(
          '1-on-1 Boxing Coaching',
          'Coach Ray Mitchell',
          '\$75/hr',
          4.9,
          312,
          DesignTokens.neonGreen,
          'Available Mon-Fri',
        ),
        _serviceTile(
          'Online Fight Plan Analysis',
          'Combat IQ Lab',
          '\$35/fight',
          4.8,
          201,
          DesignTokens.neonCyan,
          'Video breakdown included',
        ),
        _serviceTile(
          'MMA Fundamentals Course',
          'Golden Dragon Muay Thai',
          '\$199 (8 wks)',
          4.7,
          89,
          DesignTokens.neonAmber,
          'Beginners welcome',
        ),
        const SizedBox(height: 12),
        _sectionTitle('Recovery & Wellness'),
        _serviceTile(
          'Sports Massage',
          'RecoveryPro',
          '\$90/session',
          4.8,
          178,
          DesignTokens.neonMagenta,
          'Licensed therapist',
        ),
        _serviceTile(
          'Cryotherapy Session',
          'ColdPlunge NYC',
          '\$45/session',
          4.5,
          134,
          DesignTokens.neonCyan,
          '3-min whole body',
        ),
        const SizedBox(height: 12),
        _sectionTitle('Content & Media'),
        _serviceTile(
          'Fight Highlight Reel',
          'Fight Films',
          '\$150/video',
          4.6,
          67,
          DesignTokens.neonRed,
          'Professional edit',
        ),
        _serviceTile(
          'Social Media Management',
          'FightBrand Co',
          '\$300/mo',
          4.4,
          45,
          DesignTokens.neonAmber,
          'Fighter-specific',
        ),
        const SizedBox(height: 12),
        _sectionTitle('Nutrition'),
        _serviceTile(
          'Custom Meal Plan',
          'FuelFight Nutrition',
          '\$80/month',
          4.7,
          234,
          DesignTokens.neonGreen,
          'Weight-cut specialist',
        ),
        _serviceTile(
          'Fight Camp Meal Prep',
          'CleanEats',
          '\$250/week',
          4.5,
          56,
          DesignTokens.neonAmber,
          'Delivered fresh daily',
        ),
      ],
    );
  }

  Widget _serviceTile(
    String title,
    String provider,
    String price,
    double rating,
    int reviews,
    Color color,
    String detail,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Service thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  ImageAssets.dfcBrandedPlaceholder,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 44,
                    height: 44,
                    color: color.withValues(alpha: 0.1),
                    child: Icon(Icons.school, color: color, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                price,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                provider,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star, color: DesignTokens.neonGold, size: 10),
              Text(
                ' $rating',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
              ),
              Text(
                ' ($reviews)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              Text(
                detail,
                style: TextStyle(
                  color: color.withValues(alpha: 0.5),
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _actionBtn('Book Now', color),
              const SizedBox(width: 8),
              _actionBtn('Message', Colors.white54),
              const Spacer(),
              Icon(
                Icons.bookmark_border,
                color: Colors.white.withValues(alpha: 0.3),
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color color) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  label == 'Book Now'
                      ? 'Booking request sent!'
                      : label == 'Message'
                      ? 'Opening chat...'
                      : label == 'Contact'
                      ? 'Contact request sent!'
                      : label == 'View Profile'
                      ? 'Loading profile...'
                      : label == 'Offer Fight'
                      ? 'Fight offer sent!'
                      : label == 'Join'
                      ? 'Joined sparring session!'
                      : label == 'Visit'
                      ? 'Opening gym page...'
                      : label == 'Claim'
                      ? 'Claim request submitted!'
                      : '$label — coming soon',
                ),
              ],
            ),
            backgroundColor: color.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TAB 4 — FIGHTERS
  // ═══════════════════════════════════════════════════════

  Widget _buildFightersTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Available Fighters'),
        _fighterCard(
          'Marcus Torres',
          '84 kg / 185 lbs',
          '25-7-0',
          'MMA',
          DesignTokens.neonRed,
          'Looking for a 5-round main event',
          '60%',
          true,
        ),
        _fighterCard(
          'Casey O\'Neill',
          '57 kg / 125 lbs',
          '10-2-0',
          'MMA',
          DesignTokens.neonMagenta,
          'Available for short notice bouts',
          '70%',
          true,
        ),
        _fighterCard(
          'Jack Della Maddalena',
          '77 kg / 170 lbs',
          '17-2-0',
          'MMA',
          DesignTokens.neonAmber,
          'Seeking title contender fights',
          '77%',
          true,
        ),
        _fighterCard(
          'Stamp Fairtex',
          '52 kg / 115 lbs',
          '73-19-5',
          'Muay Thai',
          DesignTokens.neonGreen,
          'Open to K-1 rules or MT',
          '55%',
          true,
        ),
        _fighterCard(
          'Tyson Pedro',
          '93 kg / 205 lbs',
          '10-4-0',
          'MMA',
          DesignTokens.neonRed,
          'Light heavyweight looking for top 15 opponents',
          '80%',
          true,
        ),
        _fighterCard(
          'Ji Yeon Kim',
          '52 kg / 115 lbs',
          '12-5-2',
          'MMA',
          DesignTokens.neonCyan,
          'Strawweight veteran seeking international bouts',
          '42%',
          true,
        ),
        _fighterCard(
          'Nico Carrillo',
          '61 kg / 135 lbs',
          '11-1-0',
          'Muay Thai',
          DesignTokens.neonAmber,
          'ONE Championship ranked striker',
          '67%',
          true,
        ),
        _fighterCard(
          'Molly McCann',
          '57 kg / 125 lbs',
          '14-6-0',
          'MMA',
          DesignTokens.neonMagenta,
          'Meatball Molly available for UK/EU cards',
          '50%',
          true,
        ),
        _fighterCard(
          'Superbon',
          '70 kg / 155 lbs',
          '115-32-0',
          'Kickboxing',
          DesignTokens.neonGreen,
          'ONE kickboxing champion open to MMA crossover',
          '73%',
          true,
        ),
        _fighterCard(
          'Robert Whittaker',
          '84 kg / 185 lbs',
          '26-8-0',
          'MMA',
          DesignTokens.neonRed,
          'Former UFC champion seeking top contenders',
          '55%',
          true,
        ),
        _fighterCard(
          'Tawanchai PK Saenchai',
          '66 kg / 145 lbs',
          '133-31-2',
          'Muay Thai',
          DesignTokens.neonAmber,
          'ONE MT champion — elite level only',
          '68%',
          true,
        ),
        _fighterCard(
          'Alex Volkanovski',
          '66 kg / 145 lbs',
          '26-4-0',
          'MMA',
          DesignTokens.neonCyan,
          'Former UFC champ wants legacy fights',
          '48%',
          true,
        ),
        const SizedBox(height: 16),
        _sectionTitle('Sparring Partners Wanted'),
        _sparringCard(
          'Need: 175lb MMA sparring partner',
          'Absolute MMA Melbourne',
          'Port Melbourne, VIC',
          'Mon/Wed/Fri',
          DesignTokens.neonCyan,
        ),
        _sparringCard(
          'Looking for southpaw boxers 135-145',
          'Corporate Boxing',
          'Melbourne CBD',
          'Tues/Thurs',
          DesignTokens.neonAmber,
        ),
        _sparringCard(
          'Kickboxing sparring circle — all levels',
          'Golden Dragon Muay Thai Brisbane',
          'West End, QLD',
          'Weekends',
          DesignTokens.neonGreen,
        ),
        _sparringCard(
          'Pro MMA sparring — 170lb division camp',
          'American Top Team',
          'Coconut Creek, FL',
          'Daily 10am-12pm',
          DesignTokens.neonRed,
        ),
        _sparringCard(
          'BJJ rolling — blue belts and above',
          '10th Planet Adelaide',
          'Adelaide, SA',
          'Mon/Wed 7pm',
          DesignTokens.neonMagenta,
        ),
        _sparringCard(
          'Wrestling partners needed for comp prep',
          'Jackson-Wink MMA',
          'Albuquerque, NM',
          'Mon-Fri 2pm',
          DesignTokens.neonCyan,
        ),
        _sparringCard(
          'Muay Thai pad work partner — female fighters',
          'Tiger Muay Thai',
          'Phuket, Thailand',
          'Daily',
          DesignTokens.neonAmber,
        ),
        _sparringCard(
          'Boxing sparring — heavyweights 200+',
          'Wild Card Boxing',
          'Los Angeles, CA',
          'Sat 11am',
          DesignTokens.neonRed,
        ),
      ],
    );
  }

  Widget _fighterCard(
    String name,
    String weight,
    String record,
    String style,
    Color color,
    String desc,
    String finishRate,
    bool verified,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: ClipOval(
                  child: Image.asset(
                    ImageAssets.dfcBrandedPlaceholder,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Center(
                      child: Text(
                        name[0],
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (verified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: DesignTokens.neonCyan,
                            size: 13,
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        _chipTag(weight, color),
                        _chipTag(record, DesignTokens.neonGreen),
                        _chipTag(style, DesignTokens.neonAmber),
                        _chipTag('$finishRate fin.', DesignTokens.neonRed),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _actionBtn('Contact', color),
              const SizedBox(width: 8),
              _actionBtn('View Profile', Colors.white54),
              const Spacer(),
              _actionBtn('Offer Fight', DesignTokens.neonGold),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipTag(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _sparringCard(
    String title,
    String gym,
    String location,
    String schedule,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                ImageAssets.dfcBrandedPlaceholder,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.sports_mma,
                  color: Colors.white54,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$gym · $location',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
                Text(
                  schedule,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _actionBtn('Join', color),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TAB 5 — GYMS
  // ═══════════════════════════════════════════════════════

  Widget _buildGymsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Gyms Near You'),
        _gymCard(
          'Absolute MMA Melbourne',
          'Port Melbourne, VIC',
          'MMA · BJJ · Wrestling',
          4.8,
          567,
          '\$129',
          DesignTokens.neonRed,
          ['MMA', 'BJJ', 'Wrestling', 'Muay Thai'],
        ),
        _gymCard(
          'Corporate Boxing Melbourne',
          'Melbourne CBD',
          'Boxing · Fitness',
          4.9,
          890,
          '\$100',
          DesignTokens.neonAmber,
          ['Boxing', 'Fitness'],
        ),
        _gymCard(
          'Southern Cross BJJ Melbourne',
          'Collingwood, VIC',
          'BJJ · MMA · NoGi',
          4.9,
          1234,
          '\$200',
          DesignTokens.neonCyan,
          ['BJJ', 'MMA', 'Wrestling'],
        ),
        _gymCard(
          'Golden Dragon Muay Thai Brisbane',
          'West End, QLD',
          'Muay Thai · Kickboxing',
          4.5,
          456,
          '\$149',
          DesignTokens.neonGreen,
          ['Muay Thai', 'Kickboxing', 'Kids'],
        ),
        _gymCard(
          'Tiger Muay Thai',
          'Phuket, Thailand',
          'Muay Thai · MMA · BJJ · Boxing',
          4.7,
          3248,
          '\$89',
          DesignTokens.neonAmber,
          ['Muay Thai', 'MMA', 'BJJ', 'Boxing'],
        ),
        _gymCard(
          'American Top Team',
          'Coconut Creek, FL',
          'MMA · Wrestling · BJJ · Boxing',
          4.9,
          2891,
          '\$199',
          DesignTokens.neonRed,
          ['MMA', 'Wrestling', 'BJJ'],
        ),
        _gymCard(
          'Jackson-Wink MMA',
          'Albuquerque, NM',
          'MMA · Striking · Wrestling',
          4.8,
          1876,
          '\$175',
          DesignTokens.neonMagenta,
          ['MMA', 'Striking', 'Wrestling'],
        ),
        _gymCard(
          'Tristar Gym',
          'Montreal, Canada',
          'MMA · BJJ · Karate · Boxing',
          4.9,
          2134,
          '\$180',
          DesignTokens.neonCyan,
          ['MMA', 'BJJ', 'Boxing'],
        ),
        _gymCard(
          'City Kickboxing',
          'Auckland, NZ',
          'MMA · Kickboxing · Wrestling',
          4.8,
          987,
          '\$140',
          DesignTokens.neonGreen,
          ['MMA', 'Kickboxing', 'Wrestling'],
        ),
        _gymCard(
          '10th Planet Adelaide',
          'Adelaide, SA',
          'BJJ · NoGi · MMA',
          4.7,
          412,
          '\$120',
          DesignTokens.neonAmber,
          ['BJJ', 'NoGi', 'MMA'],
        ),
        _gymCard(
          'Wild Card Boxing Club',
          'Los Angeles, CA',
          'Boxing · Conditioning',
          4.9,
          4521,
          '\$150',
          DesignTokens.neonRed,
          ['Boxing', 'Conditioning'],
        ),
        _gymCard(
          'Evolve MMA',
          'Singapore',
          'MMA · Muay Thai · BJJ · Boxing',
          4.8,
          3672,
          '\$200',
          DesignTokens.neonMagenta,
          ['MMA', 'Muay Thai', 'BJJ', 'Boxing'],
        ),
        const SizedBox(height: 16),
        _sectionTitle('Gyms Selling Memberships'),
        _gymDealCard(
          'New Year Special',
          'Absolute MMA Melbourne',
          '3 months for \$299 (was \$387)',
          DesignTokens.neonGold,
        ),
        _gymDealCard(
          'Bring a Friend',
          'Corporate Boxing',
          'Free month when you refer someone',
          DesignTokens.neonGreen,
        ),
        _gymDealCard(
          'Student Discount',
          'Golden Dragon Muay Thai Brisbane',
          '25% off with valid student ID',
          DesignTokens.neonCyan,
        ),
        _gymDealCard(
          'Fighter Package',
          'American Top Team',
          'Unlimited classes + sparring for \$249/mo',
          DesignTokens.neonRed,
        ),
        _gymDealCard(
          'Training Camp Special',
          'Tiger Muay Thai',
          '1 month unlimited + accommodation from \$899',
          DesignTokens.neonAmber,
        ),
        _gymDealCard(
          'Annual Lockdown',
          'Jackson-Wink MMA',
          '12 months for price of 10 — \$1,750',
          DesignTokens.neonMagenta,
        ),
        _gymDealCard(
          'Women\'s First Month Free',
          'Evolve MMA',
          'Encouraging more women into combat sports',
          DesignTokens.neonGreen,
        ),
        _gymDealCard(
          'Family Package',
          'City Kickboxing',
          '2 adults + 2 kids for \$280/mo',
          DesignTokens.neonCyan,
        ),
      ],
    );
  }

  Widget _gymCard(
    String name,
    String location,
    String styles,
    double rating,
    int reviews,
    String price,
    Color color,
    List<String> tags,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    ImageAssets.dfcBrandedPlaceholder,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Icon(Icons.fitness_center, color: color, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 11,
                        ),
                        Text(
                          ' $location',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$price/mo',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: DesignTokens.neonGold, size: 10),
                      Text(
                        ' $rating ($reviews)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            styles,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              ...tags.map(
                (t) => Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      color: color,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              _actionBtn('Visit', color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gymDealCard(String title, String gym, String detail, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.08), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_offer, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title — $gym',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  detail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          _actionBtn('Claim', color),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TAB 6 — ANALYTICS (marketplace intelligence)
  // ═══════════════════════════════════════════════════════

  Widget _buildAnalyticsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Marketplace Intelligence'),
        _analyticsCard(
          'Revenue Trend (30 Days)',
          DesignTokens.neonGreen,
          Icons.show_chart,
          SizedBox(
            height: 100,
            child: CustomPaint(
              painter: _MktLineGraphPainter(
                data: [1200, 1450, 1320, 1680, 1540, 1890, 2100],
                color: DesignTokens.neonGreen,
              ),
              size: Size.infinite,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _analyticsCard(
          'Top Selling Categories',
          DesignTokens.neonAmber,
          Icons.pie_chart,
          Column(
            children: [
              _categoryBar('Gloves', 0.28, '\$12.4K', DesignTokens.neonRed),
              _categoryBar('Coaching', 0.22, '\$9.8K', DesignTokens.neonGreen),
              _categoryBar(
                'Gym Memberships',
                0.18,
                '\$8.1K',
                DesignTokens.neonCyan,
              ),
              _categoryBar('Apparel', 0.15, '\$6.7K', DesignTokens.neonMagenta),
              _categoryBar('Recovery', 0.10, '\$4.5K', DesignTokens.neonAmber),
              _categoryBar('Supplements', 0.07, '\$3.1K', Colors.white54),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _analyticsCard(
          'Buyer Demographics',
          DesignTokens.neonCyan,
          Icons.people,
          Column(
            children: [
              _demoRow('18-24', 0.32, '32%'),
              _demoRow('25-34', 0.38, '38%'),
              _demoRow('35-44', 0.18, '18%'),
              _demoRow('45+', 0.12, '12%'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _analyticsCard(
          'Price Performance',
          DesignTokens.neonMagenta,
          Icons.trending_up,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _priceRow('Avg Listing Price', '\$89.50', '↑ 4% vs LM'),
              _priceRow('Avg Sale Price', '\$72.30', '↓ 2% vs LM'),
              _priceRow('Conversion Rate', '8.4%', '↑ 1.2% vs LM'),
              _priceRow('Time to Sell', '3.2 days', '↓ 0.5 days'),
              _priceRow('Return Rate', '2.1%', '↓ 0.3%'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _analyticsCard(
          'Monthly Active Sellers',
          DesignTokens.neonGreen,
          Icons.store,
          SizedBox(
            height: 80,
            child: CustomPaint(
              painter: _MktLineGraphPainter(
                data: [420, 480, 510, 580, 640, 720, 934],
                color: DesignTokens.neonGreen,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ],
    );
  }

  Widget _analyticsCard(
    String title,
    Color color,
    IconData icon,
    Widget child,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _categoryBar(String label, double pct, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.white.withValues(alpha: 0.04),
                valueColor: AlwaysStoppedAnimation(
                  color.withValues(alpha: 0.6),
                ),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _demoRow(String age, double pct, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              age,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.white.withValues(alpha: 0.04),
                valueColor: AlwaysStoppedAnimation(
                  DesignTokens.neonCyan.withValues(alpha: 0.5),
                ),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: DesignTokens.neonCyan,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, String delta) {
    final isUp = delta.startsWith('↑');
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            delta,
            style: TextStyle(
              color: isUp ? DesignTokens.neonGreen : DesignTokens.neonRed,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // SHARED
  // ─────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showCreateListing() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12121A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreateListingSheet(),
    );
  }
}

// ═══════════════════════════════════════════════════════
// CREATE LISTING SHEET
// ═══════════════════════════════════════════════════════

class _CreateListingSheet extends StatelessWidget {
  final categories = [
    'Equipment',
    'Service',
    'Fighter Listing',
    'Gym Membership',
    'Apparel',
    'Supplements',
    'Drones & Tech', // NEW CATEGORY
    'Recovery',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF12121A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Create Listing',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const Text(
                    'What are you selling?',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories
                        .map(
                          (c) => GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Create $c listing — coming soon',
                                  ),
                                  backgroundColor: const Color(0xFF1A1A2E),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: DesignTokens.neonCyan.withValues(
                                  alpha: 0.06,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: DesignTokens.neonCyan.withValues(
                                    alpha: 0.12,
                                  ),
                                ),
                              ),
                              child: Text(
                                c,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// MARKETPLACE LINE GRAPH PAINTER
// ═══════════════════════════════════════════════════════

class _MktLineGraphPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _MktLineGraphPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.reduce(max);
    final minVal = data.reduce(min);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * size.width / (data.length - 1);
      final y =
          size.height - ((data[i] - minVal) / range) * (size.height * 0.85);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════

class _EqCat {
  final String name;
  final IconData icon;
  final int count;
  final Color color;
  const _EqCat(this.name, this.icon, this.count, this.color);
}
