import 'package:equatable/equatable.dart';

class PpvLiveStats extends Equatable {
  final int liveViewers;
  final int uniqueViewers;
  final int purchases;
  final double revenue;
  final Map<String, double> affiliateBreakdown;
  final Map<String, double> fighterBreakdown;
  final Map<String, int> deviceBreakdown;
  final Map<String, int> geoHeatmap;
  final DateTime updatedAt;
  final String streamHealthStatus;
  final int streamBitrateKbps;
  final double streamRebufferRate;
  final double streamErrorRate;
  final int totalEntitlements;
  final int failedEntitlementsCount;
  final int suspiciousActivityCount;
  final int refundsCount;
  final int incidentAlertsCount;

  const PpvLiveStats({
    required this.liveViewers,
    required this.uniqueViewers,
    required this.purchases,
    required this.revenue,
    required this.affiliateBreakdown,
    required this.fighterBreakdown,
    required this.deviceBreakdown,
    required this.geoHeatmap,
    required this.updatedAt,
    required this.streamHealthStatus,
    required this.streamBitrateKbps,
    required this.streamRebufferRate,
    required this.streamErrorRate,
    required this.totalEntitlements,
    required this.failedEntitlementsCount,
    required this.suspiciousActivityCount,
    required this.refundsCount,
    required this.incidentAlertsCount,
  });

  factory PpvLiveStats.fromMap(Map<String, dynamic> map) {
    return PpvLiveStats(
      liveViewers: map['live_viewers']?.toInt() ?? 0,
      uniqueViewers: map['unique_viewers']?.toInt() ?? 0,
      purchases: map['purchases']?.toInt() ?? 0,
      revenue: map['revenue']?.toDouble() ?? 0.0,
      affiliateBreakdown: Map<String, double>.from(map['affiliate_breakdown'] ?? {}),
      fighterBreakdown: Map<String, double>.from(map['fighter_breakdown'] ?? {}),
      deviceBreakdown: Map<String, int>.from(map['device_breakdown'] ?? {}),
      geoHeatmap: Map<String, int>.from(map['geo_heatmap'] ?? {}),
      updatedAt: DateTime.parse(map['updated_at']),
      streamHealthStatus: map['stream_health_status'] ?? 'unknown',
      streamBitrateKbps: map['stream_bitrate_kbps']?.toInt() ?? 0,
      streamRebufferRate: map['stream_rebuffer_rate']?.toDouble() ?? 0.0,
      streamErrorRate: map['stream_error_rate']?.toDouble() ?? 0.0,
      totalEntitlements: map['total_entitlements']?.toInt() ?? 0,
      failedEntitlementsCount: map['failed_entitlements_count']?.toInt() ?? 0,
      suspiciousActivityCount: map['suspicious_activity_count']?.toInt() ?? 0,
      refundsCount: map['refunds_count']?.toInt() ?? 0,
      incidentAlertsCount: map['incident_alerts_count']?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        liveViewers,
        uniqueViewers,
        purchases,
        revenue,
        affiliateBreakdown,
        fighterBreakdown,
        deviceBreakdown,
        geoHeatmap,
        updatedAt,
        streamHealthStatus,
        streamBitrateKbps,
        streamRebufferRate,
        streamErrorRate,
        totalEntitlements,
        failedEntitlementsCount,
        suspiciousActivityCount,
        refundsCount,
        incidentAlertsCount,
      ];
}
