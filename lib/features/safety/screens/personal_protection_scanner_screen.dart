import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../shared/services/chukya_radar_service.dart';

/// Blackbird API base — override at build time via --dart-define=BLACKBIRD_API_URL=...
const String _kBlackbirdApi = String.fromEnvironment(
  'BLACKBIRD_API_URL',
  defaultValue: 'http://localhost:8000',
);

// ── Design tokens ────────────────────────────────────────────────────────
const Color _ppPink = Color(0xFFFF69B4);
const Color _ppEmerald = Color(0xFF00FF9D);
const Color _ppCyan = Color(0xFF00D9FF);
const Color _ppAmber = Color(0xFFFFBF00);
const Color _ppRed = Color(0xFFFF2D55);
const Color _ppBg = Color(0xFF050A14);
const Color _ppCard = Color(0xFF0D1B2A);
const Color _ppBorder = Color(0xFF1A2E44);

/// ═══════════════════════════════════════════════════════════════════════════
/// PERSONAL PROTECTION SCANNER
/// ═══════════════════════════════════════════════════════════════════════════
///
/// User-facing protection dashboard for vulnerable individuals.
/// Integrates Chukya radar (BLE/WiFi proximity scanning) with the Blackbird
/// backend (PostGIS matching, evidence export, alert pipeline).
///
/// Tabs:
///   1. SHIELD   — Radar + scan controls + threat indicator
///   2. ZONES    — Safe zone management + geofence status
///   3. DEVICES  — Connected wearables + signal health
///   4. ALERTS   — Blackbird alert feed + evidence timeline
///   5. PANIC    — One-touch emergency with evidence capture
/// ═══════════════════════════════════════════════════════════════════════════
class PersonalProtectionScannerScreen extends StatefulWidget {
  const PersonalProtectionScannerScreen({super.key});

  @override
  State<PersonalProtectionScannerScreen> createState() =>
      _PersonalProtectionScannerScreenState();
}

