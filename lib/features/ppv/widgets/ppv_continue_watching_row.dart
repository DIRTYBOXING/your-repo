import 'package:flutter/material.dart';

class PpvContinueWatchingRow extends StatelessWidget {
  const PpvContinueWatchingRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 300,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.play_circle_outline, size: 64, color: Colors.white54),
            ),
          );
        },
      ),
    );
  }
}
