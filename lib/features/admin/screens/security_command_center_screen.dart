import 'package:flutter/material.dart';
import '../../../core/constants/app_logos.dart';
import '../../../shared/services/dfc_security_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC SECURITY COMMAND CENTER
/// AI Detectives · Threat Detection · Armoury · Counter-Pipeline
///
/// Full-screen command center giving the owner real-time visibility into:
///  - WHO is attacking / probing the platform
///  - WHAT they're targeting
///  - HOW the DFC detective bots stopped them
///  - WHEN it happened
///  - Counter-trace pipeline status (ethical reverse-tracking)
/// ═══════════════════════════════════════════════════════════════════════════
class SecurityCommandCenterScreen extends StatefulWidget {
  const SecurityCommandCenterScreen({super.key});

  @override
  State<SecurityCommandCenterScreen> createState() =>
      _SecurityCommandCenterScreenState();
}

class _SecurityCommandCenterScreenState
    extends State<SecurityCommandCenterScreen>
    with TickerProviderStateMixin {
  late AnimationController _scanLineCtrl;
  late AnimationController _pulseCtrl;
  late DfcSecurityService _security;

  @override
  void initState() {
    super.initState();
    _security = DfcSecurityService();
    _scanLineCtrl = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLineCtrl.dispose();
    _pulseCtrl.dispose();
    _security.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _security,
      builder: (context, _) {
        final snap = _security.snapshot;
        return Scaffold(
          backgroundColor: const Color(0xFF030810),
          appBar: AppBar(
            backgroundColor: const Color(0xFF060C18),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                Image.asset(
                  AppLogos.icon,
                  width: 28,
                  height: 28,
                  errorBuilder: (_, e, s) => const Icon(
                    Icons.shield,
                    color: Color(0xFF00E5FF),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'SECURITY COMMAND CENTER',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            actions: [
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, child) {
                  final alpha = 0.5 + _pulseCtrl.value * 0.5;
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF00E676).withValues(alpha: 0.15),
                      border: Border.all(
                        color: Color.fromRGBO(0, 230, 118, alpha),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.fromRGBO(0, 230, 118, alpha),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          snap?.overallStatus ?? 'SCANNING',
                          style: const TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              // Scan line animation background
              AnimatedBuilder(
                animation: _scanLineCtrl,
                builder: (context, _) => CustomPaint(
                  painter: _ScanLinePainter(progress: _scanLineCtrl.value),
                  size: Size.infinite,
                ),
              ),
              // Content
              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(14),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildSystemOverview(snap),
                          const SizedBox(height: 16),
                          _buildCounterPipelinePanel(),
                          const SizedBox(height: 16),
                          _buildSectionHeader(
                            'AI DETECTIVES — ACTIVE ROSTER',
                            Icons.smart_toy,
                          ),
                          const SizedBox(height: 8),
                          ..._security.detectives.map(
                            (d) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildDetectiveCard(d),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSectionHeader(
                            'THREAT LOG — LAST 24H',
                            Icons.warning_amber,
                          ),
                          const SizedBox(height: 8),
                          ..._security.threats.map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildThreatCard(t),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSectionHeader('ARMOURY', Icons.security),
                          const SizedBox(height: 8),
                          _buildArmouryGrid(),
                          const SizedBox(height: 100),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── SYSTEM OVERVIEW PANEL ──────────────────────────────────────────────
  Widget _buildSystemOverview(SecuritySnapshot? snap) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1628), Color(0xFF0D1B2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield, color: Color(0xFF00E5FF), size: 20),
              const SizedBox(width: 8),
              const Text(
                'SYSTEM INTEGRITY',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                '${((snap?.systemIntegrity ?? 0.997) * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Integrity bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: snap?.systemIntegrity ?? 0.997,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF00E676)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statPill(
                'THREATS TODAY',
                '${snap?.totalThreatsToday ?? 0}',
                const Color(0xFFFF6D00),
              ),
              _statPill(
                'ACTIVE',
                '${snap?.activeThreats ?? 0}',
                const Color(0xFFFF1744),
              ),
              _statPill(
                'CONTAINED',
                '${snap?.containedThreats ?? 0}',
                const Color(0xFFFFD600),
              ),
              _statPill(
                'NEUTRALIZED',
                '${snap?.neutralizedThreats ?? 0}',
                const Color(0xFF00E676),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detectives active: ${snap?.detectivesActive ?? 0}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
              Text(
                'Counter-pipelines: ${snap?.counterPipelinesRunning ?? 0}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
              Text(
                'Last scan: ${_formatTime(snap?.lastScanAt)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // ── COUNTER-PIPELINE PANEL ─────────────────────────────────────────────
  Widget _buildCounterPipelinePanel() {
    final active = _security.counterPipelineActive;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: active
              ? [const Color(0xFF1A0A28), const Color(0xFF0D0A1B)]
              : [const Color(0xFF0A1216), const Color(0xFF0A0E18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: active
              ? const Color(0xFFFF00FF).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_horiz,
                color: active ? const Color(0xFFFF00FF) : Colors.white54,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'COUNTER-PIPELINE — ETHICAL TRACEBACK',
                style: TextStyle(
                  color: active ? const Color(0xFFFF00FF) : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            active
                ? 'Pipeline ACTIVE — DFC is running ethical reverse-trace on detected threat sources. '
                      'Attackers have been notified they were detected. Intel is being collected '
                      'for forensic analysis and law enforcement reporting.'
                : 'When activated, DFC deploys ethical reverse-tracking to identify threat origins, '
                      'notify attackers they\'ve been detected, and collect forensic evidence. '
                      'All operations follow responsible disclosure principles.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if (active) ...[
            _pipelineStep(
              'DETECT',
              'Threat source identified and fingerprinted',
              true,
            ),
            _pipelineStep(
              'TRACE',
              'Reverse-path analysis to origin infrastructure',
              true,
            ),
            _pipelineStep(
              'NOTIFY',
              'Attacker served detection notice via their own channel',
              true,
            ),
            _pipelineStep(
              'COLLECT',
              'Forensic evidence preserved for legal pipeline',
              true,
            ),
            _pipelineStep(
              'REPORT',
              'Automated report generated for audit & law enforcement',
              false,
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (active) {
                  _security.deactivateCounterPipeline();
                } else {
                  _security.activateCounterPipeline();
                }
              },
              icon: Icon(active ? Icons.pause : Icons.play_arrow, size: 18),
              label: Text(
                active ? 'PAUSE COUNTER-PIPELINE' : 'ACTIVATE COUNTER-PIPELINE',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  fontSize: 12,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: active
                    ? const Color(0xFFFF1744).withValues(alpha: 0.2)
                    : const Color(0xFFFF00FF).withValues(alpha: 0.2),
                foregroundColor: active
                    ? const Color(0xFFFF1744)
                    : const Color(0xFFFF00FF),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: active
                        ? const Color(0xFFFF1744).withValues(alpha: 0.4)
                        : const Color(0xFFFF00FF).withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pipelineStep(String stage, String desc, bool complete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            complete ? Icons.check_circle : Icons.radio_button_unchecked,
            color: complete ? const Color(0xFF00E676) : Colors.white24,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '$stage — ',
            style: TextStyle(
              color: complete ? const Color(0xFF00E676) : Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(
                color: Colors.white.withValues(alpha: complete ? 0.6 : 0.3),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── DETECTIVE CARD ─────────────────────────────────────────────────────
  Widget _buildDetectiveCard(SecurityDetective det) {
    final statusColor = _detectiveStatusColor(det.status);
    final statusLabel = det.status.name.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF0A1216),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      statusColor.withValues(alpha: 0.3),
                      statusColor.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Icon(Icons.smart_toy, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      det.name,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      det.specialty,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: statusColor.withValues(alpha: 0.15),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            det.currentAssignment,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _detStat(
                'DETECTED',
                '${det.threatsDetected}',
                const Color(0xFFFFD600),
              ),
              const SizedBox(width: 16),
              _detStat(
                'NEUTRALIZED',
                '${det.threatsNeutralized}',
                const Color(0xFF00E676),
              ),
              const SizedBox(width: 16),
              _detStat(
                'EFFICIENCY',
                '${(det.efficiency * 100).toStringAsFixed(1)}%',
                const Color(0xFF00E5FF),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'ARMOURY: ',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              ...det.armoury.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: const Color(0xFF9C6FFF).withValues(alpha: 0.15),
                      border: Border.all(
                        color: const Color(0xFF9C6FFF).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      _armsLabel(a),
                      style: const TextStyle(
                        color: Color(0xFF9C6FFF),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ── THREAT CARD ────────────────────────────────────────────────────────
  Widget _buildThreatCard(ThreatEvent threat) {
    final sevColor = _severityColor(threat.severity);
    final statusColor = _threatStatusColor(threat.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF0A0E14),
        border: Border.all(color: sevColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: sevColor.withValues(alpha: 0.2),
                ),
                child: Text(
                  threat.severity.name.toUpperCase(),
                  style: TextStyle(
                    color: sevColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: statusColor.withValues(alpha: 0.2),
                ),
                child: Text(
                  threat.status.name.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                threat.id,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            threat.title,
            style: TextStyle(
              color: sevColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            threat.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          // Intel grid
          _threatInfoRow(
            Icons.language,
            'Source',
            '${threat.sourceIp} — ${threat.sourceRegion}',
          ),
          _threatInfoRow(Icons.gps_fixed, 'Target', threat.targetAsset),
          _threatInfoRow(Icons.bug_report, 'Vector', threat.attackVector),
          _threatInfoRow(Icons.smart_toy, 'Detected by', threat.detectedBy),
          _threatInfoRow(
            Icons.speed,
            'Confidence',
            '${(threat.confidenceScore * 100).toStringAsFixed(0)}%',
          ),
          _threatInfoRow(
            Icons.access_time,
            'When',
            _formatTimeFull(threat.detectedAt),
          ),
          const SizedBox(height: 8),
          // Actions applied
          Text(
            'ACTIONS APPLIED:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: threat.actionsApplied
                .map(
                  (a) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: const Color(0xFF00E676).withValues(alpha: 0.1),
                      border: Border.all(
                        color: const Color(0xFF00E676).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '✓ $a',
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _threatInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white24, size: 14),
          const SizedBox(width: 6),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ARMOURY GRID ───────────────────────────────────────────────────────
  Widget _buildArmouryGrid() {
    final arms = [
      const _ArmouryItem(
        'FIREWALL',
        Icons.local_fire_department,
        Color(0xFFFF6D00),
        'Blocks malicious IPs, filters known attack signatures, prevents unauthorized access at network edge.',
      ),
      const _ArmouryItem(
        'RATE LIMITER',
        Icons.speed,
        Color(0xFFFFD600),
        'Throttles requests per user/IP. Stops brute force, credential stuffing, and API abuse in real-time.',
      ),
      const _ArmouryItem(
        'IP BLOCK',
        Icons.block,
        Color(0xFFFF1744),
        'Instantly blacklists individual IPs or CIDR ranges. Auto-expires after 24h or permanent by admin decision.',
      ),
      const _ArmouryItem(
        'SESSION KILL',
        Icons.power_settings_new,
        Color(0xFFFF00FF),
        'Force-terminates active sessions of compromised accounts. Invalidates all tokens immediately.',
      ),
      const _ArmouryItem(
        'HONEYPOT',
        Icons.catching_pokemon,
        Color(0xFF00E676),
        'Decoy endpoints that look like real data. When accessed, automatically flags attacker and collects intel.',
      ),
      const _ArmouryItem(
        'TRACEBACK',
        Icons.swap_horiz,
        Color(0xFF00E5FF),
        'Ethical reverse-trace that identifies attack origin infrastructure. Reports to ISP and law enforcement.',
      ),
      const _ArmouryItem(
        'OWNER ALERT',
        Icons.notifications_active,
        Color(0xFF9C6FFF),
        'Instant push notification to owner with threat details, confidence score, and recommended action.',
      ),
      const _ArmouryItem(
        'QUARANTINE',
        Icons.coronavirus,
        Color(0xFFFF6D00),
        'Isolates suspicious files, payloads, and uploads in sandboxed environment for analysis before destruction.',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.2,
      children: arms
          .map(
            (arm) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFF0A1216),
                border: Border.all(color: arm.color.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(arm.icon, color: arm.color, size: 22),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          arm.name,
                          style: TextStyle(
                            color: arm.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      arm.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 10,
                        height: 1.35,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ── SECTION HEADER ─────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00E5FF), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────
  Color _severityColor(ThreatSeverity s) => switch (s) {
    ThreatSeverity.critical => const Color(0xFFFF1744),
    ThreatSeverity.high => const Color(0xFFFF6D00),
    ThreatSeverity.medium => const Color(0xFFFFD600),
    ThreatSeverity.low => const Color(0xFF00E676),
    ThreatSeverity.info => const Color(0xFF00E5FF),
  };

  Color _threatStatusColor(ThreatStatus s) => switch (s) {
    ThreatStatus.active => const Color(0xFFFF1744),
    ThreatStatus.contained => const Color(0xFFFFD600),
    ThreatStatus.neutralized => const Color(0xFF00E676),
    ThreatStatus.monitoring => const Color(0xFF00E5FF),
    ThreatStatus.investigating => const Color(0xFFFF6D00),
  };

  Color _detectiveStatusColor(DetectiveStatus s) => switch (s) {
    DetectiveStatus.patrolling => const Color(0xFF00E5FF),
    DetectiveStatus.investigating => const Color(0xFFFFD600),
    DetectiveStatus.engaging => const Color(0xFFFF6D00),
    DetectiveStatus.reporting => const Color(0xFF9C6FFF),
    DetectiveStatus.standby => Colors.white38,
  };

  String _armsLabel(ArmsType a) => switch (a) {
    ArmsType.firewall => 'FIREWALL',
    ArmsType.rateLimit => 'RATE LIMIT',
    ArmsType.ipBlock => 'IP BLOCK',
    ArmsType.sessionKill => 'SESSION KILL',
    ArmsType.honeypot => 'HONEYPOT',
    ArmsType.traceBack => 'TRACEBACK',
    ArmsType.alertOwner => 'ALERT OWNER',
  };

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--';
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
  }

  String _formatTimeFull(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours}h ${d.inMinutes % 60}m ago';
    return '${d.inDays}d ago';
  }
}

// ── DATA CLASS ───────────────────────────────────────────────────────────
class _ArmouryItem {
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  const _ArmouryItem(this.name, this.icon, this.color, this.description);
}

// ── SCAN LINE PAINTER ────────────────────────────────────────────────────
class _ScanLinePainter extends CustomPainter {
  final double progress;
  _ScanLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final y = size.height * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF00E5FF).withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, y - 30, size.width, 60));
    canvas.drawRect(Rect.fromLTWH(0, y - 30, size.width, 60), paint);

    // Thin scan line
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.15)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) => old.progress != progress;
}
