/// A single snapshot of a fighter's core performance and wellness telemetry.
class AstroSnapshot {
  final int hrv;
  final double sleepHours;
  final int stressScore; // 1-10

  AstroSnapshot({
    required this.hrv,
    required this.sleepHours,
    required this.stressScore,
  });
}

/// The bridge between raw device telemetry and the DFC AI ecosystem.
class AstroHealthService {
  /// Fetches the latest telemetry snapshot for a user.
  Future<AstroSnapshot> getSnapshot(String userId) async {
    // TODO: Pull real data from Apple HealthKit, Google Fit, Whoop, Oura, etc.
    return AstroSnapshot(
      hrv: 70, 
      sleepHours: 6.2, 
      stressScore: 5,
    );
  }
}
