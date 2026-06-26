import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/dfc_health_engine.dart';
import '../../../shared/services/platform_health_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  ██████╗ ███████╗ ██████╗    ██╗  ██╗███████╗ █████╗ ██╗  ████████╗██╗  ██╗
//  ██╔══██╗██╔════╝██╔════╝    ██║  ██║██╔════╝██╔══██╗██║  ╚══██╔══╝██║  ██║
//  ██║  ██║█████╗  ██║         ███████║█████╗  ███████║██║     ██║   ███████║
//  ██║  ██║██╔══╝  ██║         ██╔══██║██╔══╝  ██╔══██║██║     ██║   ██╔══██║
//  ██████╔╝██║     ╚██████╗    ██║  ██║███████╗██║  ██║███████╗██║   ██║  ██║
//  ╚═════╝ ╚═╝      ╚═════╝    ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝   ╚═╝  ╚═╝
// ═══════════════════════════════════════════════════════════════════════════════
//
//  DFC ECOSYSTEM HEALTH DASHBOARD
//  Real-time monitoring of every subsystem, engine, bot & service.
//  Pulse heartbeat · Self-healing log · Error budget · Uptime counter
//
//  "The app doesn't stop. Ever." — DFC Founder
// ═══════════════════════════════════════════════════════════════════════════════

class SystemHealthPage extends StatefulWidget {
  const SystemHealthPage({super.key});

  @override
  State<SystemHealthPage> createState() => _SystemHealthPageState();
}

