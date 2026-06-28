import 'package:equatable/equatable.dart';

class PpvEntitlementLog extends Equatable {
  final String logId;
  final String userId;
  final DateTime timestamp;
  final String action;
  final String status;
  final String? reason;
  final String source;
  final Map<String, dynamic> deviceInfo;
  final String ipAddress;

  const PpvEntitlementLog({
    required this.logId,
    required this.userId,
    required this.timestamp,
    required this.action,
    required this.status,
    this.reason,
    required this.source,
    required this.deviceInfo,
    required this.ipAddress,
  });

  factory PpvEntitlementLog.fromMap(Map<String, dynamic> map) {
    return PpvEntitlementLog(
      logId: map['log_id'] ?? '',
      userId: map['user_id'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      action: map['action'] ?? '',
      status: map['status'] ?? '',
      reason: map['reason'],
      source: map['source'] ?? '',
      deviceInfo: Map<String, dynamic>.from(map['device_info'] ?? {}),
      ipAddress: map['ip_address'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        logId,
        userId,
        timestamp,
        action,
        status,
        reason,
        source,
        deviceInfo,
        ipAddress,
      ];
}
