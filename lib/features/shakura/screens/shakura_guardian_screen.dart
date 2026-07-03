import 'package:flutter/material.dart';
import '../widgets/shakura_awareness_tap.dart';

class ShakuraGuardianScreen extends StatefulWidget {
  const ShakuraGuardianScreen({super.key});

  @override
  State<ShakuraGuardianScreen> createState() => _ShakuraGuardianScreenState();
}

class _ShakuraGuardianScreenState extends State<ShakuraGuardianScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _avatarController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    // A slow, calming breathe effect for the guardian avatar
    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.1, end: 0.4).animate(
      CurvedAnimation(parent: _avatarController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Guardian Avatar with animated glow
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pinkAccent.withValues(alpha: _glowAnimation.value),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.pinkAccent,
                      child: Icon(Icons.female, color: Colors.white, size: 40),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              const Text(
                "Shakura — Guardian Mode Active",
                style: TextStyle(
                  color: Colors.pinkAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // Mood Scanner
              const _MoodScanner(),

              const SizedBox(height: 20),

              // Stress Pulse Indicator
              const _StressPulse(),

              const SizedBox(height: 20),

              // Awareness Tap Button
              ShakuraAwarenessTap(
                onTap: () {
                  // Awareness logic will be injected here
                },
              ),

              const SizedBox(height: 20),

              // Journal Quick Entry
              const _JournalQuickEntry(),
            ],
          ),
        ),
      ),
    );
  }
}

// Mood Scanner Widget
class _MoodScanner extends StatelessWidget {
  const _MoodScanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
      ),
      child: const Column(
        children: [
          Text(
            "Mood Check",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          SizedBox(height: 10),
          Icon(Icons.favorite_outline, color: Colors.pinkAccent, size: 28),
        ],
      ),
    );
  }
}

// Stress Pulse Widget
class _StressPulse extends StatefulWidget {
  const _StressPulse();

  @override
  State<_StressPulse> createState() => _StressPulseState();
}

class _StressPulseState extends State<_StressPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Simulate a gentle heartbeat pulse (approx 60bpm)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text(
            "Stress Pulse",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 10),
          ScaleTransition(
            scale: _pulseAnimation,
            child: const Icon(Icons.monitor_heart, color: Colors.pinkAccent, size: 28),
          ),
        ],
      ),
    );
  }
}

// Journal Quick Entry Widget
class _JournalQuickEntry extends StatelessWidget {
  const _JournalQuickEntry();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit, color: Colors.pinkAccent, size: 18),
          SizedBox(width: 8),
          Text(
            "Journal Entry",
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
