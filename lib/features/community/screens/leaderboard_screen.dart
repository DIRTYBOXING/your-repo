import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cards/dfc_card.dart';
import '../../../core/layout/dfc_layout.dart';
import '../../../core/layout/dfc_padding.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: DfcPadding(
        child: DfcLayout.constrain(
          child: ListView(
            children: [
              const SizedBox(height: 32),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.04),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white.withOpacity(0.6),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'DFC LEADERBOARD',
                      style: TextStyle(
                        color: Color(0xFF00FF88), // Neon Green
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Ranked globally by discipline, consistency, training hours, and impact. Not looks.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),

              _buildLeaderboardItem(
                rank: 1,
                name: 'Sarah "Savage" Mitchell',
                points: '14,250',
                discipline: 'MMA',
                isTop: true,
              ),
              const SizedBox(height: 12),
              _buildLeaderboardItem(
                rank: 2,
                name: 'Elena T.',
                points: '12,840',
                discipline: 'BJJ',
                isTop: true,
              ),
              const SizedBox(height: 12),
              _buildLeaderboardItem(
                rank: 3,
                name: 'Maya K.',
                points: '11,920',
                discipline: 'Muay Thai',
                isTop: true,
              ),
              const SizedBox(height: 12),
              _buildLeaderboardItem(
                rank: 4,
                name: 'Jessica R.',
                points: '10,400',
                discipline: 'Boxing',
              ),
              const SizedBox(height: 12),
              _buildLeaderboardItem(
                rank: 5,
                name: 'Amanda S.',
                points: '9,850',
                discipline: 'Strength & Conditioning',
              ),
              const SizedBox(height: 12),
              _buildLeaderboardItem(
                rank: 6,
                name: 'Chloe B.',
                points: '9,120',
                discipline: 'MMA',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem({
    required int rank,
    required String name,
    required String points,
    required String discipline,
    bool isTop = false,
  }) {
    final Color color = isTop ? const Color(0xFF00FF88) : Colors.white54;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTop ? color.withOpacity(0.05) : const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop ? color.withOpacity(0.3) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
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
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  discipline,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                points,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'PTS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
