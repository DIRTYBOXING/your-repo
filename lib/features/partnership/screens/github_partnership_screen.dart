import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GITHUB × DATA FIGHT CENTRAL — DEVELOPER PARTNERSHIP LANDING PAGE
// Open source · CI/CD · Actions · Copilot · Packages · Security
// ═══════════════════════════════════════════════════════════════════════════════

class GithubPartnershipScreen extends StatefulWidget {
  const GithubPartnershipScreen({super.key});
  @override
  State<GithubPartnershipScreen> createState() =>
      _GithubPartnershipScreenState();
}

class _GithubPartnershipScreenState extends State<GithubPartnershipScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _pulseAnim;
  late Animation<Offset> _slideAnim;

  static const _githubPurple = Color(0xFF8957E5);
  static const _githubBlue = Color(0xFF388BFD);
  static const _githubGreen = Color(0xFF3FB950);
  static const _githubOrange = Color(0xFFFFA657);
  static const _bg = Color(0xFF050A14);
  static const _panel = Color(0xFF0D0D1A);
  static const _surface = Color(0xFF131325);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
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
            _actionsSection(isWide),
            _copilotSection(isWide),
            _openSourceSection(isWide),
            _statsStrip(),
            _securitySection(isWide),
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
      icon: const Icon(Icons.arrow_back_ios_new, color: _githubPurple),
      onPressed: () => Navigator.of(context).maybePop(),
    ),
    title: Row(
      children: [
        const Icon(Icons.code, color: Colors.white, size: 22),
        const SizedBox(width: 8),
        const Text(
          'GitHub',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          '×',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 18),
        ),
        const SizedBox(width: 10),
        const Text(
          'DFC',
          style: TextStyle(
            color: _githubPurple,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ],
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 16),
        child: _chipBtn('VIEW ON GITHUB', _githubPurple, () {}),
      ),
    ],
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
          colors: [Color(0xFF050A14), Color(0xFF0D0D1A), Color(0xFF050A14)],
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
                border: Border.all(color: _githubPurple.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(20),
                color: _githubPurple.withValues(alpha: 0.08),
              ),
              child: const Text(
                'OPEN SOURCE · CI/CD · DEVELOPER PLATFORM',
                style: TextStyle(
                  color: _githubPurple,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'GitHub powers the\nDFC development\nIntelligence Pipeline.',
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
            'GitHub Actions CI/CD · Copilot AI · Advanced Security · Packages · Code Scanning\n'
            'Every DFC feature ships through GitHub. Every commit is tested, reviewed, and deployed automatically.',
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
              _primaryBtn('EXPLORE REPOSITORY', _githubPurple, () {}),
              _outlineBtn('CONTRIBUTE', _githubGreen, () {}),
            ],
          ),
        ],
      ),
    ),
  );

  // ─── Actions Section ──────────────────────────────────────────────────────
  Widget _actionsSection(bool isWide) => Container(
    color: _panel,
    padding: EdgeInsets.symmetric(horizontal: isWide ? 120 : 24, vertical: 72),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('GITHUB ACTIONS — DFC CI/CD PIPELINE', _githubBlue),
        const SizedBox(height: 40),
        isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _pipelineVisual()),
                  const SizedBox(width: 60),
                  Expanded(child: _pipelineText()),
                ],
              )
            : Column(
                children: [
                  _pipelineText(),
                  const SizedBox(height: 40),
                  _pipelineVisual(),
                ],
              ),
      ],
    ),
  );

  Widget _pipelineText() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Push code.\nPipeline runs.\nPlatform ships.',
        style: TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.w900,
          height: 1.15,
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'DFC\'s GitHub Actions pipeline runs on every commit: '
        'Flutter web build, Dart analysis, widget tests, Playwright E2E, '
        'Docker image build to GCR, and Cloud Run deployment — '
        'all in under 8 minutes.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
          height: 1.7,
        ),
      ),
      const SizedBox(height: 28),
      ..._pipelineSteps.map(
        (s) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _githubGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: _githubGreen, size: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s,
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

  static const _pipelineSteps = [
    'flutter analyze + dart fix — static analysis on every push',
    'flutter test — widget + unit tests with lcov coverage',
    'playwright test — full E2E PPV, social, and feed smoke tests',
    'docker build → push to Google Container Registry',
    'gcloud run deploy — zero-downtime production rollout',
    'firebase deploy — hosting + functions updated automatically',
  ];

  Widget _pipelineVisual() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _githubBlue.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ci-cd.yml',
          style: TextStyle(
            color: _githubOrange,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 16),
        ..._ciLines.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line.$1,
              style: TextStyle(
                color: line.$2,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ],
    ),
  );

  static const _ciLines = [
    ('on: [push, pull_request]', Color(0xFF8B949E)),
    ('jobs:', Colors.white),
    ('  build-and-deploy:', Color(0xFF79C0FF)),
    ('    runs-on: ubuntu-latest', Color(0xFF8B949E)),
    ('    steps:', Colors.white),
    ('      - flutter analyze', Color(0xFF3FB950)),
    ('      - flutter test', Color(0xFF3FB950)),
    ('      - playwright test', Color(0xFF3FB950)),
    ('      - docker build → GCR', Color(0xFF3FB950)),
    ('      - cloud run deploy', Color(0xFF3FB950)),
    ('      - firebase deploy', Color(0xFF3FB950)),
    ('  status: ✅ passing', Color(0xFF3FB950)),
  ];

  // ─── Copilot Section ──────────────────────────────────────────────────────
  Widget _copilotSection(bool isWide) => Container(
    padding: EdgeInsets.symmetric(horizontal: isWide ? 120 : 24, vertical: 72),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('GITHUB COPILOT — AI DEVELOPMENT PARTNER', _githubPurple),
        const SizedBox(height: 40),
        GridView.count(
          crossAxisCount: isWide ? 3 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isWide ? 1.4 : 1.1,
          children: [
            _DevCard(
              icon: Icons.auto_fix_high,
              color: _githubPurple,
              title: 'Copilot Code Gen',
              subtitle:
                  'AI-assisted Flutter widget generation, Dart service scaffolding, and test writing.',
            ),
            _DevCard(
              icon: Icons.security,
              color: _githubBlue,
              title: 'Code Scanning',
              subtitle:
                  'Automated OWASP Top 10 vulnerability scanning on every PR before merge.',
            ),
            _DevCard(
              icon: Icons.speed,
              color: _githubGreen,
              title: 'PR Review AI',
              subtitle:
                  'Copilot reviews pull requests for bugs, performance issues, and security risks.',
            ),
            _DevCard(
              icon: Icons.inventory_2_outlined,
              color: _githubOrange,
              title: 'GitHub Packages',
              subtitle:
                  'Private Flutter package registry for shared DFC design system components.',
            ),
            _DevCard(
              icon: Icons.merge_type,
              color: _githubPurple,
              title: 'Branch Protection',
              subtitle:
                  'Required reviews, status checks, and signed commits enforced on master.',
            ),
            _DevCard(
              icon: Icons.analytics_outlined,
              color: _githubBlue,
              title: 'Actions Insights',
              subtitle:
                  'Build time analytics, failure tracking, and deployment frequency dashboards.',
            ),
          ],
        ),
      ],
    ),
  );

  // ─── Open Source ──────────────────────────────────────────────────────────
  Widget _openSourceSection(bool isWide) => Container(
    color: _panel,
    padding: EdgeInsets.symmetric(horizontal: isWide ? 120 : 24, vertical: 72),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('OPEN SOURCE × COMBAT SPORTS', _githubGreen),
        const SizedBox(height: 20),
        Text(
          'DFC is built transparently.\nEvery module is auditable.',
          style: TextStyle(
            color: Colors.white,
            fontSize: isWide ? 40 : 28,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'The DFC codebase is structured for community contribution. Fighter safety tools, '
          'judging algorithms, ranking systems, and analytics engines are open to review. '
          'Combat sports deserves transparent technology.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 36),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _RepoChip('lib/', 'Flutter app — 120+ screens', _githubPurple),
            _RepoChip('functions/', 'Firebase Cloud Functions', _githubBlue),
            _RepoChip(
              'services/predictor/',
              'LightGBM + SHAP engine',
              _githubGreen,
            ),
            _RepoChip('firestore.rules', 'Security rules', _githubOrange),
            _RepoChip('.github/workflows/', 'CI/CD Actions', _githubPurple),
            _RepoChip('test/', 'Widget + integration tests', _githubBlue),
          ],
        ),
      ],
    ),
  );

  // ─── Stats ────────────────────────────────────────────────────────────────
  Widget _statsStrip() => Container(
    color: _githubPurple.withValues(alpha: 0.06),
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        _GithubStatItem('120+', 'Flutter Screens\nin Repo'),
        _GithubStatItem('<8min', 'Full Pipeline\nRun Time'),
        _GithubStatItem('100%', 'CI Coverage\non Master'),
        _GithubStatItem('2 PRs', 'Open for\nReview Now'),
      ],
    ),
  );

  // ─── Security ─────────────────────────────────────────────────────────────
  Widget _securitySection(bool isWide) => Container(
    padding: EdgeInsets.symmetric(horizontal: isWide ? 120 : 24, vertical: 72),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('ADVANCED SECURITY', _githubOrange),
        const SizedBox(height: 40),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: const [
            _SecurityChip(
              'Dependabot',
              'Auto dependency updates',
              _githubGreen,
            ),
            _SecurityChip(
              'Secret Scanning',
              'Prevents key leaks',
              _githubOrange,
            ),
            _SecurityChip(
              'CodeQL Analysis',
              'Static security audit',
              _githubBlue,
            ),
            _SecurityChip(
              'Branch Protection',
              'Signed commits required',
              _githubPurple,
            ),
            _SecurityChip(
              'CODEOWNERS',
              'File-level review control',
              _githubGreen,
            ),
            _SecurityChip('Audit Log', 'Full access history', _githubOrange),
          ],
        ),
      ],
    ),
  );

  // ─── CTA ──────────────────────────────────────────────────────────────────
  Widget _cta(BuildContext context) => Container(
    color: _panel,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
    child: Column(
      children: [
        const Text(
          'Build the future of combat sports with DFC.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Open collaboration. Professional grade. Community-driven.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 36),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _primaryBtn('VIEW REPOSITORY', _githubPurple, () {}),
            _outlineBtn('CONTRIBUTE CODE', _githubGreen, () {}),
          ],
        ),
      ],
    ),
  );

  Widget _footer() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    child: const Text(
      'Data Fight Central © 2026 · Powered by GitHub · github.com/DIRTYBOXING/your-repo',
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

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _DevCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _DevCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
  static const _panel = Color(0xFF0D0D1A);
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

class _RepoChip extends StatelessWidget {
  final String title;
  final String sub;
  final Color color;
  const _RepoChip(this.title, this.sub, this.color);
  static const _surface = Color(0xFF131325);
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
            fontFamily: 'monospace',
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

class _SecurityChip extends StatelessWidget {
  final String title;
  final String sub;
  final Color color;
  const _SecurityChip(this.title, this.sub, this.color);
  static const _surface = Color(0xFF131325);
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

class _GithubStatItem extends StatelessWidget {
  final String value;
  final String label;
  const _GithubStatItem(this.value, this.label);
  static const _githubPurple = Color(0xFF8957E5);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: _githubPurple,
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
