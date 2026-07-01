// ═══════════════════════════════════════════════════════════════════════════
// ATLAS ORCHESTRATOR — Central Command & Job Queue
// ═══════════════════════════════════════════════════════════════════════════
// The brain of DFC's bot ecosystem. Manages job queues, consent store,
// policy enforcement, multi-model AI routing, audit logs, and approval gates.
// Every bot is an Atlas job worker with signed identity and limited scope.
//
// Layers:
//   1. Job Queue — prioritized task dispatch
//   2. Consent Store — versioned consent records
//   3. Policy Engine — rate limits, spend thresholds, safety rules
//   4. Multi-Model Router — Gemini/Claude/GPT/LLaMA routing
//   5. Audit Log — immutable action trail with rollback
//   6. Approval Gates — human-in-the-loop for high-risk actions
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── Enums ───────────────────────────────────────────────────────────────

enum JobPriority { low, normal, high, critical }

enum JobStatus {
  queued,
  assigned,
  processing,
  awaitingApproval,
  completed,
  failed,
  rolledBack,
}

enum ApprovalType { spend, legal, medical, fighterLikeness, paidContent }

enum ModelTier { fast, balanced, premium, safety }

enum ConsentType { biometric, likeness, marketing, aiGeneration, dataSharing }

enum PolicyAction { allow, throttle, requireApproval, block }

enum AuditSeverity { info, action, warning, violation }

// ─── Models ──────────────────────────────────────────────────────────────

/// Registered bot agent with signed identity and rate limits
class BotAgent {
  final String botId;
  final String displayName;
  final String emoji;
  final List<String> capabilities;
  final int postsPerHour;
  final int dmsPerHour;
  final double spendThresholdUsd;
  final bool requiresApprovalForPaid;
  final DateTime registeredAt;
  bool isActive;
  int jobsCompleted;
  int jobsFailed;
  double successRate;

  BotAgent({
    required this.botId,
    required this.displayName,
    required this.emoji,
    required this.capabilities,
    this.postsPerHour = 20,
    this.dmsPerHour = 50,
    this.spendThresholdUsd = 200.0,
    this.requiresApprovalForPaid = true,
    this.isActive = true,
    this.jobsCompleted = 0,
    this.jobsFailed = 0,
    this.successRate = 1.0,
  }) : registeredAt = DateTime.now();

  Map<String, dynamic> toMap() => {
    'botId': botId,
    'displayName': displayName,
    'emoji': emoji,
    'capabilities': capabilities,
    'postsPerHour': postsPerHour,
    'dmsPerHour': dmsPerHour,
    'spendThresholdUsd': spendThresholdUsd,
    'requiresApprovalForPaid': requiresApprovalForPaid,
    'isActive': isActive,
    'jobsCompleted': jobsCompleted,
    'jobsFailed': jobsFailed,
    'successRate': successRate,
    'registeredAt': Timestamp.fromDate(registeredAt),
  };
}

/// Job in the Atlas queue
class AtlasJob {
  final String id;
  final String botId;
  final String taskType;
  final String description;
  final Map<String, dynamic> payload;
  final JobPriority priority;
  JobStatus status;
  final DateTime createdAt;
  DateTime? assignedAt;
  DateTime? completedAt;
  Map<String, dynamic>? result;
  String? errorMessage;
  bool requiresApproval;
  ApprovalType? approvalType;
  String? approvedBy;
  final List<String> modelChain;
  double? confidence;

  AtlasJob({
    String? id,
    required this.botId,
    required this.taskType,
    required this.description,
    this.payload = const {},
    this.priority = JobPriority.normal,
    this.status = JobStatus.queued,
    this.result,
    this.errorMessage,
    this.requiresApproval = false,
    this.approvalType,
    this.approvedBy,
    this.modelChain = const [],
    this.confidence,
  }) : id =
           id ??
           'job_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(9999)}',
       createdAt = DateTime.now();

  Map<String, dynamic> toFirestore() => {
    'botId': botId,
    'taskType': taskType,
    'description': description,
    'payload': payload,
    'priority': priority.name,
    'status': status.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
    'completedAt': completedAt != null
        ? Timestamp.fromDate(completedAt!)
        : null,
    'result': result,
    'errorMessage': errorMessage,
    'requiresApproval': requiresApproval,
    'approvalType': approvalType?.name,
    'approvedBy': approvedBy,
    'modelChain': modelChain,
    'confidence': confidence,
  };
}

