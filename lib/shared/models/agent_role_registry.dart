import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Fixed role ordering for the DFC automation chain.
enum FeedAgentRole {
  headOfDev,
  sourceIntake,
  normalization,
  trustSafety,
  ranking,
  publisher,
  audit,
}

/// Fixed pipeline stages for automated feed processing.
enum FeedPipelineStage {
  sourceIntake,
  normalize,
  trustSafety,
  rank,
  publish,
  audit,
  failed,
}

class AgentRoleDefinition extends Equatable {
  final FeedAgentRole role;
  final String label;
  final String responsibility;

  const AgentRoleDefinition({
    required this.role,
    required this.label,
    required this.responsibility,
  });

  @override
  List<Object?> get props => [role, label, responsibility];
}

class FeedPipelineEvent extends Equatable {
  final String runId;
  final FeedPipelineStage stage;
  final FeedAgentRole role;
  final bool success;
  final String message;
  final DateTime timestamp;

  const FeedPipelineEvent({
    required this.runId,
    required this.stage,
    required this.role,
    required this.success,
    required this.message,
    required this.timestamp,
  });

  factory FeedPipelineEvent.fromMap(Map<String, dynamic> data) {
    return FeedPipelineEvent(
      runId: (data['runId'] ?? '').toString(),
      stage: AgentRoleRegistry.stageFromName((data['stage'] ?? '').toString()),
      role: AgentRoleRegistry.roleFromName((data['role'] ?? '').toString()),
      success: data['success'] == true,
      message: (data['message'] ?? '').toString(),
      timestamp: _timestampFrom(data['timestamp']),
    );
  }

  static DateTime _timestampFrom(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }

  @override
  List<Object?> get props => [runId, stage, role, success, message, timestamp];
}

class AgentRoleRegistry {
  static const orderedRoles = <AgentRoleDefinition>[
    AgentRoleDefinition(
      role: FeedAgentRole.headOfDev,
      label: 'Head Of Dev',
      responsibility:
          'Owns orchestration order, policy, and final release gate.',
    ),
    AgentRoleDefinition(
      role: FeedAgentRole.sourceIntake,
      label: 'Source Intake Agent',
      responsibility: 'Collects raw feed items from approved sources only.',
    ),
    AgentRoleDefinition(
      role: FeedAgentRole.normalization,
      label: 'Normalization Agent',
      responsibility:
          'Converts raw source payloads into DFC canonical feed shape.',
    ),
    AgentRoleDefinition(
      role: FeedAgentRole.trustSafety,
      label: 'Trust & Safety Agent',
      responsibility:
          'Validates source trust, text safety, and amplification eligibility.',
    ),
    AgentRoleDefinition(
      role: FeedAgentRole.ranking,
      label: 'Ranking Agent',
      responsibility: 'Prioritizes already-approved items using feed strategy.',
    ),
    AgentRoleDefinition(
      role: FeedAgentRole.publisher,
      label: 'Publisher Agent',
      responsibility:
          'Publishes approved payloads into existing app surfaces only.',
    ),
    AgentRoleDefinition(
      role: FeedAgentRole.audit,
      label: 'Audit Agent',
      responsibility:
          'Logs chain health, failures, rejections, and stale inputs.',
    ),
  ];

  static const orderedStages = <FeedPipelineStage>[
    FeedPipelineStage.sourceIntake,
    FeedPipelineStage.normalize,
    FeedPipelineStage.trustSafety,
    FeedPipelineStage.rank,
    FeedPipelineStage.publish,
    FeedPipelineStage.audit,
  ];

  static bool canAdvance({
    FeedPipelineStage? previous,
    required FeedPipelineStage next,
  }) {
    if (next == FeedPipelineStage.failed) return true;
    if (previous == null) {
      return next == FeedPipelineStage.sourceIntake;
    }

    final previousIndex = orderedStages.indexOf(previous);
    final nextIndex = orderedStages.indexOf(next);
    return previousIndex != -1 && nextIndex == previousIndex + 1;
  }

  static FeedAgentRole roleForStage(FeedPipelineStage stage) {
    switch (stage) {
      case FeedPipelineStage.sourceIntake:
        return FeedAgentRole.sourceIntake;
      case FeedPipelineStage.normalize:
        return FeedAgentRole.normalization;
      case FeedPipelineStage.trustSafety:
        return FeedAgentRole.trustSafety;
      case FeedPipelineStage.rank:
        return FeedAgentRole.ranking;
      case FeedPipelineStage.publish:
        return FeedAgentRole.publisher;
      case FeedPipelineStage.audit:
      case FeedPipelineStage.failed:
        return FeedAgentRole.audit;
    }
  }

  static FeedPipelineStage stageFromName(String name) {
    return FeedPipelineStage.values.firstWhere(
      (stage) => stage.name == name,
      orElse: () => FeedPipelineStage.failed,
    );
  }

  static FeedAgentRole roleFromName(String name) {
    return FeedAgentRole.values.firstWhere(
      (role) => role.name == name,
      orElse: () => FeedAgentRole.audit,
    );
  }
}
