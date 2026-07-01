import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/content_scanner_engine.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// RADAR DASHBOARD — 53-Bot Live Scanner Feed
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Shows all active scanner bots grouped by region with live status,
/// last scan time and content count per source.
/// DFC-owned channels (FightPipe YT + DFC Facebook) highlighted at top.
/// ═══════════════════════════════════════════════════════════════════════════

class RadarDashboardScreen extends StatefulWidget {
  const RadarDashboardScreen({super.key});

  @override
  State<RadarDashboardScreen> createState() => _RadarDashboardScreenState();
}

class _RadarDashboardScreenState extends State<RadarDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Timer _refreshTimer;
  late ContentScannerEngine _engine;

  // Simulated live state per bot
  final Map<String, _BotLiveState> _liveState = {};
  int _totalContentScanned = 0;

  @override
  void initState() {
    super.initState();
    _engine = ContentScannerEngine();
    _engine.initialize();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Seed initial state
    for (final bot in _engine.bots) {
      _liveState[bot.name] = _BotLiveState(
        status: _BotStatus.idle,
        lastScanAgo: Duration(minutes: (bot.interval.inMinutes / 2).round()),
        contentCount: 0,
      );
    }

    // Simulated scan pulse every 3 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        for (final bot in _engine.bots) {
          final state = _liveState[bot.name]!;
          final newAgo = Duration(seconds: state.lastScanAgo.inSeconds + 3);
          // When interval is up, mark as scanning
          final scanning = newAgo >= bot.interval;
          _liveState[bot.name] = _BotLiveState(
            status: scanning ? _BotStatus.scanning : _BotStatus.active,
            lastScanAgo: scanning ? Duration.zero : newAgo,
            contentCount: state.contentCount + (scanning ? 1 : 0),
          );
          if (scanning) _totalContentScanned++;
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _refreshTimer.cancel();
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bots = _engine.bots;
    final groups = _buildGroups(bots);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D14),
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, _) => Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignTokens.neonGreen.withValues(
                    alpha: 0.4 + 0.6 * _pulseController.value,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.neonGreen.withValues(
                        alpha: 0.3 * _pulseController.value,
                      ),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'DFC RADAR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: DesignTokens.neonCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                '${bots.length} BOTS LIVE',
                style: const TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryBar(bots),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: groups.entries.map((e) {
                return _buildRegionGroup(e.key, e.value);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(List<ScannerBot> bots) {
    final scanning = _liveState.values
        .where((s) => s.status == _BotStatus.scanning)
        .length;
    final active = _liveState.values
        .where((s) => s.status == _BotStatus.active)
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D14),
        border: Border(
          bottom: BorderSide(
            color: DesignTokens.neonCyan.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          _summaryChip(
            label: 'SCANNING',
            value: scanning.toString(),
            color: DesignTokens.neonGreen,
          ),
          const SizedBox(width: 12),
          _summaryChip(
            label: 'ACTIVE',
            value: active.toString(),
            color: DesignTokens.neonCyan,
          ),
          const SizedBox(width: 12),
          _summaryChip(
            label: 'TOTAL BOTS',
            value: bots.length.toString(),
            color: DesignTokens.neonAmber,
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_totalContentScanned',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'items pulled',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildRegionGroup(String region, List<ScannerBot> bots) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(_regionIcon(region), style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  region.toUpperCase(),
                  style: TextStyle(
                    color: _regionColor(region),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${bots.length} bots',
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
          ),
          ...bots.map(_buildBotRow),
          const SizedBox(height: 4),
          Divider(color: Colors.white.withValues(alpha: 0.05)),
        ],
      ),
    );
  }

  Widget _buildBotRow(ScannerBot bot) {
    final state =
        _liveState[bot.name] ??
        const _BotLiveState(
          status: _BotStatus.idle,
          lastScanAgo: Duration.zero,
          contentCount: 0,
        );
    final isDfcOwned =
        bot.source == ScanSource.dfcYoutube ||
        bot.source == ScanSource.dfcFacebook;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDfcOwned
            ? DesignTokens.neonGold.withValues(alpha: 0.06)
            : const Color(0xFF111119),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDfcOwned
              ? DesignTokens.neonGold.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          // Status dot
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, _) {
              final isScanning = state.status == _BotStatus.scanning;
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isScanning
                      ? DesignTokens.neonGreen.withValues(
                          alpha: 0.4 + 0.6 * _pulseController.value,
                        )
                      : _statusColor(state.status).withValues(alpha: 0.7),
                  boxShadow: isScanning
                      ? [
                          BoxShadow(
                            color: DesignTokens.neonGreen.withValues(
                              alpha: 0.4 * _pulseController.value,
                            ),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          // Source icon
          Text(_sourceIcon(bot.source), style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          // Bot name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        bot.name,
                        style: TextStyle(
                          color: isDfcOwned
                              ? DesignTokens.neonGold
                              : Colors.white,
                          fontSize: 12,
                          fontWeight: isDfcOwned
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isDfcOwned) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.neonGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'DFC OWNED',
                          style: TextStyle(
                            color: DesignTokens.neonGold,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'every ${bot.interval.inMinutes}m · last: ${_formatAgo(state.lastScanAgo)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          // Content count
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${state.contentCount}',
                style: TextStyle(
                  color: state.contentCount > 0
                      ? DesignTokens.neonCyan
                      : Colors.white24,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'items',
                style: TextStyle(color: Colors.white24, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _statusColor(state.status).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _statusLabel(state.status),
              style: TextStyle(
                color: _statusColor(state.status),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Map<String, List<ScannerBot>> _buildGroups(List<ScannerBot> bots) {
    final groups = <String, List<ScannerBot>>{
      'DFC Owned (Trust 1.00)': [],
      'Western': [],
      'East Asian': [],
      'South Asian — India': [],
      'Pakistan & Punjabi': [],
      'Metaverse & Web3': [],
      'Partner & Premium': [],
      'Other': [],
    };

    for (final bot in bots) {
      final s = bot.source;
      if (s == ScanSource.dfcYoutube || s == ScanSource.dfcFacebook) {
        groups['DFC Owned (Trust 1.00)']!.add(bot);
      } else if (s == ScanSource.shareChat ||
          s == ScanSource.moj ||
          s == ScanSource.josh ||
          s == ScanSource.roposo ||
          s == ScanSource.chingari ||
          s == ScanSource.helo ||
          s == ScanSource.takatak) {
        groups['South Asian — India']!.add(bot);
      } else if (s == ScanSource.tiktokPakistan ||
          s == ScanSource.bigoPakistan ||
          s == ScanSource.snackVideoPakistan ||
          s == ScanSource.likeePakistan ||
          s == ScanSource.facebookPakistan ||
          s == ScanSource.youtubePakistan) {
        groups['Pakistan & Punjabi']!.add(bot);
      } else if (s == ScanSource.wechat ||
          s == ScanSource.douyin ||
          s == ScanSource.bilibili ||
          s == ScanSource.line ||
          s == ScanSource.kakao ||
          s == ScanSource.niconico ||
          s == ScanSource.pixiv) {
        groups['East Asian']!.add(bot);
      } else if (s == ScanSource.roblox ||
          s == ScanSource.fortnite ||
          s == ScanSource.decentraland ||
          s == ScanSource.sandbox ||
          s == ScanSource.horizonWorlds) {
        groups['Metaverse & Web3']!.add(bot);
      } else if (s == ScanSource.premiumVerified ||
          s == ScanSource.partnerNetwork) {
        groups['Partner & Premium']!.add(bot);
      } else if (s == ScanSource.facebook ||
          s == ScanSource.instagram ||
          s == ScanSource.tiktok ||
          s == ScanSource.youtube ||
          s == ScanSource.twitter ||
          s == ScanSource.reddit ||
          s == ScanSource.snapchat ||
          s == ScanSource.twitch ||
          s == ScanSource.discord ||
          s == ScanSource.telegram) {
        groups['Western']!.add(bot);
      } else {
        groups['Other']!.add(bot);
      }
    }

    // Remove empty groups
    groups.removeWhere((_, v) => v.isEmpty);
    return groups;
  }

  String _regionIcon(String region) => switch (region) {
    'DFC Owned (Trust 1.00)' => '🏆',
    'Western' => '🌎',
    'East Asian' => '🌏',
    'South Asian — India' => '🇮🇳',
    'Pakistan & Punjabi' => '🇵🇰',
    'Metaverse & Web3' => '🌐',
    'Partner & Premium' => '🤝',
    _ => '🌍',
  };

  Color _regionColor(String region) => switch (region) {
    'DFC Owned (Trust 1.00)' => DesignTokens.neonGold,
    'Western' => DesignTokens.neonCyan,
    'East Asian' => DesignTokens.neonMagenta,
    'South Asian — India' => const Color(0xFFFF9933),
    'Pakistan & Punjabi' => const Color(0xFF01411C),
    'Metaverse & Web3' => DesignTokens.neonBlue,
    'Partner & Premium' => DesignTokens.neonGreen,
    _ => Colors.white38,
  };

  Color _statusColor(_BotStatus s) => switch (s) {
    _BotStatus.scanning => DesignTokens.neonGreen,
    _BotStatus.active => DesignTokens.neonCyan,
    _BotStatus.idle => Colors.white38,
  };

  String _statusLabel(_BotStatus s) => switch (s) {
    _BotStatus.scanning => 'SCANNING',
    _BotStatus.active => 'ACTIVE',
    _BotStatus.idle => 'IDLE',
  };

  String _formatAgo(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
  }

  String _sourceIcon(ScanSource s) => switch (s) {
    ScanSource.dfcYoutube => '▶️',
    ScanSource.dfcFacebook => '🏟️',
    ScanSource.facebook => '📘',
    ScanSource.facebookPakistan => '📘',
    ScanSource.instagram => '📸',
    ScanSource.tiktok => '🎵',
    ScanSource.tiktokPakistan => '🎵',
    ScanSource.youtube => '▶️',
    ScanSource.youtubePakistan => '▶️',
    ScanSource.twitter => '🐦',
    ScanSource.reddit => '🤖',
    ScanSource.snapchat => '👻',
    ScanSource.twitch => '🎮',
    ScanSource.discord => '💬',
    ScanSource.telegram => '✈️',
    ScanSource.wechat => '💚',
    ScanSource.douyin => '🎵',
    ScanSource.bilibili => '📺',
    ScanSource.line => '💛',
    ScanSource.kakao => '🟡',
    ScanSource.niconico => '🇯🇵',
    ScanSource.pixiv => '🎨',
    ScanSource.shareChat => '🇮🇳',
    ScanSource.moj => '🇮🇳',
    ScanSource.josh => '🇮🇳',
    ScanSource.roposo => '🇮🇳',
    ScanSource.chingari => '🔥',
    ScanSource.helo => '🇮🇳',
    ScanSource.takatak => '🎬',
    ScanSource.bigoPakistan => '🇵🇰',
    ScanSource.snackVideoPakistan => '🇵🇰',
    ScanSource.likeePakistan => '🇵🇰',
    ScanSource.roblox => '🎮',
    ScanSource.fortnite => '⚡',
    ScanSource.decentraland => '🌐',
    ScanSource.sandbox => '🏜️',
    ScanSource.horizonWorlds => '🥽',
    ScanSource.premiumVerified => '✅',
    ScanSource.partnerNetwork => '🤝',
    _ => '📡',
  };
}

// ─── Supporting Models ────────────────────────────────────────────────────

enum _BotStatus { scanning, active, idle }

class _BotLiveState {
  final _BotStatus status;
  final Duration lastScanAgo;
  final int contentCount;
  const _BotLiveState({
    required this.status,
    required this.lastScanAgo,
    required this.contentCount,
  });
}
