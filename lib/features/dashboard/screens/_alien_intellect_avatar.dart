import 'dart:math' as math;
import 'package:flutter/material.dart';

class AlienIntellectAvatar extends StatefulWidget {
  const AlienIntellectAvatar({super.key});

  @override
  State<AlienIntellectAvatar> createState() => AlienIntellectAvatarState();
}

class AlienIntellectAvatarState extends State<AlienIntellectAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset _position = const Offset(320, 120);
  bool _dragging = false;
  final List<String> _wisdom = [
    '“The mind is a galaxy. Expand it.”',
    '“Observe. Adapt. Transcend.”',
    '“True strength is the union of intellect and spirit.”',
    '“You are the anomaly. Embrace it.”',
    '“Every challenge is a portal to a higher self.”',
    '“From chaos, create new order.”',
    '“Your data is your destiny.”',
    '“The universe rewards the curious.”',
    '“Think beyond the simulation.”',
    '“You are not from here. That is your power.”',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showWisdomModal() {
    final wisdom = (_wisdom..shuffle()).first;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withValues(alpha: 0.96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.greenAccent, size: 54),
              const SizedBox(height: 18),
              const Text(
                'Alien Intellect',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                wisdom,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text('Close'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy + 24 * math.sin(_controller.value * 2 * math.pi),
      child: GestureDetector(
        onPanStart: (_) => setState(() => _dragging = true),
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        onPanEnd: (_) => setState(() => _dragging = false),
        onTap: _showWisdomModal,
        child: IgnorePointer(
          ignoring: _dragging,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Alien glow
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withValues(
                            alpha: 0.32 + 0.18 * math.sin(t * 2 * math.pi),
                          ),
                          blurRadius: 38 + 12 * math.sin(t * 2 * math.pi),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  // Alien avatar (stylized)
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Colors.greenAccent,
                          Colors.tealAccent,
                          Colors.black,
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
                        Icons.psychology,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  // Orbiting intellect sparks
                  ...List.generate(7, (i) {
                    final angle = i * 2 * math.pi / 7 + t * 2 * math.pi;
                    final radius = 44 + 8 * math.sin(t * 2 * math.pi + i);
                    return Positioned(
                      left: 44 + radius * math.cos(angle),
                      top: 44 + radius * math.sin(angle),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.greenAccent.withValues(
                            alpha: 0.7 - 0.4 * math.sin(t * 2 * math.pi + i),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withValues(alpha: 0.18),
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
