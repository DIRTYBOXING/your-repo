import 'package:flutter/material.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/neon_glow_button.dart';

class ShowmakerProfileScreen extends StatelessWidget {
  final String creatorId;

  const ShowmakerProfileScreen({Key? key, required this.creatorId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock data based on creator role (MC, Ring Girl, Commentator)
    final bool isMC = creatorId.contains('mc');
    final String name = isMC ? 'Bruce "The Voice" Buffer' : 'Arianny Celeste';
    final String role = isMC ? 'VETERAN RINGMASTER & M.C.' : 'FEATURED RING GIRL & CREATOR';
    final Color themeColor = isMC ? Colors.orangeAccent : Colors.pinkAccent;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    isMC 
                        ? 'https://images.unsplash.com/photo-1570158268183-d296b2892211?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80' 
                        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role,
                          style: TextStyle(
                            color: themeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: NeonGlowButton(
                          text: 'Subscribe (500 FIT)',
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: themeColor),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.message, color: themeColor),
                          onPressed: () {},
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('Events', '142', themeColor),
                      _buildStatColumn('Fans', '1.2M', themeColor),
                      _buildStatColumn('Reels', '84', themeColor),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // The Magic (Content Grid)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'THE MAGIC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Icon(Icons.video_library, color: themeColor),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              'https://picsum.photos/id/${index * 10 + 20}/200/300',
                              fit: BoxFit.cover,
                            ),
                            const Center(
                              child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 36),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  // Upcoming Appearances
                  const Text(
                    'UPCOMING APPEARANCES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    child: ListTile(
                      leading: Icon(Icons.event, color: themeColor),
                      title: const Text('DFC 204: Rumble in the Valley', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('Las Vegas, NV • Saturday 8PM', style: TextStyle(color: Colors.white54)),
                      trailing: Icon(Icons.arrow_forward_ios, color: themeColor, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}
