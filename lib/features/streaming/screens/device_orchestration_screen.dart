import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

/// DEVICE ORCHESTRATION — Timestamped event bus + device SDKs.
/// Haptics · Smart lights · TV overlays · Venue LED · Beacon sync
/// Competitive gap: nobody has device-level fight-moment sync.
class DeviceOrchestrationScreen extends StatefulWidget {
  const DeviceOrchestrationScreen({super.key});

  @override
  State<DeviceOrchestrationScreen> createState() =>
      _DeviceOrchestrationScreenState();
}

class _DeviceOrchestrationScreenState extends State<DeviceOrchestrationScreen> {
  String _selectedCategory = 'ALL';

  final _devices = <_Device>[
    const _Device(
      'Apple Watch Ultra',
      'wearable',
      'connected',
      14,
      DesignTokens.neonGreen,
      Icons.watch,
    ),
    const _Device(
      'Philips Hue Bridge',
      'lighting',
      'connected',
      1,
      DesignTokens.neonGreen,
      Icons.lightbulb,
    ),
    const _Device(
      'Samsung 65" QLED',
      'tv',
      'connected',
      1,
      DesignTokens.neonGreen,
      Icons.tv,
    ),
    const _Device(
      'Venue LED Array — Ring',
      'venue',
      'standby',
      1,
      DesignTokens.neonAmber,
      Icons.stadium,
    ),
    const _Device(
      'BLE Beacon Kit (x8)',
      'beacon',
      'standby',
      8,
      DesignTokens.neonAmber,
      Icons.bluetooth,
    ),
    const _Device(
      'Garmin Instinct 2',
      'wearable',
      'disconnected',
      0,
      Colors.white30,
      Icons.watch,
    ),
    const _Device(
      'LIFX Strip — Crowd Zone',
      'lighting',
      'connected',
      1,
      DesignTokens.neonGreen,
      Icons.light,
    ),
  ];

  final _hapticPatterns = <String>[
    'KNOCKOUT FLASH',
    'ROUND START PULSE',
    'KNOCKDOWN RUMBLE',
    'DECISION REVEAL',
    'CROWD SURGE',
  ];

  @override
  Widget build(BuildContext context) {
    final categories = ['ALL', 'WEARABLE', 'LIGHTING', 'TV', 'VENUE', 'BEACON'];
    final filtered = _selectedCategory == 'ALL'
        ? _devices
        : _devices
              .where((d) => d.type.toUpperCase() == _selectedCategory)
              .toList();

    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Row(
          children: [
            Icon(Icons.device_hub, color: DesignTokens.neonCyan, size: 22),
            SizedBox(width: 8),
            Text(
              'DEVICE ORCHESTRATION',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── STATUS BANNER ──
          _statusBanner(),
          const SizedBox(height: 16),

          // ── CATEGORY STRIP ──
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final c = categories[i];
                final sel = c == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: sel
                          ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                          : DesignTokens.bgCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sel
                            ? DesignTokens.neonCyan.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                    child: Text(
                      c,
                      style: TextStyle(
                        color: sel ? DesignTokens.neonCyan : Colors.white30,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── DEVICE CARDS ──
          ...filtered.map(_deviceCard),

          const SizedBox(height: 24),

          // ── HAPTIC PATTERNS ──
          const Text(
            'HAPTIC PATTERNS',
            style: TextStyle(
              color: DesignTokens.neonMagenta,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          ..._hapticPatterns.map(_hapticRow),

          const SizedBox(height: 24),

          // ── EVENT BUS ──
          const Text(
            'EVENT BUS — LIVE TIMELINE',
            style: TextStyle(
              color: DesignTokens.neonGold,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          _timelineEvent(
            '21:32:04.112',
            'ROUND_START',
            'Round 1 begin',
            DesignTokens.neonGreen,
          ),
          _timelineEvent(
            '21:33:18.445',
            'KNOCKDOWN',
            'Hepi knockdown R1',
            DesignTokens.neonRed,
          ),
          _timelineEvent(
            '21:33:18.450',
            'HAPTIC_FIRE',
            'KNOCKDOWN RUMBLE sent',
            DesignTokens.neonMagenta,
          ),
          _timelineEvent(
            '21:33:18.455',
            'LIGHT_FLASH',
            'Hue red flash',
            DesignTokens.neonAmber,
          ),
          _timelineEvent(
            '21:33:18.460',
            'TV_OVERLAY',
            'Knockdown graphic',
            DesignTokens.neonCyan,
          ),
          _timelineEvent(
            '21:35:00.000',
            'ROUND_END',
            'Round 1 end',
            Colors.white30,
          ),
        ],
      ),
    );
  }

  Widget _statusBanner() {
    final connected = _devices.where((d) => d.status == 'connected').length;
    final standby = _devices.where((d) => d.status == 'standby').length;
    final total = _devices.length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.08),
            DesignTokens.neonMagenta.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          _statPill('CONNECTED', '$connected', DesignTokens.neonGreen),
          const SizedBox(width: 12),
          _statPill('STANDBY', '$standby', DesignTokens.neonAmber),
          const SizedBox(width: 12),
          _statPill('TOTAL', '$total', DesignTokens.neonCyan),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: DesignTokens.neonGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'SYNC ALL',
              style: TextStyle(
                color: DesignTokens.neonGreen,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white30,
            fontWeight: FontWeight.w700,
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  Widget _deviceCard(_Device d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Icon(d.icon, color: d.color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.name,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: d.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      d.status.toUpperCase(),
                      style: TextStyle(
                        color: d.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ),
                    if (d.latencyMs > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${d.latencyMs}ms',
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              d.type.toUpperCase(),
              style: const TextStyle(
                color: Colors.white24,
                fontWeight: FontWeight.w700,
                fontSize: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hapticRow(String pattern) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.vibration,
            color: DesignTokens.neonMagenta,
            size: 16,
          ),
          const SizedBox(width: 10),
          Text(
            pattern,
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: DesignTokens.neonMagenta.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'TEST',
              style: TextStyle(
                color: DesignTokens.neonMagenta,
                fontWeight: FontWeight.w800,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineEvent(String ts, String type, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              ts,
              style: const TextStyle(
                color: Colors.white30,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              type,
              style: TextStyle(
                color: color,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w800,
                fontSize: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _Device {
  final String name;
  final String type;
  final String status;
  final int latencyMs;
  final Color color;
  final IconData icon;
  const _Device(
    this.name,
    this.type,
    this.status,
    this.latencyMs,
    this.color,
    this.icon,
  );
}
