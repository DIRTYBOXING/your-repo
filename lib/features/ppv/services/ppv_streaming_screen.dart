import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glow_effects.dart';
import '../../../core/theme/glass_panel.dart';

class PpvStreamingScreen extends StatefulWidget {
  final String eventId;

  const PpvStreamingScreen({super.key, required this.eventId});

  @override
  State<PpvStreamingScreen> createState() => _PpvStreamingScreenState();
}

class _PpvStreamingScreenState extends State<PpvStreamingScreen> with SingleTickerProviderStateMixin {
  int _hypeCount = 0;
  bool _isVolumetricMode = false;
  bool _isFlashing = false;
  late AnimationController _flashController;
  late Animation<Color?> _flashColor;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _flashColor = ColorTween(
      begin: Colors.transparent,
      end: Colors.redAccent.withValues(alpha: 0.6),
    ).animate(_flashController);
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  Future<void> _triggerHype() async {
    setState(() {
      _hypeCount++;
    });
    // Haptic Feedback for each hype tap
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50, amplitude: 60);
    }
  }

  Future<void> _triggerKoFlash() async {
    // Heavy haptics for a KO
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 200, 100, 400]);
    }
    
    // Screen flashing strobe effect
    setState(() => _isFlashing = true);
    for (int i = 0; i < 6; i++) {
      await _flashController.forward();
      await _flashController.reverse();
    }
    setState(() => _isFlashing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Simulated Video Stream Layer
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isVolumetricMode ? Icons.view_in_ar : Icons.play_circle_fill,
                    size: 80,
                    color: _isVolumetricMode ? AppColors.neonCyan : AppColors.neonRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isVolumetricMode 
                        ? "NVIDIA OMNIVERSE VOLUMETRIC FEED LIVE"
                        : "MUX / AWS STREAMPAY LIVE STREAM PLAYING",
                        style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Event ID: ${widget.eventId}",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),

            // 2. The KO Flash Overlay (only visible during KO)
            if (_isFlashing)
              AnimatedBuilder(
                animation: _flashColor,
                builder: (context, child) {
                  return Container(
                    color: _flashColor.value,
                  );
                },
              ),

            // 3. UI Controls
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // NVIDIA Volumetric Camera Toggle
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  setState(() => _isVolumetricMode = !_isVolumetricMode);
                  if (_isVolumetricMode) {
                    Vibration.vibrate(duration: 100);
                  }
                },
                child: GlassPanel(
                  backgroundColor: _isVolumetricMode ? AppColors.neonCyan.withValues(alpha: 0.2) : AppColors.glassMedium,
                  borderColor: _isVolumetricMode ? AppColors.neonCyan : Colors.white24,
                  shadows: _isVolumetricMode ? NeonGlow.softCyan() : null,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.threed_rotation, color: _isVolumetricMode ? AppColors.neonCyan : Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'VOLUMETRIC',
                        style: TextStyle(
                          color: _isVolumetricMode ? AppColors.neonCyan : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Simulate KO Button (For Demo/Admin Purposes)
            Positioned(
              top: 80,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: _triggerKoFlash,
                icon: const Icon(Icons.flash_on, color: Colors.white),
                label: const Text('TEST KO FLASH'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonRed,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            // 4. Interactive Hype Engine (Bottom Right)
            Positioned(
              bottom: 30,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Floating floating Hype counters could animate up here
                  Text(
                    '$_hypeCount',
                    style: const TextStyle(
                      color: AppColors.neonMagenta,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: AppColors.neonMagenta, blurRadius: 10)
                      ]
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _triggerHype,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.neonMagenta.withValues(alpha: 0.2),
                        border: Border.all(color: AppColors.neonMagenta, width: 2),
                        boxShadow: NeonGlow.mediumMagenta(),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.whatshot,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
