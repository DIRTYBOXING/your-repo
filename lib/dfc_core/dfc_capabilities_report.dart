enum DFCCapabilityStatus { implemented, partial, missing, deferred }

enum DFCCapabilityDomain {
  core,
  metadata,
  rights,
  media,
  ppv,
  social,
  broadcast,
  ai,
  portals,
  settlement,
  creator,
  discovery,
  goodwill,
}

class DFCCapability {
  const DFCCapability({
    required this.key,
    required this.label,
    required this.domain,
    required this.status,
    this.notes,
    this.dependencies = const [],
  });

  final String key;
  final String label;
  final DFCCapabilityDomain domain;
  final DFCCapabilityStatus status;
  final String? notes;
  final List<String> dependencies;

  bool get isImplemented => status == DFCCapabilityStatus.implemented;
  bool get isPartial => status == DFCCapabilityStatus.partial;
  bool get isMissing => status == DFCCapabilityStatus.missing;

  DFCCapability copyWith({
    String? key,
    String? label,
    DFCCapabilityDomain? domain,
    DFCCapabilityStatus? status,
    String? notes,
    List<String>? dependencies,
  }) {
    return DFCCapability(
      key: key ?? this.key,
      label: label ?? this.label,
      domain: domain ?? this.domain,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      dependencies: dependencies ?? this.dependencies,
    );
  }
}

class DFCCapabilitiesReport {
  DFCCapabilitiesReport({
    required this.generatedAt,
    required this.capabilities,
    this.missingFeatures = const [],
    this.outdatedLogic = const [],
    this.recommendedNextSteps = const [],
  });

  final DateTime generatedAt;
  final List<DFCCapability> capabilities;
  final List<String> missingFeatures;
  final List<String> outdatedLogic;
  final List<String> recommendedNextSteps;