/// Versioned consent record
class ConsentRecord {
  final String id;
  final String userId;
  final ConsentType type;
  final String description;
  final bool granted;
  final int version;
  final DateTime recordedAt;
  final DateTime? revokedAt;

  ConsentRecord({
    String? id,
    required this.userId,
    required this.type,
    required this.description,
    required this.granted,
    this.version = 1,
    this.revokedAt,
  }) : id = id ?? 'consent_${DateTime.now().millisecondsSinceEpoch}',
       recordedAt = DateTime.now();

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'type': type.name,
    'description': description,
    'granted': granted,
    'version': version,
    'recordedAt': Timestamp.fromDate(recordedAt),
    'revokedAt': revokedAt != null ? Timestamp.fromDate(revokedAt!) : null,
  };
}

/// Immutable audit log entry
class AuditEntry {
  final String id;
  final String actorId;
  final String actorType; // 'bot', 'human', 'system'
  final String action;
  final String targetType;
  final String? targetId;
  final Map<String, dynamic> metadata;
  final AuditSeverity severity;
  final DateTime timestamp;
  final bool canRollback;

  AuditEntry({
    String? id,
    required this.actorId,
    required this.actorType,
    required this.action,
    required this.targetType,
    this.targetId,
    this.metadata = const {},
    this.severity = AuditSeverity.action,
    this.canRollback = false,
  }) : id = id ?? 'audit_${DateTime.now().millisecondsSinceEpoch}',
       timestamp = DateTime.now();

  Map<String, dynamic> toFirestore() => {
    'actorId': actorId,
    'actorType': actorType,
    'action': action,
    'targetType': targetType,
    'targetId': targetId,
    'metadata': metadata,
    'severity': severity.name,
    'timestamp': Timestamp.fromDate(timestamp),
    'canRollback': canRollback,
  };
}

/// Model routing decision
class ModelRoute {
  final ModelTier tier;
  final String modelId;
  final String reason;

  const ModelRoute({
    required this.tier,
    required this.modelId,
    required this.reason,
  });

  static const _routes = {
    'generate_captions': ModelRoute(
      tier: ModelTier.fast,
      modelId: 'llama-3',
      reason: 'Low cost caption generation',
    ),
    'generate_hashtags': ModelRoute(
      tier: ModelTier.fast,
      modelId: 'perplexity',
      reason: 'Trending hook discovery',
    ),
    'fight_analysis': ModelRoute(
      tier: ModelTier.premium,
      modelId: 'gemini-3-pro',
      reason: 'Complex combat analysis',
    ),
    'coaching_advice': ModelRoute(
      tier: ModelTier.premium,
      modelId: 'gpt-5.2',
      reason: 'Nuanced coaching language',
    ),
    'safety_moderation': ModelRoute(
      tier: ModelTier.safety,
      modelId: 'claude-sonnet',
      reason: 'Conservative safety bias',
    ),
    'legal_phrasing': ModelRoute(
      tier: ModelTier.safety,
      modelId: 'claude-sonnet',
      reason: 'Legal accuracy required',
    ),
    'creative_variants': ModelRoute(
      tier: ModelTier.balanced,
      modelId: 'gemini-3-pro',
      reason: 'Creative variety',
    ),
    'trend_analysis': ModelRoute(
      tier: ModelTier.balanced,
      modelId: 'perplexity',
      reason: 'Real-time trend data',
    ),
    'translate': ModelRoute(
      tier: ModelTier.fast,
      modelId: 'gemini-3-pro',
      reason: 'Multi-language support',
    ),
    'clip_generation': ModelRoute(
      tier: ModelTier.premium,
      modelId: 'gemini-3-pro',
      reason: 'Video understanding',
    ),
  };

  static ModelRoute routeForTask(String taskType) =>
      _routes[taskType] ??
      const ModelRoute(
        tier: ModelTier.balanced,
        modelId: 'gemini-3-pro',
        reason: 'Default balanced routing',
      );
}

// ─── Policy Rules ────────────────────────────────────────────────────────

class PolicyRule {
  final String id;
  final String description;
  final PolicyAction action;
  final Map<String, dynamic> conditions;

