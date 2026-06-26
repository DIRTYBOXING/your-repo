import 'package:flutter/material.dart';

/// A circular marker widget for mentors on the map.
///
/// Used to render mentor-specific markers with a coloured circle,
/// icon, and tap callback. Works with the DFC neon theme.
class MentorMarker extends StatelessWidget {
  final String name;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const MentorMarker({
    required this.name,
    required this.onTap,
    this.color = const Color(0xFF7C4DFF), // violet default
    this.icon = Icons.person,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