  factory DFCCapabilitiesReport.currentDfcBaseline() {
    return DFCCapabilitiesReport(
      generatedAt: DateTime(2026, 4, 14),
      capabilities: const [
        DFCCapability(
          key: 'workspace_control_plane',
          label: 'VS Code control plane',
          domain: DFCCapabilityDomain.core,
          status: DFCCapabilityStatus.partial,
          notes:
              'Launch configs, tasks, and MCP are present, but shared workspace settings still contain personal drift and invalid overrides.',
        ),
        DFCCapability(
          key: 'media_asset_spine',
          label: 'Canonical media asset spine',
          domain: DFCCapabilityDomain.metadata,
          status: DFCCapabilityStatus.implemented,
          dependencies: ['media_ingestion_pipeline'],
          notes:
              'Media asset model and upload service exist as the canonical metadata base for rights-aware media.',
        ),
        DFCCapability(
          key: 'media_ingestion_pipeline',
          label: 'Media ingestion pipeline',
          domain: DFCCapabilityDomain.media,
          status: DFCCapabilityStatus.partial,
          dependencies: ['rights_aware_moderation', 'media_asset_spine'],
          notes:
              'Ingestion exists, but full universal enforcement across all surfaces is not complete.',
        ),
        DFCCapability(
          key: 'rights_aware_moderation',
          label: 'Rights-aware moderation',
          domain: DFCCapabilityDomain.rights,
          status: DFCCapabilityStatus.partial,
          dependencies: ['media_asset_spine'],
          notes:
              'Moderation surfaces exist, but feed/render enforcement and publish gating still need completion.',
        ),
        DFCCapability(
          key: 'promoter_rights_intake',
          label: 'Promoter rights intake',
          domain: DFCCapabilityDomain.portals,
          status: DFCCapabilityStatus.partial,
          dependencies: ['rights_aware_moderation', 'ppv_commerce_surface'],
          notes:
              'Promoter rights intake and onboarding are present, but go-live and replay publish gates are not fully closed.',
        ),
        DFCCapability(
          key: 'ppv_commerce_surface',
          label: 'PPV commerce surface',
          domain: DFCCapabilityDomain.ppv,
          status: DFCCapabilityStatus.implemented,
          dependencies: ['broadcast_pipeline', 'settlement_visibility'],
          notes:
              'PPV hub, store, checkout, library, and access services are present.',
        ),
        DFCCapability(
          key: 'settlement_visibility',
          label: 'Settlement visibility',
          domain: DFCCapabilityDomain.settlement,
          status: DFCCapabilityStatus.missing,
          dependencies: ['ppv_commerce_surface', 'creator_payouts'],
          notes:
              'Revenue wallet and monetization surfaces exist, but a canonical settlement dashboard is still missing.',
        ),
        DFCCapability(
          key: 'social_graph_and_feed',
          label: 'Social graph and feed',
          domain: DFCCapabilityDomain.social,
          status: DFCCapabilityStatus.implemented,
          dependencies: ['media_asset_spine'],
          notes:
              'Feed, posts, reels, stories, comments, members, and social hub surfaces are present.',
        ),
        DFCCapability(
          key: 'broadcast_pipeline',
          label: 'Broadcast and replay pipeline',
          domain: DFCCapabilityDomain.broadcast,
          status: DFCCapabilityStatus.partial,
          dependencies: ['ppv_commerce_surface', 'rights_aware_moderation'],
          notes:
              'Streaming functions and live/replay paths exist, but operator confidence and rights gating remain incomplete.',
        ),
        DFCCapability(
          key: 'creator_payouts',
          label: 'Creator payout and economy hooks',
          domain: DFCCapabilityDomain.creator,
          status: DFCCapabilityStatus.partial,
          dependencies: ['settlement_visibility', 'social_graph_and_feed'],
          notes:
              'Creator economy and payout services exist, but referral attribution and canonical settlement mapping are incomplete.',
        ),
        DFCCapability(
          key: 'discovery_surfaces',
          label: 'Discovery surfaces',
          domain: DFCCapabilityDomain.discovery,
          status: DFCCapabilityStatus.partial,
          dependencies: ['social_graph_and_feed'],
          notes:
              'Discovery and region surfaces exist, but unified metadata-driven ranking is still fragmented.',
        ),
        DFCCapability(
          key: 'ai_assistive_surfaces',
          label: 'AI assistive surfaces',
          domain: DFCCapabilityDomain.ai,
          status: DFCCapabilityStatus.partial,
          dependencies: ['media_asset_spine', 'social_graph_and_feed'],
          notes:
              'Many AI services exist, but they are distributed rather than normalized into one explicit platform layer.',
        ),
        DFCCapability(
          key: 'goodwill_engine',
          label: 'Goodwill engine',
          domain: DFCCapabilityDomain.goodwill,
          status: DFCCapabilityStatus.missing,
          notes:
              'Goodwill and uplift vision exists, but there is no canonical goodwill engine module in the repo.',
        ),
      ],
      missingFeatures: const [
        'Settlement dashboard with promoter, fighter, gym, creator, reserve, dispute, and payout visibility.',
        'End-to-end rights gating for go-live, replay publish, and feed visibility.',
        'Canonical goodwill/community engine module.',
      ],
      outdatedLogic: const [
        'Shared VS Code settings still mix DFC policy with personal editor preferences.',
        'Capability state lives in code, docs, and intuition instead of one canonical snapshot.',
      ],
      recommendedNextSteps: const [
        'Finish rights enforcement before expanding new media surfaces.',
        'Build settlement visibility before broadening creator monetization promises.',
        'Normalize the VS Code control plane so the workspace stays reproducible.',
      ],
    );
  }

  Iterable<DFCCapability> byDomain(DFCCapabilityDomain domain) {
    return capabilities.where((capability) => capability.domain == domain);
  }

  Iterable<DFCCapability> byStatus(DFCCapabilityStatus status) {
    return capabilities.where((capability) => capability.status == status);
  }

  int countByStatus(DFCCapabilityStatus status) {
    return byStatus(status).length;
  }

  Map<DFCCapabilityDomain, List<DFCCapability>> groupedByDomain() {
    final grouped = <DFCCapabilityDomain, List<DFCCapability>>{};
    for (final capability in capabilities) {
      grouped.putIfAbsent(capability.domain, () => <DFCCapability>[]);
      grouped[capability.domain]!.add(capability);
    }
    return grouped;
  }

  DFCCapability? capabilityFor(String key) {
    for (final capability in capabilities) {
      if (capability.key == key) {
        return capability;
      }
    }
    return null;
  }

  List<String> summaryLines() {
    return [
      'Implemented: ${countByStatus(DFCCapabilityStatus.implemented)}',
      'Partial: ${countByStatus(DFCCapabilityStatus.partial)}',
      'Missing: ${countByStatus(DFCCapabilityStatus.missing)}',
      'Deferred: ${countByStatus(DFCCapabilityStatus.deferred)}',
    ];
  }
}