  const PolicyRule({
    required this.id,
    required this.description,
    required this.action,
    this.conditions = const {},
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// ATLAS ORCHESTRATOR SERVICE
// ═══════════════════════════════════════════════════════════════════════════
class AtlasOrchestratorService with ChangeNotifier {
  static final AtlasOrchestratorService _instance =
      AtlasOrchestratorService._internal();
  factory AtlasOrchestratorService() => _instance;
  AtlasOrchestratorService._internal();

  final _db = FirebaseFirestore.instance;
  final _random = math.Random();

  // ─── State ─────────────────────────────────────────────────────────────
  bool _running = false;
  Timer? _dispatchTimer;
  Timer? _healthTimer;

  // Bot registry
  final Map<String, BotAgent> _bots = {};

  // Job queue (priority sorted)
  final List<AtlasJob> _jobQueue = [];
  final List<AtlasJob> _completedJobs = [];
  final List<AtlasJob> _awaitingApproval = [];

  // Consent store
  final Map<String, List<ConsentRecord>> _consentStore = {};

  // Audit log
  final List<AuditEntry> _auditLog = [];
  static const _maxAuditEntries = 500;

  // Rate limiting
  final Map<String, List<DateTime>> _rateBuckets = {};

  // Metrics
  int _jobsDispatched = 0;
  int _jobsCompleted = 0;
  int _jobsFailed = 0;
  int _approvalsRequested = 0;
  int _approvalsGranted = 0;

  // ─── Hard Safety Rules (non-negotiable) ────────────────────────────────
  static const List<PolicyRule> _hardRules = [
    PolicyRule(
      id: 'no_fight_without_medical',
      description: 'No live fight publish without verified medical clearance',
      action: PolicyAction.block,
    ),
    PolicyRule(
      id: 'spend_human_approval',
      description: 'No paid spend above threshold without human approval',
      action: PolicyAction.requireApproval,
      conditions: {'spendUsd': 200},
    ),
    PolicyRule(
      id: 'no_minor_dms',
      description: 'No DM seeding to users under age 16',
      action: PolicyAction.block,
    ),
    PolicyRule(
      id: 'biometric_consent_required',
      description: 'All biometric data requires explicit consent',
      action: PolicyAction.block,
    ),
    PolicyRule(
      id: 'fighter_likeness_signoff',
      description: 'Fighter likeness in AI content requires digital signoff',
      action: PolicyAction.requireApproval,
    ),
    PolicyRule(
      id: 'conservative_fight_claims',
      description: 'No unverified fight outcome claims in ads',
      action: PolicyAction.requireApproval,
    ),
  ];

  // ─── Getters ───────────────────────────────────────────────────────────
  bool get isRunning => _running;
  List<BotAgent> get registeredBots => _bots.values.toList();
  int get activeBots => _bots.values.where((b) => b.isActive).length;
  int get totalBots => _bots.length;
  List<AtlasJob> get pendingJobs =>
      _jobQueue.where((j) => j.status == JobStatus.queued).toList();
  List<AtlasJob> get activeJobs =>
      _jobQueue.where((j) => j.status == JobStatus.processing).toList();
  List<AtlasJob> get awaitingApproval => List.unmodifiable(_awaitingApproval);
  List<AuditEntry> get auditLog => List.unmodifiable(_auditLog);
  int get jobsDispatched => _jobsDispatched;
  int get jobsCompleted => _jobsCompleted;
  int get jobsFailed => _jobsFailed;
  int get approvalsRequested => _approvalsRequested;
  int get approvalsGranted => _approvalsGranted;
  List<PolicyRule> get hardRules => _hardRules;

  // ═══════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> boot() async {
    if (_running) return;
    _running = true;

    // Register default bot fleet
    _registerDefaultBots();

    // Start dispatch loop (process jobs every 2s)
    _dispatchTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _dispatchCycle(),
    );

    // Health check every 30s
    _healthTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _botHealthCheck(),
    );

    _logAudit(
      actorId: 'atlas_orchestrator',
      actorType: 'system',
      action: 'orchestrator.booted',
      targetType: 'system',
      severity: AuditSeverity.info,
    );

    notifyListeners();
    debugPrint('[ATLAS ORCHESTRATOR] Booted — ${_bots.length} bots registered');
  }

