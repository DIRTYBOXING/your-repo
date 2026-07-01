import 'package:flutter/material.dart';
import '../../../shared/services/bot_orchestrator_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../genie_persona.dart';

/// Bot Command Center — Fleet overview and management
class BotCommandCenterScreen extends StatefulWidget {
  const BotCommandCenterScreen({super.key});

  @override
  State<BotCommandCenterScreen> createState() => _BotCommandCenterScreenState();
}

class _BotCommandCenterScreenState extends State<BotCommandCenterScreen> {
  final BotOrchestratorService _orchestrator = BotOrchestratorService();
  Map<String, dynamic> _fleetStats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _orchestrator.initialize();
      final stats = _orchestrator.getFleetStats();
      if (mounted) {
        setState(() {
          _fleetStats = stats;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        title: const Text('BOT COMMAND CENTER'),
        backgroundColor: DesignTokens.bgSecondary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _loadData();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DesignTokens.neonCyan),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: DesignTokens.neonCyan,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFleetOverview(),
                  const SizedBox(height: 24),
                  _buildBotGrid(),
                  const SizedBox(height: 24),
                  _buildRecentActions(),
                ],
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FLEET OVERVIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFleetOverview() {
    final total = _fleetStats['total'] ?? 0;
    final active = _fleetStats['active'] ?? 0;
    final paused = _fleetStats['paused'] ?? 0;
    final disabled = _fleetStats['disabled'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.hub, color: DesignTokens.neonCyan, size: 24),
              SizedBox(width: 8),
              Text(
                'FLEET STATUS',
                style: TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statCard('Total', '$total', DesignTokens.neonCyan),
              const SizedBox(width: 12),
              _statCard('Active', '$active', DesignTokens.neonGreen),
              const SizedBox(width: 12),
              _statCard('Paused', '$paused', DesignTokens.neonAmber),
              const SizedBox(width: 12),
              _statCard('Disabled', '$disabled', DesignTokens.neonRed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOT GRID
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBotGrid() {
    final bots = _orchestrator.allBots;
    if (bots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No bots registered',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BOT FLEET',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...bots.map(_buildBotCard),
      ],
    );
  }

  Widget _buildBotCard(BotDefinition bot) {
    final persona = geniePersonas.cast<GeniePersona?>().firstWhere(
      (p) => p?.id == bot.id,
      orElse: () => null,
    );
    final color = persona?.accentColor ?? DesignTokens.neonCyan;
    final emoji = persona?.emoji ?? '🤖';
    final isActive = bot.status == BotStatus.active;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Emoji avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      bot.displayName,
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusBadge(bot.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  bot.type.name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${bot.capabilities.length} capabilities',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Toggle
          Switch(
            value: isActive,
            onChanged: (val) async {
              await _orchestrator.setBotStatus(
                bot.id,
                val ? BotStatus.active : BotStatus.paused,
              );
              _loadData();
            },
            activeThumbColor: color,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(BotStatus status) {
    Color color;
    String label;
    switch (status) {
      case BotStatus.active:
        color = DesignTokens.neonGreen;
        label = 'ACTIVE';
        break;
      case BotStatus.paused:
        color = DesignTokens.neonAmber;
        label = 'PAUSED';
        break;
      case BotStatus.disabled:
        color = DesignTokens.neonRed;
        label = 'OFF';
        break;
      case BotStatus.maintenance:
        color = Colors.grey;
        label = 'MAINT';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECENT ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRecentActions() {
    return FutureBuilder<List<BotAction>>(
      future: _orchestrator.getRecentActions('all', limit: 10),
      builder: (context, snapshot) {
        final actions = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RECENT ACTIONS',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            if (actions.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: DesignTokens.bgCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'No recent bot actions',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              )
            else
              ...actions.map(_buildActionTile),
          ],
        );
      },
    );
  }

  Widget _buildActionTile(BotAction action) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bolt,
            size: 16,
            color: DesignTokens.neonAmber.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${action.botId} · ${action.actionType}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (action.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      action.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _timeAgo(action.timestamp),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
