import 'ecosystem_state_service.dart';
import 'auto_feed_orchestrator_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ECOSYSTEM FEEDBACK ENGINE — Bidirectional Signal Feedback
/// ═══════════════════════════════════════════════════════════════════════════
/// Channels feedback from ecosystem events back into opportunity scoring.
/// Creates self-reinforcing loop: wins → signal boost → higher ranking → more wins
class EcosystemFeedbackEngine {
  final EcosystemStateService ecosystemState;
  final AutoFeedOrchestratorService orchestrator;

  // Feedback boost multipliers
  static const double dealClosedBoost = 0.15;
  static const double youtubeGenerationBoost = 0.08;
  static const double highEngagementBoost = 0.10;
  static const double stageAdvancementBoost = 0.05;

  EcosystemFeedbackEngine({
    required this.ecosystemState,
    required this.orchestrator,
  });

  /// Process feedback event and update opportunity scores
  /// This creates the bidirectional loop: outcome → signal boost → higher ranking
  void processFeedbackEvent(EcosystemFeedbackEvent event) {
    switch (event.eventType) {
      case 'deal_closed':
        _handleDealClosed(event);
        break;
      case 'youtube_brief_generated':
        _handleYoutubeBriefGenerated(event);
        break;
      case 'stage_advanced':
        _handleStageAdvanced(event);
        break;
      case 'outreach_engagement':
        _handleOutreachEngagement(event);
        break;
      default:
        // Other events logged but no scoring impact
        break;
    }
  }

  /// Deal closed: boost signal strength for similar opportunities
  /// Next time we see similar signals/source, they rank higher
  void _handleDealClosed(EcosystemFeedbackEvent event) {
    // Find the opportunity in the pipeline to get its signals
    final stageOp = _findOpportunityInPipeline(event.opportunityId);
    if (stageOp == null) return;

    // For each signal in this winning opportunity, boost future opportunities with same signals
    for (final signal in stageOp.commandSignals) {
      orchestrator.addSignalBoost(
        signal,
        dealClosedBoost,
        reason: 'deal_closed_feedback_${event.opportunityId}',
      );
    }

    // Also boost the source (e.g., if this UFC promotion closed, UFC promotions rank higher)
    orchestrator.addSourceBoost(
      event.source,
      dealClosedBoost * 0.8,
      reason: 'winning_source_${event.source}',
    );
  }

  /// YouTube brief generated: opportunities moving to execution phase get slight boost
  void _handleYoutubeBriefGenerated(EcosystemFeedbackEvent event) {
    final stageOp = _findOpportunityInPipeline(event.opportunityId);
    if (stageOp == null) return;

    // Boost Samurai/Joseph/Legends signals since they're moving to content phase
    if (stageOp.commandSignals.contains('samurai-promotion')) {
      orchestrator.addSignalBoost(
        'samurai-promotion',
        youtubeGenerationBoost * 1.2,
        reason: 'samurai_youtube_executed',
      );
    }
    if (stageOp.commandSignals.contains('joseph-priority')) {
      orchestrator.addSignalBoost(
        'joseph-priority',
        youtubeGenerationBoost,
        reason: 'joseph_youtube_executed',
      );
    }
    if (stageOp.commandSignals.contains('legends-show')) {
      orchestrator.addSignalBoost(
        'legends-show',
        youtubeGenerationBoost,
        reason: 'legends_youtube_executed',
      );
    }
  }

  /// Stage advancement: opportunity moved forward = execution momentum
  /// Boost other opportunities with same signals to increase throughput
  void _handleStageAdvanced(EcosystemFeedbackEvent event) {
    final transition = event.stageTransition;
    if (transition == null) return;

    final stageOp = _findOpportunityInPipeline(event.opportunityId);
    if (stageOp == null) return;

    // Slight boost to all signals in this advancing opportunity
    for (final signal in stageOp.commandSignals) {
      orchestrator.addSignalBoost(
        signal,
        stageAdvancementBoost,
        reason: 'stage_advanced_${transition.reason}',
      );
    }
  }

  /// Outreach engagement: high engagement = signal quality
  /// Future opportunities with same signals should rank higher
  void _handleOutreachEngagement(EcosystemFeedbackEvent event) {
    final stageOp = _findOpportunityInPipeline(event.opportunityId);
    if (stageOp == null) return;

    // Track engagement and boost signals if response rate is high
    // This creates self-reinforcing loop: good outreach → engagement → signal boost → similar opportunities rank higher
    for (final signal in stageOp.commandSignals) {
      orchestrator.addSignalBoost(
        signal,
        highEngagementBoost * 0.6,
        reason: 'outreach_engagement_${event.metricDelta}',
      );
    }
  }

  /// Find opportunity anywhere in pipeline
  OpportunityStageItem? _findOpportunityInPipeline(String opportunityId) {
    for (final stage in ecosystemState.stageOpportunities.values) {
      try {
        return stage.firstWhere((op) => op.opportunityId == opportunityId);
      } catch (e) {
        // Not in this stage, continue
      }
    }
    return null;
  }
}

/// Extension on AutoFeedOrchestratorService to support feedback boosts
extension FeedbackBoosts on AutoFeedOrchestratorService {
  // Temporary signal boost cache (in production, would be persisted)
  static final Map<String, double> _signalBoosts = {};
  static final Map<String, double> _sourceBoosts = {};

  /// Add temporary boost to a signal (multiplied into future scoring)
  void addSignalBoost(String signal, double boost, {required String reason}) {
    final existing = _signalBoosts[signal] ?? 0.0;
    _signalBoosts[signal] = (existing + boost).clamp(0.0, 0.5);
  }

  /// Add temporary boost to a source (multiplied into future scoring)
  void addSourceBoost(String source, double boost, {required String reason}) {
    final existing = _sourceBoosts[source] ?? 0.0;
    _sourceBoosts[source] = (existing + boost).clamp(0.0, 0.3);
  }

  /// Get current boost for a signal
  double getSignalBoost(String signal) => _signalBoosts[signal] ?? 0.0;

  /// Get current boost for a source
  double getSourceBoost(String source) => _sourceBoosts[source] ?? 0.0;

  /// Clear all boosts (for testing or reset)
  void clearAllBoosts() {
    _signalBoosts.clear();
    _sourceBoosts.clear();
  }
}
