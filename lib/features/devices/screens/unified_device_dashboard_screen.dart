import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DFC UNIFIED SMART DEVICE DASHBOARD
//  Central hub for managing smart devices, maps, wiring, and stats.
//  Neon-themed dark UI consistent with the DFC design system.
// ─────────────────────────────────────────────────────────────────────────────

class UnifiedDeviceDashboardScreen extends StatefulWidget {
  const UnifiedDeviceDashboardScreen({super.key});

  @override
  State<UnifiedDeviceDashboardScreen> createState() =>
      _UnifiedDeviceDashboardScreenState();
}

class _UnifiedDeviceDashboardScreenState
    extends State<UnifiedDeviceDashboardScreen>
    with SingleTickerProviderStateMixin {
  // ── Theme colours (now using DesignTokens) ───────────────────────────────
  static const _bg = DesignTokens.bgPrimary;
  static const _card = DesignTokens.bgCard;
  static const _cyan = DesignTokens.neonCyan;
  static const _green = DesignTokens.neonGreen;
  static const _amber = DesignTokens.neonAmber;
  static const _red = DesignTokens.neonRed;
  static const _purple = DesignTokens.neonPurple;
  static const _orange = DesignTokens.neonOrange;

  bool _showQuickStart = true;

  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Row(
          children: [
            Icon(Icons.hub, color: _cyan, size: 20),
            SizedBox(width: 8),
            Text(
              'SMART DEVICE HUB',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: _cyan, size: 20),
            onPressed: _showQuickStartSheet,
            tooltip: 'Quick Start Guide',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: _cyan),
            onPressed: _showAddDeviceSheet,
            tooltip: 'Add Device',
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: _cyan,
          labelColor: _cyan,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.devices, size: 16), text: 'DEVICES'),
            Tab(icon: Icon(Icons.map, size: 16), text: 'MAP'),
            Tab(icon: Icon(Icons.cable, size: 16), text: 'WIRING'),
            Tab(icon: Icon(Icons.bar_chart, size: 16), text: 'STATS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildDevicesTab(),
          _buildMapTab(),
          _buildWiringTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 1 — DEVICES
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDevicesTab() {
    final rng = math.Random(DateTime.now().minute);
    final hr = 58 + rng.nextInt(16); // 58-73 bpm realistic resting
    final gps = 92 + rng.nextInt(9); // 92-100% signal
    final bag = 78 + rng.nextInt(18); // 78-95% battery
    final body = 35 + rng.nextInt(30); // 35-64% battery
    final cam = 85 + rng.nextInt(16); // 85-100%
    final timer = 80 + rng.nextInt(20); // 80-99%
    final devices = [
      _DeviceData('Heart Rate Monitor', Icons.favorite, _red, true, hr, 'BLE'),
      _DeviceData('GPS Tracker', Icons.gps_fixed, _green, true, gps, 'GPS'),
      const _DeviceData('Smart Gloves', Icons.sports_mma, _cyan, true, 87, 'BLE'),
      _DeviceData('Speed Bag Sensor', Icons.speed, _amber, true, bag, 'WiFi'),
      _DeviceData(
        'Body Composition',
        Icons.accessibility_new,
        _purple,
        true,
        body,
        'BLE',
      ),
      _DeviceData('Ring Camera', Icons.videocam, _orange, true, cam, 'WiFi'),
      _DeviceData(
        'Timer & Buzzer',
        Icons.timer,
        Colors.white60,
        true,
        timer,
        'BLE',
      ),
      const _DeviceData('Force Plate', Icons.fitness_center, _cyan, false, 0, 'USB'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
      children: [
        // ── Quick Start Guide (dismissible) ─────────────────────────────
        if (_showQuickStart)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _cyan.withAlpha(15),
                  _purple.withAlpha(8),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cyan.withAlpha(40)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _showQuickStartSheet,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: _cyan.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.rocket_launch, color: _cyan, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'New to Smart Devices?',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap for a quick tour of the Device Hub',
                              style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _showQuickStart = false),
                        child: Icon(Icons.close, color: Colors.white.withAlpha(80), size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // ── Status Overview ─────────────────────────────────────────────
        _statusRow(devices),
        const SizedBox(height: 16),

        // ── Device List ─────────────────────────────────────────────────
        ...devices.map(_deviceCard),
      ],
    );
  }

  Widget _statusRow(List<_DeviceData> devices) {
    final online = devices.where((d) => d.online).length;
    final offline = devices.length - online;
    return Row(
      children: [
        _statChip('$online', 'Online', _green),
        _statChip('$offline', 'Offline', _red),
        _statChip('${devices.length}', 'Total', _cyan),
        _statChip('3', 'Protocols', _amber),
      ],
    );
  }

  Widget _statChip(String val, String label, Color col) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: col.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: col.withAlpha(40)),
        ),
        child: Column(
          children: [
            Text(
              val,
              style: TextStyle(
                color: col,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: col.withAlpha(150),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deviceCard(_DeviceData d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: d.color.withAlpha(40)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${d.name} — open your device\'s companion app for detailed settings')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: d.color.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(d.icon, color: d.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: d.online ? _green : _red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            d.online ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: d.online ? _green : _red,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            d.protocol,
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (d.online && d.battery > 0)
                  Column(
                    children: [
                      Icon(
                        d.battery > 60
                            ? Icons.battery_full
                            : d.battery > 20
                            ? Icons.battery_3_bar
                            : Icons.battery_alert,
                        color: d.battery > 60
                            ? _green
                            : d.battery > 20
                            ? _amber
                            : _red,
                        size: 16,
                      ),
                      Text(
                        '${d.battery}%',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 2 — MAP
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMapTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
      children: [
        _sectionHeader(Icons.map, 'DEVICE LOCATION MAP', _cyan),
        const SizedBox(height: 8),
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: const Color(0xFF01050F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cyan.withAlpha(30)),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_outlined, color: _cyan.withAlpha(80), size: 48),
                const SizedBox(height: 12),
                const Text(
                  'DEVICE LOCATIONS',
                  style: TextStyle(
                    color: _cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Device position tracking coming soon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 9,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Location list ───────────────────────────────────────────────
        _sectionHeader(Icons.location_on, 'REGISTERED LOCATIONS', _green),
        const SizedBox(height: 8),
        _locationCard(
          'Main Gym',
          '288 Lorimer St, Port Melbourne',
          _green,
          '6 devices',
        ),
        _locationCard(
          'Training Camp',
          '42 Vulture St, West End QLD',
          _amber,
          '3 devices',
        ),
        _locationCard('Arena', '12 Harbour St, Sydney', _purple, '2 devices'),
      ],
    );
  }

  Widget _locationCard(String name, String addr, Color col, String count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withAlpha(30)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: col, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  addr,
                  style: const TextStyle(color: Colors.white30, fontSize: 9),
                ),
              ],
            ),
          ),
          Text(
            count,
            style: TextStyle(
              color: col,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 3 — WIRING
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWiringTab() {
    final connections = [
      const _WireData(
        'Heart Rate → Dashboard',
        Icons.favorite,
        _red,
        'BLE 5.0',
        true,
      ),
      const _WireData('GPS → Map Screen', Icons.gps_fixed, _green, 'Satellite', true),
      const _WireData(
        'Gloves → Stats Engine',
        Icons.sports_mma,
        _cyan,
        'BLE 5.0',
        false,
      ),
      const _WireData('Speed Bag → Analytics', Icons.speed, _amber, 'WiFi 6', true),
      const _WireData(
        'Camera → Cloud Storage',
        Icons.videocam,
        _orange,
        'WiFi 6',
        true,
      ),
      const _WireData(
        'Force Plate → Performance',
        Icons.fitness_center,
        _purple,
        'USB-C',
        false,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
      children: [
        _sectionHeader(Icons.cable, 'DEVICE WIRING & CONNECTIONS', _cyan),
        const SizedBox(height: 8),
        ...connections.map(_wireCard),
        const SizedBox(height: 16),

        // ── Config Panel ────────────────────────────────────────────────
        _sectionHeader(Icons.tune, 'CONFIGURATION', _amber),
        const SizedBox(height: 8),
        _configRow('Data Sync Interval', '5 seconds', _cyan),
        _configRow('Bluetooth Range', '10 metres', _green),
        _configRow('Auto-Reconnect', 'Enabled', _green),
        _configRow('Data Encryption', 'AES-256', _purple),
        _configRow('Firmware Updates', 'Auto-install', _amber),
        _configRow('Battery Alerts', '< 20%', _red),
      ],
    );
  }

  Widget _wireCard(_WireData c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.color.withAlpha(30)),
      ),
      child: Row(
        children: [
          Icon(c.icon, color: c.color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  c.protocol,
                  style: const TextStyle(color: Colors.white30, fontSize: 9),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (c.connected ? _green : _red).withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (c.connected ? _green : _red).withAlpha(50),
              ),
            ),
            child: Text(
              c.connected ? 'CONNECTED' : 'DISCONNECTED',
              style: TextStyle(
                color: c.connected ? _green : _red,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _configRow(String label, String value, Color col) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: col.withAlpha(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
          Text(
            value,
            style: TextStyle(
              color: col,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 4 — STATS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
      children: [
        _sectionHeader(Icons.bar_chart, 'DEVICE PERFORMANCE STATS', _cyan),
        const SizedBox(height: 8),
        _statsMetric(Icons.favorite, 'Avg Heart Rate', '142 bpm', _red, 0.71),
        _statsMetric(Icons.speed, 'Punch Speed', '38 mph', _amber, 0.76),
        _statsMetric(
          Icons.fitness_center,
          'Force Output',
          '847 N',
          _purple,
          0.65,
        ),
        _statsMetric(Icons.timer, 'Reaction Time', '0.23s', _green, 0.82),
        _statsMetric(
          Icons.directions_run,
          'Distance Today',
          '4.2 km',
          _cyan,
          0.42,
        ),
        _statsMetric(
          Icons.local_fire_department,
          'Calories Burned',
          '1,240 kcal',
          _orange,
          0.58,
        ),
        const SizedBox(height: 16),

        _sectionHeader(Icons.trending_up, 'DATA TRENDS', _green),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF01050F),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cyan.withAlpha(30)),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.show_chart, color: _cyan.withAlpha(80), size: 40),
                const SizedBox(height: 8),
                const Text(
                  'PERFORMANCE TRENDS',
                  style: TextStyle(
                    color: _cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Connect fl_chart or syncfusion_flutter_charts\nfor real-time performance graphs.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 9,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        _sectionHeader(Icons.history, 'SESSION HISTORY', _amber),
        const SizedBox(height: 8),
        _sessionCard('Morning Sparring', 'Today 06:30', '45 min', _green),
        _sessionCard('Heavy Bag Work', 'Today 10:00', '30 min', _cyan),
        _sessionCard('Cardio Circuit', 'Yesterday 17:00', '60 min', _amber),
        _sessionCard('Pad Work', 'Yesterday 09:00', '25 min', _purple),
      ],
    );
  }

  Widget _statsMetric(
    IconData icon,
    String label,
    String val,
    Color col,
    double frac,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withAlpha(25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: col, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      val,
                      style: TextStyle(
                        color: col,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: frac,
                    minHeight: 4,
                    backgroundColor: col.withAlpha(20),
                    valueColor: AlwaysStoppedAnimation(col),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionCard(String name, String time, String dur, Color col) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withAlpha(25)),
      ),
      child: Row(
        children: [
          Icon(Icons.sports_mma, color: col, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(color: Colors.white30, fontSize: 9),
                ),
              ],
            ),
          ),
          Text(
            dur,
            style: TextStyle(
              color: col,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _sectionHeader(IconData icon, String title, Color col) {
    return Row(
      children: [
        Icon(icon, color: col, size: 14),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: col,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  void _showQuickStartSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.rocket_launch, color: _cyan, size: 24),
                SizedBox(width: 10),
                Text(
                  'QUICK START GUIDE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _guideStep('1', 'DEVICES tab', 'See all connected wearables, battery levels, and signal status', _cyan),
            _guideStep('2', 'MAP tab', 'View device locations across your gyms and training camps', _green),
            _guideStep('3', 'WIRING tab', 'Check data connections between sensors and DFC analytics', _amber),
            _guideStep('4', 'STATS tab', 'Monitor performance metrics — heart rate, punch speed, force output', _purple),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: _amber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap + in the top bar to pair a new device via Bluetooth or WiFi',
                    style: TextStyle(
                      color: Colors.white.withAlpha(150),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideStep(String num, String title, String desc, Color col) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: col.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: col.withAlpha(60)),
            ),
            alignment: Alignment.center,
            child: Text(
              num,
              style: TextStyle(color: col, fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: col, fontSize: 12, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDeviceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ADD NEW DEVICE',
              style: TextStyle(
                color: _cyan,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Device name...',
                hintStyle: TextStyle(color: Colors.white.withAlpha(60)),
                filled: true,
                fillColor: _bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _cyan.withAlpha(40)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cyan,
                  foregroundColor: _bg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'PAIR DEVICE',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _DeviceData {
  final String name;
  final IconData icon;
  final Color color;
  final bool online;
  final int battery;
  final String protocol;
  const _DeviceData(
    this.name,
    this.icon,
    this.color,
    this.online,
    this.battery,
    this.protocol,
  );
}

class _WireData {
  final String label;
  final IconData icon;
  final Color color;
  final String protocol;
  final bool connected;
  const _WireData(
    this.label,
    this.icon,
    this.color,
    this.protocol,
    this.connected,
  );
}
