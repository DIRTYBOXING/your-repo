import 'dfc_capabilities_report.dart';

class DFCDiagnosticFinding {
  const DFCDiagnosticFinding({
    required this.summary,
    required this.priority,
    required this.affectedCapabilities,
  });

  final String summary;
  final int priority;
  final List<String> affectedCapabilities;
}

class DFCNextModuleRecommendation {
  const DFCNextModuleRecommendation({
    required this.moduleKey,
    required this.why,
    required this.integrationPoints,
  });

  final String moduleKey;
  final String why;
  final List<String> integrationPoints;
}

class DFCSelfDiagnosticEngine {
  const DFCSelfDiagnosticEngine();

  DFCSelfDiagnosticResult runCurrentBaseline() {
    final report = DFCCapabilitiesReport.currentDfcBaseline();
    return DFCSelfDiagnosticResult(
      report: report,
      findings: generateFindings(report),
      recommendation: recommendNextModule(report),
    );
  }

  List<DFCDiagnosticFinding> generateFindings(DFCCapabilitiesReport report) {
    final findings = <DFCDiagnosticFinding>[];

    if (report.countByStatus(DFCCapabilityStatus.missing) > 0) {
      findings.add(
        DFCDiagnosticFinding(
          summary:
              'Missing systems still exist in the DFC ecosystem and should be evaluated before adding surface-area features.',
          priority: 100,
          affectedCapabilities: report
              .byStatus(DFCCapabilityStatus.missing)
              .map((capability) => capability.key)
              .toList(),
        ),
      );
    }

    final partialRevenueSystems = report.capabilities
        .where(
          (capability) =>
              capability.status == DFCCapabilityStatus.partial &&
              (capability.domain == DFCCapabilityDomain.ppv ||
                  capability.domain == DFCCapabilityDomain.settlement ||
                  capability.domain == DFCCapabilityDomain.creator),
        )
        .map((capability) => capability.key)
        .toList();

    if (partialRevenueSystems.isNotEmpty) {
      findings.add(
        DFCDiagnosticFinding(
          summary:
              'Revenue-linked systems are partial. Head-of-Development priority is to finish trust, entitlement, and payout paths before expanding breadth.',
          priority: 95,
          affectedCapabilities: partialRevenueSystems,
        ),
      );
    }

    if (report.outdatedLogic.isNotEmpty) {
      findings.add(
        const DFCDiagnosticFinding(
          summary:
              'Legacy or duplicated logic is still present and should be normalized into canonical services and pipelines.',
          priority: 85,
          affectedCapabilities: [],
        ),
      );
    }

    findings.sort((left, right) => right.priority.compareTo(left.priority));
    return findings;
  }

  DFCNextModuleRecommendation recommendNextModule(
    DFCCapabilitiesReport report,
  ) {
    final revenuePartial = report.capabilities.firstWhere(
      (capability) =>
          capability.status == DFCCapabilityStatus.partial &&
          capability.domain == DFCCapabilityDomain.settlement,
      orElse: () => report.capabilities.firstWhere(
        (capability) => capability.status == DFCCapabilityStatus.partial,
        orElse: () => report.capabilities.first,
      ),
    );

    return DFCNextModuleRecommendation(
      moduleKey: revenuePartial.key,
      why:
          'This module offers the highest leverage because it is already in motion and sits closest to revenue, trust, or ecosystem integrity.',
      integrationPoints: revenuePartial.dependencies,
    );
  }
}

class DFCSelfDiagnosticResult {
  const DFCSelfDiagnosticResult({
    required this.report,
    required this.findings,
    required this.recommendation,
  });

  final DFCCapabilitiesReport report;
  final List<DFCDiagnosticFinding> findings;
  final DFCNextModuleRecommendation recommendation;
}
