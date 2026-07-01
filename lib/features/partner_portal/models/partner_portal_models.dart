class PartnerProgram {
  const PartnerProgram({
    required this.id,
    required this.brandName,
    required this.briefTitle,
    required this.objective,
    required this.status,
    required this.budget,
    required this.timeline,
    required this.deliverables,
  });

  final String id;
  final String brandName;
  final String briefTitle;
  final String objective;
  final String status;
  final String budget;
  final String timeline;
  final List<String> deliverables;
}

class TalentLead {
  const TalentLead({
    required this.name,
    required this.discipline,
    required this.region,
    required this.stage,
    required this.signal,
    required this.notes,
  });

  final String name;
  final String discipline;
  final String region;
  final String stage;
  final String signal;
  final List<String> notes;
}

class PartnerMetric {
  const PartnerMetric({
    required this.label,
    required this.value,
    required this.delta,
    required this.isPositive,
    required this.caption,
  });

  final String label;
  final String value;
  final double delta;
  final bool isPositive;
  final String caption;
}
