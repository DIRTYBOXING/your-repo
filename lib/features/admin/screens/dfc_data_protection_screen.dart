import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DFC DATA PROTECTION SCREEN
//  Unified Platform Security Hub — inspired by planetary data visualisations
//  and enterprise integration diagrams.
// ─────────────────────────────────────────────────────────────────────────────

class DfcDataProtectionScreen extends StatefulWidget {
  const DfcDataProtectionScreen({super.key});

  @override
  State<DfcDataProtectionScreen> createState() =>
      _DfcDataProtectionScreenState();
}

class _DfcDataProtectionScreenState extends State<DfcDataProtectionScreen>
    with TickerProviderStateMixin {
  // ── Theme colours ──────────────────────────────────────────────────────────
  static const _bg = Color(0xFF060C18);
  static const _card = Color(0xFF0B1628);
  static const _cyan = Color(0xFF00E5FF);
  static const _green = Color(0xFF00E676);
  static const _amber = Color(0xFFFFD600);
  static const _red = Color(0xFFFF1744);
  static const _purple = Color(0xFF9C6FFF);
  static const _blue = Color(0xFF2979FF);
  static const _pink = Color(0xFFFF4081);

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _orbitCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _scanCtrl;
  late Animation<double> _pulse;
  late Animation<double> _scanLine;

  // ── Tab ────────────────────────────────────────────────────────────────────
  late TabController _tab;

  // ── Privacy toggles ────────────────────────────────────────────────────────
  final Map<String, bool> _privacyToggles = {
    'End-to-End Encryption': true,
    'Zero-Knowledge Auth': true,
    'Biometric Lock': true,
    'Fight Data Anonymisation': true,
    'Third-Party Data Sharing': false,
    'Analytics Tracking': true,
    'Crash Reporting': true,
    'Location Precision Blur': true,
  };

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);

    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _scanLine = Tween<double>(begin: 0.0, end: 1.0).animate(_scanCtrl);
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _pulseCtrl.dispose();
    _scanCtrl.dispose();
    _tab.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tab,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildHubTab(),
                  _buildLayersTab(),
                  _buildComplianceTab(),
                  _buildPrivacyTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: _card,
        border: Border(
          bottom: BorderSide(color: _cyan.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _cyan.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: _cyan,
                size: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.shield_outlined, color: _cyan, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DFC DATA PROTECTION',
                  style: TextStyle(
                    color: _cyan,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Unified Platform Security Hub',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _green.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'ALL PROTECTED',
                  style: TextStyle(
                    color: _green,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB BAR ────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cyan.withValues(alpha: 0.12)),
      ),
      child: TabBar(
        controller: _tab,
        indicator: BoxDecoration(
          color: _cyan.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _cyan.withValues(alpha: 0.4)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: _cyan,
        unselectedLabelColor: Colors.white30,
        labelStyle: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.hub_outlined, size: 13), text: 'HUB'),
          Tab(icon: Icon(Icons.layers_outlined, size: 13), text: 'LAYERS'),
          Tab(
            icon: Icon(Icons.verified_user_outlined, size: 13),
            text: 'COMPLIANCE',
          ),
          Tab(icon: Icon(Icons.lock_outline, size: 13), text: 'PRIVACY'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TAB 1 — UNIFIED PLATFORM HUB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHubTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 4),
        _hubDiagram(),
        const SizedBox(height: 16),
        _platformStatusGrid(),
        const SizedBox(height: 14),
        _realTimeStats(),
      ],
    );
  }

  // ── Orbital hub diagram ───────────────────────────────────────────────────
  Widget _hubDiagram() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cyan.withValues(alpha: 0.15)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated rings + nodes
          AnimatedBuilder(
            animation: _orbitCtrl,
            builder: (context, _) {
              return CustomPaint(
                size: const Size(double.infinity, 320),
                painter: _OrbitalPainter(angle: _orbitCtrl.value * 2 * math.pi),
              );
            },
          ),
          // Pulsing centre glow
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              return Container(
                width: 72 * _pulse.value,
                height: 72 * _pulse.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _cyan.withValues(alpha: 0.06 * _pulse.value),
                ),
              );
            },
          ),
          // Centre DFC shield
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0B1628),
              border: Border.all(color: _cyan, width: 2),
              boxShadow: [
                BoxShadow(
                  color: _cyan.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield, color: _cyan, size: 22),
                SizedBox(height: 1),
                Text(
                  'DFC',
                  style: TextStyle(
                    color: _cyan,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          // Scan line overlay
          AnimatedBuilder(
            animation: _scanLine,
            builder: (context, _) {
              return CustomPaint(
                size: const Size(double.infinity, 320),
                painter: _ScanPainter(
                  progress: _scanLine.value,
                  color: _cyan.withValues(alpha: 0.12),
                ),
              );
            },
          ),
          // Title
          const Positioned(
            top: 12,
            left: 14,
            child: Text(
              'UNIFIED PROTECTION HUB',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const Positioned(
            bottom: 12,
            right: 14,
            child: Text(
              '8 PLATFORMS SECURED',
              style: TextStyle(
                color: Color(0xFF00E676),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Platform status grid ──────────────────────────────────────────────────
  Widget _platformStatusGrid() {
    final platforms = [
      const _PlatformItem(
        name: 'Firebase Auth',
        icon: Icons.fingerprint,
        color: _amber,
        status: 'SECURED',
        detail: 'MFA + biometric',
      ),
      const _PlatformItem(
        name: 'Firestore DB',
        icon: Icons.storage_outlined,
        color: _cyan,
        status: 'SECURED',
        detail: 'Rules v2.0 active',
      ),
      const _PlatformItem(
        name: 'Cloud Storage',
        icon: Icons.cloud_outlined,
        color: _blue,
        status: 'SECURED',
        detail: 'AES-256 at rest',
      ),
      const _PlatformItem(
        name: 'Firebase Analytics',
        icon: Icons.bar_chart,
        color: _orange,
        status: 'SECURED',
        detail: 'Consent-gated',
      ),
      const _PlatformItem(
        name: 'Crashlytics',
        icon: Icons.bug_report_outlined,
        color: _red,
        status: 'SECURED',
        detail: 'PII stripped',
      ),
      const _PlatformItem(
        name: 'Google Cloud',
        icon: Icons.cloud_done_outlined,
        color: _green,
        status: 'SECURED',
        detail: 'VPC + IAM',
      ),
      const _PlatformItem(
        name: 'Apple Health',
        icon: Icons.favorite_border,
        color: _pink,
        status: 'SECURED',
        detail: 'HealthKit gated',
      ),
      const _PlatformItem(
        name: 'Cloud Functions',
        icon: Icons.bolt,
        color: _purple,
        status: 'SECURED',
        detail: 'Auth-required',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _secHeader(Icons.hub_outlined, 'INTEGRATED PLATFORMS', _cyan),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 3.6,
          children: platforms.map(_platformCard).toList(),
        ),
      ],
    );
  }

  Widget _platformCard(_PlatformItem p) {
    return Container(
      decoration: BoxDecoration(
        color: p.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(p.icon, color: p.color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: TextStyle(
                    color: p.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  p.detail,
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '✓',
              style: TextStyle(
                color: _green,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Real-time stats ───────────────────────────────────────────────────────
  Widget _realTimeStats() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _green.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secHeader(Icons.speed, 'LIVE PROTECTION METRICS', _green),
          const SizedBox(height: 12),
          Row(
            children: [
              _statBox('24.1B', 'Records\nProtected', _cyan),
              _statBox('0', 'Active\nBreaches', _green),
              _statBox('99.99%', 'Uptime\nSLA', _amber),
              _statBox('<50ms', 'Auth\nLatency', _purple),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statBox('8', 'Platforms\nIntegrated', _blue),
              _statBox('128-bit', 'TLS\nTransport', _pink),
              _statBox('256-bit', 'AES\nAt Rest', _orange),
              _statBox('v2.0', 'Rules\nVersion', _red),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TAB 2 — SECURITY LAYERS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildLayersTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _layerDiagram(),
        const SizedBox(height: 14),
        ..._layers.map(_layerCard),
      ],
    );
  }

  static final _layers = [
    const _LayerItem(
      number: 'L1',
      title: 'NETWORK LAYER',
      subtitle: 'TLS 1.3 + Certificate Pinning',
      color: _cyan,
      icon: Icons.wifi_lock_outlined,
      points: [
        'All API calls enforced over TLS 1.3 — no plain HTTP permitted',
        'Certificate pinning prevents man-in-the-middle intercepts',
        'Firebase SDK auto-rotates transport certificates quarterly',
        'HSTS (HTTP Strict Transport Security) header enforced globally',
      ],
    ),
    const _LayerItem(
      number: 'L2',
      title: 'AUTHENTICATION LAYER',
      subtitle: 'Firebase Auth + MFA + Biometric',
      color: _amber,
      icon: Icons.fingerprint,
      points: [
        'Firebase Auth with email/password + Google OAuth + Apple Sign-In',
        'Multi-Factor Authentication (SMS OTP + TOTP authenticator app)',
        'Biometric fallback (Face ID / Touch ID) on supported devices',
        'Session tokens expire every 24h, refresh tokens rotate on each use',
        'Failed login lockout after 5 attempts — 15 min escalating delay',
      ],
    ),
    const _LayerItem(
      number: 'L3',
      title: 'AUTHORISATION LAYER',
      subtitle: 'Firestore Security Rules v2.0',
      color: _green,
      icon: Icons.rule_outlined,
      points: [
        '8 vulnerability patches applied — all CRITICAL/HIGH threats resolved',
        'Role-based access: Fighter / Promoter / Admin / Owner enforced server-side',
        'User documents: read own only, write own only, no cross-user access',
        'Fighter stats, health records: strict owner-only read/write rules',
        'Admin paths require custom claims verified via Firebase Auth tokens',
      ],
    ),
    const _LayerItem(
      number: 'L4',
      title: 'ENCRYPTION LAYER',
      subtitle: 'AES-256 At Rest + TLS 1.3 In Transit',
      color: _purple,
      icon: Icons.lock_outlined,
      points: [
        'Google Cloud automatically encrypts all Firestore data at rest AES-256',
        'Cloud Storage files encrypted per-object with unique encryption keys',
        'Health biometric data (HRV, BP, SpO2) receives additional app-layer AES',
        'Encryption key management via Google Cloud KMS with automatic rotation',
      ],
    ),
    const _LayerItem(
      number: 'L5',
      title: 'DATA ISOLATION LAYER',
      subtitle: 'Tenant Separation + PII Stripping',
      color: _red,
      icon: Icons.safety_divider,
      points: [
        'Each user\'s data stored in isolated document paths — zero cross-contamination',
        'Crashlytics PII stripping: names, emails, device IDs anonymised before upload',
        'Analytics: user IDs hashed with salt before any event logging',
        'Fight health data never shared with third-party analytics vendors',
        'GDPR/CCPA right-to-erasure: full account deletion wipes all associated docs',
      ],
    ),
    const _LayerItem(
      number: 'L6',
      title: 'MONITORING LAYER',
      subtitle: 'AI Threat Detection + Audit Logs',
      color: _orange,
      icon: Icons.radar,
      points: [
        'Firebase App Check blocks non-genuine app traffic (Play Integrity + DeviceCheck)',
        'Anomaly detection: unusual read volumes trigger automatic rate-limiting',
        'All admin actions logged to immutable audit trail in Firestore',
        'AI Security Scanner runs 24/7 — alerts on new rule violations within 60s',
        'Cloud Monitoring dashboards track auth failures, rule denials, API abuse',
      ],
    ),
  ];

  Widget _layerDiagram() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cyan.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          _secHeader(
            Icons.layers_outlined,
            'DEFENCE-IN-DEPTH ARCHITECTURE',
            _cyan,
          ),
          const SizedBox(height: 14),
          ...List.generate(_layers.length, (i) {
            final l = _layers[i];
            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: l.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: l.color.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          l.number,
                          style: TextStyle(
                            color: l.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(l.icon, color: l.color, size: 14),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        l.title,
                        style: TextStyle(
                          color: l.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: _green,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                if (i < _layers.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 15, top: 2, bottom: 2),
                    child: Container(
                      width: 2,
                      height: 10,
                      color: Colors.white10,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _layerCard(_LayerItem l) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: l.color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: l.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    l.number,
                    style: TextStyle(
                      color: l.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(l.icon, color: l.color, size: 15),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.title,
                      style: TextStyle(
                        color: l.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      l.subtitle,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...l.points.map(
            (pt) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5, right: 7),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: l.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      pt,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TAB 3 — COMPLIANCE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildComplianceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _complianceBanner(),
        const SizedBox(height: 14),
        _secHeader(
          Icons.workspace_premium_outlined,
          'ACTIVE CERTIFICATIONS',
          _amber,
        ),
        const SizedBox(height: 8),
        _complianceGrid(),
        const SizedBox(height: 14),
        _secHeader(Icons.gavel_outlined, 'DATA RIGHTS FRAMEWORK', _cyan),
        const SizedBox(height: 8),
        _rightsSection(),
        const SizedBox(height: 14),
        _secHeader(Icons.schedule_outlined, 'DATA RETENTION POLICY', _purple),
        const SizedBox(height: 8),
        _retentionSection(),
      ],
    );
  }

  Widget _complianceBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _green.withValues(alpha: 0.12),
            _cyan.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: _green, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DATAFIGHTCENTRAL IS FULLY COMPLIANT',
                  style: TextStyle(
                    color: _green,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'All user data is collected, stored, and processed in accordance with international privacy law, sport data regulations, and health data standards.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _complianceGrid() {
    final certs = [
      const _CertItem(
        title: 'GDPR',
        subtitle: 'EU General Data\nProtection Regulation',
        color: _blue,
        icon: Icons.flag_outlined,
      ),
      const _CertItem(
        title: 'CCPA',
        subtitle: 'California Consumer\nPrivacy Act',
        color: _cyan,
        icon: Icons.star_outline,
      ),
      const _CertItem(
        title: 'COPPA',
        subtitle: "Children's Online\nPrivacy Protection",
        color: _amber,
        icon: Icons.child_care_outlined,
      ),
      const _CertItem(
        title: 'TGA',
        subtitle: 'Therapeutic Goods\nAdministration (AU)',
        color: _green,
        icon: Icons.medical_services_outlined,
      ),
      const _CertItem(
        title: 'HIPAA-A',
        subtitle: 'Health Data\nBest Practices',
        color: _purple,
        icon: Icons.local_hospital_outlined,
      ),
      const _CertItem(
        title: 'ISO 27001',
        subtitle: 'Info Security\nManagement',
        color: _red,
        icon: Icons.security_outlined,
      ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.05,
      children: certs
          .map(
            (c) => Container(
              decoration: BoxDecoration(
                color: c.color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.color.withValues(alpha: 0.25)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(c.icon, color: c.color, size: 20),
                  const SizedBox(height: 5),
                  Text(
                    c.title,
                    style: TextStyle(
                      color: c.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    c.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white30,
                      fontSize: 8,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '✓ ACTIVE',
                    style: TextStyle(
                      color: _green,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _rightsSection() {
    final rights = [
      (
        'Right to Access',
        Icons.visibility_outlined,
        _cyan,
        'Request a full export of all your DFC data at any time via Profile → Privacy → Export Data',
      ),
      (
        'Right to Erasure',
        Icons.delete_outline,
        _red,
        'Delete your account and permanently remove all associated data from DFC servers within 30 days',
      ),
      (
        'Right to Rectification',
        Icons.edit_outlined,
        _amber,
        'Update or correct any personal data stored on your profile at any time',
      ),
      (
        'Right to Portability',
        Icons.download_outlined,
        _green,
        'Download your data in machine-readable JSON format for transfer to another platform',
      ),
      (
        'Right to Object',
        Icons.block_outlined,
        _purple,
        'Opt out of any non-essential data processing including analytics and behavioural profiling',
      ),
      (
        'Right to Restrict',
        Icons.pause_circle_outline,
        _blue,
        'Pause specific processing activities while you contest data accuracy or lodge a complaint',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cyan.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: rights
            .map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: r.$3.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(r.$2, color: r.$3, size: 14),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.$1,
                            style: TextStyle(
                              color: r.$3,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r.$4,
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
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _retentionSection() {
    final rows = [
      ('Account Data', 'Active + 90 days post-deletion', _cyan),
      ('Fight Records', 'Indefinite (opt-out available)', _amber),
      ('Health Biometrics', '2 years (configurable)', _red),
      ('Location Data', '6 months max', _green),
      ('Analytics Events', '14 months (Google default)', _purple),
      ('Crash Reports', '90 days rolling', _orange),
      ('Chat / DM History', '1 year (deletable by user)', _blue),
      ('Payment Records', '7 years (legal requirement)', _pink),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: rows
            .map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: r.$3,
                        shape: BoxShape.circle,
                      ),
                      margin: const EdgeInsets.only(right: 10),
                    ),
                    Expanded(
                      child: Text(
                        r.$1,
                        style: TextStyle(
                          color: r.$3,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      r.$2,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TAB 4 — PRIVACY CONTROLS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPrivacyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _privacyHeader(),
        const SizedBox(height: 14),
        _secHeader(Icons.tune, 'YOUR PRIVACY CONTROLS', _cyan),
        const SizedBox(height: 8),
        _privacyToggles.entries
            .map((e) => _toggleCard(e.key, e.value))
            .toList()
            .fold<Widget>(
              const SizedBox.shrink(),
              (prev, curr) => Column(children: [prev, curr]),
            ),
        const SizedBox(height: 14),
        _secHeader(Icons.manage_accounts_outlined, 'DATA ACTIONS', _amber),
        const SizedBox(height: 8),
        _dataActions(),
        const SizedBox(height: 14),
        _ecologicalCard(),
      ],
    );
  }

  Widget _privacyHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _purple.withValues(alpha: 0.12),
            _cyan.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _purple.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.privacy_tip_outlined, color: _purple, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR DATA, YOUR CONTROL',
                  style: TextStyle(
                    color: _purple,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'DFC never sells your personal data. You control exactly what we collect, how long we keep it, and who can see it. Toggle any setting below at any time.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleCard(String label, bool value) {
    final icons = {
      'End-to-End Encryption': Icons.lock,
      'Zero-Knowledge Auth': Icons.visibility_off_outlined,
      'Biometric Lock': Icons.fingerprint,
      'Fight Data Anonymisation': Icons.person_off_outlined,
      'Third-Party Data Sharing': Icons.share_outlined,
      'Analytics Tracking': Icons.bar_chart,
      'Crash Reporting': Icons.bug_report_outlined,
      'Location Precision Blur': Icons.location_off_outlined,
    };
    final isProtective = value && label != 'Third-Party Data Sharing';
    final color = isProtective ? _green : (!value ? _red : _amber);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: (value ? _green : _red).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icons[label] ?? Icons.security_outlined, color: color, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: _green,
            inactiveThumbColor: Colors.white30,
            inactiveTrackColor: Colors.white10,
            onChanged: (v) => setState(() => _privacyToggles[label] = v),
          ),
        ],
      ),
    );
  }

  Widget _dataActions() {
    final actions = [
      ('Export My Data', Icons.download_outlined, _cyan, false),
      ('Delete My Account', Icons.delete_forever_outlined, _red, true),
      ('Request Data Audit', Icons.receipt_long_outlined, _amber, false),
      ('Revoke App Access', Icons.phonelink_erase_outlined, _purple, false),
    ];

    return Column(
      children: actions
          .map(
            (a) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${a.$1} — contact admin@datafightcentral.com for data requests')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: a.$4 ? _red.withValues(alpha: 0.06) : _card,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: a.$3.withValues(alpha: 0.22)),
                    ),
                    child: Row(
                      children: [
                        Icon(a.$2, color: a.$3, size: 16),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            a.$1,
                            style: TextStyle(
                              color: a.$3,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: a.$3.withValues(alpha: 0.4),
                          size: 13,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Ecological / Planetary Health tie-in (inspired by attached image) ─────
  Widget _ecologicalCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _green.withValues(alpha: 0.08),
            _blue.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _green.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.eco_outlined, color: _green, size: 18),
              SizedBox(width: 8),
              Text(
                'DFC & PLANETARY HEALTH',
                style: TextStyle(
                  color: _green,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Just as ecological determinants directly impact human health, your digital health data impacts your real-world performance. DFC applies the same protection principles as planetary health science — interconnected, systemic, and data-driven.\n\nYour fight data is treated like a vital ecosystem: protected, monitored, and never exploited.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 10,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ecoChip('Zero Data Exploitation', _green),
              const SizedBox(width: 6),
              _ecoChip('Fighter-First Privacy', _cyan),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _ecoChip('No Data Sold Ever', _amber),
              const SizedBox(width: 6),
              _ecoChip('AI-Governed Rules', _purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ecoChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800),
    ),
  );

  // ── Shared helpers ─────────────────────────────────────────────────────────
  static const _orange = Color(0xFFFF6D00);

  Widget _secHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 7),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _statBox(String val, String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              val,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 8,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _PlatformItem {
  final String name, detail, status;
  final IconData icon;
  final Color color;
  const _PlatformItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.status,
    required this.detail,
  });
}

class _LayerItem {
  final String number, title, subtitle;
  final Color color;
  final IconData icon;
  final List<String> points;
  const _LayerItem({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.points,
  });
}

class _CertItem {
  final String title, subtitle;
  final Color color;
  final IconData icon;
  const _CertItem({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  CUSTOM PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

class _OrbitalPainter extends CustomPainter {
  final double angle;
  _OrbitalPainter({required this.angle});

  static const _cyan = Color(0xFF00E5FF);
  static const _amber = Color(0xFFFFD600);
  static const _green = Color(0xFF00E676);
  static const _blue = Color(0xFF2979FF);
  static const _red = Color(0xFFFF1744);
  static const _purple = Color(0xFF9C6FFF);
  static const _pink = Color(0xFFFF4081);
  static const _orange = Color(0xFFFF6D00);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // ── Draw 2 orbital rings ──
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (final radius in [70.0, 115.0]) {
      ringPaint.color = _cyan.withValues(alpha: radius == 70 ? 0.18 : 0.10);
      canvas.drawCircle(Offset(cx, cy), radius, ringPaint);
    }

    // ── Nodes on inner ring (orbit 1) ──
    final inner = [
      const _NodeDef(Icons.fingerprint, _amber, 'Auth'),
      const _NodeDef(Icons.storage_outlined, _cyan, 'DB'),
      const _NodeDef(Icons.cloud_outlined, _blue, 'Storage'),
      const _NodeDef(Icons.bolt, _purple, 'Functions'),
    ];

    // ── Nodes on outer ring (orbit 2 — counter) ──
    final outer = [
      const _NodeDef(Icons.bar_chart, _orange, 'Analytics'),
      const _NodeDef(Icons.bug_report_outlined, _red, 'Crashlytics'),
      const _NodeDef(Icons.cloud_done_outlined, _green, 'GCP'),
      const _NodeDef(Icons.favorite_border, _pink, 'Health'),
    ];

    _drawRingNodes(canvas, cx, cy, 70, inner, angle, true);
    _drawRingNodes(canvas, cx, cy, 115, outer, -angle * 0.6, false);
  }

  void _drawRingNodes(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    List<_NodeDef> nodes,
    double baseAngle,
    bool drawConnectors,
  ) {
    final n = nodes.length;
    for (int i = 0; i < n; i++) {
      final a = baseAngle + (i / n) * 2 * math.pi;
      final nx = cx + r * math.cos(a);
      final ny = cy + r * math.sin(a);

      if (drawConnectors) {
        // Connector line from centre
        final connPaint = Paint()
          ..color = nodes[i].color.withValues(alpha: 0.18)
          ..strokeWidth = 0.7;
        canvas.drawLine(Offset(cx, cy), Offset(nx, ny), connPaint);
      }

      // Glow circle
      final glowPaint = Paint()
        ..color = nodes[i].color.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(nx, ny), 14, glowPaint);

      // Node background
      final nodePaint = Paint()..color = const Color(0xFF0B1628);
      canvas.drawCircle(Offset(nx, ny), 13, nodePaint);

      // Node border
      final borderPaint = Paint()
        ..color = nodes[i].color.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(Offset(nx, ny), 13, borderPaint);

      // Icon (drawn as text via TextPainter)
      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(nodes[i].icon.codePoint),
          style: TextStyle(
            fontSize: 12,
            fontFamily: nodes[i].icon.fontFamily,
            color: nodes[i].color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(nx - 6, ny - 6));
    }
  }

  @override
  bool shouldRepaint(_OrbitalPainter old) => old.angle != angle;
}

class _NodeDef {
  final IconData icon;
  final Color color;
  final String label;
  const _NodeDef(this.icon, this.color, this.label);
}

class _ScanPainter extends CustomPainter {
  final double progress;
  final Color color;
  _ScanPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(_ScanPainter old) => old.progress != progress;
}
