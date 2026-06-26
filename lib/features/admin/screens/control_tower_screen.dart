import 'package:flutter/material.dart';
import '../../../shared/services/federation_management_service.dart';
import '../../../shared/services/gym_management_service.dart';
import '../../../shared/services/amateur_league_service.dart';
import '../../../shared/services/talent_scouting_service.dart';
import '../../../shared/services/fighter_safety_system_service.dart';
import '../../../shared/services/ai_media_director_service.dart';
import '../../../shared/services/ai_event_director_service.dart';
import '../../../shared/services/global_fight_discovery_service.dart';
import '../../../shared/services/realtime_scoring_service.dart';
import '../../../shared/services/ai_referee_assistant_service.dart';
import '../../../shared/services/fight_simulation_engine.dart';
import '../../../shared/services/fighter_career_engine_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC CONTROL TOWER — Master Admin Console
/// Unified command surface for all Apex++ engines + platform operations.
/// ═══════════════════════════════════════════════════════════════════════════

const _kBg = Color(0xFF060A14);
const _kPanel = Color(0xFF0C1226);
const _kBorder = Color(0xFF1A2744);
const _kGold = Color(0xFFFFD740);
const _kCyan = Color(0xFF00E5FF);
const _kMagenta = Color(0xFFE040FB);
const _kGreen = Color(0xFF00E676);
const _kOrange = Color(0xFFFF9100);
const _kRed = Color(0xFFFF1744);

class ControlTowerScreen extends StatefulWidget {
  const ControlTowerScreen({super.key});

  @override
  State<ControlTowerScreen> createState() => _ControlTowerScreenState();
}

class _ControlTowerScreenState extends State<ControlTowerScreen> {
  late final FederationManagementService _federations;
  late final GymManagementService _gyms;
  late final AmateurLeagueService _amateurs;
  late final TalentScoutingService _scouting;
  late final FighterSafetySystemService _safety;
  late final AiMediaDirectorService _media;
  late final AiEventDirectorService _eventDir;
  late final GlobalFightDiscoveryService _discovery;
  late final RealtimeScoringService _scoring;
  late final AiRefereeAssistantService _referee;
  late final FightSimulationEngine _simulator;
  late final FighterCareerEngineService _career;

