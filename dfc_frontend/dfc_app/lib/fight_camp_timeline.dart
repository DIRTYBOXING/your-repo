import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FightCampTimelineChart extends StatelessWidget {
  final List<double> readinessValues;

  const FightCampTimelineChart({super.key, required this.readinessValues});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          backgroundColor: Colors.black,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                readinessValues.length,
                (i) => FlSpot(i.toDouble(), readinessValues[i]),
              ),
              isCurved: true,
              barWidth: 3,
              color: Colors.cyanAccent,
              belowBarData: BarAreaData(
                show: true,
                color: Colors.cyanAccent.withValues(alpha: 0.15),
              ),
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
