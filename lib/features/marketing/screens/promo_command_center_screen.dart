import 'package:flutter/material.dart' hide RouterConfig;
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/router_config.dart';
import '../../../shared/services/campaign_service.dart';
import '../../promoter/widgets/beast_mode_button.dart';

/// Promo Command Center — THE HUB
/// The Ferrari dashboard for DFC's promotional engine.
/// 8 category cards + quick actions + live stats bar + BEAST MODE.
class PromoCommandCenterScreen extends StatefulWidget {
  const PromoCommandCenterScreen({super.key});

  @override
  State<PromoCommandCenterScreen> createState() =>
      _PromoCommandCenterScreenState();
}

class _PromoCommandCenterScreenState extends State<PromoCommandCenterScreen> {
  final CampaignService _campaignService = CampaignService();
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  bool _showInstructions = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _campaignService.getMarketingStats();
      // Also grab live Firestore counts
      final postsSnap = await FirebaseFirestore.instance
          .collection('posts')
          .count()
          .get();
      final eventsSnap = await FirebaseFirestore.instance
          .collection('events')
          .count()
          .get();
      final socialSnap = await FirebaseFirestore.instance
          .collection('social_engine_posts')
          .count()
          .get();

      stats['totalPosts'] = postsSnap.count ?? 0;
      stats['totalEvents'] = eventsSnap.count ?? 0;
      stats['socialPosts'] = socialSnap.count ?? 0;

