import 'dfc_capabilities_report.dart';

enum DFCPriorityBucket { critical, high, medium, low, defer }

class DFCPriorityScore {
  const DFCPriorityScore({
    required this.capability,
    required this.total,
    required this.bucket,
  });

  final DFCCapability capability;
  final int total;
  final DFCPriorityBucket bucket;
}

class DFCPriorityMatrix {
  const DFCPriorityMatrix();

  List<DFCPriorityScore> evaluateCurrentBaseline() {
    return evaluate(DFCCapabilitiesReport.currentDfcBaseline());
  }

  List<DFCPriorityScore> evaluate(DFCCapabilitiesReport report) {
    final scores = report.capabilities.map(_scoreCapability).toList();
    scores.sort((left, right) => right.total.compareTo(left.total));
    return scores;
  }

  List<DFCPriorityScore> topImmediateBuilds(DFCCapabilitiesReport report) {
    return evaluate(report).take(3).toList();
  }

  DFCPriorityScore _scoreCapability(DFCCapability capability) {
    var total = 0;

    switch (capability.status) {
      case DFCCapabilityStatus.missing:
        total += 40;
        break;
      case DFCCapabilityStatus.partial:
        total += 55;
        break;
      case DFCCapabilityStatus.implemented:
        total += 10;
        break;
      case DFCCapabilityStatus.deferred:
        total += 5;
        break;
    }

    switch (capability.domain) {
      case DFCCapabilityDomain.rights:
      case DFCCapabilityDomain.metadata:
      case DFCCapabilityDomain.settlement:
      case DFCCapabilityDomain.broadcast:
        total += 35;
        break;
      case DFCCapabilityDomain.ppv:
      case DFCCapabilityDomain.creator:
      case DFCCapabilityDomain.media:
        total += 25;
        break;
      case DFCCapabilityDomain.social:
      case DFCCapabilityDomain.portals:
      case DFCCapabilityDomain.ai:
        total += 18;
        break;
      case DFCCapabilityDomain.core:
      case DFCCapabilityDomain.discovery:
      case DFCCapabilityDomain.goodwill:
        total += 12;
        break;
    }

    if (capability.dependencies.isNotEmpty) {
      total += 5;
    }

    return DFCPriorityScore(
      capability: capability,
      total: total.clamp(0, 100),
      bucket: _bucketFor(total),
    );
  }

  DFCPriorityBucket _bucketFor(int score) {
    if (score >= 80) return DFCPriorityBucket.critical;
    if (score >= 60) return DFCPriorityBucket.high;
    if (score >= 40) return DFCPriorityBucket.medium;
    if (score >= 20) return DFCPriorityBucket.low;
    return DFCPriorityBucket.defer;
  }
}
