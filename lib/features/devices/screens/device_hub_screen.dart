import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/config/router_config.dart' as rc;
import '../../../shared/services/wearable_api_connector_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DEVICE HUB SCREEN — Unified Wearable Connection & Health Dashboard
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Single screen for:
///   • Connecting/disconnecting wearable platforms (OAuth flow)
///   • Viewing real-time synced health data from all sources
///   • Sync history & data quality indicators
///   • Merged multi-source biometric snapshot
///
/// ═══════════════════════════════════════════════════════════════════════════
class DeviceHubScreen extends StatefulWidget {
  const DeviceHubScreen({super.key});

  @override
  State<DeviceHubScreen> createState() => _DeviceHubScreenState();
}

class _DeviceHubScreenState extends State<DeviceHubScreen>
    with SingleTickerProviderStateMixin {
  final WearableApiConnectorService _connector = WearableApiConnectorService();
  late TabController _tabController;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _init();
  }

  Future<void> _init() async {
    await _connector.initialize();
    if (mounted) {
      setState(() => _isInitializing = false);
    }
    _connector.addListener(_onDataChange);
  }

  void _onDataChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _connector.removeListener(_onDataChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
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
            Icon(Icons.devices_other, color: DesignTokens.neonCyan, size: 22),
            SizedBox(width: DesignTokens.spacingS),
            Text(
              'DEVICE HUB',
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: DesignTokens.fontSizeTitle,
                fontWeight: DesignTokens.fontWeightTitle,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: DesignTokens.neonCyan,
          labelColor: DesignTokens.neonCyan,
          unselectedLabelColor: DesignTokens.textMuted,
          labelStyle: const TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'CONNECT', icon: Icon(Icons.link, size: 18)),
            Tab(text: 'HEALTH', icon: Icon(Icons.favorite, size: 18)),
            Tab(text: 'HISTORY', icon: Icon(Icons.history, size: 18)),
          ],
        ),
        actions: [
          if (_connector.connectedCount > 0)
            IconButton(
              icon: const Icon(Icons.sync, color: DesignTokens.neonGreen),
              tooltip: 'Sync all devices',
              onPressed: _connector.syncAllConnected,
            ),
        ],
      ),
      body: _isInitializing
          ? const Center(
              child: CircularProgressIndicator(color: DesignTokens.neonCyan),
            )
          : Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildConnectTab(),
                      _buildHealthTab(),
                      _buildHistoryTab(),
                    ],
                  ),
                ),
                _buildDeviceQuickNav(),
              ],
            ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // QUICK NAV — Cross-link to related training & health screens
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildDeviceQuickNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: DesignTokens.bgSecondary,
        border: Border(
          top: BorderSide(color: DesignTokens.borderSubtle),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _devNavChip(Icons.fitness_center, 'Fight Camp', DesignTokens.neonAmber, rc.RouterConfig.fightCampToolsPath),
            const SizedBox(width: 8),
            _devNavChip(Icons.psychology_alt, 'AI Coach', DesignTokens.neonCyan, rc.RouterConfig.neuralCoachPath),
            const SizedBox(width: 8),
            _devNavChip(Icons.monitor_heart, 'Health', DesignTokens.neonMagenta, rc.RouterConfig.healthDashboardPath),
            const SizedBox(width: 8),
            _devNavChip(Icons.scale, 'Body', DesignTokens.neonGreen, rc.RouterConfig.bodyMonitorPath),
          ],
        ),
      ),
    );
  }

  Widget _devNavChip(IconData icon, String label, Color color, String route) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.push(route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TAB 1: CONNECT — Platform OAuth connections
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildConnectTab() {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      children: [
        // Status banner
        _buildStatusBanner(),
        const SizedBox(height: DesignTokens.spacingL),

        // Platform cards
        ...WearablePlatform.values.map(_buildPlatformCard),
      ],
    );
  }

  Widget _buildStatusBanner() {
    final count = _connector.connectedCount;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: count > 0
              ? DesignTokens.neonGreen.withValues(alpha: 0.3)
              : DesignTokens.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: count > 0
                  ? DesignTokens.neonGreen.withValues(alpha: 0.15)
                  : DesignTokens.textMuted.withValues(alpha: 0.1),
            ),
            child: Icon(
              count > 0 ? Icons.check_circle : Icons.device_hub,
              color: count > 0
                  ? DesignTokens.neonGreen
                  : DesignTokens.textMuted,
              size: 24,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count > 0
                      ? '$count DEVICE${count > 1 ? 'S' : ''} CONNECTED'
                      : 'NO DEVICES CONNECTED',
                  style: TextStyle(
                    color: count > 0
                        ? DesignTokens.neonGreen
                        : DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count > 0
                      ? 'Health data syncing automatically every 15 min'
                      : 'Connect a wearable to start tracking',
                  style: const TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: DesignTokens.fontSizeCaption,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformCard(WearablePlatform platform) {
    final state = _connector.connectionState(platform);
    final isConnected = state == WearableConnectionState.connected;
    final isBusy =
        state == WearableConnectionState.authorizing ||
        state == WearableConnectionState.exchangingToken ||
        state == WearableConnectionState.syncing;
    final isExpired = state == WearableConnectionState.tokenExpired;
    final isError = state == WearableConnectionState.error;
    final lastSync = _connector.lastSyncTime(platform);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isConnected) {
      statusColor = DesignTokens.neonGreen;
      statusText = 'Connected';
      statusIcon = Icons.check_circle;
    } else if (isBusy) {
      statusColor = DesignTokens.neonAmber;
      statusText = state == WearableConnectionState.syncing
          ? 'Syncing...'
          : 'Connecting...';
      statusIcon = Icons.sync;
    } else if (isExpired) {
      statusColor = DesignTokens.neonAmber;
      statusText = 'Token Expired';
      statusIcon = Icons.warning_amber;
    } else if (isError) {
      statusColor = DesignTokens.neonRed;
      statusText = 'Error';
      statusIcon = Icons.error_outline;
    } else {
      statusColor = DesignTokens.textMuted;
      statusText = 'Disconnected';
      statusIcon = Icons.link_off;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingM),
      child: Container(
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          border: Border.all(
            color: isConnected
                ? DesignTokens.neonGreen.withValues(alpha: 0.2)
                : DesignTokens.borderSubtle,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.cardPaddingMedium,
            vertical: DesignTokens.spacingXS,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            ),
            child: Center(
              child: Text(platform.icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          title: Text(
            platform.displayName,
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: DesignTokens.fontSizeBody,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, size: 12, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: DesignTokens.fontSizeCaption,
                    ),
                  ),
                ],
              ),
              if (lastSync != null)
                Text(
                  'Last sync: ${_timeAgo(lastSync)}',
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: DesignTokens.fontSizeMicro,
                  ),
                ),
            ],
          ),
          trailing: _buildPlatformAction(platform, state, isBusy),
        ),
      ),
    );
  }

  Widget _buildPlatformAction(
    WearablePlatform platform,
    WearableConnectionState state,
    bool isBusy,
  ) {
    if (isBusy) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: DesignTokens.neonAmber,
        ),
      );
    }

    if (state == WearableConnectionState.connected) {
      return PopupMenuButton<String>(
        icon: const Icon(
          Icons.more_vert,
          color: DesignTokens.textSecondary,
          size: 20,
        ),
        color: DesignTokens.bgCard,
        onSelected: (value) {
          if (value == 'sync') {
            _connector.pullLatest(platform);
          } else if (value == 'disconnect') {
            _showDisconnectDialog(platform);
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'sync',
            child: Row(
              children: [
                Icon(Icons.sync, size: 16, color: DesignTokens.neonCyan),
                SizedBox(width: 8),
                Text(
                  'Sync Now',
                  style: TextStyle(color: DesignTokens.textPrimary),
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'disconnect',
            child: Row(
              children: [
                Icon(Icons.link_off, size: 16, color: DesignTokens.neonRed),
                SizedBox(width: 8),
                Text(
                  'Disconnect',
                  style: TextStyle(color: DesignTokens.neonRed),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Not connected — show connect button
    if (platform == WearablePlatform.appleHealth) {
      return const Tooltip(
        message: 'iOS only',
        child: Icon(Icons.apple, color: DesignTokens.textMuted, size: 20),
      );
    }

    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: () => _startOAuthFlow(platform),
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.neonCyan.withValues(alpha: 0.15),
          foregroundColor: DesignTokens.neonCyan,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          ),
        ),
        child: const Text('Connect', style: TextStyle(fontSize: 12)),
      ),
    );
  }

  void _startOAuthFlow(WearablePlatform platform) {
    // In production: launch URL in webview/browser, handle redirect callback
    // For now: show the OAuth URL and a text field for the auth code
    final url = _connector.getAuthorizationUrl(platform);
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgCard,
        title: Text(
          'Connect ${platform.displayName}',
          style: const TextStyle(color: DesignTokens.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 1: Open this URL in your browser to authorize:',
              style: TextStyle(color: DesignTokens.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignTokens.bgSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Step 2: Paste the authorization code from the redirect:',
              style: TextStyle(color: DesignTokens.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: codeController,
              style: const TextStyle(color: DesignTokens.textPrimary),
              decoration: InputDecoration(
                hintText: 'Paste auth code here',
                hintStyle: const TextStyle(color: DesignTokens.textMuted),
                filled: true,
                fillColor: DesignTokens.bgSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: DesignTokens.borderSubtle,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: DesignTokens.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(ctx);
                _connector.exchangeAuthCode(platform, code);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.neonCyan,
              foregroundColor: DesignTokens.bgPrimary,
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showDisconnectDialog(WearablePlatform platform) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgCard,
        title: const Text(
          'Disconnect Device',
          style: TextStyle(color: DesignTokens.textPrimary),
        ),
        content: Text(
          'Disconnect ${platform.displayName}? '
          'You can reconnect at any time.',
          style: const TextStyle(color: DesignTokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: DesignTokens.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _connector.disconnect(platform);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.neonRed.withValues(alpha: 0.2),
              foregroundColor: DesignTokens.neonRed,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TAB 2: HEALTH — Merged biometric snapshot from all sources
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildHealthTab() {
    final snapshot = _connector.mergedSnapshot;

    if (snapshot == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monitor_heart_outlined,
              size: 64,
              color: DesignTokens.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: DesignTokens.spacingL),
            const Text(
              'No health data yet',
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeTitle,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingS),
            const Text(
              'Connect a wearable to see your biometrics',
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeCaption,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      children: [
        // Vital signs row
        _buildSectionHeader('VITAL SIGNS', Icons.favorite),
        const SizedBox(height: DesignTokens.spacingS),
        _buildMetricGrid([
          _MetricTile(
            'Heart Rate',
            '${snapshot.heartRate ?? '--'}',
            'bpm',
            DesignTokens.neonRed,
            Icons.favorite,
          ),
          _MetricTile(
            'Resting HR',
            '${snapshot.restingHR ?? '--'}',
            'bpm',
            DesignTokens.neonCyan,
            Icons.bedtime,
          ),
          _MetricTile(
            'HRV',
            '${snapshot.hrvMs ?? '--'}',
            'ms',
            DesignTokens.neonGreen,
            Icons.show_chart,
          ),
          _MetricTile(
            'SpO₂',
            '${snapshot.spo2 ?? '--'}',
            '%',
            DesignTokens.neonBlue,
            Icons.air,
          ),
        ]),
        const SizedBox(height: DesignTokens.spacingXL),

        // Activity
        _buildSectionHeader('ACTIVITY', Icons.directions_run),
        const SizedBox(height: DesignTokens.spacingS),
        _buildMetricGrid([
          _MetricTile(
            'Steps',
            '${snapshot.steps ?? '--'}',
            'today',
            DesignTokens.neonGreen,
            Icons.directions_walk,
          ),
          _MetricTile(
            'Calories',
            snapshot.caloriesBurned != null
                ? snapshot.caloriesBurned!.toStringAsFixed(0)
                : '--',
            'kcal',
            DesignTokens.neonAmber,
            Icons.local_fire_department,
          ),
          _MetricTile(
            'Active',
            snapshot.activeMinutes != null
                ? snapshot.activeMinutes!.toStringAsFixed(0)
                : '--',
            'min',
            DesignTokens.neonCyan,
            Icons.timer,
          ),
          _MetricTile(
            'Distance',
            snapshot.distanceKm != null
                ? snapshot.distanceKm!.toStringAsFixed(1)
                : '--',
            'km',
            DesignTokens.neonMagenta,
            Icons.map,
          ),
        ]),
        const SizedBox(height: DesignTokens.spacingXL),

        // Sleep
        _buildSectionHeader('SLEEP', Icons.bedtime),
        const SizedBox(height: DesignTokens.spacingS),
        _buildMetricGrid([
          _MetricTile(
            'Total Sleep',
            snapshot.sleepHours != null
                ? '${snapshot.sleepHours!.toStringAsFixed(1)}h'
                : '--',
            '',
            DesignTokens.neonBlue,
            Icons.nights_stay,
          ),
          _MetricTile(
            'Sleep Score',
            '${snapshot.sleepScore ?? '--'}',
            '/100',
            DesignTokens.neonCyan,
            Icons.star,
          ),
          _MetricTile(
            'REM',
            snapshot.remHours != null
                ? '${snapshot.remHours!.toStringAsFixed(1)}h'
                : '--',
            '',
            DesignTokens.neonMagenta,
            Icons.psychology,
          ),
          _MetricTile(
            'Deep',
            snapshot.deepSleepHours != null
                ? '${snapshot.deepSleepHours!.toStringAsFixed(1)}h'
                : '--',
            '',
            DesignTokens.neonGreen,
            Icons.nightlight,
          ),
        ]),
        const SizedBox(height: DesignTokens.spacingXL),

        // Recovery & Readiness
        _buildSectionHeader(
          'RECOVERY & READINESS',
          Icons.battery_charging_full,
        ),
        const SizedBox(height: DesignTokens.spacingS),
        _buildMetricGrid([
          _MetricTile(
            'Recovery',
            '${snapshot.recoveryScore ?? '--'}',
            '/100',
            DesignTokens.neonGreen,
            Icons.healing,
          ),
          _MetricTile(
            'Readiness',
            '${snapshot.readinessScore ?? '--'}',
            '/100',
            DesignTokens.neonCyan,
            Icons.fitness_center,
          ),
          _MetricTile(
            'Strain',
            '${snapshot.strainScore ?? '--'}',
            '/21',
            DesignTokens.neonAmber,
            Icons.whatshot,
          ),
          _MetricTile(
            'Resp Rate',
            snapshot.respiratoryRate != null
                ? snapshot.respiratoryRate!.toStringAsFixed(1)
                : '--',
            'br/min',
            DesignTokens.neonBlue,
            Icons.air,
          ),
        ]),
        const SizedBox(height: DesignTokens.spacingXL),

        // Body
        if (snapshot.weight != null || snapshot.bodyFat != null) ...[
          _buildSectionHeader('BODY', Icons.accessibility_new),
          const SizedBox(height: DesignTokens.spacingS),
          _buildMetricGrid([
            if (snapshot.weight != null)
              _MetricTile(
                'Weight',
                snapshot.weight!.toStringAsFixed(1),
                'kg',
                DesignTokens.textSecondary,
                Icons.monitor_weight,
              ),
            if (snapshot.bodyFat != null)
              _MetricTile(
                'Body Fat',
                snapshot.bodyFat!.toStringAsFixed(1),
                '%',
                DesignTokens.neonAmber,
                Icons.percent,
              ),
          ]),
          const SizedBox(height: DesignTokens.spacingXL),
        ],

        // Advanced biomarkers
        if (snapshot.glucose != null ||
            snapshot.lactate != null ||
            snapshot.cortisol != null) ...[
          _buildSectionHeader('ADVANCED BIOMARKERS', Icons.science),
          const SizedBox(height: DesignTokens.spacingS),
          _buildMetricGrid([
            if (snapshot.glucose != null)
              _MetricTile(
                'Glucose',
                snapshot.glucose!.toStringAsFixed(0),
                'mg/dL',
                DesignTokens.neonGreen,
                Icons.water_drop,
              ),
            if (snapshot.lactate != null)
              _MetricTile(
                'Lactate',
                snapshot.lactate!.toStringAsFixed(1),
                'mmol/L',
                DesignTokens.neonAmber,
                Icons.science,
              ),
            if (snapshot.cortisol != null)
              _MetricTile(
                'Cortisol',
                snapshot.cortisol!.toStringAsFixed(1),
                'ng/mL',
                DesignTokens.neonRed,
                Icons.psychology,
              ),
          ]),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: DesignTokens.neonCyan),
        const SizedBox(width: DesignTokens.spacingS),
        Text(
          title,
          style: const TextStyle(
            color: DesignTokens.neonCyan,
            fontSize: DesignTokens.fontSizeSubtitleLarge,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricGrid(List<_MetricTile> tiles) {
    return Wrap(
      spacing: DesignTokens.spacingM,
      runSpacing: DesignTokens.spacingM,
      children: tiles.map((tile) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 48 - 12) / 2,
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.cardPaddingSmall),
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              border: Border.all(color: tile.color.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(tile.icon, size: 14, color: tile.color),
                    const SizedBox(width: 4),
                    Text(
                      tile.label,
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeMicro,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      tile.value,
                      style: TextStyle(
                        color: tile.value == '--'
                            ? DesignTokens.textMuted
                            : DesignTokens.textPrimary,
                        fontSize: DesignTokens.fontSizeStatSmall,
                        fontWeight: DesignTokens.fontWeightStat,
                      ),
                    ),
                    if (tile.unit.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        tile.unit,
                        style: const TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: DesignTokens.fontSizeMicro,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TAB 3: HISTORY — Sync log
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildHistoryTab() {
    final history = _connector.syncHistory;

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: DesignTokens.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: DesignTokens.spacingL),
            const Text(
              'No sync history yet',
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeTitle,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.spacingS),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.cardPaddingSmall),
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              border: Border.all(
                color: entry.success
                    ? DesignTokens.neonGreen.withValues(alpha: 0.15)
                    : DesignTokens.neonRed.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Text(entry.platform.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.platform.displayName,
                        style: const TextStyle(
                          color: DesignTokens.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: DesignTokens.fontSizeBody,
                        ),
                      ),
                      Text(
                        entry.success
                            ? '${entry.dataPointsReceived} data points · ${entry.duration.inMilliseconds}ms'
                            : entry.errorMessage ?? 'Sync failed',
                        style: TextStyle(
                          color: entry.success
                              ? DesignTokens.textSecondary
                              : DesignTokens.neonRed,
                          fontSize: DesignTokens.fontSizeCaption,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      entry.success ? Icons.check_circle : Icons.error,
                      size: 16,
                      color: entry.success
                          ? DesignTokens.neonGreen
                          : DesignTokens.neonRed,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timeAgo(entry.syncedAt),
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeMicro,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═════════════════════════════════════════════════════════════════════════

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Helper data class for metric tiles ───────────────────────────────────

class _MetricTile {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const _MetricTile(this.label, this.value, this.unit, this.color, this.icon);
}
