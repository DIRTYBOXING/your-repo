import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/router_config.dart' as rc;
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/signal_card.dart';
import '../../../shared/widgets/ecosystem_hub.dart';
import '../../../shared/widgets/readiness_snapshot.dart';
import '../../../shared/widgets/performance_charts.dart';
import '../../../shared/widgets/fightwire_feed.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// COMMAND CENTER v3.0 — "NEURAL HQ"
/// World-first AI-native combat intelligence hub
/// ═══════════════════════════════════════════════════════════════════════════
class CommandCenterDashboard extends StatefulWidget {
  const CommandCenterDashboard({super.key});

  @override
  State<CommandCenterDashboard> createState() => _CommandCenterDashboardState();
}

class _CommandCenterDashboardState extends State<CommandCenterDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _orbController;
  late AnimationController _pulseController;
  late AnimationController _graphController;
  late Animation<double> _orbAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _graphAnimation;

  Map<String, dynamic> _readinessData = {
    'restingHR': 62,
    'hrv': 45,
    'sleepQuality': 78,
    'hydration': 85,
    'stress': 35,
    'overallScore': 82,
  };

  List<Map<String, dynamic>> _performanceSignals = [
    {
      'title': 'Load vs Recovery',
      'status': 'green',
      'value': '1.2',
      'description': 'Training load balanced with recovery capacity',
      'action': 'Maintain current intensity',
    },
    {
      'title': 'Weight Cut Risk',
      'status': 'amber',
      'value': '-2.3kg',
      'description': 'Approaching target but hydration declining',
      'action': 'Increase electrolyte intake',
    },
    {
      'title': 'Injury Risk',
      'status': 'green',
      'value': 'Low',
      'description': 'No concerning patterns detected',
      'action': 'Continue monitoring',
    },
    {
      'title': 'CNS Fatigue',
      'status': 'green',
      'value': 'Normal',
      'description': 'Central nervous system well recovered',
      'action': 'Ready for high intensity',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _orbAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_orbController);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _graphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _graphAnimation = CurvedAnimation(
      parent: _graphController,
      curve: Curves.easeOutCubic,
    );
    _loadFromFirestore();
  }

  Future<void> _loadFromFirestore() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('fighter_stats')
          .doc(uid)
          .get();
      if (!doc.exists || doc.data() == null) return;
      final data = doc.data()!;
      if (mounted) {
        setState(() {
          if (data['readiness'] is Map) {
            _readinessData = Map<String, dynamic>.from(data['readiness']);
          }
          if (data['performanceSignals'] is List) {
            _performanceSignals = (data['performanceSignals'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
        });
      }
    } catch (_) {
      // Firestore unavailable — keep defaults
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _orbController.dispose();
    _pulseController.dispose();
    _graphController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildAppBar(innerBoxIsScrolled),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildTrainingTab(),
              _buildFightWireTab(),
              _buildInsightsTab(),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // APP BAR with orbiting satellite
  // ═══════════════════════════════════════════════════
  Widget _buildAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: DesignTokens.bgPrimary,
      elevation: 0,
      expandedHeight: 160,
      title: Row(
        children: [
          // Animated satellite orb
          AnimatedBuilder(
            animation: _orbAnimation,
            builder: (context, child) {
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.neonCyan.withValues(
                        alpha: 0.3 + 0.2 * math.sin(_orbAnimation.value),
                      ),
                      blurRadius: 12 + 6 * math.sin(_orbAnimation.value),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.hub, color: Colors.white, size: 22),
                    // Orbiting dot
                    Transform.translate(
                      offset: Offset(
                        18 * math.cos(_orbAnimation.value),
                        18 * math.sin(_orbAnimation.value),
                      ),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: DesignTokens.neonCyan,
                          boxShadow: [
                            BoxShadow(
                              color: DesignTokens.neonCyan.withValues(
                                alpha: 0.8,
                              ),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NEURAL HQ',
                style: TextStyle(
                  color: DesignTokens.neonCyan,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 3,
                ),
              ),
              Text(
                'Combat Intelligence Command',
                style: TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Live status indicator
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: DesignTokens.neonGreen.withValues(
                  alpha: 0.1 * _pulseAnimation.value,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: DesignTokens.neonGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DesignTokens.neonGreen,
                      boxShadow: [
                        BoxShadow(
                          color: DesignTokens.neonGreen.withValues(
                            alpha: 0.6 * _pulseAnimation.value,
                          ),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.neonGreen,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        IconButton(
          icon: Stack(
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: DesignTokens.textSecondary,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: DesignTokens.neonRed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: DesignTokens.neonRed.withValues(alpha: 0.6),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          onPressed: () => context.push('/notification-settings'),
        ),
        IconButton(
          icon: const Icon(
            Icons.settings_outlined,
            color: DesignTokens.textSecondary,
          ),
          onPressed: () => context.push('/settings'),
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Grid background
            CustomPaint(painter: _GridBgPainter(), size: Size.infinite),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DesignTokens.neonCyan.withValues(alpha: 0.03),
                    DesignTokens.bgPrimary,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: DesignTokens.neonCyan.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: DesignTokens.neonCyan,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: DesignTokens.neonCyan,
            unselectedLabelColor: DesignTokens.textMuted,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.dashboard_rounded, size: 22),
                text: 'Overview',
              ),
              Tab(icon: Icon(Icons.fitness_center, size: 22), text: 'Training'),
              Tab(icon: Icon(Icons.bolt, size: 22), text: 'FightWire'),
              Tab(icon: Icon(Icons.psychology, size: 22), text: 'AI Insights'),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // OVERVIEW TAB
  // ═══════════════════════════════════════════════════
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAIGreeting(),
          const SizedBox(height: 20),
          _buildReadinessOrb(),
          const SizedBox(height: 20),
          const ReadinessSnapshot(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildSectionHeader('DFC Ecosystem', 'Connected tools & flow'),
          const SizedBox(height: 14),
          EcosystemHub(
            centerLabel: 'NEURAL HQ',
            centerIcon: Icons.hub,
            nodes: [
              EcosystemHubNode(
                label: 'Combat\nAnalytics',
                icon: Icons.analytics,
                accentColor: DesignTokens.neonCyan,
                onTap: () =>
                    context.push(rc.RouteConstants.combatAnalyticsPath),
              ),
              EcosystemHubNode(
                label: 'FightWire',
                icon: Icons.bolt,
                accentColor: DesignTokens.neonAmber,
                onTap: () => context.push(rc.RouteConstants.fightWirePath),
              ),
              EcosystemHubNode(
                label: 'AI Brain',
                icon: Icons.psychology_alt,
                accentColor: DesignTokens.neonMagenta,
                onTap: () => context.push(rc.RouteConstants.aiBrainPath),
              ),
              EcosystemHubNode(
                label: 'Neural\nCoach',
                icon: Icons.psychology,
                accentColor: DesignTokens.neonGreen,
                onTap: () => context.push(rc.RouteConstants.neuralCoachPath),
              ),
              EcosystemHubNode(
                label: 'Body\nMonitor',
                icon: Icons.monitor_heart,
                accentColor: DesignTokens.neonCyan,
                onTap: () => context.push(rc.RouteConstants.bodyMonitorPath),
              ),
              EcosystemHubNode(
                label: 'FightLab',
                icon: Icons.science,
                accentColor: DesignTokens.neonMagenta,
                onTap: () => context.push(rc.RouteConstants.fightLabPath),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _buildSectionHeader(
            'Performance Signals',
            'Real-time health intelligence',
          ),
          const SizedBox(height: 14),
          ..._performanceSignals.map(
            (signal) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SignalCard(
                title: signal['title'],
                status: _parseSignalStatus(signal['status']),
                explanation: '${signal['description']}. ${signal['action']}',
                action: signal['action'],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('FightWire', 'Live opportunities'),
          const SizedBox(height: 12),
          const FightWireFeed(previewMode: true),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // AI GREETING — animated gradient card
  // ═══════════════════════════════════════════════════
  Widget _buildAIGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData icon;
    Color accentColor;

    if (hour < 12) {
      greeting = 'Good morning';
      icon = Icons.wb_sunny_outlined;
      accentColor = DesignTokens.neonAmber;
    } else if (hour < 17) {
      greeting = 'Good afternoon';
      icon = Icons.wb_cloudy_outlined;
      accentColor = DesignTokens.neonCyan;
    } else {
      greeting = 'Good evening';
      icon = Icons.nightlight_outlined;
      accentColor = DesignTokens.neonMagenta;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withValues(
                  alpha: 0.08 + 0.04 * _pulseAnimation.value,
                ),
                DesignTokens.neonMagenta.withValues(alpha: 0.04),
                DesignTokens.bgCard,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.3),
                      accentColor.withValues(alpha: 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(
                        alpha: 0.2 * _pulseAnimation.value,
                      ),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, Champion',
                      style: const TextStyle(
                        color: DesignTokens.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Readiness ${_readinessData['overallScore']}% — primed for a productive session.',
                      style: const TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════
  // READINESS ORB — animated circular score
  // ═══════════════════════════════════════════════════
  Widget _buildReadinessOrb() {
    final score = _readinessData['overallScore'] as int;
    final Color orbColor = score >= 80
        ? DesignTokens.neonGreen
        : score >= 60
        ? DesignTokens.neonAmber
        : DesignTokens.neonRed;

    return AnimatedBuilder(
      animation: _graphAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: orbColor.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              // Animated orb
              SizedBox(
                width: 110,
                height: 110,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _ReadinessOrbPainter(
                        progress: (score / 100) * _graphAnimation.value,
                        color: orbColor,
                        glowIntensity: _pulseAnimation.value,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(score * _graphAnimation.value).toInt()}',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: orbColor,
                                height: 1,
                              ),
                            ),
                            Text(
                              'READY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: orbColor.withValues(alpha: 0.7),
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 24),
              // Metric bars
              Expanded(
                child: Column(
                  children: [
                    _buildMiniMetric(
                      'Heart Rate',
                      '${_readinessData['restingHR']} bpm',
                      _readinessData['restingHR'] / 100,
                      DesignTokens.neonRed,
                    ),
                    const SizedBox(height: 10),
                    _buildMiniMetric(
                      'HRV',
                      '${_readinessData['hrv']} ms',
                      _readinessData['hrv'] / 80,
                      DesignTokens.neonCyan,
                    ),
                    const SizedBox(height: 10),
                    _buildMiniMetric(
                      'Sleep',
                      '${_readinessData['sleepQuality']}%',
                      _readinessData['sleepQuality'] / 100,
                      DesignTokens.neonMagenta,
                    ),
                    const SizedBox(height: 10),
                    _buildMiniMetric(
                      'Hydration',
                      '${_readinessData['hydration']}%',
                      _readinessData['hydration'] / 100,
                      DesignTokens.neonGreen,
                    ),
                    const SizedBox(height: 10),
                    _buildMiniMetric(
                      'Stress',
                      '${_readinessData['stress']}%',
                      _readinessData['stress'] / 100,
                      DesignTokens.neonAmber,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniMetric(
    String label,
    String value,
    double progress,
    Color color,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 65,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: DesignTokens.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (progress * _graphAnimation.value).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.6), color],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // QUICK ACTIONS — styled bubble grid
  // ═══════════════════════════════════════════════════
  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.play_arrow,
        'label': 'Start\nSession',
        'color': DesignTokens.neonGreen,
        'route': '/fight-camp-tools',
      },
      {
        'icon': Icons.water_drop,
        'label': 'Log\nHydration',
        'color': DesignTokens.neonCyan,
        'route': '/metrics/hydration',
      },
      {
        'icon': Icons.bed,
        'label': 'Log\nSleep',
        'color': DesignTokens.neonMagenta,
        'route': '/metrics/sleep',
      },
      {
        'icon': Icons.monitor_weight,
        'label': 'Log\nWeight',
        'color': DesignTokens.neonAmber,
        'route': '/fight-camp-tools',
      },
      {
        'icon': Icons.flight,
        'label': 'Drone\nCommand',
        'color': DesignTokens.neonCyan,
        'route': '/drone-command',
      },
    ];

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: actions.length,
        itemBuilder: (context, i) {
          final action = actions[i];
          final color = action['color'] as Color;
          return GestureDetector(
            onTap: () => context.push(action['route'] as String),
            child: AnimatedBuilder(
              animation: _graphAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.5 + 0.5 * _graphAnimation.value,
                  child: Opacity(
                    opacity: _graphAnimation.value,
                    child: Container(
                      width: 80,
                      margin: EdgeInsets.only(right: 10, left: i == 0 ? 0 : 0),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              action['icon'] as IconData,
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            action['label'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: DesignTokens.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // SECTION HEADER
  // ═══════════════════════════════════════════════════
  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            switch (_tabController.index) {
              case 0:
                context.push('/command-center');
                break;
              case 1:
                context.push('/fight-camp-tools');
                break;
              case 2:
                context.push('/marketplace');
                break;
              case 3:
                context.push('/ai-brain');
                break;
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: DesignTokens.neonCyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'View All',
              style: TextStyle(
                color: DesignTokens.neonCyan,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // TRAINING TAB
  // ═══════════════════════════════════════════════════
  Widget _buildTrainingTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCampStatusCard(),
          const SizedBox(height: 24),
          _buildSectionHeader('Performance Trends', '7-day analysis'),
          const SizedBox(height: 14),
          const PerformanceCharts(),
          const SizedBox(height: 24),
          _buildTrainingLoadCard(),
          const SizedBox(height: 24),
          _buildRecoveryMetrics(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // CAMP STATUS — gradient card with progress
  // ═══════════════════════════════════════════════════
  Widget _buildCampStatusCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.1),
            DesignTokens.neonMagenta.withValues(alpha: 0.06),
            DesignTokens.bgCard,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_fire_department,
                      color: DesignTokens.neonGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Fight Camp Active',
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'Week 4 of 8',
                  style: TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Animated progress bar
          AnimatedBuilder(
            animation: _graphAnimation,
            builder: (context, child) {
              return Container(
                height: 10,
                decoration: BoxDecoration(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.5 * _graphAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [DesignTokens.neonCyan, DesignTokens.neonGreen],
                      ),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCampStat('Phase', 'Build', DesignTokens.neonCyan),
              _buildCampStat('Target', 'Mar 14', DesignTokens.neonAmber),
              _buildCampStat('Weight', '-3.2kg', DesignTokens.neonGreen),
              _buildCampStat('Ready', '82%', DesignTokens.neonMagenta),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCampStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: DesignTokens.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // TRAINING LOAD — animated bar chart
  // ═══════════════════════════════════════════════════
  Widget _buildTrainingLoadCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Training Load',
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '1,240 AU',
                  style: TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Animated bars
          AnimatedBuilder(
            animation: _graphAnimation,
            builder: (context, child) {
              return SizedBox(
                height: 80,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildAnimatedBar('Mon', 0.8, DesignTokens.neonGreen),
                    _buildAnimatedBar('Tue', 0.6, DesignTokens.neonGreen),
                    _buildAnimatedBar('Wed', 0.9, DesignTokens.neonAmber),
                    _buildAnimatedBar('Thu', 0.4, DesignTokens.neonGreen),
                    _buildAnimatedBar('Fri', 0.7, DesignTokens.neonCyan),
                    _buildAnimatedBar('Sat', 0.3, DesignTokens.neonGreen),
                    _buildAnimatedBar('Sun', 0.05, DesignTokens.textMuted),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // AI insight bubble
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.neonGreen.withValues(alpha: 0.08),
                  DesignTokens.bgCard,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: DesignTokens.neonGreen.withValues(alpha: 0.15),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.psychology, color: DesignTokens.neonGreen, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Load is well-balanced. Recovery optimal for increased intensity tomorrow.',
                    style: TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBar(String day, double value, Color color) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: 60 * value * _graphAnimation.value,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [color.withValues(alpha: 0.4), color],
              ),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            day,
            style: const TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // RECOVERY METRICS — animated bars
  // ═══════════════════════════════════════════════════
  Widget _buildRecoveryMetrics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DesignTokens.neonMagenta.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.healing, size: 18, color: DesignTokens.neonMagenta),
              SizedBox(width: 8),
              Text(
                'Recovery Metrics',
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildRecoveryRow('Sleep Quality', 78, DesignTokens.neonMagenta),
          _buildRecoveryRow('HRV Trend', 65, DesignTokens.neonCyan),
          _buildRecoveryRow('Muscle Readiness', 82, DesignTokens.neonGreen),
          _buildRecoveryRow('Mental Freshness', 70, DesignTokens.neonAmber),
        ],
      ),
    );
  }

  Widget _buildRecoveryRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                color: DesignTokens.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: AnimatedBuilder(
              animation: _graphAnimation,
              builder: (context, child) {
                return Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (value / 100) * _graphAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withValues(alpha: 0.5), color],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$value%',
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // FIGHTWIRE TAB
  // ═══════════════════════════════════════════════════
  Widget _buildFightWireTab() {
    return const FightWireFeed();
  }

  // ═══════════════════════════════════════════════════
  // AI INSIGHTS TAB
  // ═══════════════════════════════════════════════════
  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAICoachCard(),
          const SizedBox(height: 24),
          _buildMonthlyAnalytics(),
          const SizedBox(height: 24),
          _buildGoalsProgress(),
          const SizedBox(height: 24),
          _buildMentalHealthCheck(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // AI COACH — gradient card with orb
  // ═══════════════════════════════════════════════════
  Widget _buildAICoachCard() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DesignTokens.neonMagenta.withValues(alpha: 0.1),
                DesignTokens.neonCyan.withValues(alpha: 0.06),
                DesignTokens.bgCard,
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: DesignTokens.neonMagenta.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          DesignTokens.neonMagenta,
                          DesignTokens.neonCyan,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: DesignTokens.neonMagenta.withValues(
                            alpha: 0.3 * _pulseAnimation.value,
                          ),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Coach Insight',
                        style: TextStyle(
                          color: DesignTokens.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Daily personalized guidance',
                        style: TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DesignTokens.bgSecondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.08),
                  ),
                ),
                child: const Text(
                  '"Based on your HRV trend and training load this week, today is optimal for a high-intensity session. '
                  'Your recovery metrics show you\'re in a good adaptive state. Consider focusing on explosive work."',
                  style: TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/ai-brain'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_outlined,
                              size: 18,
                              color: DesignTokens.neonCyan,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Ask AI',
                              style: TextStyle(
                                color: DesignTokens.neonCyan,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/fight-camp-tools'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              DesignTokens.neonCyan,
                              DesignTokens.neonGreen,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: DesignTokens.neonCyan.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_arrow,
                              size: 18,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Start Session',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════
  // MONTHLY ANALYTICS — animated circles
  // ═══════════════════════════════════════════════════
  Widget _buildMonthlyAnalytics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'February Analytics',
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(
                Icons.calendar_month,
                color: DesignTokens.neonCyan,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _graphAnimation,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAnalyticOrb(
                    'Sessions',
                    '18',
                    DesignTokens.neonGreen,
                    0.9,
                  ),
                  _buildAnalyticOrb(
                    'Avg Load',
                    '156',
                    DesignTokens.neonCyan,
                    0.78,
                  ),
                  _buildAnalyticOrb(
                    'Recovery',
                    '78%',
                    DesignTokens.neonMagenta,
                    0.78,
                  ),
                  _buildAnalyticOrb(
                    'Streak',
                    '12d',
                    DesignTokens.neonAmber,
                    0.6,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticOrb(
    String label,
    String value,
    Color color,
    double progress,
  ) {
    return Column(
      children: [
        SizedBox(
          width: 68,
          height: 68,
          child: CustomPaint(
            painter: _AnalyticOrbPainter(
              progress: progress * _graphAnimation.value,
              color: color,
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: DesignTokens.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // GOALS PROGRESS
  // ═══════════════════════════════════════════════════
  Widget _buildGoalsProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DesignTokens.neonGreen.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flag, size: 18, color: DesignTokens.neonGreen),
              SizedBox(width: 8),
              Text(
                'Goals Progress',
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildGoalRow(
            'Make weight (75kg)',
            0.7,
            '77.1kg → 75kg',
            DesignTokens.neonAmber,
          ),
          _buildGoalRow(
            'Training consistency',
            0.85,
            '17/20 sessions',
            DesignTokens.neonGreen,
          ),
          _buildGoalRow(
            'Sleep 8+ hours',
            0.6,
            '12/20 nights',
            DesignTokens.neonMagenta,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalRow(
    String label,
    double progress,
    String detail,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                detail,
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _graphAnimation,
            builder: (context, child) {
              return Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress * _graphAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.5), color],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // MENTAL HEALTH CHECK
  // ═══════════════════════════════════════════════════
  Widget _buildMentalHealthCheck() {
    return GestureDetector(
      onTap: () => context.push('/wellness'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              DesignTokens.neonMagenta.withValues(alpha: 0.08),
              DesignTokens.neonCyan.withValues(alpha: 0.04),
              DesignTokens.bgCard,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: DesignTokens.neonMagenta.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DesignTokens.neonMagenta.withValues(alpha: 0.2),
                    DesignTokens.neonCyan.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.self_improvement,
                color: DesignTokens.neonMagenta,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How are you feeling today?',
                    style: TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Quick check-in helps track your mental wellness',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: DesignTokens.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  SignalStatus _parseSignalStatus(String status) {
    switch (status.toLowerCase()) {
      case 'green':
        return SignalStatus.green;
      case 'amber':
        return SignalStatus.amber;
      case 'red':
        return SignalStatus.red;
      default:
        return SignalStatus.green;
    }
  }
}

// ═══════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════

class _GridBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DesignTokens.neonCyan.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReadinessOrbPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double glowIntensity;

  _ReadinessOrbPainter({
    required this.progress,
    required this.color,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.06)
        ..style = PaintingStyle.fill,
    );

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    // Glow effect
    canvas.drawCircle(
      center,
      radius + 2,
      Paint()
        ..color = color.withValues(alpha: 0.08 * glowIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // End dot
    if (progress > 0) {
      final angle = -math.pi / 2 + 2 * math.pi * progress;
      final dotX = center.dx + radius * math.cos(angle);
      final dotY = center.dy + radius * math.sin(angle);

      canvas.drawCircle(Offset(dotX, dotY), 4, Paint()..color = color);
      canvas.drawCircle(
        Offset(dotX, dotY),
        7,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  @override
  bool shouldRepaint(_ReadinessOrbPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      color != oldDelegate.color ||
      glowIntensity != oldDelegate.glowIntensity;
}

class _AnalyticOrbPainter extends CustomPainter {
  final double progress;
  final Color color;

  _AnalyticOrbPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // Glow
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(_AnalyticOrbPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}
