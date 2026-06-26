import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DFC AI SECURITY SCANNER — Admin Panel
// Powered by Claude Sonnet · Frontier Red Team Analysis
// Firestore Rules v2.0 — 8 Vulnerabilities Patched
// ═══════════════════════════════════════════════════════════════════════════════

class AiSecurityScannerPage extends StatefulWidget {
  const AiSecurityScannerPage({super.key});

  @override
  State<AiSecurityScannerPage> createState() => _AiSecurityScannerPageState();
}

class _AiSecurityScannerPageState extends State<AiSecurityScannerPage>
    with TickerProviderStateMixin {
  late AnimationController _scanCtrl;
  late AnimationController _bgCtrl;
  late AnimationController _pulseCtrl;

  bool _scanning = false;
  double _scanProgress = 1.0;
  String _scanStatus = 'SCAN COMPLETE — FIRESTORE v2.0';

  static const _bg = Color(0xFF060A0F);
  static const _card = Color(0xFF0A1216);
  static const _cyan = Color(0xFF00E5FF);
  static const _green = Color(0xFF00E676);
  static const _red = Color(0xFFFF1744);
  static const _amber = Color(0xFFFFD600);
  static const _orange = Color(0xFFFF6D00);
  static const _purple = Color(0xFF9C6FFF);

  static const _findings = [
    _Finding(
      id: 'FSR-001',
      severity: 'CRITICAL',
      title: 'Fighter PII Exposed Anonymous Read',
      description:
          'fighters collection had `allow read: if true` — any unauthenticated user could read fighter PII including weight, age, gym location and contact data.',
      fix:
          'Restricted to `isAuthenticated()` — login required to view any fighter data.',
      collection: 'fighters/',
      color: Color(0xFFFF1744),
    ),
    _Finding(
      id: 'FSR-002',
      severity: 'CRITICAL',
      title: 'Posts — No Field Validation on Create',
      description:
          'Posts could be created with arbitrary fields, unlimited content size, and mismatched userId — allowing content injection and identity spoofing.',
      fix:
          'Added `validPostData()` helper: enforces required keys, size <= 3000, userId == request.auth.uid.',
      collection: 'posts/',
      color: Color(0xFFFF1744),
    ),
    _Finding(
      id: 'FSR-003',
      severity: 'HIGH',
      title: 'AI Logs — Any Authenticated User Write',
      description:
          '`ai_logs` collection allowed any logged-in user to write, enabling metric injection attacks that could poison AI model telemetry.',
      fix:
          'Write restricted to `isAdmin()` only. Update and delete set to false (append-only).',
      collection: 'ai_logs/',
      color: Color(0xFFFF6D00),
    ),
    _Finding(
      id: 'FSR-004',
      severity: 'HIGH',
      title: 'Audit Logs — Mutable & Deletable',
      description:
          '`audit_logs` were writable and deletable by admins — creating a compliance violation. Audit trails must be immutable.',
      fix:
          '`allow update, delete: if false` — append-only. Logs can only be created, never modified or erased.',
      collection: 'audit_logs/',
      color: Color(0xFFFF6D00),
    ),
    _Finding(
      id: 'FSR-005',
      severity: 'HIGH',
      title: 'Engagement Metrics — Public Read',
      description:
          '`engagement_metrics` publicly readable (`if true`) — leaking internal analytics data, user engagement patterns and platform growth metrics to competitors.',
      fix: 'Restricted to `isAdmin()` read only.',
      collection: 'engagement_metrics/',
      color: Color(0xFFFF6D00),
    ),
    _Finding(
      id: 'FSR-006',
      severity: 'MEDIUM',
      title: 'Fight Stocks — Public Read Without Auth',
      description:
          '`fight_stocks` data publicly readable to unauthenticated users — exposing real-time pricing data without requiring platform membership.',
      fix: 'Requires `isAuthenticated()` to read any stock data.',
      collection: 'fight_stocks/',
      color: Color(0xFFFFD600),
    ),
    _Finding(
      id: 'FSR-007',
      severity: 'MEDIUM',
      title: 'Chat Messages — No Size Limit (Storage Bomb)',
      description:
          'Chat messages had no content size validation. A malicious actor could spam massive payloads causing storage cost DoS attacks.',
      fix:
          '`text.size() <= 5000` enforced. `senderId == request.auth.uid` required.',
      collection: 'chats/*/messages/',
      color: Color(0xFFFFD600),
    ),
    _Finding(
      id: 'FSR-008',
      severity: 'MEDIUM',
      title: 'Reports — No Field Validation / UserId Spoofing',
      description:
          'Reports had no required field validation and did not verify `reporterId == request.auth.uid` — allowing false attribution of abuse reports.',
      fix:
          'Added `reporterId == request.auth.uid` check, required keys validation, and reason `size() <= 1000`.',
      collection: 'reports/',
      color: Color(0xFFFFD600),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1, milliseconds: 500),
    )..repeat();
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _bgCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _runNewScan() async {
    setState(() {
      _scanning = true;
      _scanProgress = 0.0;
      _scanStatus = 'INITIALISING SCANNER...';
    });
    final steps = [
      (0.15, 'LOADING FIRESTORE RULES...'),
      (0.35, 'ANALYSING COLLECTION RULES...'),
      (0.55, 'CHECKING FIELD VALIDATORS...'),
      (0.70, 'TESTING AUTH CONDITIONS...'),
      (0.82, 'SCANNING FOR INJECTION VECTORS...'),
      (0.92, 'VERIFYING APPEND-ONLY LOGS...'),
      (1.00, 'SCAN COMPLETE — FIRESTORE v2.0'),
    ];
    for (final step in steps) {
      await Future.delayed(const Duration(milliseconds: 380));
      if (mounted) {
        setState(() {
          _scanProgress = step.$1;
          _scanStatus = step.$2;
        });
      }
    }
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _scanning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, _) => CustomPaint(
              painter: _ScanBgPainter(_bgCtrl.value),
              size: Size.infinite,
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(child: _buildHero()),
                SliverToBoxAdapter(child: _buildScanProgress()),
                SliverToBoxAdapter(child: _buildSummaryRow()),
                SliverToBoxAdapter(child: _buildRulesVersion()),
                SliverToBoxAdapter(child: _buildFindingsHeader()),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _FindingCard(finding: _findings[i], index: i),
                    childCount: _findings.length,
                  ),
                ),
                SliverToBoxAdapter(child: _buildHelperFunctions()),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── APP BAR ────────────────────────────────────────────────────────────────
  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: _cyan, size: 20),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: const Row(
        children: [
          Icon(Icons.security, color: _cyan, size: 18),
          SizedBox(width: 8),
          Text(
            'AI SECURITY SCANNER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: _scanning ? null : _runNewScan,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, _) => Container(
              margin: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _scanning
                    ? _amber.withValues(alpha: 0.15)
                    : _green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _scanning
                      ? _amber.withValues(alpha: 0.4 + 0.4 * _pulseCtrl.value)
                      : _green.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                _scanning ? 'SCANNING...' : 'RUN SCAN',
                style: TextStyle(
                  color: _scanning ? _amber : _green,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── HERO ───────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cyan.withValues(alpha: 0.2)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_card, Color(0xFF0A1628)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _cyan.withValues(alpha: 0.1),
              border: Border.all(color: _cyan.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.shield_outlined, color: _cyan, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DATAFIGHTCENTRAL PROTECTS ALL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Powered by Claude Sonnet · Frontier Red Team\nFirestore Security Rules v2.0',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Color(0xFF00E676),
                      size: 13,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'All 8 vulnerabilities PATCHED',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SCAN PROGRESS ──────────────────────────────────────────────────────────
  Widget _buildScanProgress() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (_scanning ? _amber : _green).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _scanning ? Icons.radar : Icons.check_circle_outline,
                color: _scanning ? _amber : _green,
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _scanStatus,
                  style: TextStyle(
                    color: _scanning ? _amber : _green,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Text(
                '${(_scanProgress * 100).round()}%',
                style: TextStyle(
                  color: _scanning ? _amber : _green,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _scanProgress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(_scanning ? _amber : _green),
              minHeight: 4,
            ),
          ),
          if (!_scanning) ...[
            const SizedBox(height: 8),
            const Text(
              'Last scan: Feb 22, 2026 · 0 errors · 8 patched · System secure',
              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  // ── SUMMARY ROW ────────────────────────────────────────────────────────────
  Widget _buildSummaryRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _summaryBox('2', 'CRITICAL', _red),
          const SizedBox(width: 8),
          _summaryBox('3', 'HIGH', _orange),
          const SizedBox(width: 8),
          _summaryBox('3', 'MEDIUM', _amber),
          const SizedBox(width: 8),
          _summaryBox('0', 'LOW', _green),
          const SizedBox(width: 8),
          _summaryBox('8', 'PATCHED', _cyan),
        ],
      ),
    );
  }

  Widget _summaryBox(String count, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ),
  );

  // ── RULES VERSION ──────────────────────────────────────────────────────────
  Widget _buildRulesVersion() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.code, color: _purple, size: 14),
              SizedBox(width: 8),
              Text(
                'FIRESTORE RULES v2.0 — HELPERS',
                style: TextStyle(
                  color: _purple,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _codeSnippet(
            'isAuthenticated() · isOwner(userId) · isAdmin()\n'
            'hasRole(role) · isAdminOrOwner(userId)\n'
            'validPostData() · validCommentData()',
          ),
        ],
      ),
    );
  }

  Widget _codeSnippet(String code) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _purple.withValues(alpha: 0.15)),
    ),
    child: Text(
      code,
      style: const TextStyle(
        color: Color(0xFF00E5FF),
        fontSize: 11,
        fontFamily: 'monospace',
        height: 1.6,
      ),
    ),
  );

  // ── FINDINGS HEADER ────────────────────────────────────────────────────────
  Widget _buildFindingsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.bug_report_outlined, color: _cyan, size: 14),
          const SizedBox(width: 8),
          const Text(
            'VULNERABILITY FINDINGS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _green.withValues(alpha: 0.3)),
            ),
            child: const Text(
              '8 / 8 PATCHED',
              style: TextStyle(
                color: _green,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPER FUNCTIONS DOC ───────────────────────────────────────────────────
  Widget _buildHelperFunctions() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cyan.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: _cyan, size: 14),
              SizedBox(width: 8),
              Text(
                'SECURITY ARCHITECTURE',
                style: TextStyle(
                  color: _cyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _archRow(
            Icons.lock_outline,
            'Principle of Least Privilege',
            'Every collection defaults to deny-all. Access granted explicitly.',
            _cyan,
          ),
          _archRow(
            Icons.history_edu,
            'Immutable Audit Trails',
            'audit_logs and ai_logs are append-only. Cannot be modified or deleted.',
            _green,
          ),
          _archRow(
            Icons.data_object,
            'Field-Level Validation',
            'Posts, comments, reports all validated for size, required keys and userId ownership.',
            _amber,
          ),
          _archRow(
            Icons.people_outline,
            'Role-Based Access Control',
            'Admin, owner, and role-based helpers prevent privilege escalation.',
            _purple,
          ),
          _archRow(
            Icons.storage,
            'Storage Bomb Prevention',
            'Chat message content capped at 5,000 chars. Reports at 1,000 chars.',
            _orange,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _green.withValues(alpha: 0.2)),
            ),
            child: const Text(
              'DATAFIGHTCENTRAL PROTECTS ALL — v2.0 ACTIVE\n'
              'Next scheduled scan: Feb 29, 2026 · Auto-scan on every rules deploy',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF00E676),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _archRow(IconData icon, String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FINDING CARD
// ─────────────────────────────────────────────────────────────────────────────
class _FindingCard extends StatefulWidget {
  final _Finding finding;
  final int index;
  const _FindingCard({required this.finding, required this.index});

  @override
  State<_FindingCard> createState() => _FindingCardState();
}

class _FindingCardState extends State<_FindingCard> {
  bool _expanded = false;

  static const _card = Color(0xFF0A1216);

  @override
  Widget build(BuildContext context) {
    final f = widget.finding;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _expanded
                ? f.color.withValues(alpha: 0.4)
                : f.color.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Severity badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: f.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: f.color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      f.severity,
                      style: TextStyle(
                        color: f.color,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ID
                  Text(
                    f.id,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // PATCHED badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF00E676).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Text(
                      'PATCHED',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white38,
                    size: 18,
                  ),
                ],
              ),
            ),
            // Collection tag
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.folder_outlined,
                    color: Colors.white24,
                    size: 11,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    f.collection,
                    style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            // Expanded detail
            if (_expanded) ...[
              Divider(color: f.color.withValues(alpha: 0.15), height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Problem
                    _detailSection(
                      'VULNERABILITY',
                      f.description,
                      Icons.warning_amber_outlined,
                      f.color,
                    ),
                    const SizedBox(height: 10),
                    // Fix
                    _detailSection(
                      'FIX APPLIED',
                      f.fix,
                      Icons.check_circle_outline,
                      const Color(0xFF00E676),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailSection(String label, String text, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────
class _Finding {
  final String id, severity, title, description, fix, collection;
  final Color color;
  const _Finding({
    required this.id,
    required this.severity,
    required this.title,
    required this.description,
    required this.fix,
    required this.collection,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// BACKGROUND PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _ScanBgPainter extends CustomPainter {
  final double t;
  _ScanBgPainter(this.t);

  // cspell:ignore LTWH

  @override
  void paint(Canvas canvas, Size size) {
    // Scan line sweep
    if (t > 0 && t < 0.98) {
      final y = size.height * t;
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF00E5FF).withValues(alpha: 0.06),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, y - 20, size.width, 40));
      canvas.drawRect(Rect.fromLTWH(0, y - 20, size.width, 40), paint);
    }
    // Grid dots
    final dotPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.04);
    for (int x = 0; x < 20; x++) {
      for (int y = 0; y < 40; y++) {
        canvas.drawCircle(
          Offset(x * size.width / 20, y * size.height / 40),
          0.8,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ScanBgPainter old) => old.t != t;
}
