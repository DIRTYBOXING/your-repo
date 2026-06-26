import 'package:flutter/material.dart';

class SmartCoachCard extends StatelessWidget {
  final String advice;

  const SmartCoachCard({super.key, required this.advice});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1C23),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.psychology, color: Colors.blueAccent, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                advice,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
