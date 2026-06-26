import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

/// FIGHTER ARCHIVE — Deep stats, AI predictions, career timeline.
/// Competitive gap: UFC Fight Pass has archives but no AI overlay.
class FighterArchiveScreen extends StatefulWidget {
  const FighterArchiveScreen({super.key});

  @override
  State<FighterArchiveScreen> createState() => _FighterArchiveScreenState();
}

class _FighterArchiveScreenState extends State<FighterArchiveScreen> {
  String _selectedFighter = 'Hepi';

  final _fighters = <String>[
    'Hepi',
    'BK Bau',
    'Hardman',
    'Flanagan',
    'Sione',
    'Wisniewski',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Row(
          children: [
            Icon(Icons.auto_stories, color: DesignTokens.neonCyan, size: 22),
            SizedBox(width: 8),
            Text(
              'FIGHTER ARCHIVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── FIGHTER SELECTOR ──
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _fighters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final f = _fighters[i];
                final sel = f == _selectedFighter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFighter = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: sel
                          ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                          : DesignTokens.bgCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sel
                            ? DesignTokens.neonCyan.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                    child: Text(
                      f.toUpperCase(),
                      style: TextStyle(
                        color: sel ? DesignTokens.neonCyan : Colors.white30,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── FIGHTER HERO ──
          _fighterHero(),
          const SizedBox(height: 16),

          // ── STATS GRID ──
          _statsGrid(),
          const SizedBox(height: 16),

          // ── AI PREDICTIONS ──
          const Text(
            'AI PREDICTIONS',
            style: TextStyle(
              color: DesignTokens.neonMagenta,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          _predictionCard(
            'Win Probability vs Wisniewski',
            '72%',
            DesignTokens.neonGreen,
          ),
          _predictionCard('KO/TKO Likelihood', '45%', DesignTokens.neonAmber),
          _predictionCard('Goes to Decision', '28%', DesignTokens.neonCyan),
          _predictionCard('Round 1 Finish Chance', '18%', DesignTokens.neonRed),
          const SizedBox(height: 16),

          // ── CAREER TIMELINE ──
          const Text(
            'CAREER TIMELINE',
            style: TextStyle(
              color: DesignTokens.neonGold,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          _timelineEntry(
            'Apr 2026',
            'vs Wisniewski',
            'UPCOMING',
            DesignTokens.neonAmber,
            'BKFC Fight Night — Main Event',
          ),
          _timelineEntry(
            'Feb 2026',
            'vs Rodriguez',
            'WIN — KO R3',
            DesignTokens.neonGreen,
            'BKFC 64 — Brisbane',
          ),
          _timelineEntry(
            'Nov 2025',
            'vs Thompson',
            'WIN — UD',
            DesignTokens.neonGreen,
            'BKFC 58 — Logan',
          ),
          _timelineEntry(
            'Aug 2025',
            'vs Kim',
            'WIN — TKO R2',
            DesignTokens.neonGreen,
            'BKFC 54 — Gold Coast',
          ),
          _timelineEntry(
            'May 2025',
            'vs Jenkins',
            'LOSS — SD',
            DesignTokens.neonRed,
            'BKFC 49 — Auckland',
          ),
          _timelineEntry(
            'Feb 2025',
            'vs Davis',
            'WIN — KO R1',
            DesignTokens.neonGreen,
            'BKFC 44 — Townsville',
          ),
          _timelineEntry(
            'Dec 2024',
            'Pro Debut',
            'WIN — TKO R2',
            DesignTokens.neonGreen,
            'BKFC 40 — Logan',
          ),

          const SizedBox(height: 16),

          // ── STRIKING ANALYSIS ──
          const Text(
            'STRIKING ANALYSIS',
            style: TextStyle(
              color: DesignTokens.neonCyan,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          _strikeStat('Strikes Landed / Min', '6.4', 0.82),
          _strikeStat('Significant Strike Accuracy', '54%', 0.54),
          _strikeStat('Knockdown Rate', '32%', 0.32),
          _strikeStat('Head Strike %', '68%', 0.68),
          _strikeStat('Body Strike %', '22%', 0.22),
          _strikeStat('Defense Rate', '61%', 0.61),
        ],
      ),
    );
  }

  Widget _fighterHero() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.06),
            DesignTokens.neonMagenta.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          // Avatar placeholder
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: DesignTokens.neonCyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person,
              color: DesignTokens.neonCyan.withValues(alpha: 0.4),
              size: 36,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedFighter.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                const Row(
                  children: [
                    Text(
                      'BKFC · Middleweight',
                      style: TextStyle(
                        color: DesignTokens.neonCyan,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Logan, QLD',
                      style: TextStyle(color: Colors.white30, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '6W — 1L — 0D',
                  style: TextStyle(
                    color: DesignTokens.neonGreen,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DesignTokens.neonGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '#3 RANKED',
                  style: TextStyle(
                    color: DesignTokens.neonGold,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '86% finish rate',
                style: TextStyle(color: Colors.white30, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsGrid() {
    final stats = [
      ('WINS', '6', DesignTokens.neonGreen),
      ('LOSSES', '1', DesignTokens.neonRed),
      ('KO/TKO', '4', DesignTokens.neonAmber),
      ('DECISIONS', '2', DesignTokens.neonCyan),
      ('ROUNDS', '18', Colors.white54),
      ('FIGHT TIME', '42:18', Colors.white54),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: stats.map((s) {
        final (label, value, color) = s;
        return Container(
          width: (MediaQuery.of(context).size.width - 48) / 3,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white30,
                  fontWeight: FontWeight.w700,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _predictionCard(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.psychology,
            color: DesignTokens.neonMagenta.withValues(alpha: 0.5),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineEntry(
    String date,
    String opponent,
    String result,
    Color color,
    String event,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              date,
              style: const TextStyle(
                color: Colors.white30,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opponent,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  event,
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              result,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _strikeStat(String label, String value, double pct) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: DesignTokens.neonCyan,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withValues(alpha: 0.04),
              valueColor: AlwaysStoppedAnimation<Color>(
                DesignTokens.neonCyan.withValues(alpha: 0.6),
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
