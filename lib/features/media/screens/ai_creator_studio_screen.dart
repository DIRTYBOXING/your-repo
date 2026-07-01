import 'package:flutter/material.dart';
import '../../../shared/services/ai_media_director_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// AI CREATOR STUDIO — Media generation powered by AiMediaDirectorService.
/// Surfaces: poster gen, social packs, trailer storyboards, asset library.
/// ═══════════════════════════════════════════════════════════════════════════

const _kBg = Color(0xFF060A14);
const _kPanel = Color(0xFF0C1226);
const _kBorder = Color(0xFF1A2744);
const _kMagenta = Color(0xFFE040FB);
const _kCyan = Color(0xFF00E5FF);
const _kGold = Color(0xFFFFD740);
const _kGreen = Color(0xFF00E676);
const _kOrange = Color(0xFFFF9100);

class AiCreatorStudioScreen extends StatefulWidget {
  const AiCreatorStudioScreen({super.key});

  @override
  State<AiCreatorStudioScreen> createState() => _AiCreatorStudioScreenState();
}

class _AiCreatorStudioScreenState extends State<AiCreatorStudioScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final AiMediaDirectorService _media = AiMediaDirectorService();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('AI CREATOR STUDIO'),
        backgroundColor: _kBg,
        foregroundColor: _kMagenta,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _kMagenta,
          labelColor: _kMagenta,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'POSTERS'),
            Tab(text: 'SOCIAL'),
            Tab(text: 'TRAILERS'),
            Tab(text: 'LIBRARY'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildPosterTab(),
          _buildSocialTab(),
          _buildTrailerTab(),
          _buildLibraryTab(),
        ],
      ),
    );
  }

  Widget _buildPosterTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGeneratorCard(
          title: 'FIGHT POSTER GENERATOR',
          icon: Icons.image,
          color: _kMagenta,
          description:
              'AI generates professional fight posters using fighter '
              'profiles, brand colors, and event data.',
          buttonLabel: 'GENERATE POSTER',
          onTap: () {},
        ),
        const SizedBox(height: 16),
        _buildTemplateGrid([
          const _Template('Championship', Icons.emoji_events, _kGold),
          const _Template('Underground', Icons.nightlife, _kMagenta),
          const _Template('Classic', Icons.sports_mma, _kCyan),
          const _Template('Neon', Icons.flash_on, _kGreen),
          const _Template('Vintage', Icons.photo_album, _kOrange),
          const _Template('Premium', Icons.diamond, _kGold),
        ]),
      ],
    );
  }

  Widget _buildSocialTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGeneratorCard(
          title: 'SOCIAL MEDIA PACK',
          icon: Icons.share,
          color: _kCyan,
          description:
              'Generate platform-optimized social posts for Instagram, '
              'X/Twitter, TikTok, and Facebook. Includes captions and hashtags.',
          buttonLabel: 'GENERATE SOCIAL PACK',
          onTap: () {},
        ),
        const SizedBox(height: 16),
        _buildPlatformRow('Instagram', Icons.camera_alt, _kMagenta),
        _buildPlatformRow('X / Twitter', Icons.tag, _kCyan),
        _buildPlatformRow('TikTok', Icons.music_note, Colors.white),
        _buildPlatformRow('Facebook', Icons.facebook, const Color(0xFF1877F2)),
        _buildPlatformRow('YouTube', Icons.play_circle, _kOrange),
      ],
    );
  }

  Widget _buildTrailerTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGeneratorCard(
          title: 'TRAILER STORYBOARD',
          icon: Icons.movie_creation,
          color: _kOrange,
          description:
              'AI creates shot-by-shot trailer storyboards for fight '
              'promos. Includes music cues, text overlays, and transition notes.',
          buttonLabel: 'GENERATE STORYBOARD',
          onTap: () {},
        ),
        const SizedBox(height: 16),
        _buildStoryboardPreview(),
      ],
    );
  }

  Widget _buildLibraryTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library, color: _kGold, size: 64),
          const SizedBox(height: 16),
          const Text(
            'ASSET LIBRARY',
            style: TextStyle(
              color: _kGold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_media.totalAssetsGenerated} total assets generated',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pillBadge('Posters', _kMagenta),
              const SizedBox(width: 8),
              _pillBadge('Social', _kCyan),
              const SizedBox(width: 8),
              _pillBadge('Trailers', _kOrange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratorCard({
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateGrid(List<_Template> templates) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: templates.length,
      itemBuilder: (context, i) => Container(
        decoration: BoxDecoration(
          color: _kPanel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: templates[i].color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(templates[i].icon, color: templates[i].color, size: 28),
            const SizedBox(height: 6),
            Text(
              templates[i].name,
              style: TextStyle(color: templates[i].color, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformRow(String name, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );
  }

  Widget _buildStoryboardPreview() {
    final shots = [
      'Opening',
      'Fighter A Intro',
      'Fighter B Intro',
      'Face-Off',
      'Highlights',
      'CTA',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SHOT BREAKDOWN',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...shots.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _kOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: const TextStyle(
                          color: _kOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    e.value,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Template {
  final String name;
  final IconData icon;
  final Color color;
  const _Template(this.name, this.icon, this.color);
}
