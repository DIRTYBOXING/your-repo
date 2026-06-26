import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_image.dart';
import '../../../shared/widgets/dfc_logo_backdrop.dart';

/// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
/// DFC AIRCOMBAT â€” FPV Drone Racing  ðŸðŸš
///
/// "Can't fight? FLY. Same adrenaline. Same glory."
///
/// Race & sell FPV drones, view leaderboards, browse tracks,
/// manage your hangar. Inspired by Red Bull FPV racing.
/// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

// â”€â”€ Accent colours â”€â”€
const Color _droneAccent = Color(0xFFFF6B00); // hot-orange
const Color _droneAccent2 = Color(0xFFFFD600); // neon-yellow
const Color _droneBg = Color(0xFF0A0E18);

class DroneRacingScreen extends StatefulWidget {
  const DroneRacingScreen({super.key});

  @override
  State<DroneRacingScreen> createState() => _DroneRacingScreenState();
}

class _DroneRacingScreenState extends State<DroneRacingScreen>
    with SingleTickerProviderStateMixin {
  bool get _syntheticEnabled => AppConstants.syntheticContentEnabled;

  late TabController _tabCtrl;
  String _trackFilter = 'All';
  String _newsTag = 'ALL';
  String _videoFilter = 'ALL';

  static const _difficulties = [
    'All',
    'Rookie',
    'Amateur',
    'Pro',
    'Elite',
    'Nightmare',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // MOCK DATA
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  List<_RaceEvent> get _races => !_syntheticEnabled
      ? const []
      : const [
          _RaceEvent(
            name: 'Neon Gauntlet Grand Prix',
            track: 'Neon Gauntlet',
            location: 'Las Vegas, USA',
            date: 'Mar 8, 2026',
            format: 'Pack Race',
            difficulty: 'Pro',
            pilotsRegistered: 16,
            prizePool: '\$10,000',
            imageUrl: 'https://img.youtube.com/vi/HQ7R_buZPSo/hqdefault.jpg',
            isLive: true,
          ),
          _RaceEvent(
            name: 'Red Bull Ring Micro Invitational',
            track: 'Red Bull Ring Micro',
            location: 'Spielberg, Austria',
            date: 'Mar 15, 2026',
            format: 'Head to Head',
            difficulty: 'Elite',
            pilotsRegistered: 8,
            prizePool: '\$25,000',
            imageUrl: 'https://img.youtube.com/vi/qhKIHEDa4Eo/hqdefault.jpg',
          ),
          _RaceEvent(
            name: 'Warehouse Blitz: Brooklyn Beatdown',
            track: 'Warehouse Blitz',
            location: 'Brooklyn, USA',
            date: 'Mar 22, 2026',
            format: 'Time Attack',
            difficulty: 'Amateur',
            pilotsRegistered: 32,
            prizePool: '\$5,000',
            imageUrl: 'https://img.youtube.com/vi/bk-KQPjLeEY/hqdefault.jpg',
          ),
          _RaceEvent(
            name: 'Nightmare Alley: Tokyo Night',
            track: 'Nightmare Alley',
            location: 'Tokyo, Japan',
            date: 'Apr 5, 2026',
            format: 'Endurance',
            difficulty: 'Nightmare',
            pilotsRegistered: 6,
            prizePool: '\$50,000',
            imageUrl: 'https://img.youtube.com/vi/4v1deSQ3JbQ/hqdefault.jpg',
          ),
          _RaceEvent(
            name: 'The Cage Circuit: DFC Open',
            track: 'The Cage Circuit',
            location: 'DFC Virtual',
            date: 'Apr 12, 2026',
            format: 'Freestyle',
            difficulty: 'Rookie',
            pilotsRegistered: 48,
            prizePool: '\$1,000',
            imageUrl: 'https://img.youtube.com/vi/SsQL5FrPBbA/hqdefault.jpg',
          ),
        ];

  List<_DroneProduct> get _marketplace => !_syntheticEnabled
      ? const []
      : const [
          _DroneProduct(
            name: 'DFC GHOST 5" FPV Racer',
            description:
                'Custom 5-inch freestyle/race quad. DJI O3 Air Unit, '
                'T-Motor F60 Pro V, 6S ready. Under 250g dry.',
            price: '\$599',
            seller: 'DFC Drone Lab',
            tag: 'BEST SELLER',
            emoji: 'ðŸŽï¸',
            imageUrl: 'https://img.youtube.com/vi/HQ7R_buZPSo/hqdefault.jpg',
          ),
          _DroneProduct(
            name: 'ImpulseRC Apex 5" Frame',
            description:
                'True-X geometry, 5mm carbon arms. The frame of champions.',
            price: '\$89',
            seller: 'FPV Parts NZ',
            tag: 'FRAME',
            emoji: 'ðŸ”©',
            imageUrl: 'https://img.youtube.com/vi/4v1deSQ3JbQ/hqdefault.jpg',
          ),
          _DroneProduct(
            name: 'Walksnail Avatar HD Kit',
            description:
                'Low-latency digital FPV system. 1080p recording, '
                '4km range. Game changer for race day.',
            price: '\$219',
            seller: 'DroneZone AU',
            tag: 'HD VTX',
            emoji: 'ðŸ“¡',
            imageUrl: 'https://img.youtube.com/vi/Kf4WIVNDMCI/hqdefault.jpg',
          ),
          _DroneProduct(
            name: 'TBS Crossfire Nano RX',
            description:
                'Long range RC link. 868MHz, telemetry built-in. '
                'Never lose signal mid-race.',
            price: '\$39',
            seller: 'Team BlackSheep',
            tag: 'RECEIVER',
            emoji: 'ðŸ“¶',
            imageUrl: 'https://img.youtube.com/vi/J3Hg2f7RL1A/hqdefault.jpg',
          ),
          _DroneProduct(
            name: 'Tattu R-Line 1550mAh 6S',
            description: 'Race-grade LiPo. 150C burst. Lightweight and punchy.',
            price: '\$42',
            seller: 'Battery Kings',
            tag: 'BATTERY',
            emoji: 'ðŸ”‹',
            imageUrl: 'https://img.youtube.com/vi/HQ7R_buZPSo/hqdefault.jpg',
          ),
          _DroneProduct(
            name: 'DFC FPV Goggles V2',
            description:
                'Dual OLED screens, head tracking, DVR. '
                'Built for AirCombat league pilots.',
            price: '\$449',
            seller: 'DFC Drone Lab',
            tag: 'GOGGLES',
            emoji: 'ðŸ¥½',
            imageUrl: 'https://img.youtube.com/vi/SsQL5FrPBbA/hqdefault.jpg',
          ),
          _DroneProduct(
            name: 'Ethix S5 Props (16 pack)',
            description: 'Light Grey props, aggressive pitch. Smooth and fast.',
            price: '\$18',
            seller: 'FPV Parts NZ',
            tag: 'PROPS',
            emoji: 'ðŸŒ€',
            imageUrl: 'https://img.youtube.com/vi/4v1deSQ3JbQ/hqdefault.jpg',
          ),
          _DroneProduct(
            name: 'RadioMaster Pocket',
            description:
                'Compact ELRS radio. Hall-effect gimbals, USB-C, '
                'EdgeTX firmware. Perfect pit radio.',
            price: '\$69',
            seller: 'DroneZone AU',
            tag: 'RADIO',
            emoji: 'ðŸŽ®',
            imageUrl: 'https://img.youtube.com/vi/J3Hg2f7RL1A/hqdefault.jpg',
          ),
        ];

  List<_LeaderEntry> get _leaderboard => !_syntheticEnabled
      ? const []
      : const [
          _LeaderEntry(
            rank: 1,
            callsign: 'GHOST HAWK',
            points: 2480,
            wins: 12,
            bestLap: '18.42s',
          ),
          _LeaderEntry(
            rank: 2,
            callsign: 'IRON TALON',
            points: 2210,
            wins: 9,
            bestLap: '19.01s',
          ),
          _LeaderEntry(
            rank: 3,
            callsign: 'NEON VIPER',
            points: 1985,
            wins: 7,
            bestLap: '19.38s',
          ),
          _LeaderEntry(
            rank: 4,
            callsign: 'PKO',
            points: 1760,
            wins: 6,
            bestLap: '19.55s',
          ),
          _LeaderEntry(
            rank: 5,
            callsign: 'SKYBURN',
            points: 1540,
            wins: 5,
            bestLap: '20.01s',
          ),
          _LeaderEntry(
            rank: 6,
            callsign: 'BLITZ',
            points: 1320,
            wins: 4,
            bestLap: '20.44s',
          ),
          _LeaderEntry(
            rank: 7,
            callsign: 'THUNDERCHILD',
            points: 1100,
            wins: 3,
            bestLap: '21.12s',
          ),
          _LeaderEntry(
            rank: 8,
            callsign: 'SIREN',
            points: 890,
            wins: 2,
            bestLap: '21.67s',
          ),
        ];

  List<_HangarDrone> get _hangar => !_syntheticEnabled
      ? const []
      : const [
          _HangarDrone(
            name: 'Primary Racer',
            frame: 'DFC GHOST 5"',
            motors: 'T-Motor F60 Pro V',
            vtx: 'DJI O3 Air Unit',
            battery: '6S 1550mAh',
            status: 'Race Ready',
            emoji: 'ðŸ',
            imageUrl: 'https://img.youtube.com/vi/HQ7R_buZPSo/hqdefault.jpg',
          ),
          _HangarDrone(
            name: 'Freestyle Rig',
            frame: 'ImpulseRC Apex',
            motors: 'EMAX ECO II 2807',
            vtx: 'Walksnail Avatar HD',
            battery: '6S 1300mAh',
            status: 'Needs Props',
            emoji: 'ðŸŒ€',
            imageUrl: 'https://img.youtube.com/vi/4v1deSQ3JbQ/hqdefault.jpg',
          ),
          _HangarDrone(
            name: 'Tiny Whoop',
            frame: 'BetaFPV Meteor75',
            motors: '0802 22000KV',
            vtx: 'Built-in Analog',
            battery: '1S 450mAh',
            status: 'Charging',
            emoji: 'ðŸ',
            imageUrl: 'assets/dfc_backgrounds/dfc_logo_resized.png',
          ),
        ];

  static const _promoPanels = <_PromoPanel>[
    _PromoPanel(
      title: 'IBC 03 HIGHLIGHT WAVE',
      subtitle:
          'DFC promotion engine in ghost mode. IBC keeps the front stage.',
      body:
          'Hardman vs Tuhu. Cutler vs Modini. Gold Coast noise, broadcast heat, and DFC amplification from the back pushing the whole event harder.',
      badge: 'IBC 03',
      cta: 'OPEN IBC LIVE',
      route: '/ibc/live',
      imageUrl: 'https://img.youtube.com/vi/UVZ3vBGr12I/hqdefault.jpg',
    ),
    _PromoPanel(
      title: 'SKY TRACK DRONES',
      subtitle: 'Launch Pad coming soon.',
      body:
          'Arena fly-ins, walkout capture, overhead pursuit cams, sponsor fly-throughs, and camp tracking are being lined up for the next rollout wave.',
      badge: 'COMING NEXT',
      cta: 'VIEW ROADMAP',
      route: '',
      imageUrl: 'https://img.youtube.com/vi/aDm1WUkwrCg/hqdefault.jpg',
    ),
    _PromoPanel(
      title: 'LEGENDS ON THE WAY IN',
      subtitle: 'The lane out is opening. The next names are stepping through.',
      body:
          'IBC 3 is the proof point. Vegas is on the horizon. DFC stays behind the curtain, builds the audience, and lets the promotions and fighters own the spotlight.',
      badge: 'WORLD PUSH',
      cta: 'OPEN IBC WORLD',
      route: '/ibc/world',
      imageUrl: 'https://img.youtube.com/vi/SsQL5FrPBbA/hqdefault.jpg',
    ),
  ];

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // BUILD
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _droneBg,
      body: Stack(
        children: [
          const DfcLogoBackdrop(
            opacity: 0.04,
            size: 260,
            alignment: Alignment.bottomRight,
            offset: Offset(40, 60),
            glowColor: Color(0xFFFF6B00),
          ),
          NestedScrollView(
            headerSliverBuilder: (context, _) => [
              _buildAppBar(),
              _buildHeroBanner(),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  tabBar: TabBar(
                    controller: _tabCtrl,
                    indicatorColor: _droneAccent,
                    labelColor: Colors.white,
                    unselectedLabelColor: DesignTokens.textMuted,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: const [
                      Tab(text: 'RACES'),
                      Tab(text: 'MARKETPLACE'),
                      Tab(text: 'LEADERBOARD'),
                      Tab(text: 'MY HANGAR'),
                      Tab(text: '📹 FPV VIDEO'),
                      Tab(text: 'ðŸŒ WORLD NEWS'),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildRacesTab(),
                _buildMarketplaceTab(),
                _buildLeaderboardTab(),
                _buildHangarTab(),
                _buildFpvVideoTab(),
                _buildWorldNewsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ App Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: DesignTokens.textPrimary,
          size: 20,
        ),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_droneAccent, _droneAccent2],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.flight, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'AIRCOMBAT',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _droneAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'FPV RACING',
              style: TextStyle(
                color: _droneAccent,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: DesignTokens.textSecondary,
          ),
          onPressed: () => context.push('/notifications'),
        ),
      ],
    );
  }

  // â”€â”€ Hero Banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  SliverToBoxAdapter _buildHeroBanner() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A1500), Color(0xFF1A0A00), _droneBg],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _droneAccent.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('ðŸš', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DFC AIRCOMBAT 2026',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Can't fight? FLY. Same adrenaline. Same glory.",
                        style: TextStyle(
                          color: _droneAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _droneAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _droneAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: _droneAccent, size: 6),
                      SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: _droneAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'FPV drone racing for injured fighters.\n'
              'Race â€¢ Sell â€¢ Build â€¢ Compete â€¢ Earn.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // TAB 1 â€” RACES
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildRacesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _buildGhostPromotionCallout(),
        ),
        SizedBox(
          height: 232,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _promoPanels.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final panel = _promoPanels[index];
              return _PromoPanelCard(
                panel: panel,
                onTap: () {
                  if (panel.route.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Sky Track Launch Pad is lining up now. DFC will push it from the back when it is ready.',
                        ),
                      ),
                    );
                    return;
                  }
                  context.push(panel.route);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Difficulty filter chips
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemCount: _difficulties.length,
            itemBuilder: (context, i) {
              final d = _difficulties[i];
              final selected = d == _trackFilter;
              return FilterChip(
                label: Text(d),
                selected: selected,
                onSelected: (_) => setState(() => _trackFilter = d),
                selectedColor: _droneAccent.withValues(alpha: 0.25),
                checkmarkColor: _droneAccent,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                labelStyle: TextStyle(
                  color: selected ? _droneAccent : Colors.white70,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: selected
                      ? _droneAccent.withValues(alpha: 0.5)
                      : Colors.white12,
                ),
              );
            },
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              final filtered = _trackFilter == 'All'
                  ? _races
                  : _races.where((r) => r.difficulty == _trackFilter).toList();
              if (filtered.isEmpty) {
                return const Center(
                  child: Text(
                    'No races at this difficulty',
                    style: TextStyle(color: DesignTokens.textMuted),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildIbcMomentumCard(),
                  const SizedBox(height: 14),
                  ...filtered.map((race) => _RaceCard(race: race)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // TAB 2 â€” MARKETPLACE (buy & sell drones + parts)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildMarketplaceTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: _buildSkyTrackLaunchPadCard(),
        ),
        // Sell button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('SELL YOUR DRONE / PARTS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _droneAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Drone marketplace listings in development — check back soon')),
                );
              },
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _marketplace.length,
            itemBuilder: (context, i) => _ProductCard(product: _marketplace[i]),
          ),
        ),
      ],
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // TAB 3 â€” LEADERBOARD
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildLeaderboardTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildLegendsOnWayInCard(),
        const SizedBox(height: 14),
        // Season header
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _droneAccent.withValues(alpha: 0.12),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _droneAccent.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Text('ðŸ†', style: TextStyle(fontSize: 24)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEASON 1 STANDINGS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'AirCombat League 2026',
                      style: TextStyle(color: _droneAccent, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ..._leaderboard.map((e) => _LeaderRow(entry: e)),
      ],
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // TAB 4 â€” MY HANGAR
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildHangarTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSkyTrackOpsCard(),
        const SizedBox(height: 16),
        // Pilot card
        Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _droneAccent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_droneAccent, _droneAccent2],
                  ),
                ),
                child: const Center(
                  child: Text('ðŸ¦…', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR CALLSIGN',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'GHOST HAWK',
                      style: TextStyle(
                        color: _droneAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Rank: Ace  â€¢  12 Wins  â€¢  2,480 RP',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _droneAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'EDIT',
                  style: TextStyle(
                    color: _droneAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Drone cards
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'YOUR DRONES',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ..._hangar.map((d) => _HangarCard(drone: d)),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          icon: const Icon(Icons.add, color: _droneAccent),
          label: const Text(
            'ADD NEW DRONE',
            style: TextStyle(
              color: _droneAccent,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: _droneAccent.withValues(alpha: 0.4)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Drone builder module in development — design your race-ready drone soon')),
            );
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 5 — FPV VIDEO & TECH  (Real Racing Footage · Channels · Tech)
  // ═══════════════════════════════════════════════════════════════════════

  static const _fpvVideos = [
    // ── REAL FPV RACING FOOTAGE ──
    _FpvVideo(
      title: 'DRL Champions Final 2025 — Full Race POV',
      channel: 'Drone Racing League',
      videoId: 'HQ7R_buZPSo',
      url: 'https://www.youtube.com/watch?v=HQ7R_buZPSo',
      category: 'RACE',
      description:
          'Full first-person cockpit footage from the DRL World Championship final. 90mph through neon gates.',
      views: '2.1M',
    ),
    _FpvVideo(
      title: 'Red Bull DR.ONE — Salzburg FPV Race Highlights',
      channel: 'Red Bull',
      videoId: 'qhKIHEDa4Eo',
      url: 'https://www.youtube.com/watch?v=qhKIHEDa4Eo',
      category: 'RACE',
      description:
          'Red Bull DR.ONE championship — the fastest FPV pilots battle through the Hangar-7 at breakneck speed.',
      views: '5.8M',
    ),
    _FpvVideo(
      title: 'MultiGP Championship 2025 — Top 8 Finals',
      channel: 'MultiGP Drone Racing',
      videoId: 'bk-KQPjLeEY',
      url: 'https://www.youtube.com/watch?v=bk-KQPjLeEY',
      category: 'RACE',
      description:
          'The largest grassroots FPV racing league. 8 finalists pushing 5-inch quads to the absolute limit.',
      views: '890K',
    ),
    _FpvVideo(
      title: 'FAI World Drone Racing Championship — Korea',
      channel: 'FAI Air Sports',
      videoId: '1MqhFuRxTL8',
      url: 'https://www.youtube.com/watch?v=1MqhFuRxTL8',
      category: 'RACE',
      description:
          'Official FAI sanctioned world championship. Nations compete for gold in high-speed FPV drone combat.',
      views: '1.5M',
    ),
    // ── FREESTYLE & CINEMATIC ──
    _FpvVideo(
      title: 'Abandoned Factory Freestyle — RAW Pack',
      channel: 'Mr Steele',
      videoId: '4v1deSQ3JbQ',
      url: 'https://www.youtube.com/watch?v=4v1deSQ3JbQ',
      category: 'FREESTYLE',
      description:
          'Legendary FPV freestyle pilot Mr Steele ripping through an abandoned factory. Raw uncut footage.',
      views: '3.2M',
    ),
    _FpvVideo(
      title: 'Mountain Dive — Long Range FPV Cinematic',
      channel: 'JohnnyFPV',
      videoId: 'VgS54fqKxf0',
      url: 'https://www.youtube.com/watch?v=VgS54fqKxf0',
      category: 'CINEMATIC',
      description:
          'JohnnyFPV takes a long-range quad through mountain passes at sunrise. Breathtaking cinematic FPV.',
      views: '12M',
    ),
    _FpvVideo(
      title: 'NYC Rooftop Gap — FPV Freestyle',
      channel: 'Kabab FPV',
      videoId: 'G8LH7cOSRTQ',
      url: 'https://www.youtube.com/watch?v=G8LH7cOSRTQ',
      category: 'FREESTYLE',
      description:
          'Insane rooftop gaps and building dives through New York City skyline. Not for the faint-hearted.',
      views: '4.7M',
    ),
    // ── TECH & BUILD GUIDES ──
    _FpvVideo(
      title: 'Complete FPV Build Guide 2026 — Budget to Pro',
      channel: 'Joshua Bardwell',
      videoId: 'Avp8MurmeEY',
      url: 'https://www.youtube.com/watch?v=Avp8MurmeEY',
      category: 'TECH',
      description:
          'The godfather of FPV tutorials walks through a complete quad build. Frame, FC, ESC, motors, VTX, tuning.',
      views: '1.8M',
    ),
    _FpvVideo(
      title: 'DJI O4 Air Unit vs Walksnail Avatar — DEFINITIVE Test',
      channel: 'Oscar Liang',
      videoId: 'Kf4WIVNDMCI',
      url: 'https://www.youtube.com/watch?v=Kf4WIVNDMCI',
      category: 'TECH',
      description:
          'Head-to-head latency, range, and image quality test between the two leading digital FPV systems.',
      views: '920K',
    ),
    _FpvVideo(
      title: 'Betaflight 5.0 Tuning — Fly Like Butter',
      channel: 'UAV Tech',
      videoId: 'qJPsFj9lIak',
      url: 'https://www.youtube.com/watch?v=qJPsFj9lIak',
      category: 'TECH',
      description:
          'Step-by-step PID tuning, RPM filter setup, and rate profiles for Betaflight 5.0. Get buttery smooth flight.',
      views: '650K',
    ),
    _FpvVideo(
      title: 'ELRS 4.0 Setup — Best Long Range Link',
      channel: 'Painless360',
      videoId: 'J3Hg2f7RL1A',
      url: 'https://www.youtube.com/watch?v=J3Hg2f7RL1A',
      category: 'TECH',
      description:
          'ExpressLRS 4.0 flash & bind guide. The open-source RC link that beat Crossfire on range AND latency.',
      views: '480K',
    ),
    // ── COMBAT SPORTS × DRONES ──
    _FpvVideo(
      title: 'UFC Vegas — Drone Walkout Footage Behind the Scenes',
      channel: 'DFC AirCombat',
      videoId: 'SsQL5FrPBbA',
      url: 'https://www.youtube.com/watch?v=SsQL5FrPBbA',
      category: 'DFC',
      description:
          'DFC AirCombat team captures FPV drone footage of UFC fighter walkouts. Arena flyover + crowd reactions.',
      views: '340K',
    ),
    _FpvVideo(
      title: 'Boxing Ring Flyover — BKFC Tampa FPV',
      channel: 'DFC AirCombat',
      videoId: 'UVZ3vBGr12I',
      url: 'https://www.youtube.com/watch?v=UVZ3vBGr12I',
      category: 'DFC',
      description:
          'First-ever FPV drone flyover inside a bare knuckle fighting arena. Crowd energy captured from the air.',
      views: '220K',
    ),
    _FpvVideo(
      title: 'Fight Camp Training — Drone Follow Cam',
      channel: 'DFC AirCombat',
      videoId: 'aDm1WUkwrCg',
      url: 'https://www.youtube.com/watch?v=aDm1WUkwrCg',
      category: 'DFC',
      description:
          'SkyTrack drone follows a fighter through outdoor training camp. Running, pad work, sparring — all from above.',
      views: '180K',
    ),
  ];

  Widget _buildFpvVideoTab() {
    final sourceVideos = _syntheticEnabled ? _fpvVideos : const <_FpvVideo>[];
    final filtered = _videoFilter == 'ALL'
        ? sourceVideos
        : sourceVideos.where((v) => v.category == _videoFilter).toList();

    return CustomScrollView(
      slivers: [
        // Hero banner
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _droneAccent.withValues(alpha: 0.2),
                  const Color(0xFF7B2FF7).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _droneAccent.withValues(alpha: 0.35)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('\u{1F3AC}', style: TextStyle(fontSize: 26)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FPV VIDEO & TECH',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Real Racing Footage \u00B7 Freestyle \u00B7 Build Guides \u00B7 Tech Reviews',
                            style: TextStyle(
                              color: Color(0xFFFF6B00),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Watch real FPV racing from DRL, Red Bull DR.ONE, MultiGP & FAI World Championships. '
                  'Freestyle legends, build guides from Joshua Bardwell & Oscar Liang, plus DFC AirCombat '
                  'exclusive combat sports \u00D7 drone footage.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Category filter
        SliverToBoxAdapter(
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final cat in [
                  'ALL',
                  'RACE',
                  'FREESTYLE',
                  'CINEMATIC',
                  'TECH',
                  'DFC',
                ])
                  GestureDetector(
                    onTap: () => setState(() => _videoFilter = cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cat == _videoFilter
                            ? _droneAccent.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: cat == _videoFilter
                              ? _droneAccent.withValues(alpha: 0.6)
                              : Colors.white24,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: cat == _videoFilter
                              ? _droneAccent
                              : Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Video cards
        SliverList.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _FpvVideoCard(video: filtered[i]),
        ),

        // Top FPV channels
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _droneAccent.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '\u{1F4FA} TOP FPV CHANNELS TO FOLLOW',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                for (final ch in const [
                  [
                    'JohnnyFPV',
                    '5M+ subs',
                    'Cinematic FPV legend — worked with NFL, NBA, Hollywood',
                  ],
                  [
                    'Mr Steele',
                    '1.2M subs',
                    'Freestyle pioneer — raw ripping, no edits, pure skill',
                  ],
                  [
                    'Joshua Bardwell',
                    '800K subs',
                    'FPV professor — build guides, reviews, troubleshooting',
                  ],
                  [
                    'Rotor Riot',
                    '1.5M subs',
                    'FPV crew — racing, freestyle, reviews, group flying',
                  ],
                  [
                    'Oscar Liang',
                    '200K subs',
                    'Deep-dive FPV tech — antenna tests, VTX comparisons, PID tuning',
                  ],
                  [
                    'Drone Racing League',
                    '600K subs',
                    'Official DRL channel — races, pilots, behind the scenes',
                  ],
                  [
                    'UAV Tech',
                    '350K subs',
                    'Betaflight tuning expert — PID masterclass, filter deep-dives',
                  ],
                  [
                    'Kabab FPV',
                    '400K subs',
                    'Urban freestyle — NYC gaps, building dives, raw power',
                  ],
                  [
                    'Nurk FPV',
                    '300K subs',
                    'Smooth freestyle flows — proximity flying at its finest',
                  ],
                  [
                    'Le Drib',
                    '280K subs',
                    'French freestyle pro — buttery smooth, cinematic acro',
                  ],
                ]) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _droneAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${ch[0]}  \u00B7  ${ch[1]}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                ch[2],
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // FPV tech info section
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF7B2FF7).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF7B2FF7).withValues(alpha: 0.2),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u{1F527} FPV TECHNOLOGY EXPLAINED',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 12),
                _FpvTechItem(
                  title: 'Flight Controller (FC)',
                  info:
                      'The brain of the quad. Runs Betaflight firmware. Popular: SpeedyBee F405 V4, Diatone Mamba.',
                ),
                _FpvTechItem(
                  title: 'ESC (Electronic Speed Controller)',
                  info:
                      '4-in-1 board that controls motor speed. BLHeli_32 or AM32 firmware. 45A-60A for 5" builds.',
                ),
                _FpvTechItem(
                  title: 'VTX (Video Transmitter)',
                  info:
                      'Sends live video to goggles. Digital: DJI O3/O4, Walksnail Avatar, HDZero. Analog: RushFPV, TBS.',
                ),
                _FpvTechItem(
                  title: 'Goggles',
                  info:
                      'FPV headset. DJI Goggles 3, Walksnail VRX, Fat Shark Dominator, Skyzone Sky04X.',
                ),
                _FpvTechItem(
                  title: 'RC Link',
                  info:
                      'Radio to quad connection. ExpressLRS (open-source, lowest latency), TBS Crossfire, DJI.',
                ),
                _FpvTechItem(
                  title: 'Frame',
                  info:
                      'Carbon fiber skeleton. 5" racing: ImpulseRC Apex, Source One. Freestyle: TBS Source Two, Armattan.',
                ),
                _FpvTechItem(
                  title: 'Motors',
                  info:
                      'Brushless outrunners. 2207 or 2306 for 5". T-Motor F60 Pro V, EMAX ECO II, BrotherHobby.',
                ),
                _FpvTechItem(
                  title: 'Props',
                  info:
                      'Tri-blade 5". HQ Prop, Gemfan Hurricane, Ethix S5. Pitch/diameter affects speed vs. efficiency.',
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // TAB 5 â€” WORLD NEWS  (DroneLife Â· DroneFlyers Â· FPV Racing)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  static const _droneNews = [
    _DroneNewsItem(
      category: 'FPV RACING',
      categoryColor: Color(0xFFFF6B00),
      date: 'Jan 2026',
      title: 'DRL 2025-26 World Championship Broadcast and Race Hub',
      summary:
          'Official Drone Racing League hub with championship schedule, pilot standings, clips, and full broadcast updates.',
      source: 'Drone Racing League',
      tag: 'RACING',
      url: 'https://thedroneracingleague.com/',
    ),
    _DroneNewsItem(
      category: 'GLOBAL SERIES',
      categoryColor: Color(0xFF4FC3F7),
      date: '2026 Season',
      title: 'FAI World Drone Racing Championship Overview',
      summary:
          'International FPV racing calendar, host nation details, and official federation event coverage from FAI Air Sports.',
      source: 'FAI',
      tag: 'EVENTS',
      url: 'https://www.fai.org/world-cups/drone-racing',
    ),
    _DroneNewsItem(
      category: 'COMMUNITY LEAGUE',
      categoryColor: Color(0xFFFFCA28),
      date: 'Latest',
      title: 'MultiGP Race Calendar and Chapter Results',
      summary:
          'MultiGP publishes race-by-race results, chapter rankings, and upcoming qualifiers for grassroots and pro pilots.',
      source: 'MultiGP',
      tag: 'TRACKS',
      url: 'https://www.multigp.com/',
    ),
    _DroneNewsItem(
      category: 'FREESTYLE',
      categoryColor: Color(0xFF7E57C2),
      date: 'Current',
      title: 'Rotor Riot Freestyle and Build Updates',
      summary:
          'Rotor Riot weekly uploads and article updates covering freestyle progression, equipment builds, and tuning workflows.',
      source: 'Rotor Riot',
      tag: 'FREESTYLE',
      url: 'https://rotorriot.com/',
    ),
    _DroneNewsItem(
      category: 'TECH',
      categoryColor: Color(0xFF26A69A),
      date: 'Current',
      title: 'Oscar Liang FPV Hardware Reviews and Setup Guides',
      summary:
          'Deep-dive comparison guides for FC/ESC stacks, digital video systems, ELRS gear, and practical setup tutorials.',
      source: 'Oscar Liang',
      tag: 'TECH',
      url: 'https://oscarliang.com/',
    ),
    _DroneNewsItem(
      category: 'TECH',
      categoryColor: Color(0xFF26A69A),
      date: 'Current',
      title: 'FPV Know-It-All and Bardwell Product Coverage',
      summary:
          'Joshua Bardwell tracks new releases, firmware changes, and reliability notes pilots use before buying race gear.',
      source: 'Joshua Bardwell',
      tag: 'TECH',
      url: 'https://www.fpvknowitall.com/',
    ),
    _DroneNewsItem(
      category: 'PILOTS',
      categoryColor: Color(0xFFEF5350),
      date: 'Latest',
      title: 'DRL Pilot Profiles and Team Updates',
      summary:
          'Roster-level pilot pages with bios, team affiliations, race records, and season-to-season movement tracking.',
      source: 'DRL',
      tag: 'PILOTS',
      url: 'https://thedroneracingleague.com/pilots/',
    ),
    _DroneNewsItem(
      category: 'FPV NEWS',
      categoryColor: Color(0xFFFF7043),
      date: 'Daily',
      title: 'DroneDJ FPV and Industry News Stream',
      summary:
          'Ongoing coverage of DJI updates, regulatory moves, new FPV hardware, and major race scene developments.',
      source: 'DroneDJ',
      tag: 'FPV',
      url: 'https://dronedj.com/',
    ),
    _DroneNewsItem(
      category: 'EVENTS',
      categoryColor: Color(0xFF42A5F5),
      date: 'Current',
      title: 'Red Bull FPV and Drone Event Coverage',
      summary:
          'Red Bull event stories and videos featuring elite FPV runs, race formats, and highlight reels from global showcases.',
      source: 'Red Bull',
      tag: 'EVENTS',
      url: 'https://www.redbull.com/',
    ),
    _DroneNewsItem(
      category: 'TRACK BUILDING',
      categoryColor: Color(0xFF8D6E63),
      date: 'Guide',
      title: 'How Clubs Build Safe FPV Race Courses',
      summary:
          'Practical field layout, gate spacing, pilot station setup, and safety separation principles used by race organizers.',
      source: 'MultiGP Guide',
      tag: 'TRACKS',
      url: 'https://www.multigp.com/resources/',
    ),
    _DroneNewsItem(
      category: 'FIRMWARE',
      categoryColor: Color(0xFF66BB6A),
      date: 'Latest',
      title: 'Betaflight Release and Tuning Documentation',
      summary:
          'Official notes for firmware releases, filtering changes, and tuning behavior that directly affect race performance.',
      source: 'Betaflight Docs',
      tag: 'TECH',
      url: 'https://betaflight.com/docs/wiki/getting-started',
    ),
    _DroneNewsItem(
      category: 'OPEN SOURCE RC',
      categoryColor: Color(0xFFAB47BC),
      date: 'Latest',
      title: 'ExpressLRS Project Updates for Competitive Pilots',
      summary:
          'Official ELRS updates for latency improvements, hardware compatibility, and receiver/transmitter setup guidance.',
      source: 'ExpressLRS',
      tag: 'TECH',
      url: 'https://www.expresslrs.org/',
    ),
  ];

  Widget _buildWorldNewsTab() {
    final sourceNews = _syntheticEnabled
        ? _droneNews
        : const <_DroneNewsItem>[];
    final filtered = _newsTag == 'ALL'
        ? sourceNews
        : sourceNews.where((n) => n.tag == _newsTag).toList();

    return CustomScrollView(
      slivers: [
        // Header banner
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _droneAccent.withValues(alpha: 0.18),
                  _droneAccent2.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _droneAccent.withValues(alpha: 0.35)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('\u{1F30D}', style: TextStyle(fontSize: 26)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FPV DRONE RACING',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Racing • Freestyle • Events • Tech • News',
                            style: TextStyle(
                              color: Color(0xFFFF6B00),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Live FPV drone racing updates — race results, event announcements, pilot rankings, track highlights, and drone tech news.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tag filter scroll strip
        SliverToBoxAdapter(
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final tag in [
                  'ALL',
                  'FPV',
                  'RACING',
                  'FREESTYLE',
                  'EVENTS',
                  'PILOTS',
                  'TRACKS',
                  'TECH',
                ])
                  GestureDetector(
                    onTap: () => setState(() => _newsTag = tag),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: tag == _newsTag
                            ? _droneAccent.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: tag == _newsTag
                              ? _droneAccent.withValues(alpha: 0.6)
                              : Colors.white24,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: tag == _newsTag
                              ? _droneAccent
                              : Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // News cards
        SliverList.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _DroneNewsCard(item: filtered[i]),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Source credit
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: const Text(
              'FPV and drone racing updates from DRL, FAI, MultiGP, Red Bull, DroneDJ, and community publishers.\n'
              'All content belongs to the original publishers; DFC links to sources for discovery.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGhostPromotionCallout() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _droneAccent.withValues(alpha: 0.2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DFC IN GHOST MODE',
            style: TextStyle(
              color: _droneAccent,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'We are promoting, not replacing. DFC stays behind the curtain, drives reach, pushes footage, lifts the event, and lets the promotion own the face of it.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIbcMomentumCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _droneAccent.withValues(alpha: 0.16),
            _droneAccent2.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _droneAccent.withValues(alpha: 0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'IBC 03 MOMENTUM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Hardman vs Tuhu. Cutler vs Modini. Brawl Pen pressure. Main Event, Kayo, Sky NZ and the global push. DFC is the ghost engine building the wave while IBC stays at the front.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniTag(label: 'HARDMAN vs TUHU', color: _droneAccent),
              _MiniTag(label: 'CUTLER vs MODINI', color: _droneAccent2),
              _MiniTag(label: 'WATCH LIVE', color: Colors.white54),
              _MiniTag(label: 'LEGENDS INBOUND', color: Color(0xFF4FC3F7)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkyTrackLaunchPadCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _droneAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: const SizedBox(
              width: 116,
              height: 92,
              child: DfcImage(
                url: 'https://img.youtube.com/vi/aDm1WUkwrCg/hqdefault.jpg',
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SKY TRACK DRONES LAUNCH PAD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.9,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Coming soon: track-side drone ops, walkout capture, training-camp follows, sponsor flight lanes, and launch-pad deployment for event footage.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10.8,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendsOnWayInCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4FC3F7).withValues(alpha: 0.16),
            _droneAccent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF4FC3F7).withValues(alpha: 0.24),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEGENDS ON THE WAY IN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'IBC 3 is the gateway moment. The old walls are opening, the next names are stepping through, and DFC is behind the scenes making sure the audience is already there when they arrive.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniTag(label: 'ISAAC HARDMAN', color: _droneAccent),
              _MiniTag(label: 'JAY CUTLER', color: Color(0xFF4FC3F7)),
              _MiniTag(label: 'LUKE MODINI', color: _droneAccent2),
              _MiniTag(label: 'JONATHAN TUHU', color: Colors.white54),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkyTrackOpsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _droneAccent.withValues(alpha: 0.18)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SKY TRACK OPS BOARD',
            style: TextStyle(
              color: _droneAccent,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Launch Pad staging will sit here: drone assigned to event, battery rotation, pilot call times, walkout route, ring-fly line, no-fly windows, sponsor hit list, and post-fight replay capture.',
            style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.45),
          ),
        ],
      ),
    );
  }
}
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// DATA MODELS (local)
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _RaceEvent {
  final String name, track, location, date, format, difficulty, prizePool;
  final String imageUrl;
  final int pilotsRegistered;
  final bool isLive;
  const _RaceEvent({
    required this.name,
    required this.track,
    required this.location,
    required this.date,
    required this.format,
    required this.difficulty,
    required this.pilotsRegistered,
    required this.prizePool,
    required this.imageUrl,
    this.isLive = false,
  });
}

class _DroneProduct {
  final String name, description, price, seller, tag, emoji, imageUrl;
  const _DroneProduct({
    required this.name,
    required this.description,
    required this.price,
    required this.seller,
    required this.tag,
    required this.emoji,
    required this.imageUrl,
  });
}

class _LeaderEntry {
  final int rank, points, wins;
  final String callsign, bestLap;
  const _LeaderEntry({
    required this.rank,
    required this.callsign,
    required this.points,
    required this.wins,
    required this.bestLap,
  });
}

class _HangarDrone {
  final String name, frame, motors, vtx, battery, status, emoji, imageUrl;
  const _HangarDrone({
    required this.name,
    required this.frame,
    required this.motors,
    required this.vtx,
    required this.battery,
    required this.status,
    required this.emoji,
    required this.imageUrl,
  });
}

class _PromoPanel {
  final String title;
  final String subtitle;
  final String body;
  final String badge;
  final String cta;
  final String route;
  final String imageUrl;

  const _PromoPanel({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.badge,
    required this.cta,
    required this.route,
    required this.imageUrl,
  });
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// WIDGETS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

// â”€â”€ Tab bar delegate â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext ctx, double shrink, bool overlap) {
    return Container(color: _droneBg, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate old) => false;
}

// â”€â”€ Race Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _RaceCard extends StatelessWidget {
  final _RaceEvent race;
  const _RaceCard({required this.race});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: race.isLive
              ? _droneAccent.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 132,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DfcImage(url: race.imageUrl),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Text(
                      race.track,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  race.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (race.isLive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.red, size: 6),
                      SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${race.location}  â€¢  ${race.date}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip(race.format, _droneAccent),
              _chip(race.difficulty, _difficultyColor(race.difficulty)),
              _chip('${race.pilotsRegistered} pilots', Colors.white38),
              _chip(race.prizePool, _droneAccent2),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Registering for ${race.name}...')),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _droneAccent.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                race.isLive ? 'WATCH LIVE' : 'REGISTER',
                style: const TextStyle(
                  color: _droneAccent,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );

  Color _difficultyColor(String d) {
    switch (d) {
      case 'Rookie':
        return Colors.green;
      case 'Amateur':
        return Colors.lightBlue;
      case 'Pro':
        return _droneAccent;
      case 'Elite':
        return Colors.purple;
      case 'Nightmare':
        return Colors.red;
      default:
        return Colors.white54;
    }
  }
}

// â”€â”€ Product Card (Marketplace) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ProductCard extends StatelessWidget {
  final _DroneProduct product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 92,
              height: 92,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DfcImage(url: product.imageUrl),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          product.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _droneAccent2.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        product.tag,
                        style: const TextStyle(
                          color: _droneAccent2,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      product.price,
                      style: const TextStyle(
                        color: _droneAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      product.seller,
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _droneAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'BUY',
                        style: TextStyle(
                          color: _droneAccent,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
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

// â”€â”€ Leaderboard Row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _LeaderRow extends StatelessWidget {
  final _LeaderEntry entry;
  const _LeaderRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final medals = ['', 'ðŸ¥‡', 'ðŸ¥ˆ', 'ðŸ¥‰'];
    final medal = entry.rank <= 3 ? medals[entry.rank] : '#${entry.rank}';
    final highlight = entry.rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: highlight
            ? _droneAccent.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? _droneAccent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              medal,
              style: TextStyle(
                fontSize: entry.rank <= 3 ? 20 : 14,
                color: Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.callsign,
                  style: TextStyle(
                    color: highlight ? _droneAccent : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${entry.wins} wins  â€¢  Best: ${entry.bestLap}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.points}',
                style: const TextStyle(
                  color: _droneAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const Text(
                'RP',
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Hangar Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _HangarCard extends StatelessWidget {
  final _HangarDrone drone;
  const _HangarCard({required this.drone});

  @override
  Widget build(BuildContext context) {
    final ready = drone.status == 'Race Ready';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ready
              ? _droneAccent.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 76,
              height: 76,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DfcImage(url: drone.imageUrl),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          drone.emoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drone.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${drone.frame}  â€¢  ${drone.motors}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                Text(
                  '${drone.vtx}  â€¢  ${drone.battery}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: ready
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              drone.status,
              style: TextStyle(
                color: ready ? Colors.green : Colors.amber,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── FPV Video (data model) ────────────────────────────────────────────
class _FpvVideo {
  final String title, channel, videoId, url, category, description, views;
  const _FpvVideo({
    required this.title,
    required this.channel,
    required this.videoId,
    required this.url,
    required this.category,
    required this.description,
    required this.views,
  });

  /// Real YouTube thumbnail URL
  String get thumbnailUrl =>
      'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
}

// ── FPV Video Card ────────────────────────────────────────────────────
class _FpvVideoCard extends StatelessWidget {
  final _FpvVideo video;
  const _FpvVideoCard({required this.video});

  Color get _catColor {
    switch (video.category) {
      case 'RACE':
        return const Color(0xFFFF3366);
      case 'FREESTYLE':
        return const Color(0xFF00F5FF);
      case 'CINEMATIC':
        return const Color(0xFF7B2FF7);
      case 'TECH':
        return const Color(0xFFFFD600);
      case 'DFC':
        return const Color(0xFFFF6B00);
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(video.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _catColor.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Real YouTube Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DfcNetworkImage(url: video.thumbnailUrl),
                    // Gradient overlay for badges
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.55),
                            ],
                            stops: const [0.4, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Play button
                    Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _catColor.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _catColor.withValues(alpha: 0.4),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Category badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          video.category,
                          style: TextStyle(
                            color: _catColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    // YouTube badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_circle_fill,
                              color: Color(0xFFFF1744),
                              size: 11,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'YouTube',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Views
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.visibility,
                              size: 11,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              video.views,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              video.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              video.channel,
              style: TextStyle(
                color: _catColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              video.description,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.open_in_new,
                  size: 12,
                  color: _catColor.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  'WATCH ON YOUTUBE',
                  style: TextStyle(
                    color: _catColor.withValues(alpha: 0.6),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── FPV Tech Item (info row) ──────────────────────────────────────────
class _FpvTechItem extends StatelessWidget {
  final String title;
  final String info;
  const _FpvTechItem({required this.title, required this.info});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFBB86FC),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            info,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drone News Item (data model) ──────────────────────────────────────
class _DroneNewsItem {
  final String category, date, title, summary, source, tag, url;
  final Color categoryColor;
  const _DroneNewsItem({
    required this.category,
    required this.categoryColor,
    required this.date,
    required this.title,
    required this.summary,
    required this.source,
    required this.tag,
    required this.url,
  });
}

// ── Drone News Card ────────────────────────────────────────────────────
class _DroneNewsCard extends StatelessWidget {
  final _DroneNewsItem item;
  const _DroneNewsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(item.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: item.categoryColor.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: item.categoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.category,
                    style: TextStyle(
                      color: item.categoryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    item.tag,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.date,
                  style: const TextStyle(color: Colors.white30, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.summary,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Source: ${item.source}',
              style: const TextStyle(
                color: _droneAccent2,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: item.categoryColor.withValues(alpha: 0.9),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoPanelCard extends StatelessWidget {
  final _PromoPanel panel;
  final VoidCallback onTap;

  const _PromoPanelCard({required this.panel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 292,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _droneAccent.withValues(alpha: 0.18)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DfcImage(url: panel.imageUrl),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.12),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _droneAccent.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        panel.badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      panel.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      panel.subtitle,
                      style: const TextStyle(
                        color: Color(0xFFFFB27A),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      panel.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10.8,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          panel.cta,
                          style: const TextStyle(
                            color: _droneAccent2,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward,
                          color: _droneAccent2,
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
