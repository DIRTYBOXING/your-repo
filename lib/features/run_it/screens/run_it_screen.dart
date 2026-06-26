import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/app_logos.dart';
import '../../../shared/services/youtube_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// RUN IT — RUNIT Collision Sport  💥🏃
/// Australia's viral 1v1 collision tackle sport — YouTube-style video hub
/// Runner vs Tackler · 20m Battlefield · Pure Impact
/// ═══════════════════════════════════════════════════════════════════════════

// ── Accent colours ─────────────────────────────────────────────────────
const _kGreen = Color(0xFF00E676);
const _kGreenDim = Color(0xFF00BFA5);
const _kRed = Color(0xFFFF1744);
const _kOverlay = Color(0xFF0D1B2A);

// Keep embedded playback limited to IDs verified as playable.
// NOTE: Awaiting official RUNIT Championship YouTube channel verification
const Set<String> _kVerifiedRunItYoutubeIds = {};

class RunItScreen extends StatefulWidget {
  const RunItScreen({super.key});
  @override
  State<RunItScreen> createState() => _RunItScreenState();
}

class _RunItScreenState extends State<RunItScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _activeCategory = 'FOR YOU';
  int _sortIndex = 0; // 0=trending, 1=latest, 2=most viewed

  static const _categories = [
    'FOR YOU',
    'HIGHLIGHTS',
    'MATCHES',
    'TRAINING',
    'REACTIONS',
    'NEWS',
  ];

  static const _sortLabels = ['Trending', 'Latest', 'Most Viewed'];

  // ── Channel data ─────────────────────────────────────────────────────
  static const _channels = [
    _Channel(
      name: 'RUNIT Championship',
      handle: '@RUNITChampionship',
      avatar: '🏆',
      subs: '245K',
      verified: true,
    ),
    _Channel(
      name: 'The Project',
      handle: '@TheProjectTV',
      avatar: '📺',
      subs: '309K',
      verified: true,
    ),
    _Channel(
      name: 'Brian Sutterer MD',
      handle: '@BrianSuttererMD',
      avatar: '🩺',
      subs: '1.2M',
      verified: true,
    ),
    _Channel(
      name: 'RUNIT Australia',
      handle: '@RUNITau',
      avatar: '🇦🇺',
      subs: '89K',
      verified: true,
    ),
    _Channel(
      name: 'Combat Sports Daily',
      handle: '@CombatSportsDaily',
      avatar: '🥊',
      subs: '512K',
      verified: false,
    ),
    _Channel(
      name: 'DFC Analytics',
      handle: '@DataFightCentral',
      avatar: '📊',
      subs: '34K',
      verified: true,
    ),
  ];

  // ── Video data (YouTube-style) ───────────────────────────────────────
  List<_Video> get _allVideos => [
    // NOTE: First video removed - was pop culture content, not RUNIT sport
    // Awaiting official RUNIT Championship footage
    _Video(
      title: 'What is RUNIT? Australia\'s Craziest New Sport Explained',
      channel: _channels[1],
      views: '4.8M',
      uploaded: '6 months ago',
      duration: '8:15',
      category: 'FOR YOU',
      isLive: false,
      thumbnailGradient: [const Color(0xFF0D47A1), const Color(0xFF01579B)],
      thumbnailIcon: Icons.live_tv,
      youtubeId: 'WbNho0UJbOk',
      youtubeUrl: 'https://www.youtube.com/watch?v=WbNho0UJbOk',
      description:
          'The Project investigates RUNIT — the collision sport '
          'taking Australia by storm. Two players, 20 metres, one massive impact.',
    ),
    _Video(
      title: 'Doctor Reacts to RUNIT Collisions — Is This Safe?',
      channel: _channels[2],
      views: '3.2M',
      uploaded: '5 months ago',
      duration: '14:33',
      category: 'REACTIONS',
      isLive: false,
      thumbnailGradient: [const Color(0xFFB71C1C), const Color(0xFF880E4F)],
      thumbnailIcon: Icons.medical_services,
      youtubeId: 'pOkNe7tXh0Y',
      youtubeUrl: 'https://www.youtube.com/watch?v=pOkNe7tXh0Y',
      description:
          'Sports medicine doctor breaks down the biomechanics '
          'of RUNIT tackles. Concussion risks, neck injuries, and why athletes keep coming back.',
    ),
    _Video(
      title: 'RUNIT Training Camp — How Runners Build Impact Power',
      channel: _channels[3],
      views: '890K',
      uploaded: '2 months ago',
      duration: '22:10',
      category: 'TRAINING',
      isLive: false,
      thumbnailGradient: [const Color(0xFFE65100), const Color(0xFFBF360C)],
      thumbnailIcon: Icons.fitness_center,
      youtubeId: 'VjRqNjFCX3g',
      youtubeUrl: 'https://www.youtube.com/watch?v=VjRqNjFCX3g',
      description:
          'Inside the training facility where RUNIT athletes '
          'prepare for the battlefield. Strength, speed, and collision conditioning.',
    ),
    _Video(
      title: 'BIGGEST HITS of RUNIT 2024 — Runner vs Tackler',
      channel: _channels[0],
      views: '5.7M',
      uploaded: '4 months ago',
      duration: '12:08',
      category: 'HIGHLIGHTS',
      isLive: false,
      thumbnailGradient: [const Color(0xFFFF6F00), const Color(0xFFF57F17)],
      thumbnailIcon: Icons.local_fire_department,
      youtubeId: 'UBaH7KDxPwA',
      youtubeUrl: 'https://www.youtube.com/watch?v=UBaH7KDxPwA',
      description:
          'The most devastating collisions from RUNIT 2024. '
          'Full speed. No pads. Pure impact. Runner charges down the 20m battlefield.',
    ),
    _Video(
      title: 'RUNIT Championship — Grand Final LIVE',
      channel: _channels[0],
      views: '1.4M',
      uploaded: 'Streamed 2 weeks ago',
      duration: '2:34:15',
      category: 'MATCHES',
      isLive: false,
      thumbnailGradient: [const Color(0xFF1B5E20), const Color(0xFF004D40)],
      thumbnailIcon: Icons.emoji_events,
      youtubeId: 'hBMc9s8oDWE',
      youtubeUrl: 'https://www.youtube.com/watch?v=hBMc9s8oDWE',
      description:
          'The 2024 Grand Final — Australia vs New Zealand. '
          'Winner takes all on the 20x4m battlefield.',
    ),
    _Video(
      title: 'Ex-NRL Star\'s First RUNIT Match — "Hardest Hit I\'ve Taken"',
      channel: _channels[4],
      views: '1.8M',
      uploaded: '1 month ago',
      duration: '11:45',
      category: 'FOR YOU',
      isLive: false,
      thumbnailGradient: [const Color(0xFF4A148C), const Color(0xFF311B92)],
      thumbnailIcon: Icons.person,
      youtubeId: 'UlD4jn1G2rA',
      youtubeUrl: 'https://www.youtube.com/watch?v=UlD4jn1G2rA',
      description:
          'Former NRL player tries RUNIT for the first time. '
          'Runner position. 10m sprint zone. Full speed collision at the impact point.',
    ),
    _Video(
      title: 'RUNIT Rules Explained in 3 Minutes',
      channel: _channels[3],
      views: '2.4M',
      uploaded: '8 months ago',
      duration: '3:22',
      category: 'FOR YOU',
      isLive: false,
      thumbnailGradient: [const Color(0xFF00695C), const Color(0xFF004D40)],
      thumbnailIcon: Icons.rule,
      youtubeId: 'NxSGbLXfbw8',
      youtubeUrl: 'https://www.youtube.com/watch?v=NxSGbLXfbw8',
      description:
          '20m x 4m battlefield. Runner carries the ball. '
          'Tackler must stop them. No stepping, no swerving — run it straight. '
          'The collision sport born in Australia.',
    ),
    _Video(
      title: 'DFC x RUNIT: AI Collision Analytics Deep Dive',
      channel: _channels[5],
      views: '156K',
      uploaded: '3 weeks ago',
      duration: '16:50',
      category: 'FOR YOU',
      isLive: false,
      thumbnailGradient: [const Color(0xFF006064), const Color(0xFF00838F)],
      thumbnailIcon: Icons.analytics,
      youtubeId: '6zT4bUztXYw',
      youtubeUrl: 'https://www.youtube.com/watch?v=6zT4bUztXYw',
      description:
          'DataFightCentral breaks down RUNIT collision data — '
          'impact force, tackle success rates, runner speed analysis, injury patterns.',
    ),
    _Video(
      title: 'Women\'s RUNIT Championship 2024 — All Knockdowns',
      channel: _channels[0],
      views: '980K',
      uploaded: '2 months ago',
      duration: '9:30',
      category: 'HIGHLIGHTS',
      isLive: false,
      thumbnailGradient: [const Color(0xFFAD1457), const Color(0xFF880E4F)],
      thumbnailIcon: Icons.whatshot,
      youtubeId: 'nJJq6MlWddY',
      youtubeUrl: 'https://www.youtube.com/watch?v=nJJq6MlWddY',
      description:
          'Every knockdown from the Women\'s RUNIT Championship. '
          'Speed, power, technique — the women\'s division is no joke.',
    ),
    _Video(
      title: 'RUNIT Battlefield Setup — Behind the Scenes',
      channel: _channels[3],
      views: '340K',
      uploaded: '5 weeks ago',
      duration: '7:18',
      category: 'TRAINING',
      isLive: false,
      thumbnailGradient: [const Color(0xFF33691E), const Color(0xFF1B5E20)],
      thumbnailIcon: Icons.construction,
      youtubeId: 'AcaKMq8T5fE',
      youtubeUrl: 'https://www.youtube.com/watch?v=AcaKMq8T5fE',
      description:
          'How the 20x4m RUNIT battlefield is built. '
          'The run zone, impact zone, and tackler position explained.',
    ),
    _Video(
      title: 'Why RUNIT is Going Viral — TikTok Compilation',
      channel: _channels[4],
      views: '8.3M',
      uploaded: '7 months ago',
      duration: '6:55',
      category: 'FOR YOU',
      isLive: false,
      thumbnailGradient: [const Color(0xFF263238), const Color(0xFF37474F)],
      thumbnailIcon: Icons.trending_up,
      youtubeId: 'aPOQCJlfvdA',
      youtubeUrl: 'https://www.youtube.com/watch?v=aPOQCJlfvdA',
      description:
          'The best RUNIT clips from TikTok that broke the internet. '
          'Millions of views. One sport. Pure collision.',
    ),
    _Video(
      title: 'RUNIT Physio: Recovery After a Collision Match',
      channel: _channels[2],
      views: '670K',
      uploaded: '6 weeks ago',
      duration: '19:22',
      category: 'REACTIONS',
      isLive: false,
      thumbnailGradient: [const Color(0xFF1A237E), const Color(0xFF0D47A1)],
      thumbnailIcon: Icons.healing,
      youtubeId: 'Gd5fA3vX8uw',
      youtubeUrl: 'https://www.youtube.com/watch?v=Gd5fA3vX8uw',
      description:
          'What happens to the body after a RUNIT match? '
          'Scans, recovery protocols, and why doctors are watching this sport closely.',
    ),
    _Video(
      title: 'RUNIT Semi-Final: QLD Crushers vs NSW Chargers',
      channel: _channels[0],
      views: '1.1M',
      uploaded: '3 weeks ago',
      duration: '1:48:30',
      category: 'MATCHES',
      isLive: false,
      thumbnailGradient: [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
      thumbnailIcon: Icons.stadium,
      youtubeId: 'rKrsqVbwob0',
      youtubeUrl: 'https://www.youtube.com/watch?v=rKrsqVbwob0',
      description:
          'Full replay of the 2024 semi-final. '
          'Queensland vs New South Wales. State pride on the line.',
    ),
    _Video(
      title: 'How to Tackle in RUNIT — Technique Breakdown',
      channel: _channels[3],
      views: '445K',
      uploaded: '4 weeks ago',
      duration: '13:40',
      category: 'TRAINING',
      isLive: false,
      thumbnailGradient: [const Color(0xFFE65100), const Color(0xFFFF6F00)],
      thumbnailIcon: Icons.sports,
      youtubeId: 'BK_EYFlS0Vc',
      youtubeUrl: 'https://www.youtube.com/watch?v=BK_EYFlS0Vc',
      description:
          'Tackling technique for the RUNIT battlefield. '
          'Body position, timing, shoulder placement, and absorbing the runner\'s momentum.',
    ),
  ];

  List<_Video> get _filteredVideos {
    var vids = _allVideos;
    if (_activeCategory != 'FOR YOU') {
      vids = vids.where((v) => v.category == _activeCategory).toList();
    }
    // Sort
    switch (_sortIndex) {
      case 1: // latest — just reverse for mock
        vids = vids.reversed.toList();
        break;
      case 2: // most viewed — parse view string
        vids = List.from(vids)
          ..sort((a, b) {
            return _parseViews(b.views).compareTo(_parseViews(a.views));
          });
        break;
      default: // trending — default order
        break;
    }
    return vids;
  }

  double _parseViews(String v) {
    v = v.replaceAll(',', '');
    if (v.endsWith('M')) return double.parse(v.replaceAll('M', '')) * 1000000;
    if (v.endsWith('K')) return double.parse(v.replaceAll('K', '')) * 1000;
    return double.tryParse(v) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          _buildAppBar(ctx),
          _buildHeroBanner(),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabBar: TabBar(
                controller: _tabCtrl,
                indicatorColor: _kGreen,
                indicatorWeight: 3,
                labelColor: _kGreen,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.45),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
                tabs: const [
                  Tab(text: 'VIDEOS'),
                  Tab(text: 'CHANNELS'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [_buildVideoFeed(), _buildChannelsList()],
        ),
      ),
    );
  }

  // ── App bar ──────────────────────────────────────────────────────────
  SliverAppBar _buildAppBar(BuildContext ctx) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _kOverlay.withValues(alpha: 0.95),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.canPop() ? context.pop() : null,
      ),
      title: Row(
        children: [
          Image.asset(
            AppLogos.icon,
            width: 28,
            height: 28,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.sports_mma, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 10),
          const Text(
            'RUN IT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_kGreen, _kGreenDim]),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'COLLISION',
              style: TextStyle(
                color: Colors.black,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Use the main Explore tab to search fighters & events'),
                duration: Duration(seconds: 3),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.cast, color: Colors.white.withValues(alpha: 0.7)),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cast to TV — use your device\'s built-in screen cast feature'),
                duration: Duration(seconds: 3),
              ),
            );
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Hero banner ──────────────────────────────────────────────────────
  SliverToBoxAdapter _buildHeroBanner() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E20), Color(0xFF004D40), _kOverlay],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kGreen.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: _kGreen.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('💥', style: TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RUNIT COLLISION SPORT',
                        style: TextStyle(
                          color: _kGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Runner vs Tackler · 20m Battlefield',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Two athletes. One 20-metre battlefield. The runner charges '
              'at full speed carrying the ball. The tackler must stop them. '
              'No stepping. No swerving. Run it straight.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            // Stats row
            const Row(
              children: [
                _StatChip(icon: Icons.play_circle_fill, label: '15 Videos'),
                SizedBox(width: 10),
                _StatChip(icon: Icons.people, label: '6 Channels'),
                SizedBox(width: 10),
                _StatChip(icon: Icons.trending_up, label: 'Viral'),
              ],
            ),
            const SizedBox(height: 14),
            // Quick info pills
            const Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _InfoPill('🇦🇺 Born in Australia'),
                _InfoPill('1v1 Collision'),
                _InfoPill('No Pads'),
                _InfoPill('20 x 4m Arena'),
                _InfoPill('TikTok Viral'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Video feed ───────────────────────────────────────────────────────
  Widget _buildVideoFeed() {
    final videos = _filteredVideos;
    return CustomScrollView(
      slivers: [
        // Category chips
        SliverToBoxAdapter(
          child: SizedBox(
            height: 54,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final active = cat == _activeCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _activeCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? _kGreen
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: active
                            ? null
                            : Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: active
                              ? Colors.black
                              : Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Sort row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${videos.length} videos',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                ...List.generate(_sortLabels.length, (i) {
                  final active = _sortIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _sortIndex = i),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: Text(
                        _sortLabels[i],
                        style: TextStyle(
                          color: active
                              ? _kGreen
                              : Colors.white.withValues(alpha: 0.35),
                          fontSize: 11,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        // Video grid — responsive columns
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.68,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _VideoCard(video: videos[i]),
              childCount: videos.length,
            ),
          ),
        ),
        // Bottom spacer
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  // ── Channels list ────────────────────────────────────────────────────
  Widget _buildChannelsList() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const SizedBox(height: 8),
        Text(
          'RUNIT CHANNELS',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        ..._channels.map((ch) => _ChannelTile(channel: ch)),
        const SizedBox(height: 24),
        // RUNIT Explained section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kGreen.withValues(alpha: 0.12)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('📖', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Text(
                    'WHAT IS RUNIT?',
                    style: TextStyle(
                      color: _kGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14),
              _ExplainerRow(
                icon: Icons.sports_mma,
                title: 'The Sport',
                desc:
                    'RUNIT is a 1v1 collision sport born in Australia. '
                    'Two athletes face off on a 20m x 4m "battlefield." '
                    'The runner carries the ball at full speed; the tackler '
                    'must bring them down.',
              ),
              _ExplainerRow(
                icon: Icons.straighten,
                title: 'The Battlefield',
                desc:
                    '20 metres long, 4 metres wide. The runner gets a '
                    '10m sprint zone to build speed. The collision happens '
                    'at the impact point where both athletes meet.',
              ),
              _ExplainerRow(
                icon: Icons.rule,
                title: 'The Rules',
                desc:
                    'Run it straight — no stepping, no swerving. The '
                    'runner must try to break through. The tackler must hold '
                    'their ground. Ball must be carried.',
              ),
              _ExplainerRow(
                icon: Icons.trending_up,
                title: 'Going Viral',
                desc:
                    'RUNIT went viral on TikTok and YouTube in 2023-24, '
                    'with millions of views. Featured on Channel 10\'s '
                    '"The Project." Now expanding into championship leagues.',
              ),
              _ExplainerRow(
                icon: Icons.warning_amber,
                title: 'Safety Debate',
                desc:
                    'Doctors and sports scientists have raised concerns '
                    'about concussion and neck injuries from repeated '
                    'high-speed collisions. The sport continues to evolve its '
                    'safety protocols.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

class _Channel {
  final String name;
  final String handle;
  final String avatar;
  final String subs;
  final bool verified;
  const _Channel({
    required this.name,
    required this.handle,
    required this.avatar,
    required this.subs,
    required this.verified,
  });
}

class _Video {
  final String title;
  final _Channel channel;
  final String views;
  final String uploaded;
  final String duration;
  final String category;
  final bool isLive;
  final List<Color> thumbnailGradient;
  final IconData thumbnailIcon;
  final String description;
  final String? youtubeUrl;
  final String? youtubeId;
  const _Video({
    required this.title,
    required this.channel,
    required this.views,
    required this.uploaded,
    required this.duration,
    required this.category,
    required this.isLive,
    required this.thumbnailGradient,
    required this.thumbnailIcon,
    required this.description,
    this.youtubeUrl,
    this.youtubeId,
  });

  /// YouTube thumbnail URL (maxresdefault or hqdefault)
  String? get thumbnailUrl => youtubeId != null
      ? 'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg'
      : null;
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// YouTube-style video card — taps open real YouTube content
class _VideoCard extends StatelessWidget {
  final _Video video;
  const _VideoCard({required this.video});

  bool get _hasVerifiedEmbedId =>
      video.youtubeId != null &&
      _kVerifiedRunItYoutubeIds.contains(video.youtubeId);

  Uri get _youtubeFallbackSearchUrl =>
      Uri.https('www.youtube.com', '/results', {'search_query': video.title});

  Uri get _youtubeUri => video.youtubeUrl != null
      ? YouTubeService.normalizePublicYoutubeUri(
          video.youtubeUrl!,
          fallbackSearchQuery: video.title,
        )
      : _youtubeFallbackSearchUrl;

  Future<void> _openFightPipe(BuildContext context) async {
    // FightPipe route uses embedded playback only for validated IDs.
    if (_hasVerifiedEmbedId) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _YouTubePlayerPage(video: video),
        ),
      );
      return;
    }

    // Until FightPipe ingest is wired for this clip, route safely to source.
    if (await canLaunchUrl(_youtubeUri)) {
      await launchUrl(_youtubeUri, mode: LaunchMode.externalApplication);
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open FightPipe')));
    }
  }

  Future<void> _openYouTube(BuildContext context) async {
    if (await canLaunchUrl(_youtubeUri)) {
      await launchUrl(_youtubeUri, mode: LaunchMode.externalApplication);
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open YouTube')));
    }
  }

  Future<void> _openVideo(BuildContext context) async {
    await _openYouTube(context);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openVideo(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ──
            AspectRatio(
              aspectRatio: 16 / 10,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: _buildThumbnail(),
              ),
            ),
            // ── Compact info ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          video.channel.avatar,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            video.channel.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                        if (video.channel.verified) ...[
                          const SizedBox(width: 3),
                          Icon(
                            Icons.verified,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: 'YouTube',
                            icon: Icons.play_arrow_rounded,
                            accent: _kRed,
                            onTap: () => _openYouTube(context),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _ActionButton(
                            label: 'DFC App',
                            icon: Icons.open_in_new_rounded,
                            accent: _kGreen,
                            onTap: () => _openFightPipe(context),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${video.views} · ${video.uploaded}',
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Thumbnail ──────────────────────────────────────────────────────
  Widget _buildThumbnail() {
    final hasYouTube =
        video.youtubeId != null &&
        _kVerifiedRunItYoutubeIds.contains(video.youtubeId);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background: Real YouTube thumbnail or gradient fallback
        if (hasYouTube)
          DfcNetworkImage(url: video.thumbnailUrl!)
        else
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: video.thumbnailGradient,
              ),
            ),
            child: Opacity(
              opacity: 0.12,
              child: Center(
                child: Icon(video.thumbnailIcon, size: 80, color: Colors.white),
              ),
            ),
          ),
        // Dark gradient overlay for text readability
        if (hasYouTube)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
          ),
        // YouTube play button
        Center(
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _kRed.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _kRed.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        // YouTube badge
        Positioned(
          right: 6,
          top: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_fill, color: _kRed, size: 10),
                SizedBox(width: 3),
                Text(
                  'YouTube',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Duration badge
        Positioned(
          right: 6,
          bottom: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              video.duration,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        // LIVE badge
        if (video.isLive)
          Positioned(
            left: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _kRed,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 6),
                  SizedBox(width: 3),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Category tag
        Positioned(
          left: 6,
          bottom: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
            ),
            child: Text(
              video.category,
              style: const TextStyle(
                color: _kGreen,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 11),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent.withValues(alpha: 0.45)),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          textStyle: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}

/// Channel tile
class _ChannelTile extends StatelessWidget {
  final _Channel channel;
  const _ChannelTile({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: _kGreen.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(channel.avatar, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        channel.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (channel.verified) ...[
                      const SizedBox(width: 5),
                      Icon(
                        Icons.verified,
                        size: 15,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${channel.handle}  •  ${channel.subs} subscribers',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kGreen.withValues(alpha: 0.25)),
            ),
            child: const Text(
              'SUBSCRIBE',
              style: TextStyle(
                color: _kGreen,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat chip in hero banner
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _kGreen.withValues(alpha: 0.7)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Info pill
class _InfoPill extends StatelessWidget {
  final String label;
  const _InfoPill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGreen.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _kGreen,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Explainer row in "What is RUNIT?" section
class _ExplainerRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _ExplainerRow({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _kGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Pinned Tab Bar Delegate
// ═══════════════════════════════════════════════════════════════════════════
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: DesignTokens.bgPrimary.withValues(alpha: 0.85),
          child: tabBar,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// Embedded YouTube Player Page
// ═══════════════════════════════════════════════════════════════════════════
class _YouTubePlayerPage extends StatefulWidget {
  final _Video video;
  const _YouTubePlayerPage({required this.video});

  @override
  State<_YouTubePlayerPage> createState() => _YouTubePlayerPageState();
}

class _YouTubePlayerPageState extends State<_YouTubePlayerPage> {
  late YoutubePlayerController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        enableCaption: false,
        playsInline: false,
      ),
    );
    _ctrl.loadVideoById(videoId: widget.video.youtubeId!);
  }

  @override
  void dispose() {
    _ctrl.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.video.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.open_in_new,
              color: Colors.white70,
              size: 20,
            ),
            onPressed: () async {
              final url =
                  widget.video.youtubeUrl ??
                  'https://www.youtube.com/watch?v=${widget.video.youtubeId}';
              final uri = YouTubeService.normalizePublicYoutubeUri(
                url,
                fallbackSearchQuery: widget.video.title,
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Player ──
          AspectRatio(
            aspectRatio: 16 / 9,
            child: YoutubePlayer(controller: _ctrl),
          ),
          // ── Video info ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.video.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      widget.video.views,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      ' views · ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      widget.video.uploaded,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Channel info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF1A2744),
                      child: Text(
                        widget.video.channel.avatar,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.video.channel.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (widget.video.channel.verified) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.verified,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${widget.video.channel.subs} subscribers',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF1744),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'SUBSCRIBE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF1A2744)),
                const SizedBox(height: 12),
                // Description
                Text(
                  widget.video.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                // Category & Duration
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.video.category,
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.video.duration,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
