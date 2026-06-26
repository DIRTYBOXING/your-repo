import 'package:flutter/material.dart';
import '../core/theme/design_tokens.dart';
import '../features/ppv/api/ai_workflow_api.dart';

class AdrenalineGateQuiz extends StatefulWidget {
  final String ppvTitle;

  const AdrenalineGateQuiz({super.key, required this.ppvTitle});

  @override
  State<AdrenalineGateQuiz> createState() => _AdrenalineGateQuizState();
}

class _AdrenalineGateQuizState extends State<AdrenalineGateQuiz> {
  int _currentQuestion = 0;
  final Map<int, String> _answers = {};
  bool _isSubmitting = false;
  bool _isComplete = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Who gets the first knockdown?',
      'options': ['Fighter A', 'Fighter B', 'No Knockdowns'],
    },
    {
      'question': 'Will the fight go the distance?',
      'options': ['Yes', 'No - Early Finish'],
    },
    {
      'question': 'Method of Victory?',
      'options': ['KO / TKO', 'Submission', 'Decision'],
    },
  ];

  Future<void> _submitQuiz() async {
    setState(() => _isSubmitting = true);
    try {
      final api = WorkflowAutomationClient();
      await api.submitPrediction(ppvTitle: widget.ppvTitle, answers: _answers);
      if (mounted) setState(() => _isComplete = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting prediction: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _answerQuestion(String answer) {
    setState(() {
      _answers[_currentQuestion] = answer;
      if (_currentQuestion < _questions.length - 1) {
        _currentQuestion++;
      } else {
        _submitQuiz();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isComplete) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DesignTokens.neonGreen, width: 2),
        ),
        child: const Column(
          children: [
            Icon(Icons.local_fire_department, color: Colors.orange, size: 48),
            SizedBox(height: 16),
            Text(
              'HYPE LOCKED IN!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your predictions have been added to the global data feed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final question = _questions[_currentQuestion];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.neonCyan, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ADRENALINE GATE',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '${_currentQuestion + 1} / ${_questions.length}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            question['question'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          if (_isSubmitting)
            const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            )
          else
            ...(question['options'] as List<String>).map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black45,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _answerQuestion(option),
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
