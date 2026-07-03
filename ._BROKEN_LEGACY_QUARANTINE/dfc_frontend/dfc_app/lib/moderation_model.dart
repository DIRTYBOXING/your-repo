class ReportModel {
  final String id;
  final String type;
  final String targetId;
  final String reporterId;
  final String reason;
  final String contentPreview;
  final int createdAt;

  ReportModel({
    required this.id,
    required this.type,
    required this.targetId,
    required this.reporterId,
    required this.reason,
    required this.contentPreview,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) => ReportModel(
    id: json['id'] ?? '',
    type: json['type'] ?? 'UNKNOWN',
    targetId: json['targetId'] ?? '',
    reporterId: json['reporterId'] ?? '',
    reason: json['reason'] ?? '',
    contentPreview: json['contentPreview'] ?? '',
    createdAt: json['createdAt'] ?? 0,
  );
}
