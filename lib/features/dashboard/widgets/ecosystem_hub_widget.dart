import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:datafightcentral/core/theme/app_theme.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import 'package:datafightcentral/shared/services/ecosystem_state_service.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PROMOTER WAR ROOM — Live Operations Command Center
/// ═══════════════════════════════════════════════════════════════════════════
/// Watch the DFC machine work in real-time. Events flow through pipeline:
/// 🔍 SCOUTING → 🏗️ BUILDING → 🏆 WINNING → 💵 CLOSING
/// Bots working. Content generating. Deals closing. Revenue flowing.
class EcosystemHubWidget extends StatefulWidget {
  final bool
  showFullView; // true = expanded dashboard, false = compact card view

  const EcosystemHubWidget({super.key, this.showFullView = false});

  @override
  State<EcosystemHubWidget> createState() => _EcosystemHubWidgetState();
}

class _EcosystemHubWidgetState extends State<EcosystemHubWidget>
    with TickerProviderStateMixin {
  late AnimationController _flowAnimationController;
  late Animation<double> _flowAnimation;
  late AnimationController _pulseController;

  // ═══ DYNAMIC ACTIVITY STREAM ═══
  Timer? _activityTimer;
  final List<Map<String, dynamic>> _liveActivities = [];
  int _activityCounter = 0;
  final _random = Random();

  // Activity templates that rotate to show the machine working
  static const List<Map<String, dynamic>> _activityTemplates = [
    {
      'bot': '🔍 SCOUT BOT',
      'actions': [
        'Scanning Brisbane events',
        'Found IBC event in Melbourne',
        'Detected new promotion: BKFC Australia',
        'Indexing UFC 320 card',
        'Monitoring PFL Sydney',
      ],
      'color': Color(0xFF00D9FF),
    },
    {
      'bot': '🎬 CONTENT BOT',
      'actions': [
        'Generated thumbnail for UFC 315',
        'Creating highlight reel',
        'Processing fight clip',
        'Uploading to YouTube',
        'Optimizing SEO tags',
      ],
      'color': Color(0xFF00FF88),
    },
    {
      'bot': '📊 STRATEGY BOT',
      'actions': [
        'Scored opportunity: 2.9/3.0',
        'Analyzing market potential',
        'Calculating ROI projection',
        'Strategic score updated',
        'Flagged high-value deal',
      ],
      'color': Color(0xFFFFD600),
    },
    {
      'bot': '💬 OUTREACH BOT',
      'actions': [
        'Sent partnership brief',
        'Following up with promoter',
        'Email sequence triggered',
        'LinkedIn connection sent',
        'Contract template prepared',
      ],
      'color': Color(0xFFFF0080),
    },
    {
      'bot': '🤖 SAMURAI SHIDO',
      'actions': [
        'Analyzing fighter matchups',
        'Predicting bout outcome',
        'Training recommendation sent',
        'Performance insight generated',
        'Fight camp analysis complete',
      ],
      'color': Color(0xFF9C27B0),
    },
    {
      'bot': '💰 REVENUE BOT',
      'actions': [
        'PPV projection calculated',
        'Sponsorship value estimated',
        'Ticket sales tracked',
        'Merch revenue updated',
        'Ad placement optimized',
      ],
      'color': Color(0xFFFF6D00),
    },
    {
      'bot': '📡 FEED ENGINE',
      'actions': [
        'Ingesting fight news',
        'Normalizing source data',
        'Ranking content priority',
        'Publishing to feed',
        'Trust score verified',
      ],
      'color': Color(0xFF00BCD4),
    },
  ];

  @override
  void initState() {
    super.initState();
    // Continuous smooth animation for opportunity flow
    _flowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _flowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_flowAnimationController);
    _flowAnimationController.repeat();

    // Pulse animation for LIVE indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // ═══ START DYNAMIC ACTIVITY STREAM ═══
    _seedInitialActivities();
    _startActivityStream();
  }

  void _seedInitialActivities() {
    // Seed with 5 initial activities so it doesn't start empty
    for (int i = 0; i < 5; i++) {
      _addRandomActivity(age: (5 - i) * 15);
    }
  }

  void _startActivityStream() {
    // Add new activity every 3-6 seconds to show the machine working
    _activityTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() {
          _addRandomActivity();
          // Keep only last 8 activities
          if (_liveActivities.length > 8) {
            _liveActivities.removeAt(0);
          }
        });
      }
    });
  }

  void _addRandomActivity({int age = 0}) {
    final template =
        _activityTemplates[_random.nextInt(_activityTemplates.length)];
    final actions = template['actions'] as List<String>;
    final action = actions[_random.nextInt(actions.length)];

    _liveActivities.add({
      'id': _activityCounter++,
      'bot': template['bot'],
      'action': action,
      'time': age == 0 ? 'Just now' : '${age}s ago',
      'color': template['color'],
      'timestamp': DateTime.now().subtract(Duration(seconds: age)),
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Seed demo data immediately so the dashboard is never blank,
    // then start the auto-refresh pipeline from real feed sources.
    try {
      final eco = context.read<EcosystemStateService>();
      eco.seedIfEmpty();
      eco.startPipelineRefresh();
    } catch (_) {}
  }

  @override
  void dispose() {
    _activityTimer?.cancel();
    _flowAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Consumer<EcosystemStateService>(
        builder: (context, ecosystemState, _) {
          return widget.showFullView
              ? _buildFullDashboard(context, ecosystemState)
              : _buildCompactCard(context, ecosystemState);
        },
      );
    } catch (e) {
      debugPrint('EcosystemHubWidget: Provider read failed: $e');
      return const SizedBox.shrink();
    }
  }

  // ── FULL DASHBOARD VIEW ────────────────────────────────────────────────
  Widget _buildFullDashboard(
    BuildContext context,
    EcosystemStateService state,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — WAR ROOM BRANDING
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.red,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WAR ROOM',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.red.withValues(alpha: 0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'LIVE OPERATIONS • ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neonCyan,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _buildLiveIndicator(),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Watch the machine work. Events discovered. Content created. Deals closing.',
              style: TextStyle(fontSize: 13, color: Colors.white60),
            ),
            const SizedBox(height: 16),

            // Real-time metrics row
            _buildMetricsRow(state),
            const SizedBox(height: 16),

            // Animation canvas: 4-stage pipeline
            _buildAnimatedPipeline(context, state),
            const SizedBox(height: 16),

            // Live Activity Feed — what the bots are doing NOW
            _buildLiveActivityFeed(state),
          ],
        ),
      ),
    );
  }

  // ── COMPACT CARD VIEW ──────────────────────────────────────────────────
  Widget _buildCompactCard(BuildContext context, EcosystemStateService state) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0A0E1A).withValues(alpha: 0.95),
            const Color(0xFF1A1E3A).withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.red,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'WAR ROOM',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${state.totalOpportunitiesInPipeline} LIVE',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Four stage indicators
          _buildCompactStageRow(state),
          const SizedBox(height: 12),

          // Key metrics
          _buildCompactMetrics(state),
        ],
      ),
    );
  }

  // ── REAL-TIME WAR ROOM METRICS ──────────────────────────────────────────
  Widget _buildMetricsRow(EcosystemStateService state) {
    final metrics = state.realTimeMetrics;
    final dealsCount = metrics['deals_closed'] ?? 0;
    final viewsRaw = metrics['youtube_views_generated'] ?? 0;
    final viewsDisplay = viewsRaw >= 1000
        ? '${(viewsRaw / 1000).toStringAsFixed(1)}K'
        : viewsRaw.toString();

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _buildMetricCard(
          label: 'PIPELINE',
          value: state.totalOpportunitiesInPipeline.toString(),
          color: AppTheme.neonCyan,
          icon: Icons.track_changes,
          subtitle: 'events being processed',
        ),
        _buildMetricCard(
          label: 'DEALS',
          value: dealsCount.toString(),
          color: AppTheme.neonGreen,
          icon: Icons.handshake,
          subtitle: 'partnerships closed',
        ),
        _buildMetricCard(
          label: 'REACH',
          value: viewsDisplay,
          color: AppTheme.neonOrange,
          icon: Icons.play_circle_fill,
          subtitle: 'views generated',
        ),
        _buildMetricCard(
          label: 'POWER',
          value:
              '${(metrics['avg_strategic_score'] as num).toStringAsFixed(1)}/3',
          color: AppTheme.neonMagenta,
          icon: Icons.bolt,
          subtitle: 'system efficiency',
        ),
      ],
    );
  }

  /// Live pulsing indicator showing the system is active
  Widget _buildLiveIndicator() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.withValues(
              alpha: 0.1 + (_pulseController.value * 0.15),
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.red.withValues(
                alpha: 0.5 + (_pulseController.value * 0.3),
              ),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(
                        alpha: 0.5 + (_pulseController.value * 0.5),
                      ),
                      blurRadius: 4 + (_pulseController.value * 4),
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.red,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── LIVE ACTIVITY FEED ─────────────────────────────────────────────────
  /// Shows what bots are doing RIGHT NOW - the heart of the war room
  /// This is DYNAMIC - activities stream in every few seconds to show the machine working
  Widget _buildLiveActivityFeed(EcosystemStateService state) {
    // Update timestamps for activities
    final now = DateTime.now();
    for (var activity in _liveActivities) {
      final ts = activity['timestamp'] as DateTime;
      final diff = now.difference(ts).inSeconds;
      activity['time'] = diff < 5
          ? 'Just now'
          : diff < 60
          ? '${diff}s ago'
          : '${(diff / 60).floor()}m ago';
    }

    // Reversed so newest is at top
    final displayActivities = _liveActivities.reversed.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0A0E1A).withValues(alpha: 0.95),
            const Color(0xFF1A1E3A).withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with pulsing live indicator
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) => Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(
                          alpha: 0.6 + (_pulseController.value * 0.4),
                        ),
                        blurRadius: 6 + (_pulseController.value * 6),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'LIVE ACTIVITY',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neonCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.neonCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${state.totalOpportunitiesInPipeline} OPS RUNNING',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.neonCyan,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Machine status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.neonGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.neonGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.settings_suggest,
                  color: AppTheme.neonGreen,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'DFC MACHINE ACTIVE • ${_activityTemplates.length} BOTS WORKING',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.neonGreen,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dynamic activity list with animations
          ...displayActivities.take(6).map((activity) {
            final isNew = activity['time'] == 'Just now';
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isNew
                    ? (activity['color'] as Color).withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isNew
                      ? (activity['color'] as Color).withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  // Status indicator bar
                  Container(
                    width: 4,
                    height: 36,
                    decoration: BoxDecoration(
                      color: activity['color'] as Color,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: isNew
                          ? [
                              BoxShadow(
                                color: (activity['color'] as Color).withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['bot'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: activity['color'] as Color,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activity['action'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isNew
                          ? AppTheme.neonGreen.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      activity['time'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isNew ? AppTheme.neonGreen : Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    String? subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── ANIMATED PIPELINE ──────────────────────────────────────────────────
  Widget _buildAnimatedPipeline(
    BuildContext context,
    EcosystemStateService state,
  ) {
    const stages = ['discover', 'build', 'win', 'sell'];
    const stageLabels = [
      '🔍 SCOUTING',
      '🏗️ BUILDING',
      '🏆 WINNING',
      '💵 CLOSING',
    ];
    const stageColors = [
      Color(0xFF00D9FF), // cyan
      Color(0xFF00FF88), // green
      Color(0xFFFFD600), // yellow
      Color(0xFFFF0080), // magenta
    ];

    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0A0E1A).withValues(alpha: 0.9),
            const Color(0xFF1A1E3A).withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppTheme.neonCyan.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Stage labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                stages.length,
                (i) => Expanded(
                  child: Center(
                    child: Text(
                      stageLabels[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: stageColors[i],
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: stageColors[i].withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Connecting flow lines with animation
            Expanded(
              child: Stack(
                children: [
                  // Animated flow lines
                  CustomPaint(
                    painter: AnimatedFlowLinePainter(
                      animation: _flowAnimation,
                      stageCount: stages.length,
                    ),
                    size: Size.infinite,
                  ),

                  // Stage columns with opportunity cards
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(
                      stages.length,
                      (i) => Expanded(
                        child: _buildStageColumn(
                          stage: stages[i],
                          stageIndex: i,
                          stageColor: stageColors[i],
                          state: state,
                        ),
                      ),
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

  Widget _buildStageColumn({
    required String stage,
    required int stageIndex,
    required Color stageColor,
    required EcosystemStateService state,
  }) {
    final opportunities = state.stageOpportunities[stage] ?? [];

    return Column(
      children: [
        // Count badge
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                stageColor.withValues(alpha: 0.6),
                stageColor.withValues(alpha: 0.3),
              ],
            ),
            border: Border.all(color: stageColor, width: 2),
          ),
          child: Center(
            child: Text(
              opportunities.length.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: stageColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Opportunity cards (scrollable if many)
        Expanded(
          child: opportunities.isEmpty
              ? Center(
                  child: Text(
                    '∅',
                    style: TextStyle(
                      fontSize: 24,
                      color: stageColor.withValues(alpha: 0.3),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: opportunities.map((opp) {
                      // Highlight samurai/joseph/legends signals
                      final isPriority = opp.commandSignals.any(
                        (s) =>
                            s == 'samurai-promotion' ||
                            s == 'joseph-priority' ||
                            s == 'legends-show',
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: [
                              stageColor.withValues(
                                alpha: isPriority ? 0.4 : 0.15,
                              ),
                              stageColor.withValues(
                                alpha: isPriority ? 0.2 : 0.05,
                              ),
                            ],
                          ),
                          border: Border.all(
                            color: stageColor,
                            width: isPriority ? 2 : 1,
                          ),
                          boxShadow: isPriority
                              ? [
                                  BoxShadow(
                                    color: stageColor.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image (if available) with drag-drop zone
                            _buildImageDropZone(
                              opp: opp,
                              stageColor: stageColor,
                              onImageDropped: (bytes, filename) async {
                                await _handleImageUpload(
                                  context,
                                  opp.id,
                                  bytes,
                                  filename,
                                );
                              },
                            ),

                            // Title
                            Text(
                              opp.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),

                            // Time in stage
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _formatDuration(opp.timeInStage),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white54,
                                ),
                              ),
                            ),

                            // Signal badges
                            if (isPriority)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  spacing: 4,
                                  children: opp.commandSignals
                                      .where(
                                        (s) =>
                                            s == 'samurai-promotion' ||
                                            s == 'joseph-priority' ||
                                            s == 'legends-show',
                                      )
                                      .map(
                                        (signal) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            signal.substring(0, 3),
                                            style: const TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  // ── STAGE DETAILS GRID ─────────────────────────────────────────────────
  // ignore: unused_element
  Widget _buildStageDetailsGrid(EcosystemStateService state) {
    const stages = ['discover', 'build', 'win', 'sell'];
    const stageLabels = [
      '🔍 SCOUTING',
      '🏗️ BUILDING',
      '🏆 WINNING',
      '💵 CLOSING',
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: List.generate(stages.length, (i) {
        final count = state.opportunitiesInStage(stages[i]);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  stageLabels[i],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      count.toString(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'opportunities',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── COMPACT STAGE ROW (for card view) ───────────────────────────────────
  Widget _buildCompactStageRow(EcosystemStateService state) {
    const stages = ['discover', 'build', 'win', 'sell'];
    const stageColors = [
      Color(0xFF00D9FF),
      Color(0xFF00FF88),
      Color(0xFFFFD600),
      Color(0xFFFF0080),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(stages.length, (i) {
        final count = state.opportunitiesInStage(stages[i]);
        return Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    stageColors[i].withValues(alpha: 0.3),
                    stageColors[i].withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: stageColors[i].withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: stageColors[i],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              stages[i].toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: stageColors[i],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCompactMetrics(EcosystemStateService state) {
    final metrics = state.realTimeMetrics;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCompactMetricBadge(
          'Closed',
          metrics['deals_closed'].toString(),
          Colors.green,
        ),
        _buildCompactMetricBadge(
          'YouTube',
          metrics['youtube_views_generated'].toString(),
          Colors.orange,
        ),
        _buildCompactMetricBadge(
          'Samurai',
          metrics['samurai_signal_hits'].toString(),
          AppTheme.neonCyan,
        ),
      ],
    );
  }

  Widget _buildCompactMetricBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  // ── IMAGE DROP ZONE FOR PIPELINE CARDS ──────────────────────────────────
  Widget _buildImageDropZone({
    required OpportunityStageItem opp,
    required Color stageColor,
    required Future<void> Function(Uint8List bytes, String filename)
    onImageDropped,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isDragging = false;

        return GestureDetector(
          onTap: () => _pickImageForOpportunity(opp.id),
          child: DragTarget<Object>(
            onWillAcceptWithDetails: (details) {
              setState(() => isDragging = true);
              return true;
            },
            onLeave: (_) => setState(() => isDragging = false),
            onAcceptWithDetails: (details) async {
              setState(() => isDragging = false);
              // Handle web file drops via JS interop
              _handleWebFileDrop(opp.id);
            },
            builder: (context, candidateData, rejectedData) {
              // Show existing image or placeholder
              return Container(
                height: 50,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: isDragging
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: (opp.imageUrl != null && opp.imageUrl!.isNotEmpty)
                      ? DfcNetworkImage(url: opp.imageUrl!)
                      : _buildImagePlaceholder(stageColor, isDragging),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildImagePlaceholder(Color stageColor, bool isDragging) {
    return Container(
      height: 40,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: stageColor.withValues(alpha: isDragging ? 0.4 : 0.2),
        border: Border.all(
          color: isDragging ? Colors.white : stageColor.withValues(alpha: 0.5),
          width: isDragging ? 2 : 1,
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDragging ? Icons.download : Icons.add_photo_alternate_outlined,
              size: 14,
              color: isDragging ? Colors.white : Colors.white54,
            ),
            const SizedBox(width: 4),
            Text(
              isDragging ? 'DROP' : 'Add Image',
              style: TextStyle(
                fontSize: 9,
                color: isDragging ? Colors.white : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Pick image using file input
  void _pickImageForOpportunity(String opportunityId) {
    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = 'image/*';
    input.click();

    input.onChange.listen((event) async {
      final files = input.files;
      if (files != null && files.length > 0) {
        final file = files.item(0)!;
        final reader = web.FileReader();

        reader.onLoadEnd.listen((event) async {
          if (reader.result != null) {
            final arrayBuffer = reader.result! as JSArrayBuffer;
            final bytes = arrayBuffer.toDart.asUint8List();
            await _uploadImageToFirebase(opportunityId, bytes, file.name);
          }
        });

        reader.readAsArrayBuffer(file);
      }
    });
  }

  // Handle web file drop
  void _handleWebFileDrop(String opportunityId) {
    // For web, we use the click-to-upload since native drag requires JS interop
    _pickImageForOpportunity(opportunityId);
  }

  // Upload image to Firebase Storage
  Future<void> _uploadImageToFirebase(
    String opportunityId,
    Uint8List bytes,
    String filename,
  ) async {
    try {
      final storage = FirebaseStorage.instance;
      final ext = filename.split('.').last;
      final ref = storage.ref('pipeline_images/$opportunityId.$ext');

      await ref.putData(bytes, SettableMetadata(contentType: 'image/$ext'));
      final url = await ref.getDownloadURL();

      // Update the opportunity with the image URL
      if (!mounted) return;
      final state = context.read<EcosystemStateService>();
      state.updateOpportunityImage(opportunityId, url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded!'),
            backgroundColor: AppTheme.accentCyan,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Handle image upload (called from drag-drop)
  Future<void> _handleImageUpload(
    BuildContext context,
    String opportunityId,
    Uint8List bytes,
    String filename,
  ) async {
    await _uploadImageToFirebase(opportunityId, bytes, filename);
  }
}

/// ─────────────────────────────────────────────────────────────────────────
/// Custom Painter: Animated flow lines between stages
class AnimatedFlowLinePainter extends CustomPainter {
  final Animation<double> animation;
  final int stageCount;

  AnimatedFlowLinePainter({required this.animation, required this.stageCount})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF00D9FF),
          Color(0xFF00FF88),
          Color(0xFFFFD600),
          Color(0xFFFF0080),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final stageSeparation = size.width / stageCount;

    for (int i = 0; i < stageCount - 1; i++) {
      final x1 = (i + 0.5) * stageSeparation;
      final x2 = (i + 1.5) * stageSeparation;

      // Animated arrow effect
      final animProgress = animation.value;
      final pathProgress = (animProgress + (i / stageCount)) % 1.0;

      // Draw connecting curve with dash animation
      final path = Path()
        ..moveTo(x1, size.height / 2)
        ..cubicTo(
          x1 + (x2 - x1) * 0.3,
          size.height / 2 - 20,
          x1 + (x2 - x1) * 0.7,
          size.height / 2 + 20,
          x2,
          size.height / 2,
        );

      // Create dashed effect with animation
      _drawDashedPath(canvas, path, paint, pathProgress);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double progress) {
    // Simple implementation: draw segments
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final len = metric.length;
      final dashLength = 10.0;
      final gapLength = 8.0;
      final totalLength = dashLength + gapLength;

      double distance = (progress * len * 2) % len;
      while (distance < len) {
        final next = distance + dashLength;
        if (next <= len) {
          final pathSegment = metric.extractPath(
            distance,
            next.clamp(0, len).toDouble(),
          );
          canvas.drawPath(pathSegment, paint);
        }
        distance += totalLength;
      }
    }
  }

  @override
  bool shouldRepaint(AnimatedFlowLinePainter oldDelegate) => true;
}