      if (mounted) {
        setState(() {
          _stats = stats;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('PROMO COMMAND CENTER'),
        backgroundColor: AppTheme.cardBackground,
        foregroundColor: AppTheme.neonCyan,
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── BEAST MODE POWER CONTROL ──────────────────────
              const BeastModeButton(),
              const SizedBox(height: 16),

              // ── INSTRUCTIONS ──────────────────────────────────
              _buildInstructionsCard(),
              const SizedBox(height: 24),

              // ── LIVE STATS BAR ────────────────────────────────
              _buildStatsBar(),
              const SizedBox(height: 24),

              // ── CATEGORY GRID ─────────────────────────────────
              Text(
                'MISSION CONTROL',
                style: AppTheme.headingLarge.copyWith(
                  color: AppTheme.neonCyan,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              _buildCategoryGrid(),
              const SizedBox(height: 24),

              // ── QUICK ACTIONS ─────────────────────────────────
              Text(
                'QUICK ACTIONS',
                style: AppTheme.headingLarge.copyWith(
                  color: AppTheme.neonMagenta,
                  letterSpacing: 2,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.neonCyan.withValues(alpha: 0.1),
            AppTheme.neonMagenta.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.neonCyan.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _showInstructions = !_showInstructions),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.neonCyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: AppTheme.neonCyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PROMOTIONAL FACTORY GUIDE',
                          style: TextStyle(
                            color: AppTheme.neonCyan,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _showInstructions
                              ? 'Tap to hide'
                              : 'Tap for instructions',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showInstructions
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppTheme.neonCyan,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppTheme.neonCyan, height: 1),
                  const SizedBox(height: 16),

                  // Beast Mode Section
                  _buildInstructionSection(
                    icon: '⚡',
                    title: 'BEAST MODE CONTROL',
                    color: AppTheme.neonCyan,
                    items: [
                      '🟢 OFF (1x) - Normal operations, steady pace',
                      '🟡 TURBO (2x) - 2x faster content, +40% viral boost',
                      '🟠 BEAST (3x) - 3x frequency, +80% hype, 4x reach',
                      '🔴 NUCLEAR (5x) - Maximum power, 5x speed, 7.5x reach',
                      '',
                      '💡 TAP to cycle modes | LONG-PRESS for instant BEAST',
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Upload Media Section
                  _buildInstructionSection(
                    icon: '📸',
                    title: 'UPLOAD PHOTOS & VIDEOS',
                    color: AppTheme.neonMagenta,
                    items: [
                      '1️⃣ Events & Promos → Create Event → Add Media',
                      '2️⃣ Social Media → Queue → New Post → Upload',
                      '3️⃣ Content Engine → Generate → Attach Media',
                      '4️⃣ Campaigns → New Campaign → Visual Assets',
                      '',
                      '📷 Photos: JPG, PNG, WebP (max 10MB)',
                      '🎥 Videos: MP4, MOV, WebM (max 100MB)',
                      '✨ Auto-optimization and compression applied',
                      '🎨 Edit with filters/effects in Creative Hub',
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Factory Functions Section
                  _buildInstructionSection(
                    icon: '🏭',
                    title: 'FACTORY FUNCTIONS',
                    color: AppTheme.neonCyan,
                    items: [
                      '📝 Content Engine:',
                      '   → Swarm AI bot auto-generates posts',
                      '   → 10+ content types (hype, stats, predictions)',
                      '   → Review queue before publishing',
                      '',
                      '📱 Social Media Queue:',
                      '   → Schedule posts across platforms',
                      '   → Optimal posting times suggested',
                      '   → Bulk upload and batch scheduling',
                      '',
                      '🎉 Events & Promos:',
                      '   → Create fight events with posters',
                      '   → Generate promo videos automatically',
                      '   → Countdown timers and reminders',
                      '',
                      '🔍 SEO & Discovery:',
                      '   → Keyword research for hashtags',
                      '   → Trending topics analyzer',
                      '   → Competitor hashtag tracking',
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Advanced Features Section
                  _buildInstructionSection(
                    icon: '🚀',
                    title: 'ADVANCED FEATURES',
                    color: AppTheme.neonPurple,
                    items: [
                      '📊 Analytics Dashboard:',
                      '   → Real-time engagement tracking',
                      '   → Conversion rate optimization',
                      '   → A/B test results comparison',
                      '',
                      '🎪 Campaign Manager:',
                      '   → Multi-channel campaigns',
                      '   → Audience targeting by demographics',
                      '   → Budget allocation and ROI tracking',
                      '',
                      '📲 QR Code Generator:',
                      '   → Dynamic QR codes for events',
                      '   → Track scans and conversions',
                      '   → Custom branding and colors',
                      '',
                      '📅 Content Calendar:',
                      '   → Visual drag-and-drop scheduling',
                      '   → Recurring post templates',
                      '   → Team collaboration features',
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Pro Tips Section
                  _buildInstructionSection(
                    icon: '💡',
                    title: 'PRO TIPS & WORKFLOWS',
                    color: AppTheme.neonGreen,
                    items: [
                      '🎯 Daily Workflow:',
                      '   1. Check stats bar for performance',
                      '   2. Review Content Engine queue',
                      '   3. Schedule 3-5 posts in Social Queue',
                      '   4. Monitor engagement in Analytics',
                      '',
                      '⚡ Quick Wins:',
                      '   → Use TURBO during steady growth periods',
                      '   → Activate BEAST for event week launches',
                      '   → Go NUCLEAR for major announcements',
                      '   → QR codes boost offline-to-online traffic',
                      '',
                      '🎨 Content Best Practices:',
                      '   → Mix video (60%) and photo (40%) content',
                      '   → Post 3-5x daily for maximum reach',
                      '   → Use trending hashtags from SEO tool',
                      '   → A/B test headlines before major drops',
                      '',
                      '🔄 Pull down anywhere to refresh stats',
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Limits & Quotas Section
                  _buildInstructionSection(
                    icon: '⚖️',
                    title: 'LIMITS & QUOTAS',
                    color: AppTheme.neonOrange,
                    items: [
                      '📊 Daily Limits:',
                      '   → Social posts: 50 per day',
                      '   → Campaign creates: 10 per day',
                      '   → QR code generates: 100 per day',
                      '',
                      '💾 Storage & Media:',
                      '   → Photo max: 10MB per file',
                      '   → Video max: 100MB per file',
                      '   → Total storage: 5GB (upgradeable)',
                      '',
                      '⚡ Beast Mode:',
                      '   → TURBO: 4 hours max per session',
                      '   → BEAST: 2 hours max per session',
                      '   → NUCLEAR: 30 minutes max per session',
                      '   → Cooldown: 1 hour between activations',
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Permissions Section
                  _buildInstructionSection(
                    icon: '🔐',
                    title: 'USER PERMISSIONS',
                    color: AppTheme.neonPurple,
                    items: [
                      '👤 Fighter Role:',
                      '   → View analytics only',
                      '   → Cannot create campaigns',
                      '   → Can submit content for review',
                      '',
                      '📣 Promoter Role:',
                      '   → Full access to all tools',
                      '   → Create & manage campaigns',
                      '   → Activate Beast Mode',
                      '   → Access Swarm AI controls',
                      '',
                      '⚡ Admin Role:',
                      '   → All Promoter permissions',
                      '   → Access Content Command Center',
                      '   → Manage user roles & permissions',
                      '   → System-wide settings',
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Troubleshooting Section
                  _buildInstructionSection(
                    icon: '🔧',
                    title: 'TROUBLESHOOTING',
                    color: Colors.redAccent,
                    items: [
                      '❌ Upload Failed:',
                      '   → Check file size (10MB photo / 100MB video)',
                      '   → Verify format (JPG, PNG, MP4, MOV, WebM)',
                      '   → Check internet connection',
                      '   → Try compressing file before upload',
                      '',
                      '⚡ Beast Mode Not Activating:',
                      '   → Ensure you have Promoter/Admin role',
                      '   → Check for active cooldown period',
                      '   → Verify not at session time limit',
                      '   → Refresh app and try again',
                      '',
                      '📱 Posts Not Publishing:',
                      '   → Review queue for pending approval',
                      '   → Check daily post limit (50/day)',
                      '   → Verify scheduled time is future',
                      '   → Ensure all required fields filled',
                      '',
                      '📞 Still Having Issues?',
                      '   → Contact support via Settings → Help',
                      '   → Report bugs on GitHub Issues',
                      '   → Check docs/ folder for guides',
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Warning banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.neonOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.neonOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.neonOrange,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'BEAST & NUCLEAR modes consume more resources. '
                            'Monitor performance and deactivate if needed.',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _showInstructions
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionSection({
    required String icon,
    required String title,
    required Color color,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 26, bottom: 4),
            child: Text(
              item,
              style: TextStyle(
                color: item.isEmpty
                    ? Colors.transparent
                    : AppTheme.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsBar() {
    if (_loading) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.neonCyan),
        ),
      );
    }

    final statItems = [
      _StatItem(
        'Campaigns',
        '${_stats['totalCampaigns'] ?? 0}',
        AppTheme.neonCyan,
      ),
      _StatItem(
        'Active',
        '${_stats['activeCampaigns'] ?? 0}',
        AppTheme.neonGreen,
      ),
      _StatItem('Posts', '${_stats['totalPosts'] ?? 0}', AppTheme.neonMagenta),
      _StatItem('Events', '${_stats['totalEvents'] ?? 0}', AppTheme.neonOrange),
      _StatItem('Social', '${_stats['socialPosts'] ?? 0}', AppTheme.neonPurple),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: statItems
            .map(
              (s) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.value,
                    style: TextStyle(
                      color: s.color,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.label,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      _Category(
        icon: Icons.auto_awesome,
        title: 'Content Engine',
        subtitle: 'Swarm AI + Pipeline',
        color: AppTheme.neonCyan,
        route: RouterConfig.contentPipelineDashboardPath,
      ),
      _Category(
        icon: Icons.share,
        title: 'Social Media',
        subtitle: 'Queue & Distribute',
        color: AppTheme.neonMagenta,
        route: RouterConfig.socialQueuePath,
      ),
      _Category(
        icon: Icons.event,
        title: 'Events & Promos',
        subtitle: 'Create & Promote',
        color: AppTheme.neonOrange,
        route: RouterConfig.eventsPath,
      ),
      _Category(
        icon: Icons.analytics,
        title: 'Analytics',
        subtitle: 'KPIs & Engagement',
        color: AppTheme.neonPurple,
        route: RouterConfig.marketingAnalyticsPath,
      ),
      _Category(
        icon: Icons.campaign,
        title: 'Campaigns',
        subtitle: 'A/B Tests & Targeting',
        color: const Color(0xFF4A9EFF),
        route: RouterConfig.marketingHQPath,
      ),
      _Category(
        icon: Icons.qr_code,
        title: 'QR & Links',
        subtitle: 'QR Codes & Link-in-Bio',
        color: const Color(0xFFFFD700),
        route: RouterConfig.qrPromoPath,
      ),
      _Category(
        icon: Icons.calendar_month,
        title: 'Content Calendar',
        subtitle: 'Schedule & Plan',
        color: const Color(0xFFFF6B6B),
        route: RouterConfig.contentCalendarPath,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return _buildCategoryCard(cat);
      },
    );
  }

  Widget _buildCategoryCard(_Category cat) {
    return GestureDetector(
      onTap: () => context.push(cat.route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cat.color.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: cat.color.withValues(alpha: 0.1),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(cat.icon, color: cat.color, size: 32),
            const SizedBox(height: 8),
            Text(
              cat.title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              cat.subtitle,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        'New Campaign',
        Icons.add_circle,
        AppTheme.neonCyan,
        () => context.push(RouterConfig.marketingHQPath),
      ),
      _QuickAction(
        'Post Now',
        Icons.send,
        AppTheme.neonMagenta,
        () => context.push(RouterConfig.socialQueuePath),
      ),
      _QuickAction(
        'Generate QR',
        Icons.qr_code_2,
        AppTheme.neonGreen,
        () => context.push(RouterConfig.qrPromoPath),
      ),
      _QuickAction(
        'Link-in-Bio',
        Icons.link,
        AppTheme.neonOrange,
        () => context.push(RouterConfig.linkInBioPath),
      ),
      _QuickAction(
        'View Pipeline',
        Icons.water,
        AppTheme.neonPurple,
        () => context.push(RouterConfig.contentPipelineDashboardPath),
      ),
      _QuickAction(
        'Engagement',
        Icons.trending_up,
        const Color(0xFFFFD700),
        () => context.push(RouterConfig.engagementDashboardPath),
      ),
      _QuickAction(
        'Poster Maker',
        Icons.brush,
        const Color(0xFFFF6B6B),
        () => context.push(RouterConfig.posterGeneratorPath),
      ),
      _QuickAction(
        'Warehouse',
        Icons.factory,
        const Color(0xFF00E5FF),
        () => context.push(RouterConfig.promotionWarehousePath),
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: actions
          .map(
            (a) => ActionChip(
              avatar: Icon(a.icon, color: a.color, size: 18),
              label: Text(
                a.label,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
              ),
              backgroundColor: AppTheme.cardBackground,
              side: BorderSide(color: a.color.withValues(alpha: 0.4)),
              onPressed: a.onTap,
            ),
          )
          .toList(),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final Color color;
  _StatItem(this.label, this.value, this.color);
}

class _Category {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;
  _Category({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
  });
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _QuickAction(this.label, this.icon, this.color, this.onTap);
}
