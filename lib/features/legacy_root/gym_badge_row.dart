import 'package:flutter/material.dart';

class GymBadgeRow extends StatelessWidget {
  const GymBadgeRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBadge(Icons.star, 'Elite', Colors.amber),
          _buildBadge(Icons.shield, 'Defense', Colors.blueAccent),
          _buildBadge(
            Icons.local_fire_department,
            'Striking',
            Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
