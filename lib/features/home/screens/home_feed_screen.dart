import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_panel.dart';
import '../../../core/theme/glow_effects.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC TIKTOK-STYLE HOME FEED
/// Highly engaging, vertical scroll focused on PPV, Fights, and Creators.
/// Fully UI-Friendly, highly logical placement of social + monetization triggers.
/// ═══════════════════════════════════════════════════════════════════════════
class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({Key? key}) : super(key: key);

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final PageController _pageController = PageController();

  // Mock feed items representing the mixed content approach
  final List<Map<String, dynamic>> _feedData = [
    {
      'type': 'ppv_trailer',
      'username': '@ufc_pass',
      'title': 'UFC 310: Title Fight Trailer',
      'description': 'The biggest clash of the year. Who takes the crown? 👑🔥',
      'videoUrl': 'assets/videos/trailer_1.mp4',
      'likes': '24.5K',
      'comments': '1.2K',
      'isPPV': true,
      'ppvPrice': '\$69.99',
    },
    {
      'type': 'fighter_highlight',
      'username': '@lightning_mma',
      'title': 'Training Camp Day 12',
      'description': 'Sharpening the elbows and timing. #MuayThai #Grind',
      'videoUrl': 'assets/videos/training_1.mp4',
      'likes': '5.2K',
      'comments': '342',
      'isPPV': false,
    },
    {
      'type': 'creator_breakdown',
      'username': '@fight_nerd',
      'title': 'Tactical Breakdown: The Check Hook',
      'description': 'Why this strike changes everything inside the pocket.',
      'videoUrl': 'assets/videos/breakdown_1.mp4',
      'likes': '890',
      'comments': '45',
      'isPPV': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      extendBodyBehindAppBar: true,
      // Minimal transparent transparent App Bar for global search/filters
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTab('Following', false),
            const SizedBox(width: 16),
            _buildTab('For You', true),
            const SizedBox(width: 16),
            _buildTab('PPV', false),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _feedData.length,
        itemBuilder: (context, index) {
          return _FeedVideoItem(data: _feedData[index]);
        },
      ),
    );
  }

  Widget _buildTab(String text, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white60,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            fontSize: 16,
          ),
        ),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 4),
            height: 3,
            width: 24,
            decoration: BoxDecoration(
              color: AppColors.neonCyan,
              borderRadius: BorderRadius.circular(2),
              boxShadow: NeonGlow.softCyan(),
            ),
          ),
      ],
    );
  }
}

/// A single full-screen video item in the feed.
class _FeedVideoItem extends StatelessWidget {
  final Map<String, dynamic> data;

  const _FeedVideoItem({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Background Video (Simulated with Gradient/Image for now)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.bgPrimary,
                  AppColors.bgSecondary,
                  AppColors.bgTertiary,
                ],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.play_circle_outline,
                size: 64,
                color: Colors.white24,
              ),
            ),
          ),
        ),

        // Bottom heavy gradient to make text readable UI-friendly
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 300,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
          ),
        ),

        // 2. Right Side: Social Action Buttons
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAvatarBtn(),
              const SizedBox(height: 24),
              _buildActionBtn(
                Icons.favorite,
                data['likes'],
                AppColors.neonMagenta,
              ),
              const SizedBox(height: 20),
              _buildActionBtn(Icons.comment, data['comments'], Colors.white),
              const SizedBox(height: 20),
              _buildActionBtn(Icons.share, 'Share', Colors.white),
              if (data['type'] == 'creator_breakdown') ...[
                const SizedBox(height: 20),
                _buildActionBtn(
                  Icons.monetization_on,
                  'Tip',
                  AppColors.neonLime,
                ),
              ],
            ],
          ),
        ),

        // 3. Bottom Left: Video Info & PPV CTA (Logical structure)
        Positioned(
          left: 16,
          bottom: 24,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CTA Overlay if it's a PPV
              if (data['isPPV'] == true) ...[
                _buildPPVCard(),
                const SizedBox(height: 12),
              ],
              Text(
                data['username'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                data['title'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 36),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarBtn() {
    return SizedBox(
      width: 50,
      height: 60,
      child: Stack(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.neonCyan, width: 2),
              boxShadow: NeonGlow.softCyan(),
              color: AppColors.cardBackground,
            ),
            child: const Icon(Icons.person, color: AppColors.textSecondary),
          ),
          Positioned(
            bottom: 0,
            left: 15,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.neonMagenta,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Beautiful UI-friendly PPV purchasing block embedded right into the feed
  Widget _buildPPVCard() {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(16),
      borderColor: AppColors.neonMagenta.withValues(alpha: 0.5),
      borderWidth: 1.5,
      backgroundColor: Colors.black.withValues(alpha: 0.4),
      shadows: NeonGlow.softMagenta(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: AppColors.neonOrange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LIVE PPV EVENT',
                style: TextStyle(
                  color: AppColors.neonMagenta,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                data['ppvPrice'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.gradientPPV,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Unlock',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
