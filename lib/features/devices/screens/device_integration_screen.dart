import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/health_data_service.dart';
import '../../../shared/services/twitter_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SMART DEVICE INTEGRATION SCREEN
/// Connects Google Fit, Apple Health, wearables, and manual input
/// ═══════════════════════════════════════════════════════════════════════════
class DeviceIntegrationScreen extends StatefulWidget {
  const DeviceIntegrationScreen({super.key});

  @override
  State<DeviceIntegrationScreen> createState() =>
      _DeviceIntegrationScreenState();
}

class _DeviceIntegrationScreenState extends State<DeviceIntegrationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late HealthDataService _healthService;

  // Third-party wearables (manual for now - not using health package)
  final bool _garminConnected = false;
  final bool _whoopConnected = false;
  final bool _ouraConnected = false;

  bool _isConnecting = false;

  // Manual input controllers
  final _heartRateCtrl = TextEditingController();
  final _bloodPressureCtrl = TextEditingController();
  final _bodyTempCtrl = TextEditingController();
  final _restingHRCtrl = TextEditingController();
  bool _isSavingManual = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _healthService = context.read<HealthDataService>();
    _initializeHealthService();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _initializeHealthService() async {
    await _healthService.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heartRateCtrl.dispose();
    _bloodPressureCtrl.dispose();
    _bodyTempCtrl.dispose();
    _restingHRCtrl.dispose();
    super.dispose();
  }

  bool get _googleFitConnected => _healthService.isGoogleFitConnected;
  bool get _appleHealthConnected => _healthService.isAppleHealthConnected;

  Future<void> _toggleGoogleFit() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _showPlatformNotSupportedDialog('Google Fit', 'Android');
      return;
    }

    setState(() => _isConnecting = true);

    if (_googleFitConnected) {
      await _healthService.disconnectGoogleFit();
    } else {
      final success = await _healthService.connectGoogleFit();
      if (!success && mounted) {
        _showConnectionErrorDialog('Google Fit');
      }
    }

    if (mounted) setState(() => _isConnecting = false);
  }

  Future<void> _toggleAppleHealth() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      _showPlatformNotSupportedDialog('Apple Health', 'iOS');
      return;
    }

    setState(() => _isConnecting = true);

    if (_appleHealthConnected) {
      await _healthService.disconnectAppleHealth();
    } else {
      final success = await _healthService.connectAppleHealth();
      if (!success && mounted) {
        _showConnectionErrorDialog('Apple Health');
      }
    }

    if (mounted) setState(() => _isConnecting = false);
  }

  Future<void> _syncNow() async {
    if (!_googleFitConnected && !_appleHealthConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No health platform connected')),
      );
      return;
    }

    setState(() => _isConnecting = true);

    final result = await _healthService.syncHealthData();

    if (mounted) {
      setState(() => _isConnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'Synced ${result.dataPointsReceived} data points'
                : 'Sync failed: ${result.errorMessage}',
          ),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showPlatformNotSupportedDialog(
    String platform,
    String requiredPlatform,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          '$platform Not Available',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          '$platform is only available on $requiredPlatform devices.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showConnectionErrorDialog(String platform) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          '$platform Connection Failed',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Could not connect to $platform. Please ensure you have granted the required permissions in your device settings.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildAppBar(),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildConnectionsTab(),
              _buildManualInputTab(),
              _buildDataTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.primaryBackground,
      expandedHeight: 130,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.green, Colors.teal],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.watch, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Smart Devices',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                'Connect your health data',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.white),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: AppTheme.cardBackground,
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
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Icon(Icons.watch, color: AppTheme.neonCyan, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'DEVICE SETUP GUIDE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _helpStep(
                      Icons.bluetooth,
                      'Connections',
                      'Link Google Fit, Apple Health, or pair via Bluetooth',
                      AppTheme.neonCyan,
                    ),
                    _helpStep(
                      Icons.edit_note,
                      'Manual Input',
                      'Enter heart rate, blood pressure & vitals manually',
                      AppTheme.neonGreen,
                    ),
                    _helpStep(
                      Icons.bar_chart,
                      'Data',
                      'View all your synced device data in one place',
                      const Color(0xFFFFB800),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          color: Colors.white54,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Need help? support@datafightcentral.com',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.green,
        labelColor: Colors.green,
        unselectedLabelColor: Colors.white54,
        tabs: const [
          Tab(icon: Icon(Icons.link, size: 18), text: 'Connections'),
          Tab(icon: Icon(Icons.edit_note, size: 18), text: 'Manual'),
          Tab(icon: Icon(Icons.data_usage, size: 18), text: 'Data'),
        ],
      ),
    );
  }

  Widget _helpStep(IconData icon, String title, String desc, Color col) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: col.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: col, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: col,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// CONNECTIONS TAB - Link devices and health platforms
  /// ═══════════════════════════════════════════════════════════════════════════
  Widget _buildConnectionsTab() {
    // Social platform stubs
    final twitter = TwitterService();
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sync Status Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withValues(alpha: 0.2),
                  Colors.teal.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.sync, color: Colors.green, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Sync Status',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Active',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Last synced: 2 minutes ago',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.cloud_done, color: Colors.green, size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      '2 devices connected',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _isConnecting ? null : _syncNow,
                      child: _isConnecting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.green,
                              ),
                            )
                          : const Text(
                              'Sync Now',
                              style: TextStyle(color: Colors.green),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Social Platforms
          const Text(
            'Social Platforms',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.facebook, color: Colors.white),
                  label: const Text('Meta (FB/IG)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Meta integration is in development — connect your IG/FB from account settings',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.alternate_email, color: Colors.white),
                  label: const Text('Twitter/X'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await twitter.connect();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Twitter/X integration is in development — follow @datafightcentral for updates',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Health Platforms
          const Text(
            'Health Platforms',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildPlatformCard(
            name: 'Google Fit',
            description: 'Steps, heart rate, workouts',
            icon: Icons.fitness_center,
            color: Colors.blue,
            connected: _googleFitConnected,
            isLoading: _isConnecting,
            onToggle: _toggleGoogleFit,
          ),
          const SizedBox(height: 12),
          _buildPlatformCard(
            name: 'Apple Health',
            description: 'Activity, sleep, vitals',
            icon: Icons.favorite,
            color: Colors.red,
            connected: _appleHealthConnected,
            isLoading: _isConnecting,
            onToggle: _toggleAppleHealth,
          ),
          const SizedBox(height: 24),

          // Wearables
          const Text(
            'Wearable Devices',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildDeviceCard(
            name: 'Garmin Watch',
            model: 'Fenix 7',
            icon: Icons.watch,
            color: Colors.orange,
            connected: _garminConnected,
            lastSync: _garminConnected ? '10 min ago' : 'Not connected',
            onToggle: () => _showWearableComingSoonDialog('Garmin'),
          ),
          const SizedBox(height: 12),
          _buildDeviceCard(
            name: 'WHOOP',
            model: '4.0 Strap',
            icon: Icons.track_changes,
            color: Colors.teal,
            connected: _whoopConnected,
            lastSync: _whoopConnected ? '2 min ago' : 'Not connected',
            onToggle: () => _showWearableComingSoonDialog('WHOOP'),
          ),
          const SizedBox(height: 12),
          _buildDeviceCard(
            name: 'Oura Ring',
            model: 'Gen 3',
            icon: Icons.radio_button_checked,
            color: Colors.purple,
            connected: _ouraConnected,
            lastSync: _ouraConnected ? '5 min ago' : 'Not connected',
            onToggle: () => _showWearableComingSoonDialog('Oura'),
          ),
          const SizedBox(height: 24),

          // Drone Command
          _buildDeviceCard(
            name: 'SkyTrack',
            model: 'Training Drone',
            icon: Icons.flight,
            color: Colors.cyan,
            connected: true,
            lastSync: 'Command Center',
            onToggle: () => context.push('/drone-command'),
          ),
          const SizedBox(height: 24),

          // Add Device Button
          OutlinedButton.icon(
            onPressed: _showAddDeviceSheet,
            icon: const Icon(Icons.add),
            label: const Text('Add New Device'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showWearableComingSoonDialog(String deviceName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          '$deviceName Integration',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Direct $deviceName integration is coming soon! For now, sync your $deviceName data through Google Fit or Apple Health.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformCard({
    required String name,
    required String description,
    required IconData icon,
    required Color color,
    required bool connected,
    required VoidCallback onToggle,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: connected
            ? Border.all(color: color.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(
                  value: connected,
                  onChanged: (_) => onToggle(),
                  activeThumbColor: color,
                ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard({
    required String name,
    required String model,
    required IconData icon,
    required Color color,
    required bool connected,
    required String lastSync,
    required VoidCallback onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: connected
            ? Border.all(color: color.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      model,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      connected ? Icons.sync : Icons.sync_disabled,
                      color: connected ? Colors.green : Colors.white38,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      lastSync,
                      style: TextStyle(
                        color: connected ? Colors.green : Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          connected
              ? IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white38),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Device settings are managed through your wearable\'s companion app',
                        ),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                )
              : TextButton(
                  onPressed: onToggle,
                  child: Text('Connect', style: TextStyle(color: color)),
                ),
        ],
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// MANUAL INPUT TAB - For users without devices
  /// ═══════════════════════════════════════════════════════════════════════════
  Widget _buildManualInputTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Camera HR Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withValues(alpha: 0.2),
                  Colors.pink.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.camera_alt, color: Colors.red, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Camera Heart Rate (PPG)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Place your fingertip over the camera to measure your heart rate using photoplethysmography.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showCameraHRScreen,
                        icon: const Icon(Icons.favorite, size: 18),
                        label: const Text('Measure HR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.white38,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'How it works',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Input Cards
          const Text(
            'Quick Log',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickInputCard(
                  'Weight',
                  Icons.monitor_weight,
                  Colors.orange,
                  '78.2 kg / 172.5 lbs',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickInputCard(
                  'Sleep',
                  Icons.bedtime,
                  Colors.purple,
                  '7h 30m',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickInputCard(
                  'Hydration',
                  Icons.water_drop,
                  Colors.blue,
                  '2.5L',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickInputCard(
                  'Mood',
                  Icons.mood,
                  Colors.green,
                  '😊 Good',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Manual Entry Form
          const Text(
            'Detailed Entry',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildManualInputField(
            'Heart Rate',
            'bpm',
            Icons.favorite,
            Colors.red,
            _heartRateCtrl,
          ),
          const SizedBox(height: 12),
          _buildManualInputField(
            'Blood Pressure',
            'mmHg',
            Icons.speed,
            Colors.blue,
            _bloodPressureCtrl,
          ),
          const SizedBox(height: 12),
          _buildManualInputField(
            'Body Temperature',
            '°F',
            Icons.thermostat,
            Colors.orange,
            _bodyTempCtrl,
          ),
          const SizedBox(height: 12),
          _buildManualInputField(
            'Resting HR',
            'bpm',
            Icons.favorite_border,
            Colors.pink,
            _restingHRCtrl,
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSavingManual ? null : _saveManualEntries,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSavingManual
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'SAVE ENTRIES',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildQuickInputCard(
    String label,
    IconData icon,
    Color color,
    String value,
  ) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label Input — connect a sensor to start tracking'),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                const Icon(Icons.edit, color: Colors.white38, size: 14),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualInputField(
    String label,
    String unit,
    IconData icon,
    Color color,
    TextEditingController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: label,
                hintStyle: const TextStyle(color: Colors.white38),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              unit,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveManualEntries() async {
    final hr = double.tryParse(_heartRateCtrl.text);
    final restingHR = double.tryParse(_restingHRCtrl.text);
    final temp = double.tryParse(_bodyTempCtrl.text);
    final bp = _bloodPressureCtrl.text.trim();

    if (hr == null && restingHR == null && temp == null && bp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter at least one field'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSavingManual = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';
      final now = DateTime.now();

      await FirebaseFirestore.instance.collection('health_metrics').add({
        'userId': uid,
        'recordedAt': Timestamp.fromDate(now),
        'source': 'manual',
        'heartRate': hr,
        'restingHeartRate': restingHR,
        'bodyTemperature': temp,
        'bloodPressure': bp.isNotEmpty ? bp : null,
        'createdAt': Timestamp.fromDate(now),
        'isVerified': false,
      });

      // Clear fields after save
      _heartRateCtrl.clear();
      _bloodPressureCtrl.clear();
      _bodyTempCtrl.clear();
      _restingHRCtrl.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Vitals saved${restingHR != null ? ' \u2014 Resting HR: ${restingHR.toInt()} bpm' : ''}',
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingManual = false);
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// DATA TAB - View and manage synced data
  /// ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDataTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data Overview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDataStat('12,450', 'Data points', Colors.blue),
                    Container(width: 1, height: 40, color: Colors.white12),
                    _buildDataStat('32', 'Days tracked', Colors.green),
                    Container(width: 1, height: 40, color: Colors.white12),
                    _buildDataStat('2.4 GB', 'Storage', Colors.orange),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Latest Readings
          const Text(
            'Latest Readings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildReadingCard(
            'Heart Rate',
            '68',
            'bpm',
            Icons.favorite,
            Colors.red,
            'Resting • Normal',
            _buildHRSparkline(),
          ),
          const SizedBox(height: 12),
          _buildReadingCard(
            'HRV',
            '52',
            'ms',
            Icons.show_chart,
            Colors.purple,
            'Good recovery',
            _buildHRVSparkline(),
          ),
          const SizedBox(height: 12),
          _buildReadingCard(
            'Sleep',
            '7h 45m',
            '',
            Icons.bedtime,
            Colors.indigo,
            '92% efficiency',
            _buildSleepSparkline(),
          ),
          const SizedBox(height: 12),
          _buildReadingCard(
            'Steps Today',
            '8,234',
            '',
            Icons.directions_walk,
            Colors.green,
            '82% of goal',
            _buildStepsSparkline(),
          ),
          const SizedBox(height: 24),

          // Data Management
          const Text(
            'Data Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildDataOption(
            'Export Data',
            'Download your health data',
            Icons.download,
            Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildDataOption(
            'Data Sources',
            'Manage connected services',
            Icons.source,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildDataOption(
            'Privacy Settings',
            'Control data sharing',
            Icons.lock,
            Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildDataOption(
            'Clear History',
            'Remove old data',
            Icons.delete_outline,
            Colors.red,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildDataStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildReadingCard(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
    String subtitle,
    Widget sparkline,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: color, fontSize: 10)),
              ],
            ),
          ),
          SizedBox(width: 80, height: 40, child: sparkline),
        ],
      ),
    );
  }

  Widget _buildHRSparkline() {
    return CustomPaint(
      painter: _SparklinePainter(
        values: [65, 68, 72, 70, 68, 66, 68],
        color: Colors.red,
      ),
    );
  }

  Widget _buildHRVSparkline() {
    return CustomPaint(
      painter: _SparklinePainter(
        values: [48, 50, 52, 49, 51, 53, 52],
        color: Colors.purple,
      ),
    );
  }

  Widget _buildSleepSparkline() {
    return CustomPaint(
      painter: _SparklinePainter(
        values: [6.5, 7.0, 7.5, 6.0, 7.75, 8.0, 7.75],
        color: Colors.indigo,
      ),
    );
  }

  Widget _buildStepsSparkline() {
    return CustomPaint(
      painter: _SparklinePainter(
        values: [6500, 8000, 7500, 9200, 8500, 10000, 8234],
        color: Colors.green,
      ),
    );
  }

  Widget _buildDataOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );
  }

  void _showAddDeviceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Device',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildDeviceTypeOption('Smart Watch', Icons.watch, Colors.blue),
                _buildDeviceTypeOption(
                  'Fitness Band',
                  Icons.track_changes,
                  Colors.green,
                ),
                _buildDeviceTypeOption(
                  'Heart Rate Monitor',
                  Icons.favorite,
                  Colors.red,
                ),
                _buildDeviceTypeOption(
                  'Smart Scale',
                  Icons.monitor_weight,
                  Colors.orange,
                ),
                _buildDeviceTypeOption(
                  'Sleep Tracker',
                  Icons.bedtime,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceTypeOption(String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCameraHRScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Heart Rate Measurement',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 3),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fingerprint, color: Colors.red, size: 60),
                      SizedBox(height: 8),
                      Text(
                        'Place finger here',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Cover the camera with your fingertip\nKeep still for 30 seconds',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'START MEASUREMENT',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// SPARKLINE PAINTER
/// ═══════════════════════════════════════════════════════════════════════════
class _SparklinePainter extends CustomPainter {
  final List<num> values;
  final Color color;

  _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final minVal = values.reduce(math.min).toDouble();
    final maxVal = values.reduce(math.max).toDouble();
    final range = maxVal - minVal;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final stepX = size.width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = range == 0
          ? size.height / 2
          : size.height - ((values[i] - minVal) / range * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw end dot
    final lastX = size.width;
    final lastY = range == 0
        ? size.height / 2
        : size.height - ((values.last - minVal) / range * size.height);

    canvas.drawCircle(Offset(lastX, lastY), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
