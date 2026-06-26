import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/dfc_network_image.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PIPELINE LIVE VISUALIZER — Watch Content Flow Through Stages in Real-Time
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Visual representation of the DFC content pipeline:
/// INTAKE → TRANSFORM → QUEUE → DISTRIBUTE → TRACK → COMPLETE
///
/// Each stage shows:
/// - Live count of items in that stage
/// - Animated flow arrows between stages
/// - Active jobs passing through with progress indicators
/// - Color-coded stages with glow effects
///
/// This is NOT a toy. This is production pipeline visualization.
/// ═══════════════════════════════════════════════════════════════════════════

class PipelineJobInfo {
  final String id;
  final String title;
  final String stage;
  final String? imageUrl;
  final String sport;
  final String region;
  final double progress;
  final DateTime startedAt;

  const PipelineJobInfo({
    required this.id,
    required this.title,
    required this.stage,
    this.imageUrl,
    required this.sport,
    required this.region,
    required this.progress,
    required this.startedAt,
  });
}

class PipelineLiveVisualizer extends StatefulWidget {
  final Map<String, int> stageCounts;
  final List<PipelineJobInfo> activeJobs;
  final VoidCallback? onRefresh;

  const PipelineLiveVisualizer({
    super.key,
    required this.stageCounts,
    required this.activeJobs,
    this.onRefresh,
  });

  @override
  State<PipelineLiveVisualizer> createState() => _PipelineLiveVisualizerState();
}

