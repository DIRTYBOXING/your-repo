import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV CAMERA SWITCHER — MULTI-CAMERA READY
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Horizontal list of available camera feeds:
/// - Octagon cam (main)
/// - Crowd cam
/// - Replay/slow-mo
/// - Fighter POV (future)
///
/// Neon selection glow with smooth fade transitions.
///
/// ═══════════════════════════════════════════════════════════════════════════

class PPVCameraSwitcher extends StatefulWidget {
  final ValueNotifier<int> selectedCamera;
  final Function(int) onCameraSwitch;

  /// Camera feed names (default: common MMA angles)
  final List<String> cameras;

  const PPVCameraSwitcher({
    super.key,
    required this.selectedCamera,
    required this.onCameraSwitch,
    this.cameras = const [
      'OCTAGON',
      'CROWD',
      'REPLAY',
    ],
  });

  @override
  State<PPVCameraSwitcher> createState() => _PPVCameraSwitcherState();
}

class _PPVCameraSwitcherState extends State<PPVCameraSwitcher> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: const ColorFilter.mode(Colors.black26, BlendMode.srcOver),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DesignTokens.neonCyan.withValues(alpha: 0.2),
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              widget.cameras.length,
              (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ValueListenableBuilder<int>(
                    valueListenable: widget.selectedCamera,
                    builder: (context, selected, _) {
                      final isActive = selected == index;

                      return GestureDetector(
                        onTap: () {
                          widget.selectedCamera.value = index;
                          widget.onCameraSwitch(index);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? DesignTokens.neonCyan.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isActive
                                  ? DesignTokens.neonCyan
                                  : Colors.white.withValues(alpha: 0.2),
                              width: isActive ? 2 : 1,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: DesignTokens.neonCyan
                                          .withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            widget.cameras[index],
                            style: TextStyle(
                              color: isActive
                                  ? DesignTokens.neonCyan
                                  : Colors.white.withValues(alpha: 0.5),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
