import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/operator_actions.dart';
import '../../../shared/widgets/mission_control_widgets.dart';

class MissionControlFeedScreen extends StatefulWidget {
  const MissionControlFeedScreen({super.key});

  @override
  State<MissionControlFeedScreen> createState() =>
      _MissionControlFeedScreenState();
}

class _MissionControlFeedScreenState extends State<MissionControlFeedScreen> {
  final String heroImageUrl =
      'https://images.unsplash.com/photo-1544390623-df9c1db162e4?w=1600';
  bool _sponsorOverlayEnabled = true;
  String? _activeOperatorAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('MISSION CONTROL'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.monitor_heart_outlined,
              color: AppTheme.accentCyan,
            ),
            onPressed: _showOperatorPanel,
            tooltip: 'Operator Panel',
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: CinematicHero(
              imageUrl: heroImageUrl,
              eyebrow: 'Operator cockpit',
              title:
                  'Championship night under control, pressure, and velocity.',
              subtitle:
                  'A cinematic live hub that lets DFC run the show, tune conversion, and see stream health without losing the pulse of the crowd.',
              isLive: true,
              badges: [
                const SignalPill(
                  label: 'Latency',
                  value: '1.8s',
                  color: AppTheme.success,
                ),
                const SignalPill(
                  label: 'Sentiment',
                  value: '+24%',
                  color: AppTheme.neonMagenta,
                ),
                SignalPill(
                  label: 'Overlay',
                  value: _sponsorOverlayEnabled ? 'On' : 'Off',
                  color: _sponsorOverlayEnabled
                      ? AppTheme.accentCyan
                      : AppTheme.warning,
                ),
              ],
              metrics: const [
                MetricChip(
                  icon: Icons.people_alt_outlined,
                  label: '12.4K live viewers',
                ),
                MetricChip(
                  icon: Icons.bolt_rounded,
                  label: '98.7% success rate',
                ),
                MetricChip(
                  icon: Icons.workspace_premium_outlined,
                  label: '3 sponsor slots armed',
                ),
              ],
              actionButton: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _showOperatorPanel,
                icon: const Icon(Icons.tune, color: Colors.white),
                label: const Text(
                  'OPEN OPERATOR DECK',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              secondaryAction: OutlinedButton.icon(
                onPressed: () => setState(() {
                  _sponsorOverlayEnabled = !_sponsorOverlayEnabled;
                }),
                icon: Icon(
                  _sponsorOverlayEnabled
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                label: Text(
                  _sponsorOverlayEnabled
                      ? 'Hide sponsor layer'
                      : 'Show sponsor layer',
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: 'Signal Layers',
                    subtitle:
                        'Immediate broadcast health, conversion pressure, and audience energy.',
                    action: TextButton(
                      onPressed: _showOperatorPanel,
                      child: const Text('Open panel'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 170,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        _SignalLayerCard(
                          title: 'Stream health',
                          value: 'Excellent',
                          description:
                              'No dropped callbacks, buffer stable, canary green.',
                          accent: AppTheme.success,
                          icon: Icons.monitor_heart,
                        ),
                        SizedBox(width: 14),
                        _SignalLayerCard(
                          title: 'Crowd temperature',
                          value: 'Heating up',
                          description:
                              'Emoji heatmap and chat velocity point to main-card lift.',
                          accent: AppTheme.neonMagenta,
                          icon: Icons.favorite,
                        ),
                        SizedBox(width: 14),
                        _SignalLayerCard(
                          title: 'Revenue pace',
                          value: '+18%',
                          description:
                              'Premium bundle outperforming baseline since trailer loop started.',
                          accent: AppTheme.warning,
                          icon: Icons.trending_up,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                    title: 'Pinned Missions',
                    subtitle:
                        'Operational actions with the highest leverage right now.',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 232,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _missions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 14),
                      itemBuilder: (context, index) =>
                          _MissionCard(mission: _missions[index]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
              child: PremiumGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: _SectionHeader(
                            title: 'Command Grid',
                            subtitle:
                                'The operator slice that explains why the room feels under control.',
                          ),
                        ),
                        Switch.adaptive(
                          value: _sponsorOverlayEnabled,
                          onChanged: (value) =>
                              setState(() => _sponsorOverlayEnabled = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _HeatMetric(label: 'Bitrate', value: '1080p / 60fps'),
                        _HeatMetric(label: 'Retries', value: '0 active'),
                        _HeatMetric(label: 'Dead letters', value: '< 0.1%'),
                        _HeatMetric(label: 'Watchdog', value: 'Armed'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return _buildFeedCard(index);
            }, childCount: _feedItems.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildFeedCard(int index) {
    final item = _feedItems[index];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: PremiumGlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, color: item.accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        item.timestamp,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.body,
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: item.tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOperatorPanel() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'OPERATOR PANEL',
                          style: TextStyle(
                            color: AppTheme.accentCyan,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _activeOperatorAction == null
                            ? const SizedBox.shrink()
                            : Container(
                                key: ValueKey(_activeOperatorAction),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.warning.withValues(
                                    alpha: 0.18,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Running $_activeOperatorAction',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  PremiumGlassCard(
                    child: Column(
                      children: [
                        _buildOperatorStatRow(
                          'Stream Health',
                          'Excellent',
                          AppTheme.success,
                        ),
                        _buildOperatorStatRow(
                          'Active Viewers',
                          '12,431',
                          Colors.white,
                        ),
                        _buildOperatorStatRow(
                          'Bitrate',
                          '1080p / 60fps',
                          Colors.white,
                        ),
                        _buildOperatorStatRow(
                          'Callback backlog',
                          '0 waiting',
                          AppTheme.success,
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 40),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickActionBtn(
                        Icons.campaign,
                        'Send Promo',
                        Colors.purpleAccent,
                        () => _runOperatorAction('send_promo'),
                      ),
                      _buildQuickActionBtn(
                        Icons.cut,
                        'Create Clip',
                        Colors.orange,
                        () => _runOperatorAction('create_clip'),
                      ),
                      _buildQuickActionBtn(
                        Icons.refresh,
                        'Retry Sync',
                        Colors.blue,
                        () => _runOperatorAction('retry_sync'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Activity Timeline',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: _timeline.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final entry = _timeline[index];
                        return PremiumGlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          radius: 18,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: entry.color,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      entry.status,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                entry.timeAgo,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOperatorStatRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runOperatorAction(String action) async {
    setState(() {
      _activeOperatorAction = action;
    });

    try {
      final functionUrl = AppConstants.operatorFunctionUrl;
      final operatorId = AppConstants.operatorId;
      final operatorSecret = AppConstants.operatorSecret;

      if (functionUrl.isNotEmpty &&
          operatorId.isNotEmpty &&
          operatorSecret.isNotEmpty) {
        await OperatorActions.callOperatorAction(
          functionUrl: functionUrl,
          operatorId: operatorId,
          action: action,
          params: <String, dynamic>{
            'source': 'mission_control',
            'idempotencyKey':
                '${action}_${DateTime.now().millisecondsSinceEpoch}',
          },
          apiKey: operatorSecret,
        );
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 900));
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Action queued: $action')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Action failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _activeOperatorAction = null;
        });
      }
    }
  }

  Widget _buildQuickActionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.2),
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final trailingActions = [action].whereType<Widget>().toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, height: 1.45),
              ),
            ],
          ),
        ),
        ...trailingActions,
      ],
    );
  }
}

class _SignalLayerCard extends StatelessWidget {
  final String title;
  final String value;
  final String description;
  final Color accent;
  final IconData icon;

  const _SignalLayerCard({
    required this.title,
    required this.value,
    required this.description,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: PremiumGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: Colors.white70, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final _MissionCardData mission;

  const _MissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: PremiumGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    mission.priority,
                    style: TextStyle(
                      color: mission.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Icon(mission.icon, color: mission.accent),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              mission.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              mission.description,
              style: const TextStyle(color: Colors.white70, height: 1.45),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: mission.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      mission.cta,
                      style: TextStyle(
                        color: mission.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: mission.accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeatMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionCardData {
  final String priority;
  final String title;
  final String description;
  final String cta;
  final Color accent;
  final IconData icon;

  const _MissionCardData({
    required this.priority,
    required this.title,
    required this.description,
    required this.cta,
    required this.accent,
    required this.icon,
  });
}

class _FeedItem {
  final String title;
  final String body;
  final String timestamp;
  final List<String> tags;
  final IconData icon;
  final Color accent;

  const _FeedItem({
    required this.title,
    required this.body,
    required this.timestamp,
    required this.tags,
    required this.icon,
    required this.accent,
  });
}

class _OperatorTimelineEntry {
  final String title;
  final String status;
  final String timeAgo;
  final Color color;

  const _OperatorTimelineEntry(
    this.title,
    this.status,
    this.timeAgo,
    this.color,
  );
}

const List<_MissionCardData> _missions = [
  _MissionCardData(
    priority: 'Priority 1',
    title: 'Push premium bundle before co-main walkouts',
    description:
        'Conversion window is strongest when hype peaks and the stream is already proving stable.',
    cta: 'Open PPV upsell',
    accent: AppTheme.warning,
    icon: Icons.local_fire_department,
  ),
  _MissionCardData(
    priority: 'Operator',
    title: 'Sponsor overlay tuned for mobile-safe lower thirds',
    description:
        'Keep the cinematic framing while preserving the fighter walkout visuals and social clipping space.',
    cta: 'Adjust overlay mix',
    accent: AppTheme.accentCyan,
    icon: Icons.layers,
  ),
  _MissionCardData(
    priority: 'Automation',
    title: 'Clip factory primed for immediate post-knockdown highlights',
    description:
        'Watchdog is armed and worker headroom is available for short-form export.',
    cta: 'Open clip lane',
    accent: AppTheme.neonMagenta,
    icon: Icons.content_cut,
  ),
];

const List<_FeedItem> _feedItems = [
  _FeedItem(
    title: 'Walkout trailer boosted replay intent',
    body:
        'Completion rate held above benchmark and replay add-on interest climbed after the second cinematic cutdown.',
    timestamp: 'Now',
    tags: ['Replay', 'Engagement', 'Trailer'],
    icon: Icons.ondemand_video,
    accent: AppTheme.accentCyan,
  ),
  _FeedItem(
    title: 'Geo-targeted promo lane cleared the approval gate',
    body:
        'The promoter-safe copy passed moderation, and the region-specific bundle can ship on the next crowd spike.',
    timestamp: '3m',
    tags: ['Promo', 'Approval', 'Regional'],
    icon: Icons.campaign,
    accent: AppTheme.warning,
  ),
  _FeedItem(
    title: 'Operator retry budget untouched during main-card ingest',
    body:
        'No stuck jobs older than threshold. The current run is clean enough to support a canary content push.',
    timestamp: '8m',
    tags: ['SLO', 'Watchdog', 'Canary'],
    icon: Icons.verified,
    accent: AppTheme.success,
  ),
  _FeedItem(
    title: 'Audience heat map points to knockout-highlight demand',
    body:
        'The emoji surge is concentrated around two exchanges, making them the highest-value moments for auto-clipping.',
    timestamp: '12m',
    tags: ['Heatmap', 'Highlights', 'Clips'],
    icon: Icons.whatshot,
    accent: AppTheme.neonMagenta,
  ),
  _FeedItem(
    title: 'Creator lane ready for branded short-form distribution',
    body:
        'Sponsor-safe slates and attribution metadata are attached, so highlights can push without manual cleanup.',
    timestamp: '16m',
    tags: ['Creator', 'Sponsor', 'Metadata'],
    icon: Icons.auto_awesome,
    accent: AppTheme.accentPurple,
  ),
];

const List<_OperatorTimelineEntry> _timeline = [
  _OperatorTimelineEntry('Mux ingest', 'Healthy', '22s ago', AppTheme.success),
  _OperatorTimelineEntry('Promo wave', 'Queued', '2m ago', AppTheme.warning),
  _OperatorTimelineEntry(
    'Clip export',
    'Rendering',
    '4m ago',
    AppTheme.accentCyan,
  ),
];