  @override
  void initState() {
    super.initState();
    _federations = FederationManagementService();
    _gyms = GymManagementService();
    _amateurs = AmateurLeagueService();
    _scouting = TalentScoutingService();
    _safety = FighterSafetySystemService();
    _media = AiMediaDirectorService();
    _eventDir = AiEventDirectorService();
    _discovery = GlobalFightDiscoveryService();
    _scoring = RealtimeScoringService();
    _referee = AiRefereeAssistantService();
    _simulator = FightSimulationEngine();
    _career = FighterCareerEngineService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('DFC CONTROL TOWER'),
        backgroundColor: _kBg,
        foregroundColor: _kGold,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _kCyan),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusBar(),
          const SizedBox(height: 20),
          _sectionHeader('PLATFORM ENGINES', _kGold),
          const SizedBox(height: 12),
          _buildEngineGrid(),
          const SizedBox(height: 24),
          _sectionHeader('SAFETY & GOVERNANCE', _kRed),
          const SizedBox(height: 12),
          _buildSafetyPanel(),
          const SizedBox(height: 24),
          _sectionHeader('AI TOOLS', _kMagenta),
          const SizedBox(height: 12),
          _buildAIToolsGrid(),
          const SizedBox(height: 24),
          _sectionHeader('GLOBAL NETWORK', _kCyan),
          const SizedBox(height: 12),
          _buildGlobalPanel(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          _statusBadge(
            'Federations',
            '${_federations.federations.length}',
            _kGold,
          ),
          _statusBadge(
            'Gyms',
            _gyms.initialized ? "Active" : "Offline",
            _kCyan,
          ),
          _statusBadge(
            'Amateur Leagues',
            '${_amateurs.activeTournaments.length}',
            _kGreen,
          ),
          _statusBadge(
            'Safety Incidents',
            '${_safety.totalIncidentsRecorded}',
            _kRed,
          ),
          _statusBadge(
            'Global Fighters',
            '${_discovery.totalFighters}',
            _kMagenta,
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        color: color,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildEngineGrid() {
    final modules = <_ModuleCard>[
      _ModuleCard(
        'Events',
        Icons.event,
        _kOrange,
        '${_eventDir.totalEventsProduced} produced',
        '/admin/events',
      ),
      _ModuleCard(
        'Fighters',
        Icons.sports_mma,
        _kRed,
        '${_career.totalAssessments} careers',
        '/admin/fighters',
      ),
      const _ModuleCard(
        'Gyms',
        Icons.fitness_center,
        _kCyan,
        '0 registered',
        '/admin/gyms',
      ),
      _ModuleCard(
        'Federations',
        Icons.account_balance,
        _kGold,
        '${_federations.federations.length} active',
        '/admin/federations',
      ),
      _ModuleCard(
        'Amateur Leagues',
        Icons.emoji_events,
        _kGreen,
        '${_amateurs.activeTournaments.length} leagues',
        '/admin/amateur-leagues',
      ),
      const _ModuleCard(
        'Matchmaking',
        Icons.compare_arrows,
        _kMagenta,
        'AI-powered',
        '/admin/matchmaking',
      ),
      _ModuleCard(
        'Scoring',
        Icons.scoreboard,
        _kCyan,
        '${_scoring.activeFightCount} fights scored',
        '/admin/scoring',
      ),
      _ModuleCard(
        'Talent Scouting',
        Icons.search,
        _kOrange,
        '${_scouting.totalAssessments} scouted',
        '/admin/scouting',
      ),
      const _ModuleCard(
        'Sponsorships',
        Icons.handshake,
        _kGold,
        'Revenue engine',
        '/admin/sponsorships',
      ),
      _ModuleCard(
        'Content',
        Icons.auto_awesome,
        _kMagenta,
        '${_media.totalAssetsGenerated} assets',
        '/admin/content',
      ),
      _ModuleCard(
        'Simulations',
        Icons.science,
        _kCyan,
        '${_simulator.totalSimulations} sims',
        '/admin/simulations',
      ),
      _ModuleCard(
        'Discovery',
        Icons.explore,
        _kGreen,
        '${_discovery.totalSearches} searches',
        '/admin/discovery',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: modules.length,
      itemBuilder: (context, i) => _buildModuleCard(modules[i]),
    );
  }

  Widget _buildSafetyPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kRed.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield, color: _kRed, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Fighter Safety Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              _pillBadge('${_safety.totalIncidentsRecorded} incidents', _kRed),
              const SizedBox(width: 8),
              _pillBadge('${_safety.bookingsBlocked} blocked', _kOrange),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _actionButton('Safety Alerts', Icons.warning, _kRed, () {}),
              const SizedBox(width: 8),
              _actionButton(
                'Health Passports',
                Icons.medical_services,
                _kGreen,
                () {},
              ),
              const SizedBox(width: 8),
              _actionButton('AI Referee Log', Icons.visibility, _kCyan, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIToolsGrid() {
    final tools = [
      const _ModuleCard(
        'AI Media Director',
        Icons.movie_creation,
        _kMagenta,
        'Auto media gen',
        '/admin/ai-media',
      ),
      const _ModuleCard(
        'AI Event Director',
        Icons.directions_run,
        _kOrange,
        'Run sheet auto',
        '/admin/ai-event',
      ),
      _ModuleCard(
        'AI Referee',
        Icons.remove_red_eye,
        _kRed,
        '${_referee.totalAlertsIssued} alerts',
        '/admin/ai-referee',
      ),
      const _ModuleCard(
        'Fight Simulator',
        Icons.science,
        _kCyan,
        'Monte Carlo',
        '/admin/simulator',
      ),
      const _ModuleCard(
        'Brand Engine',
        Icons.palette,
        _kGold,
        'Fighter brands',
        '/admin/brand-engine',
      ),
      const _ModuleCard(
        'Career Engine',
        Icons.trending_up,
        _kGreen,
        'Career tracking',
        '/admin/career-engine',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: tools.length,
      itemBuilder: (context, i) => _buildModuleCard(tools[i]),
    );
  }

  Widget _buildGlobalPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kCyan.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.public, color: _kCyan, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Global Fight Network',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              _pillBadge('${_discovery.totalFighters} fighters', _kCyan),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _actionButton('Global Fighters', Icons.people, _kCyan, () {}),
              const SizedBox(width: 8),
              _actionButton('Opportunities', Icons.work, _kGold, () {}),
              const SizedBox(width: 8),
              _actionButton(
                'Regional Rankings',
                Icons.leaderboard,
                _kGreen,
                () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(_ModuleCard card) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kPanel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: card.color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(card.icon, color: card.color, size: 28),
            const SizedBox(height: 6),
            Text(
              card.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              card.subtitle,
              style: TextStyle(
                color: card.color.withValues(alpha: 0.7),
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 9),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard {
  final String label;
  final IconData icon;
  final Color color;
  final String subtitle;
  final String route;
  const _ModuleCard(
    this.label,
    this.icon,
    this.color,
    this.subtitle,
    this.route,
  );
}
