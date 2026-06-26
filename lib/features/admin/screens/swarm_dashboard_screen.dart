import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/samurai_swarm_coordinator.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// SAMURAI SWARM DASHBOARD
/// Real-time status dashboard showing all 53 agents, swarm health,
/// content generation, and inter-agent communication.
/// ═══════════════════════════════════════════════════════════════════════════════
class SwarmDashboardScreen extends StatefulWidget {
  const SwarmDashboardScreen({super.key});

  @override
  State<SwarmDashboardScreen> createState() => _SwarmDashboardScreenState();
}

class _SwarmDashboardScreenState extends State<SwarmDashboardScreen>
    with SingleTickerProviderStateMixin {
  final SamuraiSwarmCoordinator _swarm = SamuraiSwarmCoordinator();
  late TabController _tabController;
  bool _booting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _swarm.addListener(_onSwarmUpdate);

    // Auto-boot if not already booted
    if (!_swarm.initialized) {
      _bootSwarm();
    }
  }

  @override
  void dispose() {
    _swarm.removeListener(_onSwarmUpdate);
    _tabController.dispose();
    super.dispose();
  }

  void _onSwarmUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _bootSwarm() async {
    setState(() => _booting = true);
    await _swarm.bootSwarm();
    if (mounted) setState(() => _booting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          '⚔️ SAMURAI SWARM',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        backgroundColor: Colors.black,
        foregroundColor: AppTheme.neonCyan,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.neonCyan,
          labelColor: AppTheme.neonCyan,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          tabs: const [
            Tab(text: '⚡ OVERVIEW'),
            Tab(text: '🤖 AGENTS'),
            Tab(text: '📡 MESSAGE BUS'),
            Tab(text: '📊 CONTENT'),
          ],
        ),
        actions: [
          if (_swarm.swarmActive)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_swarm.onlineAgents}/${_swarm.totalAgents}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _booting
          ? _buildBootScreen()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildAgentsTab(),
                _buildMessageBusTab(),
                _buildContentTab(),
              ],
            ),
      floatingActionButton: _swarm.initialized
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'pump',
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await _swarm.forcePump();
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('⚔️ Content pump fired!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  backgroundColor: AppTheme.neonCyan,
                  child: const Icon(Icons.bolt, color: Colors.black),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'fire',
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await _swarm.fireAll();
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('🔥 FIRE ALL — Publishing everywhere!'),
                          backgroundColor: Colors.deepOrange,
                        ),
                      );
                    }
                  },
                  backgroundColor: Colors.deepOrange,
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'seed',
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final count = await _swarm.seedAllPages();
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            '⚔️ MEGA SEED: $count items generated!',
                          ),
                          backgroundColor: Colors.purple,
                        ),
                      );
                    }
                  },
                  backgroundColor: Colors.purple,
                  child: const Icon(Icons.rocket_launch, color: Colors.white),
                ),
              ],
            )
          : null,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOOT SCREEN
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBootScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              color: AppTheme.neonCyan,
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '⚔️ BOOTING SAMURAI SWARM',
            style: TextStyle(
              color: AppTheme.neonCyan,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '53 agents · 25 engines · 1 hive mind',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Initializing all scanners, promoters, and AI personas...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OVERVIEW TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildOverviewTab() {
    final health = _swarm.latestHealth;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Swarm mood banner
          if (health != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.neonCyan.withValues(alpha: 0.15),
                    Colors.purple.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.neonCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    health.swarmMood,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cycle ${_swarm.cycleCount} · Uptime: ${_formatUptime()}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Stat cards
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'AGENTS',
                  '${_swarm.onlineAgents}/${_swarm.totalAgents}',
                  Icons.smart_toy,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard(
                  'CONTENT',
                  '${_swarm.totalContentGenerated}',
                  Icons.article,
                  AppTheme.neonCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'MESSAGES',
                  '${health?.messagesProcessed ?? 0}',
                  Icons.message,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard(
                  'VELOCITY',
                  '${health?.contentVelocity.toStringAsFixed(1) ?? "0"}/min',
                  Icons.speed,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'EFFICIENCY',
                  '${((health?.swarmEfficiency ?? 0) * 100).toStringAsFixed(0)}%',
                  Icons.analytics,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard(
                  'CYCLES',
                  '${_swarm.cycleCount}',
                  Icons.autorenew,
                  Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Engine status grid
          const Text(
            'ENGINE STATUS',
            style: TextStyle(
              color: AppTheme.neonCyan,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          if (health != null)
            ...health.engineStatus.entries.map(
              (e) => _engineStatusRow(e.key, e.value),
            ),

          const SizedBox(height: 24),

          // Recent messages
          const Text(
            'RECENT SWARM ACTIVITY',
            style: TextStyle(
              color: AppTheme.neonCyan,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          if (health != null && health.recentMessages.isNotEmpty)
            ...health.recentMessages.take(5).map(_buildMessageTile),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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

  Widget _engineStatusRow(String name, AgentStatus status) {
    final color = status == AgentStatus.online
        ? Colors.green
        : status == AgentStatus.booting
        ? Colors.amber
        : Colors.red;
    final label = status == AgentStatus.online
        ? 'ONLINE'
        : status == AgentStatus.booting
        ? 'BOOTING'
        : 'OFFLINE';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AGENTS TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAgentsTab() {
    final agents = _swarm.agents;
    final scanners = agents
        .where((a) => a.engineName == 'ContentScannerEngine')
        .toList();
    final promos = agents
        .where((a) => a.engineName == 'PromoterAIService')
        .toList();
    final personas = agents
        .where((a) => a.engineName == 'SamuraiOrchestrator')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _agentSection('⚔️ SAMURAI PERSONAS (${personas.length})', personas),
          const SizedBox(height: 16),
          _agentSection('🔥 PROMOTER BOTS (${promos.length})', promos),
          const SizedBox(height: 16),
          _agentSection('🔍 SCANNER BOTS (${scanners.length})', scanners),
        ],
      ),
    );
  }

  Widget _agentSection(String title, List<SwarmAgent> agents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.neonCyan,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: agents.map(_buildAgentChip).toList(),
        ),
      ],
    );
  }

  Widget _buildAgentChip(SwarmAgent agent) {
    final color = agent.status == AgentStatus.online
        ? Colors.green
        : agent.status == AgentStatus.booting
        ? Colors.amber
        : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(agent.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                agent.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${agent.contentGenerated} items · ${(agent.performanceScore * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGE BUS TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMessageBusTab() {
    final messages = _swarm.messageBus;
    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet — swarm is quiet',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) => _buildMessageTile(messages[index]),
    );
  }

  Widget _buildMessageTile(SwarmMessage msg) {
    final priorityColor = msg.priority == SwarmPriority.critical
        ? Colors.red
        : msg.priority == SwarmPriority.high
        ? Colors.orange
        : msg.priority == SwarmPriority.normal
        ? AppTheme.neonCyan
        : Colors.white38;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: priorityColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: priorityColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  msg.type,
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${msg.fromAgent} → ${msg.toAgent == '*' ? 'ALL' : msg.toAgent}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ),
              Text(
                _formatTime(msg.timestamp),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            msg.payload,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTENT TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildContentTab() {
    final content = _swarm.contentQueue;
    if (content.isEmpty) {
      return const Center(
        child: Text(
          'Content pump starting — items will appear here',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: content.length,
      itemBuilder: (context, index) {
        final item = content[content.length - 1 - index]; // newest first
        return _buildContentTile(item);
      },
    );
  }

  Widget _buildContentTile(SwarmContent item) {
    final typeColor = _typeColor(item.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: typeColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: typeColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.type.toUpperCase(),
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.source,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ),
              _hypeIndicator(item.hypeScore),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (item.body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.body.length > 120
                  ? '${item.body.substring(0, 120)}...'
                  : item.body,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
          if (item.tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              children: item.tags
                  .map(
                    (t) => Text(
                      '#$t',
                      style: TextStyle(
                        color: typeColor.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _hypeIndicator(double score) {
    final color = score >= 0.9
        ? Colors.red
        : score >= 0.7
        ? Colors.orange
        : score >= 0.5
        ? Colors.amber
        : Colors.green;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_fire_department, color: color, size: 12),
        const SizedBox(width: 2),
        Text(
          (score * 100).toStringAsFixed(0),
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'news':
        return Colors.blue;
      case 'post':
        return AppTheme.neonCyan;
      case 'event':
        return Colors.purple;
      case 'promo':
        return Colors.deepOrange;
      case 'training':
        return Colors.green;
      case 'story':
        return Colors.amber;
      case 'metaverse':
        return Colors.teal;
      default:
        return Colors.white54;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  String _formatUptime() {
    if (_swarm.bootTime == null) return '--';
    final d = DateTime.now().difference(_swarm.bootTime!);
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }

  String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
  }
}
