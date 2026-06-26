class HealthDocumentModel {
  final String id;
  final String filename;
  final String status;
  final double progress;

  HealthDocumentModel({
    required this.id,
    required this.filename,
    required this.status,
    required this.progress,
  });

  factory HealthDocumentModel.fromJson(Map<String, dynamic> json) {
    return HealthDocumentModel(
      id: json['id'] ?? '',
      filename: json['filename'] ?? 'Unknown File',
      status: json['status'] ?? 'Pending',
      progress: (json['progress'] ?? 0.0).toDouble(),
    );
  }
}