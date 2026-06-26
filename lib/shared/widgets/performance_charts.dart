import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/genie/genie_api_service.dart';
import '../../features/genie/genie_persona.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PERFORMANCE CHARTS - 2026 Custom Performance Visualization
/// Soft glow, gradient fill, no axes clutter
/// ═══════════════════════════════════════════════════════════════════════════
class PerformanceCharts extends StatefulWidget {
  const PerformanceCharts({super.key});

  @override
  State<PerformanceCharts> createState() => _PerformanceChartsState();
}

class _PerformanceChartsState extends State<PerformanceCharts> {
  bool _isLoadingInsights = false;
  String? _loadInsight;
  String? _weightInsight;
  String? _sleepInsight;

  GeniePersona get _shidoPersona => geniePersonas.firstWhere(
    (p) => p.id == 'shido',
    orElse: () => geniePersonas.last,
  );

  @override
  void initState() {
    super.initState();
    _fetchShidoInsights();
  }

  Future<void> _fetchShidoInsights() async {
    setState(() {
      _isLoadingInsights = true;
    });

    try {
      final persona = _shidoPersona;
      final loadFuture = GenieApiService.askGenie(
        'Analyze my 7-day training load vs recovery chart. Load is high but mostly balanced with recovery. Give one sentence of coaching advice.',
        persona: persona,
      );
      final weightFuture = GenieApiService.askGenie(
        'Analyze my 7-day weight-cut trend chart where weight is steadily dropping toward target. Give one sentence of guidance on staying safe.',
        persona: persona,
      );
      final sleepFuture = GenieApiService.askGenie(
        'Analyze my 7-night sleep and HRV chart where sleep duration is decent and HRV is slowly improving. Give one sentence on recovery quality.',
        persona: persona,
      );

      final results = await Future.wait([
        loadFuture,
        weightFuture,
        sleepFuture,
      ]);

      if (!mounted) return;

      setState(() {
        _loadInsight = results[0];
        _weightInsight = results[1];
        _sleepInsight = results[2];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInsights = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildChartCard(
          title: 'Load vs Recovery',
          subtitle: 'Balance indicator',
          chart: const _LoadRecoveryChart(),
          aiInsight:
              _loadInsight ??
              'Training load is well-balanced with recovery. Optimal for adaptation.',
          status: 'green',
        ),
        const SizedBox(height: 16),
        _buildChartCard(
          title: 'Weight Trend',
          subtitle: 'Cut progress',
          chart: const _WeightTrendChart(),
          aiInsight:
              _weightInsight ??
              'On track to make weight. Hydration should be monitored closely.',
          status: 'amber',
        ),
        const SizedBox(height: 16),
        _buildChartCard(
          title: 'Sleep & HRV',
          subtitle: 'Recovery quality',
          chart: const _SleepHRVChart(),
          aiInsight:
              _sleepInsight ??
              'Sleep quality correlating well with HRV improvements.',
          status: 'green',
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_isLoadingInsights)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.neonCyan,
                    ),
                  ),
                ),
              if (_isLoadingInsights) const SizedBox(width: 8),
              Icon(
                Icons.self_improvement,
                size: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                _isLoadingInsights
                    ? 'Samurai Shido analyzing your trends...'
                    : 'Insights powered by Samurai Shido',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required Widget chart,
    required String aiInsight,
    required String status,
  }) {
    Color statusColor;
    switch (status) {
      case 'green':
        statusColor = Colors.green;
        break;
      case 'amber':
        statusColor = Colors.amber;
        break;
      case 'red':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 120, child: chart),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.psychology, color: statusColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    aiInsight,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
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

/// Load vs Recovery Chart
class _LoadRecoveryChart extends StatelessWidget {
  const _LoadRecoveryChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _LoadRecoveryPainter(), size: Size.infinite);
  }
}

