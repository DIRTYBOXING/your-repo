class PpvEntitlementModel {
  final bool hasAccess;
  final String? playbackId;
  final String status;

  PpvEntitlementModel({
    required this.hasAccess,
    this.playbackId,
    this.status = 'offline',
  });

  factory PpvEntitlementModel.fromJson(Map<String, dynamic> json) {
    return PpvEntitlementModel(
      hasAccess: json['hasAccess'] ?? false,
      playbackId: json['playbackId'],
      status: json['status'] ?? 'offline',
    );
  }
}
