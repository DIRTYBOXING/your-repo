import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:datafightcentral/features/home/screens/home_feed_screen.dart';
import 'package:datafightcentral/features/ppv/screens/ppv_hub_screen.dart';
import 'package:datafightcentral/features/discovery/screens/explore_screen.dart';
import 'package:datafightcentral/features/profile/screens/profile_screen_v2.dart';
import 'package:datafightcentral/features/social/screens/social_hub_screen.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/config/router_config.dart' as app_router;
import '../../../core/constants/app_logos.dart';
import '../../../shared/widgets/dfc_nav_drawer.dart';
import '../../../shared/widgets/dfc_dashboard_drawer.dart';
import '../../../shared/widgets/dfc_bottom_nav.dart';
import '../../../shared/widgets/dfc_shell_top_bar.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/enhanced_friends_service.dart';
import '../../messaging/services/messaging_service.dart';
import '../../../shared/services/app_review_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DATAFIGHTCENTRAL — MASTER APP SHELL
/// Bottom nav: Feed | PPV | Explore | Social | Profile
/// Clean combat streaming layout — no toys, no overlays
/// ═══════════════════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  final int initialTab;
  final bool openDrawerOnStart;
  const HomeScreen({
    super.key,
    this.initialTab = 0,
    this.openDrawerOnStart = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<_ShellChannel> _shellChannels = [
    _ShellChannel(
      icon: Icons.dynamic_feed_rounded,
      title: 'Feed',
      subtitle: 'Live updates, stories, and fight news',
      tabIndex: 0,
    ),
    _ShellChannel(
      icon: Icons.live_tv_rounded,
      title: 'PPV',
      subtitle: 'Watch, buy, and manage premium events',
      tabIndex: 1,
    ),
    _ShellChannel(
      icon: Icons.explore_rounded,
      title: 'Explore',
      subtitle: 'Discover fighters, gyms, and events',
      tabIndex: 2,
    ),
    _ShellChannel(
      icon: Icons.people_alt_rounded,
      title: 'Network',
      subtitle: 'Messages, friends, and community surfaces',
      tabIndex: 3,
    ),
    _ShellChannel(
      icon: Icons.person_rounded,
      title: 'Profile',
      subtitle: 'Account, purchases, and identity surfaces',
      tabIndex: 4,
    ),
  ];

  static const List<_ShellQuickAction> _shellQuickActions = [
    _ShellQuickAction(
      label: 'PPV Storefront',
      hint: 'Buy the premium main card',
      icon: Icons.live_tv_rounded,
      tabIndex: 1,
      accent: DesignTokens.ppvAccent,
      routePath: app_router.RouterConfig.ppvStorePath,
    ),
    _ShellQuickAction(
      label: 'Earth Network',
      hint: 'Global discovery',
      icon: Icons.public_rounded,
      tabIndex: 2,
      accent: DesignTokens.neonCyan,
    ),
    _ShellQuickAction(
      label: 'Social Grid',
      hint: 'Community power',
      icon: Icons.people_alt_rounded,
      tabIndex: 3,
      accent: DesignTokens.neonMagenta,
    ),
    _ShellQuickAction(
      label: 'Viral Arena',
      hint: 'Trending clips & social discovery',
      icon: Icons.trending_up_rounded,
      tabIndex: -1, // Not a main tab
      accent: DesignTokens.neonRed,
      routePath: app_router.RouterConfig.viralClipsFeedPath,
    ),
    _ShellQuickAction(
      label: 'Mission Control',
      hint: 'Operate feed, clips, and promo jobs',
      icon: Icons.rocket_launch_rounded,
      tabIndex: 0,
      accent: DesignTokens.neonCyan,
      routePath: app_router.RouterConfig.missionControlPath,
    ),
    _ShellQuickAction(
      label: 'Creator Dashboard',
      hint: 'Manage your clips and earnings',
      icon: Icons.trending_up_rounded,
      tabIndex: -1, // Not a main tab
      accent: DesignTokens.neonRed,
      routePath: app_router.RouterConfig.creatorDashboardPath,
    ),
  ];

  late int _selectedIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Lazy tab cache — only build tabs when first visited
  final Map<int, Widget> _builtTabs = {};
  static const _tabCount = 5;

  Widget _tabForIndex(int index) {
    return _builtTabs.putIfAbsent(index, () {
      final tabs = <Widget>[
        _SafeTab(childBuilder: () => const HomeFeedScreen()),
        _SafeTab(childBuilder: () => const PPVHubScreen()),
        _SafeTab(childBuilder: () => const ExploreScreen()),
        _SafeTab(childBuilder: () => const SocialHubScreen()),
        _SafeTab(childBuilder: () => const ProfileScreen()),
      ];
      return RepaintBoundary(child: tabs[index]);
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab.clamp(0, _tabCount - 1);
    if (widget.openDrawerOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scaffoldKey.currentState?.openDrawer();
      });
    }
    // Production polish: track launches & prompt review after engagement
    DFCAppReviewService.trackLaunch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) DFCAppReviewService.maybeShowPrompt(context);
      });
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  bool get _useShellV2 => AppConstants.featureShellV2;

  _ShellChannel get _activeChannel => _shellChannels[_selectedIndex];

  String get _shellMissionHeadline {
    switch (_selectedIndex) {
      case 1:
        return 'PPV COMMAND ONLINE';
      case 2:
        return 'GLOBAL DISCOVERY ONLINE';
      case 3:
        return 'NETWORK SIGNAL ONLINE';
      case 4:
        return 'IDENTITY CONTROL ONLINE';
      default:
        return 'DFC COMMAND ONLINE';
    }
  }

  String get _shellMissionBody {
    switch (_selectedIndex) {
      case 1:
        return 'Turn premium fight nights into a broadcast-grade storefront with access control, replay continuity, and purchase confidence.';
      case 2:
        return 'Map gyms, promotions, and campaign lanes into one visible combat network that can scale toward 2030 and beyond.';
      case 3:
        return 'Keep the community engine moving with messaging, signal routing, and social discovery tied directly to fight commerce.';
      case 4:
        return 'Manage purchases, account trust, and fighter identity without breaking the platform shell.';
      default:
        return 'Unify social reach, PPV revenue, and real-world discovery into one operational combat platform built to protect and empower people.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.primaryBackground,
      drawer: DFCNavDrawer(
        onTabSelected: (index) {
          setState(() => _selectedIndex = index.clamp(0, _tabCount - 1));
        },
      ),
      endDrawer: const DFCDashboardDrawer(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _ShellBackdrop(selectedIndex: _selectedIndex),
          // Main tab content — lazy-loaded, only builds visited tabs
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    // On compact/mobile screens the command deck is hidden,
                    // so clear only the slim button-row height (handled by
                    // each tab's own SafeArea + SizedBox(56) spacer).
                    top: _useShellV2 && MediaQuery.of(context).size.width >= 520
                        ? 108
                        : 0,
                  ),
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: List.generate(_tabCount, (i) {
                      if (!_builtTabs.containsKey(i) && i != _selectedIndex) {
                        return const SizedBox.shrink();
                      }
                      return _tabForIndex(i);
                    }),
                  ),
                ),
              ),
            ],
          ),
          if (_useShellV2)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: _buildShellHeader(context),
            )
          else ...[
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    AppLogos.icon,
                    width: 42,
                    height: 42,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(
                      child: Text(
                        'DFC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 66,
              right: 12,
              child: _buildActionBar(context),
            ),
          ],
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Debug-mode health strip — visible indicator that app is alive
          if (kDebugMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              color: const Color(0xFF0D1117),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF39FF14),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'DFC ${kIsWeb ? "Web" : "Native"} | Tab $_selectedIndex | Demo: ${AppConstants.webDemoMode}',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          kIsWeb
              ? _buildWebBottomNav()
              : DFCBottomNav(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                ),
        ],
      ),
    );
  }

  /// Web-safe bottom nav — matches native DFCBottomNav styling without BackdropFilter
  Widget _buildWebBottomNav() {
    return DFCBottomNav(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return DFCHomeShellTopBar(
      onOpenMessaging: () => context.push('/messaging'),
      onOpenFriendRequests: () => context.push('/friend-requests'),
      onOpenDashboard: () => _scaffoldKey.currentState?.openEndDrawer(),
      onOpenAccountMenu: () => _showAccountMenu(context),
      inboxBadgeStream: () {
        try {
          final uid = context.read<AuthService>().currentUser?.uid;
          if (uid == null) return Stream.value(0);
          return context
              .read<MessagingService>()
              .totalUnreadStream(uid)
              .handleError((_) {});
        } catch (_) {
          return Stream.value(0);
        }
      }(),
      friendRequestBadgeStream: () {
        try {
          final uid = context.read<AuthService>().currentUser?.uid;
          if (uid == null) return Stream.value(0);
          return context
              .read<EnhancedFriendsService>()
              .streamPendingRequestCount()
              .handleError((_) {});
        } catch (_) {
          return Stream.value(0);
        }
      }(),
    );
  }

  Widget _buildShellHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShellButton(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  padding: const EdgeInsets.all(6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      AppLogos.icon,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Center(
                        child: Text(
                          'DFC',
                          style: TextStyle(
                            color: DesignTokens.shellText,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildShellButton(
                  onTap: () => _showChannelsModal(context),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 10 : 12,
                    vertical: 9,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.grid_view_rounded,
                        color: DesignTokens.ppvAccent,
                        size: 18,
                      ),
                      if (!compact) ...[
                        const SizedBox(width: 6),
                        const Text(
                          'Channels',
                          style: TextStyle(
                            color: DesignTokens.shellText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildActionBar(context)),
              ],
            ),
            // Command deck is only shown on wide (tablet/web) screens.
            // On compact/mobile it would wrap into multiple rows and
            // completely bury the feed content beneath it.
            if (!compact) ...[
              const SizedBox(height: 10),
              _buildShellCommandDeck(compact: false),
            ],
          ],
        );
      },
    );
  }

  Widget _buildShellCommandDeck({required bool compact}) {
    final activeChannel = _activeChannel;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 16,
        14,
        compact ? 14 : 16,
        14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: DesignTokens.shellBorder.withValues(alpha: 0.95),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.shellSurfaceRaised.withValues(alpha: 0.98),
            DesignTokens.shellSurface.withValues(alpha: 0.95),
            DesignTokens.shellOverlay.withValues(alpha: 0.98),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.neonCyan.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _shellMissionHeadline,
                      style: const TextStyle(
                        color: DesignTokens.neonCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      activeChannel.title,
                      style: TextStyle(
                        color: DesignTokens.shellText,
                        fontSize: compact ? 20 : 24,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _shellMissionBody,
                      style: const TextStyle(
                        color: DesignTokens.shellTextMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.ppvAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: DesignTokens.ppvAccent.withValues(alpha: 0.24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '2030 VECTOR',
                      style: TextStyle(
                        color: DesignTokens.ppvAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activeChannel.subtitle,
                      style: const TextStyle(
                        color: DesignTokens.shellText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
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
              _buildSignalChip('PPV READY', DesignTokens.ppvAccent),
              _buildSignalChip('SOCIAL LIVE', DesignTokens.neonMagenta),
              _buildSignalChip('EARTH ACTIVE', DesignTokens.neonCyan),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _shellQuickActions.map((action) {
              final active = action.tabIndex == _selectedIndex;
              return _buildQuickActionCard(action: action, active: active);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.9,
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required _ShellQuickAction action,
    required bool active,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (action.routePath != null) {
            context.push(action.routePath!);
            return;
          }
          setState(() => _selectedIndex = action.tabIndex);
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 168,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: active
                ? action.accent.withValues(alpha: 0.16)
                : DesignTokens.shellSurface.withValues(alpha: 0.72),
            border: Border.all(
              color: active
                  ? action.accent.withValues(alpha: 0.36)
                  : DesignTokens.shellBorder.withValues(alpha: 0.9),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: action.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.accent, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.label,
                      style: const TextStyle(
                        color: DesignTokens.shellText,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.hint,
                      style: const TextStyle(
                        color: DesignTokens.shellTextMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                active ? Icons.check_circle : Icons.arrow_forward_rounded,
                color: active ? action.accent : DesignTokens.shellTextSubtle,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShellButton({
    required Widget child,
    required VoidCallback onTap,
    required EdgeInsetsGeometry padding,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 40,
          padding: padding,
          decoration: BoxDecoration(
            color: DesignTokens.shellSurfaceRaised.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: DesignTokens.shellBorder.withValues(alpha: 0.95),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  void _showChannelsModal(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: DesignTokens.shellOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DesignTokens.shellBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Channels',
                style: TextStyle(
                  color: DesignTokens.shellText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Jump across the core DFC surfaces without changing the product chrome.',
                style: TextStyle(
                  color: DesignTokens.shellTextMuted,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              ..._shellChannels.map(
                (channel) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: DesignTokens.shellSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: DesignTokens.shellBorder.withValues(alpha: 0.9),
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(channel.icon, color: DesignTokens.ppvAccent),
                    title: Text(
                      channel.title,
                      style: const TextStyle(
                        color: DesignTokens.shellText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      channel.subtitle,
                      style: const TextStyle(
                        color: DesignTokens.shellTextMuted,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_rounded,
                      color: DesignTokens.shellTextSubtle,
                    ),
                    onTap: () {
                      Navigator.of(sheetCtx).pop();
                      setState(() => _selectedIndex = channel.tabIndex);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountMenu(BuildContext ctx) {
    final auth = ctx.read<AuthService>();
    final user = auth.userModel;
    final useShellV2 = _useShellV2;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: useShellV2
          ? DesignTokens.shellOverlay
          : DesignTokens.bgOverlay,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: useShellV2
            ? const BorderSide(color: DesignTokens.shellBorder)
            : BorderSide.none,
      ),
      builder: (sheetCtx) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: useShellV2 ? DesignTokens.shellBorder : Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // User info
              DfcCircleAvatar(
                imageUrl: user?.photoUrl,
                radius: 28,
                backgroundColor: useShellV2
                    ? DesignTokens.shellSurfaceRaised
                    : AppTheme.neonCyan.withValues(alpha: 0.16),
                borderColor: useShellV2
                    ? DesignTokens.shellBorder
                    : AppTheme.neonCyan.withValues(alpha: 0.3),
                borderWidth: 1,
                fallbackText: (user?.displayName ?? 'U')
                    .substring(0, 1)
                    .toUpperCase(),
                fallbackIconColor: useShellV2
                    ? DesignTokens.ppvAccent
                    : Colors.cyanAccent,
              ),
              const SizedBox(height: 10),
              Text(
                user?.displayName ?? 'Fight Fan',
                style: const TextStyle(
                  color: DesignTokens.shellText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                user?.email ?? '',
                style: const TextStyle(
                  color: DesignTokens.shellTextMuted,
                  fontSize: 12,
                ),
              ),
              if (user?.role != null)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: useShellV2
                        ? DesignTokens.ppvAccent.withValues(alpha: 0.12)
                        : AppTheme.neonCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user!.role.name.toUpperCase(),
                    style: TextStyle(
                      color: useShellV2
                          ? DesignTokens.ppvAccent
                          : Colors.cyanAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Divider(
                color: useShellV2
                    ? DesignTokens.shellBorder.withValues(alpha: 0.8)
                    : Colors.white12,
              ),
              // Quick actions
              ListTile(
                leading: const Icon(
                  Icons.person,
                  color: DesignTokens.shellTextMuted,
                ),
                title: const Text(
                  'Profile',
                  style: TextStyle(color: DesignTokens.shellText),
                ),
                dense: true,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  setState(() => _selectedIndex = 4);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.settings,
                  color: DesignTokens.shellTextMuted,
                ),
                title: const Text(
                  'Settings',
                  style: TextStyle(color: DesignTokens.shellText),
                ),
                dense: true,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  ctx.push('/settings');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.notifications,
                  color: DesignTokens.shellTextMuted,
                ),
                title: const Text(
                  'Notifications',
                  style: TextStyle(color: DesignTokens.shellText),
                ),
                dense: true,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  ctx.push('/notifications');
                },
              ),
              Divider(
                color: useShellV2
                    ? DesignTokens.shellBorder.withValues(alpha: 0.8)
                    : Colors.white12,
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                dense: true,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _confirmLogout(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext ctx) {
    final useShellV2 = _useShellV2;
    showDialog(
      context: ctx,
      builder: (dlg) => AlertDialog(
        backgroundColor: useShellV2
            ? DesignTokens.shellOverlay
            : DesignTokens.bgOverlay,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: useShellV2
                ? DesignTokens.shellBorder
                : Colors.redAccent.withValues(alpha: 0.3),
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.redAccent, size: 22),
            SizedBox(width: 10),
            Text('Log Out', style: TextStyle(color: DesignTokens.shellText)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: DesignTokens.shellTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlg).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: DesignTokens.shellTextSubtle),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dlg).pop();
              ctx.read<AuthService>().logout();
              GoRouter.of(ctx).go('/login');
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

/// Error boundary widget that catches build errors and shows them visually
/// instead of silently crashing the entire tab to dark/blank.
class _SafeTab extends StatefulWidget {
  final Widget Function() childBuilder;
  const _SafeTab({required this.childBuilder});

  @override
  State<_SafeTab> createState() => _SafeTabState();
}

class _SafeTabState extends State<_SafeTab> {
  Object? _error;
  Widget? _built;

  void _retry() {
    setState(() {
      _error = null;
      _built = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        color: const Color(0xFF0A0E1A),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tab failed to load',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FFF0),
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    _built ??= _safeBuild();
    return _built!;
  }

  Widget _safeBuild() {
    try {
      return widget.childBuilder();
    } catch (e, st) {
      debugPrint('_SafeTab build error: $e\n$st');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _error = e;
          });
        }
      });
      return const SizedBox.shrink();
    }
  }
}

class _ShellBackdrop extends StatelessWidget {
  final int selectedIndex;

  const _ShellBackdrop({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    if (AppConstants.featureShellV2) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF161D28),
              DesignTokens.shellBackground,
              Color(0xFF06090E),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.15,
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.72],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.06),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final accent = switch (selectedIndex) {
      0 => DesignTokens.neonCyan,
      1 => DesignTokens.neonMagenta,
      2 => DesignTokens.neonAmber,
      3 => DesignTokens.neonGreen,
      _ => DesignTokens.neonCyan,
    };

    return DecoratedBox(
      decoration: const BoxDecoration(color: AppTheme.primaryBackground),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -120,
            left: -60,
            child: _BackdropOrb(
              color: accent.withValues(alpha: 0.16),
              size: 280,
            ),
          ),
          Positioned(
            top: 80,
            right: -90,
            child: _BackdropOrb(
              color: DesignTokens.neonMagenta.withValues(alpha: 0.08),
              size: 240,
            ),
          ),
          Positioned(
            bottom: -140,
            left: 40,
            child: _BackdropOrb(
              color: DesignTokens.neonCyan.withValues(alpha: 0.06),
              size: 300,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.02),
                    AppTheme.primaryBackground,
                    AppTheme.primaryBackground,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _BackdropOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _ShellChannel {
  const _ShellChannel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tabIndex,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int tabIndex;
}

class _ShellQuickAction {
  const _ShellQuickAction({
    required this.label,
    required this.hint,
    required this.icon,
    required this.tabIndex,
    required this.accent,
    this.routePath,
  });

  final String label;
  final String hint;
  final IconData icon;
  final int tabIndex;
  final Color accent;
  final String? routePath;
}
