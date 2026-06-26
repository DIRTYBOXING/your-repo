import 'dart:math';
import 'package:flutter/material.dart' hide RouterConfig;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/config/router_config.dart' as app_router;
import '../../../shared/services/blotato_viral_coach_service.dart';

/// Viral AI Coach Feedback Screen
///
/// Displays Blotato analysis results: scorecard, hooks, hashtags, tips.
/// Matches architecture: User → DFC Backend → Blotato API → Display Results
class ViralAiCoachScreen extends StatefulWidget {
  const ViralAiCoachScreen({super.key});

  @override
  State<ViralAiCoachScreen> createState() => _ViralAiCoachScreenState();
}

class _ViralAiCoachScreenState extends State<ViralAiCoachScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isAnalyzing = false;
  VideoAnalysis? _analysis;

  // Demo data for display
  final _demoAnalysis = const VideoAnalysis(
    id: 'demo',
    userId: 'demo',
    videoUrl: '',
    videoTitle: 'Training camp day 14 — new combo drill',
    status: 'completed',
    overallScore: 72,
    scores: ScoreBreakdown(
      openingHook: 65,
      painBenefitHook: 78,
      noSoundClarity: 82,
      infoDensity: 68,
      emotionalResonance: 70,
    ),
    overallFeedback:
        'Solid content but your hook needs work. The first 2 seconds are static — '
        'lead with the combo impact or a bold claim. Add text overlay for mute viewers.',
    suggestedHooks: [
      'This 3-punch combo ends fights in round 1...',
      'My coach said this drill is banned in some gyms 👀',
      'Day 14 of fight camp — watch what happens at 0:08',
      'The combo that changed my entire game',
      'Nobody teaches this footwork trick',
    ],
    hashtags: HashtagRecommendation(
      broad: ['fyp', 'mma', 'boxing'],
      niche: ['fightcamp', 'combosports'],
    ),
    improvementTips: [
      'Start with the impact — show the combination landing before the setup',
      'Add captions: 65% of social video is watched on mute',
      'End with a question to boost comments ("What combo should I drill next?")',
      'Trim to under 15 seconds — shorter videos get 2x completion rate on TikTok',
    ],
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _analysis = _demoAnalysis;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _simulateAnalysis() {
    setState(() => _isAnalyzing = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _analysis = _demoAnalysis;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'Viral AI Coach',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: DesignTokens.neonCyan),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: DesignTokens.neonCyan),
            onPressed: () {},
            tooltip: 'Analysis History',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: DesignTokens.neonCyan,
          labelColor: DesignTokens.neonCyan,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'SCORECARD'),
            Tab(text: 'HOOKS'),
            Tab(text: 'DISTRIBUTE'),
          ],
        ),
      ),
      body: _isAnalyzing
          ? _buildAnalyzingState()
          : _analysis == null
          ? _buildUploadPrompt()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildScorecardTab(),
                _buildHooksTab(),
                _buildDistributeTab(),
              ],
            ),
      floatingActionButton: _analysis != null && !_isAnalyzing
          ? FloatingActionButton.extended(
              onPressed: _simulateAnalysis,
              backgroundColor: DesignTokens.neonCyan,
              icon: const Icon(Icons.refresh, color: DesignTokens.bgPrimary),
              label: const Text(
                'Re-analyze',
                style: TextStyle(
                  color: DesignTokens.bgPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  // ── Analyzing State ────────────────────────────────────────────────────
  Widget _buildAnalyzingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(
                DesignTokens.neonCyan.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Analyzing your video...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI is scoring hooks, clarity, and emotional resonance',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Upload Prompt ──────────────────────────────────────────────────────
  Widget _buildUploadPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_call,
              size: 64,
              color: DesignTokens.neonCyan.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upload a Draft Video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get AI feedback on your hook, pacing, and viral potential before posting.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _simulateAnalysis,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.neonCyan,
                foregroundColor: DesignTokens.bgPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.upload_file),
              label: const Text(
                'Select Video',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SCORECARD TAB ──────────────────────────────────────────────────────
  Widget _buildScorecardTab() {
    final a = _analysis!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall Score Ring
        _buildOverallScore(a.overallScore),
        const SizedBox(height: 20),

        // Score Breakdown
        ...a.scores.entries.map((e) => _buildScoreBar(e.key, e.value)),
        const SizedBox(height: 20),

        // Feedback
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DesignTokens.neonAmber.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: DesignTokens.neonAmber,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'AI Feedback',
                    style: TextStyle(
                      color: DesignTokens.neonAmber,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                a.overallFeedback,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Improvement Tips
        const Text(
          'IMPROVEMENT TIPS',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        ...a.improvementTips.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${e.key + 1}',
                      style: const TextStyle(
                        color: DesignTokens.neonCyan,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.value,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildOverallScore(int score) {
    final color = score >= 70
        ? DesignTokens.neonGreen
        : score >= 50
        ? DesignTokens.neonAmber
        : DesignTokens.neonRed;

    return Center(
      child: SizedBox(
        width: 140,
        height: 140,
        child: CustomPaint(
          painter: _ScoreRingPainter(score / 100, color),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    color: color,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  score >= 70 ? 'VIRAL READY' : 'NEEDS WORK',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBar(String label, int score) {
    final color = score >= 70
        ? DesignTokens.neonGreen
        : score >= 50
        ? DesignTokens.neonAmber
        : DesignTokens.neonRed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              Text(
                '$score/100',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  // ── HOOKS TAB ──────────────────────────────────────────────────────────
  Widget _buildHooksTab() {
    final a = _analysis!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Suggested Hooks
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.neonMagenta.withValues(alpha: 0.08),
                DesignTokens.neonCyan.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DesignTokens.neonMagenta.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: DesignTokens.neonMagenta,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'AI-Generated Viral Hooks',
                    style: TextStyle(
                      color: DesignTokens.neonMagenta,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Based on 1,000+ viral combat sports videos. Tap to copy.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        ...a.suggestedHooks.asMap().entries.map(
          (e) => _HookCard(
            index: e.key + 1,
            text: e.value,
            onCopy: () {
              Clipboard.setData(ClipboardData(text: e.value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hook copied: "${e.value}"'),
                  backgroundColor: DesignTokens.bgSecondary,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // Hashtag Recommendations
        const Text(
          'RECOMMENDED HASHTAGS',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Broad Reach',
          style: TextStyle(
            color: DesignTokens.neonCyan,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: a.hashtags.broad
              .map((tag) => _HashtagChip(tag: tag, isBroad: true))
              .toList(),
        ),
        const SizedBox(height: 12),
        const Text(
          'Niche Discovery',
          style: TextStyle(
            color: DesignTokens.neonGreen,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: a.hashtags.niche
              .map((tag) => _HashtagChip(tag: tag, isBroad: false))
              .toList(),
        ),
        const SizedBox(height: 12),

        // Copy all hashtags
        OutlinedButton.icon(
          onPressed: () {
            final all = a.hashtags.all.map((t) => '#$t').join(' ');
            Clipboard.setData(ClipboardData(text: all));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('All hashtags copied!'),
                backgroundColor: DesignTokens.bgSecondary,
              ),
            );
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy All Hashtags'),
          style: OutlinedButton.styleFrom(
            foregroundColor: DesignTokens.neonCyan,
            side: BorderSide(
              color: DesignTokens.neonCyan.withValues(alpha: 0.3),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── DISTRIBUTE TAB ─────────────────────────────────────────────────────
  Widget _buildDistributeTab() {
    final platforms = [
      _PlatformItem('TikTok', Icons.music_note, DesignTokens.neonRed, true),
      _PlatformItem(
        'Instagram',
        Icons.camera_alt,
        DesignTokens.neonMagenta,
        true,
      ),
      _PlatformItem(
        'YouTube Shorts',
        Icons.play_circle,
        DesignTokens.neonRed,
        true,
      ),
      _PlatformItem('LinkedIn', Icons.work, DesignTokens.neonCyan, true),
      _PlatformItem('Threads', Icons.alternate_email, Colors.white70, true),
      _PlatformItem('Bluesky', Icons.cloud, DesignTokens.neonCyan, true),
      _PlatformItem('Pinterest', Icons.push_pin, DesignTokens.neonRed, false),
      _PlatformItem('X / Twitter', Icons.tag, Colors.white70, true),
      _PlatformItem('Facebook', Icons.facebook, DesignTokens.neonCyan, true),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DesignTokens.neonGreen.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.rocket_launch,
                    color: DesignTokens.neonGreen,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Cross-Platform Distribution',
                    style: TextStyle(
                      color: DesignTokens.neonGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Publish to all 9 platforms with one tap via Blotato.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ...platforms.map((p) => _PlatformToggleTile(platform: p)),

        const SizedBox(height: 20),

        // Publish Now
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              context.push(
                app_router.RouterConfig.crossPlatformPublishPath,
                extra: {
                  'caption': _analysis?.videoTitle ?? '',
                  'hashtags':
                      _analysis?.hashtags.all.map((t) => '#$t').join(' ') ?? '',
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.neonGreen,
              foregroundColor: DesignTokens.bgPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.send),
            label: const Text(
              'Publish Now',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Schedule
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              context.push(
                app_router.RouterConfig.crossPlatformPublishPath,
                extra: {
                  'caption': _analysis?.videoTitle ?? '',
                  'hashtags':
                      _analysis?.hashtags.all.map((t) => '#$t').join(' ') ?? '',
                  'schedule': true,
                },
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: DesignTokens.neonAmber,
              side: BorderSide(
                color: DesignTokens.neonAmber.withValues(alpha: 0.3),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.schedule),
            label: const Text(
              'Schedule for Later',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Score Ring Painter ───────────────────────────────────────────────────

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScoreRingPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// ── Hook Card ────────────────────────────────────────────────────────────

class _HookCard extends StatelessWidget {
  final int index;
  final String text;
  final VoidCallback onCopy;

  const _HookCard({
    required this.index,
    required this.text,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onCopy,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: DesignTokens.neonCyan.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: DesignTokens.neonMagenta.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: DesignTokens.neonMagenta,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ),
              Icon(
                Icons.copy,
                size: 16,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hashtag Chip ─────────────────────────────────────────────────────────

class _HashtagChip extends StatelessWidget {
  final String tag;
  final bool isBroad;

  const _HashtagChip({required this.tag, required this.isBroad});

  @override
  Widget build(BuildContext context) {
    final color = isBroad ? DesignTokens.neonCyan : DesignTokens.neonGreen;
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: '#$tag'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('#$tag copied'),
            backgroundColor: DesignTokens.bgSecondary,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          '#$tag',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Platform Toggle ──────────────────────────────────────────────────────

class _PlatformItem {
  final String name;
  final IconData icon;
  final Color color;
  bool enabled;

  _PlatformItem(this.name, this.icon, this.color, this.enabled);
}

class _PlatformToggleTile extends StatefulWidget {
  final _PlatformItem platform;
  const _PlatformToggleTile({required this.platform});

  @override
  State<_PlatformToggleTile> createState() => _PlatformToggleTileState();
}

class _PlatformToggleTileState extends State<_PlatformToggleTile> {
  @override
  Widget build(BuildContext context) {
    final p = widget.platform;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: p.enabled ? p.color.withValues(alpha: 0.2) : Colors.white12,
          ),
        ),
        child: SwitchListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          secondary: Icon(p.icon, color: p.color, size: 22),
          title: Text(
            p.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          subtitle: Text(
            p.enabled ? 'Connected' : 'Disconnected',
            style: TextStyle(
              color: p.enabled
                  ? DesignTokens.neonGreen.withValues(alpha: 0.7)
                  : Colors.white30,
              fontSize: 10,
            ),
          ),
          value: p.enabled,
          activeTrackColor: DesignTokens.neonGreen,
          onChanged: (v) => setState(() => p.enabled = v),
        ),
      ),
    );
  }
}