class _PipelineLiveVisualizerState extends State<PipelineLiveVisualizer>
    with TickerProviderStateMixin {
  late final AnimationController _flowController;
  late final AnimationController _glowController;
  late final Animation<double> _flowAnim;
  late final Animation<double> _glowAnim;

  static const _stages = [
    _StageInfo('INTAKE', Icons.download, '0xFF00F5FF'),
    _StageInfo('TRANSFORM', Icons.auto_fix_high, '0xFFFF00FF'),
    _StageInfo('QUEUE', Icons.queue, '0xFFFFAA00'),
    _StageInfo('DISTRIBUTE', Icons.send, '0xFF9D00FF'),
    _StageInfo('TRACK', Icons.analytics, '0xFF00C8FF'),
    _StageInfo('COMPLETE', Icons.check_circle, '0xFF00FF88'),
  ];

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _flowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_flowController);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flowController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildPipelineFlow(),
          const SizedBox(height: 24),
          _buildStageStats(),
          const SizedBox(height: 24),
          _buildActiveJobsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final total = widget.stageCounts.values.fold(0, (a, b) => a + b);
    return Row(
      children: [
        AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, _) => Icon(
            Icons.conveyor_belt,
            color: AppTheme.neonCyan.withValues(alpha: _glowAnim.value),
            size: 28,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'LIVE PIPELINE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.neonCyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
          ),
          child: Text(
            '$total TOTAL ITEMS',
            style: const TextStyle(
              color: AppTheme.neonCyan,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        if (widget.onRefresh != null) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.neonCyan, size: 20),
            onPressed: widget.onRefresh,
          ),
        ],
      ],
    );
  }

  // ─── Pipeline Flow Visualization ────────────────────────────────────────
  Widget _buildPipelineFlow() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          // Stage nodes with flow arrows
          SizedBox(
            height: 160,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stageWidth =
                    (constraints.maxWidth - (_stages.length - 1) * 20) /
                    _stages.length;
                return Row(
                  children: List.generate(_stages.length * 2 - 1, (index) {
                    if (index.isEven) {
                      final stageIdx = index ~/ 2;
                      return SizedBox(
                        width: stageWidth,
                        child: _buildStageNode(
                          _stages[stageIdx],
                          widget.stageCounts[_stages[stageIdx].name
                                  .toLowerCase()] ??
                              0,
                          stageIdx,
                        ),
                      );
                    } else {
                      return SizedBox(width: 20, child: _buildFlowArrow());
                    }
                  }),
                );
              },
            ),
          ),
          // Animated flow line
          const SizedBox(height: 12),
          _buildAnimatedFlowLine(),
        ],
      ),
    );
  }

  Widget _buildStageNode(_StageInfo stage, int count, int index) {
    final color = Color(int.parse(stage.colorHex));
    final hasItems = count > 0;
    final jobsInStage = widget.activeJobs
        .where((j) => j.stage.toLowerCase() == stage.name.toLowerCase())
        .length;

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, _) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Stage icon with glow
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasItems
                  ? color.withValues(alpha: 0.15)
                  : const Color(0xFF101828),
              border: Border.all(
                color: hasItems
                    ? color.withValues(alpha: _glowAnim.value)
                    : color.withValues(alpha: 0.25),
                width: hasItems ? 2.5 : 1.5,
              ),
              boxShadow: hasItems
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3 * _glowAnim.value),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              stage.icon,
              color: hasItems ? color : color.withValues(alpha: 0.4),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          // Stage name
          Text(
            stage.name,
            style: TextStyle(
              color: hasItems ? color : Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          // Count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: hasItems
                  ? color.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasItems
                    ? color.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: hasItems ? color : Colors.white30,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (jobsInStage > 0) ...[
            const SizedBox(height: 4),
            Text(
              '$jobsInStage active',
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFlowArrow() {
    return AnimatedBuilder(
      animation: _flowAnim,
      builder: (_, _) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_forward_ios,
            color: AppTheme.neonCyan.withValues(
              alpha: 0.3 + 0.4 * _flowAnim.value,
            ),
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedFlowLine() {
    return AnimatedBuilder(
      animation: _flowAnim,
      builder: (_, _) => Container(
        height: 3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: LinearGradient(
            colors: [
              AppTheme.neonCyan.withValues(alpha: 0.0),
              AppTheme.neonCyan.withValues(alpha: 0.6 * _flowAnim.value),
              AppTheme.neonMagenta.withValues(alpha: 0.6 * _flowAnim.value),
              AppTheme.neonGreen.withValues(alpha: 0.0),
            ],
            stops: [
              0.0,
              _flowAnim.value.clamp(0.0, 0.5),
              _flowAnim.value.clamp(0.5, 1.0),
              1.0,
            ],
          ),
        ),
      ),
    );
  }

  // ─── Stage Stats Grid ──────────────────────────────────────────────────
  Widget _buildStageStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STAGE BREAKDOWN',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _stages.map((stage) {
            final count = widget.stageCounts[stage.name.toLowerCase()] ?? 0;
            final color = Color(int.parse(stage.colorHex));
            final total = widget.stageCounts.values.fold(0, (a, b) => a + b);
            final pct = total > 0 ? (count / total * 100) : 0.0;

            return Container(
              width: 160,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(stage.icon, color: color, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        stage.name,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: const Color(0xFF1A2744),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pct.toStringAsFixed(1)}% of pipeline',
                    style: TextStyle(
                      color: color.withValues(alpha: 0.5),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        // Failed count
        if ((widget.stageCounts['failed'] ?? 0) > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.stageCounts['failed']} FAILED',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'RETRY ALL',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─── Active Jobs Feed ──────────────────────────────────────────────────
  Widget _buildActiveJobsList() {
    if (widget.activeJobs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.conveyor_belt,
                color: Colors.white.withValues(alpha: 0.1),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Pipeline is empty — drop posters to start',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'ACTIVE JOBS',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            Text(
              '${widget.activeJobs.length} running',
              style: const TextStyle(
                color: AppTheme.neonGreen,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...widget.activeJobs.map(_buildJobTracker),
      ],
    );
  }

  Widget _buildJobTracker(PipelineJobInfo job) {
    final stageIdx = _stages.indexWhere(
      (s) => s.name.toLowerCase() == job.stage.toLowerCase(),
    );
    final stageColor = stageIdx >= 0
        ? Color(int.parse(_stages[stageIdx].colorHex))
        : AppTheme.neonCyan;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stageColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Poster thumbnail
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2744),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: stageColor.withValues(alpha: 0.3)),
                ),
                child: job.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: DfcNetworkImage(
                          url: job.imageUrl!,
                        ),
                      )
                    : Icon(Icons.image, color: stageColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${job.sport} • ${job.region}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Stage badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: stageColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: stageColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  job.stage.toUpperCase(),
                  style: TextStyle(
                    color: stageColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Stage progress dots
          Row(
            children: List.generate(_stages.length, (i) {
              final isCompleted = i < stageIdx;
              final isCurrent = i == stageIdx;
              final stageClr = Color(int.parse(_stages[i].colorHex));
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isCompleted
                        ? stageClr
                        : isCurrent
                        ? stageClr.withValues(alpha: 0.5)
                        : const Color(0xFF1A2744),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${(job.progress * 100).toInt()}% complete',
                style: TextStyle(
                  color: stageColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _timeSince(job.startedAt),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeSince(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ─── Stage Info ──────────────────────────────────────────────────────────
class _StageInfo {
  final String name;
  final IconData icon;
  final String colorHex;
  const _StageInfo(this.name, this.icon, this.colorHex);
}
