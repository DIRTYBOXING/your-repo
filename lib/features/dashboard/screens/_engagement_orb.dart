import 'dart:math' as math;
import 'package:flutter/material.dart';

class EngagementOrb extends StatefulWidget {
  const EngagementOrb({super.key});

  @override
  State<EngagementOrb> createState() => EngagementOrbState();
}

class EngagementOrbState extends State<EngagementOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset _position = const Offset(60, 420);
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showXPModal() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.emoji_events, color: Colors.amberAccent, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'XP Rewards Unlocked!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'You earned 50 XP for exploring the dashboard. Keep interacting to level up and unlock exclusive features!',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const LinearProgressIndicator(
                  value: 0.7,
                  backgroundColor: Colors.white12,
                  color: Colors.cyanAccent,
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Level 3 — 70% to next reward',
                  style: TextStyle(color: Colors.cyanAccent, fontSize: 13),
                ),
                const SizedBox(height: 18),
                Divider(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(
                      Icons.health_and_safety,
                      color: Colors.greenAccent,
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Wellness Resources',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '• Treatments: Personalized plans for nutrition, sleep, pain, and recovery.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 6),
                const Text(
                  '• Doctors & Prescribers: Connect with certified professionals for advice and prescriptions.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 6),
                const Text(
                  '• Dispensaries: Find trusted dispensaries for supplements, CBD, and wellness products.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.campaign, color: Colors.greenAccent, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Coming soon: Local wellness offers, advertising, and exclusive deals for your well-being!',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _dragging = true),
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        onPanEnd: (_) => setState(() => _dragging = false),
        onTap: _showXPModal,
        child: IgnorePointer(
          ignoring: _dragging,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Neon glow
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(
                            alpha: 0.38 + 0.18 * math.sin(t * 2 * math.pi),
                          ),
                          blurRadius: 32 + 12 * math.sin(t * 2 * math.pi),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  // Main orb
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Colors.cyanAccent,
                          Colors.blueAccent,
                          Colors.purpleAccent,
                        ],
                        stops: [0.2, 0.7, 1.0],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.touch_app,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  // Particle effect
                  ...List.generate(12, (i) {
                    final angle = i * 2 * math.pi / 12 + t * 2 * math.pi;
                    final radius = 38 + 8 * math.sin(t * 2 * math.pi + i);
                    return Positioned(
                      left: 36 + radius * math.cos(angle),
                      top: 36 + radius * math.sin(angle),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.cyanAccent.withValues(
                            alpha: 0.7 - 0.4 * math.sin(t * 2 * math.pi + i),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withValues(alpha: 0.18),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
