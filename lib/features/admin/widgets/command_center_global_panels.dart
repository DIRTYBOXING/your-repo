import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/router_config.dart' as rc;
import '../../../shared/services/global_pricing_service.dart';
import '../../../shared/services/global_distribution_service.dart';
import '../../../shared/services/global_ranking_service.dart';
import '../../../shared/services/auto_caption_service.dart';
import '../../../shared/services/global_seo_service.dart';

/// Command Centre Global Panels — live readout of all 5 Global Expansion Engines.
class CommandCenterGlobalPanels extends StatelessWidget {
  const CommandCenterGlobalPanels({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader('GLOBAL EXPANSION ENGINES'),
        const SizedBox(height: 10),
        _buildPricingPanel(context),
        const SizedBox(height: 10),
        _buildDistributionPanel(context),
        const SizedBox(height: 10),
        _buildRankingPanel(context),
        const SizedBox(height: 10),
        _buildCaptionPanel(context),
        const SizedBox(height: 10),
        _buildSeoPanel(context),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Section Header ──────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 3, height: 18, color: AppTheme.neonCyan),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.neonCyan,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Panel Builder ───────────────────────────────────────────────────────────

  Widget _panel({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required List<Widget> rows,
    VoidCallback? onTap,
    String? navLabel,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel header
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, color: accentColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null) ...[
                    Text(
                      navLabel ?? 'VIEW',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: accentColor, size: 16),
                  ],
                ],
              ),
            ),
          ),
          Divider(height: 1, color: accentColor.withValues(alpha: 0.15)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rows,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Panel 1: Pricing Engine ─────────────────────────────────────────────────

  Widget _buildPricingPanel(BuildContext context) {
    final svc = GlobalPricingService();
    final entries = svc.allEntries
        .where((e) => ['AU', 'US', 'GB', 'IN', 'NG'].contains(e.code))
        .toList();

    return _panel(
      title: 'Global Pricing Engine',
      subtitle: '${svc.allEntries.length} regions configured',
      icon: Icons.attach_money,
      accentColor: AppTheme.neonGreen,
      onTap: () => context.push(rc.RouterConfig.globalPricingPath),
      navLabel: 'MANAGE',
      rows: [
        ...entries.map(
          (e) => _row(
            '${e.flag}  ${e.name}',
            '${e.symbol}${e.displayPrice} ${e.currency}',
            AppTheme.neonGreen,
          ),
        ),
        _row(
          '+ ${svc.allEntries.length - entries.length} more regions',
          '',
          Colors.white24,
        ),
      ],
    );
  }

  // ── Panel 2: Distribution Engine ───────────────────────────────────────────

  Widget _buildDistributionPanel(BuildContext context) {
    final configs = GlobalDistributionService().getDemoChannelConfigs();
    final enabled = configs.where((c) => c.enabled).toList();
    final disabled = configs.where((c) => !c.enabled).toList();

    return _panel(
      title: 'Global Distribution Engine',
      subtitle: '${enabled.length} channels active, ${disabled.length} paused',
      icon: Icons.broadcast_on_personal,
      accentColor: AppTheme.neonCyan,
      onTap: () => context.push(rc.RouterConfig.globalDistributionPath),
      navLabel: 'CHANNELS',
      rows: [
        ...configs.map(
          (c) => _row(
            _platformLabel(c.platform),
            c.enabled ? 'ACTIVE' : 'PAUSED',
            c.enabled ? AppTheme.neonGreen : Colors.white24,
          ),
        ),
      ],
    );
  }

  String _platformLabel(String platform) {
    const icons = {
      'facebook': '📘 Facebook',
      'instagram': '📸 Instagram',
      'youtube': '▶️ YouTube',
      'tiktok': '🎵 TikTok',
      'whatsapp': '💬 WhatsApp',
    };
    return icons[platform] ?? platform;
  }

  // ── Panel 3: Global Ranking Engine ─────────────────────────────────────────

  Widget _buildRankingPanel(BuildContext context) {
    final top3 = GlobalRankingService().getDemoLeaderboard().take(3).toList();

    return _panel(
      title: 'Global Ranking Engine',
      subtitle: 'Hype + momentum scores, live leaderboard',
      icon: Icons.emoji_events,
      accentColor: AppTheme.neonMagenta,
      onTap: () => context.push(rc.RouterConfig.globalRankingPath),
      navLabel: 'LEADERBOARD',
      rows: top3.asMap().entries.map((e) {
        final rank = e.key + 1;
        final entry = e.value;
        return _row(
          '#$rank  ${entry.name}',
          '${entry.globalScore.toStringAsFixed(0)} pts',
          AppTheme.neonMagenta,
        );
      }).toList(),
    );
  }

  // ── Panel 4: AI Caption Engine ──────────────────────────────────────────────

  Widget _buildCaptionPanel(BuildContext context) {
    final svc = AutoCaptionService();

    return _panel(
      title: 'AI Caption Engine',
      subtitle: svc.useAi
          ? 'Gemini Flash AI active'
          : 'Template mode — wire GEMINI_API_KEY for AI',
      icon: Icons.auto_awesome,
      accentColor: AppTheme.neonOrange,
      onTap: () => context.push(rc.RouterConfig.autoCaptionPath),
      navLabel: 'GENERATE',
      rows: [
        _row(
          'Mode',
          svc.useAi ? 'AI (Gemini Flash)' : 'Template (offline)',
          AppTheme.neonOrange,
        ),
        _row('Hype captions', 'Ready', AppTheme.neonGreen),
        _row('SEO descriptions', 'Ready', AppTheme.neonGreen),
        _row('Gemini integration', 'Stub — wire API key', Colors.white38),
      ],
    );
  }

  // ── Panel 5: Global SEO Engine ──────────────────────────────────────────────

  Widget _buildSeoPanel(BuildContext context) {
    final svc = GlobalSeoService();
    final sample = svc.forFighter(
      name: 'DFC Platform',
      weightClass: 'Global',
      sport: 'Combat Sports',
      wins: 0,
      losses: 0,
    );

    return _panel(
      title: 'Global SEO Engine',
      subtitle: 'Auto-metadata for fighters, gyms, and events',
      icon: Icons.travel_explore,
      accentColor: const Color(0xFF7C4DFF),
      onTap: () => context.push(rc.RouterConfig.globalSeoScreenPath),
      navLabel: 'SEO PANEL',
      rows: [
        _row('Fighters', 'Meta + OG tags ready', AppTheme.neonGreen),
        _row('Gyms', 'Meta + OG tags ready', AppTheme.neonGreen),
        _row('Events', 'Meta + OG tags ready', AppTheme.neonGreen),
        _row(
          'Keywords in sample',
          '${sample.keywords.length}',
          const Color(0xFF7C4DFF),
        ),
      ],
    );
  }
}
