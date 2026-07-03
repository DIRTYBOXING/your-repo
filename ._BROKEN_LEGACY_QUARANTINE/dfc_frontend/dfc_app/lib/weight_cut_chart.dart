import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeightCutChart extends StatelessWidget {
  final List<Map<String, dynamic>> weightData;

  const WeightCutChart({super.key, required this.weightData});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          backgroundColor: Colors.black,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineBarsData: [
            // Actual Weight Curve
            LineChartBarData(
              spots: List.generate(
                weightData.length,
                (i) => FlSpot(i.toDouble(), weightData[i]["weight"]),
              ),
              isCurved: true,
              barWidth: 3,
              color: Colors.redAccent,
              dotData: const FlDotData(show: true),
            ),
            // Target Weight Cut Trajectory
            LineChartBarData(
              spots: List.generate(
                weightData.length,
                (i) => FlSpot(i.toDouble(), weightData[i]["target_weight"]),
              ),
              isCurved: false,
              barWidth: 2,
              color: Colors.white54,
              dashArray: [5, 5],
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
