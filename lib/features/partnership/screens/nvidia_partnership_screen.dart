import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// NVIDIA × DATA FIGHT CENTRAL — PARTNERSHIP LANDING PAGE
// RTX Vision AI · Jetson Edge · DLSS · Broadcast SDK · Omniverse
// Combat sports + AI-powered computer vision for movement analysis
// ═══════════════════════════════════════════════════════════════════════════════

class NvidiaPartnershipScreen extends StatefulWidget {
  const NvidiaPartnershipScreen({super.key});
  @override
  State<NvidiaPartnershipScreen> createState() =>
      _NvidiaPartnershipScreenState();
}

class _NvidiaPartnershipScreenState extends State<NvidiaPartnershipScreen>
    with TickerProviderStateMixin {
  late AnimationController _scanCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _scanAnim;
  late Animation<Offset> _slideAnim;

  static const _nvidiaGreen = Color(0xFF76B900);
  static const _nvidiaLight = Color(0xFF9FDB2A);
  static const _bg = Color(0xFF050A14);
  static const _panel = Color(0xFF0A1A0A);
  static const _surface = Color(0xFF0F2010);
  static const _border = Color(0xFF1A3A1A);

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scanAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.linear));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: _bg,
      appBar: _appBar(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _hero(isWide),
            _visionTechGrid(isWide),
            _movementAnalysis(isWide),
            _edgeAiSection(isWide),
            _statsStrip(),
            _broadcastSection(isWide),
            _cta(context),
            _footer(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context) => AppBar(
    backgroundColor: _panel,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, color: _nvidiaGreen),
      onPressed: () => Navigator.of(context).maybePop(),
    ),
    title: Row(
      children: [
        _nvidiaLogo(),
        const SizedBox(width: 10),
        const Text(
          '×',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 18),
        ),
        const SizedBox(width: 10),
        const Text(
          'DFC',
          style: TextStyle(
            color: _nvidiaGreen,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ],
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 16),
        child: _chipBtn('TECH PARTNERSHIP', _nvidiaGreen, () {}),
      ),
    ],
  );

  Widget _nvidiaLogo() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _nvidiaGreen,
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Text(
      'NVIDIA',
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w900,
        fontSize: 12,
        letterSpacing: 1,
      ),
    ),
  );

  // ─── Hero ──────────────────────────────────────────────────────────────────
  Widget _hero(bool isWide) => SlideTransition(
    position: _slideAnim,
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 120 : 24,
        vertical: 80,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF050A14), Color(0xFF071A07), Color(0xFF050A14)],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: _nvidiaGreen.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(20),
              color: _nvidiaGreen.withValues(alpha: 0.06),
            ),
            child: const Text(
              'AI VISION + COMBAT SPORTS TECHNOLOGY',
              style: TextStyle(
                color: _nvidiaGreen,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'NVIDIA Vision AI\nbrings combat\nto life.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isWide ? 56 : 38,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'RTX-powered movement tracking · Jetson Edge AI · Broadcast SDK · Pose estimation\n'
            'Real-time fighter technique analysis. Frame-by-frame. Millisecond accuracy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 17,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _primaryBtn('EXPLORE VISION AI', _nvidiaGreen, () {}),
              _outlineBtn('WATCH DEMO', _nvidiaLight, () {}),
            ],
          ),
        ],
      ),
    ),
  );

  // ─── Vision Tech Grid ────────────────────────────────────────────────────
  Widget _visionTechGrid(bool isWide) => Container(
    color: _panel,
    padding: EdgeInsets.symmetric(horizontal: isWide ? 120 : 24, vertical: 72),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('NVIDIA × DFC TECHNOLOGY STACK', _nvidiaGreen),
        const SizedBox(height: 40),
        GridView.count(
          crossAxisCount: isWide ? 3 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isWide ? 1.3 : 1.05,
          children: [
            _TechCard(
              icon: Icons.videocam,
              color: _nvidiaGreen,
              title: 'RTX Vision Cameras',
              subtitle:
                  'High-frame-rate fight capture with AI-assisted motion enhancement and noise reduction.',
            ),
            _TechCard(
              icon: Icons.accessibility_new,
              color: _nvidiaLight,
              title: 'Pose Estimation AI',
              subtitle:
                  '34-point fighter skeleton tracking — stance detection, strike trajectory, guard patterns.',
            ),
            _TechCard(
              icon: Icons.memory,
              color: _nvidiaGreen,
              title: 'Jetson Edge AI',
              subtitle:
                  'On-site Jetson Orin modules processing fight footage locally for sub-10ms latency analytics.',
            ),
            _TechCard(
              icon: Icons.broadcast_on_personal,
              color: _nvidiaLight,
              title: 'Broadcast SDK',
              subtitle:
                  'AI-powered graphics overlays, real-time highlight detection, and automated clip generation.',
            ),
            _TechCard(
              icon: Icons.analytics_outlined,
              color: _nvidiaGreen,
              title: 'cuDNN Inference',
              subtitle:
                  'GPU-accelerated model inference for fight prediction and real-time statistical overlays.',
            ),
            _TechCard(
              icon: Icons.view_in_ar,
              color: _nvidiaLight,
              title: 'Omniverse Integration',
              subtitle:
                  'Digital twin fight simulations and 3D fighter movement reconstruction for coaching.',
            ),
          ],
        ),
      ],
    ),
  );

  // ─── Movement Analysis ────────────────────────────────────────────────────
  Widget _movementAnalysis(bool isWide) => Container(
    padding: EdgeInsets.symmetric(horizontal: isWide ? 120 : 24, vertical: 72),
    child: isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _movementVisual()),
              const SizedBox(width: 60),
              Expanded(child: _movementText()),
            ],
          )
        : Column(
            children: [
              _movementText(),
              const SizedBox(height: 40),
              _movementVisual(),
            ],
          ),
  );

  Widget _movementText() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('REAL-TIME MOVEMENT ANALYSIS', _nvidiaGreen),
      const SizedBox(height: 20),
      const Text(
        'See every technique.\nEvery movement.\nEvery advantage.',
        style: TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.w900,
          height: 1.15,
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'NVIDIA\'s AI tracks 34 body keypoints at 120fps. DFC processes this into actionable '
        'coaching intelligence — strike accuracy, grappling efficiency, fatigue indicators, '
        'and tactical pattern recognition. Fighters see what the AI sees.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
          height: 1.7,
        ),
      ),
      const SizedBox(height: 28),
      ..._movementFeatures.map(
        (f) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _nvidiaGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  f,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  static const _movementFeatures = [
    '34-point skeleton tracking at 120 frames per second',
    'Strike trajectory prediction and impact zone analysis',
    'Guard drop detection with sub-50ms reaction time',
    'Grappling position control time and leverage scoring',
    'Fatigue signature recognition from movement patterns',
    'Instant clip generation when highlight moment detected',
  ];

  Widget _movementVisual() => AnimatedBuilder(
    animation: _scanAnim,
    builder: (_, child) => Container(
      height: 340,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _nvidiaGreen.withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
          child!,
          Positioned(
            top: _scanAnim.value * 290,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _nvidiaGreen.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, color: _nvidiaGreen),
            const SizedBox(width: 8),
            const Text(
              'VISION AI TRACKING',
              style: TextStyle(
                color: _nvidiaGreen,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            const Text(
              '120 FPS',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ..._trackingMetrics.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.radio_button_checked,
                  size: 10,
                  color: _nvidiaGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  m.$1,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  m.$2,
                  style: const TextStyle(
                    color: _nvidiaGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  static const _trackingMetrics = [
    ('Strike Speed — Jab', '11.3 m/s'),
    ('Guard Position', 'HIGH GUARD'),
    ('Footwork Pattern', 'PRESSURE'),
    ('Head Movement', 'ACTIVE'),
    ('Grappling Control', '73%'),
    ('Fatigue Signature', 'LOW (Round 2)'),
    ('Predicted Next Move', 'LEVEL CHANGE'),
    ('Highlight Moment', '⚡ DETECTED'),
  ];

  // ─── Edge AI ─────────────────────────────────────────────────────────────
  Widget _edgeAiSection(bool isWide) => Container(
    color: _panel,
    padding: EdgeInsets.symmetric(horizontal: isWide ? 120 : 24, vertical: 72),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('JETSON EDGE AI — ON-SITE PROCESSING', _nvidiaLight),
        const SizedBox(height: 40),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: const [
            _EdgeChip('Jetson Orin NX', 'On-cage unit', _nvidiaGreen),
            _EdgeChip('Sub 10ms Latency', 'Local inference', _nvidiaLight),
            _EdgeChip('No Cloud Dependency', 'Air-gapped events', _nvidiaGreen),
            _EdgeChip('Multi-camera Sync', '4K × 4 angles', _nvidiaLight),
            _EdgeChip('Instant Replay AI', 'Auto highlight', _nvidiaGreen),
            _EdgeChip('Coach Tablet Feed', 'Real-time HUD', _nvidiaLight),
          ],
        ),
      ],
    ),
  );

  // ─── Stats ────────────────────────────────────────────────────────────────
  Widget _statsStrip() => Container(
    color: _nvidiaGreen.withValues(alpha: 0.06),
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        _NvidiaStatItem('120fps', 'AI Tracking\nFrame Rate'),
        _NvidiaStatItem('34pts', 'Body Keypoints\nTracked'),
        _NvidiaStatItem('<10ms', 'Edge Inference\nLatency'),
        _NvidiaStatItem('4K×4', 'Simultaneous\nCamera Angles'),
      ],
    ),
  );

  // ─── Broadcast Section ────────────────────────────────────────────────────
  Widget _broadcastSection(bool isWide) => Container(
    padding: EdgeInsets.symmetric(horizontal: isWide ? 120 : 24, vertical: 72),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('BROADCAST-GRADE AI PRODUCTION', _nvidiaGreen),
        const SizedBox(height: 40),
        Text(
          'From cage-side camera\nto broadcast-ready content\nin seconds.',
          style: TextStyle(
            color: Colors.white,
            fontSize: isWide ? 40 : 28,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'NVIDIA Broadcast SDK powers DFC\'s automated highlight generation, real-time '
          'statistical overlays, and AI-guided replay sequencing. Every great moment is '
          'captured, clipped, and published — automatically.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            height: 1.7,
          ),
        ),
      ],
    ),
  );

  // ─── CTA ──────────────────────────────────────────────────────────────────
  Widget _cta(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
    child: Column(
      children: [
        const Text(
          'Ready to power combat sports with NVIDIA AI?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'The most advanced combat sports analytics platform on Earth.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 36),
        _primaryBtn('APPLY AS TECHNOLOGY PARTNER', _nvidiaGreen, () {}),
      ],
    ),
  );

  Widget _footer() => Container(
    color: _panel,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    child: const Text(
      'Data Fight Central © 2026 · Powered by NVIDIA Vision AI · datafightcentral.com',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
    ),
  );

  // ─── Helpers ─────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text, Color color) => Text(
    text,
    style: TextStyle(
      color: color,
      fontWeight: FontWeight.w700,
      fontSize: 12,
      letterSpacing: 2,
    ),
  );

  Widget _primaryBtn(String label, Color color, VoidCallback onTap) =>
      ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
      );

  Widget _outlineBtn(String label, Color color, VoidCallback onTap) =>
      OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      );

  Widget _chipBtn(String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
}

class _TechCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _TechCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
  static const _panel = Color(0xFF0A1A0A);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _panel,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

class _EdgeChip extends StatelessWidget {
  final String title;
  final String sub;
  final Color color;
  const _EdgeChip(this.title, this.sub, this.color);
  static const _surface = Color(0xFF0F2010);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        Text(
          sub,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
      ],
    ),
  );
}

class _NvidiaStatItem extends StatelessWidget {
  final String value;
  final String label;
  const _NvidiaStatItem(this.value, this.label);
  static const _nvidiaGreen = Color(0xFF76B900);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: _nvidiaGreen,
          fontSize: 32,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    ],
  );
}
