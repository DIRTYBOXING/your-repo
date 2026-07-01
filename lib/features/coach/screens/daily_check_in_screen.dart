import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Daily Check-In Screen
/// The AI asks, the human answers, the system learns
/// This is where human + AI integration starts each day
class DailyCheckInScreen extends StatefulWidget {
  const DailyCheckInScreen({super.key});

  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen> {
  int _currentStep = 0;

  // Check-in responses
  int _sleepHours = 7;
  int _sleepQuality = 3; // 1-5
  int _energyLevel = 3; // 1-5
  int _painLevel = 1; // 1-5
  int _stressLevel = 2; // 1-5
  int _motivation = 4; // 1-5
  double _hydrationLiters = 2.0;
  String _todayFocus = '';

  final List<String> _questions = [
    "How'd you sleep?",
    "Energy level right now?",
    "Any pain or soreness?",
    "Stress level?",
    "Motivation to train?",
    "Hydration so far?",
    "What's the focus today?",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(child: _buildCurrentQuestion()),
            _buildNavButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.neonCyan, AppTheme.neonGreen],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.wb_sunny_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Morning Check-In',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getGreeting(),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Let's see where you're at.";
    if (hour < 17) return "Afternoon check. How's the body?";
    return "Evening update. Wrapping up the day.";
  }

  Widget _buildProgressBar() {
    final progress = (_currentStep + 1) / _questions.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of ${_questions.length}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: AppTheme.neonCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.surfaceColor,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.neonCyan,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentQuestion() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        key: ValueKey(_currentStep),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _questions[_currentStep],
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildInputForStep(_currentStep),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForStep(int step) {
    switch (step) {
      case 0: // Sleep
        return _buildSleepInput();
      case 1: // Energy
        return _buildScaleInput(
          _energyLevel,
          'Energy',
          (v) => setState(() => _energyLevel = v),
        );
      case 2: // Pain
        return _buildScaleInput(
          _painLevel,
          'Pain',
          (v) => setState(() => _painLevel = v),
          inverted: true,
        );
      case 3: // Stress
        return _buildScaleInput(
          _stressLevel,
          'Stress',
          (v) => setState(() => _stressLevel = v),
          inverted: true,
        );
      case 4: // Motivation
        return _buildScaleInput(
          _motivation,
          'Motivation',
          (v) => setState(() => _motivation = v),
        );
      case 5: // Hydration
        return _buildHydrationInput();
      case 6: // Focus
        return _buildFocusInput();
      default:
        return const SizedBox();
    }
  }

  Widget _buildSleepInput() {
    return Column(
      children: [
        // Hours slider
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$_sleepHours',
              style: const TextStyle(
                color: AppTheme.neonCyan,
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              ' hours',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 20),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.neonCyan,
            inactiveTrackColor: AppTheme.surfaceColor,
            thumbColor: AppTheme.neonCyan,
            overlayColor: AppTheme.neonCyan.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: _sleepHours.toDouble(),
            max: 12,
            divisions: 12,
            onChanged: (v) => setState(() => _sleepHours = v.toInt()),
          ),
        ),
        const SizedBox(height: 24),
        // Quality
        const Text(
          'Sleep quality?',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _buildScaleButtons(
          _sleepQuality,
          (v) => setState(() => _sleepQuality = v),
        ),
      ],
    );
  }

