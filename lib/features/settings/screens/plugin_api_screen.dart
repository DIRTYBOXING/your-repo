import 'package:flutter/material.dart';
import 'package:datafightcentral/core/theme/design_tokens.dart';

/// Plugin API Screen — DFC's developer ecosystem.
/// API keys, webhook management, connected apps, usage analytics.
/// Empowering the tech-smart community to build on combat sports data.
class PluginApiScreen extends StatefulWidget {
  const PluginApiScreen({super.key});

  @override
  State<PluginApiScreen> createState() => _PluginApiScreenState();
}

class _PluginApiScreenState extends State<PluginApiScreen> {
  final bool _apiEnabled = true;
  int _selectedTab = 0;

  static const _tabs = ['API Keys', 'Webhooks', 'Connected Apps', 'Usage'];

  static const List<Map<String, dynamic>> _apiKeys = [
    {
      'name': 'Production Key',
      'key': 'dfc_live_sk_••••••••••••7f3a',
      'created': 'Feb 15, 2026',
      'lastUsed': '2 hours ago',
      'active': true,
    },
    {
      'name': 'Development Key',
      'key': 'dfc_test_sk_••••••••••••9b2c',
      'created': 'Jan 20, 2026',
      'lastUsed': 'Yesterday',
      'active': true,
    },
    {
      'name': 'Training Analytics',
      'key': 'dfc_live_sk_••••••••••••1d4e',
      'created': 'Mar 1, 2026',
      'lastUsed': 'Never',
      'active': false,
    },
  ];

  static const List<Map<String, dynamic>> _webhooks = [
    {
      'url': 'https://myapp.com/webhooks/dfc',
      'events': ['fight.result', 'athlete.update'],
      'status': 'Active',
      'successRate': '99.8%',
    },
    {
      'url': 'https://analytics.gym.io/ingest',
      'events': ['training.completed', 'wellness.check'],
      'status': 'Active',
      'successRate': '100%',
    },
  ];

  static const List<Map<String, dynamic>> _connectedApps = [
    {
      'name': 'FitTracker Pro',
      'icon': '🏋️',
      'category': 'Fitness',
      'connected': 'Jan 2026',
      'status': 'Connected',
    },
    {
      'name': 'NutritionIQ',
      'icon': '🥗',
      'category': 'Nutrition',
      'connected': 'Feb 2026',
      'status': 'Connected',
    },
    {
      'name': 'MindfulCoach',
      'icon': '🧠',
      'category': 'Mental Health',
      'connected': 'Feb 2026',
      'status': 'Connected',
    },
    {
      'name': 'Garmin Connect',
      'icon': '⌚',
      'category': 'Wearables',
      'connected': 'Mar 2026',
      'status': 'Pending',
    },
    {
      'name': 'Strava',
      'icon': '🏃',
      'category': 'Cardio Tracking',
      'connected': 'N/A',
      'status': 'Available',
    },
  ];

