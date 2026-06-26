class DashboardModel {
  final String upcomingEventTitle;
  final int daysOut;
  final double weight;
  final int readiness;
  final int tokens;

  // UI fallbacks for fields not yet provided by backend
  final String redCorner = "EWART";
  final String blueCorner = "JOHNSON";
  final String blueprintTitle = "ACTIVE RECOVERY";
  final String blueprintDesc =
      "Mobility (30m), Zone 2 (45m). Optimized for elevated acute load.";

  DashboardModel({
    required this.upcomingEventTitle,
    required this.daysOut,
    required this.weight,
    required this.readiness,
    required this.tokens,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      upcomingEventTitle: json['upcomingEventTitle'] ?? 'DFC 2: REDEMPTION',
      daysOut: json['daysOut'] ?? 14,
      weight: (json['weight'] ?? 74.5).toDouble(),
      readiness: json['readiness'] ?? 88,
      tokens: json['tokens'] ?? 2400,
    );
  }
}
