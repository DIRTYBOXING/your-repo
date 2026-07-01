import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// LOG TRAINING SESSION — 15 Fitness Components (Interactive)
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Each button is fully interactive and routes to a logging screen or callback.
///
class LogTrainingSessionDialog extends StatelessWidget {
  final void Function(String component) onLog;

  const LogTrainingSessionDialog({required this.onLog, super.key});

  static const List<_FitnessComponent> _components = [
    _FitnessComponent('Striking', Icons.sports_mma, Colors.redAccent),
    _FitnessComponent('Grappling', Icons.sports_kabaddi, Colors.blueAccent),
    _FitnessComponent(
      'Conditioning',
      Icons.directions_run,
      Colors.orangeAccent,
    ),
    _FitnessComponent('Sparring', Icons.flash_on, Colors.purpleAccent),
    _FitnessComponent('Recovery', Icons.spa, Colors.greenAccent),
    _FitnessComponent('Strength', Icons.fitness_center, Colors.tealAccent),
    _FitnessComponent(
      'Flexibility',
      Icons.accessibility_new,
      Colors.pinkAccent,
    ),
    _FitnessComponent('Balance', Icons.self_improvement, Colors.cyanAccent),
    _FitnessComponent('Agility', Icons.directions_walk, Colors.yellowAccent),
    _FitnessComponent('Speed', Icons.speed, Colors.deepOrangeAccent),
    _FitnessComponent('Power', Icons.bolt, Colors.amberAccent),
    _FitnessComponent('Endurance', Icons.timer, Colors.lightGreenAccent),
    _FitnessComponent('Coordination', Icons.sync, Colors.indigoAccent),
    _FitnessComponent('Reaction Time', Icons.timer_outlined, Colors.limeAccent),
    _FitnessComponent(
      'Mobility',
      Icons.directions_bike,
      Colors.lightBlueAccent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Log Training Session',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            ..._components.map((c) => _buildButton(context, c)),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, _FitnessComponent c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton.icon(
        icon: Icon(c.icon, color: c.color, size: 24),
        label: Text(
          c.name,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () => onLog(c.name),
      ),
    );
  }
}

class _FitnessComponent {
  final String name;
  final IconData icon;
  final Color color;
  const _FitnessComponent(this.name, this.icon, this.color);
}

/// Usage:
/// showDialog(
///   context: context,
///   builder: (_) => LogTrainingSessionDialog(onLog: (component) {
///     // Navigate or log for the selected component
///   }),
/// );
