import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GOOGLE CLOUD × DATA FIGHT CENTRAL — PARTNERSHIP LANDING PAGE
// Firebase · Gemini AI · Cloud Run · BigQuery · Maps · Cloud Build
// ═══════════════════════════════════════════════════════════════════════════════

class GooglePartnershipScreen extends StatefulWidget {
  const GooglePartnershipScreen({super.key});

  @override
  State<GooglePartnershipScreen> createState() =>
      _GooglePartnershipScreenState();
}

class _GooglePartnershipScreenState extends State<GooglePartnershipScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulse;
  late AnimationController _slide;
  late Animation<double> _pulseAnim;
  late Animation<Offset> _slideAnim;

  static const _googleBlue = Color(0xFF4285F4);
  static const _googleRed = Color(0xFFEA4335);
  static const _googleYellow = Color(0xFFFBBC04);
  static const _googleGreen = Color(0xFF34A853);
  static const _bg = Color(0xFF050A14);
  static const _panel = Color(0xFF0D1B2A);
  static const _surface = Color(0xFF142236);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slide, curve: Curves.easeOut));
    _slide.forward();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHero(isWide),
            _buildIntegrationGrid(isWide),
            _buildAiSection(isWide),
            _buildInfraSection(isWide),
            _buildStatsStrip(),
            _buildCTA(context),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) => AppBar(
    backgroundColor: _panel,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.neonCyan),
      onPressed: () => context.pop(),
    ),
    title: Row(
      children: [
        _googleG(),
        const SizedBox(width: 10),
        const Text(
          '×',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 18),
        ),
        const SizedBox(width: 10),
        const Text(
          'DFC',
          style: TextStyle(
            color: AppColors.neonCyan,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ],
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 16),
        child: _chipButton('PARTNER APPLICATION', _googleBlue, () {}),
      ),
    ],
  );

  Widget _googleG() => Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      gradient: const SweepGradient(
        colors: [
          _googleBlue,
          _googleRed,
          _googleYellow,
          _googleGreen,
          _googleBlue,
        ],
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Center(
      child: Text(
        'G',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    ),
  );

  // ─── Hero ─────────────────────────────────────────────────────────────────
  Widget _buildHero(bool isWide) => SlideTransition(
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
          colors: [Color(0xFF050A14), Color(0xFF0A1628), Color(0xFF050A14)],
        ),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) =>
                Opacity(opacity: _pulseAnim.value, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: _googleBlue.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(20),
                color: _googleBlue.withValues(alpha: 0.08),
              ),
              child: const Text(
                'OFFICIAL TECHNOLOGY PARTNER',
                style: TextStyle(
                  color: _googleBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Google Cloud\npowers the DFC\nIntelligence Engine.',
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
            'Firebase · Gemini 2.0 · Cloud Run · BigQuery · Google Maps · Cloud Build\n'
            'Every prediction, every live update, every fighter profile — powered by Google infrastructure.',
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
              _primaryBtn('EXPLORE INTEGRATIONS', _googleBlue, () {}),
              _outlineBtn('VIEW ARCHITECTURE', AppColors.textSecondary, () {}),
            ],
          ),
        ],
      ),
    ),
  );

  // ─── Integration Grid ──────────────────────────────────────────────────────
  Widget _buildIntegrationGrid(bool isWide) => Container(
    color: _panel,
    padding: EdgeInsets.symmetric(horizontal: isWide ? 120 : 24, vertical: 72),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('GOOGLE × DFC INTEGRATION MAP', _googleBlue),
        const SizedBox(height: 40),
        GridView.count(
          crossAxisCount: isWide ? 3 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isWide ? 1.4 : 1.1,
          children: const [
            _IntegrationCard(
              icon: Icons.local_fire_department,
              color: _googleRed,
              title: 'Firebase Firestore',
              subtitle:
                  'Real-time fight data, PPV events, fighter profiles, social feed — all live-synced.',
            ),
            _IntegrationCard(
              icon: Icons.psychology,
              color: _googleBlue,
              title: 'Gemini 2.0 AI',
              subtitle:
                  'Fight predictions, content generation, coaching insights, and SHAP explanations.',
            ),
            _IntegrationCard(
              icon: Icons.cloud_queue,
              color: _googleGreen,
              title: 'Cloud Run',
              subtitle:
                  'Containerised microservices: predictor, poster-worker, entitlements, genkit.',
            ),
            _IntegrationCard(
              icon: Icons.bar_chart,
              color: _googleYellow,
              title: 'BigQuery',
              subtitle:
                  'Event analytics, fight outcome modeling, revenue attribution, and feed KPIs.',
            ),
            _IntegrationCard(
              icon: Icons.map_outlined,
              color: _googleBlue,
              title: 'Google Maps',
              subtitle:
                  'Global fight venue GIS, gym discovery, and live event location intelligence.',
            ),
            _IntegrationCard(
              icon: Icons.build_circle_outlined,
              color: _googleGreen,
              title: 'Cloud Build',
              subtitle:
                  'CI/CD pipeline deploying every DFC service update to production in minutes.',
            ),
          ],
        ),
      ],
    ),
  );

  // ─── AI Section ───────────────────────────────────────────────────────────
  Widget _buildAiSection(bool isWide) => Container(
    padding: EdgeInsets.symmetric(horizontal: isWide ? 120 : 24, vertical: 72),
    child: isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _aiText()),
              const SizedBox(width: 60),
              Expanded(child: _aiVisual()),
            ],
          )
        : Column(
            children: [_aiText(), const SizedBox(height: 40), _aiVisual()],
          ),
  );

  Widget _aiText() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('GEMINI AI × DFC PREDICTOR', _googleBlue),
      const SizedBox(height: 20),
      const Text(
        'Fight intelligence\nat Gemini scale.',
        style: TextStyle(
          color: Colors.white,
          fontSize: 38,
          fontWeight: FontWeight.w900,
          height: 1.1,
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'DFC\'s AI Fight Predictor uses Gemini 2.0 Flash for natural-language fight breakdowns, '
        'tactical coaching explanations, and real-time SHAP-driven analysis. '
        'Every prediction is explainable, auditable, and grounded in real fight data.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
          height: 1.7,
        ),
      ),
      const SizedBox(height: 28),
      ..._aiFeatures.map(
        (f) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _googleBlue,
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

  static const _aiFeatures = [
    'Real-time win probability morphing as conditioning inputs change',
    'SHAP explainability tree — see exactly what drives each prediction',
    'Natural-language fight breakdowns for every bout on the card',
    'Gemini-powered coaching suggestions integrated into training flows',
    'Automated fight content generation for social and media feeds',
  ];

  Widget _aiVisual() => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: _panel,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _googleBlue.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.psychology, color: _googleBlue, size: 18),
            const SizedBox(width: 8),
            const Text(
              'GEMINI PREDICTION ENGINE',
              style: TextStyle(
                color: _googleBlue,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _googleGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: _googleGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _shapBar('Win Probability — Fighter A', 0.74, _googleBlue),
        const SizedBox(height: 10),
        _shapBar('Camp Length Advantage', 0.58, _googleGreen),
        const SizedBox(height: 10),
        _shapBar('Fatigue Differential', 0.42, _googleYellow),
        const SizedBox(height: 10),
        _shapBar('Weight Cut Severity', 0.31, _googleRed),
        const SizedBox(height: 10),
        _shapBar('Market Odds Edge', 0.27, _googleBlue),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _googleBlue.withValues(alpha: 0.15)),
          ),
          child: const Text(
            '"Fighter A\'s extended 10-week camp combined with a minimal weight cut gives a '
            'significant conditioning edge. Gemini projects 74% win probability via decision."',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _shapBar(String label, double value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            '${(value * 100).round()}%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Stack(
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          FractionallySizedBox(
            widthFactor: value,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    ],
  );

  // ─── Infra Section ────────────────────────────────────────────────────────
  Widget _buildInfraSection(bool isWide) => Container(
    color: _panel,
    padding: EdgeInsets.symmetric(horizontal: isWide ? 120 : 24, vertical: 72),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('PRODUCTION INFRASTRUCTURE', _googleGreen),
        const SizedBox(height: 40),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: const [
            _InfraChip('Cloud Run', 'australia-southeast1', _googleGreen),
            _InfraChip('Firebase Auth', 'Multi-platform OAuth', _googleBlue),
            _InfraChip('Firestore', 'Real-time + offline sync', _googleRed),
            _InfraChip('Cloud Build', 'CI/CD pipeline', _googleYellow),
            _InfraChip('Cloud Storage', 'Media + poster assets', _googleGreen),
            _InfraChip('Cloud Pub/Sub', 'Event-driven ingestion', _googleBlue),
            _InfraChip('Cloud Logging', 'Full observability stack', _googleRed),
            _InfraChip(
              'Cloud Secrets',
              'Zero-trust key management',
              _googleYellow,
            ),
          ],
        ),
      ],
    ),
  );

  // ─── Stats ────────────────────────────────────────────────────────────────
  Widget _buildStatsStrip() => Container(
    color: _googleBlue.withValues(alpha: 0.08),
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        _StatItem('8', 'Cloud Run Services\nDeployed'),
        _StatItem('<200ms', 'Avg Prediction\nLatency'),
        _StatItem('1hr TTL', 'Prediction Cache\nin Firestore'),
        _StatItem('100%', 'GCP-Managed\nInfrastructure'),
      ],
    ),
  );

  // ─── CTA ──────────────────────────────────────────────────────────────────
  Widget _buildCTA(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
    child: Column(
      children: [
        const Text(
          'Ready to build with DFC × Google Cloud?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Join the platform built for the next generation of combat sports.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 36),
        _primaryBtn('APPLY AS TECHNOLOGY PARTNER', _googleBlue, () {}),
      ],
    ),
  );

  Widget _buildFooter() => Container(
    color: _panel,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    child: const Text(
      'Data Fight Central © 2026 · Built on Google Cloud · datafightcentral.com',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
    ),
  );

  // ─── Helpers ──────────────────────────────────────────────────────────────
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
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
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

  Widget _chipButton(String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
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

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _IntegrationCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _IntegrationCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  static const _panel = Color(0xFF0D1B2A);

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
            color: color.withValues(alpha: 0.12),
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

class _InfraChip extends StatelessWidget {
  final String title;
  final String sub;
  final Color color;
  const _InfraChip(this.title, this.sub, this.color);

  static const _surface = Color(0xFF142236);

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

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem(this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Color(0xFF4285F4),
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