  static const List<Map<String, dynamic>> _usageStats = [
    {
      'label': 'API Calls Today',
      'value': '1,247',
      'trend': '+12%',
      'color': 0xFF00F5FF,
    },
    {
      'label': 'Monthly Quota',
      'value': '34,892 / 50K',
      'trend': '69.8%',
      'color': 0xFF00FF88,
    },
    {
      'label': 'Avg Response',
      'value': '42ms',
      'trend': '-8ms',
      'color': 0xFFFFB800,
    },
    {
      'label': 'Error Rate',
      'value': '0.02%',
      'trend': 'Excellent',
      'color': 0xFFFF69B4,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgPrimary,
        elevation: 0,
        title: const Text(
          'Plugin API',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _apiEnabled
                  ? DesignTokens.neonGreen.withValues(alpha: 0.12)
                  : DesignTokens.neonRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
              border: Border.all(
                color: _apiEnabled
                    ? DesignTokens.neonGreen.withValues(alpha: 0.3)
                    : DesignTokens.neonRed.withValues(alpha: 0.3),
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
                    color: _apiEnabled
                        ? DesignTokens.neonGreen
                        : DesignTokens.neonRed,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _apiEnabled ? 'API Active' : 'API Off',
                  style: TextStyle(
                    color: _apiEnabled
                        ? DesignTokens.neonGreen
                        : DesignTokens.neonRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildDeveloperBanner(),
                const SizedBox(height: 16),
                _buildContent(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selected
                      ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                  border: selected
                      ? Border.all(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabs[i],
                  style: TextStyle(
                    color: selected
                        ? DesignTokens.neonCyan
                        : Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDeveloperBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.06),
            DesignTokens.neonMagenta.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          const Text('🔌', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Build on Combat Sports Data',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Connect fitness apps, training tools, and health trackers. '
                  'DFC API powers the next generation of athlete technology.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildApiKeys();
      case 1:
        return _buildWebhooks();
      case 2:
        return _buildConnectedApps();
      case 3:
        return _buildUsage();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildApiKeys() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._apiKeys.map(
          (key) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _glassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (key['active'] as bool)
                              ? DesignTokens.neonGreen
                              : Colors.white24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        key['name'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.copy,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      key['key'] as String,
                      style: TextStyle(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Created ${key['created']}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Last used: ${key['lastUsed']}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('New API key generated — keep it secure!'),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'Generate New Key',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: DesignTokens.neonCyan,
              side: BorderSide(
                color: DesignTokens.neonCyan.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebhooks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._webhooks.map(
          (wh) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _glassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.webhook,
                        color: DesignTokens.neonMagenta,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          wh['url'] as String,
                          style: TextStyle(
                            color: DesignTokens.neonCyan.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: (wh['events'] as List)
                        .map(
                          (e) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.neonMagenta.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radiusPill,
                              ),
                            ),
                            child: Text(
                              e as String,
                              style: const TextStyle(
                                color: DesignTokens.neonMagenta,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Status: ${wh['status']}',
                        style: const TextStyle(
                          color: DesignTokens.neonGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Success: ${wh['successRate']}',
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
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'Add Webhook',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: DesignTokens.neonMagenta,
              side: BorderSide(
                color: DesignTokens.neonMagenta.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedApps() {
    return Column(
      children: _connectedApps.map((app) {
        final connected = app['status'] == 'Connected';
        final pending = app['status'] == 'Pending';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _glassCard(
            child: Row(
              children: [
                Text(
                  app['icon'] as String,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app['name'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${app['category']}${connected ? ' • Since ${app['connected']}' : ''}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: connected
                        ? DesignTokens.neonGreen.withValues(alpha: 0.1)
                        : pending
                        ? DesignTokens.neonAmber.withValues(alpha: 0.1)
                        : DesignTokens.neonCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusPill,
                    ),
                    border: Border.all(
                      color: connected
                          ? DesignTokens.neonGreen.withValues(alpha: 0.3)
                          : pending
                          ? DesignTokens.neonAmber.withValues(alpha: 0.3)
                          : DesignTokens.neonCyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    app['status'] as String,
                    style: TextStyle(
                      color: connected
                          ? DesignTokens.neonGreen
                          : pending
                          ? DesignTokens.neonAmber
                          : DesignTokens.neonCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUsage() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(_usageStats[0])),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard(_usageStats[1])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildStatCard(_usageStats[2])),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard(_usageStats[3])),
          ],
        ),
        const SizedBox(height: 16),
        _glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bar_chart, color: DesignTokens.neonCyan, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Request History (7 days)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 80,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [0.4, 0.6, 0.8, 0.5, 0.9, 0.7, 1.0]
                      .asMap()
                      .entries
                      .map((e) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: FractionallySizedBox(
                                    heightFactor: e.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: DesignTokens.neonCyan.withValues(
                                          alpha: 0.3 + e.value * 0.4,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ['M', 'T', 'W', 'T', 'F', 'S', 'S'][e.key],
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    final color = Color(stat['color'] as int);
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat['label'] as String,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stat['value'] as String,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat['trend'] as String,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard.withValues(
          alpha: DesignTokens.glassOpacity + 0.04,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: DesignTokens.glassBorderOpacity,
          ),
        ),
      ),
      child: child,
    );
  }
}
