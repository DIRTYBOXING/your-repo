import 'package:flutter/material.dart';
import '../services/judge_score_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ROUND SCORING WIDGET — "You're The Judge" Live Interface
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Compact overlay for scoring rounds during live fights.
/// Appears between rounds or when user taps "Judge" button.
///
/// Features:
///   • 10-7 scoring system (10-9, 10-8, 10-7 buttons)
///   • Red vs Blue corner selection
///   • Quick submit with haptic feedback
///   • XP popup animation on successful submit
///   • "Already scored" state if round was judged
///   • Live position tracker ("3rd to score!")
/// ═══════════════════════════════════════════════════════════════════════════
class RoundScoringWidget extends StatefulWidget {
  final String eventId;
  final String fightId;
  final int currentRound;
  final String redCornerName;
  final String blueCornerName;
  final VoidCallback? onScoreSubmitted;

  const RoundScoringWidget({
    super.key,
    required this.eventId,
    required this.fightId,
    required this.currentRound,
    required this.redCornerName,
    required this.blueCornerName,
    this.onScoreSubmitted,
  });

  @override
  State<RoundScoringWidget> createState() => _RoundScoringWidgetState();
}

class _RoundScoringWidgetState extends State<RoundScoringWidget>
    with SingleTickerProviderStateMixin {
  final JudgeScoreService _judgeService = JudgeScoreService();

  int _redScore = 10;
  int _blueScore = 10;
  bool _submitting = false;
  bool _alreadyScored = false;
  late AnimationController _xpAnimCtrl;
  late Animation<double> _xpScale;
  late Animation<double> _xpFade;

  @override
  void initState() {
    super.initState();
    _xpAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _xpScale = Tween<double>(
      begin: 0.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _xpAnimCtrl, curve: Curves.elasticOut));
    _xpFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _xpAnimCtrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    _checkIfAlreadyScored();
  }

  @override
  void dispose() {
    _xpAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkIfAlreadyScored() async {
    final scored = await _judgeService.hasUserScoredRound(
      eventId: widget.eventId,
      fightId: widget.fightId,
      roundNumber: widget.currentRound,
    );
    if (!mounted) return;
    setState(() {
      _alreadyScored = scored;
    });
  }

  Future<void> _submitScore() async {
    if (_submitting || _alreadyScored) return;

    setState(() {
      _submitting = true;
    });

    try {
      await _judgeService.submitRoundScore(
        eventId: widget.eventId,
        fightId: widget.fightId,
        roundNumber: widget.currentRound,
        redCornerScore: _redScore,
        blueCornerScore: _blueScore,
      );

      if (!mounted) return;

      _xpAnimCtrl.forward(from: 0);

      setState(() {
        _alreadyScored = true;
      });

      widget.onScoreSubmitted?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Score submitted! XP pending official results.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.95),
            Colors.grey.shade900.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _alreadyScored
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.cyanAccent.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.gavel, color: Colors.cyanAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Judge Round ${widget.currentRound}',
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (_alreadyScored)
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Scored',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Scoring interface
          if (!_alreadyScored) ...[
            Row(
              children: [
                // Red Corner
                Expanded(
                  child: _buildCornerScorer(
                    name: widget.redCornerName,
                    color: Colors.red,
                    score: _redScore,
                    onScoreChanged: (score) {
                      setState(() {
                        _redScore = score;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                // Blue Corner
                Expanded(
                  child: _buildCornerScorer(
                    name: widget.blueCornerName,
                    color: Colors.blue,
                    score: _blueScore,
                    onScoreChanged: (score) {
                      setState(() {
                        _blueScore = score;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitScore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Score',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ] else ...[
            // Already scored view
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            widget.redCornerName,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _redScore.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        '-',
                        style: TextStyle(color: Colors.white54, fontSize: 24),
                      ),
                      Column(
                        children: [
                          Text(
                            widget.blueCornerName,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _blueScore.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '⏳ Awaiting official results to award XP',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],

          // XP animation overlay
          AnimatedBuilder(
            animation: _xpAnimCtrl,
            builder: (context, child) {
              if (!_xpAnimCtrl.isAnimating && _xpAnimCtrl.value == 0) {
                return const SizedBox.shrink();
              }
              return Positioned.fill(
                child: Center(
                  child: Opacity(
                    opacity: _xpFade.value,
                    child: Transform.scale(
                      scale: _xpScale.value,
                      child: const Text(
                        '+10 XP',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(blurRadius: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCornerScorer({
    required String name,
    required Color color,
    required int score,
    required ValueChanged<int> onScoreChanged,
  }) {
    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Text(
          score.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 4,
          children: [
            _buildScoreButton(10, score, color, onScoreChanged),
            _buildScoreButton(9, score, color, onScoreChanged),
            _buildScoreButton(8, score, color, onScoreChanged),
            _buildScoreButton(7, score, color, onScoreChanged),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreButton(
    int value,
    int currentScore,
    Color color,
    ValueChanged<int> onChanged,
  ) {
    final isSelected = value == currentScore;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          value.toString(),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