  Widget _buildScaleInput(
    int value,
    String label,
    Function(int) onChanged, {
    bool inverted = false,
  }) {
    return Column(
      children: [
        _buildScaleButtons(value, onChanged, inverted: inverted),
        const SizedBox(height: 20),
        Text(
          _getScaleLabel(value, inverted),
          style: TextStyle(
            color: _getScaleColor(value, inverted),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildScaleButtons(
    int value,
    Function(int) onChanged, {
    bool inverted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final level = index + 1;
        final isSelected = level == value;
        final color = _getButtonColor(level, inverted);

        return GestureDetector(
          onTap: () => onChanged(level),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected ? color : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? color : AppTheme.surfaceColor,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                '$level',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Color _getButtonColor(int level, bool inverted) {
    if (inverted) {
      // For pain/stress - low is good
      if (level <= 2) return AppTheme.neonGreen;
      if (level == 3) return Colors.orange;
      return const Color(0xFFE17055);
    } else {
      // For energy/motivation - high is good
      if (level >= 4) return AppTheme.neonGreen;
      if (level == 3) return Colors.orange;
      return const Color(0xFFE17055);
    }
  }

  String _getScaleLabel(int value, bool inverted) {
    if (inverted) {
      switch (value) {
        case 1:
          return 'None / Minimal';
        case 2:
          return 'Slight';
        case 3:
          return 'Moderate';
        case 4:
          return 'Significant';
        case 5:
          return 'Severe';
        default:
          return '';
      }
    } else {
      switch (value) {
        case 1:
          return 'Very Low';
        case 2:
          return 'Low';
        case 3:
          return 'Moderate';
        case 4:
          return 'Good';
        case 5:
          return 'Excellent';
        default:
          return '';
      }
    }
  }

  Color _getScaleColor(int value, bool inverted) {
    return _getButtonColor(value, inverted);
  }

  Widget _buildHydrationInput() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _hydrationLiters.toStringAsFixed(1),
              style: const TextStyle(
                color: AppTheme.neonCyan,
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              ' L',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 24),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _hydrationLiters < 1.5
              ? '⚠️ Below target'
              : _hydrationLiters >= 2.5
              ? '✅ Great hydration'
              : 'On track',
          style: TextStyle(
            color: _hydrationLiters < 1.5
                ? Colors.orange
                : _hydrationLiters >= 2.5
                ? AppTheme.neonGreen
                : AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.neonCyan,
            inactiveTrackColor: AppTheme.surfaceColor,
            thumbColor: AppTheme.neonCyan,
            overlayColor: AppTheme.neonCyan.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: _hydrationLiters,
            max: 5,
            divisions: 10,
            onChanged: (v) => setState(() => _hydrationLiters = v),
          ),
        ),
      ],
    );
  }

  Widget _buildFocusInput() {
    final options = [
      'Sparring',
      'Technique',
      'Conditioning',
      'Recovery',
      'Strength',
      'Flexibility',
      'Rest day',
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: options.map((option) {
        final isSelected = _todayFocus == option;
        return GestureDetector(
          onTap: () => setState(() => _todayFocus = option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.neonCyan : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? AppTheme.neonCyan : AppTheme.surfaceColor,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.neonCyan.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNavButtons() {
    final isLast = _currentStep == _questions.length - 1;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.surfaceColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonCyan,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isLast ? 'Complete Check-In' : 'Next',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() {
    if (_currentStep < _questions.length - 1) {
      setState(() => _currentStep++);
    } else {
      _submitCheckIn();
    }
  }

  void _submitCheckIn() {
    // Calculate overall readiness score
    final readinessScore = _calculateReadiness();

    // Show summary dialog
    showDialog(
      context: context,
      builder: (context) => _buildSummaryDialog(readinessScore),
    );
  }

  int _calculateReadiness() {
    // Weighted calculation
    double score = 0;

    // Sleep (0-20 points)
    score += (_sleepHours / 8) * 10;
    score += (_sleepQuality / 5) * 10;

    // Energy (0-15 points)
    score += (_energyLevel / 5) * 15;

    // Pain inverted (0-15 points) - less pain = more points
    score += ((6 - _painLevel) / 5) * 15;

    // Stress inverted (0-15 points)
    score += ((6 - _stressLevel) / 5) * 15;

    // Motivation (0-15 points)
    score += (_motivation / 5) * 15;

    // Hydration (0-10 points)
    score += (_hydrationLiters / 3) * 10;

    return score.clamp(0, 100).toInt();
  }

  Widget _buildSummaryDialog(int readinessScore) {
    String status;
    Color statusColor;
    String aiMessage;

    if (readinessScore >= 80) {
      status = 'GREEN LIGHT';
      statusColor = AppTheme.neonGreen;
      aiMessage =
          "You're ready. Trust the work you've put in. Go get it today.";
    } else if (readinessScore >= 60) {
      status = 'PROCEED';
      statusColor = Colors.orange;
      aiMessage =
          "Good enough to train, but listen to your body. Adjust intensity if needed.";
    } else {
      status = 'RECOVERY MODE';
      statusColor = const Color(0xFFE17055);
      aiMessage =
          "The body's asking for rest. Recovery today means performance tomorrow.";
    }

    return Dialog(
      backgroundColor: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$readinessScore',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.psychology,
                    color: AppTheme.neonCyan,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      aiMessage,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to previous screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonCyan,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
