import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/agent_role_registry.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/feed_pipeline_audit_service.dart';
import '../../../shared/services/source_trust_rules_service.dart';

class FeedPipelineMonitorScreen extends StatefulWidget {
  const FeedPipelineMonitorScreen({super.key});

  @override
  State<FeedPipelineMonitorScreen> createState() =>
      _FeedPipelineMonitorScreenState();
}

class _FeedPipelineMonitorScreenState extends State<FeedPipelineMonitorScreen> {
  final FeedPipelineAuditService _auditService = FeedPipelineAuditService();
  final SourceTrustRulesService _trustRules = SourceTrustRulesService();

  @override
  void initState() {
    super.initState();
    _trustRules.ensureProfilesSeeded();
  }

  Future<void> _refresh() async {
    await _trustRules.getProfiles(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (!auth.isAdmin) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBackground,
        appBar: AppBar(
          title: const Text('FEED PIPELINE MONITOR'),
          backgroundColor: AppTheme.cardBackground,
          foregroundColor: AppTheme.neonCyan,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Admin access is required to review feed pipeline audit runs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('FEED PIPELINE MONITOR'),
        backgroundColor: AppTheme.cardBackground,
        foregroundColor: AppTheme.neonCyan,
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh monitor',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildIntroCard(),
            const SizedBox(height: 16),
            _buildRunsSection(),
            const SizedBox(height: 16),
            _buildTrustProfilesSection(),
            const SizedBox(height: 16),
            _buildRecentEventsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PIPELINE OVERSIGHT',
            style: TextStyle(
              color: AppTheme.neonCyan,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monitor stage outcomes from feed_pipeline_audit and tune weighted source trust profiles from Firestore. Defaults are auto-seeded when the profile collection is empty.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunsSection() {
    return StreamBuilder<List<FeedPipelineEvent>>(
      stream: _auditService.streamPersistedEvents(limit: 180),
      builder: (context, snapshot) {
        final events = snapshot.data ?? const <FeedPipelineEvent>[];
        final runs = _summarizeRuns(events);

        return _buildSectionCard(
          title: 'Recent Runs',
          icon: Icons.account_tree,
          child: runs.isEmpty
              ? _buildEmptyState('No persisted pipeline runs yet.')
              : Column(
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: runs.take(8).map(_buildRunSummaryCard).toList(),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${events.length} recent audit events loaded',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.52),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildTrustProfilesSection() {
    return StreamBuilder<List<SourceTrustProfile>>(
      stream: _trustRules.streamProfiles(),
      builder: (context, snapshot) {
        final profiles = snapshot.data ?? const <SourceTrustProfile>[];

        return _buildSectionCard(
          title: 'Source Trust Profiles',
          icon: Icons.verified_user,
          child: profiles.isEmpty
              ? _buildEmptyState('No trust profiles available.')
              : Column(
                  children: profiles
                      .map(
                        (profile) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildTrustProfileCard(profile),
                        ),
                      )
                      .toList(),
                ),
        );
      },
    );
  }

  Widget _buildRecentEventsSection() {
    return StreamBuilder<List<FeedPipelineEvent>>(
      stream: _auditService.streamPersistedEvents(limit: 60),
      builder: (context, snapshot) {
        final events = snapshot.data ?? const <FeedPipelineEvent>[];

        return _buildSectionCard(
          title: 'Recent Events',
          icon: Icons.receipt_long,
          child: events.isEmpty
              ? _buildEmptyState('No recent audit events found.')
              : Column(children: events.take(20).map(_buildEventTile).toList()),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.neonOrange, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildRunSummaryCard(_PipelineRunSummary run) {
    final accent = run.failedCount > 0
        ? AppTheme.errorColor
        : AppTheme.neonGreen;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                run.failedCount > 0 ? Icons.error_outline : Icons.check_circle,
                color: accent,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  run.runId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Latest: ${run.latestStage.name}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _metricChip('${run.events.length} events', AppTheme.neonCyan),
              _metricChip('${run.failedCount} failed', accent),
              _metricChip(
                _formatTimestamp(run.latestTimestamp),
                AppTheme.neonPurple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustProfileCard(SourceTrustProfile profile) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.key,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showEditProfileDialog(profile),
                icon: const Icon(Icons.tune, color: AppTheme.neonCyan),
                tooltip: 'Edit trust profile',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _metricChip(
                'trust ${profile.trustScore.toStringAsFixed(2)}',
                AppTheme.neonGreen,
              ),
              _metricChip(
                'weight ${profile.rankingWeight.toStringAsFixed(2)}',
                AppTheme.neonOrange,
              ),
              if (profile.highPriority)
                _metricChip('high priority', AppTheme.neonMagenta),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            profile.domains.join(', '),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTile(FeedPipelineEvent event) {
    final accent = event.success ? AppTheme.neonGreen : AppTheme.errorColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            event.success ? Icons.check_circle_outline : Icons.error_outline,
            color: accent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      event.stage.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      event.role.name,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.42),
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTimestamp(event.timestamp),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.42),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.52),
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _showEditProfileDialog(SourceTrustProfile profile) async {
    final labelController = TextEditingController(text: profile.label);
    final domainsController = TextEditingController(
      text: profile.domains.join(', '),
    );
    final trustController = TextEditingController(
      text: profile.trustScore.toStringAsFixed(2),
    );
    final weightController = TextEditingController(
      text: profile.rankingWeight.toStringAsFixed(2),
    );
    var highPriority = profile.highPriority;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBackground,
              title: const Text(
                'Edit Trust Profile',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogField(labelController, 'Label'),
                    const SizedBox(height: 10),
                    _buildDialogField(
                      domainsController,
                      'Domains, comma separated',
                    ),
                    const SizedBox(height: 10),
                    _buildDialogField(
                      trustController,
                      'Trust score (0.00 - 1.00)',
                    ),
                    const SizedBox(height: 10),
                    _buildDialogField(weightController, 'Ranking weight'),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      value: highPriority,
                      onChanged: (value) =>
                          setState(() => highPriority = value),
                      activeThumbColor: AppTheme.neonCyan,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'High priority source',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final trustScore = double.tryParse(
                      trustController.text.trim(),
                    );
                    final rankingWeight = double.tryParse(
                      weightController.text.trim(),
                    );
                    if (trustScore == null || rankingWeight == null) {
                      return;
                    }

                    final updated = profile.copyWith(
                      label: labelController.text.trim().isEmpty
                          ? profile.label
                          : labelController.text.trim(),
                      domains: domainsController.text
                          .split(',')
                          .map((domain) => domain.trim().toLowerCase())
                          .where((domain) => domain.isNotEmpty)
                          .toList(),
                      trustScore: trustScore.clamp(0.0, 1.0).toDouble(),
                      rankingWeight: rankingWeight < 0 ? 0.0 : rankingWeight,
                      highPriority: highPriority,
                    );

                    await _trustRules.upsertProfile(updated);
                    if (!mounted) {
                      return;
                    }

                    Navigator.of(this.context).pop();
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('${updated.label} updated'),
                        backgroundColor: Colors.green[800],
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppTheme.neonCyan),
        ),
      ),
    );
  }

  List<_PipelineRunSummary> _summarizeRuns(List<FeedPipelineEvent> events) {
    final grouped = <String, List<FeedPipelineEvent>>{};
    for (final event in events) {
      grouped.putIfAbsent(event.runId, () => <FeedPipelineEvent>[]).add(event);
    }

    final runs =
        grouped.entries.map((entry) {
          final runEvents = [...entry.value]
            ..sort((left, right) => right.timestamp.compareTo(left.timestamp));
          final latest = runEvents.first;
          final failedCount = runEvents.where((event) => !event.success).length;

          return _PipelineRunSummary(
            runId: entry.key,
            latestStage: latest.stage,
            latestTimestamp: latest.timestamp,
            failedCount: failedCount,
            events: runEvents,
          );
        }).toList()..sort(
          (left, right) =>
              right.latestTimestamp.compareTo(left.latestTimestamp),
        );

    return runs;
  }

  String _formatTimestamp(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

class _PipelineRunSummary {
  final String runId;
  final FeedPipelineStage latestStage;
  final DateTime latestTimestamp;
  final int failedCount;
  final List<FeedPipelineEvent> events;

  const _PipelineRunSummary({
    required this.runId,
    required this.latestStage,
    required this.latestTimestamp,
    required this.failedCount,
    required this.events,
  });
}
