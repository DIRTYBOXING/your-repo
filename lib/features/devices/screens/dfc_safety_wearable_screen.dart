import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/dfc_wearables_engine.dart';
import '../../../shared/widgets/dfc_chart_helpers.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC SAFETY WEARABLE SCREEN — Women's Safety + Emergency Device Hub
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Production-grade safety device dashboard:
///   TAB 1 — DEVICES:     safety wearables you can buy NOW
///   TAB 2 — GUARDIAN:    walk-home mode, check-ins, live map
///   TAB 3 — ANALYTICS:   safety event history, response times, coverage
///   TAB 4 — EDUCATION:   how safety protocols work, why BLE+LTE-M
/// ═══════════════════════════════════════════════════════════════════════════
class DFCSafetyWearableScreen extends StatefulWidget {
  const DFCSafetyWearableScreen({super.key});

  @override
  State<DFCSafetyWearableScreen> createState() =>
      _DFCSafetyWearableScreenState();
}

class _DFCSafetyWearableScreenState extends State<DFCSafetyWearableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _guardianActive = false;
  bool _panicActive = false;
  int _checkInCount = 0;

  // Safety device category from engine
  List<RealDevice> get _safetyDevices => [
    ...DFCWearablesEngine.availableDevices.where(
      (d) => d.category == DeviceCategory.safetyDevice,
    ),
    // Also include smartwatches with SOS
    ...DFCWearablesEngine.availableDevices.where(
      (d) =>
          d.category == DeviceCategory.smartwatch &&
          d.metrics.any(
            (m) =>
                m.toLowerCase().contains('sos') ||
                m.toLowerCase().contains('fall') ||
                m.toLowerCase().contains('crash'),
          ),
    ),
  ];

  List<RealDevice> get _futureSafetyDevices => DFCWearablesEngine.futureDevices
      .where(
        (d) =>
            d.category == DeviceCategory.safetyDevice ||
            d.metrics.any((m) => m.toLowerCase().contains('panic')),
      )
      .toList();

  // Simulated safety analytics
  late final List<double> _responseTimesMs;
  late final List<double> _alertsPerWeek;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final rng = math.Random(99);
    _responseTimesMs = List.generate(12, (i) => 200 + rng.nextDouble() * 800);
    _alertsPerWeek = List.generate(8, (i) => rng.nextDouble() * 5);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDevicesTab(),
                _buildGuardianTab(),
                _buildAnalyticsTab(),
                _buildEducationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header with Dragon Shield ─────────────────────────────────────

  Widget _buildHeader() {
    final emerald = const Color(0xFF00FF9D);
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            emerald.withValues(alpha: 0.06),
            const Color(0xFFFF69B4).withValues(alpha: 0.04),
            DesignTokens.bgPrimary,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          // Dragon shield icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  emerald.withValues(alpha: 0.3),
                  const Color(0xFFFF69B4).withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: emerald.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.shield, color: Color(0xFF00FF9D), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SAFETY WEARABLES',
                  style: TextStyle(
                    color: Color(0xFF00FF9D),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  '${_safetyDevices.length} devices available  •  '
                  '${_futureSafetyDevices.length} in roadmap',
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (_guardianActive)
            _pulsingBadge('GUARDIAN', const Color(0xFF00FF9D))
          else if (_panicActive)
            _pulsingBadge('SOS', DesignTokens.neonRed),
        ],
      ),
    );
  }

  Widget _pulsingBadge(String label, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
              border: Border.all(color: color.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    const emerald = Color(0xFF00FF9D);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: GlassDecoration.card(accent: emerald),
      child: TabBar(
        controller: _tabController,
        indicatorColor: emerald,
        indicatorWeight: 2.5,
        labelColor: emerald,
        unselectedLabelColor: DesignTokens.textMuted,
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
        tabs: const [
          Tab(text: 'DEVICES'),
          Tab(text: 'GUARDIAN'),
          Tab(text: 'ANALYTICS'),
          Tab(text: 'EDUCATION'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 1: SAFETY DEVICES
  // ══════════════════════════════════════════════════════════════════

  Widget _buildDevicesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSafetyBanner(),
        const SizedBox(height: 16),
        _sectionLabel('AVAILABLE NOW', const Color(0xFF00FF9D)),
        ..._safetyDevices.map(_buildSafetyDeviceCard),
        const SizedBox(height: 16),
        if (_futureSafetyDevices.isNotEmpty) ...[
          _sectionLabel('2029-2030 ROADMAP', DesignTokens.neonMagenta),
          ..._futureSafetyDevices.map(_buildSafetyDeviceCard),
        ],
      ],
    );
  }

  Widget _buildSafetyBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF69B4).withValues(alpha: 0.08),
            const Color(0xFF00FF9D).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: const Color(0xFFFF69B4).withValues(alpha: 0.2),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield, color: Color(0xFFFF69B4), size: 20),
              SizedBox(width: 8),
              Text(
                'WOMEN\'S SAFETY, REINVENTED',
                style: TextStyle(
                  color: Color(0xFFFF69B4),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'DFC safety wearables use BLE 5.3 + LTE-M for sub-50ms panic alerts '
            'that work everywhere — no WiFi required. Guardian Mode tracks your '
            'walk home with automatic check-ins and emergency escalation.',
            style: TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyDeviceCard(RealDevice device) {
    final isSafetyPrimary = device.category == DeviceCategory.safetyDevice;
    final accent = isSafetyPrimary
        ? const Color(0xFF00FF9D)
        : DesignTokens.neonCyan;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: GlassDecoration.card(accent: accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(device.imageEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            device.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (device.dfcVerified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF00FF9D,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DFC ✓',
                              style: TextStyle(
                                color: Color(0xFF00FF9D),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${device.manufacturer}  •  ${device.priceRange}',
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (!device.availableNow)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonMagenta.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusPill,
                    ),
                  ),
                  child: Text(
                    '${device.releaseYear}',
                    style: const TextStyle(
                      color: DesignTokens.neonMagenta,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Safety features as prominent chips
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: device.metrics.map((m) {
              final isCritical =
                  m.toLowerCase().contains('panic') ||
                  m.toLowerCase().contains('sos') ||
                  m.toLowerCase().contains('fall') ||
                  m.toLowerCase().contains('crash') ||
                  m.toLowerCase().contains('emergency');
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isCritical
                      ? DesignTokens.neonRed.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(6),
                  border: isCritical
                      ? Border.all(
                          color: DesignTokens.neonRed.withValues(alpha: 0.3),
                        )
                      : null,
                ),
                child: Text(
                  m,
                  style: TextStyle(
                    color: isCritical
                        ? DesignTokens.neonRed
                        : DesignTokens.textSecondary,
                    fontSize: 10,
                    fontWeight: isCritical ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Protocol + battery row
          Row(
            children: [
              ...device.protocols.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _protoColor(p).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      p.displayName,
                      style: TextStyle(
                        color: _protoColor(p),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.battery_full, size: 12, color: DesignTokens.textMuted),
              const SizedBox(width: 3),
              Text(
                '${device.batteryDays}d',
                style: const TextStyle(
                  color: DesignTokens.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 2: GUARDIAN MODE
  // ══════════════════════════════════════════════════════════════════

  Widget _buildGuardianTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGuardianStatus(),
        const SizedBox(height: 16),
        _buildPanicButton(),
        const SizedBox(height: 16),
        _buildGuardianActions(),
        const SizedBox(height: 16),
        _buildEmergencyContacts(),
        const SizedBox(height: 16),
        _buildSafetyChecklist(),
      ],
    );
  }

  Widget _buildGuardianStatus() {
    final emerald = const Color(0xFF00FF9D);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (_guardianActive ? emerald : DesignTokens.neonAmber).withValues(
              alpha: 0.08,
            ),
            DesignTokens.bgPrimary,
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: (_guardianActive ? emerald : Colors.white).withValues(
            alpha: 0.15,
          ),
        ),
      ),
      child: Column(
        children: [
          // Shield icon with ring animation
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (_guardianActive ? emerald : DesignTokens.textMuted)
                  .withValues(alpha: 0.1),
              border: Border.all(
                color: (_guardianActive ? emerald : DesignTokens.textMuted)
                    .withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              _guardianActive ? Icons.shield : Icons.shield_outlined,
              color: _guardianActive ? emerald : DesignTokens.textMuted,
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _guardianActive ? 'GUARDIAN MODE ACTIVE' : 'GUARDIAN MODE OFF',
            style: TextStyle(
              color: _guardianActive ? emerald : DesignTokens.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          if (_guardianActive) ...[
            const SizedBox(height: 4),
            Text(
              'Check-ins: $_checkInCount  •  Contacts notified',
              style: const TextStyle(
                color: DesignTokens.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Toggle button
          GestureDetector(
            onTap: () {
              setState(() {
                _guardianActive = !_guardianActive;
                if (_guardianActive) _checkInCount = 0;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _guardianActive
                    ? DesignTokens.neonRed.withValues(alpha: 0.15)
                    : emerald.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                border: Border.all(
                  color: (_guardianActive ? DesignTokens.neonRed : emerald)
                      .withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                _guardianActive ? 'END GUARDIAN MODE' : 'START GUARDIAN MODE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _guardianActive ? DesignTokens.neonRed : emerald,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanicButton() {
    return GestureDetector(
      onLongPress: () {
        setState(() => _panicActive = !_panicActive);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              DesignTokens.neonRed.withValues(alpha: _panicActive ? 0.3 : 0.1),
              DesignTokens.neonRed.withValues(
                alpha: _panicActive ? 0.15 : 0.05,
              ),
            ],
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(
            color: DesignTokens.neonRed.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: _panicActive
              ? [
                  BoxShadow(
                    color: DesignTokens.neonRed.withValues(alpha: 0.3),
                    blurRadius: 20,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              _panicActive ? Icons.warning_rounded : Icons.sos,
              color: DesignTokens.neonRed,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              _panicActive
                  ? 'SOS ACTIVE — HELP IS COMING'
                  : 'HOLD FOR EMERGENCY SOS',
              style: const TextStyle(
                color: DesignTokens.neonRed,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _panicActive
                  ? 'Location broadcast active • Recording'
                  : 'Long-press 3 seconds to activate',
              style: TextStyle(
                color: DesignTokens.neonRed.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuardianActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _actionCard(
                Icons.check_circle_outline,
                'CHECK IN',
                'Send safe signal',
                const Color(0xFF00FF9D),
                () {
                  setState(() => _checkInCount++);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionCard(
                Icons.location_on,
                'SHARE LOCATION',
                'Broadcast live GPS',
                DesignTokens.neonCyan,
                () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _actionCard(
                Icons.mic,
                'AUTO-RECORD',
                'Evidence vault',
                DesignTokens.neonAmber,
                () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionCard(
                Icons.phone,
                'EMERGENCY CALL',
                'Direct 000/911',
                DesignTokens.neonRed,
                () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionCard(
    IconData icon,
    String title,
    String subtitle,
    Color accent,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: GlassDecoration.card(accent: accent),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContacts() {
    final contacts = [
      {
        'name': 'Emergency Services',
        'number': '000 / 911 / 999',
        'icon': Icons.local_hospital,
      },
      {
        'name': 'DFC Safety Line',
        'number': '1800-DFC-SAFE',
        'icon': Icons.shield,
      },
      {
        'name': 'Personal Contact #1',
        'number': 'Tap to set',
        'icon': Icons.person,
      },
      {
        'name': 'Personal Contact #2',
        'number': 'Tap to set',
        'icon': Icons.person_outline,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('EMERGENCY CONTACTS', DesignTokens.neonRed),
        ...contacts.map(
          (c) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: GlassDecoration.card(accent: DesignTokens.neonRed),
            child: Row(
              children: [
                Icon(
                  c['icon'] as IconData,
                  color: DesignTokens.neonRed,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c['name'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        c['number'] as String,
                        style: const TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: DesignTokens.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyChecklist() {
    final items = [
      {'text': 'Emergency contacts configured', 'done': false},
      {'text': 'Safety wearable paired', 'done': false},
      {'text': 'Guardian Mode tested', 'done': false},
      {'text': 'Auto-recording enabled', 'done': true},
      {'text': 'Location sharing allowed', 'done': true},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('SAFETY CHECKLIST', DesignTokens.neonAmber),
        ...items.map((item) {
          final done = item['done'] as bool;
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: GlassDecoration.card(
              accent: done ? const Color(0xFF00FF9D) : DesignTokens.neonAmber,
            ),
            child: Row(
              children: [
                Icon(
                  done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: done
                      ? const Color(0xFF00FF9D)
                      : DesignTokens.neonAmber,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  item['text'] as String,
                  style: TextStyle(
                    color: done ? DesignTokens.textSecondary : Colors.white,
                    fontSize: 12,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 3: ANALYTICS
  // ══════════════════════════════════════════════════════════════════

  Widget _buildAnalyticsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCards(),
        const SizedBox(height: 16),
        _sectionLabel('RESPONSE TIME TREND (ms)', DesignTokens.neonCyan),
        const SizedBox(height: 8),
        _buildResponseTimeChart(),
        const SizedBox(height: 16),
        _sectionLabel('WEEKLY ALERT VOLUME', const Color(0xFF00FF9D)),
        const SizedBox(height: 8),
        _buildAlertVolumeChart(),
        const SizedBox(height: 16),
        _sectionLabel('PROTOCOL COVERAGE STATS', DesignTokens.neonAmber),
        const SizedBox(height: 8),
        _buildCoverageTable(),
      ],
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(
          child: _statCard('AVG RESPONSE', '340ms', DesignTokens.neonCyan),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard('ALERTS TODAY', '0', const Color(0xFF00FF9D)),
        ),
        const SizedBox(width: 10),
        Expanded(child: _statCard('COVERAGE', '99.7%', DesignTokens.neonAmber)),
      ],
    );
  }

  Widget _statCard(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: GlassDecoration.card(accent: accent),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResponseTimeChart() {
    final spots = _responseTimesMs
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: GlassDecoration.card(),
      child: DFCAreaChart(
        height: 150,
        legend: const [
          DFCLegendItem(label: 'Response (ms)', color: DesignTokens.neonCyan),
        ],
        lines: [
          DFCGradientFill.lineWithGradient(
            spots: spots,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertVolumeChart() {
    final weeks = ['W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7', 'W8'];
    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: GlassDecoration.card(accent: const Color(0xFF00FF9D)),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Text(
                  weeks[v.toInt() % 8],
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (v, _) => Text(
                  '${v.round()}',
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            topTitles: const AxisTitles(
              
            ),
            rightTitles: const AxisTitles(
              
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _alertsPerWeek.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value,
                  width: 18,
                  color: const Color(0xFF00FF9D).withValues(alpha: 0.7),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
          maxY: 6,
        ),
      ),
    );
  }

  Widget _buildCoverageTable() {
    final data = [
      {
        'protocol': 'BLE 5.3',
        'indoor': '99.9%',
        'outdoor': '95%',
        'emergency': 'Paired device required',
      },
      {
        'protocol': 'LTE-M',
        'indoor': '98%',
        'outdoor': '99.5%',
        'emergency': 'Works standalone',
      },
      {
        'protocol': 'WiFi 6',
        'indoor': '99.9%',
        'outdoor': '30%',
        'emergency': 'Range limited',
      },
    ];

    return Container(
      decoration: GlassDecoration.card(accent: DesignTokens.neonAmber),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: DesignTokens.neonAmber.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(DesignTokens.radiusMedium),
                topRight: Radius.circular(DesignTokens.radiusMedium),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'PROTOCOL',
                    style: TextStyle(
                      color: DesignTokens.neonAmber,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'INDOOR',
                    style: TextStyle(
                      color: DesignTokens.neonGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'OUTDOOR',
                    style: TextStyle(
                      color: DesignTokens.neonCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'EMERGENCY',
                    style: TextStyle(
                      color: DesignTokens.neonRed,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...data.map(
            (row) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      row['protocol']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      row['indoor']!,
                      style: const TextStyle(
                        color: DesignTokens.neonGreen,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      row['outdoor']!,
                      style: const TextStyle(
                        color: DesignTokens.neonCyan,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      row['emergency']!,
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 4: EDUCATION
  // ══════════════════════════════════════════════════════════════════

  Widget _buildEducationTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildEducationSection(
          'HOW GUARDIAN MODE WORKS',
          const Color(0xFF00FF9D),
          Icons.shield,
          [
            _eduStep(
              '1',
              'Activate',
              'Press Guardian Mode before walking, jogging, or leaving an event.',
            ),
            _eduStep(
              '2',
              'Auto Check-In',
              'Every 5 minutes your device confirms you\'re safe via BLE heartbeat.',
            ),
            _eduStep(
              '3',
              'Missed Check-In',
              'If 2 consecutive check-ins are missed, your emergency contacts are alerted.',
            ),
            _eduStep(
              '4',
              'Escalation',
              'No response after 3 minutes triggers full panic: location broadcast, auto-recording, emergency call.',
            ),
            _eduStep(
              '5',
              'Evidence Vault',
              'All audio, video, and location data is encrypted and stored for police-ready evidence packages.',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildEducationSection(
          'WHY BLE 5.3 + LTE-M FOR SAFETY',
          DesignTokens.neonCyan,
          Icons.bluetooth_connected,
          [
            _eduStep(
              '→',
              'BLE 5.3',
              'Primary link to your phone. 3ms latency, 400m range, always connected. Transmits panic signals instantly.',
            ),
            _eduStep(
              '→',
              'LTE-M',
              'Cellular failover. Works when phone is dead, WiFi is down, or you\'re out of BLE range. Direct to tower.',
            ),
            _eduStep(
              '→',
              'Dual-path',
              'Both protocols fire simultaneously. If one fails, the other delivers. Zero single point of failure.',
            ),
            _eduStep(
              '✗',
              'NOT mesh',
              'Z-Wave/Zigbee mesh networks can take 500ms+ per hop and fail silently. Unacceptable for safety.',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildEducationSection(
          'WHAT HAPPENS DURING A PANIC ALERT',
          DesignTokens.neonRed,
          Icons.emergency,
          [
            _eduStep(
              '0s',
              'Signal Sent',
              'BLE 5.3 + LTE-M simultaneously transmit panic to DFC servers and emergency contacts.',
            ),
            _eduStep(
              '< 1s',
              'Location Locked',
              'GPS + UWB + cell tower triangulation pinpoints your position within 2 meters.',
            ),
            _eduStep(
              '< 2s',
              'Contacts Notified',
              'Push notification + SMS + automated call chain begins for all emergency contacts.',
            ),
            _eduStep(
              '< 5s',
              'Recording Active',
              'Audio recording starts automatically. Video if phone is accessible. All encrypted.',
            ),
            _eduStep(
              '< 30s',
              'Evidence Secured',
              'Data streams to DFC Evidence Vault — tamper-proof, police-ready, legally admissible.',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildAntiViolenceResources(),
      ],
    );
  }

  Widget _buildEducationSection(
    String title,
    Color accent,
    IconData icon,
    List<Widget> steps,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecoration.card(accent: accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...steps,
        ],
      ),
    );
  }

  Widget _eduStep(String marker, String title, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              marker,
              style: const TextStyle(
                color: DesignTokens.neonAmber,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
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

  Widget _buildAntiViolenceResources() {
    final resources = [
      {
        'name': '1800RESPECT (AU)',
        'number': '1800 737 732',
        'type': 'DV & Sexual Assault',
      },
      {
        'name': 'National DV Hotline (US)',
        'number': '1-800-799-7233',
        'type': 'Domestic Violence',
      },
      {'name': 'Refuge (UK)', 'number': '0808 2000 247', 'type': 'DV & Abuse'},
      {
        'name': 'Women\'s Refuge NZ',
        'number': '0800 733 843',
        'type': 'Crisis Support',
      },
      {
        'name': 'Crisis Text Line',
        'number': 'Text HOME to 741741',
        'type': 'Global Crisis',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF69B4).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: const Color(0xFFFF69B4).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite, color: Color(0xFFFF69B4), size: 18),
              SizedBox(width: 8),
              Text(
                'ANTI-VIOLENCE RESOURCES',
                style: TextStyle(
                  color: Color(0xFFFF69B4),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...resources.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r['name']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          r['type']!,
                          style: const TextStyle(
                            color: DesignTokens.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    r['number']!,
                    style: const TextStyle(
                      color: Color(0xFFFF69B4),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────

  Widget _sectionLabel(String text, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Color _protoColor(WearableProtocol p) {
    switch (p) {
      case WearableProtocol.ble53:
        return DesignTokens.neonCyan;
      case WearableProtocol.uwb:
        return DesignTokens.neonGreen;
      case WearableProtocol.wifi6:
        return DesignTokens.neonAmber;
      case WearableProtocol.lteM:
        return DesignTokens.neonRed;
      case WearableProtocol.nbIot:
        return const Color(0xFF888888);
      case WearableProtocol.ant:
        return DesignTokens.neonMagenta;
      case WearableProtocol.usb:
        return DesignTokens.neonBlue;
    }
  }
}
