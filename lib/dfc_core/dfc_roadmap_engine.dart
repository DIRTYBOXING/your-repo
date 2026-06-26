import 'dfc_capabilities_report.dart';
import 'dfc_priority_matrix.dart';

class DFCRoadmapPhase {
  const DFCRoadmapPhase({
    required this.label,
    required this.items,
    required this.rationale,
  });

  final String label;
  final List<String> items;
  final String rationale;
}

class DFCRoadmap {
  const DFCRoadmap({
    required this.thirtyDay,
    required this.sixtyDay,
    required this.ninetyDay,
  });

  final DFCRoadmapPhase thirtyDay;
  final DFCRoadmapPhase sixtyDay;
  final DFCRoadmapPhase ninetyDay;
}

class DFCRoadmapEngine {
  const DFCRoadmapEngine();

  DFCRoadmap generateCurrentBaseline() {
    final report = DFCCapabilitiesReport.currentDfcBaseline();
    return generate(report, const DFCPriorityMatrix());
  }

  DFCRoadmap generate(
    DFCCapabilitiesReport report,
    DFCPriorityMatrix priorityMatrix,
  ) {
    final scored = priorityMatrix.evaluate(report);
    final thirtyDayItems = scored
        .take(3)
        .map((score) => score.capability.label)
        .toList();
    final sixtyDayItems = scored
        .skip(3)
        .take(5)
        .map((score) => score.capability.label)
        .toList();
    final ninetyDayItems = scored
        .skip(8)
        .take(5)
        .map((score) => score.capability.label)
        .toList();

    return DFCRoadmap(
      thirtyDay: DFCRoadmapPhase(
        label: '30 Day Critical Path',
        items: thirtyDayItems,
        rationale:
            'Finish the highest-leverage trust, revenue, and rights systems first so DFC can run clean shows and settle them safely.',
      ),
      sixtyDay: DFCRoadmapPhase(
        label: '60 Day Expansion Path',
        items: sixtyDayItems,
        rationale:
            'Expand the social, creator, and portal surface only after the platform spine is reliable.',
      ),
      ninetyDay: DFCRoadmapPhase(
        label: '90 Day Ecosystem Path',
        items: ninetyDayItems,
        rationale:
            'Use the stable foundation to grow sponsorship, community, discovery, and advanced automation.',
      ),
    );
  }
}
