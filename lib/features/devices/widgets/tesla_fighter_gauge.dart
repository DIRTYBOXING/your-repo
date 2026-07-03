import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../../shared/widgets/glass_card.dart';

class TeslaFighterGauge extends StatelessWidget {
  final double powerLevel;
  final double staminaLevel;
  final double heartRate;

  const TeslaFighterGauge({
    Key? key,
    required this.powerLevel,
    required this.staminaLevel,
    required this.heartRate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'BIOMETRIC TELEMETRY',
              style: TextStyle(
                color: Colors.cyanAccent,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 0,
                    maximum: 100,
                    startAngle: 180,
                    endAngle: 360,
                    showLabels: false,
                    showTicks: false,
                    radiusFactor: 0.9,
                    axisLineStyle: const AxisLineStyle(
                      thickness: 0.2,
                      cornerStyle: CornerStyle.bothCurve,
                      color: Colors.white10,
                      thicknessUnit: GaugeSizeUnit.factor,
                    ),
                    pointers: <GaugePointer>[
                      RangePointer(
                        value: powerLevel,
                        cornerStyle: CornerStyle.bothCurve,
                        width: 0.2,
                        sizeUnit: GaugeSizeUnit.factor,
                        gradient: const SweepGradient(
                          colors: <Color>[Colors.blue, Colors.cyanAccent],
                          stops: <double>[0.25, 0.75],
                        ),
                      ),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        positionFactor: 0.1,
                        angle: 90,
                        widget: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${powerLevel.toInt()}%',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'STRIKE POWER',
                              style: TextStyle(color: Colors.white54, fontSize: 10),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLinearGauge('STAMINA', staminaLevel, Colors.purpleAccent),
                _buildLinearGauge('HEART RATE', heartRate / 200 * 100, Colors.redAccent),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLinearGauge(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        SizedBox(
          width: 100,
          height: 10,
          child: LinearProgressIndicator(
            value: value / 100,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(height: 4),
        Text('${value.toInt()}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
