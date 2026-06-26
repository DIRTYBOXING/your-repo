import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════
/// DRONE COMMAND CENTER v1.0
/// "SkyTrack" — Autonomous Training Drone Control
///
/// Supported Technologies:
/// • DJI ActiveTrack (Mavic 3, Air 3, Mini 4 Pro)
/// • Skydio Autonomy (Skydio 2+, X10)
/// • DroneKit / MAVLink (ArduPilot custom builds)
/// • Parrot ANAFI (FreeFlight SDK)
///
/// Communication Protocols:
/// • WiFi Direct → Drone SDK bridge
/// • GPS Follow-Me → Phone broadcasts coords
/// • MAVLink → Waypoint commands over UDP
/// • RTSP/RTMP → Live video stream
/// ═══════════════════════════════════════════════════════════════
class DroneCommandScreen extends StatefulWidget {
  const DroneCommandScreen({super.key});

  @override
  State<DroneCommandScreen> createState() => _DroneCommandScreenState();
}

class _DroneCommandScreenState extends State<DroneCommandScreen>
    with TickerProviderStateMixin {
  // ── State ──
  bool _isConnected = false;
  bool _isFollowing = false;
  bool _isRecording = false;
  bool _isSearching = false;
  int _selectedDroneIndex = -1;
  double _altitude = 15.0; // meters
  double _followDistance = 8.0; // meters
  double _followSpeed = 12.0; // km/h max
  int _cameraAngle = 1; // 0=front, 1=45°, 2=side, 3=overhead
  String _recordingTime = '00:00';
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  int _batteryLevel = 87;
  int _signalStrength = 4; // out of 5
  int _satellites = 0;
  String _flightMode = 'STANDBY';

  // ── Animations ──
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late AnimationController _radarController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _radarAnimation;

  // ── Mock detected drones ──
  final List<_DetectedDrone> _detectedDrones = [];

  // ── Camera angles ──
  final List<String> _cameraAngles = [
    'Front Chase',
    '45° Cinematic',
    'Side Profile',
    'Overhead Bird',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(_pulseController);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    // _scanAnimation removed as unused

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _radarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_radarController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    _radarController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _isSearching = true;
      _detectedDrones.clear();
    });
    _scanController.forward(from: 0);

    // Simulate finding drones
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _detectedDrones.add(
            const _DetectedDrone(
              name: 'DJI Mavic 3 Pro',
              brand: 'DJI',
              protocol: 'ActiveTrack 5.0',
              signal: 5,
              battery: 92,
              icon: Icons.flight,
              color: DesignTokens.neonCyan,
            ),
          );
        });
      }
    });
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() {
          _detectedDrones.add(
            const _DetectedDrone(
              name: 'Skydio 2+',
              brand: 'Skydio',
              protocol: 'Autonomy AI',
              signal: 4,
              battery: 78,
              icon: Icons.airplanemode_active,
              color: DesignTokens.neonGreen,
            ),
          );
        });
      }
    });
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) {
        setState(() {
          _detectedDrones.add(
            const _DetectedDrone(
              name: 'ArduPilot Custom',
              brand: 'MAVLink',
              protocol: 'DroneKit GPS',
              signal: 3,
              battery: 65,
              icon: Icons.settings_input_antenna,
              color: DesignTokens.neonAmber,
            ),
          );
        });
      }
    });
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    });
  }

  void _connectDrone(int index) {
    setState(() {
      _selectedDroneIndex = index;
      _isConnected = true;
      _batteryLevel = _detectedDrones[index].battery;
      _signalStrength = _detectedDrones[index].signal;
      _satellites = 14;
      _flightMode = 'CONNECTED';
    });
  }

  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
      if (_isFollowing) {
        _flightMode = 'FOLLOW ME';
      } else {
        _flightMode = 'HOVER';
      }
    });
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        _recordingSeconds = 0;
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingSeconds++;
            final mins = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
            final secs = (_recordingSeconds % 60).toString().padLeft(2, '0');
            _recordingTime = '$mins:$secs';
          });
        });
      } else {
        _recordingTimer?.cancel();
      }
    });
  }

  void _disconnect() {
    setState(() {
      _isConnected = false;
      _isFollowing = false;
      _isRecording = false;
      _selectedDroneIndex = -1;
      _recordingTimer?.cancel();
      _recordingTime = '00:00';
      _recordingSeconds = 0;
      _flightMode = 'STANDBY';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(child: _buildBody()),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════
  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: DesignTokens.bgPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (_isConnected)
          _buildTelemetryChip(
            Icons.battery_charging_full,
            '$_batteryLevel%',
            _batteryLevel > 30 ? DesignTokens.neonGreen : DesignTokens.neonRed,
          ),
        if (_isConnected)
          _buildTelemetryChip(
            Icons.signal_cellular_alt,
            '$_signalStrength/5',
            _signalStrength > 2
                ? DesignTokens.neonCyan
                : DesignTokens.neonAmber,
          ),
        if (_isConnected)
          _buildTelemetryChip(
            Icons.satellite_alt,
            '$_satellites GPS',
            DesignTokens.neonGreen,
          ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DesignTokens.bgPrimary,
                Color(0xFF0A1A2E),
                DesignTokens.bgPrimary,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Grid overlay
              CustomPaint(painter: _GridPainter(), size: Size.infinite),
              // Radar sweep
              if (_isSearching || _isFollowing)
                Center(
                  child: AnimatedBuilder(
                    animation: _radarAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _RadarPainter(
                          sweep: _radarAnimation.value,
                          color: _isFollowing
                              ? DesignTokens.neonGreen
                              : DesignTokens.neonCyan,
                        ),
                        size: const Size(160, 160),
                      );
                    },
                  ),
                ),
              // Title content
              Positioned(
                bottom: 60,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.flight_takeoff,
                          color: _isFollowing
                              ? DesignTokens.neonGreen
                              : DesignTokens.neonCyan,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'SKYTRACK',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: _isFollowing
                                ? DesignTokens.neonGreen
                                : DesignTokens.neonCyan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Autonomous Training Drone Control',
                      style: TextStyle(
                        fontSize: 13,
                        color: DesignTokens.textMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Flight mode badge
              Positioned(
                bottom: 60,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getFlightModeColor().withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getFlightModeColor().withValues(alpha: 0.5),
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
                          color: _getFlightModeColor(),
                          boxShadow: [
                            BoxShadow(
                              color: _getFlightModeColor().withValues(
                                alpha: 0.6,
                              ),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _flightMode,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _getFlightModeColor(),
                          letterSpacing: 1,
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
    );
  }

  Widget _buildTelemetryChip(IconData icon, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getFlightModeColor() {
    switch (_flightMode) {
      case 'FOLLOW ME':
        return DesignTokens.neonGreen;
      case 'HOVER':
        return DesignTokens.neonAmber;
      case 'CONNECTED':
        return DesignTokens.neonCyan;
      case 'RECORDING':
        return DesignTokens.neonRed;
      default:
        return DesignTokens.textMuted;
    }
  }

  // ═══════════════════════════════════════════════════
  // BODY
  // ═══════════════════════════════════════════════════
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          if (!_isConnected) ...[
            _buildScanSection(),
            if (_detectedDrones.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildDetectedDrones(),
            ],
            const SizedBox(height: 24),
            _buildCompatibleDrones(),
          ] else ...[
            _buildConnectedDroneCard(),
            const SizedBox(height: 16),
            _buildFollowMeButton(),
            const SizedBox(height: 16),
            _buildVideoFeed(),
            const SizedBox(height: 16),
            _buildFlightControls(),
            const SizedBox(height: 16),
            _buildCameraControls(),
            const SizedBox(height: 16),
            _buildTrainingModes(),
            const SizedBox(height: 16),
            _buildTelemetryPanel(),
            const SizedBox(height: 16),
            _buildFlightLog(),
            const SizedBox(height: 16),
            _buildAITrainingInsights(),
            const SizedBox(height: 16),
            _buildSocialShare(),
          ],
          const SizedBox(height: 20),
          _buildTechStack(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // SCAN SECTION
  // ═══════════════════════════════════════════════════
  Widget _buildScanSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          // Radar animation
          SizedBox(
            height: 140,
            width: 140,
            child: AnimatedBuilder(
              animation: _radarAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _RadarPainter(
                    sweep: _radarAnimation.value,
                    color: _isSearching
                        ? DesignTokens.neonCyan
                        : DesignTokens.textMuted,
                  ),
                  child: Center(
                    child: Icon(
                      _isSearching ? Icons.radar : Icons.flight_takeoff,
                      size: 36,
                      color: _isSearching
                          ? DesignTokens.neonCyan
                          : DesignTokens.textMuted,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isSearching ? 'SCANNING FOR DRONES...' : 'SCAN NEARBY DRONES',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _isSearching
                  ? DesignTokens.neonCyan
                  : DesignTokens.textPrimary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Make sure your drone is powered on and WiFi is enabled',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: DesignTokens.textMuted),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSearching ? null : _startScan,
              icon: Icon(_isSearching ? Icons.radar : Icons.search, size: 20),
              label: Text(
                _isSearching ? 'SCANNING...' : 'SCAN FOR DRONES',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.neonCyan.withValues(alpha: 0.15),
                foregroundColor: DesignTokens.neonCyan,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // DETECTED DRONES
  // ═══════════════════════════════════════════════════
  Widget _buildDetectedDrones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.wifi_tethering, size: 18, color: DesignTokens.neonGreen),
            const SizedBox(width: 8),
            Text(
              'DETECTED (${_detectedDrones.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: DesignTokens.neonGreen,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._detectedDrones.asMap().entries.map((entry) {
          final i = entry.key;
          final drone = entry.value;
          return _buildDroneCard(drone, i);
        }),
      ],
    );
  }

  Widget _buildDroneCard(_DetectedDrone drone, int index) {
    final isSelected = _selectedDroneIndex == index;
    return GestureDetector(
      onTap: () => _connectDrone(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? drone.color.withValues(alpha: 0.1)
              : DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? drone.color.withValues(alpha: 0.5)
                : DesignTokens.neonCyan.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: drone.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(drone.icon, color: drone.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drone.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    drone.protocol,
                    style: TextStyle(
                      fontSize: 12,
                      color: drone.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.battery_std,
                      size: 14,
                      color: DesignTokens.neonGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${drone.battery}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: DesignTokens.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    return Icon(
                      Icons.signal_cellular_alt,
                      size: 10,
                      color: i < drone.signal
                          ? DesignTokens.neonCyan
                          : DesignTokens.textDisabled,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: drone.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: drone.color.withValues(alpha: 0.4)),
              ),
              child: Text(
                'CONNECT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: drone.color,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // CONNECTED DRONE CARD
  // ═══════════════════════════════════════════════════
  Widget _buildConnectedDroneCard() {
    final drone = _detectedDrones[_selectedDroneIndex];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [drone.color.withValues(alpha: 0.1), DesignTokens.bgCard],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: drone.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: drone.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: drone.color.withValues(alpha: 0.3)),
            ),
            child: Icon(drone.icon, color: drone.color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      drone.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DesignTokens.neonGreen,
                        boxShadow: [
                          BoxShadow(
                            color: DesignTokens.neonGreen.withValues(
                              alpha: 0.6,
                            ),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${drone.protocol} • Connected',
                  style: const TextStyle(fontSize: 12, color: DesignTokens.neonGreen),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _disconnect,
            icon: const Icon(Icons.link_off, color: DesignTokens.neonRed),
            tooltip: 'Disconnect',
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // FOLLOW ME BUTTON (Main CTA)
  // ═══════════════════════════════════════════════════
  Widget _buildFollowMeButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = _isFollowing ? _pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale * 0.95 + 0.05,
          child: GestureDetector(
            onTap: _toggleFollow,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isFollowing
                      ? [
                          DesignTokens.neonGreen.withValues(alpha: 0.2),
                          const Color(0xFF002200),
                        ]
                      : [
                          DesignTokens.neonCyan.withValues(alpha: 0.15),
                          DesignTokens.bgCard,
                        ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isFollowing
                      ? DesignTokens.neonGreen.withValues(alpha: 0.6)
                      : DesignTokens.neonCyan.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: _isFollowing
                    ? [
                        BoxShadow(
                          color: DesignTokens.neonGreen.withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Icon(
                    _isFollowing ? Icons.gps_fixed : Icons.gps_not_fixed,
                    size: 48,
                    color: _isFollowing
                        ? DesignTokens.neonGreen
                        : DesignTokens.neonCyan,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isFollowing ? 'FOLLOWING YOU' : 'FOLLOW ME',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: _isFollowing
                          ? DesignTokens.neonGreen
                          : DesignTokens.neonCyan,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isFollowing
                        ? 'Drone is tracking your GPS • Tap to stop'
                        : 'Tap to activate autonomous follow mode',
                    style: const TextStyle(
                      fontSize: 12,
                      color: DesignTokens.textMuted,
                    ),
                  ),
                  if (_isFollowing) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLiveStat(
                          'ALT',
                          '${_altitude.toInt()}m',
                          DesignTokens.neonCyan,
                        ),
                        const SizedBox(width: 20),
                        _buildLiveStat(
                          'DIST',
                          '${_followDistance.toInt()}m',
                          DesignTokens.neonAmber,
                        ),
                        const SizedBox(width: 20),
                        _buildLiveStat(
                          'SPD',
                          '${_followSpeed.toInt()} km/h',
                          DesignTokens.neonGreen,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiveStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: DesignTokens.textMuted,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // VIDEO FEED / RECORDING
  // ═══════════════════════════════════════════════════
  Widget _buildVideoFeed() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isRecording
              ? DesignTokens.neonRed.withValues(alpha: 0.6)
              : DesignTokens.neonCyan.withValues(alpha: 0.15),
          width: _isRecording ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          // Simulated video feed
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam,
                  size: 40,
                  color: DesignTokens.textMuted.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  _isFollowing ? 'LIVE DRONE CAMERA FEED' : 'CAMERA STANDBY',
                  style: const TextStyle(
                    fontSize: 12,
                    color: DesignTokens.textMuted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'RTSP stream from drone camera',
                  style: TextStyle(
                    fontSize: 10,
                    color: DesignTokens.textDisabled,
                  ),
                ),
              ],
            ),
          ),
          // Camera angle badge
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _cameraAngles[_cameraAngle],
                style: const TextStyle(
                  fontSize: 10,
                  color: DesignTokens.neonCyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Recording indicator
          if (_isRecording)
            Positioned(
              top: 12,
              right: 12,
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _pulseAnimation.value > 1.0 ? 1.0 : 0.3,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: DesignTokens.neonRed,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'REC $_recordingTime',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.neonRed,
                    ),
                  ),
                ],
              ),
            ),
          // Record button
          Positioned(
            bottom: 12,
            right: 12,
            child: GestureDetector(
              onTap: _toggleRecording,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording
                      ? DesignTokens.neonRed.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.1),
                  border: Border.all(
                    color: _isRecording
                        ? DesignTokens.neonRed
                        : Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: _isRecording
                      ? Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: DesignTokens.neonRed,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        )
                      : Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: DesignTokens.neonRed,
                          ),
                        ),
                ),
              ),
            ),
          ),
          // Snapshot button
          Positioned(
            bottom: 12,
            right: 70,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📸 Snapshot saved to gallery'),
                    backgroundColor: DesignTokens.bgSecondary,
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // FLIGHT CONTROLS (Altitude, Distance, Speed)
  // ═══════════════════════════════════════════════════
  Widget _buildFlightControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, size: 18, color: DesignTokens.neonCyan),
              SizedBox(width: 8),
              Text(
                'FLIGHT PARAMETERS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.neonCyan,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSlider(
            'FOLLOW ALTITUDE',
            _altitude,
            5,
            50,
            'm',
            DesignTokens.neonCyan,
            Icons.height,
            (v) => setState(() => _altitude = v),
          ),
          const SizedBox(height: 16),
          _buildSlider(
            'FOLLOW DISTANCE',
            _followDistance,
            3,
            25,
            'm',
            DesignTokens.neonAmber,
            Icons.social_distance,
            (v) => setState(() => _followDistance = v),
          ),
          const SizedBox(height: 16),
          _buildSlider(
            'MAX SPEED',
            _followSpeed,
            5,
            30,
            'km/h',
            DesignTokens.neonGreen,
            Icons.speed,
            (v) => setState(() => _followSpeed = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    String unit,
    Color color,
    IconData icon,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textMuted,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Text(
              '${value.toInt()} $unit',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.15),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.1),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // CAMERA ANGLE CONTROLS
  // ═══════════════════════════════════════════════════
  Widget _buildCameraControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DesignTokens.neonMagenta.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.videocam, size: 18, color: DesignTokens.neonMagenta),
              SizedBox(width: 8),
              Text(
                'CAMERA ANGLE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.neonMagenta,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: _cameraAngles.asMap().entries.map((entry) {
              final i = entry.key;
              final angle = entry.value;
              final isSelected = _cameraAngle == i;
              final icons = [
                Icons.arrow_forward,
                Icons.north_east,
                Icons.arrow_upward,
                Icons.flight,
              ];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _cameraAngle = i),
                  child: Container(
                    margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? DesignTokens.neonMagenta.withValues(alpha: 0.15)
                          : DesignTokens.bgSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? DesignTokens.neonMagenta.withValues(alpha: 0.5)
                            : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          icons[i],
                          size: 20,
                          color: isSelected
                              ? DesignTokens.neonMagenta
                              : DesignTokens.textMuted,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          angle.split(' ').first,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? DesignTokens.neonMagenta
                                : DesignTokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // TRAINING MODES
  // ═══════════════════════════════════════════════════
  Widget _buildTrainingModes() {
    final modes = [
      const _TrainingMode(
        'Road Run',
        'Chase cam for outdoor running',
        Icons.directions_run,
        DesignTokens.neonGreen,
        'GPS follow at 15m altitude',
      ),
      const _TrainingMode(
        'Pad Work',
        'Overhead static for technique',
        Icons.sports_mma,
        DesignTokens.neonRed,
        'Hover overhead at 5m',
      ),
      const _TrainingMode(
        'Sparring',
        'Multi-angle orbit recording',
        Icons.sports_kabaddi,
        DesignTokens.neonAmber,
        'Orbit mode, 8m radius',
      ),
      const _TrainingMode(
        'Vlog Mode',
        'Front-facing follow for talking',
        Icons.mic,
        DesignTokens.neonMagenta,
        'Front chase, eye-level',
      ),
      const _TrainingMode(
        'Highlight Reel',
        'Auto-edit best moments',
        Icons.auto_awesome,
        DesignTokens.neonCyan,
        'AI clip detection + export',
      ),
      const _TrainingMode(
        'Cinematic',
        'Pro drone shots for promos',
        Icons.movie_creation,
        Color(0xFFFFD700),
        'Dolly zoom, reveal shots',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DesignTokens.neonGreen.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.category, size: 18, color: DesignTokens.neonGreen),
              SizedBox(width: 8),
              Text(
                'TRAINING MODES',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.neonGreen,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: modes.length,
            itemBuilder: (context, i) {
              final mode = modes[i];
              return GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${mode.name}: ${mode.description}'),
                      backgroundColor: DesignTokens.bgSecondary,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: mode.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: mode.color.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(mode.icon, size: 28, color: mode.color),
                      const SizedBox(height: 8),
                      Text(
                        mode.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mode.preset,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 8,
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // TELEMETRY PANEL
  // ═══════════════════════════════════════════════════
  Widget _buildTelemetryPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DesignTokens.neonAmber.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.speed, size: 18, color: DesignTokens.neonAmber),
              SizedBox(width: 8),
              Text(
                'LIVE TELEMETRY',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.neonAmber,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTelemetryItem(
                'Altitude',
                '${_altitude.toInt()}m',
                Icons.height,
                DesignTokens.neonCyan,
              ),
              _buildTelemetryItem(
                'Speed',
                _isFollowing
                    ? '${(_followSpeed * 0.7).toStringAsFixed(1)} km/h'
                    : '0.0 km/h',
                Icons.speed,
                DesignTokens.neonGreen,
              ),
              _buildTelemetryItem(
                'Distance',
                '${_followDistance.toInt()}m',
                Icons.social_distance,
                DesignTokens.neonAmber,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTelemetryItem(
                'Battery',
                '$_batteryLevel%',
                Icons.battery_charging_full,
                _batteryLevel > 30
                    ? DesignTokens.neonGreen
                    : DesignTokens.neonRed,
              ),
              _buildTelemetryItem(
                'GPS Sats',
                '$_satellites',
                Icons.satellite_alt,
                DesignTokens.neonCyan,
              ),
              _buildTelemetryItem(
                'Flight Time',
                _isFollowing ? _recordingTime : '00:00',
                Icons.timer,
                DesignTokens.neonMagenta,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: DesignTokens.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // COMPATIBLE DRONES LIST
  // ═══════════════════════════════════════════════════
  Widget _buildCompatibleDrones() {
    final drones = [
      const _CompatibleDrone(
        'DJI Mavic 3 Pro',
        'ActiveTrack 5.0 — Vision-based autonomous follow with obstacle avoidance. '
            'Best for outdoor running/training. WiFi SDK connection.',
        'DJI Mobile SDK (iOS/Android platform channels)',
        Icons.flight,
        DesignTokens.neonCyan,
        '\$2,199',
        ['46 min flight', 'Hasselblad cam', 'APAS 5.0', '4K/120fps'],
      ),
      const _CompatibleDrone(
        'Skydio 2+',
        'Best autonomous follow drone. 360° obstacle avoidance. Tracks through trees '
            'and buildings. GPS + Visual follow.',
        'Skydio SDK (REST API + WebSocket)',
        Icons.airplanemode_active,
        DesignTokens.neonGreen,
        '\$1,099',
        ['27 min flight', '4K/60fps', 'AI tracking', 'KeyFrame'],
      ),
      const _CompatibleDrone(
        'DJI Air 3',
        'Dual-camera system with ActiveTrack. Compact form factor '
            'ideal for training sessions. Great wind resistance.',
        'DJI Mobile SDK',
        Icons.flight,
        DesignTokens.neonAmber,
        '\$1,099',
        ['46 min flight', 'Dual cam', '4K/100fps', 'APAS 4.0'],
      ),
      const _CompatibleDrone(
        'DJI Mini 4 Pro',
        'Sub-250g follow-me drone. No registration required in many countries. '
            'ActiveTrack with omnidirectional sensing.',
        'DJI Mobile SDK',
        Icons.flight,
        DesignTokens.neonMagenta,
        '\$759',
        ['34 min flight', '4K/100fps', '<249g', 'Omnisensing'],
      ),
      const _CompatibleDrone(
        'ArduPilot Custom',
        'Open-source MAVLink protocol. Build your own follow-me drone. '
            'GPS-based following via DroneKit + phone coordinates.',
        'DroneKit Python / MAVLink (UDP/WebSocket)',
        Icons.settings_input_antenna,
        Color(0xFFFFD700),
        'DIY',
        ['Custom flight', 'Open source', 'GPS follow', 'MAVLink'],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.devices_other,
              size: 18,
              color: DesignTokens.textSecondary,
            ),
            SizedBox(width: 8),
            Text(
              'COMPATIBLE DRONES',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: DesignTokens.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...drones.map(_buildCompatibleDroneCard),
      ],
    );
  }

  Widget _buildCompatibleDroneCard(_CompatibleDrone drone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: drone.color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: drone.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(drone.icon, color: drone.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drone.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.textPrimary,
                      ),
                    ),
                    Text(
                      drone.price,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: drone.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            drone.description,
            style: const TextStyle(
              fontSize: 12,
              color: DesignTokens.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: drone.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'SDK: ${drone.sdk}',
              style: TextStyle(
                fontSize: 10,
                color: drone.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: drone.specs.map((spec) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DesignTokens.bgSecondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  spec,
                  style: const TextStyle(
                    fontSize: 10,
                    color: DesignTokens.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // FLIGHT LOG HISTORY
  // ═══════════════════════════════════════════════════
  Widget _buildFlightLog() {
    final logs = [
      const _FlightLog(
        'Morning Road Run',
        'Today',
        '12:34',
        '3.8 km',
        '87%',
        DesignTokens.neonGreen,
        Icons.directions_run,
      ),
      const _FlightLog(
        'Pad Work Session',
        'Yesterday',
        '08:15',
        '—',
        '92%',
        DesignTokens.neonRed,
        Icons.sports_mma,
      ),
      const _FlightLog(
        'Sparring Highlight',
        '2 days ago',
        '22:47',
        '—',
        '78%',
        DesignTokens.neonAmber,
        Icons.sports_kabaddi,
      ),
      const _FlightLog(
        '5K Training Run',
        '3 days ago',
        '25:12',
        '5.1 km',
        '65%',
        DesignTokens.neonCyan,
        Icons.directions_run,
      ),
      const _FlightLog(
        'Cinematic Promo',
        '1 week ago',
        '06:30',
        '—',
        '94%',
        Color(0xFFFFD700),
        Icons.movie_creation,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 18, color: DesignTokens.neonCyan),
              const SizedBox(width: 8),
              const Text(
                'FLIGHT LOG',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.neonCyan,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${logs.length} FLIGHTS',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.neonCyan,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats summary row
          Row(
            children: [
              _buildLogStat('Total Time', '1h 15m', DesignTokens.neonCyan),
              _buildLogStat('Distance', '8.9 km', DesignTokens.neonGreen),
              _buildLogStat('Clips', '23', DesignTokens.neonMagenta),
              _buildLogStat('Best', '94%', const Color(0xFFFFD700)),
            ],
          ),
          const SizedBox(height: 16),
          ...logs.map(_buildFlightLogItem),
        ],
      ),
    );
  }

  Widget _buildLogStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: DesignTokens.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlightLogItem(_FlightLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: log.color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: log.color.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: log.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(log.icon, color: log.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textPrimary,
                  ),
                ),
                Text(
                  log.date,
                  style: const TextStyle(fontSize: 10, color: DesignTokens.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                log.duration,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textSecondary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (log.distance != '—') ...[
                    Text(
                      log.distance,
                      style: const TextStyle(
                        fontSize: 10,
                        color: DesignTokens.neonGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(Icons.battery_std, size: 10, color: log.color),
                  const SizedBox(width: 2),
                  Text(
                    log.battery,
                    style: const TextStyle(
                      fontSize: 10,
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.play_circle_outline,
            size: 22,
            color: log.color.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // AI TRAINING INSIGHTS
  // ═══════════════════════════════════════════════════
  Widget _buildAITrainingInsights() {
    final insights = [
      const _Insight(
        'Form Analysis',
        'AI detected your guard drops 23% during round 3. '
            'Drone footage shows right hand lowering after combinations.',
        Icons.analytics,
        DesignTokens.neonCyan,
        'TECHNIQUE',
        87,
      ),
      const _Insight(
        'Running Pace',
        'Your pace improved 8% this week. Drone GPS tracking shows '
            'consistent 4:32/km splits on hill segments.',
        Icons.speed,
        DesignTokens.neonGreen,
        'CARDIO',
        92,
      ),
      const _Insight(
        'Footwork Pattern',
        'Overhead drone view reveals lateral movement bias. '
            'You circle left 73% of the time — mix directions for unpredictability.',
        Icons.directions_walk,
        DesignTokens.neonAmber,
        'MOVEMENT',
        68,
      ),
      const _Insight(
        'Recovery Zones',
        'Heart rate data + drone footage correlation: you recover faster '
            'with active shadow boxing vs static rest between rounds.',
        Icons.favorite,
        DesignTokens.neonRed,
        'RECOVERY',
        78,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.neonMagenta.withValues(alpha: 0.05),
            DesignTokens.bgCard,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DesignTokens.neonMagenta.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, size: 18, color: DesignTokens.neonMagenta),
              const SizedBox(width: 8),
              const Text(
                'AI TRAINING INSIGHTS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.neonMagenta,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DesignTokens.neonMagenta.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: DesignTokens.neonMagenta,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.neonMagenta,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Powered by drone footage + combat analytics',
            style: TextStyle(fontSize: 11, color: DesignTokens.textMuted),
          ),
          const SizedBox(height: 16),
          ...insights.map(_buildInsightCard),
        ],
      ),
    );
  }

  Widget _buildInsightCard(_Insight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: insight.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: insight.color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: insight.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(insight.icon, color: insight.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.textPrimary,
                      ),
                    ),
                    Text(
                      insight.category,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: insight.color,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              // Score ring
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: insight.score / 100,
                      strokeWidth: 3,
                      backgroundColor: insight.color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(insight.color),
                    ),
                    Text(
                      '${insight.score}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: insight.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            insight.description,
            style: const TextStyle(
              fontSize: 11,
              color: DesignTokens.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // SOCIAL SHARE & EXPORT
  // ═══════════════════════════════════════════════════
  Widget _buildSocialShare() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.share, size: 18, color: Color(0xFFFFD700)),
              SizedBox(width: 8),
              Text(
                'SHARE & EXPORT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFD700),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildShareOption(
            'Auto-Edit Highlight Reel',
            'AI cuts your best moments into a 30-60s clip with music',
            Icons.auto_awesome_mosaic,
            DesignTokens.neonMagenta,
          ),
          _buildShareOption(
            'Post to DFC Feed',
            'Share drone footage directly to your DataFightCentral timeline',
            Icons.dynamic_feed,
            DesignTokens.neonCyan,
          ),
          _buildShareOption(
            'Export Raw Footage',
            'Download full unedited drone recording to device',
            Icons.download,
            DesignTokens.neonGreen,
          ),
          _buildShareOption(
            'Training Report',
            'Generate PDF with drone analytics, GPS map, and AI insights',
            Icons.picture_as_pdf,
            DesignTokens.neonAmber,
          ),
          const SizedBox(height: 12),
          // Export all button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Exporting training footage + analytics...',
                    ),
                    backgroundColor: DesignTokens.bgSecondary,
                  ),
                );
              },
              icon: const Icon(Icons.cloud_upload, size: 18),
              label: const Text(
                'EXPORT ALL TO CLOUD',
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFFFFD700,
                ).withValues(alpha: 0.15),
                foregroundColor: const Color(0xFFFFD700),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(title),
            backgroundColor: DesignTokens.bgSecondary,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
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
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: color.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // TECH STACK INFO
  // ═══════════════════════════════════════════════════
  Widget _buildTechStack() {
    final techs = [
      const _TechItem(
        'GPS Follow-Me',
        'Phone broadcasts GPS coordinates via geolocator package. '
            'Drone receives waypoints and follows in real-time.',
        Icons.gps_fixed,
        DesignTokens.neonGreen,
        'Ready — uses phone GPS',
      ),
      const _TechItem(
        'DJI ActiveTrack',
        'Vision-based AI tracking. Drone camera locks onto you and follows '
            'autonomously with obstacle avoidance (APAS).',
        Icons.visibility,
        DesignTokens.neonCyan,
        'DJI Mobile SDK → Platform Channels',
      ),
      const _TechItem(
        'Skydio Autonomy',
        'Industry-best autonomous follow. 360° obstacle avoidance AI. '
            'Tracks through trees, under bridges, between buildings.',
        Icons.auto_awesome,
        DesignTokens.neonMagenta,
        'REST API + WebSocket bridge',
      ),
      const _TechItem(
        'MAVLink / DroneKit',
        'Open-source protocol for ArduPilot drones. Send GPS waypoints '
            'over UDP. Full telemetry and mission planning.',
        Icons.settings_input_antenna,
        DesignTokens.neonAmber,
        'dart:io UDP sockets + MAVLink parser',
      ),
      const _TechItem(
        'RTSP Video Stream',
        'Live drone camera feed via RTSP/RTMP protocol. '
            'Rendered in Flutter using flutter_vlc_player or video_player.',
        Icons.videocam,
        DesignTokens.neonRed,
        'flutter_vlc_player for RTSP',
      ),
      const _TechItem(
        'Training AI',
        'Auto-detect training highlights. Clip best moments. '
            'Combine with combat analytics for form analysis overlays.',
        Icons.psychology,
        Color(0xFFFFD700),
        'Firebase ML + on-device inference',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.developer_board,
                size: 18,
                color: DesignTokens.neonCyan,
              ),
              SizedBox(width: 8),
              Text(
                'HOW IT WORKS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.neonCyan,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Technologies powering autonomous drone follow',
            style: TextStyle(fontSize: 12, color: DesignTokens.textMuted),
          ),
          const SizedBox(height: 16),
          ...techs.map(_buildTechCard),
        ],
      ),
    );
  }

  Widget _buildTechCard(_TechItem tech) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tech.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tech.color.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tech.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(tech.icon, color: tech.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tech.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tech.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: DesignTokens.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: tech.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tech.integration,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: tech.color,
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
}

// ═══════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════
class _DetectedDrone {
  final String name;
  final String brand;
  final String protocol;
  final int signal;
  final int battery;
  final IconData icon;
  final Color color;

  const _DetectedDrone({
    required this.name,
    required this.brand,
    required this.protocol,
    required this.signal,
    required this.battery,
    required this.icon,
    required this.color,
  });
}

class _TrainingMode {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String preset;

  const _TrainingMode(
    this.name,
    this.description,
    this.icon,
    this.color,
    this.preset,
  );
}

class _CompatibleDrone {
  final String name;
  final String description;
  final String sdk;
  final IconData icon;
  final Color color;
  final String price;
  final List<String> specs;

  const _CompatibleDrone(
    this.name,
    this.description,
    this.sdk,
    this.icon,
    this.color,
    this.price,
    this.specs,
  );
}

class _TechItem {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String integration;

  const _TechItem(
    this.name,
    this.description,
    this.icon,
    this.color,
    this.integration,
  );
}

class _FlightLog {
  final String title;
  final String date;
  final String duration;
  final String distance;
  final String battery;
  final Color color;
  final IconData icon;

  const _FlightLog(
    this.title,
    this.date,
    this.duration,
    this.distance,
    this.battery,
    this.color,
    this.icon,
  );
}

class _Insight {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String category;
  final int score;

  const _Insight(
    this.title,
    this.description,
    this.icon,
    this.color,
    this.category,
    this.score,
  );
}

// ═══════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DesignTokens.neonCyan.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RadarPainter extends CustomPainter {
  final double sweep;
  final Color color;

  _RadarPainter({required this.sweep, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Circles
    for (int i = 1; i <= 3; i++) {
      final r = radius * i / 3;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = color.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // Cross lines
    final crossPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      crossPaint,
    );

    // Sweep
    final sweepAngle = sweep * 2 * math.pi;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle - 0.5,
        endAngle: sweepAngle,
        colors: [Colors.transparent, color.withValues(alpha: 0.3)],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      sweepAngle - 0.5,
      0.5,
      true,
      sweepPaint,
    );

    // Center dot
    canvas.drawCircle(center, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) =>
      sweep != oldDelegate.sweep || color != oldDelegate.color;
}
