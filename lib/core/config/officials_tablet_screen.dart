import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// OFFICIALS TABLET - 10-POINT MUST SCORING SYSTEM
/// Live ringside scoring interface for official judges.
/// ═══════════════════════════════════════════════════════════════════════════
class OfficialsTabletScreen extends StatefulWidget {
  const OfficialsTabletScreen({super.key});

  @override
  State<OfficialsTabletScreen> createState() => _OfficialsTabletScreenState();
}

class _OfficialsTabletScreenState extends State<OfficialsTabletScreen> {
  // Mocking active fight data. In production, this pulls from your `fights` stream.
  final String _fightId = 'demo_fight_123';
  final String _fighterAName = 'Marcus Torres';
  final String _fighterBName = 'Elijah Okafor';

  int _currentRound = 1;
  int _scoreA = 10;
  int _scoreB = 9;
  bool _isSubmitting = false;

  Future<void> _lockScore() async {
    setState(() => _isSubmitting = true);

    try {
      final judgeId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_judge';

      // Write directly to the Regulatory Engine's judges_scores table
      await FirebaseFirestore.instance.collection('judges_scores').add({
        'fight_id': _fightId,
        'judge_id': judgeId,
        'round_num': _currentRound,
        'fighter_a_score': _scoreA,
        'fighter_b_score': _scoreB,
        'locked': true,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Round $_currentRound locked successfully.',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppColors.neonGreen,
          ),
        );
        setState(() {
          _currentRound++;
          _scoreA = 10;
          _scoreB = 9;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error locking score: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.neonRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        title: const Text(
          'RINGSIDE SCORING',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: AppColors.neonCyan.withValues(alpha: 0.1),
              child: Center(
                child: Text(
                  'ROUND $_currentRound',
                  style: const TextStyle(
                    color: AppColors.neonCyan,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  // ── RED CORNER (FIGHTER A) ──
                  Expanded(
                    child: _buildCornerScorer(
                      name: _fighterAName,
                      score: _scoreA,
                      cornerColor: AppColors.neonRed,
                      onIncrease: () =>
                          setState(() => _scoreA = (_scoreA + 1).clamp(7, 10)),
                      onDecrease: () =>
                          setState(() => _scoreA = (_scoreA - 1).clamp(7, 10)),
                    ),
                  ),

                  Container(width: 2, color: AppColors.border),

                  // ── BLUE CORNER (FIGHTER B) ──
                  Expanded(
                    child: _buildCornerScorer(
                      name: _fighterBName,
                      score: _scoreB,
                      cornerColor: AppColors.neonBlue,
                      onIncrease: () =>
                          setState(() => _scoreB = (_scoreB + 1).clamp(7, 10)),
                      onDecrease: () =>
                          setState(() => _scoreB = (_scoreB - 1).clamp(7, 10)),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              color: AppColors.panel,
              child: SizedBox(
                width: double.infinity,
                height: 70,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _lockScore,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          'LOCK ROUND $_currentRound',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerScorer({
    required String name,
    required int score,
    required Color cornerColor,
    required VoidCallback onIncrease,
    required VoidCallback onDecrease,
  }) {
    return Container(
      color: cornerColor.withValues(alpha: 0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cornerColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ScoreButton(
                icon: Icons.remove,
                color: cornerColor,
                onTap: onDecrease,
              ),
              const SizedBox(width: 30),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: cornerColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    score.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 30),
              _ScoreButton(
                icon: Icons.add,
                color: cornerColor,
                onTap: onIncrease,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ScoreButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color),
        ),
        child: Icon(icon, color: color, size: 36),
      ),
    );
  }
}
