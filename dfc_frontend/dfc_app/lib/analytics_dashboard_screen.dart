import 'package:flutter/material.dart';

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          children: [
            const SizedBox(height: 32),
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'ANALYTICS & TELEMETRY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // High-Level Telemetry
            Row(
              children: [
                Expanded(
                  child: _TelemetryCard(
                    label: 'LIVE PPV REVENUE',
                    value: '\$142.5K',
                    trend: '+12.4%',
                    color: Colors.greenAccent,
                    icon: Icons.attach_money,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TelemetryCard(
                    label: 'ACTIVE GYMS',
                    value: '840',
                    trend: '+5',
                    color: Colors.blueAccent,
                    icon: Icons.fitness_center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tesla-style Neon Chart
            const Text(
              'EVENT PERFORMANCE (PPV BUYS)',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            _DfcCard(
              height: 240,
              glow: true,
              glowColor: Colors.cyanAccent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'DFC 1',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      Text(
                        'CURRENT',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: _NeonChartWidget(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Matchmaking & Popularity Heatmap
            const Text(
              'FIGHTER POPULARITY HEATMAP',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            _DfcCard(
              height: 200,
              child: Column(
                children: [
                  _HeatmapRow('Heath Ewart', '98%', Colors.redAccent),
                  const Divider(color: Colors.white10),
                  _HeatmapRow('Kai Johnson', '85%', Colors.orangeAccent),
                  const Divider(color: Colors.white10),
                  _HeatmapRow('Mason Lee', '72%', Colors.yellowAccent),
                  const Divider(color: Colors.white10),
                  _HeatmapRow('Alex Torres', '64%', Colors.cyanAccent),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _TelemetryCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final Color color;
  final IconData icon;

  const _TelemetryCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _DfcCard(
      height: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            trend,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapRow extends StatelessWidget {
  final String name;
  final String index;
  final Color intensityColor;

  const _HeatmapRow(this.name, this.index, this.intensityColor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: intensityColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: intensityColor.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            index,
            style: TextStyle(
              color: intensityColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _NeonChartWidget extends StatelessWidget {
  const _NeonChartWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CustomPaint(painter: _NeonChartPainter()),
    );
  }
}

class _NeonChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width * 0.2, size.height * 0.7);
    path.lineTo(size.width * 0.4, size.height * 0.8);
    path.lineTo(size.width * 0.6, size.height * 0.3);
    path.lineTo(size.width * 0.8, size.height * 0.5);
    path.lineTo(size.width, 0);

    final glowPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.4)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final linePaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DfcCard extends StatelessWidget {
  final double height;
  final bool glow;
  final Color glowColor;
  final Widget child;

  const _DfcCard({
    required this.height,
    this.glow = false,
    this.glowColor = Colors.cyanAccent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: child,
    );
  }
}
