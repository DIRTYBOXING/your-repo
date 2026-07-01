import 'package:flutter/material.dart';
import '../../../shared/models/health_metrics_model.dart';

/// Risk Indicator Widget
/// Displays a risk level (green/amber/orange/red) with visual styling
/// Supports both compact inline and large card formats
class RiskIndicator extends StatelessWidget {
  final String label;
  final RiskLevel risk;
  final bool isLarge;

  const RiskIndicator({
    super.key,
    required this.label,
    required this.risk,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getRiskColor(risk);
    final text = _getRiskText(risk);
    final icon = _getRiskIcon(risk);

    if (isLarge) {
      return _buildLargeIndicator(color, text, icon);
    }
    return _buildCompactIndicator(color, text, icon);
  }

  Widget _buildLargeIndicator(Color color, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildRiskDot(RiskLevel.green, color),
              Expanded(child: _buildRiskLine(0, color)),
              _buildRiskDot(RiskLevel.amber, color),
              Expanded(child: _buildRiskLine(1, color)),
              _buildRiskDot(RiskLevel.orange, color),
              Expanded(child: _buildRiskLine(2, color)),
              _buildRiskDot(RiskLevel.red, color),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskDot(RiskLevel level, Color activeColor) {
    final isActive = level == risk;
    final dotColor = _getRiskColor(level);

    return Container(
      width: isActive ? 18 : 12,
      height: isActive ? 18 : 12,
      decoration: BoxDecoration(
        color: isActive ? dotColor : Colors.white10,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? dotColor : Colors.white24,
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildRiskLine(int index, Color activeColor) {
    final levels = [
      RiskLevel.green,
      RiskLevel.amber,
      RiskLevel.orange,
      RiskLevel.red,
    ];
    final currentIndex = levels.indexOf(risk);
    final isActive = index < currentIndex;

    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? _getRiskColor(levels[index]) : Colors.white10,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildCompactIndicator(Color color, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.green:
        return Colors.green;
      case RiskLevel.amber:
        return Colors.amber;
      case RiskLevel.orange:
        return Colors.orange;
      case RiskLevel.red:
        return Colors.red;
    }
  }

  String _getRiskText(RiskLevel level) {
    switch (level) {
      case RiskLevel.green:
        return 'Optimal';
      case RiskLevel.amber:
        return 'Monitor';
      case RiskLevel.orange:
        return 'Elevated';
      case RiskLevel.red:
        return 'Critical';
    }
  }

  IconData _getRiskIcon(RiskLevel level) {
    switch (level) {
      case RiskLevel.green:
        return Icons.check_circle;
      case RiskLevel.amber:
        return Icons.info;
      case RiskLevel.orange:
        return Icons.warning;
      case RiskLevel.red:
        return Icons.error;
    }
  }
}
