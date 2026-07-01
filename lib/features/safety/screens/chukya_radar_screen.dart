import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/chukya_radar_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CHUKYA 3.0 RADAR SCREEN — Human Radar Detection System
/// ═══════════════════════════════════════════════════════════════════════════
///
/// First-of-its-kind human radar detection — born in Logan, QLD.
/// Detects police-registered threat profiles by phone proximity
/// (BLE/WiFi fingerprinting). Ankle monitor integration, AI risk
/// scoring, missing persons mesh network, court-admissible evidence.
///
/// Tabs:
///   1. RADAR     — live scan display, threat level, mode selector
///   2. WATCHLIST — registered threat profiles (police ref required)
///   3. SAFE ZONES — home, work, gym with radius
///   4. EVIDENCE  — alert history log (timestamped, GPS, admissible)
/// ═══════════════════════════════════════════════════════════════════════════
class ChukyaRadarScreen extends StatefulWidget {
  const ChukyaRadarScreen({super.key});

  @override
  State<ChukyaRadarScreen> createState() => _ChukyaRadarScreenState();
}

class _ChukyaRadarScreenState extends State<ChukyaRadarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ChukyaRadarService _radar = ChukyaRadarService();
  bool _scanActive = false;
  ChukyaScanMode _selectedMode = ChukyaScanMode.homeShield;
  final ThreatLevel _threatLevel = ThreatLevel.clear;

  // Demo data
  final List<_DemoThreatProfile> _demoWatchlist = [
    const _DemoThreatProfile(
      alias: 'Case #DV-2026-0441',
      policeRef: 'QLD-RO-2026-0441',
      distance: 200,
      validated: true,
      registeredDaysAgo: 45,
    ),
  ];

  final List<_DemoSafeZone> _demoSafeZones = [
    const _DemoSafeZone(
      name: 'Home',
      icon: Icons.home_rounded,
      radius: 200,
      active: true,
    ),
    const _DemoSafeZone(
      name: 'Work',
      icon: Icons.work_rounded,
      radius: 150,
      active: true,
    ),
    const _DemoSafeZone(
      name: 'Kids School',
      icon: Icons.school_rounded,
      radius: 300,
      active: true,
    ),
    const _DemoSafeZone(
      name: 'Pink Shield Gym',
      icon: Icons.fitness_center_rounded,
      radius: 100,
      active: false,
    ),
  ];

  final List<_DemoAlert> _demoAlerts = [
    const _DemoAlert(
      time: '2 days ago',
      mode: 'HOME SHIELD',
      threat: 'ELEVATED',
      distance: '~85m',
      confidence: 0.72,
      action: 'Logged — below threshold',
    ),
    const _DemoAlert(
      time: '5 days ago',
      mode: 'TRAVEL RADAR',
      threat: 'HIGH',
      distance: '~40m',
      confidence: 0.88,
      action: 'Police notified (auto)',
    ),
    const _DemoAlert(
      time: '12 days ago',
      mode: 'SAFE ZONE',
      threat: 'CRITICAL',
      distance: '~15m',
      confidence: 0.94,
      action: 'Police + contacts notified',
    ),
  ];

  int _scanCount = 0;

  // ── AI SHIELD state ───────────────────────────────────────────────────────
  // Approach vector simulation — in production this is fed by
  // the registered-device telemetry stream (ankle monitor / DFC app ping)
  bool _approachActive = false;
  int _approachSeconds = 612; // countdown in seconds (10m 12s)
  double _approachDistanceM = 847.0; // metres
  final double _approachSpeedMph = 28.4; // km/h approach rate
  double _aiRiskScore = 0.0; // 0–100
  Timer? _approachTimer;

  // Sparkline history (last 20 scan scores)
  final List<double> _signalHistory = [
    12,
    15,
    11,
    28,
    32,
    44,
    38,
    55,
    61,
    58,
    70,
    74,
    68,
    79,
    82,
    77,
    85,
    89,
    91,
    94,
  ];

  // BLE probe hit chart (last 10 scans, count of hits)
  final List<int> _bleHits = [0, 1, 0, 2, 0, 3, 1, 4, 5, 6];

  // Registered devices under supervision
  final List<_RegisteredDevice> _supervisedDevices = [
    const _RegisteredDevice(
      label: 'Ankle Monitor — Case QLD-2026-0441',
      type: DeviceType.ankleMonitor,
      status: DeviceStatus.online,
      lastPingAgo: '14s ago',
      distanceM: 847,
      policeRef: 'QLD-RO-2026-0441',
    ),
    const _RegisteredDevice(
      label: 'Mobile Phone — IMEI on Registry',
      type: DeviceType.phone,
      status: DeviceStatus.online,
      lastPingAgo: '22s ago',
      distanceM: 851,
      policeRef: 'QLD-RO-2026-0441',
    ),
  ];

  // Missing persons DFC network pings
  final List<_MissingPing> _missingPings = [
    const _MissingPing(
      name: 'Child — Ref MP-2026-0089',
      lastSeen: '6h 14m ago',
      lastLocation: 'Forest Lake, QLD',
      networkHits: 3,
      active: true,
    ),
    const _MissingPing(
      name: 'Adult — Ref MP-2026-0102',
      lastSeen: '1 day 3h ago',
      lastLocation: 'Ipswich, QLD',
      networkHits: 1,
      active: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _approachTimer?.cancel();
    _tabController.dispose();
    _radar.stopScanning();
    super.dispose();
  }

  void _startApproachSimulation() {
    _approachTimer?.cancel();
    setState(() {
      _approachActive = true;
      _approachSeconds = 612;
      _approachDistanceM = 847.0;
      _aiRiskScore = 94.0;
    });
    _approachTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_approachSeconds > 0) {
          _approachSeconds--;
          _approachDistanceM = (_approachDistanceM - 1.38).clamp(0, 2000);
        } else {
          // Threat arrived — max alert
          _approachActive = false;
          t.cancel();
        }
      });
    });
  }

  void _stopApproachSimulation() {
    _approachTimer?.cancel();
    setState(() {
      _approachActive = false;
      _approachSeconds = 612;
      _approachDistanceM = 847.0;
      _aiRiskScore = 0.0;
    });
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
                _buildRadarTab(),
                _buildWatchlistTab(),
                _buildSafeZonesTab(),
                _buildEvidenceTab(),
                _buildAiShieldTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────

  Widget _buildHeader() {
    const pink = Color(0xFFFF69B4);
    const emerald = Color(0xFF00FF9D);
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
            pink.withValues(alpha: 0.08),
            emerald.withValues(alpha: 0.04),
            DesignTokens.bgPrimary,
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [pink, Color(0xFFFF1493)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'PINK SHIELD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHUKYA 3.0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Human Radar Detection \u2022 First of Its Kind \u2022 Logan, QLD',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              _buildThreatBadge(),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: emerald.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: emerald.withValues(alpha: 0.15)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_rounded, color: emerald, size: 14),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'We always have your back. Safety is our main concern.',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
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

  Widget _buildThreatBadge() {
    final colors = {
      ThreatLevel.clear: const Color(0xFF00FF9D),
      ThreatLevel.low: const Color(0xFF00FF9D),
      ThreatLevel.elevated: DesignTokens.neonAmber,
      ThreatLevel.high: const Color(0xFFFF6B35),
      ThreatLevel.critical: DesignTokens.neonRed,
    };
    final color = colors[_threatLevel] ?? const Color(0xFF00FF9D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            _threatLevel.label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    const pink = Color(0xFFFF69B4);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: pink.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: pink.withValues(alpha: 0.3)),
        ),
        labelColor: pink,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        dividerHeight: 0,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(text: 'RADAR'),
          Tab(text: 'WATCHLIST'),
          Tab(text: 'SAFE ZONES'),
          Tab(text: 'EVIDENCE'),
          Tab(text: 'AI SHIELD'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 1: RADAR — Live Scan Display
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildRadarTab() {
    const pink = Color(0xFFFF69B4);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Radar visual
          _buildRadarVisual(),
          const SizedBox(height: 16),

          // Mode selector
          _buildModeSelector(),
          const SizedBox(height: 16),

          // Scan control
          _buildScanControl(),
          const SizedBox(height: 16),

          // Stats row
          _buildStatsRow(),
          const SizedBox(height: 16),

          // How it works
          _buildInfoCard(
            'How Chukya 3.0 Works',
            'Your phone passively scans nearby Bluetooth and WiFi signals. '
                'When a signal matches a police-registered threat profile, you get a silent alert '
                'and police are automatically notified with your GPS location and the restraining '
                'order case number. No extra hardware needed — your phone is the scanner.',
            pink,
            Icons.info_outline_rounded,
          ),
          const SizedBox(height: 12),

          // Protocol info
          _buildProtocolCard(),
        ],
      ),
    );
  }

  Widget _buildRadarVisual() {
    const pink = Color(0xFFFF69B4);
    const emerald = Color(0xFF00FF9D);
    final scanColor = _scanActive ? emerald : Colors.white24;

    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scanColor.withValues(alpha: 0.2)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Concentric rings
          for (int i = 3; i >= 1; i--)
            Container(
              width: 60.0 + (i * 60.0),
              height: 60.0 + (i * 60.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: scanColor.withValues(alpha: 0.08 + (i * 0.04)),
                ),
              ),
            ),

          // Range labels
          Positioned(
            right: 16,
            top: 60,
            child: Text(
              '200m',
              style: TextStyle(
                color: scanColor.withValues(alpha: 0.4),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            right: 50,
            top: 95,
            child: Text(
              '100m',
              style: TextStyle(
                color: scanColor.withValues(alpha: 0.4),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            right: 85,
            top: 125,
            child: Text(
              '30m',
              style: TextStyle(
                color: scanColor.withValues(alpha: 0.4),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Center — "YOU"
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pink.withValues(alpha: 0.15),
              border: Border.all(color: pink.withValues(alpha: 0.5), width: 2),
            ),
            child: const Center(
              child: Text(
                'YOU',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          // Scan status overlay
          Positioned(
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: (_scanActive ? emerald : Colors.white24).withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (_scanActive ? emerald : Colors.white24).withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_scanActive) ...[
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: emerald,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    _scanActive
                        ? 'SCANNING — ${_selectedMode.label}'
                        : 'SCANNER IDLE',
                    style: TextStyle(
                      color: _scanActive ? emerald : Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scan count
          Positioned(
            top: 12,
            left: 12,
            child: Text(
              'Scans: $_scanCount',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Mode
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_selectedMode.icon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  _selectedMode.label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    const pink = Color(0xFFFF69B4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SCAN MODE',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ChukyaScanMode.values.map((mode) {
            final selected = mode == _selectedMode;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMode = mode;
                    if (_scanActive) {
                      _radar.switchMode(mode);
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? pink.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? pink.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(mode.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(
                        mode.label.split(' ').first,
                        style: TextStyle(
                          color: selected ? pink : Colors.white38,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScanControl() {
    const pink = Color(0xFFFF69B4);
    return GestureDetector(
      onTap: () {
        setState(() {
          _scanActive = !_scanActive;
          if (_scanActive) {
            _radar.startScanning(_selectedMode);
            _scanCount++;
          } else {
            _radar.stopScanning();
          }
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _scanActive
                ? [DesignTokens.neonRed, const Color(0xFFFF1744)]
                : [pink, const Color(0xFFFF1493)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (_scanActive ? DesignTokens.neonRed : pink).withValues(
                alpha: 0.3,
              ),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _scanActive ? Icons.stop_circle_rounded : Icons.radar_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              _scanActive ? 'STOP SCANNER' : 'ACTIVATE CHUKYA RADAR',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    const emerald = Color(0xFF00FF9D);
    final stats = [
      _StatItem('Scans Today', '$_scanCount', emerald),
      _StatItem(
        'Watchlist',
        '${_demoWatchlist.length}',
        const Color(0xFFFF69B4),
      ),
      _StatItem(
        'Safe Zones',
        '${_demoSafeZones.where((z) => z.active).length}',
        DesignTokens.neonCyan,
      ),
      _StatItem('Alerts', '${_demoAlerts.length}', DesignTokens.neonAmber),
    ];
    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: s.color.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Text(
                  s.value,
                  style: TextStyle(
                    color: s.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.label,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProtocolCard() {
    const protocols = [
      ('BLE 5.3', '2ms', 'Primary scan — detects phones, earbuds, watches'),
      ('WiFi Probe', '5ms', 'Detects WiFi-enabled devices nearby'),
      ('LTE-M', '15ms', 'Emergency failover when no Bluetooth'),
      ('UWB', '1ms', 'Precision distance (supported devices)'),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DETECTION PROTOCOLS',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          ...protocols.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 55,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.$1,
                      style: const TextStyle(
                        color: DesignTokens.neonCyan,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    p.$2,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.$3,
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 9,
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

  // ══════════════════════════════════════════════════════════════════════
  // TAB 2: WATCHLIST — Registered Threat Profiles
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildWatchlistTab() {
    const pink = Color(0xFFFF69B4);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Police Reference Required',
            'Only individuals with a valid restraining order can be added. '
                'You need the police case reference number. DFC verifies each profile '
                'before scanning activates. This prevents misuse and ensures legal compliance.',
            const Color(0xFFFF69B4),
            Icons.gavel_rounded,
          ),
          const SizedBox(height: 16),

          // Watchlist entries
          ..._demoWatchlist.map(_buildThreatCard),
          const SizedBox(height: 16),

          // Add button
          GestureDetector(
            onTap: () {
              // In production: opens registration flow with police ref input
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Registration requires police reference number',
                  ),
                  backgroundColor: Color(0xFF1A1A2E),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: pink.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: pink.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, color: pink, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'REGISTER THREAT PROFILE',
                    style: TextStyle(
                      color: pink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // How it matches
          _buildInfoCard(
            'How Matching Works',
            'When you register a threat, DFC creates a hashed device fingerprint '
                'from the phone number characteristics. Your phone then passively scans '
                'for BLE/WiFi signals matching that fingerprint. No raw phone numbers '
                'are ever stored — only encrypted, one-way hashes.',
            DesignTokens.neonCyan,
            Icons.fingerprint_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildThreatCard(_DemoThreatProfile t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.neonRed.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DesignTokens.neonRed.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DesignTokens.neonRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_off_rounded,
                  color: Color(0xFFFF3366),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.alias,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Police Ref: ${t.policeRef}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: t.validated
                      ? const Color(0xFF00FF9D).withValues(alpha: 0.1)
                      : DesignTokens.neonAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  t.validated ? 'VALIDATED' : 'PENDING',
                  style: TextStyle(
                    color: t.validated
                        ? const Color(0xFF00FF9D)
                        : DesignTokens.neonAmber,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildSmallStat(
                'Distance',
                '${t.distance}m',
                DesignTokens.neonRed,
              ),
              const SizedBox(width: 8),
              _buildSmallStat(
                'Registered',
                '${t.registeredDaysAgo}d ago',
                Colors.white38,
              ),
              const SizedBox(width: 8),
              _buildSmallStat(
                'Scanning',
                t.validated ? 'ACTIVE' : 'PAUSED',
                t.validated ? const Color(0xFF00FF9D) : DesignTokens.neonAmber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 3: SAFE ZONES — Home, Work, Gym
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildSafeZonesTab() {
    const emerald = Color(0xFF00FF9D);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Safe Zone Protection',
            'Register the places that matter — home, work, school, gym. '
                'Chukya automatically activates Safe Zone scanning when you enter '
                'these areas. If a threat is detected near any safe zone, police '
                'are notified immediately with the exact location.',
            emerald,
            Icons.location_on_rounded,
          ),
          const SizedBox(height: 16),

          ..._demoSafeZones.map(_buildSafeZoneCard),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Safe zone registration uses your current GPS'),
                  backgroundColor: Color(0xFF1A1A2E),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: emerald.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: emerald.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_location_alt_rounded,
                    color: emerald,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ADD SAFE ZONE',
                    style: TextStyle(
                      color: emerald,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
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

  Widget _buildSafeZoneCard(_DemoSafeZone z) {
    const emerald = Color(0xFF00FF9D);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (z.active ? emerald : Colors.white24).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (z.active ? emerald : Colors.white24).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (z.active ? emerald : Colors.white24).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              z.icon,
              color: z.active ? emerald : Colors.white38,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  z.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Radius: ${z.radius}m',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (z.active ? emerald : Colors.white24).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              z.active ? 'ACTIVE' : 'PAUSED',
              style: TextStyle(
                color: z.active ? emerald : Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 5: AI SHIELD — Mission Control / NASA Approach Warning System
  // ══════════════════════════════════════════════════════════════════════
  //
  // Concept: Like an aircraft threat warning system. Registered devices
  // (ankle monitors, phones on DFC registry, GPS tags) broadcast periodic
  // pings. AI fuses signal distance + speed + trajectory to compute an
  // intercept time and a risk score (0-100). When the abuser's registered
  // device is APPROACHING your location, the countdown starts.
  //
  // Technical stack (production):
  //   • BLE 5.3 + WiFi probe → raw signal distance (RSSI triangulation)
  //   • Ankle monitor / GPS tag → police backend → DFC relay feed
  //   • AI intercept engine → distance ÷ approach_speed = seconds_to_contact
  //   • Chukya Radar Service → Firestore alert + FCM push
  //
  // Privacy law compliance:
  //   • BLE/WiFi scanning = passive RF detection, no tracking of strangers
  //   • Registered devices = court-mandated GPS transmitters (police controlled)
  //   • Missing persons = family-consented pings via DFC guardian network
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildAiShieldTab() {
    const red = Color(0xFFFF1744);
    const amber = Color(0xFFFFD600);
    const emerald = Color(0xFF00FF9D);
    const cyan = Color(0xFF00E5FF);
    const pink = Color(0xFFFF69B4);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── APPROACH VECTOR WARNING BANNER ──────────────────────────
          _buildApproachWarningBanner(red, amber, emerald),
          const SizedBox(height: 12),

          // ── TOP ROW: AI Risk Gauge + Intercept Countdown ─────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildRiskGauge(red, amber, emerald)),
              const SizedBox(width: 10),
              Expanded(child: _buildInterceptClock(red, amber, emerald)),
            ],
          ),
          const SizedBox(height: 12),

          // ── SIGNAL INTELLIGENCE: Threat score over time ─────────────
          _buildSectionLabel('SIGNAL INTELLIGENCE', cyan, Icons.show_chart),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSparklineCard(
                  'THREAT SCORE HISTORY',
                  _signalHistory.map((v) => v / 100).toList(),
                  cyan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBleHitBarCard('BLE PROBE HITS', _bleHits, pink),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── REGISTERED DEVICE MONITOR ────────────────────────────────
          _buildSectionLabel('REGISTERED DEVICE MONITOR', amber, Icons.sensors),
          _buildRegisteredDevicesPanel(amber, red, emerald),
          const SizedBox(height: 12),

          // ── MISSING PERSONS PING NET ─────────────────────────────────
          _buildSectionLabel(
            'MISSING PERSONS NETWORK PING',
            pink,
            Icons.person_search,
          ),
          _buildMissingPersonsPanel(pink, cyan),
          const SizedBox(height: 12),

          // ── HOW IT WORKS ─────────────────────────────────────────────
          _buildShieldInfoCard(cyan),
        ],
      ),
    );
  }

  // ── Approach Warning Banner ─────────────────────────────────────────────────

  Widget _buildApproachWarningBanner(Color red, Color amber, Color emerald) {
    final isActive = _approachActive;
    final color = isActive ? red : emerald;
    final mins = _approachSeconds ~/ 60;
    final secs = _approachSeconds % 60;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isActive ? 0.7 : 0.25),
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: red.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isActive
                    ? Icons.warning_amber_rounded
                    : Icons.verified_user_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isActive
                      ? '⚠  THREAT VECTOR DETECTED — APPROACH IN PROGRESS'
                      : '✓  ALL CLEAR — NO APPROACH DETECTED',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _buildWarningMetric(
                  'ETA',
                  '${mins}m ${secs.toString().padLeft(2, '0')}s',
                  red,
                ),
                const SizedBox(width: 8),
                _buildWarningMetric(
                  'DISTANCE',
                  '${_approachDistanceM.toStringAsFixed(0)}m',
                  amber,
                ),
                const SizedBox(width: 8),
                _buildWarningMetric(
                  'SPEED',
                  '${_approachSpeedMph.toStringAsFixed(1)} km/h',
                  amber,
                ),
                const SizedBox(width: 8),
                _buildWarningMetric('CONFIDENCE', '94%', red),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isActive
                      ? _stopApproachSimulation
                      : _startApproachSimulation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isActive
                            ? [emerald, const Color(0xFF00C853)]
                            : [red, const Color(0xFFC62828)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        isActive
                            ? '✓  STAND DOWN — THREAT CLEARED'
                            : '⚡  SIMULATE APPROACH — DEMO MODE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isActive
                ? 'Police auto-notified at 500m threshold. Evidence recording active.'
                : 'Monitoring ${_supervisedDevices.length} registered device(s). '
                      'Police alert triggers at 500m proximity.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningMetric(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 8,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AI Risk Gauge ────────────────────────────────────────────────────────────

  Widget _buildRiskGauge(Color red, Color amber, Color emerald) {
    const cyan = Color(0xFF00E5FF);
    final score = _aiRiskScore;
    final color = score >= 80
        ? red
        : score >= 50
        ? amber
        : emerald;
    final label = score >= 80
        ? 'CRITICAL'
        : score >= 50
        ? 'ELEVATED'
        : 'CLEAR';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.psychology_alt_rounded,
                color: Color(0xFF00E5FF),
                size: 14,
              ),
              SizedBox(width: 6),
              Text(
                'AI RISK ENGINE',
                style: TextStyle(
                  color: cyan,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.07),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score.toStringAsFixed(0),
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildMiniMetricRow('Pattern', 'Repeated approach ×3'),
          _buildMiniMetricRow('Source', '2 registered devices'),
          _buildMiniMetricRow('Last update', '14s ago'),
        ],
      ),
    );
  }

  Widget _buildMiniMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label  ',
            style: const TextStyle(color: Colors.white38, fontSize: 9),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Intercept Clock ──────────────────────────────────────────────────────────

  Widget _buildInterceptClock(Color red, Color amber, Color emerald) {
    final isActive = _approachActive;
    final color = isActive ? red : emerald;
    final mins = _approachSeconds ~/ 60;
    final secs = _approachSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                'INTERCEPT CLOCK',
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: Column(
              children: [
                Text(
                  isActive
                      ? '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}'
                      : '--:--',
                  style: TextStyle(
                    color: color,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: 4,
                  ),
                ),
                Text(
                  isActive ? 'MINUTES TO CONTACT' : 'SYSTEM STANDBY',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.6),
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Approach bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: isActive ? 1 - (_approachSeconds / 612) : 0,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isActive
                ? '${_approachDistanceM.toStringAsFixed(0)}m remaining — police notified at 500m'
                : 'No registered device approaching',
            style: const TextStyle(color: Colors.white38, fontSize: 9),
          ),
        ],
      ),
    );
  }

  // ── Sparkline ────────────────────────────────────────────────────────────────

  Widget _buildSparklineCard(String title, List<double> data, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: CustomPaint(
              painter: _SparklinePainter(data, color),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Last ${data.length} scans',
            style: const TextStyle(color: Colors.white24, fontSize: 7),
          ),
        ],
      ),
    );
  }

  Widget _buildBleHitBarCard(String title, List<int> data, Color color) {
    final maxVal = data.reduce(math.max).toDouble();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((v) {
                final h = maxVal > 0 ? (v / maxVal) : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: FractionallySizedBox(
                      alignment: Alignment.bottomCenter,
                      heightFactor: h.clamp(0.04, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: v > 3 ? 0.9 : 0.45),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hits per scan window',
            style: TextStyle(color: Colors.white24, fontSize: 7),
          ),
        ],
      ),
    );
  }

  // ── Section Label ────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Registered Devices Panel ─────────────────────────────────────────────────

  Widget _buildRegisteredDevicesPanel(Color amber, Color red, Color emerald) {
    return Column(
      children: [
        ..._supervisedDevices.map((d) {
          final online = d.status == DeviceStatus.online;
          final statusColor = online ? emerald : red;
          final icon = switch (d.type) {
            DeviceType.ankleMonitor => Icons.monitor_heart_rounded,
            DeviceType.phone => Icons.smartphone_rounded,
            DeviceType.gpsTag => Icons.gps_fixed_rounded,
            DeviceType.airTag => Icons.location_on_rounded,
          };
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withValues(alpha: 0.12),
                  ),
                  child: Icon(icon, color: statusColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Police ref: ${d.policeRef}  •  Ping: ${d.lastPingAgo}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        online ? 'ONLINE' : 'OFFLINE',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${d.distanceM}m away',
                      style: TextStyle(
                        color: amber,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        // Add device button
        GestureDetector(
          onTap: _showAddDeviceDialog,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.white38, size: 14),
                SizedBox(width: 6),
                Text(
                  'Register court-mandated device (police ref required)',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddDeviceDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF12121A),
        title: const Text(
          'Register Device',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'To register a device (ankle monitor, phone IMEI, or GPS tag), '
          'a valid police reference number is required.\n\n'
          'Contact your Pink Shield case manager or police liaison officer '
          'to activate device monitoring.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFFFF69B4))),
          ),
        ],
      ),
    );
  }

  // ── Missing Persons Panel ─────────────────────────────────────────────────────

  Widget _buildMissingPersonsPanel(Color pink, Color cyan) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cyan.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cyan.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.hub_rounded, color: cyan, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DFC Guardian Network: ${_missingPings.length} active pings. '
                  'Every DFC app user within 200m of a missing person\'s '
                  'last-known BLE/WiFi signature sends an anonymous detection ping.',
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        ..._missingPings.map(
          (p) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: pink.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: pink.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pink.withValues(alpha: 0.15),
                  ),
                  child: const Icon(
                    Icons.person_search_rounded,
                    color: Color(0xFFFF69B4),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Last seen: ${p.lastSeen}  •  ${p.lastLocation}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                        ),
                      ),
                      Text(
                        'Network hits: ${p.networkHits} detection(s)',
                        style: TextStyle(
                          color: cyan,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: pink.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: pink,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Info Card ─────────────────────────────────────────────────────────────────

  Widget _buildShieldInfoCard(Color cyan) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cyan.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cyan.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_rounded, color: cyan, size: 14),
              const SizedBox(width: 6),
              Text(
                'HOW THE TECHNOLOGY WORKS',
                style: TextStyle(
                  color: cyan,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...[
            (
              'BLE + WiFi passive scan',
              'Your phone detects all nearby Bluetooth/WiFi signals every 30–60s. No tracking of random people — only checks against your registered watchlist.',
            ),
            (
              'Ankle monitor / GPS tag integration',
              'Court-mandated devices broadcast GPS via police relay. DFC receives a distance feed — not raw location — preserving privacy while giving you an intercept countdown.',
            ),
            (
              'AI approach engine',
              'Distance ÷ approach speed = intercept ETA. Repeated approach patterns score higher. 3 false positives are within 48h correction window before recalibration.',
            ),
            (
              'Missing persons ping',
              'With family consent, we broadcast the last known BLE signal fingerprint of a missing person across the DFC network. Any DFC user who comes within range sends an anonymous hit — building a location trail without exposing any individual user\'s identity.',
            ),
            (
              'What this is NOT',
              'This is not GPS surveillance of an offender. It is passive DETECTION that you are nearby a registered device. The difference is legally significant and by design.',
            ),
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.fromLTRB(0, 5, 8, 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cyan,
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${item.$1}  ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: item.$2,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ],
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

  // ══════════════════════════════════════════════════════════════════════
  // TAB 4: EVIDENCE — Alert History Log
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildEvidenceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Evidence Vault',
            'Every proximity detection is timestamped, GPS-stamped, and stored '
                'securely. This log is designed to be admissible — it proves the '
                'offender violated the restraining order distance. Share with police '
                'or your lawyer directly from this screen.',
            DesignTokens.neonAmber,
            Icons.folder_special_rounded,
          ),
          const SizedBox(height: 16),

          // Alert history
          ..._demoAlerts.asMap().entries.map(
            (e) => _buildAlertCard(e.value, e.key),
          ),

          const SizedBox(height: 16),

          // Export button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: DesignTokens.neonCyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DesignTokens.neonCyan.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.file_download_outlined,
                  color: DesignTokens.neonCyan,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'EXPORT EVIDENCE REPORT',
                  style: TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(_DemoAlert a, int index) {
    final colors = {
      'ELEVATED': DesignTokens.neonAmber,
      'HIGH': const Color(0xFFFF6B35),
      'CRITICAL': DesignTokens.neonRed,
    };
    final color = colors[a.threat] ?? Colors.white38;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  a.threat,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                a.mode,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                a.time,
                style: const TextStyle(color: Colors.white24, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSmallStat('Distance', a.distance, color),
              const SizedBox(width: 8),
              _buildSmallStat(
                'Confidence',
                '${(a.confidence * 100).toInt()}%',
                a.confidence >= 0.8
                    ? DesignTokens.neonRed
                    : DesignTokens.neonAmber,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  a.action,
                  style: const TextStyle(color: Colors.white30, fontSize: 9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Shared Widgets ─────────────────────────────────────────────────

  Widget _buildInfoCard(
    String title,
    String body,
    Color accent,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 7,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Demo data models (screen-local) ──────────────────────────────────────

class _DemoThreatProfile {
  final String alias;
  final String policeRef;
  final int distance;
  final bool validated;
  final int registeredDaysAgo;
  const _DemoThreatProfile({
    required this.alias,
    required this.policeRef,
    required this.distance,
    required this.validated,
    required this.registeredDaysAgo,
  });
}

class _DemoSafeZone {
  final String name;
  final IconData icon;
  final int radius;
  final bool active;
  const _DemoSafeZone({
    required this.name,
    required this.icon,
    required this.radius,
    required this.active,
  });
}

class _DemoAlert {
  final String time;
  final String mode;
  final String threat;
  final String distance;
  final double confidence;
  final String action;
  const _DemoAlert({
    required this.time,
    required this.mode,
    required this.threat,
    required this.distance,
    required this.confidence,
    required this.action,
  });
}

class _StatItem {
  final String label;
  final String value;
  final Color color;
  const _StatItem(this.label, this.value, this.color);
}

// ── AI SHIELD data models ─────────────────────────────────────────────────────

enum DeviceType { ankleMonitor, phone, gpsTag, airTag }

enum DeviceStatus { online, offline, breach }

class _RegisteredDevice {
  final String label;
  final DeviceType type;
  final DeviceStatus status;
  final String lastPingAgo;
  final int distanceM;
  final String policeRef;
  const _RegisteredDevice({
    required this.label,
    required this.type,
    required this.status,
    required this.lastPingAgo,
    required this.distanceM,
    required this.policeRef,
  });
}

class _MissingPing {
  final String name;
  final String lastSeen;
  final String lastLocation;
  final int networkHits;
  final bool active;
  const _MissingPing({
    required this.name,
    required this.lastSeen,
    required this.lastLocation,
    required this.networkHits,
    required this.active,
  });
}

// ── Custom painter: sparkline ─────────────────────────────────────────────────

class _SparklinePainter extends CustomPainter {
  final List<double> data; // 0.0 – 1.0 normalised
  final Color color;
  const _SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final step = size.width / (data.length - 1);
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final y = size.height - (data[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo((data.length - 1) * step, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // last point dot
    final lastX = (data.length - 1) * step;
    final lastY = size.height - (data.last * size.height);
    canvas.drawCircle(Offset(lastX, lastY), 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.data != data;
}
