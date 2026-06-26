import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/ai_sentinel_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ATHLETE COMMAND CENTER — Fighter protection & reputation dashboard
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Every registered fighter gets:
///   • Real-time protection status (sentinel shield)
///   • Defamation attempts tracked + blocked
///   • Harassment detection counter
///   • Impersonation alerts
///   • Reputation score of users who interact with them
///   • Report tools for direct submission
///   • Protection settings (terms, alert preferences)
/// ═══════════════════════════════════════════════════════════════════════════

class AthleteCommandCenterScreen extends StatefulWidget {
  final String fighterId;
  final String fighterName;

  const AthleteCommandCenterScreen({
    super.key,
    required this.fighterId,
    required this.fighterName,
  });

  @override
  State<AthleteCommandCenterScreen> createState() =>
      _AthleteCommandCenterScreenState();
}

class _AthleteCommandCenterScreenState
    extends State<AthleteCommandCenterScreen> {
  final AISentinelService _sentinel = AISentinelService();
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _stats = await _sentinel.getSentinelStats();
      setState(() => _loading = false);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _activateProtection() async {
    await _sentinel.registerAthleteProtection(
      fighterId: widget.fighterId,
      fighterName: widget.fighterName,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sentinel protection ACTIVATED'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ATHLETE COMMAND CENTER',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              widget.fighterName,
              style: const TextStyle(
                fontSize: 11,
                color: DesignTokens.neonCyan,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield, color: DesignTokens.neonGreen),
            onPressed: _activateProtection,
            tooltip: 'Activate Protection',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DesignTokens.neonCyan),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildShieldStatus(),
                const SizedBox(height: 16),
                _buildProtectionStats(),
                const SizedBox(height: 16),
                _buildThreatBreakdown(),
                const SizedBox(height: 16),
                _buildRecentIncidents(),
                const SizedBox(height: 16),
                _buildQuickActions(),
              ],
            ),
    );
  }

  Widget _buildShieldStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.neonGreen.withValues(alpha: 0.1),
            DesignTokens.bgCard,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignTokens.neonGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.shield, size: 48, color: DesignTokens.neonGreen),
          const SizedBox(height: 8),
          const Text(
            'SENTINEL ACTIVE',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: DesignTokens.neonGreen,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'AI monitors all content mentioning you across DFC',
            style: TextStyle(
              fontSize: 11,
              color: DesignTokens.textMuted.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProtectionStats() {
    return Row(
      children: [
        _statTile(
          '${_stats['totalIncidents'] ?? 0}',
          'INCIDENTS',
          Icons.warning_amber,
          DesignTokens.neonAmber,
        ),
        const SizedBox(width: 8),
        _statTile(
          '${_stats['resolvedIncidents'] ?? 0}',
          'RESOLVED',
          Icons.check_circle_outline,
          DesignTokens.neonGreen,
        ),
        const SizedBox(width: 8),
        _statTile(
          '${_stats['activeIncidents'] ?? 0}',
          'ACTIVE',
          Icons.error_outline,
          DesignTokens.neonRed,
        ),
      ],
    );
  }

  Widget _statTile(String value, String label, IconData icon, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: accent.withValues(alpha: 0.7),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreatBreakdown() {
    final byType = (_stats['byType'] as Map<String, int>?) ?? {};
    if (byType.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No threats detected — all clear',
            style: TextStyle(color: DesignTokens.textMuted),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THREAT BREAKDOWN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          ...byType.entries.map((e) {
            final color = _typeColor(e.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.key.toUpperCase().replaceAll('_', ' '),
                      style: const TextStyle(
                        fontSize: 11,
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${e.value}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentIncidents() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RECENT INCIDENTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(fontSize: 11, color: DesignTokens.neonCyan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<SentinelIncident>>(
            stream: _sentinel.streamIncidents(limit: 5),
            builder: (ctx, snap) {
              if (!snap.hasData || snap.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: Text(
                      'No incidents — your reputation is clean',
                      style: TextStyle(
                        fontSize: 12,
                        color: DesignTokens.neonGreen.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: snap.data!
                    .map(_incidentRow)
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _incidentRow(SentinelIncident incident) {
    final color = _threatColor(incident.threatLevel);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(_threatIcon(incident.threatLevel), size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.type.name.toUpperCase().replaceAll('_', ' '),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  incident.contentText.length > 50
                      ? '${incident.contentText.substring(0, 50)}...'
                      : incident.contentText,
                  style: const TextStyle(
                    fontSize: 11,
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              incident.status.name.toUpperCase(),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK ACTIONS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: DesignTokens.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _actionChip('Report Content', Icons.flag, DesignTokens.neonRed, _showReportDialog),
            _actionChip(
              'Update Protected Terms',
              Icons.edit,
              DesignTokens.neonAmber,
              _showTermsDialog,
            ),
            _actionChip(
              'View Reputation',
              Icons.person_search,
              DesignTokens.neonCyan,
              _showReputationDialog,
            ),
            _actionChip(
              'Share Protection Status',
              Icons.share,
              DesignTokens.neonGreen,
              () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionChip(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog() {
    final contentCtrl = TextEditingController();
    final userIdCtrl = TextEditingController();
    final IncidentType selectedType = IncidentType.defamation;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'REPORT CONTENT',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userIdCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'User ID',
                labelStyle: TextStyle(color: DesignTokens.textMuted),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: contentCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Content or Description',
                labelStyle: TextStyle(color: DesignTokens.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              await _sentinel.reportContent(
                contentId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                contentText: contentCtrl.text,
                source: ContentSource.post,
                reportedUserId: userIdCtrl.text,
                reportedByUserId: user.uid,
                type: selectedType,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.neonRed.withValues(alpha: 0.3),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    final termCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'PROTECTED TERMS',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add nicknames, aliases, or terms to monitor',
              style: TextStyle(fontSize: 12, color: DesignTokens.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: termCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Term (comma-separated)',
                labelStyle: TextStyle(color: DesignTokens.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final terms = termCtrl.text
                  .split(',')
                  .map((t) => t.trim())
                  .toList();
              await _sentinel.registerAthleteProtection(
                fighterId: widget.fighterId,
                fighterName: widget.fighterName,
                additionalTerms: terms,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.neonAmber.withValues(alpha: 0.3),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showReputationDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final rep = await _sentinel.getUserReputation(user.uid);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'YOUR REPUTATION',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rep.score.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: _tierColor(rep.tier),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _tierColor(rep.tier).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                rep.tier.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _tierColor(rep.tier),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Incidents: ${rep.totalIncidents}  |  Warnings: ${rep.warningCount}',
              style: const TextStyle(
                fontSize: 11,
                color: DesignTokens.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _typeColor(String type) => switch (type) {
    'hate' => DesignTokens.neonRed,
    'harassment' => Colors.red,
    'defamation' => DesignTokens.neonAmber,
    'impersonation' => DesignTokens.neonMagenta,
    'scam' => Colors.orange,
    'spam' => DesignTokens.textMuted,
    'matchFixing' => DesignTokens.neonMagenta,
    _ => DesignTokens.neonCyan,
  };

  Color _threatColor(ThreatLevel level) => switch (level) {
    ThreatLevel.none => DesignTokens.neonGreen,
    ThreatLevel.low => DesignTokens.neonAmber,
    ThreatLevel.medium => Colors.orange,
    ThreatLevel.high => DesignTokens.neonRed,
    ThreatLevel.critical => Colors.red,
  };

  IconData _threatIcon(ThreatLevel level) => switch (level) {
    ThreatLevel.none => Icons.check_circle,
    ThreatLevel.low => Icons.info_outline,
    ThreatLevel.medium => Icons.warning_amber,
    ThreatLevel.high => Icons.error,
    ThreatLevel.critical => Icons.dangerous,
  };

  Color _tierColor(ReputationTier tier) => switch (tier) {
    ReputationTier.trusted => DesignTokens.neonGreen,
    ReputationTier.neutral => DesignTokens.neonCyan,
    ReputationTier.watchlist => DesignTokens.neonAmber,
    ReputationTier.restricted => DesignTokens.neonRed,
    ReputationTier.banned => Colors.red,
  };
}
