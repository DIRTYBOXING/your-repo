import 'package:flutter/material.dart';

class FeaturedCreatorsCarousel extends StatelessWidget {
  const FeaturedCreatorsCarousel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FIT CREATORS & RING GIRLS',
                style: TextStyle(
                  color: Colors.pinkAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text('See All', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            children: [
              _buildCreatorAvatar('Arianny', 'https://i.pravatar.cc/150?img=1', true),
              _buildCreatorAvatar('Brittney', 'https://i.pravatar.cc/150?img=5', false),
              _buildCreatorAvatar('Luciana', 'https://i.pravatar.cc/150?img=9', true),
              _buildCreatorAvatar('Camila', 'https://i.pravatar.cc/150?img=12', true),
              _buildCreatorAvatar('Jhenny', 'https://i.pravatar.cc/150?img=16', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreatorAvatar(String name, String imageUrl, bool isLive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isLive
                  ? const LinearGradient(colors: [Colors.pinkAccent, Colors.purpleAccent])
                  : null,
              border: !isLive ? Border.all(color: Colors.white24, width: 2) : null,
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundImage: NetworkImage(imageUrl),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          if (isLive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.pinkAccent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 8)),
            )
        ],
      ),
    );
  }
}
