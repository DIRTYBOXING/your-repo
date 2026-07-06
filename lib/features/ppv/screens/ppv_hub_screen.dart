import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/config/router_constants.dart' as rc;
import '../../../core/utils/web_route_test_hook.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/ppv_model.dart';
import '../../../shared/models/ppv_presentation_model.dart';
import '../../../shared/services/ppv_service.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/widgets/dfc_state_panel.dart';
import '../../../shared/widgets/dfc_poster_frame.dart';
import '../../../shared/widgets/ppv_ai_overlay.dart';
import '../../../widgets/poster_card.dart';
import '../widgets/fight_card_poster.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV HUB SCREEN — The DFC Pay-Per-View Marketplace
/// ═══════════════════════════════════════════════════════════════════════════
///
/// "We promote promotions. We power fights. PPV is how it pays."
///
/// This screen shows:
///   • Live PPV events (red pulsing banner)
///   • Upcoming PPV cards with pricing tiers
///   • Purchase flow with tier selection
///   • User's purchased PPV library
///
/// ═══════════════════════════════════════════════════════════════════════════
class PPVHubScreen extends StatefulWidget {
  const PPVHubScreen({super.key});

  @override
  State<PPVHubScreen> createState() => _PPVHubScreenState();
}

class _PPVHubScreenState extends State<PPVHubScreen>
    with TickerProviderStateMixin {
  final PPVService _ppvService = PPVService();
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  bool _isLoading = true;
  int _selectedTab = 0; // 0=Upcoming, 1=Live, 2=Map, 3=My PPVs
  String _selectedSport = 'All';

  // ── Map State ──
  GoogleMapController? _mapController;
  Set<Marker> _mapMarkers = {};
  String _mapFilter = 'ALL';
  _MapLocationData? _selectedMapLocation;
  static const _mapFilters = ['ALL', 'GYMS', 'EVENTS', 'CAMPAIGNS'];

  static const _sportFilters = [
    'All',
    'MMA',
    'Boxing',
    'BKFC',
    'Kickboxing',
    'Muay Thai',
    'Wrestling',
    'Bare Knuckle',
  ];

  void _goBackSafely() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(rc.RouteConstants.home);
  }

  @override
  void initState() {
    super.initState();
    setWebRouteTestHook('ppv-hub');
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _loadPPVData();
    _buildMapMarkers();
  }

  Future<void> _loadPPVData() async {
    final uid = context.read<AuthService>().currentUser?.uid;
    try {
      await Future.wait([
        _ppvService.loadUpcomingPPVs(),
        _ppvService.loadLivePPVs(),
        if (uid != null) _ppvService.loadUserPurchases(uid),
      ]);
    } catch (e) {
      debugPrint('PPVHub load failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // When Map tab is selected, show full-screen map instead of scrollable content
    if (_selectedTab == 2) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: _buildMapView(),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => PpvAiOverlay.show(context),
        backgroundColor: const Color(0xFF050A14),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: DesignTokens.neonCyan.withValues(alpha: 0.55),
          ),
        ),
        icon: const Icon(
          Icons.psychology_outlined,
          color: DesignTokens.neonCyan,
          size: 20,
        ),
        label: const Text(
          'DFC AI',
          style: TextStyle(
            color: DesignTokens.neonCyan,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildHeroBanner(),
          _buildTabBar(),
          if (_selectedTab == 0) _buildSportFilterPills(),
          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: DFCStatePanel.loading(
                  title: 'Loading PPV marketplace',
                  message:
                      'Syncing live cards, upcoming events, and your purchase library.',
                ),
              ),
            )
          else ...[
            if (_selectedTab == 0) ..._buildUpcomingPPVs(),
            if (_selectedTab == 1) ..._buildLivePPVs(),
            if (_selectedTab == 3) ..._buildMyPPVs(),
          ],
          // Legal disclaimer
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'DFC is a licensed streaming platform for partner promotions. '
                'PPV access is available for events where DFC holds distribution rights. '
                'Third-party platform names are shown for informational purposes only. '
                'All trademarks belong to their respective owners.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DesignTokens.textDisabled,
                  fontSize: DesignTokens.fontSizeMicro,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  // ── App Bar ──

  SliverAppBar _buildAppBar() {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 380;
    return SliverAppBar(
      expandedHeight: 56,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, child) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DesignTokens.bgPrimary,
                Color.lerp(
                  DesignTokens.bgPrimary,
                  DesignTokens.neonMagenta.withValues(alpha: 0.08),
                  _glowAnim.value,
                )!,
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Color.lerp(
                  DesignTokens.neonCyan.withValues(alpha: 0.25),
                  DesignTokens.neonMagenta.withValues(alpha: 0.45),
                  _glowAnim.value,
                )!,
                width: 1.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.neonCyan.withValues(
                  alpha: 0.08 + 0.1 * _glowAnim.value,
                ),
                blurRadius: 18,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        ),
        child: const SizedBox.expand(),
      ),
      leading: IconButton(
        tooltip: 'Back',
        onPressed: _goBackSafely,
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: DesignTokens.textPrimary,
          size: 18,
        ),
      ),
      title: Row(
        children: [
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, _) => Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DesignTokens.neonMagenta.withValues(
                      alpha: 0.18 + 0.1 * _glowAnim.value,
                    ),
                    DesignTokens.neonCyan.withValues(
                      alpha: 0.12 + 0.08 * _glowAnim.value,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: DesignTokens.neonCyan.withValues(
                    alpha: 0.4 + 0.35 * _glowAnim.value,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.neonCyan.withValues(
                      alpha: 0.2 * _glowAnim.value,
                    ),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.live_tv,
                color: DesignTokens.neonCyan,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                DesignTokens.neonCyan,
                Colors.white,
                DesignTokens.neonMagenta,
              ],
              stops: [0.0, 0.5, 1.0],
            ).createShader(bounds),
            child: Text(
              'PPV Marketplace',
              style: TextStyle(
                color: Colors.white,
                fontSize: isNarrow ? 18 : 19,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
      actions: [_buildLiveIndicator(), const SizedBox(width: 12)],
    );
  }

  // ── Hero Banner ──

  SliverToBoxAdapter _buildHeroBanner() {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 380;
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (_, child) => Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0D1825),
                Color.lerp(
                  const Color(0xFF0D1825),
                  DesignTokens.neonMagenta.withValues(alpha: 0.12),
                  _glowAnim.value,
                )!,
              ],
            ),
            border: Border.all(
              color: Color.lerp(
                DesignTokens.neonCyan.withValues(alpha: 0.3),
                DesignTokens.neonMagenta.withValues(alpha: 0.6),
                _glowAnim.value,
              )!,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.neonCyan.withValues(
                  alpha: 0.1 + 0.15 * _glowAnim.value,
                ),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge - 2),
          child: Stack(
            children: [
              // Radial glow top-right
              Positioned(
                top: -60,
                right: -40,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        DesignTokens.neonMagenta.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -40,
                left: -30,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        DesignTokens.neonCyan.withValues(alpha: 0.09),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Grid pattern
              Positioned.fill(
                child: CustomPaint(painter: _GridPatternPainter()),
              ),
              // Content
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isNarrow ? 18 : 24,
                  isNarrow ? 22 : 28,
                  isNarrow ? 18 : 24,
                  isNarrow ? 18 : 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Neon badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            DesignTokens.neonCyan.withValues(alpha: 0.15),
                            DesignTokens.neonMagenta.withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: DesignTokens.neonCyan,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            'PROMOTIONAL PPV DISTRIBUTION',
                            style: TextStyle(
                              color: DesignTokens.neonCyan,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Gradient headline
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Colors.white,
                          DesignTokens.neonCyan,
                          Colors.white,
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ).createShader(bounds),
                      child: Text(
                        'Live Events, Replays,\nAnd Secure Access',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isNarrow ? 24 : 30,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Operational PPV Delivery For Combat Sports',
                      style: TextStyle(
                        color: DesignTokens.neonMagenta.withValues(alpha: 0.9),
                        fontSize: isNarrow ? 13 : 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Browse licensed events, complete secure checkout, and stream with backend-verified entitlements across live and replay windows.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: isNarrow ? 11 : 12.5,
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: isNarrow ? 16 : 20),
                    // Glowing CTAs
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push(
                              rc.RouteConstants.subscriptionPath,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    DesignTokens.neonCyan,
                                    DesignTokens.neonMagenta,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: DesignTokens.neonCyan.withValues(
                                      alpha: 0.45,
                                    ),
                                    blurRadius: 18,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'View Plans',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: DesignTokens.neonCyan.withValues(
                                    alpha: 0.45,
                                  ),
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'Browse Events',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isNarrow ? 10 : 14),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _NeonMetaChip(
                          label: 'Peak-night launches',
                          color: DesignTokens.neonCyan,
                        ),
                        _NeonMetaChip(
                          label: 'Replay retention',
                          color: DesignTokens.neonMagenta,
                        ),
                        _NeonMetaChip(
                          label: 'Social conversion',
                          color: DesignTokens.neonGreen,
                        ),
                      ],
                    ),
                    SizedBox(height: isNarrow ? 10 : 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: DesignTokens.neonGold.withValues(alpha: 0.28),
                        ),
                      ),
                      child: const Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _NeonMetaChip(
                            label: 'Hosted Stripe checkout',
                            color: DesignTokens.neonGold,
                          ),
                          _NeonMetaChip(
                            label: 'Auto entitlement unlock',
                            color: DesignTokens.neonAmber,
                          ),
                          _NeonMetaChip(
                            label: 'Broadcast-grade storefront',
                            color: DesignTokens.neonPurple,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isNarrow ? 8 : 10),
                    Text(
                      'Licensed events only. Entitlements and checkout remain backend-controlled.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: isNarrow ? 10 : 11,
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

  Widget _buildLiveIndicator() {
    final hasLive = _ppvService.livePPVs.isNotEmpty;
    if (!hasLive) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.withValues(alpha: 0.3 * _pulseAnim.value),
              DesignTokens.neonMagenta.withValues(
                alpha: 0.15 * _pulseAnim.value,
              ),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.5 + 0.5 * _pulseAnim.value),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.4 * _pulseAnim.value),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.red.withValues(
                  alpha: 0.6 + 0.4 * _pulseAnim.value,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.8 * _pulseAnim.value),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${_ppvService.livePPVs.length} LIVE',
              style: TextStyle(
                color: Colors.red.withValues(
                  alpha: 0.7 + 0.3 * _pulseAnim.value,
                ),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab Bar (pill-toggle style) ──

  SliverToBoxAdapter _buildTabBar() {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 380;
    final tabs = ['Schedule', 'Live', 'Map', 'Library'];
    final icons = [
      Icons.schedule,
      Icons.sensors,
      Icons.public,
      Icons.video_library,
    ];
    final tabAccents = [
      DesignTokens.neonCyan,
      Colors.red,
      DesignTokens.neonGreen,
      DesignTokens.neonMagenta,
    ];
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1220),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: DesignTokens.neonCyan.withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.neonCyan.withValues(alpha: 0.06),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final selected = _selectedTab == i;
            final accent = tabAccents[i];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: EdgeInsets.symmetric(vertical: isNarrow ? 8 : 10),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              accent.withValues(alpha: 0.18),
                              accent.withValues(alpha: 0.06),
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(10),
                    border: selected
                        ? Border.all(
                            color: accent.withValues(alpha: 0.5),
                            width: 1.2,
                          )
                        : null,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.25),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icons[i],
                        size: isNarrow ? 13 : 15,
                        color: selected
                            ? accent
                            : Colors.white.withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tabs[i],
                        style: TextStyle(
                          color: selected
                              ? accent
                              : Colors.white.withValues(alpha: 0.35),
                          fontSize: isNarrow ? 10 : 11,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w500,
                          letterSpacing: selected ? 0.4 : 0.2,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(height: 3),
                        Container(
                          width: 18,
                          height: 2,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(1),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.7),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Sport Filter Pills (Kayo-style horizontal scroll) ──

  SliverToBoxAdapter _buildSportFilterPills() {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 380;
    return SliverToBoxAdapter(
      child: SizedBox(
        height: isNarrow ? 40 : 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _sportFilters.length,
          itemBuilder: (context, index) {
            final sport = _sportFilters[index];
            final selected = _selectedSport == sport;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedSport = sport),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            colors: [
                              DesignTokens.neonCyan.withValues(alpha: 0.18),
                              DesignTokens.neonMagenta.withValues(alpha: 0.10),
                            ],
                          )
                        : null,
                    color: selected ? null : const Color(0xFF0A1220),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? DesignTokens.neonCyan.withValues(alpha: 0.65)
                          : Colors.white.withValues(alpha: 0.1),
                      width: selected ? 1.5 : 1.0,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: DesignTokens.neonCyan.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: DesignTokens.neonCyan,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: DesignTokens.neonCyan.withValues(
                                    alpha: 0.8,
                                  ),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        ),
                      Text(
                        sport,
                        style: TextStyle(
                          color: selected
                              ? DesignTokens.neonCyan
                              : Colors.white.withValues(alpha: 0.5),
                          fontSize: isNarrow ? 11 : 12,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Upcoming PPVs ──

  List<Widget> _buildUpcomingPPVs() {
    var events = _ppvService.upcomingPPVs;
    // Apply sport filter (match against title, subtitle, description)
    if (_selectedSport != 'All') {
      events = events.where((e) {
        final searchText =
            '${e.title} ${e.subtitle ?? ''} ${e.description ?? ''} ${e.sport ?? ''} ${e.promotion ?? ''}'
                .toLowerCase();
        final filter = _selectedSport.toLowerCase();
        return searchText.contains(filter);
      }).toList();
    }

    if (events.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _emptyState(
            _selectedSport == 'All'
                ? 'No upcoming PPV events'
                : 'No $_selectedSport events coming up',
            Icons.event_busy,
          ),
        ),
      ];
    }

    // ── Split into sections like TrillerTV ──
    final now = DateTime.now();
    final endOfWeek = now.add(Duration(days: 7 - now.weekday % 7));
    final endOfNextWeek = endOfWeek.add(const Duration(days: 7));

    final thisWeek = events
        .where((e) => e.eventDate.isBefore(endOfWeek))
        .toList();
    final nextWeek = events
        .where(
          (e) =>
              !e.eventDate.isBefore(endOfWeek) &&
              e.eventDate.isBefore(endOfNextWeek),
        )
        .toList();
    final comingUp = events
        .where((e) => !e.eventDate.isBefore(endOfNextWeek))
        .toList();

    // ── Build sectioned list ──
    final widgets = <Widget>[];

    widgets.add(_buildPlatformStrip());

    if (thisWeek.isNotEmpty) {
      widgets.add(
        _sectionHeader(
          'This Week',
          Icons.local_fire_department,
          const Color(0xFFCF5A52),
          count: thisWeek.length,
        ),
      );
      widgets.add(
        SliverToBoxAdapter(
          child: SizedBox(
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: thisWeek.length,
              itemBuilder: (context, i) => _buildHorizontalPPVCard(thisWeek[i]),
            ),
          ),
        ),
      );
    }

    if (nextWeek.isNotEmpty) {
      widgets.add(
        _sectionHeader(
          'Next Week',
          Icons.event,
          DesignTokens.ppvAccent,
          count: nextWeek.length,
        ),
      );
      widgets.add(
        SliverToBoxAdapter(
          child: SizedBox(
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: nextWeek.length,
              itemBuilder: (context, i) => _buildHorizontalPPVCard(nextWeek[i]),
            ),
          ),
        ),
      );
    }

    if (comingUp.isNotEmpty) {
      widgets.add(
        _sectionHeader(
          'Coming Up',
          Icons.calendar_month,
          DesignTokens.shellAccentSoft,
          count: comingUp.length,
        ),
      );
      widgets.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildProfessionalPosterCard(comingUp[index]),
            childCount: comingUp.length,
          ),
        ),
      );
    }

    widgets.add(_buildStreamingFooter());

    return widgets;
  }

  // ── Horizontal PPV Card (TrillerTV-style tile) ──

  Widget _buildHorizontalPPVCard(PPVEvent ppv) {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 380;
    final palette = eventPaletteForTitle(ppv.title);
    final mainFight = ppv.fightCard.isNotEmpty ? ppv.fightCard.first : null;
    final presentation = PPVPresentationModel.fromEvent(ppv);
    final useGeneratedPoster =
        presentation.posterMode == PosterRenderMode.generatedCard;

    return GestureDetector(
      onTap: () => _showPPVDetail(ppv),
      child: Container(
        width: isNarrow ? 176 : 200,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.bg1, palette.bg2],
          ),
          border: Border.all(color: palette.accent.withValues(alpha: 0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top image area with sport badge
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Remote poster art when available, otherwise render a richer
                    // data-driven card instead of sparse generated thumbnail assets.
                    if (!useGeneratedPoster)
                      DFCPosterFrame(
                        imageUrl: presentation.posterUrl,
                        borderRadius: BorderRadius.zero,
                        background: _buildGeneratedTileArtwork(ppv),
                        errorWidget: const SizedBox.shrink(),
                        loadingWidget: Container(
                          color: Colors.black.withValues(alpha: 0.12),
                        ),
                      )
                    else
                      Positioned.fill(child: _buildGeneratedTileArtwork(ppv)),
                    // Bottom gradient overlay for readability
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Sport/promotion badge
                    if (ppv.promotion != null || ppv.sport != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: palette.accent.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            (ppv.promotion ?? ppv.sport ?? '').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    // Platform badge
                    if (ppv.streamPlatforms.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ppv.streamPlatforms.first,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Bottom info section
              Container(
                padding: EdgeInsets.all(isNarrow ? 8 : 10),
                color: const Color(0xFF0A0E1A),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date + time
                    Text(
                      _formatEventDate(ppv.eventDate),
                      style: TextStyle(
                        color: palette.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Title
                    Text(
                      ppv.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isNarrow ? 12 : 13,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    if (ppv.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        ppv.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: isNarrow ? 9.5 : 10,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Price + platform
                    Row(
                      children: [
                        if (ppv.standardPriceCents > 0)
                          Text(
                            'PPV \$${ppv.standardPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: palette.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        else
                          Text(
                            'INCLUDED',
                            style: TextStyle(
                              color: Colors.greenAccent.withValues(alpha: 0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        const Spacer(),
                        if (mainFight != null)
                          Icon(
                            Icons.sports_mma,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.3),
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

  Widget _buildGeneratedTileArtwork(PPVEvent ppv) {
    final palette = eventPaletteForTitle(ppv.title);
    final mainFight = ppv.fightCard.isNotEmpty ? ppv.fightCard.first : null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.bg1,
            palette.bg2,
            Colors.black.withValues(alpha: 0.92),
          ],
          stops: const [0.0, 0.42, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -18,
            bottom: -22,
            child: Icon(
              palette.icon,
              size: 104,
              color: palette.accent.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ppv.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: 0.2,
                  ),
                ),
                if (ppv.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    ppv.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.accent.withValues(alpha: 0.92),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (mainFight != null)
            Positioned(
              left: 14,
              right: 14,
              bottom: 16,
              child: Column(
                children: [
                  Text(
                    mainFight.fighter1Name.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.94),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'VS',
                    style: TextStyle(
                      color: palette.accent,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mainFight.fighter2Name.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.94),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            )
          else
            Center(
              child: Icon(
                palette.icon,
                size: 54,
                color: palette.accent.withValues(alpha: 0.45),
              ),
            ),
        ],
      ),
    );
  }

  String _formatEventDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
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
    ];
    final dayStr = days[date.weekday - 1];
    final monthStr = months[date.month - 1];
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final min = date.minute.toString().padLeft(2, '0');
    return '$dayStr $monthStr ${date.day} | $hour:$min $amPm';
  }

  // ── Streaming Platform Strip (like TrillerTV top nav) ──

  SliverToBoxAdapter _buildPlatformStrip() {
    const platforms = [
      ('Main Event', Icons.tv, Color(0xFFFF4500)),
      ('Kayo', Icons.sports, Color(0xFF00C853)),
      ('TrillerTV+', Icons.play_circle, Color(0xFFE040FB)),
      ('Paramount+', Icons.movie, Color(0xFF2962FF)),
      ('ESPN+', Icons.sports_mma, Color(0xFFFF1744)),
      ('DAZN', Icons.live_tv, Color(0xFFFFD600)),
      ('BKFC App', Icons.front_hand, Color(0xFFFF6D00)),
      ('Live Combat Sports', Icons.videocam, Color(0xFF76FF03)),
    ];

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 48,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: platforms.length,
          itemBuilder: (context, i) {
            final (name, icon, color) = platforms[i];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 6),
                  Text(
                    name,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Live PPVs (horizontal scroll + vertical list) ──

  List<Widget> _buildLivePPVs() {
    final events = _ppvService.livePPVs;
    if (events.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _emptyState('No live PPV events right now', Icons.live_tv),
        ),
      ];
    }

    return [
      _sectionHeader('LIVE NOW', Icons.sensors, Colors.red),
      // Horizontal hero scroll for live events
      SliverToBoxAdapter(
        child: SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: events.length,
            itemBuilder: (context, index) => _buildLiveHeroCard(events[index]),
          ),
        ),
      ),
      _buildStreamingFooter(),
    ];
  }

  Widget _buildLiveHeroCard(PPVEvent ppv) {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 380;
    final presentation = PPVPresentationModel.fromEvent(ppv);
    final showPosterText =
        presentation.posterMode == PosterRenderMode.generatedCard;
    final showExternalMetadata =
        !presentation.metadataInsideImage &&
        presentation.posterMode == PosterRenderMode.embeddedArtwork;

    return GestureDetector(
      onTap: () => _showPPVDetail(ppv),
      child: Container(
        width: isNarrow ? 264 : 300,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Fight card poster
              FightCardPoster(
                event: ppv,
                presentation: presentation,
                height: 220,
                width: isNarrow ? 264 : 300,
                showHeader: false,
                showStatusBadge: false,
                showUndercard: false,
                showFooter: false,
              ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
              // LIVE badge
              Positioned(
                top: 12,
                left: 12,
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, _) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(
                            alpha: 0.5 * _pulseAnim.value,
                          ),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Title + price at bottom
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showPosterText || showExternalMetadata) ...[
                      Text(
                        ppv.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isNarrow ? 14 : 16,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      if (ppv.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          ppv.subtitle!,
                          style: TextStyle(
                            color: DesignTokens.neonCyan.withValues(alpha: 0.9),
                            fontSize: isNarrow ? 11 : 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                DesignTokens.neonCyan,
                                DesignTokens.neonMagenta,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'WATCH NOW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '\$${ppv.standardPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
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

  // ── My PPVs ──

  List<Widget> _buildMyPPVs() {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) {
      return [
        SliverToBoxAdapter(
          child: _emptyState(
            'Sign in to see your purchased PPVs',
            Icons.lock_outline,
          ),
        ),
      ];
    }

    final purchases = _ppvService.userPurchases;
    if (purchases.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _emptyState(
            'No purchases yet. Browse upcoming events!',
            Icons.shopping_bag_outlined,
          ),
        ),
      ];
    }

    return [
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final purchase = purchases[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DesignTokens.neonCyan.withValues(alpha: 0.15),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
                  ),
                ),
                child: const Icon(Icons.live_tv, color: Colors.white, size: 24),
              ),
              title: Text(
                _eventTitleForPurchase(purchase),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                '${purchase.tier.name.toUpperCase()} \u2022 \$${purchase.pricePaid.toStringAsFixed(2)}',
                style: TextStyle(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.neonGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'OWNED',
                  style: TextStyle(
                    color: DesignTokens.neonGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              onTap: () {
                context.push(
                  rc.RouteConstants.ppvEventById.replaceFirst(
                    ':id',
                    purchase.ppvEventId,
                  ),
                );
              },
            ),
          );
        }, childCount: purchases.length),
      ),
      _buildStreamingFooter(),
    ];
  }

  // ── PPV Card ──

  Widget _buildProfessionalPosterCard(PPVEvent ppv) {
    final subtitle =
        '${_formatEventDate(ppv.eventDate)} • ${ppv.promotion ?? 'DFC'}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: PosterCard(
        title: ppv.title,
        subtitle: subtitle,
        posterUrl: ppv.posterUrl ?? '',
        price: ppv.isPresale ? ppv.earlyBirdPrice : ppv.standardPrice,
        onBuy: () => _showPPVDetail(ppv),
        onOpen: () => _showPPVDetail(ppv),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildPPVCard(PPVEvent ppv, {bool isLive = false}) {
    final daysUntil = ppv.eventDate.difference(DateTime.now()).inDays;
    final isPresale = ppv.status == PPVStatus.presale;
    final isCurrentlyLive = isLive || ppv.status == PPVStatus.live;
    final presentation = PPVPresentationModel.fromEvent(ppv);
    final showPosterText =
        presentation.posterMode == PosterRenderMode.generatedCard;
    final showExternalMetadata =
        !presentation.metadataInsideImage &&
        presentation.posterMode == PosterRenderMode.embeddedArtwork;
    final actionLabel = isCurrentlyLive
        ? 'WATCH LIVE'
        : ppv.isOnSale
        ? (isPresale ? 'LOCK PRESALE' : 'BUY NOW')
        : 'VIEW CARD';
    final actionGradient = isCurrentlyLive
        ? const [Color(0xFFFF3358), Color(0xFFFF7A45)]
        : ppv.isOnSale
        ? const [DesignTokens.neonMagenta, DesignTokens.neonCyan]
        : [
            Colors.white.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.18),
          ];

    return GestureDetector(
      onTap: () => _showPPVDetail(ppv),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLive
                ? Colors.red.withValues(alpha: 0.4)
                : DesignTokens.neonCyan.withValues(alpha: 0.12),
          ),
          boxShadow: isLive
              ? [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster / Hero
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  FightCardPoster(
                    event: ppv,
                    presentation: presentation,
                    height: 180,
                    width: double.infinity,
                    showHeader: false,
                    showStatusBadge: false,
                    showUndercard: false,
                    showFooter: false,
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Status badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(ppv.status).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ppv.statusLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // Platforms badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      children: ppv.streamPlatforms
                          .take(3)
                          .map(
                            (p) => Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                p,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  // Title overlay at bottom
                  if (showPosterText)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ppv.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (ppv.subtitle != null)
                            Text(
                              ppv.subtitle!,
                              style: TextStyle(
                                color: DesignTokens.neonCyan.withValues(
                                  alpha: 0.9,
                                ),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Details section
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showExternalMetadata) ...[
                    Text(
                      ppv.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    if (ppv.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        ppv.subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                  // Price & countdown row
                  Row(
                    children: [
                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isPresale
                                ? [
                                    DesignTokens.neonGreen,
                                    const Color(0xFF00C853),
                                  ]
                                : [
                                    DesignTokens.neonCyan,
                                    DesignTokens.neonMagenta,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPresale
                              ? '\$${ppv.earlyBirdPrice.toStringAsFixed(2)}'
                              : '\$${ppv.standardPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (isPresale) ...[
                        const SizedBox(width: 8),
                        Text(
                          '\$${ppv.standardPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.neonGreen.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'EARLY BIRD',
                            style: TextStyle(
                              color: DesignTokens.neonGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Countdown
                      if (daysUntil > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              color: Colors.white38,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              daysUntil == 1 ? 'TOMORROW' : '$daysUntil DAYS',
                              style: TextStyle(
                                color: daysUntil <= 7
                                    ? DesignTokens.neonAmber
                                    : Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Fight card preview
                  if (ppv.fightCard.isNotEmpty) ...[
                    ...ppv.fightCard
                        .take(3)
                        .map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                if (f.isMainEvent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: DesignTokens.neonAmber.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: const Text(
                                      'ME',
                                      style: TextStyle(
                                        color: DesignTokens.neonAmber,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                if (f.isTitleFight)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Icon(
                                      Icons.emoji_events,
                                      color: DesignTokens.neonGold,
                                      size: 12,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    '${f.fighter1Name} vs ${f.fighter2Name}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  f.weightClass,
                                  style: const TextStyle(
                                    color: Colors.white30,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    if (ppv.fightCard.length > 3)
                      Text(
                        '+${ppv.fightCard.length - 3} more bouts',
                        style: TextStyle(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      ),
                  ],

                  const SizedBox(height: 12),

                  // Stats row
                  Row(
                    children: [
                      _statChip(
                        Icons.people,
                        '${_formatCount(ppv.purchaseCount)} buys',
                      ),
                      const SizedBox(width: 12),
                      _statChip(
                        Icons.sports_mma,
                        '${ppv.fightCard.length} bouts',
                      ),
                      const Spacer(),
                      // BUY button
                      AnimatedBuilder(
                        animation: _glowAnim,
                        builder: (_, _) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: actionGradient),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isCurrentlyLive
                                            ? Colors.redAccent
                                            : DesignTokens.neonMagenta)
                                        .withValues(
                                          alpha: 0.34 + 0.22 * _glowAnim.value,
                                        ),
                                blurRadius: 16 + 8 * _glowAnim.value,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCurrentlyLive
                                    ? Icons.play_circle
                                    : (ppv.isOnSale
                                          ? Icons.bolt
                                          : Icons.visibility),
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                actionLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
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
      ),
    );
  }

  // ── PPV Detail — Navigate to full-screen globe zoom experience ──

  void _showPPVDetail(PPVEvent ppv) {
    // Navigate to full PPV Event Detail Screen with globe zoom animation
    context.push(
      rc.RouteConstants.ppvEventById.replaceFirst(':id', ppv.id),
      extra: ppv,
    );
  }

  // Old bottom sheet version (backup)

  // ── Helpers ──

  Widget _emptyState(String msg, IconData icon) {
    final accent = switch (icon) {
      Icons.lock_outline => DesignTokens.neonCyan,
      Icons.live_tv => DesignTokens.neonRed,
      Icons.shopping_bag_outlined => DesignTokens.neonGreen,
      _ => DesignTokens.neonAmber,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
      child: DFCStatePanel(
        title: 'Nothing to show right now',
        message: msg,
        icon: icon,
        accent: accent,
      ),
    );
  }

  // ── Section Header ──

  SliverToBoxAdapter _sectionHeader(
    String title,
    IconData icon,
    Color accent, {
    int? count,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.22),
                    accent.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: accent.withValues(alpha: 0.45)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(icon, color: accent, size: 16),
            ),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.white, accent.withValues(alpha: 0.8)],
              ).createShader(bounds),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.25),
                      accent.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Streaming Platform Footer (Paramount+ / Kayo style) ──

  SliverToBoxAdapter _buildStreamingFooter() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 32, 16, 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          children: [
            // Quick links row
            Wrap(
              spacing: 20,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _footerLink(
                  'Privacy Policy',
                  () => context.push(rc.RouteConstants.privacyPath),
                ),
                _footerLink(
                  'Terms of Use',
                  () => context.push(rc.RouteConstants.legalPath),
                ),
                _footerLink(
                  'Community Guidelines',
                  () => context.push(rc.RouteConstants.communityStandardsPath),
                ),
                _footerLink(
                  'Help Centre',
                  () => context.push(rc.RouteConstants.helpPath),
                ),
                _footerLink(
                  'Supported Devices',
                  () => context.push(rc.RouteConstants.helpPath),
                ),
                _footerLink(
                  'Compare Platforms',
                  () => context.push(rc.RouteConstants.streamingComparisonPath),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
            const SizedBox(height: 16),
            // Tagline
            Text(
              'DataFightCentral is the promotional engine for combat sports worldwide.\nEvery fight. Every promotion. One platform.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 11,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            // Copyright
            Text(
              'DFC \u00a9 2026 DataFightCentral Pty Ltd. All Rights Reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.15),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerLink(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _eventTitleForPurchase(PPVPurchase purchase) {
    // Try to match the purchase to a loaded event for its title
    final allEvents = [..._ppvService.upcomingPPVs, ..._ppvService.livePPVs];
    final match = allEvents.where((e) => e.id == purchase.ppvEventId);
    if (match.isNotEmpty) return match.first.title;
    return 'PPV Event';
  }

  Widget _statChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white38, size: 13),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Color _statusColor(PPVStatus status) {
    switch (status) {
      case PPVStatus.announced:
        return DesignTokens.neonBlue;
      case PPVStatus.presale:
        return DesignTokens.neonGreen;
      case PPVStatus.onSale:
        return DesignTokens.neonCyan;
      case PPVStatus.live:
        return Colors.red;
      case PPVStatus.replay:
        return DesignTokens.neonAmber;
      case PPVStatus.expired:
        return Colors.grey;
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAP TAB — Earth zoom with gyms, events, campaigns
  // ═══════════════════════════════════════════════════════════════════════════

  static const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#0a1628"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8a92b8"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#0a1628"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#1a2a42"}]},
  {"featureType": "administrative.country", "elementType": "labels.text.fill", "stylers": [{"color": "#00d4ff"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0f1d33"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#4a6a8a"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#1a2a42"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#6a7a9a"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#0f1d33"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#5a6a8a"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#1a2a42"}]}
]
  ''';

  static final List<_MapLocationData> _mapLocations = [
    // ─── ELITE GYMS ───
    const _MapLocationData(
      'UFC Performance Institute',
      'Las Vegas',
      '🇺🇸',
      36.085,
      -115.153,
      'gym',
      'elite',
      'MMA · Wrestling · BJJ',
    ),
    const _MapLocationData(
      'Tiger Muay Thai',
      'Phuket',
      '🇹🇭',
      7.880,
      98.392,
      'gym',
      'elite',
      'Muay Thai · MMA · BJJ',
    ),
    const _MapLocationData(
      'American Top Team',
      'Coconut Creek',
      '🇺🇸',
      26.254,
      -80.178,
      'gym',
      'elite',
      'MMA · Boxing · Wrestling',
    ),
    const _MapLocationData(
      'City Kickboxing',
      'Auckland',
      '🇳🇿',
      -36.860,
      174.763,
      'gym',
      'elite',
      'MMA · Kickboxing · Wrestling',
    ),
    const _MapLocationData(
      'Evolve MMA',
      'Singapore',
      '🇸🇬',
      1.280,
      103.848,
      'gym',
      'elite',
      'MMA · Muay Thai · BJJ',
    ),
    const _MapLocationData(
      'Tristar Gym',
      'Montreal',
      '🇨🇦',
      45.502,
      -73.567,
      'gym',
      'premier',
      'MMA · Boxing · Wrestling',
    ),
    const _MapLocationData(
      'Jackson-Wink MMA',
      'Albuquerque',
      '🇺🇸',
      35.085,
      -106.650,
      'gym',
      'premier',
      'MMA · Striking · Wrestling',
    ),
    const _MapLocationData(
      'Gracie Barra HQ',
      'Rio de Janeiro',
      '🇧🇷',
      -22.906,
      -43.172,
      'gym',
      'premier',
      'BJJ · Judo · NoGi',
    ),
    const _MapLocationData(
      'Kings MMA',
      'Huntington Beach',
      '🇺🇸',
      33.660,
      -117.999,
      'gym',
      'premier',
      'MMA · Muay Thai · BJJ',
    ),
    const _MapLocationData(
      'Fairtex Training Center',
      'Pattaya',
      '🇹🇭',
      12.931,
      100.888,
      'gym',
      'premier',
      'Muay Thai · MMA',
    ),
    const _MapLocationData(
      'ATOS Jiu-Jitsu',
      'San Diego',
      '🇺🇸',
      32.826,
      -117.133,
      'gym',
      'premier',
      'BJJ · NoGi · MMA',
    ),
    const _MapLocationData(
      'Alliance BJJ',
      'São Paulo',
      '🇧🇷',
      -23.533,
      -46.625,
      'gym',
      'premier',
      'BJJ · NoGi · MMA',
    ),
    const _MapLocationData(
      'London Shootfighters',
      'London',
      '🇬🇧',
      51.464,
      -0.165,
      'gym',
      'premier',
      'MMA · Muay Thai · BJJ',
    ),
    const _MapLocationData(
      'Renzo Gracie Academy',
      'New York',
      '🇺🇸',
      40.747,
      -73.983,
      'gym',
      'standard',
      'BJJ · MMA · Wrestling',
    ),
    const _MapLocationData(
      'Team Nogueira',
      'Rio de Janeiro',
      '🇧🇷',
      -22.920,
      -43.180,
      'gym',
      'standard',
      'MMA · BJJ · Boxing',
    ),
    const _MapLocationData(
      'Sanford MMA',
      'Deerfield Beach',
      '🇺🇸',
      26.318,
      -80.099,
      'gym',
      'standard',
      'MMA · Striking · Boxing',
    ),
    // ─── AUSTRALIAN GYMS ───
    const _MapLocationData(
      'Absolute MMA',
      'Melbourne',
      '🇦🇺',
      -37.813,
      144.963,
      'gym',
      'premier',
      'MMA · BJJ · Muay Thai',
    ),
    const _MapLocationData(
      'Crows Nest Martial Arts',
      'Sydney',
      '🇦🇺',
      -33.826,
      151.203,
      'gym',
      'standard',
      'MMA · Kickboxing',
    ),
    const _MapLocationData(
      'Eternal MMA Gym',
      'Brisbane',
      '🇦🇺',
      -27.470,
      153.021,
      'gym',
      'standard',
      'MMA · BJJ · Boxing',
    ),
    const _MapLocationData(
      'Gold Coast Combat Academy',
      'Gold Coast',
      '🇦🇺',
      -27.963,
      153.382,
      'gym',
      'standard',
      'MMA · BKFC · Muay Thai',
    ),
    const _MapLocationData(
      'Perth MMA Centre',
      'Perth',
      '🇦🇺',
      -31.950,
      115.860,
      'gym',
      'standard',
      'MMA · Wrestling · BJJ',
    ),
    // ─── EVENTS (THIS WEEKEND / UPCOMING) ───
    const _MapLocationData(
      'UFC 323 Sydney',
      'Sydney',
      '🇦🇺',
      -33.847,
      151.063,
      'event',
      'ppv',
      'Main Card · PPV · This Weekend',
    ),
    const _MapLocationData(
      'ONE Friday Fights',
      'Bangkok',
      '🇹🇭',
      13.746,
      100.539,
      'event',
      'live',
      'Muay Thai · Kickboxing · LIVE',
    ),
    const _MapLocationData(
      'Bellator 310',
      'Dublin',
      '🇮🇪',
      53.342,
      -6.267,
      'event',
      'ppv',
      'MMA · PPV · This Weekend',
    ),
    const _MapLocationData(
      'RIZIN 53',
      'Tokyo',
      '🇯🇵',
      35.678,
      139.710,
      'event',
      'upcoming',
      'MMA · Kickboxing',
    ),
    const _MapLocationData(
      'Glory 102',
      'Rotterdam',
      '🇳🇱',
      51.924,
      4.477,
      'event',
      'upcoming',
      'Kickboxing · Tournament',
    ),
    const _MapLocationData(
      'Hex Fight Series',
      'Melbourne',
      '🇦🇺',
      -37.813,
      144.963,
      'event',
      'upcoming',
      'Regional MMA',
    ),
    const _MapLocationData(
      'BKFC Australia',
      'Gold Coast',
      '🇦🇺',
      -28.016,
      153.399,
      'event',
      'ppv',
      'Bare Knuckle · PPV',
    ),
    const _MapLocationData(
      'BKFC Fight Night Australia',
      'Townsville',
      '🇦🇺',
      -19.258,
      146.818,
      'event',
      'ppv',
      'Hepi vs Wisniewski II · Apr 18 · PPV',
    ),
    const _MapLocationData(
      'IBC III',
      'Brisbane',
      '🇦🇺',
      -27.471,
      153.023,
      'event',
      'upcoming',
      'International · MMA',
    ),
    const _MapLocationData(
      'UFC Fight Night',
      'Las Vegas',
      '🇺🇸',
      36.102,
      -115.173,
      'event',
      'live',
      'MMA · ESPN+ · LIVE',
    ),
    const _MapLocationData(
      'PFL Europe',
      'Paris',
      '🇫🇷',
      48.856,
      2.352,
      'event',
      'upcoming',
      'Mar 20',
    ),
    const _MapLocationData(
      'Cage Warriors 180',
      'Manchester',
      '🇬🇧',
      53.483,
      -2.244,
      'event',
      'upcoming',
      'Mar 25',
    ),
    const _MapLocationData(
      'KSW 100',
      'Warsaw',
      '🇵🇱',
      52.229,
      21.012,
      'event',
      'ppv',
      'Apr 12 · PPV',
    ),
    // ─── PINK SHIELD CAMPAIGNS ───
    const _MapLocationData(
      'Iron Will MMA Academy',
      'Los Angeles',
      '🇺🇸',
      34.052,
      -118.243,
      'campaign',
      'pinkshield',
      'DV-safe zone · Women\'s self-defense',
    ),
    const _MapLocationData(
      'Harmony Fight Club',
      'New York',
      '🇺🇸',
      40.750,
      -73.993,
      'campaign',
      'pinkshield',
      'Anti-bullying certified',
    ),
    const _MapLocationData(
      'Phoenix Rising BJJ',
      'Miami',
      '🇺🇸',
      25.761,
      -80.191,
      'campaign',
      'pinkshield',
      'LGBTQ+ friendly',
    ),
    const _MapLocationData(
      'Crows Nest Safe Space',
      'Sydney',
      '🇦🇺',
      -33.826,
      151.203,
      'campaign',
      'pinkshield',
      'DV-safe certified',
    ),
    // ─── GOLD COIN DRIVE ───
    const _MapLocationData(
      'Eternal MMA Youth Fund',
      'Brisbane',
      '🇦🇺',
      -27.470,
      153.021,
      'campaign',
      'goldcoin',
      'At-risk youth training',
    ),
    const _MapLocationData(
      'Gracie Barra Scholarship',
      'Rio de Janeiro',
      '🇧🇷',
      -22.906,
      -43.172,
      'campaign',
      'goldcoin',
      'Free BJJ for kids',
    ),
    const _MapLocationData(
      'Perth Youth Boxing',
      'Perth',
      '🇦🇺',
      -31.950,
      115.860,
      'campaign',
      'goldcoin',
      'Community-funded',
    ),
    // ─── COFFEE NOT COFFIN ───
    const _MapLocationData(
      '24hr Gold Coast Grind',
      'Gold Coast',
      '🇦🇺',
      -27.963,
      153.382,
      'campaign',
      'coffee',
      '24hr safe coffee',
    ),
    const _MapLocationData(
      'Vegas Training Fuel',
      'Las Vegas',
      '🇺🇸',
      36.085,
      -115.153,
      'campaign',
      'coffee',
      '24hr athlete café',
    ),
  ];

  void _buildMapMarkers() {
    final filtered = _filteredMapLocations;

    setState(() {
      _mapMarkers = filtered.map((loc) {
        return Marker(
          markerId: MarkerId('${loc.type}_${loc.name}'),
          position: LatLng(loc.lat, loc.lng),
          icon: _getMapMarkerIcon(loc),
          infoWindow: InfoWindow(
            title: loc.name,
            snippet: '${loc.flag} ${loc.city}',
          ),
          onTap: () => setState(() => _selectedMapLocation = loc),
        );
      }).toSet();
    });
  }

  List<_MapLocationData> get _filteredMapLocations {
    if (_mapFilter == 'ALL') {
      return _mapLocations;
    }

    return _mapLocations
        .where((loc) {
          switch (_mapFilter) {
            case 'GYMS':
              return loc.type == 'gym';
            case 'EVENTS':
              return loc.type == 'event';
            case 'CAMPAIGNS':
              return loc.type == 'campaign';
            default:
              return true;
          }
        })
        .toList(growable: false);
  }

  BitmapDescriptor _getMapMarkerIcon(_MapLocationData loc) {
    switch (loc.type) {
      case 'gym':
        return loc.tier == 'elite'
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
            : loc.tier == 'premier'
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case 'event':
        return loc.tier == 'live'
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
            : loc.tier == 'ppv'
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      case 'campaign':
        return loc.tier == 'pinkshield'
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose)
            : loc.tier == 'goldcoin'
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  Widget _buildMapView() {
    if (kIsWeb) {
      return _buildMapFallbackView();
    }

    return Stack(
      children: [
        // ─── GOOGLE MAP with Earth zoom ───
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(20.0, 0.0),
            zoom: 2.0,
            tilt: 45,
          ),
          markers: _mapMarkers,
          mapType: kIsWeb ? MapType.satellite : MapType.hybrid,
          style: kIsWeb ? null : _darkMapStyle,
          onMapCreated: (controller) {
            _mapController = controller;
          },
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          compassEnabled: false,
          onTap: (_) => setState(() => _selectedMapLocation = null),
        ),

        // ─── TOP BAR with back-to-PPV + title ───
        SafeArea(
          child: Column(
            children: [
              _buildMapTopBar(),
              const SizedBox(height: 8),
              _buildMapFilterChips(),
            ],
          ),
        ),

        // ─── STATS OVERLAY ───
        Positioned(
          bottom: _selectedMapLocation != null ? 220 : 16,
          left: 16,
          child: _buildMapStats(),
        ),

        // ─── LOCATION DETAIL PANEL ───
        if (_selectedMapLocation != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildMapDetailPanel(_selectedMapLocation!),
          ),
      ],
    );
  }

  Widget _buildMapFallbackView() {
    final filtered = _filteredMapLocations;

    return SafeArea(
      child: Column(
        children: [
          _buildMapTopBar(),
          const SizedBox(height: 8),
          _buildMapFilterChips(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF12121A).withAlpha(220),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: DesignTokens.neonCyan.withAlpha(45)),
              ),
              child: const Text(
                'Interactive Google Maps is disabled on web here. DFC fallback mode is active so gyms, events, and campaigns still load reliably.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF06101C),
                        Color(0xFF0A1628),
                        Color(0xFF04070D),
                      ],
                    ),
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      _selectedMapLocation != null ? 236 : 96,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _buildMapFallbackCard(filtered[index]),
                  ),
                ),
                Positioned(
                  bottom: _selectedMapLocation != null ? 220 : 16,
                  left: 16,
                  child: _buildMapStats(),
                ),
                if (_selectedMapLocation != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildMapDetailPanel(_selectedMapLocation!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapFallbackCard(_MapLocationData loc) {
    final isSelected = identical(_selectedMapLocation, loc);
    final (accentColor, typeIcon, typeLabel) = switch (loc.type) {
      'gym' => (Colors.red, Icons.fitness_center, loc.tier.toUpperCase()),
      'event' => (
        loc.tier == 'live' ? DesignTokens.neonGreen : DesignTokens.neonCyan,
        Icons.event,
        loc.tier == 'live' ? 'LIVE EVENT' : loc.tier.toUpperCase(),
      ),
      'campaign' => (
        loc.tier == 'pinkshield'
            ? const Color(0xFFFF69B4)
            : DesignTokens.neonGold,
        Icons.favorite,
        loc.tier == 'pinkshield'
            ? 'PINK SHIELD'
            : loc.tier == 'goldcoin'
            ? 'GOLD COIN'
            : 'COFFEE',
      ),
      _ => (DesignTokens.neonCyan, Icons.place, 'LOCATION'),
    };

    return GestureDetector(
      onTap: () => setState(() => _selectedMapLocation = loc),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF12121A).withAlpha(230),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor.withAlpha(170) : Colors.white12,
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withAlpha(35),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : const [],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accentColor.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(typeIcon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${loc.flag} ${loc.city} • ${loc.desc}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(28),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accentColor.withAlpha(90)),
              ),
              child: Text(
                typeLabel,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTopBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A).withAlpha(230),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.neonCyan.withAlpha(50)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => setState(() => _selectedTab = 0),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.public, color: DesignTokens.neonCyan, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'FIND GYMS & EVENTS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.push(rc.RouteConstants.googleEarthPath),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: DesignTokens.neonCyan.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DesignTokens.neonCyan.withAlpha(100)),
              ),
              child: const Text(
                'FULL MAP',
                style: TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapFilterChips() {
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _mapFilters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final filter = _mapFilters[i];
          final isActive = _mapFilter == filter;
          return GestureDetector(
            onTap: () {
              setState(() => _mapFilter = filter);
              _buildMapMarkers();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive
                    ? DesignTokens.neonCyan
                    : const Color(0xFF12121A).withAlpha(200),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isActive ? DesignTokens.neonCyan : Colors.white24,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                filter,
                style: TextStyle(
                  color: isActive ? const Color(0xFF0A0A12) : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapStats() {
    final gymCount = _mapLocations.where((l) => l.type == 'gym').length;
    final eventCount = _mapLocations.where((l) => l.type == 'event').length;
    final liveCount = _mapLocations.where((l) => l.tier == 'live').length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A).withAlpha(230),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.neonCyan.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _mapStatRow('🥊', '$gymCount Gyms', Colors.red),
          const SizedBox(height: 6),
          _mapStatRow('📍', '$eventCount Events', DesignTokens.neonCyan),
          const SizedBox(height: 6),
          _mapStatRow('🔴', '$liveCount Live Now', DesignTokens.neonGreen),
        ],
      ),
    );
  }

  Widget _mapStatRow(String emoji, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildMapDetailPanel(_MapLocationData loc) {
    Color accentColor;
    String typeLabel;
    IconData typeIcon;

    switch (loc.type) {
      case 'gym':
        accentColor = Colors.red;
        typeLabel = loc.tier.toUpperCase();
        typeIcon = Icons.fitness_center;
        break;
      case 'event':
        accentColor = loc.tier == 'live'
            ? DesignTokens.neonGreen
            : DesignTokens.neonCyan;
        typeLabel = loc.tier == 'live' ? '🔴 LIVE' : loc.tier.toUpperCase();
        typeIcon = Icons.event;
        break;
      case 'campaign':
        accentColor = loc.tier == 'pinkshield'
            ? const Color(0xFFFF69B4)
            : DesignTokens.neonGold;
        typeLabel = loc.tier == 'pinkshield'
            ? 'PINK SHIELD'
            : loc.tier == 'goldcoin'
            ? 'GOLD COIN'
            : 'COFFEE';
        typeIcon = Icons.favorite;
        break;
      default:
        accentColor = DesignTokens.neonCyan;
        typeLabel = 'LOCATION';
        typeIcon = Icons.place;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: accentColor.withAlpha(100), width: 2),
        ),
      ),
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
          const SizedBox(height: 16),
          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withAlpha(100)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(typeIcon, color: accentColor, size: 14),
                const SizedBox(width: 6),
                Text(
                  typeLabel,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            loc.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(loc.flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.city,
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            loc.desc,
            style: TextStyle(
              color: Colors.white.withAlpha(150),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(LatLng(loc.lat, loc.lng), 15),
                    );
                  },
                  icon: const Icon(Icons.zoom_in, size: 18),
                  label: const Text('ZOOM IN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _selectedMapLocation = null),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('CLOSE'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV Detail Bottom Sheet — Full event details + tier selection + purchase
/// ═══════════════════════════════════════════════════════════════════════════
class _PPVDetailSheet extends StatefulWidget {
  final PPVEvent ppv;
  final PPVService ppvService;

  const _PPVDetailSheet({required this.ppv, required this.ppvService});

  @override
  State<_PPVDetailSheet> createState() => _PPVDetailSheetState();
}

class _PPVDetailSheetState extends State<_PPVDetailSheet> {
  PPVTier _selectedTier = PPVTier.standard;
  bool _isPurchasing = false;

  int get _selectedPriceCents {
    switch (_selectedTier) {
      case PPVTier.earlyBird:
        return widget.ppv.earlyBirdPriceCents ?? widget.ppv.standardPriceCents;
      case PPVTier.premium:
        return widget.ppv.premiumPriceCents ?? widget.ppv.standardPriceCents;
      case PPVTier.vip:
        return widget.ppv.vipPriceCents ?? widget.ppv.standardPriceCents;
      case PPVTier.standard:
        return widget.ppv.standardPriceCents;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ppv = widget.ppv;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: DesignTokens.neonCyan.withValues(alpha: 0.15),
          ),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            // Drag handle
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
            const SizedBox(height: 16),

            // Title
            Text(
              ppv.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            if (ppv.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                ppv.subtitle!,
                style: const TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 8),

            // Date & venue
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.white38,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  '${ppv.eventDate.day}/${ppv.eventDate.month}/${ppv.eventDate.year}',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, color: Colors.white38, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${ppv.eventDate.hour}:${ppv.eventDate.minute.toString().padLeft(2, '0')} AEST',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            if (ppv.description != null)
              Text(
                ppv.description!,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            const SizedBox(height: 20),

            // ── FULL FIGHT CARD ──
            if (ppv.fightCard.isNotEmpty) ...[
              const Text(
                'FIGHT CARD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              ...ppv.fightCard.map(
                (f) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: f.isMainEvent
                        ? DesignTokens.neonAmber.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: f.isMainEvent
                          ? DesignTokens.neonAmber.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (f.isMainEvent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: DesignTokens.neonAmber,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: const Text(
                                      'MAIN EVENT',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                if (f.isTitleFight)
                                  const Icon(
                                    Icons.emoji_events,
                                    color: DesignTokens.neonGold,
                                    size: 14,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${f.fighter1Name} vs ${f.fighter2Name}',
                              style: TextStyle(
                                color: Colors.white.withValues(
                                  alpha: f.isMainEvent ? 1.0 : 0.8,
                                ),
                                fontSize: f.isMainEvent ? 15 : 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            f.weightClass,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            '${f.rounds} Rounds',
                            style: const TextStyle(
                              color: Colors.white24,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── TIER SELECTION ──
            const Text(
              'SELECT YOUR TIER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            _buildTierOption(
              PPVTier.standard,
              'STANDARD',
              'Live stream + predictions',
              ppv.standardPriceCents,
              DesignTokens.neonCyan,
            ),
            if (ppv.earlyBirdPriceCents != null &&
                ppv.status == PPVStatus.presale)
              _buildTierOption(
                PPVTier.earlyBird,
                'EARLY BIRD',
                'Live stream + predictions (limited)',
                ppv.earlyBirdPriceCents!,
                DesignTokens.neonGreen,
              ),
            if (ppv.premiumPriceCents != null)
              _buildTierOption(
                PPVTier.premium,
                'PREMIUM',
                'Live + 30-day replay + bonus content',
                ppv.premiumPriceCents!,
                DesignTokens.neonMagenta,
              ),
            if (ppv.vipPriceCents != null)
              _buildTierOption(
                PPVTier.vip,
                'VIP',
                'Live + replay + multi-cam + backstage + chat',
                ppv.vipPriceCents!,
                DesignTokens.neonGold,
              ),

            const SizedBox(height: 24),

            // ── PURCHASE BUTTON ──
            if (ppv.isOnSale)
              GestureDetector(
                onTap: _isPurchasing ? null : _handlePurchase,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _isPurchasing
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.bolt,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'SECURE CHECKOUT — \$${(_selectedPriceCents / 100).toStringAsFixed(2)} ${ppv.currency}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.verified_user,
                    size: 14,
                    color: DesignTokens.neonGreen,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hosted Stripe checkout. Entitlement unlocks automatically after payment confirmation.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // WATCH LIVE button — navigates to DFC stream viewer
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  final nav = GoRouter.of(context);
                  nav.go(
                    rc.RouteConstants.ppvWatchById.replaceFirst(':id', ppv.id),
                  );
                },
                icon: const Icon(Icons.play_circle_fill, size: 20),
                label: Text(
                  ppv.status == PPVStatus.live
                      ? 'WATCH LIVE NOW'
                      : ppv.status == PPVStatus.replay
                      ? 'WATCH REPLAY'
                      : 'GO TO STREAM PAGE',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DesignTokens.neonCyan,
                  side: BorderSide(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Features
            if (ppv.chatEnabled ||
                ppv.multiCamEnabled ||
                ppv.predictionsEnabled)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (ppv.chatEnabled) _featureChip('💬 Live Chat'),
                  if (ppv.multiCamEnabled) _featureChip('📹 Multi-Cam'),
                  if (ppv.predictionsEnabled) _featureChip('🎯 Predictions'),
                  _featureChip('📊 Live Stats'),
                  _featureChip('🔔 Round Alerts'),
                ],
              ),

            const SizedBox(height: 16),

            // Platforms
            Row(
              children: [
                const Text(
                  'Available on: ',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                ...ppv.streamPlatforms.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      p,
                      style: const TextStyle(
                        color: DesignTokens.neonCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // DFC branding
            Center(
              child: Text(
                'DFC — THE PROMOTIONAL ENGINE',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.15),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierOption(
    PPVTier tier,
    String name,
    String desc,
    int priceCents,
    Color accent,
  ) {
    final selected = _selectedTier == tier;
    return GestureDetector(
      onTap: () => setState(() => _selectedTier = tier),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.06),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? accent : Colors.transparent,
                border: Border.all(
                  color: selected ? accent : Colors.white30,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: selected ? accent : Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              '\$${(priceCents / 100).toStringAsFixed(2)}',
              style: TextStyle(
                color: selected ? accent : Colors.white54,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white60, fontSize: 11),
      ),
    );
  }

  Future<void> _handlePurchase() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to purchase PPV events.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isPurchasing = true);

    try {
      await widget.ppvService.purchasePPV(
        userId: userId,
        ppvEvent: widget.ppv,
        tier: _selectedTier,
      );

      if (mounted) {
        setState(() => _isPurchasing = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🔥 Opening Stripe checkout for ${widget.ppv.title}…',
            ),
            backgroundColor: DesignTokens.neonGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPurchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ─── Neon meta chip ───────────────────────────────────────────────────────────

class _NeonMetaChip extends StatelessWidget {
  const _NeonMetaChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 8),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withValues(alpha: 0.9),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Grid pattern painter ──────────────────────────────────────────────────────

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAP LOCATION DATA MODEL
// ═══════════════════════════════════════════════════════════════════════════════

class _MapLocationData {
  final String name;
  final String city;
  final String flag;
  final double lat;
  final double lng;
  final String type;
  final String tier;
  final String desc;

  const _MapLocationData(
    this.name,
    this.city,
    this.flag,
    this.lat,
    this.lng,
    this.type,
    this.tier,
    this.desc,
  );
}