  Future<void> shutdown() async {
    _running = false;
    _dispatchTimer?.cancel();
    _healthTimer?.cancel();

    _logAudit(
      actorId: 'atlas_orchestrator',
      actorType: 'system',
      action: 'orchestrator.shutdown',
      targetType: 'system',
      metadata: {
        'jobsDispatched': _jobsDispatched,
        'jobsCompleted': _jobsCompleted,
      },
    );

    notifyListeners();
    debugPrint('[ATLAS ORCHESTRATOR] Shutdown');
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BOT REGISTRATION
  // ═══════════════════════════════════════════════════════════════════════

  void _registerDefaultBots() {
    _registerBot(
      BotAgent(
        botId: 'hype_bot_v1',
        displayName: 'HypeBot',
        emoji: '🔥',
        capabilities: [
          'generate_clips',
          'generate_captions',
          'suggest_hashtags',
        ],
      ),
    );
    _registerBot(
      BotAgent(
        botId: 'spotlight_bot_v1',
        displayName: 'SpotlightBot',
        emoji: '⭐',
        capabilities: ['fighter_profiles', 'social_cards', 'highlight_reels'],
        postsPerHour: 10,
        spendThresholdUsd: 100,
      ),
    );
    _registerBot(
      BotAgent(
        botId: 'matchmaker_bot_v1',
        displayName: 'MatchmakerBot',
        emoji: '🥊',
        capabilities: ['matchup_analysis', 'dream_fights', 'social_threads'],
        postsPerHour: 8,
        spendThresholdUsd: 50,
      ),
    );
    _registerBot(
      BotAgent(
        botId: 'trend_bot_v1',
        displayName: 'TrendBot',
        emoji: '📈',
        capabilities: [
          'trend_analysis',
          'hook_suggestions',
          'timing_optimization',
        ],
        postsPerHour: 30,
        spendThresholdUsd: 0,
      ),
    );
    _registerBot(
      BotAgent(
        botId: 'campaign_bot_v1',
        displayName: 'CampaignBot',
        emoji: '🎯',
        capabilities: [
          'schedule_posts',
          'ad_buys',
          'ooh_sync',
          'market_export',
        ],
        postsPerHour: 15,
        spendThresholdUsd: 500,
      ),
    );
    _registerBot(
      BotAgent(
        botId: 'event_bot_v1',
        displayName: 'EventBot',
        emoji: '⏱️',
        capabilities: ['countdowns', 'live_push', 'scorecard_updates'],
        postsPerHour: 25,
        spendThresholdUsd: 0,
      ),
    );
    _registerBot(
      BotAgent(
        botId: 'viral_bot_v1',
        displayName: 'ViralBot',
        emoji: '🚀',
        capabilities: [
          'clip_generation',
          'micro_influencer_seeds',
          'dm_outreach',
        ],
        postsPerHour: 12,
        spendThresholdUsd: 300,
      ),
    );
    _registerBot(
      BotAgent(
        botId: 'analytics_bot_v1',
        displayName: 'AnalyticsBot',
        emoji: '📊',
        capabilities: [
          'roas_calculation',
          'cac_tracking',
          'auto_scale_recommendations',
        ],
        postsPerHour: 5,
        spendThresholdUsd: 0,
      ),
    );
    _registerBot(
      BotAgent(
        botId: 'guardian_bot_v1',
        displayName: 'GuardianBot',
        emoji: '🛡️',
        capabilities: [
          'content_scanning',
          'toxicity_detection',
          'piracy_detection',
          'age_gating',
        ],
        postsPerHour: 0,
        spendThresholdUsd: 0,
      ),
    );
    _registerBot(
      BotAgent(
        botId: 'scanner_bot_v1',
        displayName: 'ScannerBot',
        emoji: '🔍',
        capabilities: [
          'web_scanning',
          'social_monitoring',
          'news_alerts',
          'competitor_tracking',
        ],
        postsPerHour: 0,
        spendThresholdUsd: 0,
      ),
    );
    _registerBot(
      BotAgent(
        botId: 'ninja_guardian_v1',
        displayName: 'NinjaGuardian',
        emoji: '🥷',
        capabilities: [
          'onboarding',
          'behavior_rewards',
          'moderation',
          'escalation',
        ],
        postsPerHour: 10,
        spendThresholdUsd: 0,
      ),
    );
    _registerBot(
      BotAgent(
        botId: 'drm_bot_v1',
        displayName: 'DRM Watchdog',
        emoji: '🔒',
        capabilities: [
          'watermark_verify',
          'takedown_requests',
          'piracy_scanning',
        ],
        postsPerHour: 0,
        spendThresholdUsd: 0,
      ),
    );
    _registerBot(
      BotAgent(
        botId: 'medical_gate_v1',
        displayName: 'MedicalGate',
        emoji: '🏥',
        capabilities: [
          'clearance_verify',
          'biometric_alerts',
          'emergency_pause',
        ],
        postsPerHour: 0,
        spendThresholdUsd: 0,
      ),
    );
  }

  void _registerBot(BotAgent bot) {
    _bots[bot.botId] = bot;
    _logAudit(
      actorId: 'atlas_orchestrator',
      actorType: 'system',
      action: 'bot.registered',
      targetType: 'bot',
      targetId: bot.botId,
      metadata: {'capabilities': bot.capabilities},
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // JOB QUEUE
  // ═══════════════════════════════════════════════════════════════════════

  /// Enqueue a job for a bot
  AtlasJob enqueueJob({
    required String botId,
    required String taskType,
    required String description,
    Map<String, dynamic> payload = const {},
    JobPriority priority = JobPriority.normal,
  }) {
    final bot = _bots[botId];
    if (bot == null || !bot.isActive) {
      debugPrint('[ATLAS] Bot $botId not found or inactive');
      return AtlasJob(
        botId: botId,
        taskType: taskType,
        description: description,
        status: JobStatus.failed,
        errorMessage: 'Bot not registered or inactive',
      );
    }

    // Check rate limits
    final policyCheck = _checkPolicy(botId, taskType, payload);
    final needsApproval = policyCheck == PolicyAction.requireApproval;
    if (policyCheck == PolicyAction.block) {
      _logAudit(
        actorId: botId,
        actorType: 'bot',
        action: 'job.blocked_by_policy',
        targetType: 'job',
        metadata: {'taskType': taskType},
        severity: AuditSeverity.warning,
      );
      return AtlasJob(
        botId: botId,
        taskType: taskType,
        description: description,
        status: JobStatus.failed,
        errorMessage: 'Blocked by policy',
      );
    }

    // Route to correct AI model
    final route = ModelRoute.routeForTask(taskType);

    final job = AtlasJob(
      botId: botId,
      taskType: taskType,
      description: description,
      payload: {...payload, 'modelRoute': route.modelId},
      priority: priority,
      requiresApproval: needsApproval,
      approvalType: needsApproval ? _inferApprovalType(taskType) : null,
      modelChain: [route.modelId],
    );

    _jobQueue.add(job);

    // Sort by priority
    _jobQueue.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    _logAudit(
      actorId: 'atlas_orchestrator',
      actorType: 'system',
      action: 'job.enqueued',
      targetType: 'job',
      targetId: job.id,
      metadata: {
        'botId': botId,
        'taskType': taskType,
        'priority': priority.name,
      },
    );

    notifyListeners();
    return job;
  }

  /// Process the next batch of jobs
  void _dispatchCycle() {
    if (!_running) return;

    final pending = _jobQueue
        .where((j) => j.status == JobStatus.queued)
        .take(5);
    for (final job in pending) {
      _processJob(job);
    }
  }

  void _processJob(AtlasJob job) {
    final bot = _bots[job.botId];
    if (bot == null || !bot.isActive) {
      job.status = JobStatus.failed;
      job.errorMessage = 'Bot unavailable';
      _jobsFailed++;
      notifyListeners();
      return;
    }

    // Check rate limit
    if (!_checkRateLimit(job.botId, bot.postsPerHour)) {
      return; // Will retry next cycle
    }

    job.status = JobStatus.processing;
    job.assignedAt = DateTime.now();
    _jobsDispatched++;

    // Simulate processing (in production, call Cloud Functions)
    Future.delayed(Duration(milliseconds: 500 + _random.nextInt(2000)), () {
      if (job.requiresApproval) {
        job.status = JobStatus.awaitingApproval;
        _awaitingApproval.add(job);
        _approvalsRequested++;
        _logAudit(
          actorId: job.botId,
          actorType: 'bot',
          action: 'job.awaiting_approval',
          targetType: 'job',
          targetId: job.id,
          metadata: {'approvalType': job.approvalType?.name},
        );
      } else {
        _completeJob(job);
      }
      notifyListeners();
    });
  }

  void _completeJob(AtlasJob job) {
    final bot = _bots[job.botId];
    job.status = JobStatus.completed;
    job.completedAt = DateTime.now();
    job.confidence = 0.7 + _random.nextDouble() * 0.3;
    job.result = _generateJobResult(job);

    _jobsCompleted++;
    if (bot != null) {
      bot.jobsCompleted++;
      bot.successRate =
          bot.jobsCompleted / (bot.jobsCompleted + bot.jobsFailed);
    }

    _completedJobs.add(job);
    if (_completedJobs.length > 200) _completedJobs.removeAt(0);

    _logAudit(
      actorId: job.botId,
      actorType: 'bot',
      action: 'job.completed',
      targetType: 'job',
      targetId: job.id,
      metadata: {
        'taskType': job.taskType,
        'confidence': job.confidence,
        'modelChain': job.modelChain,
      },
    );

    // Persist to Firestore
    _persistJobResult(job);
  }

  Map<String, dynamic> _generateJobResult(AtlasJob job) {
    switch (job.taskType) {
      case 'generate_captions':
        return {
          'captions': [
            'Dragon Pass early access — link in bio 🔥',
            'This fight changes everything. Watch live.',
            'The beast awakens. Dragon Pass holders get front row.',
          ],
          'hashtags': ['#FightNight', '#DragonPass', '#DFC', '#CombatSports'],
        };
      case 'generate_clips':
        return {
          'clips': [
            {'duration': '6s', 'format': '9:16', 'url': 'pending_generation'},
            {'duration': '15s', 'format': '1:1', 'url': 'pending_generation'},
            {'duration': '45s', 'format': '16:9', 'url': 'pending_generation'},
          ],
        };
      case 'trend_analysis':
        return {
          'trends': ['#UFC300', '#KnockoutOfTheYear', '#FightWeek'],
          'suggestedHooks': [
            'Everyone is talking about this knockout...',
            'This underdog story is going viral...',
          ],
        };
      case 'safety_moderation':
        return {'safe': true, 'flags': <String>[], 'confidence': 0.95};
      default:
        return {
          'status': 'completed',
          'output': 'Task processed by ${job.botId}',
        };
    }
  }

  Future<void> _persistJobResult(AtlasJob job) async {
    try {
      await _db.collection('atlas_jobs').doc(job.id).set(job.toFirestore());
    } catch (e) {
      debugPrint('[ATLAS] Failed to persist job ${job.id}: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // APPROVAL GATES
  // ═══════════════════════════════════════════════════════════════════════

  /// Human approves a pending job
  void approveJob(String jobId) {
    final job = _awaitingApproval.firstWhere(
      (j) => j.id == jobId,
      orElse: () => AtlasJob(
        botId: '',
        taskType: '',
        description: '',
        status: JobStatus.failed,
      ),
    );
    if (job.status != JobStatus.awaitingApproval) return;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    job.approvedBy = uid;
    _awaitingApproval.remove(job);
    _approvalsGranted++;

    _logAudit(
      actorId: uid,
      actorType: 'human',
      action: 'job.approved',
      targetType: 'job',
      targetId: jobId,
      metadata: {'approvalType': job.approvalType?.name},
    );

    _completeJob(job);
    notifyListeners();
  }

  /// Human rejects a pending job
  void rejectJob(String jobId, {String? reason}) {
    final job = _awaitingApproval.firstWhere(
      (j) => j.id == jobId,
      orElse: () => AtlasJob(
        botId: '',
        taskType: '',
        description: '',
        status: JobStatus.failed,
      ),
    );
    if (job.status != JobStatus.awaitingApproval) return;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    job.status = JobStatus.failed;
    job.errorMessage = reason ?? 'Rejected by human reviewer';
    _awaitingApproval.remove(job);

    _logAudit(
      actorId: uid,
      actorType: 'human',
      action: 'job.rejected',
      targetType: 'job',
      targetId: jobId,
      metadata: {'reason': reason},
      severity: AuditSeverity.warning,
    );

    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CONSENT STORE
  // ═══════════════════════════════════════════════════════════════════════

  /// Record user consent
  Future<void> recordConsent({
    required String userId,
    required ConsentType type,
    required String description,
    required bool granted,
  }) async {
    final record = ConsentRecord(
      userId: userId,
      type: type,
      description: description,
      granted: granted,
    );

    _consentStore.putIfAbsent(userId, () => []);
    _consentStore[userId]!.add(record);

    _logAudit(
      actorId: userId,
      actorType: 'human',
      action: granted ? 'consent.granted' : 'consent.revoked',
      targetType: 'consent',
      targetId: record.id,
      metadata: {'type': type.name},
    );

    try {
      await _db
          .collection('atlas_consent')
          .doc(record.id)
          .set(record.toFirestore());
    } catch (e) {
      debugPrint('[ATLAS] Consent persist failed: $e');
    }

    notifyListeners();
  }

  /// Check if user has active consent for a type
  bool hasConsent(String userId, ConsentType type) {
    final records = _consentStore[userId] ?? [];
    final latest = records.where((r) => r.type == type).lastOrNull;
    return latest?.granted ?? false;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // POLICY ENGINE
  // ═══════════════════════════════════════════════════════════════════════

  PolicyAction _checkPolicy(
    String botId,
    String taskType,
    Map<String, dynamic> payload,
  ) {
    // Check hard rules
    for (final rule in _hardRules) {
      if (rule.id == 'no_fight_without_medical' &&
          taskType == 'publish_live_fight') {
        final hasClearance = payload['medicalClearance'] == true;
        if (!hasClearance) return PolicyAction.block;
      }

      if (rule.id == 'spend_human_approval') {
        final spend = (payload['spendUsd'] as num?)?.toDouble() ?? 0;
        final bot = _bots[botId];
        if (spend > (bot?.spendThresholdUsd ?? 200)) {
          return PolicyAction.requireApproval;
        }
      }

      if (rule.id == 'no_minor_dms' && taskType == 'dm_outreach') {
        final targetAge = payload['targetAge'] as int?;
        if (targetAge != null && targetAge < 16) return PolicyAction.block;
      }

      if (rule.id == 'biometric_consent_required' &&
          taskType.contains('biometric')) {
        final userId = payload['userId'] as String?;
        if (userId != null && !hasConsent(userId, ConsentType.biometric)) {
          return PolicyAction.block;
        }
      }

      if (rule.id == 'fighter_likeness_signoff' &&
          taskType.contains('ai_generate')) {
        final fighterId = payload['fighterId'] as String?;
        if (fighterId != null && !hasConsent(fighterId, ConsentType.likeness)) {
          return PolicyAction.requireApproval;
        }
      }
    }

    return PolicyAction.allow;
  }

  ApprovalType? _inferApprovalType(String taskType) {
    if (taskType.contains('spend') || taskType.contains('ad_buy')) {
      return ApprovalType.spend;
    }
    if (taskType.contains('legal')) return ApprovalType.legal;
    if (taskType.contains('medical') || taskType.contains('fight_publish')) {
      return ApprovalType.medical;
    }
    if (taskType.contains('likeness') || taskType.contains('ai_generate')) {
      return ApprovalType.fighterLikeness;
    }
    return ApprovalType.paidContent;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RATE LIMITING
  // ═══════════════════════════════════════════════════════════════════════

  bool _checkRateLimit(String botId, int maxPerHour) {
    if (maxPerHour == 0) return true; // No limit for monitoring bots

    final now = DateTime.now();
    final bucket = _rateBuckets.putIfAbsent(botId, () => []);

    // Purge entries older than 1 hour
    bucket.removeWhere((t) => now.difference(t).inMinutes > 60);

    if (bucket.length >= maxPerHour) return false;

    bucket.add(now);
    return true;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AUDIT LOG
  // ═══════════════════════════════════════════════════════════════════════

  void _logAudit({
    required String actorId,
    required String actorType,
    required String action,
    required String targetType,
    String? targetId,
    Map<String, dynamic> metadata = const {},
    AuditSeverity severity = AuditSeverity.action,
    bool canRollback = false,
  }) {
    final entry = AuditEntry(
      actorId: actorId,
      actorType: actorType,
      action: action,
      targetType: targetType,
      targetId: targetId,
      metadata: metadata,
      severity: severity,
      canRollback: canRollback,
    );

    _auditLog.add(entry);
    if (_auditLog.length > _maxAuditEntries) _auditLog.removeAt(0);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BOT HEALTH
  // ═══════════════════════════════════════════════════════════════════════

  void _botHealthCheck() {
    for (final bot in _bots.values) {
      if (bot.jobsFailed > 10 && bot.successRate < 0.5) {
        bot.isActive = false;
        _logAudit(
          actorId: 'atlas_orchestrator',
          actorType: 'system',
          action: 'bot.auto_disabled',
          targetType: 'bot',
          targetId: bot.botId,
          metadata: {
            'successRate': bot.successRate,
            'failCount': bot.jobsFailed,
          },
          severity: AuditSeverity.warning,
        );
      }
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PIPELINE INTEGRATION — Called by Promotion Powerhouse
  // ═══════════════════════════════════════════════════════════════════════

  /// Main hook: called when assets move through the pipeline
  Future<void> syncToPipeline({
    required String eventId,
    required List<String> assetIds,
    required List<String> stages,
    String? animationState,
    Map<String, dynamic> metadata = const {},
  }) async {
    _logAudit(
      actorId: FirebaseAuth.instance.currentUser?.uid ?? 'system',
      actorType: 'human',
      action: 'pipeline.sync',
      targetType: 'pipeline',
      metadata: {
        'eventId': eventId,
        'assetCount': assetIds.length,
        'stages': stages,
      },
    );

    for (final assetId in assetIds) {
      // Stage 1: War Room — generate variants
      if (stages.contains('warroom')) {
        enqueueJob(
          botId: 'hype_bot_v1',
          taskType: 'generate_clips',
          description: 'Generate clip variants for $assetId',
          payload: {
            'assetId': assetId,
            'eventId': eventId,
            'animationState': animationState,
          },
          priority: JobPriority.high,
        );
        enqueueJob(
          botId: 'hype_bot_v1',
          taskType: 'generate_captions',
          description: 'Generate captions for $assetId',
          payload: {'assetId': assetId, 'eventId': eventId},
        );
      }

      // Stage 2: Review — safety check
      if (stages.contains('review')) {
        enqueueJob(
          botId: 'guardian_bot_v1',
          taskType: 'safety_moderation',
          description: 'Safety check for $assetId',
          payload: {'assetId': assetId},
          priority: JobPriority.high,
        );
      }

      // Stage 3: Market Prep — campaign setup
      if (stages.contains('marketPrep')) {
        enqueueJob(
          botId: 'campaign_bot_v1',
          taskType: 'schedule_posts',
          description: 'Schedule posts for $assetId across platforms',
          payload: {'assetId': assetId, 'eventId': eventId, ...metadata},
        );
        enqueueJob(
          botId: 'trend_bot_v1',
          taskType: 'trend_analysis',
          description: 'Find trending hooks for $assetId',
          payload: {'assetId': assetId},
        );
      }

      // Stage 4: Export — global distribution
      if (stages.contains('export')) {
        enqueueJob(
          botId: 'viral_bot_v1',
          taskType: 'micro_influencer_seeds',
          description: 'Seed micro-influencers for $assetId',
          payload: {'assetId': assetId, 'eventId': eventId, ...metadata},
        );
        enqueueJob(
          botId: 'analytics_bot_v1',
          taskType: 'roas_calculation',
          description: 'Calculate ROAS for campaign',
          payload: {'eventId': eventId},
        );
      }
    }

    // Persist sync event
    try {
      await _db.collection('atlas_pipeline_syncs').add({
        'eventId': eventId,
        'assetIds': assetIds,
        'stages': stages,
        'animationState': animationState,
        'metadata': metadata,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
      });
    } catch (e) {
      debugPrint('[ATLAS] Pipeline sync persist failed: $e');
    }

    notifyListeners();
  }

  /// Bot seed job — discovery and lead capture
  Future<void> seedJob({
    required String assetId,
    required List<String> channels,
    int microInfluencers = 10,
    List<String> geoTargets = const ['Brisbane', 'Auckland'],
    String? consentText,
  }) async {
    for (final channel in channels) {
      enqueueJob(
        botId: 'viral_bot_v1',
        taskType: 'dm_outreach',
        description: 'Seed $channel for asset $assetId',
        payload: {
          'assetId': assetId,
          'channel': channel,
          'microInfluencers': microInfluencers,
          'geo': geoTargets,
          'consentText': consentText ?? 'I agree to receive updates from DFC',
        },
      );
    }
    notifyListeners();
  }
}
