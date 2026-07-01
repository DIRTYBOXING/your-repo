import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/moderation_engine.dart';
import '../../../shared/models/moderation_model.dart';

/// Command Dashboard Home — The unified admin overview panel.
/// Live event banner, moderation queue, region metrics, quick actions,
/// alerts, and editorial content in a responsive grid.
class CommandDashboardHome extends StatefulWidget {
  const CommandDashboardHome({super.key});

  @override
  State<CommandDashboardHome> createState() => _CommandDashboardHomeState();
}

class _CommandDashboardHomeState extends State<CommandDashboardHome> {
  final ModerationEngine _modEngine = ModerationEngine();

  // Demo data
  int _pendingModCount = 0;

  @override
  void initState() {
    super.initState();
    _loadQueueStats();
  }

  Future<void> _loadQueueStats() async {
    try {
      final stats = await _modEngine.getQueueStats();
      if (mounted) setState(() => _pendingModCount = stats['pending'] ?? 0);
    } catch (_) {
      if (mounted) setState(() => _pendingModCount = 5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Live event banner
          _buildEventBanner(),
          const SizedBox(height: 20),
          // Stats row
          _buildStatsRow(isWide),
          const SizedBox(height: 20),
          // Two-column (wide) or stacked (narrow)
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildLeftColumn()),
                const SizedBox(width: 16),
                Expanded(child: _buildRightColumn()),
              ],
            )
          else ...[
            _buildLeftColumn(),
            const SizedBox(height: 16),
            _buildRightColumn(),
          ],
        ],
      ),
    );
  }

  // ── Live Event Banner ──

  Widget _buildEventBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.12),
            DesignTokens.neonMagenta.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignTokens.neonCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.live_tv,
              color: DesignTokens.neonCyan,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.neonRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'UPCOMING',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Apr 18, 2026 · Townsville',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'BKFC Fight Night Australia',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hepi vs Wisniewski · 8 bouts · PPV + Gate',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            children: [
              _bannerAction('PROMOTE', Icons.campaign, () {}),
              const SizedBox(height: 8),
              _bannerAction('MANAGE', Icons.settings, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerAction(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: DesignTokens.neonCyan.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: DesignTokens.neonCyan.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: DesignTokens.neonCyan, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: DesignTokens.neonCyan,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats Row ──

  Widget _buildStatsRow(bool isWide) {
    final stats = [
      _StatData(
        'MOD QUEUE',
        '$_pendingModCount',
        DesignTokens.neonRed,
        Icons.shield_outlined,
      ),
      const _StatData(
        'NEW POSTS',
        '47',
        DesignTokens.neonCyan,
        Icons.article_outlined,
      ),
      const _StatData(
        'USERS TODAY',
        '23',
        DesignTokens.neonGreen,
        Icons.people_outlined,
      ),
      const _StatData(
        'FAN QUESTIONS',
        '12',
        DesignTokens.neonAmber,
        Icons.help_outline,
      ),
      const _StatData(
        'REGIONS',
        '4',
        DesignTokens.neonGold,
        Icons.location_city_outlined,
      ),
      const _StatData('EVENTS', '2', DesignTokens.neonMagenta, Icons.event_outlined),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: stats.map((s) {
        return SizedBox(
          width: isWide ? 155 : (MediaQuery.of(context).size.width - 56) / 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: s.color.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(s.icon, color: s.color, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      s.label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  s.value,
                  style: TextStyle(
                    color: s.color,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Left Column (main content) ──

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header('QUICK ACTIONS'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _quickAction(
              'Mod Queue',
              Icons.shield,
              DesignTokens.neonRed,
              () => context.push('/admin/moderation'),
            ),
            _quickAction(
              'Fighter Inbox',
              Icons.question_answer,
              DesignTokens.neonAmber,
              () => context.push('/correspondence/fighter-inbox'),
            ),
            _quickAction(
              'Create Event',
              Icons.add_circle_outline,
              DesignTokens.neonGreen,
              () {},
            ),
            _quickAction(
              'Region Manager',
              Icons.map_outlined,
              DesignTokens.neonGold,
              () => context.push('/admin/region-manager'),
            ),
            _quickAction(
              'Event Manager',
              Icons.event_note,
              DesignTokens.neonMagenta,
              () => context.push('/admin/event-manager'),
            ),
            _quickAction(
              'User Settings',
              Icons.settings,
              DesignTokens.neonCyan,
              () => context.push('/user-settings'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _header('MODERATION QUEUE'),
        const SizedBox(height: 12),
        _buildModerationPreview(),
        const SizedBox(height: 24),
        _header('REGION ACTIVITY'),
        const SizedBox(height: 12),
        _buildRegionActivity(),
      ],
    );
  }

  // ── Right Column (alerts, pinned, shortcuts) ──

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header('ALERTS'),
        const SizedBox(height: 12),
        _alertCard(
          'BKFC Townsville — 24 days away. Promo assets needed.',
          DesignTokens.neonAmber,
          Icons.warning_amber,
        ),
        _alertCard(
          '$_pendingModCount items in moderation queue.',
          DesignTokens.neonRed,
          Icons.shield,
        ),
        _alertCard(
          'Logan region: 120 new followers this week.',
          DesignTokens.neonGreen,
          Icons.trending_up,
        ),
        const SizedBox(height: 24),
        _header('FIGHTER Q&A ACTIVITY'),
        const SizedBox(height: 12),
        _buildQAActivity(),
        const SizedBox(height: 24),
        _header('PINNED CONTENT'),
        const SizedBox(height: 12),
        _pinnedItem('Hepi vs Wisniewski promo clip', 'Video · 2h ago'),
        _pinnedItem('BKFC April 18 poster', 'Image · 1d ago'),
        _pinnedItem('Logan region spotlight', 'Article · 3d ago'),
      ],
    );
  }

  Widget _buildModerationPreview() {
    return StreamBuilder<List<ModerationModel>>(
      stream: _modEngine.streamQueue(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final preview = items.take(3).toList();
        if (preview.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: DesignTokens.neonGreen,
                  size: 18,
                ),
                SizedBox(width: 10),
                Text(
                  'Queue is clear',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            ...preview.map(_modQueueItem),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => context.push('/admin/moderation'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View full queue ($_pendingModCount items)',
                      style: const TextStyle(
                        color: DesignTokens.neonCyan,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward,
                      color: DesignTokens.neonCyan,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _modQueueItem(ModerationModel item) {
    final statusColor = switch (item.status) {
      ModerationStatus.pending => DesignTokens.neonAmber,
      ModerationStatus.rejected => DesignTokens.neonRed,
      _ => Colors.white38,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 32,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.content.length > 60
                      ? '${item.content.substring(0, 60)}...'
                      : item.content,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.type.name} · ${item.status.name.toUpperCase()}',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionActivity() {
    final regions = [
      ('Logan', '12.4K', '+8%', DesignTokens.neonCyan),
      ('Brisbane', '8.2K', '+3%', DesignTokens.neonGreen),
      ('Bronx Islanders', '6.8K', '+12%', DesignTokens.neonAmber),
      ('Townsville', '3.4K', '+22%', DesignTokens.neonMagenta),
    ];
    return Column(
      children: regions
          .map(
            (r) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DesignTokens.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: r.$4.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.location_city, color: r.$4, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.$1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${r.$2} followers',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    r.$3,
                    style: const TextStyle(
                      color: DesignTokens.neonGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildQAActivity() {
    final items = [
      ('Haze Hepi', '3 new questions', DesignTokens.neonCyan),
      ('Mark Flanagan', '1 pending reply', DesignTokens.neonAmber),
      ('Sam Soliman', '2 answered today', DesignTokens.neonGreen),
    ];
    return Column(
      children: items
          .map(
            (i) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DesignTokens.bgCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: i.$3.withValues(alpha: 0.15),
                    child: Text(
                      i.$1[0],
                      style: TextStyle(
                        color: i.$3,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i.$1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          i.$2,
                          style: TextStyle(
                            color: i.$3,
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
          )
          .toList(),
    );
  }

  // ── Shared Pieces ──

  Widget _header(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: DesignTokens.neonCyan,
        fontWeight: FontWeight.w900,
        fontSize: 12,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _quickAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertCard(String text, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pinnedItem(String title, String meta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.push_pin,
            color: DesignTokens.neonGold.withValues(alpha: 0.6),
            size: 14,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  meta,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatData(this.label, this.value, this.color, this.icon);
}
