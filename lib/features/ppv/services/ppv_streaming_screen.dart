import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PpvStreamingScreen extends StatelessWidget {
  final String eventId;

  const PpvStreamingScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    // TODO: Initialize MUX Video Player or AWS IVS Player here using the streamUrl
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            const Center(
              child: Text(
                "STREAM VIDEO PLAYER",
                style: TextStyle(color: AppColors.neonRed),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
