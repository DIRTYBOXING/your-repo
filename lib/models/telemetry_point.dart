class TelemetryPoint {
  final double timestamp;
  final double strikeVelocity; // In km/h
  final int staminaPercent; // 0-100
  final int heartRate; // BPM

  TelemetryPoint({
    required this.timestamp,
    required this.strikeVelocity,
    required this.staminaPercent,
    required this.heartRate,
  });

  factory TelemetryPoint.fromJson(Map<String, dynamic> json) {
    return TelemetryPoint(
      timestamp: json['t'],
      strikeVelocity: json['sv'],
      staminaPercent: json['sp'],
      heartRate: json['hr'],
    );
  }
}
