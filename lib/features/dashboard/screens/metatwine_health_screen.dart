import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/metatwine_engine.dart';

class MetaTwineHealthScreen extends StatefulWidget {
  const MetaTwineHealthScreen({super.key});

  @override
  State<MetaTwineHealthScreen> createState() => _MetaTwineHealthScreenState();
}

class _MetaTwineHealthScreenState extends State<MetaTwineHealthScreen> {
  MetaTwineHealthSnapshot? _snapshot;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final engine = MetaTwineEngine();
    if (!engine.initialized) {
      await engine.initialize();
    }
    if (mounted) {
      setState(() {
        _snapshot = engine.getHealthSnapshot();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'METATWINE HEALTH',
          style: TextStyle(
            color: DesignTokens.neonCyan,
            letterSpacing: 3,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: DesignTokens.neonCyan),
            onPressed: () {
              setState(() => _loading = true);
              _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(DesignTokens.neonCyan),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Scanning graph…',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            )
          : _buildBody(_snapshot!),
    );
  }

  Widget _buildBody(MetaTwineHealthSnapshot s) {
    return RefreshIndicator(
      onRefresh: _load,
      color: DesignTokens.neonCyan,
      backgroundColor: DesignTokens.bgSecondary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const SizedBox(height: 8),
          _buildScoreCard(s),
          const SizedBox(height: 16),
          _buildStatRow(s),
          const SizedBox(height: 16),
          _buildHealthBar(s),
          const SizedBox(height: 24),
          _buildNodeHealthSection(s),
          const SizedBox(height: 24),
          _buildSectionHeader('MULTIPLIER EDGES', '${s.totalMultiplierEdges}'),
          const SizedBox(height: 8),
          _buildEdgesNote(s),
        ],
      ),
    );
  }

  Widget _buildScoreCard(MetaTwineHealthSnapshot s) {
    final score = s.systemMultiplierScore;
    final color = score >= 20
        ? DesignTokens.neonGreen
        : score >= 10
        ? DesignTokens.neonAmber
        : DesignTokens.neonRed;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [DesignTokens.bgSecondary, color.withAlpha(20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withAlpha(100), width: 1.5),
      ),
      child: Column(
        children: [
          const Text(
            'SYSTEM MULTIPLIER SCORE',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            score.toStringAsFixed(2),
            style: TextStyle(
              color: color,
              fontSize: 56,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                s.isHealthy ? Icons.check_circle : Icons.warning_amber_rounded,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                s.isHealthy ? 'SYSTEM HEALTHY' : 'ATTENTION REQUIRED',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(MetaTwineHealthSnapshot s) {
    return Row(
      children: [
        _buildStatTile(
          'BOTS',
          '${s.activeBots}/${s.totalBots}',
          DesignTokens.neonCyan,
          Icons.smart_toy,
        ),
        const SizedBox(width: 8),
        _buildStatTile(
          'NODES',
          '${s.activeNodes}/${s.totalNodes}',
          DesignTokens.neonMagenta,
          Icons.hub,
        ),
        const SizedBox(width: 8),
        _buildStatTile(
          'PLATFORMS',
          '${s.activePlatforms}/${s.totalPlatforms}',
          DesignTokens.neonAmber,
          Icons.language,
        ),
      ],
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: DesignTokens.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthBar(MetaTwineHealthSnapshot s) {
    final pct = s.healthPercent;
    final color = pct > 0.7
        ? DesignTokens.neonGreen
        : pct > 0.4
        ? DesignTokens.neonAmber
        : DesignTokens.neonRed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'OVERALL GRAPH HEALTH',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
            Text(
              '${(pct * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildNodeHealthSection(MetaTwineHealthSnapshot s) {
    final nodes = s.nodeHealthMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('NODE HEALTH MAP', '${nodes.length}'),
        const SizedBox(height: 8),
        ...nodes.map((e) => _buildNodeRow(e.key, e.value)),
      ],
    );
  }

  Widget _buildNodeRow(String nodeName, double health) {
    final color = health > 0.7
        ? DesignTokens.neonGreen
        : health > 0.4
        ? DesignTokens.neonAmber
        : DesignTokens.neonRed;
    final displayName = nodeName
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
        .trim()
        .toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withAlpha(120), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              displayName,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
          SizedBox(
            width: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: health,
                minHeight: 4,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '${(health * 100).toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: TextStyle(color: color, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEdgesNote(MetaTwineHealthSnapshot s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.neonMagenta.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.device_hub,
                color: DesignTokens.neonMagenta,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${s.totalMultiplierEdges} INTER-SERVICE EDGES ACTIVE',
                style: const TextStyle(
                  color: DesignTokens.neonMagenta,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'These edges represent how DFC services amplify, feed into, '
            'validate, monetize, and protect each other. '
            'Each edge carries a weighted connection (0.0–1.0) '
            'determining signal propagation strength across the graph.',
            style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
          ),
          const SizedBox(height: 12),
          _buildEdgeTypeLegend(),
        ],
      ),
    );
  }

  Widget _buildEdgeTypeLegend() {
    const types = [
      ('feedsInto', '→', 'Output of A becomes input to B'),
      ('amplifies', '⬆', 'A increases effectiveness of B'),
      ('validates', '✓', 'A verifies / gates output of B'),
      ('monetizes', r'$', 'A creates revenue from B'),
      ('distributes', '📡', 'A distributes B to wider audience'),
      ('protects', '🛡', 'A safeguards B from risk/abuse'),
      ('learns', '🧠', 'A improves B through feedback'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: types
          .map(
            (t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      t.$2,
                      style: const TextStyle(
                        color: DesignTokens.neonCyan,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '${t.$1}: ',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      t.$3,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSectionHeader(String title, String count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: DesignTokens.neonCyan.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DesignTokens.neonCyan.withAlpha(80)),
          ),
          child: Text(
            count,
            style: const TextStyle(color: DesignTokens.neonCyan, fontSize: 10),
          ),
        ),
      ],
    );
  }
}