class _LoadRecoveryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final loadData = [0.6, 0.7, 0.8, 0.65, 0.75, 0.9, 0.7];
    final recoveryData = [0.7, 0.65, 0.55, 0.7, 0.6, 0.5, 0.65];

    // Draw recovery area (under)
    _drawArea(canvas, size, recoveryData, Colors.purple.withValues(alpha: 0.3));
    _drawLine(canvas, size, recoveryData, Colors.purple);

    // Draw load area (on top)
    _drawArea(canvas, size, loadData, AppTheme.neonCyan.withValues(alpha: 0.3));
    _drawLine(canvas, size, loadData, AppTheme.neonCyan);
  }

  void _drawArea(Canvas canvas, Size size, List<double> data, Color color) {
    final path = Path();
    final stepX = size.width / (data.length - 1);

    path.moveTo(0, size.height);
    for (int i = 0; i < data.length; i++) {
      path.lineTo(i * stepX, size.height * (1 - data[i]));
    }
    path.lineTo(size.width, size.height);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);
  }

  void _drawLine(Canvas canvas, Size size, List<double> data, Color color) {
    final path = Path();
    final stepX = size.width / (data.length - 1);

    path.moveTo(0, size.height * (1 - data[0]));
    for (int i = 1; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height * (1 - data[i]);
      final prevX = (i - 1) * stepX;
      final prevY = size.height * (1 - data[i - 1]);
      final ctrlX = (prevX + x) / 2;
      path.cubicTo(ctrlX, prevY, ctrlX, y, x, y);
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Weight Trend Chart
class _WeightTrendChart extends StatelessWidget {
  const _WeightTrendChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _WeightTrendPainter(), size: Size.infinite);
  }
}

class _WeightTrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final weightData = [0.8, 0.75, 0.7, 0.65, 0.6, 0.55, 0.52];
    final targetLine = 0.5;

    // Draw target zone
    final targetPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height * (1 - targetLine - 0.05),
        size.width,
        size.height * 0.1,
      ),
      targetPaint,
    );

    // Draw target line
    final targetLinePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, size.height * (1 - targetLine)),
      Offset(size.width, size.height * (1 - targetLine)),
      targetLinePaint,
    );

    // Draw weight line
    _drawArea(canvas, size, weightData, Colors.orange.withValues(alpha: 0.3));
    _drawLine(canvas, size, weightData, Colors.orange);
  }

  void _drawArea(Canvas canvas, Size size, List<double> data, Color color) {
    final path = Path();
    final stepX = size.width / (data.length - 1);

    path.moveTo(0, size.height);
    for (int i = 0; i < data.length; i++) {
      path.lineTo(i * stepX, size.height * (1 - data[i]));
    }
    path.lineTo(size.width, size.height);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);
  }

  void _drawLine(Canvas canvas, Size size, List<double> data, Color color) {
    final path = Path();
    final stepX = size.width / (data.length - 1);

    path.moveTo(0, size.height * (1 - data[0]));
    for (int i = 1; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height * (1 - data[i]);
      final prevX = (i - 1) * stepX;
      final prevY = size.height * (1 - data[i - 1]);
      final ctrlX = (prevX + x) / 2;
      path.cubicTo(ctrlX, prevY, ctrlX, y, x, y);
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Sleep & HRV Chart
class _SleepHRVChart extends StatelessWidget {
  const _SleepHRVChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SleepHRVPainter(), size: Size.infinite);
  }
}

class _SleepHRVPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sleepData = [0.7, 0.75, 0.6, 0.8, 0.85, 0.7, 0.78];
    final hrvData = [0.5, 0.55, 0.45, 0.6, 0.65, 0.55, 0.6];

    // Draw bars for sleep
    final barWidth = size.width / sleepData.length - 8;
    for (int i = 0; i < sleepData.length; i++) {
      final x = i * (size.width / sleepData.length) + 4;
      final height = size.height * sleepData[i] * 0.8;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - height, barWidth, height),
        const Radius.circular(4),
      );
      final paint = Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.purple, Colors.purple.withValues(alpha: 0.3)],
            ).createShader(
              Rect.fromLTWH(x, size.height - height, barWidth, height),
            );
      canvas.drawRRect(rect, paint);
    }

    // Draw HRV line on top
    _drawLine(canvas, size, hrvData, AppTheme.neonCyan);
  }

  void _drawLine(Canvas canvas, Size size, List<double> data, Color color) {
    final path = Path();
    final stepX = size.width / data.length;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX + stepX / 2;
      final y = size.height * (1 - data[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = (i - 1) * stepX + stepX / 2;
        final prevY = size.height * (1 - data[i - 1]);
        final ctrlX = (prevX + x) / 2;
        path.cubicTo(ctrlX, prevY, ctrlX, y, x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);

    // Draw dots
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX + stepX / 2;
      final y = size.height * (1 - data[i]);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
