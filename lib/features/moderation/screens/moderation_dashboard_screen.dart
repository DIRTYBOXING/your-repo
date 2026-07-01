import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/models/media_asset_model.dart';
import '../../../shared/models/moderation_model.dart';
import '../../../shared/services/moderation_engine.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC Moderation Dashboard — Admin view for the human review layer
/// ═══════════════════════════════════════════════════════════════════════════
class ModerationDashboardScreen extends StatefulWidget {
  const ModerationDashboardScreen({super.key});

  @override
  State<ModerationDashboardScreen> createState() =>
      _ModerationDashboardScreenState();
}

class _ModerationDashboardScreenState extends State<ModerationDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ModerationEngine _engine = ModerationEngine();

  // Demo stats
  Map<String, int> _stats = {'pending': 0, 'approved': 0, 'rejected': 0};
  bool _useDemoData = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _engine.getQueueStats();
      final mediaStats = await _engine.getMediaQueueStats();
      if (mounted) setState(() => _stats = {...stats, ...mediaStats});
      _useDemoData = false;
    } catch (_) {
      // Offline — use demo data counts
      if (mounted) {
        setState(() {
          _stats = {'pending': 5, 'approved': 23, 'rejected': 8};
          _useDemoData = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Neon Theme Tokens ──────────────────────────────────────────────────
  static const _bgPrimary = Color(0xFF050A14);
  static const _bgCard = Color(0xFF0D1B2A);
  static const _neonCyan = Color(0xFF00F5FF);
  static const _neonMagenta = Color(0xFFFF00FF);
  static const _neonGreen = Color(0xFF00FF88);
  static const _neonAmber = Color(0xFFFFB800);
  static const _neonRed = Color(0xFFFF3366);
  static const _textPrimary = Colors.white;
  static const _textSecondary = Color(0xFF8899AA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPrimary,
      appBar: AppBar(
        backgroundColor: _bgPrimary,
        title: const Text(
          'MODERATION HQ',
          style: TextStyle(
            color: _neonCyan,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _neonCyan,
          labelColor: _neonCyan,
          unselectedLabelColor: _textSecondary,
          tabs: [
            Tab(
              icon: Badge(
                label: Text('${_stats['pending'] ?? 0}'),
                backgroundColor: _neonRed,
                child: const Icon(Icons.pending_actions),
              ),
              text: 'QUEUE',
            ),
            const Tab(icon: Icon(Icons.check_circle), text: 'RESOLVED'),
            Tab(
              icon: Badge(
                label: Text('${_stats['mediaPending'] ?? 0}'),
                backgroundColor: _neonAmber,
                child: const Icon(Icons.perm_media),
              ),
              text: 'MEDIA',
            ),
            const Tab(icon: Icon(Icons.bar_chart), text: 'STATS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQueueTab(),
          _buildResolvedTab(),
          _buildMediaQueueTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  // ── TAB 1: Pending Queue ───────────────────────────────────────────────

  Widget _buildQueueTab() {
    if (_useDemoData) {
      return _buildItemList(
        ModerationEngine.demoQueue
            .where((m) => m.status == ModerationStatus.pending)
            .toList(),
      );
    }
    return StreamBuilder<List<ModerationModel>>(
      stream: _engine.streamQueue(status: ModerationStatus.pending),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _neonCyan),
          );
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user, color: _neonGreen, size: 64),
                SizedBox(height: 16),
                Text(
                  'Queue is clear',
                  style: TextStyle(
                    color: _neonGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'No items pending review',
                  style: TextStyle(color: _textSecondary),
                ),
              ],
            ),
          );
        }
        return _buildItemList(items);
      },
    );
  }

  Widget _buildItemList(List<ModerationModel> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildModerationCard(items[index]),
    );
  }

  Widget _buildModerationCard(ModerationModel item) {
    final typeIcon = switch (item.type) {
      ModerationType.post => Icons.article,
      ModerationType.comment => Icons.comment,
      ModerationType.question => Icons.help_outline,
    };
    final typeColor = switch (item.type) {
      ModerationType.post => _neonCyan,
      ModerationType.comment => _neonAmber,
      ModerationType.question => _neonMagenta,
    };
    final statusColor = switch (item.status) {
      ModerationStatus.pending => _neonAmber,
      ModerationStatus.approved => _neonGreen,
      ModerationStatus.rejected => _neonRed,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Icon(typeIcon, color: typeColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  item.type.name.toUpperCase(),
                  style: TextStyle(
                    color: typeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.status.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Text(
              item.content,
              style: const TextStyle(color: _textPrimary, fontSize: 14),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Metadata
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  color: _textSecondary,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  item.userId,
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
                if (item.targetId != null) ...[
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.arrow_forward,
                    color: _textSecondary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.targetId!,
                    style: const TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                ],
                const Spacer(),
                Text(
                  _timeAgo(item.createdAt),
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          // Actions (only for pending)
          if (item.status == ModerationStatus.pending)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _approveItem(item),
                      icon: const Icon(Icons.check, color: _neonGreen),
                      label: const Text(
                        'APPROVE',
                        style: TextStyle(
                          color: _neonGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _rejectItem(item),
                      icon: const Icon(Icons.close, color: _neonRed),
                      label: const Text(
                        'REJECT',
                        style: TextStyle(
                          color: _neonRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _showDetails(item),
                      icon: const Icon(Icons.info_outline, color: _neonCyan),
                      label: const Text(
                        'DETAILS',
                        style: TextStyle(
                          color: _neonCyan,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── TAB 2: Resolved ────────────────────────────────────────────────────

  Widget _buildResolvedTab() {
    if (_useDemoData) {
      final resolved = [
        ModerationModel(
          id: 'res_1',
          type: ModerationType.comment,
          content: 'Spam post about crypto scams removed',
          userId: 'spammer_01',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          status: ModerationStatus.rejected,
          moderatedBy: 'admin',
          moderatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        ModerationModel(
          id: 'res_2',
          type: ModerationType.post,
          content: 'Great fight analysis — approved after link review',
          userId: 'analyst_12',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          status: ModerationStatus.approved,
          moderatedBy: 'admin',
          moderatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
      return _buildItemList(resolved);
    }

    return StreamBuilder<List<ModerationModel>>(
      stream: _engine.streamQueue(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _neonCyan),
          );
        }
        final items = (snap.data ?? [])
            .where((m) => m.status != ModerationStatus.pending)
            .toList();
        if (items.isEmpty) {
          return const Center(
            child: Text(
              'No resolved items yet',
              style: TextStyle(color: _textSecondary),
            ),
          );
        }
        return _buildItemList(items);
      },
    );
  }

  Widget _buildMediaQueueTab() {
    return StreamBuilder<List<MediaAssetModel>>(
      stream: _engine.streamMediaQueue(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _neonCyan),
          );
        }

        final assets = snap.data ?? const <MediaAssetModel>[];
        if (assets.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.perm_media, color: _neonGreen, size: 64),
                SizedBox(height: 16),
                Text(
                  'Media queue is clear',
                  style: TextStyle(
                    color: _neonGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'No media assets pending review',
                  style: TextStyle(color: _textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assets.length,
          itemBuilder: (context, index) => _buildMediaAssetCard(assets[index]),
        );
      },
    );
  }

  Widget _buildMediaAssetCard(MediaAssetModel asset) {
    final moderatorId =
        FirebaseAuth.instance.currentUser?.uid ?? 'moderation_dashboard';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _neonAmber.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.perm_media, color: _neonAmber, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${asset.kind.name.toUpperCase()} • ${asset.mediaType.name.toUpperCase()}',
                  style: const TextStyle(
                    color: _neonAmber,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  _timeAgo(asset.createdAt),
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              asset.fileName,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Owner: ${asset.rightsOwner} • Rights: ${asset.rightsType.name} • Entity: ${asset.entityType}/${asset.entityId}',
              style: const TextStyle(color: _textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              asset.rightsDeclaration,
              style: const TextStyle(color: _textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _engine.approveMediaAsset(asset.id, moderatorId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _neonGreen,
                    ),
                    child: const Text('APPROVE'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _engine.quarantineMediaAsset(
                      asset.id,
                      moderatorId,
                      'Needs manual legal review',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _neonAmber,
                    ),
                    child: const Text('QUARANTINE'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _engine.rejectMediaAsset(
                      asset.id,
                      moderatorId,
                      'Rights or safety review failed',
                    ),
                    style: OutlinedButton.styleFrom(foregroundColor: _neonRed),
                    child: const Text('REJECT'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── TAB 3: Stats ───────────────────────────────────────────────────────

  Widget _buildStatsTab() {
    final total =
        (_stats['pending'] ?? 0) +
        (_stats['approved'] ?? 0) +
        (_stats['rejected'] ?? 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Overview cards
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'PENDING',
                  '${_stats['pending'] ?? 0}',
                  _neonAmber,
                  Icons.pending_actions,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard(
                  'APPROVED',
                  '${_stats['approved'] ?? 0}',
                  _neonGreen,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard(
                  'REJECTED',
                  '${_stats['rejected'] ?? 0}',
                  _neonRed,
                  Icons.cancel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _statCard('TOTAL REVIEWED', '$total', _neonCyan, Icons.assessment),
          const SizedBox(height: 24),

          // Pipeline visualization
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _neonCyan.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MODERATION PIPELINE',
                  style: TextStyle(
                    color: _neonCyan,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                _pipelineStep(
                  1,
                  'RULES ENGINE',
                  'Banned words, spam detection, URL filter',
                  _neonGreen,
                  Icons.rule,
                ),
                _pipelineConnector(),
                _pipelineStep(
                  2,
                  'AI SCORING',
                  'Toxicity, defamation, match fixing, scam detection',
                  _neonMagenta,
                  Icons.psychology,
                ),
                _pipelineConnector(),
                _pipelineStep(
                  3,
                  'HUMAN REVIEW',
                  'Admin queue for flagged content',
                  _neonAmber,
                  Icons.person_search,
                ),
                _pipelineConnector(),
                _pipelineStep(
                  4,
                  'ENFORCEMENT',
                  'Approve / Shadow mute / Warn / Ban',
                  _neonRed,
                  Icons.gavel,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Enforcement tiers
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _neonAmber.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ENFORCEMENT TIERS',
                  style: TextStyle(
                    color: _neonAmber,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                _enforcementTier(
                  1,
                  'WARNING',
                  'First violation — formal warning issued',
                  _neonGreen,
                ),
                _enforcementTier(
                  2,
                  'SHADOW MUTE',
                  '24h content hidden from others',
                  _neonAmber,
                ),
                _enforcementTier(
                  3,
                  'SUSPENSION',
                  '7-day account suspension',
                  _neonMagenta,
                ),
                _enforcementTier(
                  4,
                  'PERMANENT BAN',
                  'Account permanently banned',
                  _neonRed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pipelineStep(
    int step,
    String title,
    String description,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Center(child: Icon(icon, color: color, size: 20)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LAYER $step: $title',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(color: _textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pipelineConnector() {
    return Padding(
      padding: const EdgeInsets.only(left: 19),
      child: Container(
        width: 2,
        height: 24,
        color: _textSecondary.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _enforcementTier(int tier, String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(
                '$tier',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────

  Future<void> _approveItem(ModerationModel item) async {
    if (_useDemoData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Approved (demo mode)'),
          backgroundColor: Color(0xFF00FF88),
        ),
      );
      return;
    }
    await _engine.approve(item.id, 'admin');
    _loadStats();
  }

  Future<void> _rejectItem(ModerationModel item) async {
    if (_useDemoData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rejected (demo mode)'),
          backgroundColor: Color(0xFFFF3366),
        ),
      );
      return;
    }
    await _engine.reject(item.id, 'admin', 'Rejected by moderator');
    _loadStats();
  }

  void _showDetails(ModerationModel item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CONTENT DETAIL',
              style: TextStyle(
                color: _neonCyan,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            _detailRow('Type', item.type.name.toUpperCase()),
            _detailRow('User', item.userId),
            if (item.targetId != null) _detailRow('Target', item.targetId!),
            _detailRow('Submitted', _timeAgo(item.createdAt)),
            _detailRow('Status', item.status.name.toUpperCase()),
            const SizedBox(height: 12),
            const Text(
              'CONTENT:',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bgPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.content,
                style: const TextStyle(color: _textPrimary, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: _textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
