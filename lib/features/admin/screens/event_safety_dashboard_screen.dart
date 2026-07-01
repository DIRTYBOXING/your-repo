import 'package:flutter/material.dart';
import '../../../shared/services/fighter_safety_system_service.dart';
import '../../../shared/services/fighter_health_passport_service.dart';
import '../../../shared/services/ai_referee_assistant_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// EVENT SAFETY DASHBOARD — Real-time fighter safety during live events.
/// Connects: FighterSafetySystem + HealthPassport + AI Referee
/// ═══════════════════════════════════════════════════════════════════════════

const _kBg = Color(0xFF060A14);
const _kPanel = Color(0xFF0C1226);
const _kBorder = Color(0xFF1A2744);
const _kRed = Color(0xFFFF1744);
const _kGreen = Color(0xFF00E676);
const _kOrange = Color(0xFFFF9100);
const _kCyan = Color(0xFF00E5FF);

class EventSafetyDashboardScreen extends StatefulWidget {
  final String eventId;
  const EventSafetyDashboardScreen({super.key, required this.eventId});

  @override
  State<EventSafetyDashboardScreen> createState() =>
      _EventSafetyDashboardScreenState();
}

class _EventSafetyDashboardScreenState
    extends State<EventSafetyDashboardScreen> {
  late final FighterSafetySystemService _safety;
  late final FighterHealthPassportService _health;
  late final AiRefereeAssistantService _referee;

  @override
  void initState() {
    super.initState();
    _safety = FighterSafetySystemService();
    _health = FighterHealthPassportService();
    _referee = AiRefereeAssistantService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('EVENT SAFETY'),
        backgroundColor: _kBg,
        foregroundColor: _kRed,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLiveStatus(),
          const SizedBox(height: 16),
          _buildSafetyAlerts(),
          const SizedBox(height: 16),
          _buildHealthPassportPanel(),
          const SizedBox(height: 16),
          _buildRefereePanel(),
          const SizedBox(height: 16),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildLiveStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kRed.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _kGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: _kGreen.withValues(alpha: 0.5), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'SAFETY MONITORING ACTIVE',
            style: TextStyle(
              color: _kGreen,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          _statBadge('Incidents', '${_safety.totalIncidentsRecorded}', _kRed),
          const SizedBox(width: 12),
          _statBadge('Blocked', '${_safety.bookingsBlocked}', _kOrange),
        ],
      ),
    );
  }

  Widget _buildSafetyAlerts() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACTIVE SAFETY ALERTS',
            style: TextStyle(
              color: _kRed,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _alertRow(Icons.warning, 'Weight cut monitoring', 'Active', _kOrange),
          _alertRow(
            Icons.psychology,
            'Concussion protocol',
            'Standby',
            _kGreen,
          ),
          _alertRow(
            Icons.fitness_center,
            'Overtraining detection',
            'Active',
            _kOrange,
          ),
          _alertRow(Icons.timer, 'Fight frequency check', 'Active', _kCyan),
        ],
      ),
    );
  }

  Widget _buildHealthPassportPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_services, color: _kGreen, size: 20),
              const SizedBox(width: 8),
              const Text(
                'HEALTH PASSPORTS',
                style: TextStyle(
                  color: _kGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              _statBadge(
                'Total',
                '${_health.totalConcussionsTracked}',
                _kGreen,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'All fighters must have valid health passports before competing. '
            'Medical clearance, concussion history, and weight logs are tracked.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRefereePanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility, color: _kCyan, size: 20),
              const SizedBox(width: 8),
              const Text(
                'AI REFEREE ASSISTANT',
                style: TextStyle(
                  color: _kCyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              _statBadge('Alerts', '${_referee.totalAlertsIssued}', _kCyan),
            ],
          ),
          const SizedBox(height: 12),
          _alertRow(Icons.sports_mma, 'Foul detection', 'Online', _kGreen),
          _alertRow(
            Icons.monitor_heart,
            'Distress detection',
            'Online',
            _kGreen,
          ),
          _alertRow(Icons.sports, 'Knockdown tracking', 'Online', _kGreen),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _quickAction('Emergency\nStop', Icons.pan_tool, _kRed, () {}),
        const SizedBox(width: 12),
        _quickAction('Medical\nTeam', Icons.local_hospital, _kGreen, () {}),
        const SizedBox(width: 12),
        _quickAction('Review\nFighter', Icons.person_search, _kCyan, () {}),
        const SizedBox(width: 12),
        _quickAction('Export\nReport', Icons.file_download, _kOrange, () {}),
      ],
    );
  }

  Widget _alertRow(IconData icon, String label, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _quickAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
