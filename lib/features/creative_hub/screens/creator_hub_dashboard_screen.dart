import 'package:flutter/material.dart' hide RouterConfig;
import 'package:go_router/go_router.dart';
import '../../../core/config/router_config.dart';
import '../../../core/theme/design_tokens.dart';

/// Creator Hub — central dashboard linking ALL content creation tools.
class CreatorHubDashboardScreen extends StatelessWidget {
  const CreatorHubDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'Creator Hub',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: DesignTokens.neonCyan),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Hero Banner ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.neonCyan.withValues(alpha: 0.12),
                  DesignTokens.neonMagenta.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DesignTokens.neonCyan.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: DesignTokens.neonCyan,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Content Creation Suite',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Everything you need to create, edit, and distribute fight content.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Create ──
          _sectionHeader('CREATE'),
          const SizedBox(height: 10),
          const _ToolGrid(
            tools: [
              _HubTool(
                'Viral Templates',
                Icons.trending_up,
                DesignTokens.neonRed,
                'Browse & remix trending post formats',
                routeName: RouterConfig.viralPostTemplate,
              ),
              _HubTool(
                'Thread Composer',
                Icons.view_stream,
                DesignTokens.neonCyan,
                'Write multi-tweet threads',
                routeName: RouterConfig.twitterThreadComposer,
              ),
              _HubTool(
                'Script Writer',
                Icons.movie_creation_outlined,
                DesignTokens.neonAmber,
                'YouTube scripts + teleprompter',
                routeName: RouterConfig.youtubeScriptWriter,
              ),
              _HubTool(
                'Post Preview',
                Icons.facebook,
                DesignTokens.neonCyan,
                'Facebook/social post mockups',
                routeName: RouterConfig.facebookPostPreview,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Edit & Polish ──
          _sectionHeader('EDIT & POLISH'),
          const SizedBox(height: 10),
          const _ToolGrid(
            tools: [
              _HubTool(
                'Quick Edit',
                Icons.auto_fix_high,
                DesignTokens.neonGreen,
                'AI text transforms — punchier, expand, fix',
                routeName: RouterConfig.aiQuickEdit,
              ),
              _HubTool(
                'Brand Voices',
                Icons.record_voice_over,
                DesignTokens.neonMagenta,
                'Switch AI tone & personality',
                routeName: RouterConfig.brandVoiceManager,
              ),
              _HubTool(
                'Promo Video',
                Icons.videocam,
                DesignTokens.neonRed,
                'Photos → fight promo clips',
                routeName: RouterConfig.promoVideoEditor,
              ),
              _HubTool(
                'Creative Studio',
                Icons.palette,
                DesignTokens.neonGold,
                'PosterBoy, AI images & gallery',
                routeName: RouterConfig.creativeHub,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Distribute ──
          _sectionHeader('DISTRIBUTE'),
          const SizedBox(height: 10),
          const _ToolGrid(
            tools: [
              _HubTool(
                'Social Queue',
                Icons.schedule,
                DesignTokens.neonAmber,
                'Buffer-style post scheduling',
                routeName: RouterConfig.socialQueue,
              ),
              _HubTool(
                'Content Calendar',
                Icons.calendar_month,
                DesignTokens.neonCyan,
                'Visual week planner',
                routeName: RouterConfig.socialCommandCenter,
              ),
              _HubTool(
                'Content Pipeline',
                Icons.moving,
                DesignTokens.neonGreen,
                'Kanban flow: intake → publish',
                routeName: RouterConfig.contentPipelineDashboard,
              ),
              _HubTool(
                'Link in Bio',
                Icons.link,
                DesignTokens.neonMagenta,
                'Smart link page for profiles',
                routeName: RouterConfig.linkInBio,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Grow ──
          _sectionHeader('GROW'),
          const SizedBox(height: 10),
          const _ToolGrid(
            tools: [
              _HubTool(
                'Local Marketing',
                Icons.storefront,
                DesignTokens.neonGold,
                'Gym & promoter local toolkit',
                routeName: RouterConfig.localBusinessMarketing,
              ),

              _HubTool(
                'UTM Builder',
                Icons.insert_link,
                DesignTokens.neonCyan,
                'Tracked marketing links',
                routeName: RouterConfig.utmLinkBuilder,
              ),
              _HubTool(
                'QR Promos',
                Icons.qr_code,
                DesignTokens.neonAmber,
                'QR codes for events & links',
                routeName: RouterConfig.qrPromo,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Analyze ──
          _sectionHeader('ANALYZE'),
          const SizedBox(height: 10),
          const _ToolGrid(
            tools: [
              _HubTool(
                'Marketing HQ',
                Icons.rocket_launch,
                DesignTokens.neonRed,
                'Mission control dashboard',
                routeName: RouterConfig.marketingHQ,
              ),
              _HubTool(
                'Engagement',
                Icons.insights,
                DesignTokens.neonAmber,
                'Top content + hourly heatmap',
                routeName: RouterConfig.engagementDashboard,
              ),
              _HubTool(
                'Growth Engine',
                Icons.trending_up,
                DesignTokens.neonGreen,
                'Experiments & viral hooks',
                routeName: RouterConfig.growthEngineDashboard,
              ),
              _HubTool(
                'Cost Estimator',
                Icons.calculate,
                DesignTokens.neonMagenta,
                'Ad spend & ROI calculator',
                routeName: RouterConfig.marketingCostEstimator,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.4),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }
}

// ── Tool Grid ────────────────────────────────────────────────────────────────

class _ToolGrid extends StatelessWidget {
  final List<_HubTool> tools;
  const _ToolGrid({required this.tools});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: tools.map((t) => _ToolTile(tool: t)).toList(),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final _HubTool tool;
  const _ToolTile({required this.tool});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (tool.routeName != null) {
          context.pushNamed(tool.routeName!);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          border: Border.all(color: tool.color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(tool.icon, color: tool.color, size: 22),
            const SizedBox(height: 8),
            Text(
              tool.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Text(
              tool.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Model ────────────────────────────────────────────────────────────────────

class _HubTool {
  final String title;
  final IconData icon;
  final Color color;
  final String subtitle;
  final String? routeName;

  const _HubTool(
    this.title,
    this.icon,
    this.color,
    this.subtitle, {
    this.routeName,
  });
}