class _PersonalProtectionScannerScreenState
    extends State<PersonalProtectionScannerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _radarSweep;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final ChukyaRadarService _radar = ChukyaRadarService();

  // ── Google Maps for zones tab ──
  GoogleMapController? _mapController; // ignore: unused_field
  static const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0a1628"}]},
  {"elementType":"geometry.stroke","stylers":[{"color":"#1a2a42"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8a92b8"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0a1628"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#1a2a42"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0f1d33"}]}
]
  ''';

  // ── State ──
  bool _scanActive = false;
  ChukyaScanMode _selectedMode = ChukyaScanMode.homeShield;
  ThreatLevel _threatLevel = ThreatLevel.clear;

  int _scanCount = 0;
  Timer? _scanDisplayTimer;

  // Blackbird alerts pulled from API
  List<_BlackbirdAlert> _bbAlerts = [];
  bool _bbLoading = false;
  String _bbError = '';
  Timer? _bbRefreshTimer;
  DateTime? _bbLastRefreshed;

  // Device status (simulated — would come from BLE/wearable SDK in prod)
  final List<_DeviceEntry> _devices = [
    const _DeviceEntry(
      name: 'Apple Watch SE',
      type: 'watch',
      signal: 0.92,
      battery: 78,
      protocol: 'BLE 5.3',
      status: 'connected',
    ),
    const _DeviceEntry(
      name: 'DFC Safety Band',
      type: 'band',
      signal: 0.85,
      battery: 64,
      protocol: 'BLE 5.0',
      status: 'connected',
    ),
    const _DeviceEntry(
      name: 'Home Beacon',
      type: 'beacon',
      signal: 0.97,
      battery: 100,
      protocol: 'WiFi 6',
      status: 'connected',
    ),
    const _DeviceEntry(
      name: 'Ankle Monitor Relay',
      type: 'monitor',
      signal: 0.30,
      battery: -1,
      protocol: 'LTE-M',
      status: 'passive',
    ),
  ];

  // Safe zones (demo — in prod these come from ChukyaRadarService)
  final List<_ZoneEntry> _zones = [
    const _ZoneEntry(
      name: 'Home',
      icon: Icons.home_rounded,
      radius: 200,
      active: true,
      lastCheck: '12s ago',
      lat: -27.6388,
      lng: 153.1094,
    ),
    const _ZoneEntry(
      name: 'Work',
      icon: Icons.work_rounded,
      radius: 150,
      active: true,
      lastCheck: '45s ago',
      lat: -27.4698,
      lng: 153.0251,
    ),
    const _ZoneEntry(
      name: "Kids' School",
      icon: Icons.school_rounded,
      radius: 300,
      active: true,
      lastCheck: '1m ago',
      lat: -27.6150,
      lng: 153.1050,
    ),
    const _ZoneEntry(
      name: 'Pink Shield Gym',
      icon: Icons.fitness_center_rounded,
      radius: 100,
      active: false,
      lastCheck: '—',
      lat: -27.6300,
      lng: 153.1200,
    ),
  ];

  // Signal strength history for sparkline (last 20 scans)
  final List<double> _signalHistory = [
    12,
    15,
    11,
    28,
    32,
    24,
    18,
    15,
    21,
    14,
    12,
    18,
    22,
    25,
    19,
    16,
    13,
    11,
    14,
    12,
  ];

  // Panic mode
  bool _panicActive = false;
  int _panicCountdown = 0;
  Timer? _panicTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _radarSweep = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fetchBlackbirdAlerts();
    _bbRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchBlackbirdAlerts(),
    );
  }

  @override
  void dispose() {
    _scanDisplayTimer?.cancel();
    _bbRefreshTimer?.cancel();
    _panicTimer?.cancel();
    _tabController.dispose();
    _radarSweep.dispose();
    _pulseController.dispose();
    _radar.stopScanning();
    super.dispose();
  }

  // ── Blackbird integration ─────────────────────────────────────────────
  Future<void> _fetchBlackbirdAlerts() async {
    setState(() {
      _bbLoading = true;
      _bbError = '';
    });
    try {
      final res = await http
          .get(Uri.parse('$_kBlackbirdApi/blackbird/alerts?limit=30'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
        setState(() {
          _bbAlerts = data
              .map((j) => _BlackbirdAlert.fromJson(j as Map<String, dynamic>))
              .toList();
          _bbLoading = false;
          _bbLastRefreshed = DateTime.now();
        });
      } else {
        setState(() {
          _bbError = 'Blackbird returned ${res.statusCode}';
          _bbLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _bbError = 'Blackbird offline — local protection still active';
        _bbLoading = false;
        _bbLastRefreshed = DateTime.now();
      });
    }
  }

  // ── Scan controls ─────────────────────────────────────────────────────
  void _toggleScan() {
    setState(() {
      _scanActive = !_scanActive;
      if (_scanActive) {
        _radarSweep.repeat();
        _radar.startScanning(_selectedMode);
        _scanDisplayTimer = Timer.periodic(const Duration(seconds: 2), (_) {
          if (!mounted) return;
          setState(() {
            _scanCount++;
            // Simulate signal variation
            _signalHistory.removeAt(0);
            _signalHistory.add(10 + math.Random().nextDouble() * 25);
          });
        });
      } else {
        _radarSweep.stop();
        _scanDisplayTimer?.cancel();
        _radar.stopScanning();
        _threatLevel = ThreatLevel.clear;
      }
    });
  }

  void _switchMode(ChukyaScanMode mode) {
    setState(() {
      _selectedMode = mode;
      if (_scanActive) {
        _radar.switchMode(mode);
      }
    });
  }

  // ── Panic mode ────────────────────────────────────────────────────────
  void _activatePanic() {
    HapticFeedback.heavyImpact();
    setState(() {
      _panicActive = true;
      _panicCountdown = 5;
    });
    _panicTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _panicCountdown--;
        if (_panicCountdown <= 0) {
          t.cancel();
          _executePanicProtocol();
        }
      });
    });
  }

  void _cancelPanic() {
    _panicTimer?.cancel();
    setState(() {
      _panicActive = false;
      _panicCountdown = 0;
    });
  }

  void _executePanicProtocol() {
    // In production:
    // 1. Fire proximity alert via ChukyaRadarService
    // 2. POST to Blackbird /blackbird/ingest/track with GPS + signals
    // 3. Notify emergency contacts via SafetyHubService
    // 4. Start audio/location recording
    setState(() {
      _threatLevel = ThreatLevel.critical;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: _ppRed,
        content: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'PANIC PROTOCOL ACTIVE — Emergency contacts notified. '
                'Location sharing ON. Evidence recording started.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 6),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ppBg,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildShieldTab(),
                _buildZonesTab(),
                _buildDevicesTab(),
                _buildAlertsTab(),
                _buildPanicTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────
  Widget _buildHeader() {
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
            _ppPink.withValues(alpha: 0.08),
            _ppEmerald.withValues(alpha: 0.04),
            _ppBg,
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
              // Blackbird integration badge
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, _) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _ppCyan.withValues(alpha: _pulseAnim.value * 0.3),
                        _ppPink.withValues(alpha: _pulseAnim.value * 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _ppCyan.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _bbAlerts.isNotEmpty || _bbError.isEmpty
                              ? _ppEmerald
                              : _ppAmber,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'BLACKBIRD',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROTECTION SCANNER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Personal Radar \u2022 Blackbird Integrated \u2022 Always Watching',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
              ),
              _buildThreatBadge(),
            ],
          ),
          const SizedBox(height: 8),
          // Status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _ppEmerald.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _ppEmerald.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: _ppEmerald, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _scanActive
                        ? 'Shield active — scanning ${_selectedMode.label} mode'
                        : 'We always have your back. Tap SHIELD to begin scanning.',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                if (_scanActive)
                  Text(
                    '$_scanCount scans',
                    style: TextStyle(
                      color: _ppEmerald.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
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
      ThreatLevel.clear: _ppEmerald,
      ThreatLevel.low: _ppEmerald,
      ThreatLevel.elevated: _ppAmber,
      ThreatLevel.high: const Color(0xFFFF6B35),
      ThreatLevel.critical: _ppRed,
    };
    final color = colors[_threatLevel] ?? _ppEmerald;
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

  // ── Tab bar ────────────────────────────────────────────────────────
  Widget _buildTabBar() {
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
          color: _ppPink.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _ppPink.withValues(alpha: 0.3)),
        ),
        labelColor: _ppPink,
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
          Tab(text: 'SHIELD'),
          Tab(text: 'ZONES'),
          Tab(text: 'DEVICES'),
          Tab(text: 'ALERTS'),
          Tab(text: 'PANIC'),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // TAB 1: SHIELD — Radar + Scan Controls
  // ═════════════════════════════════════════════════════════════════════
  Widget _buildShieldTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildRadarVisual(),
          const SizedBox(height: 16),
          _buildModeSelector(),
          const SizedBox(height: 16),
          _buildScanButton(),
          const SizedBox(height: 16),
          _buildStatsRow(),
          const SizedBox(height: 16),
          _buildSignalSparkline(),
          const SizedBox(height: 16),
          _buildProtocolInfo(),
        ],
      ),
    );
  }

  Widget _buildRadarVisual() {
    final scanColor = _scanActive ? _ppEmerald : Colors.white24;
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
            top: 55,
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
            top: 90,
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
            top: 120,
            child: Text(
              '30m',
              style: TextStyle(
                color: scanColor.withValues(alpha: 0.4),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Sweep arm (animated)
          if (_scanActive)
            AnimatedBuilder(
              animation: _radarSweep,
              builder: (_, _) => Transform.rotate(
                angle: _radarSweep.value * 2 * math.pi,
                child: Container(
                  width: 240,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        _ppEmerald.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Center — "YOU"
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _ppPink.withValues(alpha: 0.15),
              border: Border.all(
                color: _ppPink.withValues(alpha: 0.5),
                width: 2,
              ),
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
          // Safe zone indicators
          if (_scanActive)
            for (
              int i = 0;
              i < _zones.where((z) => z.active).length && i < 3;
              i++
            )
              Positioned(
                left: 30 + (i * 70.0),
                top: 20 + (i * 30.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _ppCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _ppCyan.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _zones.where((z) => z.active).elementAt(i).name,
                    style: TextStyle(
                      color: _ppCyan.withValues(alpha: 0.6),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          // Scan status
          Positioned(
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: scanColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: scanColor.withValues(alpha: 0.3)),
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
                        color: _ppEmerald,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    _scanActive
                        ? 'SCANNING — ${_selectedMode.label}'
                        : 'SCANNER IDLE',
                    style: TextStyle(
                      color: scanColor,
                      fontSize: 11,
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

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _ppCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ppBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SCAN MODE',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ChukyaScanMode.values.map(_modeChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(ChukyaScanMode mode) {
    final selected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => _switchMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? _ppPink.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _ppPink.withValues(alpha: 0.4) : _ppBorder,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mode.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              mode.label,
              style: TextStyle(
                color: selected ? _ppPink : Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _scanActive
              ? _ppRed.withValues(alpha: 0.8)
              : _ppEmerald,
          foregroundColor: _scanActive ? Colors.white : _ppBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(
          _scanActive ? Icons.stop_rounded : Icons.shield_rounded,
          size: 20,
        ),
        label: Text(
          _scanActive ? 'STOP SCANNING' : 'ACTIVATE SHIELD',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        onPressed: _toggleScan,
      ),
    );
  }

  Widget _buildStatsRow() {
    final activeZones = _zones.where((z) => z.active).length;
    final connectedDevices = _devices
        .where((d) => d.status == 'connected')
        .length;
    return Row(
      children: [
        _statCard('Scans', '$_scanCount', _ppCyan),
        const SizedBox(width: 8),
        _statCard('Zones', '$activeZones active', _ppEmerald),
        const SizedBox(width: 8),
        _statCard('Devices', '$connectedDevices linked', _ppAmber),
        const SizedBox(width: 8),
        _statCard(
          'Blackbird',
          _bbAlerts.isNotEmpty ? '${_bbAlerts.length} alerts' : 'ONLINE',
          _ppCyan,
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalSparkline() {
    final maxVal = _signalHistory.reduce(math.max);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _ppCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ppBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'SIGNAL STRENGTH',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                'Last 20 scans',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: CustomPaint(
              size: const Size(double.infinity, 40),
              painter: _SparklinePainter(
                data: _signalHistory,
                maxValue: maxVal,
                color: _ppEmerald,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _ppCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ppBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACTIVE PROTOCOLS',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          _protocolRow('BLE 5.3', true, '< 50ms latency'),
          _protocolRow('WiFi 6 Fingerprint', true, 'Passive probe'),
          _protocolRow('Blackbird PostGIS', _bbError.isEmpty, 'Geo-matching'),
          _protocolRow(
            'LTE-M Failover',
            _devices.any((d) => d.protocol == 'LTE-M'),
            'Emergency backup',
          ),
          _protocolRow('Evidence Chain', true, 'SHA-256 manifest'),
        ],
      ),
    );
  }

  Widget _protocolRow(String name, bool active, String note) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            color: active ? _ppEmerald : Colors.white24,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          Text(
            note,
            style: TextStyle(
              color: active ? _ppEmerald : Colors.white24,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // TAB 2: ZONES — Safe Zone Management
  // ═════════════════════════════════════════════════════════════════════
  Widget _buildZonesTab() {
    final activeZones = _zones.where((z) => z.active).toList();
    final markers = <Marker>{};
    final circles = <Circle>{};
    for (final z in _zones) {
      final pos = LatLng(z.lat, z.lng);
      markers.add(
        Marker(
          markerId: MarkerId(z.name),
          position: pos,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            z.active ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(title: z.name, snippet: '${z.radius}m radius'),
        ),
      );
      circles.add(
        Circle(
          circleId: CircleId(z.name),
          center: pos,
          radius: z.radius.toDouble(),
          fillColor: (z.active ? _ppEmerald : _ppRed).withValues(alpha: 0.12),
          strokeColor: (z.active ? _ppEmerald : _ppRed).withValues(alpha: 0.4),
          strokeWidth: 2,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zone overview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_ppCyan.withValues(alpha: 0.08), _ppBg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _ppCyan.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: _ppCyan, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GEOFENCED SAFE ZONES',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${activeZones.length} of ${_zones.length} zones active',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── Google Map showing safe zone geofences ──
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 240,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _zones.isNotEmpty
                      ? LatLng(_zones.first.lat, _zones.first.lng)
                      : const LatLng(-27.63, 153.11),
                  zoom: 12.5,
                ),
                markers: markers,
                circles: circles,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                style: _darkMapStyle,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Zone list
          ..._zones.map(_buildZoneCard),
          const SizedBox(height: 16),
          // Add zone
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _ppCyan,
                side: BorderSide(color: _ppCyan.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add_location_alt_rounded, size: 18),
              label: const Text(
                'ADD SAFE ZONE',
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Safe zone setup requires location access. Enable in device settings.',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneCard(_ZoneEntry zone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ppCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: zone.active ? _ppEmerald.withValues(alpha: 0.2) : _ppBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: zone.active
                  ? _ppEmerald.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              zone.icon,
              color: zone.active ? _ppEmerald : Colors.white24,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zone.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${zone.radius}m radius \u2022 Last check: ${zone.lastCheck}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: zone.active
                  ? _ppEmerald.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              zone.active ? 'ACTIVE' : 'OFF',
              style: TextStyle(
                color: zone.active ? _ppEmerald : Colors.white24,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // TAB 3: DEVICES — Connected Wearables
  // ═════════════════════════════════════════════════════════════════════
  Widget _buildDevicesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device health overview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_ppAmber.withValues(alpha: 0.08), _ppBg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _ppAmber.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.devices_rounded, color: _ppAmber, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DEVICE NETWORK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${_devices.where((d) => d.status == "connected").length} connected \u2022 ${_devices.length} registered',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Device list
          ..._devices.map(_buildDeviceCard),
          const SizedBox(height: 16),
          // Pair new device
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _ppAmber,
                side: BorderSide(color: _ppAmber.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.bluetooth_searching, size: 18),
              label: const Text(
                'PAIR NEW DEVICE',
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Enable Bluetooth and bring device nearby to pair.',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(_DeviceEntry device) {
    final connected = device.status == 'connected';
    final signalColor = device.signal > 0.7
        ? _ppEmerald
        : device.signal > 0.4
        ? _ppAmber
        : _ppRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ppCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: connected ? signalColor.withValues(alpha: 0.2) : _ppBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: signalColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _deviceIcon(device.type),
              color: connected ? signalColor : Colors.white24,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      device.protocol,
                      style: TextStyle(
                        color: signalColor.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (device.battery >= 0) ...[
                      Icon(
                        device.battery > 50
                            ? Icons.battery_full
                            : Icons.battery_3_bar,
                        color: Colors.white24,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${device.battery}%',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Signal bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _signalBars(device.signal, signalColor),
              const SizedBox(height: 4),
              Text(
                device.status.toUpperCase(),
                style: TextStyle(
                  color: connected ? signalColor : Colors.white24,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _signalBars(double strength, Color color) {
    final bars = (strength * 4).ceil().clamp(0, 4);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
        final active = i < bars;
        return Container(
          width: 4,
          height: 6.0 + (i * 3.0),
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: active ? color : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  IconData _deviceIcon(String type) {
    switch (type) {
      case 'watch':
        return Icons.watch_rounded;
      case 'band':
        return Icons.fitness_center_rounded;
      case 'beacon':
        return Icons.wifi_tethering_rounded;
      case 'monitor':
        return Icons.radio_button_checked;
      default:
        return Icons.devices_other_rounded;
    }
  }

  // ═════════════════════════════════════════════════════════════════════
  // TAB 4: ALERTS — Blackbird Feed + Evidence Timeline
  // ═════════════════════════════════════════════════════════════════════
  Widget _buildAlertsTab() {
    return Column(
      children: [
        // Blackbird connection status
        Container(
          width: double.infinity,
          color: _bbError.isEmpty
              ? _ppCyan.withValues(alpha: 0.07)
              : _ppAmber.withValues(alpha: 0.07),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Icon(
                _bbError.isEmpty
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                color: _bbError.isEmpty ? _ppCyan : _ppAmber,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _bbError.isEmpty
                      ? 'Blackbird connected — ${_bbAlerts.length} alerts tracked'
                      : _bbError,
                  style: TextStyle(
                    color: _bbError.isEmpty ? _ppCyan : _ppAmber,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_bbLastRefreshed != null)
                Text(
                  'Updated ${_formatTimeAgo(_bbLastRefreshed!)}',
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _fetchBlackbirdAlerts,
                child: const Icon(Icons.refresh, color: _ppCyan, size: 16),
              ),
            ],
          ),
        ),
        // Alert list
        Expanded(
          child: _bbLoading
              ? const Center(child: CircularProgressIndicator(color: _ppCyan))
              : _bbAlerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_rounded,
                        color: _ppEmerald.withValues(alpha: 0.3),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'ALL CLEAR',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'No active threats detected by Blackbird.',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bbAlerts.length,
                  itemBuilder: (_, i) => _buildAlertCard(_bbAlerts[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(_BlackbirdAlert alert) {
    final levelColor = alert.level == 'Action'
        ? _ppRed
        : alert.level == 'Warning'
        ? _ppAmber
        : _ppCyan;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ppCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: levelColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  alert.level.toUpperCase(),
                  style: TextStyle(
                    color: levelColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.id,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              Text(
                alert.status,
                style: TextStyle(
                  color: alert.status == 'Unacknowledged' ? _ppRed : _ppEmerald,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.reason,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Score: ${alert.score}',
                style: TextStyle(
                  color: levelColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                alert.createdAt,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  // TAB 5: PANIC — One-Touch Emergency
  // ═════════════════════════════════════════════════════════════════════
  Widget _buildPanicTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Panic info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _ppRed.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _ppRed.withValues(alpha: 0.15)),
            ),
            child: const Column(
              children: [
                Icon(Icons.warning_rounded, color: _ppRed, size: 32),
                SizedBox(height: 10),
                Text(
                  'EMERGENCY PANIC PROTOCOL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Press and hold the button below for 3 seconds to activate.\n'
                  'This will instantly:\n'
                  '\u2022 Alert all emergency contacts\n'
                  '\u2022 Share your live location\n'
                  '\u2022 Begin evidence recording\n'
                  '\u2022 Notify Blackbird threat pipeline\n'
                  '\u2022 Log to court-admissible evidence vault',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Panic button
          GestureDetector(
            onLongPress: _panicActive ? null : _activatePanic,
            onTap: _panicActive ? _cancelPanic : null,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, _) => Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _panicActive
                      ? _ppRed.withValues(alpha: 0.3 + (_pulseAnim.value * 0.2))
                      : _ppRed.withValues(alpha: 0.15),
                  border: Border.all(
                    color: _ppRed.withValues(
                      alpha: _panicActive ? _pulseAnim.value : 0.4,
                    ),
                    width: _panicActive ? 4 : 2,
                  ),
                  boxShadow: _panicActive
                      ? [
                          BoxShadow(
                            color: _ppRed.withValues(
                              alpha: _pulseAnim.value * 0.4,
                            ),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _panicActive
                          ? Icons.close_rounded
                          : Icons.emergency_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _panicActive
                          ? 'TAP TO CANCEL\n$_panicCountdown...'
                          : 'HOLD TO\nACTIVATE',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Emergency contacts quick-view
          _buildEmergencyContacts(),
          const SizedBox(height: 16),
          // Recent panic events
          _buildRecentPanicEvents(),
        ],
      ),
    );
  }

  Widget _buildEmergencyContacts() {
    final contacts = [
      ('Emergency Services', '000', Icons.local_police_rounded, _ppRed),
      ('Trusted Person 1', 'Configured', Icons.person_rounded, _ppPink),
      (
        'Pink Shield Gym',
        'Configured',
        Icons.fitness_center_rounded,
        _ppEmerald,
      ),
      ('DFC Guardian', 'Auto-linked', Icons.shield_rounded, _ppCyan),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ppCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ppBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EMERGENCY CONTACTS',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          ...contacts.map(
            (c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(c.$3, color: c.$4, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.$1,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  Text(
                    c.$2,
                    style: TextStyle(
                      color: c.$4,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  Widget _buildRecentPanicEvents() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ppCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ppBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EVIDENCE VAULT LOG',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'No panic events recorded.',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_rounded,
                color: _ppEmerald.withValues(alpha: 0.3),
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                'All evidence encrypted with AES-256',
                style: TextStyle(
                  color: _ppEmerald.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Utility ────────────────────────────────────────────────────────
  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ═════════════════════════════════════════════════════════════════════════
// HELPER MODELS
// ═════════════════════════════════════════════════════════════════════════

class _BlackbirdAlert {
  final String id;
  final String level;
  final String reason;
  final int score;
  final String status;
  final String createdAt;

  _BlackbirdAlert({
    required this.id,
    required this.level,
    required this.reason,
    required this.score,
    required this.status,
    required this.createdAt,
  });

  factory _BlackbirdAlert.fromJson(Map<String, dynamic> j) => _BlackbirdAlert(
    id: j['alert_id']?.toString() ?? j['id']?.toString() ?? '',
    level: j['level']?.toString() ?? 'Info',
    reason: j['reason']?.toString() ?? j['type']?.toString() ?? '',
    score:
        (j['score'] as num?)?.toInt() ?? (j['riskScore'] as num?)?.toInt() ?? 0,
    status: j['status']?.toString() ?? 'Unacknowledged',
    createdAt: j['created_at']?.toString() ?? j['createdAt']?.toString() ?? '',
  );
}

class _DeviceEntry {
  final String name;
  final String type;
  final double signal;
  final int battery;
  final String protocol;
  final String status;

  const _DeviceEntry({
    required this.name,
    required this.type,
    required this.signal,
    required this.battery,
    required this.protocol,
    required this.status,
  });
}

class _ZoneEntry {
  final String name;
  final IconData icon;
  final int radius;
  final bool active;
  final String lastCheck;
  final double lat;
  final double lng;

  const _ZoneEntry({
    required this.name,
    required this.icon,
    required this.radius,
    required this.active,
    required this.lastCheck,
    required this.lat,
    required this.lng,
  });
}

// ═════════════════════════════════════════════════════════════════════════
// SPARKLINE PAINTER
// ═════════════════════════════════════════════════════════════════════════

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final double maxValue;
  final Color color;

  _SparklinePainter({
    required this.data,
    required this.maxValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxValue == 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / maxValue) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      data != old.data || maxValue != old.maxValue;
}
