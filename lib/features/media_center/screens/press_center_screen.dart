import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC MEDIA & PRESS CENTER v1.0
///
/// The credibility machine. Press kits, media assets, embeddable widgets,
/// fight stats packages, and journalist quick-access.
///
/// Built from pain. Forged in battles. Hardened by resilience.
/// ═══════════════════════════════════════════════════════════════════════════

class PressCenterScreen extends StatefulWidget {
  const PressCenterScreen({super.key});

  @override
  State<PressCenterScreen> createState() => _PressCenterScreenState();
}

class _PressCenterScreenState extends State<PressCenterScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _scanCtrl;
  int _selectedTab = 0;

  final _tabs = const ['PRESS KIT', 'MEDIA ASSETS', 'STATS PACK', 'EMBED'];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, _) => Icon(
                Icons.newspaper,
                color: Color.lerp(
                  const Color(0xFF00E5FF),
                  const Color(0xFFFF0040),
                  _pulseCtrl.value,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'MEDIA & PRESS CENTER',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF00E5FF)),
            onPressed: () => _copyLink('https://datafightcentral.com/press'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildScanLine(),
          _buildTabBar(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanLine() {
    return AnimatedBuilder(
      animation: _scanCtrl,
      builder: (_, _) => Container(
        height: 2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFF00E5FF).withValues(alpha: _scanCtrl.value),
              Colors.transparent,
            ],
            stops: [
              math.max(0, _scanCtrl.value - 0.2),
              _scanCtrl.value,
              math.min(1, _scanCtrl.value + 0.2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      color: const Color(0xFF0A0A14),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _tabs.length,
        itemBuilder: (context, i) {
          final sel = i == _selectedTab;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: sel
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: sel ? const Color(0xFF00E5FF) : Colors.white12,
                  width: sel ? 1.5 : 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _tabs[i],
                style: TextStyle(
                  color: sel ? const Color(0xFF00E5FF) : Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildPressKit();
      case 1:
        return _buildMediaAssets();
      case 2:
        return _buildStatsPack();
      case 3:
        return _buildEmbedSection();
      default:
        return _buildPressKit();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: PRESS KIT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPressKit() {
    return ListView(
      key: const ValueKey('press-kit'),
      padding: const EdgeInsets.all(16),
      children: [
        _sectionBanner(
          'DATA FIGHT CENTRAL',
          'THE DIGITAL INFRASTRUCTURE OF COMBAT SPORTS',
          Icons.shield,
          const Color(0xFFFF0040),
        ),
        const SizedBox(height: 20),
        _infoCard(
          'ABOUT DFC',
          'Data Fight Central is the world\'s first all-in-one digital platform for combat sports. '
              'Built for fighters, promoters, gyms, and fans — DFC provides event management, PPV streaming, '
              'fighter profiles, live scoring, AI analytics, training tools, and community features all under one roof.\n\n'
              'Founded by DFC Founder, DFC was born from the trenches of Australian combat sports — '
              'built from pain, forged in battles, hardened by resilience.',
          Icons.info_outline,
        ),
        const SizedBox(height: 12),
        _infoCard(
          'KEY FACTS',
          '• Platform: datafightcentral.com\n'
              '• Domains: datafightcentral.com / .org\n'
              '• Founded: 2025, Gold Coast, Australia\n'
              '• Tech Stack: Flutter Web + Firebase + AI\n'
              '• 200+ screens, 130+ routes, 232K+ lines of code\n'
              '• Features: PPV, Live Scoring, Fighter Profiles, Training, AI Analytics\n'
              '• Social Good: NightChill Program (crisis intervention, DV protection, homeless support)\n'
              '• First Major Event: IBC III — March 7, 2026, Gold Coast',
          Icons.fact_check,
        ),
        const SizedBox(height: 12),
        _infoCard(
          'FOUNDER — DFC Founder',
          'Combat sports technologist and platform architect. '
              'Heath built DFC solo from the ground up — every screen, every animation, every line of code. '
              'His vision: give every fighter, every promoter, every gym access to the same digital tools '
              'that billion-dollar organizations use.\n\n'
              '"We\'re the turbo for combat sports. The fuel-injected promotional machine."',
          Icons.person,
        ),
        const SizedBox(height: 20),
        _ibcPressRelease(),
        const SizedBox(height: 20),
        _contactCard(),
      ],
    );
  }

  Widget _ibcPressRelease() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF0040).withValues(alpha: 0.15),
            const Color(0xFFFF6600).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF0040).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0040),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PRESS RELEASE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'March 6, 2026',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'DATA FIGHT CENTRAL LAUNCHES AS DIGITAL PARTNER FOR IBC III',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'GOLD COAST, AUSTRALIA — Data Fight Central (DFC), the world\'s first all-in-one combat sports '
            'digital platform, today announced its launch as the official digital infrastructure partner for '
            'IBC III: Gold Coast Brawl, taking place March 7, 2026 at Gold Coast Sports & Leisure Centre.\n\n'
            'The platform features dedicated event coverage including a live Event Day Command Centre, '
            'interactive fight card with tappable fighter profiles, PPV streaming integration (\$29.99 AUD), '
            'and real-time fight scoring capabilities.\n\n'
            'IBC III\'s 11-bout card is headlined by Jay Cutler vs Luke Modini for the Light Heavyweight Title '
            'in a scheduled five-round main event. Co-main billing goes to Isaac Hardman vs Jonathan Tuhu for the IBC Championship, '
            'with heavyweight, middleweight, welterweight, and lightweight matchups stacked underneath.\n\n'
            'Streaming is available on DFC, TrillerTV+, Kayo Sports, and in-person via Eventbrite ticketing.\n\n'
            '"We built DFC to be the digital engine for combat sports," said founder DFC Founder. '
            '"IBC III is the first event to run through our full stack — from fighter profiles to PPV to live scoring. '
            'This is what the future of combat sports technology looks like."',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _actionChip(
                'VIEW IBC III',
                Icons.live_tv,
                () => context.push('/ibc/live'),
              ),
              const SizedBox(width: 8),
              _actionChip(
                'COPY',
                Icons.copy,
                () => _copyLink(
                  'Data Fight Central launches as digital partner for IBC III. '
                  'Full event hub live at datafightcentral.com/ibc/live',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: MEDIA ASSETS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMediaAssets() {
    final assets = [
      const _AssetGroup('DFC BRAND', [
        _Asset(
          'DFC Logo (Full)',
          'PNG • 2048x2048',
          Icons.image,
          'dfc-logo-full.png',
        ),
        _Asset(
          'DFC Logo (Icon)',
          'PNG • 512x512',
          Icons.image,
          'dfc-logo-icon.png',
        ),
        _Asset(
          'DFC Logo (Dark BG)',
          'SVG • Vector',
          Icons.image,
          'dfc-logo-dark.svg',
        ),
        _Asset(
          'DFC Banner',
          'PNG • 1920x600',
          Icons.panorama,
          'dfc-banner.png',
        ),
        _Asset(
          'Brand Guidelines',
          'PDF • 12 pages',
          Icons.description,
          'dfc-brand-guide.pdf',
        ),
      ]),
      const _AssetGroup('IBC III EVENT', [
        _Asset(
          'IBC III Poster',
          'PNG • 1080x1920',
          Icons.image,
          'ibc3-poster.png',
        ),
        _Asset(
          'IBC III Fight Card',
          'PNG • 1080x1350',
          Icons.image,
          'ibc3-fightcard.png',
        ),
        _Asset(
          'IBC III Banner',
          'PNG • 1920x600',
          Icons.panorama,
          'ibc3-banner.png',
        ),
        _Asset(
          'Cutler vs Modini Promo',
          'PNG • 1080x1080',
          Icons.image,
          'cutler-vs-modini.png',
        ),
        _Asset(
          'Full 5-Bout Card Graphic',
          'PNG • 1080x1920',
          Icons.image,
          'ibc3-full-card.png',
        ),
      ]),
      const _AssetGroup('FIGHTER HEADSHOTS', [
        _Asset('Jay Cutler', 'PNG • 800x800', Icons.person, 'jay-cutler.png'),
        _Asset('Luke Modini', 'PNG • 800x800', Icons.person, 'luke-modini.png'),
        _Asset(
          'Isaac Hardman',
          'PNG • 800x800',
          Icons.person,
          'isaac-hardman.png',
        ),
        _Asset(
          'Jonathan Tuhu',
          'PNG • 800x800',
          Icons.person,
          'jonathan-tuhu.png',
        ),
        _Asset(
          'Nikita Davids',
          'PNG • 800x800',
          Icons.person,
          'nikita-davids.png',
        ),
        _Asset('Sarah King', 'PNG • 800x800', Icons.person, 'sarah-king.png'),
        _Asset(
          'Danny Torres',
          'PNG • 800x800',
          Icons.person,
          'danny-torres.png',
        ),
        _Asset('Koji Tanaka', 'PNG • 800x800', Icons.person, 'koji-tanaka.png'),
        _Asset(
          'Liam O\'Brien',
          'PNG • 800x800',
          Icons.person,
          'liam-obrien.png',
        ),
        _Asset(
          'Ratu Vunipola',
          'PNG • 800x800',
          Icons.person,
          'ratu-vunipola.png',
        ),
      ]),
      const _AssetGroup('SOCIAL MEDIA TEMPLATES', [
        _Asset(
          'Instagram Story Template',
          'PSD • 1080x1920',
          Icons.phone_android,
          'ig-story-template.psd',
        ),
        _Asset(
          'Twitter/X Header',
          'PNG • 1500x500',
          Icons.image,
          'twitter-header.png',
        ),
        _Asset('Facebook Cover', 'PNG • 820x312', Icons.image, 'fb-cover.png'),
        _Asset(
          'YouTube Thumbnail',
          'PNG • 1280x720',
          Icons.image,
          'yt-thumbnail.png',
        ),
      ]),
    ];

    return ListView(
      key: const ValueKey('media-assets'),
      padding: const EdgeInsets.all(16),
      children: [
        _sectionBanner(
          'MEDIA ASSETS',
          'DOWNLOADABLE BRAND & EVENT ASSETS',
          Icons.photo_library,
          const Color(0xFF00E5FF),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.amber, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Media assets available upon request. Contact press@datafightcentral.com for high-res files.',
                  style: TextStyle(
                    color: Colors.amber.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...assets.map(_buildAssetGroup),
      ],
    );
  }

  Widget _buildAssetGroup(_AssetGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 12),
          child: Text(
            group.title,
            style: const TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ),
        ...group.assets.map(
          (asset) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Icon(
                  asset.icon,
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        asset.spec,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
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
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    'REQUEST',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3: STATS PACK
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsPack() {
    return ListView(
      key: const ValueKey('stats-pack'),
      padding: const EdgeInsets.all(16),
      children: [
        _sectionBanner(
          'FIGHT STATS PACKAGE',
          'IBC III — GOLD COAST BRAWL • MARCH 7 2026',
          Icons.analytics,
          const Color(0xFFFF6600),
        ),
        const SizedBox(height: 20),

        // Event overview
        _statBlock('EVENT OVERVIEW', [
          const _StatRow('Event', 'IBC III: Gold Coast Brawl'),
          const _StatRow('Date', 'Saturday, March 7, 2026'),
          const _StatRow('Time', '7:00 PM AEST'),
          const _StatRow('Venue', 'Gold Coast Sports & Leisure Centre'),
          const _StatRow('Bouts', '11'),
          const _StatRow('Main Event', 'Cutler vs Modini — LHW Title (5 Rds)'),
          const _StatRow('PPV Price', '\$29.99 AUD'),
          const _StatRow('Broadcast', 'DFC, TrillerTV+, Kayo Sports'),
        ]),
        const SizedBox(height: 16),

        // Full fight card
        _statBlock('FULL FIGHT CARD', [
          const _StatRow(
            'MAIN EVENT',
            'Jay Cutler vs Luke Modini — Light Heavyweight Title, 5 Rds',
          ),
          const _StatRow(
            'CO-MAIN',
            'Isaac Hardman vs Jonathan Tuhu — IBC Championship, 5 Rds',
          ),
          const _StatRow(
            'BOUT 3',
            'Louis Kapua vs Viktor Rosinhaskev — Heavyweight, 3 Rds',
          ),
          const _StatRow(
            'BOUT 2',
            'Loulanting vs Cody Irvine — Middleweight, 3 Rds',
          ),
          const _StatRow(
            'OPENER',
            'Joshua Hepi vs Kane Halcrow — Lightweight, 3 Rds',
          ),
        ]),
        const SizedBox(height: 16),

        _statBlock('MAIN EVENT SPOTLIGHT — JAY CUTLER', [
          const _StatRow('Role', 'IBC III main event red corner'),
          const _StatRow('Fight', 'Luke Modini'),
          const _StatRow('Division', 'Light Heavyweight'),
          const _StatRow('Format', 'Championship · 5 rounds'),
          const _StatRow('Platform', 'DFC / TrillerTV+ / Kayo Sports'),
          const _StatRow('Storyline', 'Headlining the Gold Coast title bout'),
        ]),
        const SizedBox(height: 16),

        _statBlock('MAIN EVENT SPOTLIGHT — LUKE MODINI', [
          const _StatRow('Role', 'IBC III main event blue corner'),
          const _StatRow('Fight', 'Jay Cutler'),
          const _StatRow('Division', 'Light Heavyweight'),
          const _StatRow('Format', 'Championship · 5 rounds'),
          const _StatRow('Platform', 'DFC / TrillerTV+ / Kayo Sports'),
          const _StatRow(
            'Storyline',
            'Challenging for the featured Gold Coast headliner',
          ),
        ]),
        const SizedBox(height: 16),

        // Copy all stats
        Center(
          child: GestureDetector(
            onTap: () => _copyLink(
              'IBC III: Gold Coast Brawl — March 7, 2026 @ 7PM AEST\n'
              'Gold Coast Sports & Leisure Centre\n'
              'MAIN EVENT: Jay Cutler vs Luke Modini — LHW Title, 5 Rds\n'
              'CO-MAIN: Isaac Hardman vs Jonathan Tuhu — IBC Championship, 5 Rds\n'
              'BOUT 3: Louis Kapua vs Viktor Rosinhaskev — HW, 3 Rds\n'
              'BOUT 2: Loulanting vs Cody Irvine — MW, 3 Rds\n'
              'OPENER: Joshua Hepi vs Kane Halcrow — LW, 3 Rds\n'
              'PPV: \$29.99 AUD | Broadcast: DFC, TrillerTV+, Kayo\n'
              'datafightcentral.com/ibc/live',
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6600).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF6600)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy, color: Color(0xFFFF6600), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'COPY ALL STATS',
                    style: TextStyle(
                      color: Color(0xFFFF6600),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _statBlock(String title, List<_StatRow> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFF6600),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      row.label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 4: EMBED / API
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildEmbedSection() {
    return ListView(
      key: const ValueKey('embed'),
      padding: const EdgeInsets.all(16),
      children: [
        _sectionBanner(
          'EMBED & INTEGRATE',
          'PUT DFC ON YOUR SITE',
          Icons.code,
          const Color(0xFF00FF88),
        ),
        const SizedBox(height: 20),

        _embedBlock(
          'IBC III EVENT WIDGET',
          'Embed the live IBC III event hub on your website.',
          '<iframe src="https://datafightcentral.com/ibc/live"\n'
              '  width="100%" height="800" frameborder="0"\n'
              '  allow="autoplay; encrypted-media"\n'
              '  style="border-radius: 12px; border: 1px solid #333;">\n'
              '</iframe>',
        ),
        const SizedBox(height: 12),

        _embedBlock(
          'FIGHT CARD WIDGET',
          'Show the full IBC III fight card on your site.',
          '<iframe src="https://datafightcentral.com/ibc/fight-card"\n'
              '  width="100%" height="600" frameborder="0"\n'
              '  style="border-radius: 12px; border: 1px solid #333;">\n'
              '</iframe>',
        ),
        const SizedBox(height: 12),

        _embedBlock(
          'FIGHTER PROFILE WIDGET',
          'Embed any fighter\'s profile. Replace {fighterId}.',
          '<iframe src="https://datafightcentral.com/fighter/{fighterId}"\n'
              '  width="400" height="700" frameborder="0"\n'
              '  style="border-radius: 12px; border: 1px solid #333;">\n'
              '</iframe>',
        ),
        const SizedBox(height: 12),

        _embedBlock(
          'PPV PURCHASE LINK',
          'Direct link to PPV purchase page for IBC III.',
          'https://datafightcentral.com/ppv/ppv-ibc-03/watch',
        ),
        const SizedBox(height: 12),

        _embedBlock(
          'SOCIAL SHARE LINK',
          'Quick share link for IBC III event.',
          'https://datafightcentral.com/ibc/live\n\n'
              '<!-- Open Graph Tags for your site: -->\n'
              '<meta property="og:title" content="IBC III: Gold Coast Brawl — LIVE on DFC" />\n'
              '<meta property="og:description" content="Cutler vs Modini LHW Title. March 7, 2026. Watch on Data Fight Central." />\n'
              '<meta property="og:url" content="https://datafightcentral.com/ibc/live" />\n'
              '<meta property="og:type" content="website" />',
        ),
        const SizedBox(height: 12),

        _embedBlock(
          'JSON API — FIGHT CARD',
          'Structured data for the IBC III fight card (for media integrations).',
          '{\n'
              '  "event": "IBC III: Gold Coast Brawl",\n'
              '  "date": "2026-03-07T19:00:00+10:00",\n'
              '  "venue": "Gold Coast Sports & Leisure Centre",\n'
              '  "bouts": [\n'
              '    {"main": true, "f1": "Jay Cutler", "f2": "Luke Modini", "weight": "LHW", "rounds": 5, "title": true},\n'
              '    {"f1": "Blake Watts", "f2": "Jordan Silva", "weight": "WW", "rounds": 3},\n'
              '    {"f1": "Nikita Davids", "f2": "Sarah King", "weight": "SW", "rounds": 3},\n'
              '    {"f1": "Danny Torres", "f2": "Koji Tanaka", "weight": "LW", "rounds": 3},\n'
              '    {"f1": "Liam O\'Brien", "f2": "Ratu Vunipola", "weight": "HW", "rounds": 3}\n'
              '  ],\n'
              '  "ppv_price": 29.99,\n'
              '  "currency": "AUD",\n'
              '  "streams": ["DFC", "TrillerTV+", "Kayo Sports"]\n'
              '}',
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _embedBlock(String title, String description, String code) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00FF88).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF00FF88),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D1A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: SelectableText(
              code,
              style: const TextStyle(
                color: Color(0xFF00FF88),
                fontSize: 11,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _copyLink(code),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy, color: Color(0xFF00FF88), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'COPY CODE',
                      style: TextStyle(
                        color: Color(0xFF00FF88),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _sectionBanner(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, _) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.15 + _pulseCtrl.value * 0.05),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String body, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00E5FF), size: 18),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00E5FF).withValues(alpha: 0.1),
            const Color(0xFF6C00FF).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.email, color: Color(0xFF00E5FF), size: 20),
              SizedBox(width: 10),
              Text(
                'MEDIA CONTACT',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _contactRow('Press Inquiries', 'press@datafightcentral.com'),
          _contactRow('General', 'info@datafightcentral.com'),
          _contactRow('Partnerships', 'partnerships@datafightcentral.com'),
          _contactRow('Website', 'datafightcentral.com'),
          _contactRow('Domain', 'datafightcentral.com'),
          _contactRow('Founder', 'DFC Founder'),
        ],
      ),
    );
  }

  Widget _contactRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _copyLink(value),
              child: Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFF0040).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFFFF0040).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFFF0040), size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFFF0040),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyLink(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('📋 Copied to clipboard'),
        backgroundColor: Colors.green.shade900,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════════════════

class _AssetGroup {
  final String title;
  final List<_Asset> assets;
  const _AssetGroup(this.title, this.assets);
}

class _Asset {
  final String name;
  final String spec;
  final IconData icon;
  final String filename;
  const _Asset(this.name, this.spec, this.icon, this.filename);
}

class _StatRow {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);
}
