import 'package:flutter/material.dart';

/// AI Head Coach Panel
/// Proactive agent for training, feedback, and super prompt customization
class AiHeadCoachPanel extends StatelessWidget {
  final void Function()? onSuperPrompt;
  const AiHeadCoachPanel({super.key, this.onSuperPrompt});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.deepPurple.shade900.withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.sports_mma, color: Colors.amberAccent, size: 32),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'AI Head Coach: Samurai',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.amberAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Samurai is your proactive AI coach—planning, tracking, and optimizing your fight camp. Ask for training plans, feedback, or motivation. Samurai integrates with all your devices and bots.',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: const Text('Customize Super Prompt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed:
                  onSuperPrompt ??
                  () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Colors.black87,
                        title: const Text(
                          'Super Prompt Setup',
                          style: TextStyle(color: Colors.amberAccent),
                        ),
                        content: const Text(
                          'Describe your ideal fight camp, goals, and preferences. Samurai will adapt all plans and feedback to your style.',
                        ),
                        actions: [
                          TextButton(
                            child: const Text(
                              'OK',
                              style: TextStyle(color: Colors.amberAccent),
                            ),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    );
                  },
            ),
          ],
        ),
      ),
    );
  }
}
