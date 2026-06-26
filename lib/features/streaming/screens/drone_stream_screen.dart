import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DRONE STREAMING SCREEN
/// Live FPV drone footage with AI overlay for training analysis
/// ═══════════════════════════════════════════════════════════════════════════

class DroneStreamScreen extends StatefulWidget {
  final String? sessionId;
  final String? droneId;
  final String? fighterId;

  const DroneStreamScreen({
    super.key,
    this.sessionId,
    this.droneId,
    this.fighterId,
  });

  @override
  State<DroneStreamScreen> createState() => _DroneStreamScreenState();
}

class _DroneStreamScreenState extends State<DroneStreamScreen>
    with SingleTickerProviderStateMixin {
  bool _isConnected = false;
  bool _isLoading = false;
  bool _showAIOverlay = true;
  bool _isRecording = false;
  String? _currentSessionId;
  String _connectionStatus = 'Ready';

  Map<String, dynamic> _aiInsights = {};
  final List<Map<String, dynamic>> _detectedMovements = [];

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    if (widget.sessionId != null) {
      _joinSession(widget.sessionId!);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startDroneStream() async {
    setState(() => _isLoading = true);

    try {
      final sessionRef = await FirebaseFirestore.instance
          .collection('drone_sessions')
          .add({
            'droneId': widget.droneId ?? 'drone-001',
            'fighterId': widget.fighterId,
            'sessionName':
                'Training Session ${DateTime.now().millisecondsSinceEpoch}',
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'waiting',
            'aiAnalysis': {},
            'detectedMovements': [],
          });

      _currentSessionId = sessionRef.id;

      setState(() {
        _connectionStatus = 'Waiting for drone...';
        _isLoading = false;
      });

      _listenForAIInsights();

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _isConnected = true;
          _connectionStatus = 'Connected';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _connectionStatus = 'Failed: $e';
      });
    }
  }

  Future<void> _joinSession(String sessionId) async {
    setState(() => _isLoading = true);

    try {
      _currentSessionId = sessionId;
      _listenForAIInsights();

      await FirebaseFirestore.instance
          .collection('drone_sessions')
          .doc(sessionId)
          .update({
            'viewers': FieldValue.arrayUnion([
              'viewer_${DateTime.now().millisecondsSinceEpoch}',
            ]),
          });

      setState(() {
        _isConnected = true;
        _connectionStatus = 'Connected';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _connectionStatus = 'Failed to join: $e';
      });
    }
  }

  void _listenForAIInsights() {
    if (_currentSessionId == null) return;

    FirebaseFirestore.instance
        .collection('drone_sessions')
        .doc(_currentSessionId)
        .snapshots()
        .listen((snapshot) {
          if (!snapshot.exists || !mounted) return;
          final data = snapshot.data()!;

          setState(() {
            _aiInsights = Map<String, dynamic>.from(data['aiAnalysis'] ?? {});
          });
        });
  }

  Future<void> _endSession() async {
    if (_currentSessionId != null) {
      await FirebaseFirestore.instance
          .collection('drone_sessions')
          .doc(_currentSessionId)
          .update({'status': 'ended', 'endedAt': FieldValue.serverTimestamp()});
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildVideoView(),
          if (_showAIOverlay && _isConnected) _buildAIOverlay(),
          _buildControlsOverlay(),
          _buildStatusBar(),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.neonCyan),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoView() {
    if (_isConnected) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey[900]!,
                  Colors.black,
                  const Color(0xFF303030),
                ],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: GridPainter(
                    opacity: 0.1 + (_pulseController.value * 0.05),
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.filter_center_focus,
                    size: 80,
                    color: AppTheme.neonCyan.withValues(alpha: 0.3),
                  ),
                ),
                Positioned(
                  top: 100,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(top: 100, right: 20, child: _buildTelemetryPanel()),
              ],
            ),
          );
        },
      );
    }

    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Icon(
                  Icons.flight,
                  size: 80,
                  color: AppTheme.neonCyan.withValues(
                    alpha: 0.3 + (_pulseController.value * 0.3),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Drone Stream',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _connectionStatus,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 32),
            if (widget.sessionId == null)
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _startDroneStream,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Drone Stream'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          _telemetryRow('ALT', '12.5m'),
          _telemetryRow('SPD', '2.3m/s'),
          _telemetryRow('BAT', '78%'),
          _telemetryRow('SIG', '●●●●○'),
        ],
      ),
    );
  }

  Widget _telemetryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.neonCyan,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: AIOverlayPainter(
            movements: _detectedMovements,
            insights: _aiInsights,
          ),
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _controlButton(
              icon: Icons.call_end,
              label: 'End',
              color: Colors.red,
              onPressed: _endSession,
            ),
            _controlButton(
              icon: _showAIOverlay ? Icons.visibility : Icons.visibility_off,
              label: 'AI',
              color: _showAIOverlay ? AppTheme.neonCyan : Colors.grey,
              onPressed: () => setState(() => _showAIOverlay = !_showAIOverlay),
            ),
            _controlButton(
              icon: _isRecording ? Icons.stop : Icons.fiber_manual_record,
              label: _isRecording ? 'Stop' : 'Record',
              color: _isRecording ? Colors.red : Colors.white,
              onPressed: () => setState(() => _isRecording = !_isRecording),
            ),
            _controlButton(
              icon: Icons.cameraswitch,
              label: 'Switch',
              color: Colors.white,
              onPressed: () {},
            ),
            _controlButton(
              icon: Icons.share,
              label: 'Share',
              color: Colors.white,
              onPressed: _shareSession,
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: color)),
      ],
    );
  }

  Widget _buildStatusBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isConnected ? Colors.green : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _connectionStatus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (_currentSessionId != null)
                      Text(
                        'Session: ${_currentSessionId!.substring(0, 8)}...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              if (_showAIOverlay)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.neonCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.neonCyan.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.smart_toy, size: 14, color: AppTheme.neonCyan),
                      SizedBox(width: 4),
                      Text(
                        'ATLAS AI',
                        style: TextStyle(
                          color: AppTheme.neonCyan,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_isRecording)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'REC',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareSession() {
    if (_currentSessionId == null) return;

    final shareUrl =
        'https://datafightcentral.web.app/drone/$_currentSessionId';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Share Session',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                shareUrl,
                style: const TextStyle(color: AppTheme.neonCyan, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Share this link to let others watch the drone stream',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final double opacity;
  GridPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F5FF).withValues(alpha: opacity)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) =>
      opacity != oldDelegate.opacity;
}

class AIOverlayPainter extends CustomPainter {
  final List<Map<String, dynamic>> movements;
  final Map<String, dynamic> insights;

  AIOverlayPainter({required this.movements, required this.insights});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F5FF).withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var movement in movements) {
      final x = (movement['x'] ?? 0.0) * size.width;
      final y = (movement['y'] ?? 0.0) * size.height;
      final w = (movement['width'] ?? 0.1) * size.width;
      final h = (movement['height'] ?? 0.1) * size.height;

      canvas.drawRect(Rect.fromLTWH(x, y, w, h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant AIOverlayPainter oldDelegate) =>
      movements != oldDelegate.movements || insights != oldDelegate.insights;
}
