import 'package:equatable/equatable.dart';

class PpvIncident extends Equatable {
  final String incidentId;
  final String type;
  final DateTime timestamp;
  final String severity;
  final String description;
  final Map<String, dynamic> details;
  final String status;
  final String? assignedTo;
  final DateTime? resolvedAt;
  final String? userId;

  const PpvIncident({
    required this.incidentId,
    required this.type,
    required this.timestamp,
    required this.severity,
    required this.description,
    required this.details,
    required this.status,
    this.assignedTo,
    this.resolvedAt,
    this.userId,
  });

  factory PpvIncident.fromMap(Map<String, dynamic> map) {
    return PpvIncident(
      incidentId: map['incident_id'] ?? '',
      type: map['type'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      severity: map['severity'] ?? '',
      description: map['description'] ?? '',
      details: Map<String, dynamic>.from(map['details'] ?? {}),
      status: map['status'] ?? 'unknown',
      assignedTo: map['assigned_to'],
      resolvedAt: map['resolved_at'] != null ? DateTime.parse(map['resolved_at']) : null,
      userId: map['user_id'],
    );
  }

  @override
  List<Object?> get props => [
        incidentId,
        type,
        timestamp,
        severity,
        description,
        details,
        status,
        assignedTo,
        resolvedAt,
        userId,
      ];
}
