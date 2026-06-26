import '../models/partner_portal_models.dart';

class MockPartnerPortalService {
  const MockPartnerPortalService();

  List<PartnerProgram> get programs => List.unmodifiable(_programs);
  List<TalentLead> get pipeline => List.unmodifiable(_talentPipeline);
  List<PartnerMetric> get metrics => List.unmodifiable(_metrics);
}

final List<PartnerProgram> _programs = [
  const PartnerProgram(
    id: 'program-301',
    brandName: 'Origin Labs',
    briefTitle: 'Metabolic Lab Residency',
    objective:
        'Place two fighters into Origin Labs flagship residency with daily content capture.',
    status: 'In Review',
    budget: '45k total package',
    timeline: 'Feb 05 - Mar 01',
    deliverables: [
      'Lab residency',
      'Recovery analytics access',
      'Story content drops',
    ],
  ),
  const PartnerProgram(
    id: 'program-302',
    brandName: 'Pulse Energy',
    briefTitle: 'Energy System Tour',
    objective: 'Secure a fighter ambassador for the Pulse City Arena tour.',
    status: 'Shortlist',
    budget: '35k retainer + tour bonus',
    timeline: 'Mar 15 - Apr 30',
    deliverables: ['Arena meetups', 'Train-along sessions', 'Live Q&A host'],
  ),
];

final List<TalentLead> _talentPipeline = [
  const TalentLead(
    name: 'Kai Moreno',
    discipline: 'Featherweight southpaw',
    region: 'Sydney, AU',
    stage: 'Chemistry call booked',
    signal: '86% match score',
    notes: ['High engagement', 'Prefers capsule collabs'],
  ),
  const TalentLead(
    name: 'Maya Quinn',
    discipline: 'MMA striker',
    region: 'Austin, TX',
    stage: 'Awaiting deck',
    signal: '74% match score',
    notes: ['Story-first', 'Content pipeline ready'],
  ),
];

final List<PartnerMetric> _metrics = [
  const PartnerMetric(
    label: 'Active briefs',
    value: '6',
    delta: 1.2,
    isPositive: true,
    caption: 'Live brand requests in queue',
  ),
  const PartnerMetric(
    label: 'Avg. approval',
    value: '8.4 days',
    delta: -0.5,
    isPositive: true,
    caption: 'Speed from brief to handshake',
  ),
  const PartnerMetric(
    label: 'Creator NPS',
    value: '71',
    delta: 3.0,
    isPositive: true,
    caption: 'Quarterly satisfaction pulse',
  ),
];