class _SystemHealthPageState extends State<SystemHealthPage>
    with SingleTickerProviderStateMixin {
  final DfcHealthEngine _engine = DfcHealthEngine();
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  Timer? _refreshTimer;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Boot the engine if not already running
    if (!_engine.isRunning) {
      _engine.boot();
    }

    // Listen for changes
    _engine.addListener(_onEngineUpdate);

    // Refresh UI every 5s for uptime counter
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  void _onEngineUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _refreshTimer?.cancel();
    _engine.removeListener(_onEngineUpdate);
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Color _statusColor(HealthStatus status) => switch (status) {
    HealthStatus.optimal => DesignTokens.neonGreen,
    HealthStatus.degraded => DesignTokens.neonAmber,
    HealthStatus.critical => DesignTokens.neonRed,
    HealthStatus.offline => Colors.grey,
    HealthStatus.unknown => Colors.white38,
  };

  IconData _statusIcon(HealthStatus status) => switch (status) {
    HealthStatus.optimal => Icons.check_circle,
    HealthStatus.degraded => Icons.warning_amber_rounded,
    HealthStatus.critical => Icons.error,
    HealthStatus.offline => Icons.cloud_off,
    HealthStatus.unknown => Icons.help_outline,
  };

  String _statusLabel(HealthStatus status) => switch (status) {
    HealthStatus.optimal => 'OPTIMAL',
    HealthStatus.degraded => 'DEGRADED',
    HealthStatus.critical => 'CRITICAL',
    HealthStatus.offline => 'OFFLINE',
    HealthStatus.unknown => 'UNKNOWN',
  };

  String _formatUptime(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (days > 0) return '${days}d ${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
    return '${minutes}m ${seconds}s';
  }

  List<String> get _categories {
    final cats = _engine.subsystems.values
        .map((s) => s.category)
        .toSet()
        .toList();
    cats.sort();
    return ['All', ...cats];
  }

  List<SubsystemHealth> get _filteredSubsystems {
    final all = _engine.subsystems.values.toList();
    if (_selectedCategory == 'All') return all;
    return all.where((s) => s.category == _selectedCategory).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final summary = _engine.summary;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: _buildAppBar(summary),
      body: RefreshIndicator(
        onRefresh: _engine.forceScan,
        color: DesignTokens.neonCyan,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Overall Status Banner ────────────────────────────────
            _buildOverallBanner(summary),
            const SizedBox(height: 16),

            // ── Stats Row ────────────────────────────────────────────
            if (isWide)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'UPTIME',
                      _formatUptime(summary.uptime),
                      Icons.timer,
                      DesignTokens.neonCyan,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'SUBSYSTEMS',
                      '${summary.totalSubsystems}',
                      Icons.hub,
                      DesignTokens.neonMagenta,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'SELF-HEALS',
                      '${summary.totalSelfHeals}',
                      Icons.healing,
                      DesignTokens.neonGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'ERR / 5min',
                      '${summary.errorsLast5Min}',
                      Icons.bug_report,
                      summary.errorsLast5Min > 5
                          ? DesignTokens.neonRed
                          : DesignTokens.neonAmber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'AVG MS',
                      summary.avgResponseTimeMs.toStringAsFixed(0),
                      Icons.speed,
                      DesignTokens.neonBlue,
                    ),
                  ),
                ],
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatCard(
                    'UPTIME',
                    _formatUptime(summary.uptime),
                    Icons.timer,
                    DesignTokens.neonCyan,
                  ),
                  _buildStatCard(
                    'SUBSYSTEMS',
                    '${summary.totalSubsystems}',
                    Icons.hub,
                    DesignTokens.neonMagenta,
                  ),
                  _buildStatCard(
                    'SELF-HEALS',
                    '${summary.totalSelfHeals}',
                    Icons.healing,
                    DesignTokens.neonGreen,
                  ),
                  _buildStatCard(
                    'ERR / 5min',
                    '${summary.errorsLast5Min}',
                    Icons.bug_report,
                    summary.errorsLast5Min > 5
                        ? DesignTokens.neonRed
                        : DesignTokens.neonAmber,
                  ),
                  _buildStatCard(
                    'AVG MS',
                    summary.avgResponseTimeMs.toStringAsFixed(0),
                    Icons.speed,
                    DesignTokens.neonBlue,
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // ── Heartbeat Pulse ──────────────────────────────────────
            _buildHeartbeatPulse(summary),
            const SizedBox(height: 20),

            // ── Category Filter Chips ────────────────────────────────
            _buildCategoryChips(),
            const SizedBox(height: 16),

            // ── Subsystem Grid ───────────────────────────────────────
            _buildSubsystemGrid(isWide),
            const SizedBox(height: 24),

            // ── Self-Healing Event Log ───────────────────────────────
            _buildEventLog(),
            const SizedBox(height: 24),

            // ── Platform Health Service Circuit Breaker ──────────────
            _buildCircuitBreakerPanel(),
            const SizedBox(height: 24),

            // ── Quick Actions ────────────────────────────────────────
            _buildQuickActions(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar(EcosystemHealthSummary summary) {
    return AppBar(
      backgroundColor: DesignTokens.bgSecondary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, _) => Opacity(
              opacity: _pulseAnim.value,
              child: Icon(
                summary.overallStatus == HealthStatus.optimal
                    ? Icons.favorite
                    : Icons.heart_broken,
                color: _statusColor(summary.overallStatus),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'DFC ECOSYSTEM HEALTH',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        if (_engine.isScanning)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: DesignTokens.neonCyan,
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor(summary.overallStatus).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _statusColor(summary.overallStatus).withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            _statusLabel(summary.overallStatus),
            style: TextStyle(
              color: _statusColor(summary.overallStatus),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OVERALL BANNER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildOverallBanner(EcosystemHealthSummary summary) {
    final color = _statusColor(summary.overallStatus);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.15), DesignTokens.bgCard],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, _) => Transform.scale(
                  scale: 0.9 + (_pulseAnim.value * 0.2),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withValues(alpha: 0.6),
                          color.withValues(alpha: 0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(
                            alpha: 0.4 * _pulseAnim.value,
                          ),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      summary.overallStatus == HealthStatus.optimal
                          ? Icons.favorite
                          : summary.overallStatus == HealthStatus.degraded
                          ? Icons.warning_amber_rounded
                          : Icons.heart_broken,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.overallStatus == HealthStatus.optimal
                          ? 'ALL SYSTEMS NOMINAL'
                          : summary.overallStatus == HealthStatus.degraded
                          ? 'PARTIAL DEGRADATION'
                          : 'SYSTEMS CRITICAL',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.optimalCount} optimal · ${summary.degradedCount} degraded · ${summary.criticalCount} critical · ${summary.offlineCount} offline',
                      style: const TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Uptime bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: summary.uptimePercent / 100,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Uptime: ${summary.uptimePercent.toStringAsFixed(2)}%',
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: 12,
                ),
              ),
              Text(
                'Running: ${_formatUptime(summary.uptime)}',
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STAT CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEARTBEAT PULSE VISUALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeartbeatPulse(EcosystemHealthSummary summary) {
    final color = _statusColor(summary.overallStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, _) => Opacity(
                  opacity: _pulseAnim.value,
                  child: Icon(Icons.monitor_heart, color: color, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'HEARTBEAT PULSE',
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, _) => Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: _pulseAnim.value),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5 * _pulseAnim.value),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _engine.isScanning ? 'SCANNING...' : 'LIVE',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Pulse wave visualization (simplified ECG-like)
          SizedBox(
            height: 40,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, _) => CustomPaint(
                size: const Size(double.infinity, 40),
                painter: _PulseWavePainter(
                  color: color,
                  phase: _pulseAnim.value,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cycle: 30s',
                style: TextStyle(color: DesignTokens.textMuted, fontSize: 11),
              ),
              Text(
                'Last scan: ${_timeSince(summary.lastFullScan)}',
                style: const TextStyle(color: DesignTokens.textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeSince(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 5) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CATEGORY FILTER CHIPS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          final count = cat == 'All'
              ? _engine.subsystems.length
              : _engine.subsystems.values
                    .where((s) => s.category == cat)
                    .length;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                '$cat ($count)',
                style: TextStyle(
                  color: isSelected ? Colors.black : DesignTokens.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategory = cat),
              backgroundColor: DesignTokens.bgCard,
              selectedColor: DesignTokens.neonCyan,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? DesignTokens.neonCyan
                      : DesignTokens.borderSubtle,
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBSYSTEM GRID
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSubsystemGrid(bool isWide) {
    final filtered = _filteredSubsystems;
    final crossAxisCount = isWide ? 4 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isWide ? 2.2 : 1.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final sub = filtered[index];
        return _buildSubsystemTile(sub);
      },
    );
  }

  Widget _buildSubsystemTile(SubsystemHealth sub) {
    final color = _statusColor(sub.status);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(sub.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  sub.name,
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(_statusIcon(sub.status), color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                _statusLabel(sub.status),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            sub.statusMessage,
            style: const TextStyle(color: DesignTokens.textMuted, fontSize: 10),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${sub.responseTimeMs}ms',
                style: TextStyle(
                  color: sub.responseTimeMs > 200
                      ? DesignTokens.neonAmber
                      : DesignTokens.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (sub.selfHealAttempted)
                const Icon(
                  Icons.healing,
                  color: DesignTokens.neonGreen,
                  size: 12,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EVENT LOG
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEventLog() {
    final events = _engine.eventLog.take(20).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.history,
              color: DesignTokens.neonMagenta,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'HEALTH EVENT LOG',
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            Text(
              '${events.length} events',
              style: const TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: DesignTokens.neonGreen,
                  size: 40,
                ),
                SizedBox(height: 8),
                Text(
                  'No health events yet — all systems nominal',
                  style: TextStyle(color: DesignTokens.textMuted, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ...events.map((event) {
            final color = _statusColor(event.toStatus);
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: DesignTokens.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: event.wasAutoHealed
                      ? DesignTokens.neonGreen.withValues(alpha: 0.3)
                      : color.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    event.wasAutoHealed
                        ? Icons.healing
                        : _statusIcon(event.toStatus),
                    color: event.wasAutoHealed ? DesignTokens.neonGreen : color,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.subsystem.toUpperCase(),
                          style: const TextStyle(
                            color: DesignTokens.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          event.message,
                          style: const TextStyle(
                            color: DesignTokens.textMuted,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _timeSince(event.timestamp),
                    style: const TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CIRCUIT BREAKER PANEL (PlatformHealthService)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCircuitBreakerPanel() {
    final phs = PlatformHealthService.instance;
    final status = phs.statusLabel;
    final events = phs.recentEventSummaries;
    final isClosed = status == 'CLOSED';
    final isOpen = status == 'OPEN';
    final statusColor = isClosed
        ? DesignTokens.neonGreen
        : isOpen
        ? DesignTokens.neonRed
        : DesignTokens.neonAmber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.security, color: statusColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'CIRCUIT BREAKER',
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.verified_user,
                  color: DesignTokens.neonGreen,
                  size: 36,
                ),
                SizedBox(height: 8),
                Text(
                  'Circuit breaker closed — all services operational',
                  style: TextStyle(color: DesignTokens.textMuted, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ...events
              .take(15)
              .map(
                (event) => Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: DesignTokens.neonRed.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '[${event['severity']}] ${event['tag']}: ${event['message']}',
                    style: const TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  // QUICK ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.flash_on, color: DesignTokens.neonAmber, size: 20),
            SizedBox(width: 8),
            Text(
              'QUICK ACTIONS',
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _actionButton(
                icon: Icons.refresh,
                label: 'Force Scan',
                color: DesignTokens.neonCyan,
                onTap: () async {
                  await _engine.forceScan();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🏥 Full health scan complete'),
                        backgroundColor: Color(0xFF0A1628),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionButton(
                icon: Icons.healing,
                label: 'Self-Heal All',
                color: DesignTokens.neonGreen,
                onTap: () async {
                  await _engine.forceScan();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✅ Self-heal complete — ${_engine.totalSelfHeals} total heals',
                        ),
                        backgroundColor: const Color(0xFF0A1628),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionButton(
                icon: Icons.lock_open,
                label: 'Lockdown',
                color: DesignTokens.neonRed,
                onTap: () => context.push('/admin/emergency-lockdown'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PULSE WAVE PAINTER — ECG-style heartbeat visualization
// ═══════════════════════════════════════════════════════════════════════════════

class _PulseWavePainter extends CustomPainter {
  final Color color;
  final double phase;

  _PulseWavePainter({required this.color, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final midY = size.height / 2;
    final segmentWidth = size.width / 8;

    // Flat → spike → flat → mini spike → flat pattern (ECG-like)
    path.moveTo(0, midY);

    // Segment 1: flat baseline
    path.lineTo(segmentWidth * 1, midY);

    // Segment 2: small P wave
    path.quadraticBezierTo(
      segmentWidth * 1.5,
      midY - 6 * phase,
      segmentWidth * 2,
      midY,
    );

    // Segment 3: flat
    path.lineTo(segmentWidth * 2.5, midY);

    // Segment 4: QRS complex (big spike)
    path.lineTo(segmentWidth * 2.8, midY + 4);
    path.lineTo(segmentWidth * 3.2, midY - size.height * 0.6 * phase);
    path.lineTo(segmentWidth * 3.5, midY + size.height * 0.2 * phase);
    path.lineTo(segmentWidth * 3.8, midY);

    // Segment 5: flat
    path.lineTo(segmentWidth * 4.2, midY);

    // Segment 6: T wave
    path.quadraticBezierTo(
      segmentWidth * 4.8,
      midY - 10 * phase,
      segmentWidth * 5.5,
      midY,
    );

    // Segment 7: flat to end
    path.lineTo(size.width, midY);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    // Draw baseline
    final basePaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), basePaint);
  }

  @override
  bool shouldRepaint(covariant _PulseWavePainter old) =>
      old.phase != phase || old.color != color;
}
