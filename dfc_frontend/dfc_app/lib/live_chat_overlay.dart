import 'package:flutter/material.dart';
import '../../../../dfc_theme.dart';

class LiveChatOverlay extends StatelessWidget {
  const LiveChatOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withValues(alpha: 0.0), Colors.black.withValues(alpha: 0.8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: 15,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(text: 'FightFan99: ', style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                        TextSpan(text: 'This round is insane! 🔥', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
              child: const TextField(
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(hintText: "Say something...", hintStyle: TextStyle(color: AppColors.textMuted), border: InputBorder.none),
              ),
            ),
          ),
        ],
      ),
    );
  }
}