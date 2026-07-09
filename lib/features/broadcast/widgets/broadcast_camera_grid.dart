import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../models/broadcast_control_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// BROADCAST CAMERA GRID — Multi-Angle Camera Previews
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Shows grid of all camera feeds with:
///   - Live thumbnail previews
///   - Active camera highlight (neon glow)
///   - Tap-to-switch camera
///   - Camera info overlay
///   - Status indicators
///
/// ═══════════════════════════════════════════════════════════════════════════

class BroadcastCameraGrid extends StatelessWidget {
  final List<CameraProfile> cameras;
  final String activeCameraId;
  final void Function(String cameraId) onCameraSelected;

  const BroadcastCameraGrid({
    super.key,
    required this.cameras,
    required this.activeCameraId,
    required this.onCameraSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 16 / 10,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cameras.length,
      itemBuilder: (context, index) {
        final camera = cameras[index];
        final isActive = camera.id == activeCameraId;

        return _CameraPreviewCard(
          camera: camera,
          isActive: isActive,
          onTap: () => onCameraSelected(camera.id),
        );
      },
    );
  }
}

/// Individual camera preview card
class _CameraPreviewCard extends StatelessWidget {
  final CameraProfile camera;
  final bool isActive;
  final VoidCallback onTap;

  const _CameraPreviewCard({
    required this.camera,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          border: Border.all(
            color: isActive ? DesignTokens.neonCyan : Colors.white12,
            width: isActive ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: DesignTokens.neonCyan.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            // ── Camera Placeholder ──
            Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getAngleIcon(camera.angle),
                      size: 32,
                      color: Colors.white30,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'CAM FEED',
                      style: TextStyle(color: Colors.white20, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),

            // ── Camera Info Overlay ──
            Positioned(
              left: 8,
              top: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        camera.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getAngleName(camera.angle),
                        style: TextStyle(color: Colors.white60, fontSize: 10),
                      ),
                    ],
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.neonCyan.withOpacity(0.2),
                        border: Border.all(
                          color: DesignTokens.neonCyan,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: DesignTokens.neonCyan,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Active Indicator Glow ──
            if (isActive)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: DesignTokens.neonCyan.withOpacity(0.1),
                      width: 6,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

            // ── Tap Indicator ──
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  border: Border.all(color: Colors.white20, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isActive ? '✓ LIVE' : '→ TAP',
                  style: TextStyle(
                    color: isActive ? DesignTokens.neonCyan : Colors.white60,
                    fontSize: 9,
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

  String _getAngleName(CameraAngle angle) {
    switch (angle) {
      case CameraAngle.wide:
        return 'Wide Angle';
      case CameraAngle.closeup:
        return 'Closeup';
      case CameraAngle.ground:
        return 'Ground Angle';
      case CameraAngle.overhead:
        return 'Overhead';
      case CameraAngle.replay:
        return 'Replay';
    }
  }

  IconData _getAngleIcon(CameraAngle angle) {
    switch (angle) {
      case CameraAngle.wide:
        return Icons.panorama_wide;
      case CameraAngle.closeup:
        return Icons.zoom_in;
      case CameraAngle.ground:
        return Icons.height;
      case CameraAngle.overhead:
        return Icons.zoom_out;
      case CameraAngle.replay:
        return Icons.replay;
    }
  }
}
