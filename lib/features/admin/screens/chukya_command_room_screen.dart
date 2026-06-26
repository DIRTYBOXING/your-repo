import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CHUKYA 3.0 COMMAND ROOM — Full System Control Center
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Master control board with 5 operational panels:
///   1. RADAR CONTROL   — scan modes, BLE/WiFi toggles, sweep status
///   2. DEVICE TRACKING  — ankle monitors, GPS, mobile ping, IMEI lookup
///   3. DIAGNOSTICS      — system health, battery, signal, Firestore sync
///   4. MODERATION       — content flags, takedowns, user bans
///   5. ALERT CONSOLE    — live proximity alerts, police notify queue
/// ═══════════════════════════════════════════════════════════════════════════
class ChukyaCommandRoomScreen extends StatefulWidget {
  const ChukyaCommandRoomScreen({super.key});

  @override
  State<ChukyaCommandRoomScreen> createState() =>
      _ChukyaCommandRoomScreenState();
}

class _ChukyaCommandRoomScreenState extends State<ChukyaCommandRoomScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Radar Control State ──────────────────────────────────────────────
  bool _bleScanEnabled = true;
  bool _wifiScanEnabled = true;
  bool _gpsTrackingEnabled = true;
  bool _mobilePingEnabled = false;
  bool _ankleMonitorFeed = false;
  bool _imeiLookupEnabled = false;
  String _scanMode = 'HOME SHIELD';
  bool _radarSweepActive = false;
  int _sweepCount = 0;
  final double _signalStrength = 0.74;

  // ── Device Tracking State ────────────────────────────────────────────
  final List<_TrackedDevice> _trackedDevices = [
    const _TrackedDevice(
      id: 'ANK-2026-0441',
      type: DeviceType.ankleMonitor,
      label: 'Case DV-2026-0441 — Ankle GPS',
      lat: -27.4698,
      lng: 153.0251,
      lastPing: '2 min ago',
      signalStrength: 0.92,
      batteryPercent: 78,
      status: DeviceStatus.active,
    ),
    const _TrackedDevice(
      id: 'MOB-2026-0441',
      type: DeviceType.mobilePhone,
      label: 'Case DV-2026-0441 — Mobile',
      lat: -27.4701,
      lng: 153.0248,
      lastPing: '45 sec ago',
      signalStrength: 0.85,
      batteryPercent: 54,
      status: DeviceStatus.active,
      imei: '35-209900-176148-1',
    ),
    const _TrackedDevice(
      id: 'GPS-2026-0889',
      type: DeviceType.gpsTracker,
      label: 'Case DV-2026-0889 — Vehicle GPS',
      lat: -27.9673,
      lng: 153.4145,
      lastPing: '8 min ago',
      signalStrength: 0.61,
      batteryPercent: 33,
      status: DeviceStatus.lowBattery,
    ),
    const _TrackedDevice(
      id: 'BLE-2026-1102',
      type: DeviceType.bleBeacon,
      label: 'Case DV-2026-1102 — BLE Tag',
      lat: -27.3812,
      lng: 153.1234,
      lastPing: '22 min ago',
      signalStrength: 0.23,
      batteryPercent: 12,
      status: DeviceStatus.signalWeak,
    ),
  ];

  // ── Diagnostics State ────────────────────────────────────────────────
  final Map<String, _DiagnosticItem> _diagnostics = {
    'firestore_sync': const _DiagnosticItem(
      label: 'Firestore Sync',
      value: 'OK',
      status: DiagStatus.ok,
    ),
    'ble_adapter': const _DiagnosticItem(
      label: 'BLE Adapter',
      value: 'Active',
      status: DiagStatus.ok,
    ),
    'wifi_scanner': const _DiagnosticItem(
      label: 'WiFi Scanner',
      value: 'Active',
      status: DiagStatus.ok,
    ),
    'gps_accuracy': const _DiagnosticItem(
      label: 'GPS Accuracy',
      value: '±4.2m',
      status: DiagStatus.ok,
    ),
    'battery_impact': const _DiagnosticItem(
      label: 'Battery Impact (24h)',
      value: '3.8%',
      status: DiagStatus.ok,
    ),
    'police_api': const _DiagnosticItem(
      label: 'Police Notify API',
      value: 'Connected',
      status: DiagStatus.ok,
    ),
    'evidence_vault': const _DiagnosticItem(
      label: 'Evidence Vault',
      value: '2.1 GB / 10 GB',
      status: DiagStatus.ok,
    ),
    'cloud_functions': const _DiagnosticItem(
      label: 'Cloud Functions',
      value: 'Healthy',
      status: DiagStatus.ok,
    ),
    'fingerprint_db': const _DiagnosticItem(
      label: 'Fingerprint DB',
      value: '847 entries',
      status: DiagStatus.ok,
    ),
    'watchlist_sync': const _DiagnosticItem(
      label: 'Watchlist Sync',
      value: 'Last: 12s ago',
      status: DiagStatus.ok,
    ),
  };

  // ── Alert Console State ──────────────────────────────────────────────
  final List<_AlertEntry> _alertLog = [
    const _AlertEntry(
      time: '14:32:08',
      severity: 'CRITICAL',
      message: 'Case 0441 — device in 15m perimeter. Police auto-notified.',
      caseRef: 'DV-2026-0441',
    ),
    const _AlertEntry(
      time: '14:28:44',
      severity: 'HIGH',
      message: 'Case 0441 — BLE match confidence 0.88. Tracking.',
      caseRef: 'DV-2026-0441',
    ),
    const _AlertEntry(
      time: '13:55:12',
      severity: 'ELEVATED',
      message: 'Case 0889 — GPS fence breach (Gold Coast zone).',
      caseRef: 'DV-2026-0889',
    ),
    const _AlertEntry(
      time: '12:10:01',
      severity: 'LOW',
      message: 'Case 1102 — BLE tag signal weak. May need replacement.',
      caseRef: 'DV-2026-1102',
    ),
    const _AlertEntry(
      time: '11:45:33',
      severity: 'INFO',
      message: 'Nightly watchlist sync complete. 847 profiles loaded.',
      caseRef: 'SYSTEM',
    ),
  ];

  // ── Moderation Queue State ───────────────────────────────────────────
  final int _pendingFlags = 7;
  final int _pendingTakedowns = 2;
  final int _activeBans = 14;
  bool _autoModEnabled = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1520),
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _radarSweepActive
                    ? AppTheme.neonGreen
                    : AppTheme.neonPink,
                boxShadow: [
                  BoxShadow(
                    color:
                        (_radarSweepActive
                                ? AppTheme.neonGreen
                                : AppTheme.neonPink)
                            .withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'CHUKYA 3.0 COMMAND ROOM',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.neonPink,
          labelColor: AppTheme.neonPink,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.radar, size: 18), text: 'RADAR'),
            Tab(icon: Icon(Icons.gps_fixed, size: 18), text: 'DEVICES'),
            Tab(icon: Icon(Icons.monitor_heart, size: 18), text: 'DIAG'),
            Tab(icon: Icon(Icons.shield, size: 18), text: 'MOD'),
            Tab(icon: Icon(Icons.warning_amber, size: 18), text: 'ALERTS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRadarPanel(),
          _buildDeviceTrackingPanel(),
          _buildDiagnosticsPanel(),
          _buildModerationPanel(),
          _buildAlertConsolePanel(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 1: RADAR CONTROL
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildRadarPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sweep status card
          _buildPanelCard(
            title: 'SWEEP STATUS',
            icon: Icons.radar,
            color: _radarSweepActive ? AppTheme.neonGreen : AppTheme.textMuted,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _radarSweepActive ? 'SCANNING' : 'STANDBY',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: _radarSweepActive
                                ? AppTheme.neonGreen
                                : AppTheme.textMuted,
                          ),
                        ),
                        Text(
                          'Mode: $_scanMode  |  Sweeps: $_sweepCount',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _radarSweepActive = !_radarSweepActive;
                          if (_radarSweepActive) _sweepCount++;
                        });
                      },
                      icon: Icon(
                        _radarSweepActive
                            ? Icons.stop_circle
                            : Icons.play_circle,
                      ),
                      label: Text(_radarSweepActive ? 'STOP' : 'START'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _radarSweepActive
                            ? AppTheme.error
                            : AppTheme.neonGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Signal strength bar
                _buildProgressIndicator(
                  'Signal Strength',
                  _signalStrength,
                  AppTheme.neonCyan,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Scan mode selector
          _buildPanelCard(
            title: 'SCAN MODE',
            icon: Icons.tune,
            color: AppTheme.neonCyan,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildModeChip('HOME SHIELD', Icons.home_rounded),
                _buildModeChip('TRAVEL RADAR', Icons.directions_walk),
                _buildModeChip('AMBUSH DETECT', Icons.warning_amber),
                _buildModeChip('SAFE ZONE', Icons.my_location),
                _buildModeChip('GUARDIAN', Icons.security),
                _buildModeChip('STEALTH SENTINEL', Icons.visibility_off),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Scanner toggles
          _buildPanelCard(
            title: 'SCANNER CONTROLS',
            icon: Icons.settings_input_antenna,
            color: AppTheme.neonPink,
            child: Column(
              children: [
                _buildToggleRow(
                  'BLE Scan',
                  Icons.bluetooth,
                  _bleScanEnabled,
                  (v) => setState(() => _bleScanEnabled = v),
                ),
                _buildToggleRow(
                  'WiFi Scan',
                  Icons.wifi,
                  _wifiScanEnabled,
                  (v) => setState(() => _wifiScanEnabled = v),
                ),
                _buildToggleRow(
                  'GPS Tracking',
                  Icons.gps_fixed,
                  _gpsTrackingEnabled,
                  (v) => setState(() => _gpsTrackingEnabled = v),
                ),
                _buildToggleRow(
                  'Mobile Ping',
                  Icons.cell_tower,
                  _mobilePingEnabled,
                  (v) => setState(() => _mobilePingEnabled = v),
                ),
                _buildToggleRow(
                  'Ankle Monitor Feed',
                  Icons.link,
                  _ankleMonitorFeed,
                  (v) => setState(() => _ankleMonitorFeed = v),
                ),
                _buildToggleRow(
                  'IMEI Lookup',
                  Icons.phonelink_lock,
                  _imeiLookupEnabled,
                  (v) => setState(() => _imeiLookupEnabled = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 2: DEVICE TRACKING
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildDeviceTrackingPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary bar
          _buildPanelCard(
            title: 'TRACKED DEVICES',
            icon: Icons.devices,
            color: AppTheme.neonCyan,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBadge(
                  'ACTIVE',
                  _trackedDevices
                      .where((d) => d.status == DeviceStatus.active)
                      .length
                      .toString(),
                  AppTheme.neonGreen,
                ),
                _buildStatBadge(
                  'WEAK',
                  _trackedDevices
                      .where((d) => d.status == DeviceStatus.signalWeak)
                      .length
                      .toString(),
                  AppTheme.warning,
                ),
                _buildStatBadge(
                  'LOW BAT',
                  _trackedDevices
                      .where((d) => d.status == DeviceStatus.lowBattery)
                      .length
                      .toString(),
                  AppTheme.error,
                ),
                _buildStatBadge(
                  'TOTAL',
                  _trackedDevices.length.toString(),
                  AppTheme.neonCyan,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Device cards
          ..._trackedDevices.map(
            (device) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildDeviceCard(device),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(_TrackedDevice device) {
    final statusColor = switch (device.status) {
      DeviceStatus.active => AppTheme.neonGreen,
      DeviceStatus.signalWeak => AppTheme.warning,
      DeviceStatus.lowBattery => AppTheme.error,
      DeviceStatus.offline => AppTheme.textMuted,
    };

    final typeIcon = switch (device.type) {
      DeviceType.ankleMonitor => Icons.link,
      DeviceType.mobilePhone => Icons.phone_android,
      DeviceType.gpsTracker => Icons.gps_fixed,
      DeviceType.bleBeacon => Icons.bluetooth_searching,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(typeIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  device.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  device.status.name.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildDeviceField('ID', device.id),
              const SizedBox(width: 16),
              _buildDeviceField('Last Ping', device.lastPing),
              if (device.imei != null) ...[
                const SizedBox(width: 16),
                _buildDeviceField('IMEI', device.imei!),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildProgressIndicator(
                  'Signal',
                  device.signalStrength,
                  AppTheme.neonCyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProgressIndicator(
                  'Battery',
                  device.batteryPercent / 100,
                  device.batteryPercent < 20
                      ? AppTheme.error
                      : AppTheme.neonGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'GPS: ${device.lat.toStringAsFixed(4)}, ${device.lng.toStringAsFixed(4)}',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildActionButton('PING', Icons.cell_tower, AppTheme.neonCyan),
              const SizedBox(width: 8),
              _buildActionButton('LOCATE', Icons.map, AppTheme.neonGreen),
              const SizedBox(width: 8),
              _buildActionButton('HISTORY', Icons.history, AppTheme.neonPink),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 3: DIAGNOSTICS
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildDiagnosticsPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelCard(
            title: 'SYSTEM DIAGNOSTICS',
            icon: Icons.monitor_heart,
            color: AppTheme.neonGreen,
            child: Column(
              children: [
                // Overall health bar
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.neonGreen,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ALL SYSTEMS OPERATIONAL',
                          style: TextStyle(
                            color: AppTheme.neonGreen,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${_diagnostics.length} subsystems checked',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('RESCAN'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.neonCyan,
                        side: const BorderSide(color: AppTheme.neonCyan),
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppTheme.textMuted, height: 24),
                ..._diagnostics.entries.map((e) => _buildDiagRow(e.value)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildPanelCard(
            title: 'SCAN PERFORMANCE',
            icon: Icons.speed,
            color: AppTheme.neonCyan,
            child: Column(
              children: [
                _buildProgressIndicator(
                  'BLE Scan Rate',
                  0.82,
                  AppTheme.neonCyan,
                ),
                const SizedBox(height: 8),
                _buildProgressIndicator(
                  'WiFi Match Rate',
                  0.68,
                  AppTheme.neonPink,
                ),
                const SizedBox(height: 8),
                _buildProgressIndicator(
                  'GPS Fix Time',
                  0.91,
                  AppTheme.neonGreen,
                ),
                const SizedBox(height: 8),
                _buildProgressIndicator(
                  'Fingerprint Match Latency',
                  0.76,
                  AppTheme.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagRow(_DiagnosticItem item) {
    final color = switch (item.status) {
      DiagStatus.ok => AppTheme.neonGreen,
      DiagStatus.warning => AppTheme.warning,
      DiagStatus.error => AppTheme.error,
    };
    final icon = switch (item.status) {
      DiagStatus.ok => Icons.check_circle_outline,
      DiagStatus.warning => Icons.warning_amber_rounded,
      DiagStatus.error => Icons.error_outline,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Text(
            item.value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 4: MODERATION
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildModerationPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelCard(
            title: 'MODERATION QUEUE',
            icon: Icons.shield,
            color: AppTheme.warning,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatBadge(
                      'FLAGS',
                      _pendingFlags.toString(),
                      AppTheme.warning,
                    ),
                    _buildStatBadge(
                      'TAKEDOWNS',
                      _pendingTakedowns.toString(),
                      AppTheme.error,
                    ),
                    _buildStatBadge(
                      'BANS',
                      _activeBans.toString(),
                      AppTheme.neonPink,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildToggleRow(
                  'Auto-Moderation',
                  Icons.smart_toy,
                  _autoModEnabled,
                  (v) => setState(() => _autoModEnabled = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildPanelCard(
            title: 'QUICK ACTIONS',
            icon: Icons.flash_on,
            color: AppTheme.neonMagenta,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                  'Review Flags',
                  Icons.flag,
                  AppTheme.warning,
                ),
                _buildActionButton(
                  'Process Takedowns',
                  Icons.delete_sweep,
                  AppTheme.error,
                ),
                _buildActionButton(
                  'Ban Manager',
                  Icons.block,
                  AppTheme.neonPink,
                ),
                _buildActionButton(
                  'Content Audit',
                  Icons.fact_check,
                  AppTheme.neonCyan,
                ),
                _buildActionButton(
                  'User Reports',
                  Icons.report,
                  AppTheme.neonOrange,
                ),
                _buildActionButton(
                  'Appeal Queue',
                  Icons.gavel,
                  AppTheme.neonPurple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 5: ALERT CONSOLE
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildAlertConsolePanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelCard(
            title: 'LIVE ALERT FEED',
            icon: Icons.warning_amber,
            color: AppTheme.error,
            child: Column(
              children: [..._alertLog.map(_buildAlertRow)],
            ),
          ),
          const SizedBox(height: 12),
          _buildPanelCard(
            title: 'POLICE NOTIFY QUEUE',
            icon: Icons.local_police,
            color: AppTheme.neonPink,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatBadge('SENT TODAY', '3', AppTheme.neonGreen),
                    _buildStatBadge('PENDING', '0', AppTheme.textMuted),
                    _buildStatBadge('FAILED', '0', AppTheme.textMuted),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.neonGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.neonGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.neonGreen,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'All police notifications delivered successfully',
                        style: TextStyle(
                          color: AppTheme.neonGreen,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertRow(_AlertEntry alert) {
    final color = switch (alert.severity) {
      'CRITICAL' => AppTheme.error,
      'HIGH' => AppTheme.neonPink,
      'ELEVATED' => AppTheme.warning,
      'LOW' => AppTheme.neonCyan,
      _ => AppTheme.textMuted,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              alert.severity,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.message,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  '${alert.time}  |  ${alert.caseRef}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildPanelCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildToggleRow(
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? AppTheme.neonGreen : AppTheme.textMuted,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.neonGreen,
            inactiveThumbColor: AppTheme.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, IconData icon) {
    final selected = _scanMode == label;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: selected ? Colors.black : AppTheme.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
      selected: selected,
      onSelected: (_) => setState(() => _scanMode = label),
      selectedColor: AppTheme.neonPink,
      backgroundColor: AppTheme.surfaceColor,
      labelStyle: TextStyle(
        color: selected ? Colors.black : AppTheme.textSecondary,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(
        color: selected
            ? AppTheme.neonPink
            : AppTheme.textMuted.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildProgressIndicator(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }

  Widget _buildDeviceField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════════════════

enum DeviceType { ankleMonitor, mobilePhone, gpsTracker, bleBeacon }

enum DeviceStatus { active, signalWeak, lowBattery, offline }

enum DiagStatus { ok, warning, error }

class _TrackedDevice {
  final String id;
  final DeviceType type;
  final String label;
  final double lat;
  final double lng;
  final String lastPing;
  final double signalStrength;
  final int batteryPercent;
  final DeviceStatus status;
  final String? imei;

  const _TrackedDevice({
    required this.id,
    required this.type,
    required this.label,
    required this.lat,
    required this.lng,
    required this.lastPing,
    required this.signalStrength,
    required this.batteryPercent,
    required this.status,
    this.imei,
  });
}

class _DiagnosticItem {
  final String label;
  final String value;
  final DiagStatus status;

  const _DiagnosticItem({
    required this.label,
    required this.value,
    required this.status,
  });
}

class _AlertEntry {
  final String time;
  final String severity;
  final String message;
  final String caseRef;

  const _AlertEntry({
    required this.time,
    required this.severity,
    required this.message,
    required this.caseRef,
  });
}
