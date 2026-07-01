import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/video_highlights_service.dart';
import '../../../shared/widgets/ai_highlights_graph.dart';

/// Full-screen AI Video Highlights view.
///
/// Shows: video placeholder + interactive interest graph + key moments
/// + overall excitement score + suggested auto-clip region.
///
/// Supports both Firestore-backed analysis and demo mode.
class VideoHighlightsScreen extends StatefulWidget {
  final String? highlightId;
  final String? videoUrl;
  final String? videoTitle;
  final bool demoMode;

  const VideoHighlightsScreen({
    super.key,
    this.highlightId,
    this.videoUrl,
    this.videoTitle,
    this.demoMode = false,
  });

  @override
  State<VideoHighlightsScreen> createState() => _VideoHighlightsScreenState();
}

class _VideoHighlightsScreenState extends State<VideoHighlightsScreen> {
  final _service = VideoHighlightsService();
  VideoHighlights? _highlights;
  bool _loading = true;
  String? _error;
  double _playbackPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _loadHighlights();
  }

  Future<void> _loadHighlights() async {
    if (widget.demoMode) {
      setState(() {
        _highlights = VideoHighlightsService.generateDemoHighlights(
          videoTitle:
              widget.videoTitle ?? 'UFC 300 Main Event — Championship Round',
        );
        _loading = false;
      });
      return;
    }

    try {
      VideoHighlights? h;
      if (widget.highlightId != null) {
        h = await _service.getHighlights(widget.highlightId!);
      } else if (widget.videoUrl != null) {
        h = await _service.getHighlightsForVideo(widget.videoUrl!);
      }

      if (h == null && widget.videoUrl != null) {
        // Auto-trigger analysis for new videos
        final id = await _service.analyzeVideo(
          videoUrl: widget.videoUrl!,
          videoTitle: widget.videoTitle ?? 'Video Analysis',
        );
        // Listen for completion
        _service.streamHighlights(id).listen((result) {
          if (mounted && result != null) {
            setState(() {
              _highlights = result;
              _loading = !result.isCompleted;
            });
          }
        });
        return;
      }

      setState(() {
        _highlights = h;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: Text(
          widget.videoTitle ?? 'AI Video Highlights',
          style: const TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: DesignTokens.fontSizeTitle,
            fontWeight: DesignTokens.fontWeightTitle,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_highlights?.isCompleted == true)
            IconButton(
              icon: const Icon(
                Icons.auto_awesome,
                color: DesignTokens.neonCyan,
              ),
              tooltip: 'Re-analyze',
              onPressed: _reanalyze,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildLoadingState();
    if (_error != null) return _buildErrorState();
    if (_highlights == null) return _buildEmptyState();
    return _buildHighlightsView(_highlights!);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: DesignTokens.neonCyan,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingL),
          const Text(
            'Analyzing video highlights...',
            style: TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: DesignTokens.fontSizeBody,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            _highlights?.isPending == true
                ? 'AI is scanning for key fight moments'
                : 'Submitting to analysis queue',
            style: const TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeCaption,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: DesignTokens.neonRed,
            size: 48,
          ),
          const SizedBox(height: DesignTokens.spacingL),
          const Text(
            'Analysis failed',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              style: const TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.video_library_outlined,
            color: DesignTokens.neonCyan.withValues(alpha: 0.5),
            size: 64,
          ),
          const SizedBox(height: DesignTokens.spacingL),
          const Text(
            'No highlights available',
            style: TextStyle(color: DesignTokens.textPrimary, fontSize: 16),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          const Text(
            'Submit a fight video to generate AI highlights',
            style: TextStyle(color: DesignTokens.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsView(VideoHighlights h) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Video placeholder ──
          _buildVideoArea(h),
          const SizedBox(height: DesignTokens.spacingXS),

          // ── AI Highlights Graph ──
          _buildGraphSection(h),

          const SizedBox(height: DesignTokens.spacingXL),

          // ── Stats row ──
          _buildStatsRow(h),

          const SizedBox(height: DesignTokens.spacingXL),

          // ── Key Moments ──
          if (h.keyMoments.isNotEmpty) ...[
            const Text(
              'KEY MOMENTS',
              style: TextStyle(
                color: DesignTokens.neonCyan,
                fontSize: DesignTokens.fontSizeCaption,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingS),
            _buildKeyMoments(h),
          ],

          const SizedBox(height: DesignTokens.spacingXL),

          // ── Suggested Clip ──
          if (h.suggestedClipStart != null) _buildSuggestedClip(h),
        ],
      ),
    );
  }

  Widget _buildVideoArea(VideoHighlights h) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: DesignTokens.bgSecondary,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.borderSubtle,
          width: DesignTokens.borderThin,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Thumbnail / preview
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_circle_outline,
                color: DesignTokens.neonCyan.withValues(alpha: 0.7),
                size: 56,
              ),
              const SizedBox(height: DesignTokens.spacingS),
              Text(
                h.videoTitle,
                style: const TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeBody,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spacingXS),
              Text(
                _formatDuration(h.durationSeconds),
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeCaption,
                ),
              ),
            ],
          ),
          // Playback scrubber (simplified for demo)
          Positioned(left: 0, right: 0, bottom: 0, child: _buildScrubber(h)),
        ],
      ),
    );
  }

  Widget _buildScrubber(VideoHighlights h) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final width = box.size.width;
        setState(() {
          _playbackPosition = (details.localPosition.dx / width).clamp(
            0.0,
            1.0,
          );
        });
      },
      child: Container(
        height: 4,
        margin: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingS,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: _playbackPosition.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGraphSection(VideoHighlights h) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.15),
          width: DesignTokens.borderThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_graph,
                color: DesignTokens.neonCyan,
                size: 16,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              const Text(
                'AI INTEREST GRAPH',
                style: TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: DesignTokens.fontSizeCaption,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'AI',
                  style: TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingM),
          AiHighlightsGraph(
            highlights: h,
            playbackPosition: _playbackPosition,
            height: 72,
            onSeek: (pos) => setState(() => _playbackPosition = pos),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          // Time labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_playbackPosition * h.durationSeconds),
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeMicro,
                ),
              ),
              Text(
                _formatDuration(h.durationSeconds),
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeMicro,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(VideoHighlights h) {
    return Row(
      children: [
        _buildStatCard(
          'Excitement',
          '${(h.overallExcitement * 100).round()}%',
          DesignTokens.neonCyan,
          Icons.local_fire_department,
        ),
        const SizedBox(width: DesignTokens.spacingS),
        _buildStatCard(
          'Key Moments',
          '${h.keyMoments.length}',
          DesignTokens.neonAmber,
          Icons.bolt,
        ),
        const SizedBox(width: DesignTokens.spacingS),
        _buildStatCard(
          'Peak',
          _formatDuration(h.peakMomentTimestamp ?? 0),
          DesignTokens.neonRed,
          Icons.flash_on,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: DesignTokens.borderThin,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: DesignTokens.spacingXS),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: DesignTokens.fontSizeStatSmall,
                fontWeight: DesignTokens.fontWeightStat,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: DesignTokens.textMuted,
                fontSize: DesignTokens.fontSizeMicro,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMoments(VideoHighlights h) {
    return Wrap(
      spacing: DesignTokens.spacingS,
      runSpacing: DesignTokens.spacingS,
      children: h.keyMoments.map((m) {
        return KeyMomentChip(
          moment: m,
          durationSeconds: h.durationSeconds,
          onTap: () {
            setState(() {
              _playbackPosition = h.durationSeconds > 0
                  ? m.timestamp / h.durationSeconds
                  : 0.0;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSuggestedClip(VideoHighlights h) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.neonGold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(
          color: DesignTokens.neonGold.withValues(alpha: 0.25),
          width: DesignTokens.borderThin,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.content_cut, color: DesignTokens.neonGold, size: 20),
          const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SUGGESTED HIGHLIGHT CLIP',
                  style: TextStyle(
                    color: DesignTokens.neonGold,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDuration(h.suggestedClipStart ?? 0)} → '
                  '${_formatDuration(h.suggestedClipEnd ?? h.durationSeconds)} '
                  '(${h.suggestedClipDuration.round()}s)',
                  style: const TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: DesignTokens.fontSizeCaption,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: DesignTokens.neonGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            ),
            child: const Text(
              'Auto-Clip',
              style: TextStyle(
                color: DesignTokens.neonGold,
                fontSize: DesignTokens.fontSizeCaption,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(double seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).round();
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _reanalyze() async {
    if (widget.videoUrl == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    _loadHighlights();
  }
}
