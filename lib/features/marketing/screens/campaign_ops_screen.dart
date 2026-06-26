import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/marketing_campaign_model.dart';
import '../../../shared/services/campaign_service.dart';
import '../../../shared/services/promotion_run_service.dart';

/// CampaignOpsScreen — live campaign management + DLQ viewer.
/// Tab 1: Active campaigns with activate/pause toggles.
/// Tab 2: Dead-letter queue (failed promotion jobs) with requeue/dismiss.
class CampaignOpsScreen extends StatefulWidget {
  const CampaignOpsScreen({super.key});

  @override
  State<CampaignOpsScreen> createState() => _CampaignOpsScreenState();
}

class _CampaignOpsScreenState extends State<CampaignOpsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _campaignSvc = CampaignService();
  final _runSvc = PromotionRunService();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── Activate ─────────────────────────────────────────────────────────────

  Future<void> _activate(String id) async {
    try {
      await _campaignSvc.updateStatus(id, CampaignStatus.active);
      if (mounted) _toast('Campaign activated', AppTheme.neonGreen);
    } catch (e) {
      if (mounted) _toast('Error: $e', Colors.redAccent);
    }
  }

  Future<void> _pause(String id) async {
    try {
      await _campaignSvc.updateStatus(id, CampaignStatus.paused);
      if (mounted) _toast('Campaign paused', AppTheme.neonOrange);
    } catch (e) {
      if (mounted) _toast('Error: $e', Colors.redAccent);
    }
  }

  // ── DLQ ──────────────────────────────────────────────────────────────────

  Future<void> _requeue(String jobId) async {
    try {
      await _runSvc.requeueDlqJob(jobId);
      if (mounted) _toast('Job requeued', AppTheme.neonCyan);
    } catch (e) {
      if (mounted) _toast('Error: $e', Colors.redAccent);
    }
  }

  Future<void> _dismiss(String jobId) async {
    final confirm = await _confirmDialog('Dismiss this failed job?');
    if (!confirm || !mounted) return;
    try {
      await _runSvc.dismissDlqJob(jobId);
      if (mounted) _toast('Job dismissed', AppTheme.neonMagenta);
    } catch (e) {
      if (mounted) _toast('Error: $e', Colors.redAccent);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _confirmDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Text('Confirm', style: TextStyle(color: Colors.white)),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        leading: const BackButton(color: AppTheme.neonCyan),
        title: const Text(
          'CAMPAIGN OPS',
          style: TextStyle(
            color: AppTheme.neonCyan,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.neonCyan,
          labelColor: AppTheme.neonCyan,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'CAMPAIGNS'),
            Tab(text: 'DEAD-LETTER QUEUE'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_buildCampaignsTab(), _buildDlqTab()],
      ),
    );
  }

  // ── Campaigns Tab ─────────────────────────────────────────────────────────

  Widget _buildCampaignsTab() {
    return StreamBuilder<List<MarketingCampaignModel>>(
      stream: _campaignSvc.streamCampaigns(limit: 100),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.neonCyan),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Error: ${snap.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }
        final campaigns = snap.data ?? [];
        if (campaigns.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.campaign_outlined, color: Colors.white24, size: 64),
                SizedBox(height: 12),
                Text(
                  'No campaigns found',
                  style: TextStyle(color: Colors.white38, fontSize: 16),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: campaigns.length,
          itemBuilder: (_, i) => _campaignCard(campaigns[i]),
        );
      },
    );
  }

  Widget _campaignCard(MarketingCampaignModel c) {
    final isActive = c.status == CampaignStatus.active;
    final statusColor = _statusColor(c.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF12121F),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _statusBadge(c.status),
              ],
            ),
            const SizedBox(height: 8),
            // Meta row
            Row(
              children: [
                _metaChip(c.type.name.toUpperCase(), Colors.white24),
                const SizedBox(width: 6),
                ...c.channels
                    .take(3)
                    .map(
                      (ch) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _metaChip(
                          ch.name,
                          AppTheme.neonCyan.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 10),
            // Action buttons
            Row(
              children: [
                if (!isActive)
                  Expanded(
                    child: _opsButton(
                      'Activate',
                      Icons.play_arrow,
                      AppTheme.neonGreen,
                      () => _activate(c.id),
                    ),
                  ),
                if (isActive)
                  Expanded(
                    child: _opsButton(
                      'Pause',
                      Icons.pause,
                      AppTheme.neonOrange,
                      () => _pause(c.id),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: _opsButton(
                    'View Runs',
                    Icons.analytics_outlined,
                    AppTheme.neonCyan,
                    () => _showRunsSheet(c),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _opsButton(
                    'Variants',
                    Icons.science_outlined,
                    AppTheme.neonMagenta,
                    () => _showVariantsSheet(c),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── DLQ Tab ───────────────────────────────────────────────────────────────

  Widget _buildDlqTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _runSvc.streamDlq(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.redAccent),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Error: ${snap.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }
        final jobs = snap.data ?? [];
        if (jobs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.neonGreen,
                  size: 64,
                ),
                SizedBox(height: 12),
                Text(
                  'DLQ is clear — no failed jobs',
                  style: TextStyle(color: AppTheme.neonGreen, fontSize: 16),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            _dlqHeader(jobs.length),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: jobs.length,
                itemBuilder: (_, i) => _dlqCard(jobs[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dlqHeader(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF1A0A0A),
        border: Border(bottom: BorderSide(color: Color(0xFF3A1010))),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Text(
            '$count failed job${count == 1 ? '' : 's'} in DLQ',
            style: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dlqCard(Map<String, dynamic> job) {
    final jobId = job['id'] as String? ?? '';
    final campaignId = job['campaignId'] as String? ?? 'unknown';
    final channel = job['channel'] as String? ?? 'unknown';
    final reason =
        job['errorMessage'] as String? ??
        job['reason'] as String? ??
        'Unknown error';
    final attempts = job['attempts'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF14090B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Campaign: $campaignId',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Attempts: $attempts',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Channel: $channel',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              reason,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _opsButton(
                    'Requeue',
                    Icons.replay,
                    AppTheme.neonCyan,
                    () => _requeue(jobId),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _opsButton(
                    'Dismiss',
                    Icons.delete_outline,
                    Colors.redAccent,
                    () => _dismiss(jobId),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // ── Variants Bottom Sheet ─────────────────────────────────────────

  void _showVariantsSheet(MarketingCampaignModel campaign) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12121F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        minChildSize: 0.35,
        expand: false,
        builder: (ctx, controller) => _VariantsSheet(
          campaign: campaign,
          campaignSvc: _campaignSvc,
          scrollController: controller,
        ),
      ),
    );
  }
  // ── Runs Bottom Sheet ────────────────────────────────────────────────────

  void _showRunsSheet(MarketingCampaignModel campaign) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12121F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, controller) => _RunsSheet(
          campaign: campaign,
          runSvc: _runSvc,
          scrollController: controller,
        ),
      ),
    );
  }

  // ── Small Widgets ─────────────────────────────────────────────────────────

  Widget _opsButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: Colors.black),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  Widget _statusBadge(CampaignStatus status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _metaChip(String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 10),
      ),
    );
  }

  Color _statusColor(CampaignStatus s) {
    switch (s) {
      case CampaignStatus.active:
        return AppTheme.neonGreen;
      case CampaignStatus.paused:
        return AppTheme.neonOrange;
      case CampaignStatus.scheduled:
        return AppTheme.neonCyan;
      case CampaignStatus.completed:
        return Colors.white38;
      case CampaignStatus.draft:
        return Colors.white24;
      case CampaignStatus.archived:
        return Colors.white12;
    }
  }
}

// ── Runs Sheet ───────────────────────────────────────────────────────────────

class _RunsSheet extends StatelessWidget {
  const _RunsSheet({
    required this.campaign,
    required this.runSvc,
    required this.scrollController,
  });

  final MarketingCampaignModel campaign;
  final PromotionRunService runSvc;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                'RUNS — ${campaign.title}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white12),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: runSvc
                .streamRunsForCampaign(campaign.id)
                .map(
                  (runs) => runs
                      .map(
                        (r) => {
                          'id': r.id,
                          'status': r.status.name,
                          'channel': r.channel,
                          'market': r.market,
                          'attempts': r.attempts,
                          'startedAt': r.startedAt,
                          'isError': r.isError,
                        },
                      )
                      .toList(),
                ),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final runs = snap.data ?? [];
              if (runs.isEmpty) {
                return const Center(
                  child: Text(
                    'No runs found for this campaign',
                    style: TextStyle(color: Colors.white38),
                  ),
                );
              }
              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: runs.length,
                itemBuilder: (_, i) {
                  final r = runs[i];
                  final isError = r['isError'] as bool? ?? false;
                  final statusColor = isError
                      ? Colors.redAccent
                      : AppTheme.neonGreen;
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isError
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: statusColor,
                      size: 18,
                    ),
                    title: Text(
                      '${r['channel']} · ${r['market']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      'Status: ${r['status']}  Attempts: ${r['attempts']}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                    trailing: Text(
                      r['startedAt'] != null
                          ? _fmtTime(r['startedAt'] as DateTime)
                          : '—',
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.month}/${dt.day} $h:$m';
  }
}

// ── Variants Sheet ────────────────────────────────────────────────────────────

class _VariantsSheet extends StatelessWidget {
  const _VariantsSheet({
    required this.campaign,
    required this.campaignSvc,
    required this.scrollController,
  });

  final MarketingCampaignModel campaign;
  final CampaignService campaignSvc;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Icon(
                Icons.science_outlined,
                color: AppTheme.neonMagenta,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A/B VARIANTS — ${campaign.title}',
                  style: const TextStyle(
                    color: AppTheme.neonMagenta,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white12),
        Expanded(
          child: StreamBuilder<List<CampaignVariant>>(
            stream: campaignSvc.streamVariants(campaign.id),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.neonMagenta),
                );
              }
              final variants = snap.data ?? [];
              if (variants.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.science_outlined,
                        color: Colors.white24,
                        size: 48,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No variants yet',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: variants.length,
                itemBuilder: (_, i) => _variantTile(variants[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _variantTile(CampaignVariant v) {
    final ctr = v.impressions > 0
        ? (v.clicks / v.impressions * 100).toStringAsFixed(1)
        : '—';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF14091A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: v.isWinner
              ? AppTheme.neonGreen.withValues(alpha: 0.5)
              : AppTheme.neonMagenta.withValues(alpha: 0.2),
          width: v.isWinner ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.neonMagenta.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Variant ${v.label}',
                    style: const TextStyle(
                      color: AppTheme.neonMagenta,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (v.isWinner)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.neonGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'WINNER',
                      style: TextStyle(
                        color: AppTheme.neonGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  'CTR: $ctr%',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            if (v.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                v.description,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _stat('Impressions', v.impressions),
                const SizedBox(width: 16),
                _stat('Clicks', v.clicks),
                const SizedBox(width: 16),
                _stat('Conversions', v.conversions),
              ],
            ),
            if (!v.isWinner) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => campaignSvc.markWinner(campaign.id, v.id),
                  icon: const Icon(
                    Icons.emoji_events,
                    size: 14,
                    color: Colors.black,
                  ),
                  label: const Text(
                    'Mark Winner',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonGreen,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
