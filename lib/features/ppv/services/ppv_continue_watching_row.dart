import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PpvContinueWatchingRow extends StatelessWidget {
  final String userId;

  const PpvContinueWatchingRow({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // TODO: Use PpvService.getContinueWatching(userId) StreamBuilder here
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CONTINUE WATCHING',
          style: TextStyle(color: AppColors.neonCyan, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: Center(child: Text("Watch history will appear here.", style: TextStyle(color: Colors.white.withOpacity(0.5)))),
        ),
      ],
    );
  }
}