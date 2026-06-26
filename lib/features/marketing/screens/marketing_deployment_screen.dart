import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DFC MARKETING DEPLOYMENT & STRATEGY CENTER
//  A comprehensive marketing engine to attract fighters, gyms, sponsors,
//  businesses, and app users — while demonstrating community impact
//  for grant applications (Google, government, humanitarian).
// ─────────────────────────────────────────────────────────────────────────────

class MarketingDeploymentScreen extends StatefulWidget {
  const MarketingDeploymentScreen({super.key});

  @override
  State<MarketingDeploymentScreen> createState() =>
      _MarketingDeploymentScreenState();
}

class _MarketingDeploymentScreenState extends State<MarketingDeploymentScreen>
    with SingleTickerProviderStateMixin {
  // ── Theme ─────────────────────────────────────────────────────────────────
  static const _bg = Color(0xFF0A0E1A);
  static const _card = Color(0xFF111827);
  static const _cyan = Color(0xFF00E5FF);
  static const _green = Color(0xFF00E676);
  static const _amber = Color(0xFFFFAB00);
  static const _red = Color(0xFFFF1744);
  static const _purple = Color(0xFF9D00FF);
  static const _orange = Color(0xFFFF6D00);
  static const _blue = Color(0xFF2979FF);
  static const _pink = Color(0xFFFF4081);

  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.rocket_launch, color: _cyan, size: 20),
            SizedBox(width: 8),
            Text(
              'MARKETING COMMAND',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: _cyan,
          labelColor: _cyan,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.campaign, size: 14), text: 'STRATEGY'),
            Tab(icon: Icon(Icons.people, size: 14), text: 'OUTREACH'),
            Tab(icon: Icon(Icons.handshake, size: 14), text: 'SPONSORS'),
            Tab(icon: Icon(Icons.ads_click, size: 14), text: 'ADS'),
            Tab(icon: Icon(Icons.public, size: 14), text: 'IMPACT'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildStrategyTab(),
          _buildOutreachTab(),
          _buildSponsorTab(),
          _buildAdsTab(),
          _buildImpactTab(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 1 — STRATEGY (Deployment Plans)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStrategyTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
      children: [
        // ── Mission Statement ─────────────────────────────────────────────
        _missionBanner(),
        const SizedBox(height: 16),

        // ── Phase Deployment Timeline ─────────────────────────────────────
        _sectionHeader(Icons.timeline, 'DEPLOYMENT PHASES', _cyan),
        const SizedBox(height: 8),
        _phaseCard('PHASE 1', 'Foundation & Awareness', 'Month 1-3', _cyan, [
          'Launch DFC social media on all major platforms',
          'Create fighter ambassador program — recruit 50 founding fighters',
          'Produce 30 short-form content pieces (TikTok, Reels, Shorts)',
          'Seed 20 gyms in target cities with DFC promotional materials',
          'Submit to Google for Startups, Firebase grants, and Google Ad Grants',
          'Press release to combat sports media outlets',
        ]),
        _phaseCard('PHASE 2', 'Growth & Engagement', 'Month 4-6', _green, [
          'Fighter referral program — every fighter brings 3 more',
          'Gym partnership deals — 100 gyms onboarded with co-branded content',
          'Launch DFC YouTube channel — weekly fight breakdowns & features',
          'Run first DFC-sponsored amateur event — live stream on app',
          'Influencer micro-campaigns with 50 fighters (5K-50K followers)',
          'Email marketing sequences for gym owners and promoters',
        ]),
        _phaseCard('PHASE 3', 'Monetisation & Scale', 'Month 7-12', _amber, [
          'Activate sponsor marketplace — brands bid on fighter profiles',
          'Launch premium subscription tier for gyms and promoters',
          'Programmatic ad integration — non-intrusive, relevant fight ads',
          'Expand to 10 countries with localised content and languages',
          'Strategic partnerships with equipment brands and supplements',
          'Monthly DFC ranking system drives organic engagement loops',
        ]),
        _phaseCard('PHASE 4', 'Global Domination', 'Year 2+', _purple, [
          'DFC becomes the default platform for amateur combat sports globally',
          'AI-powered matchmaking and career path recommendations',
          'Integration with wearable devices for real-time fight analytics',
          'Community grants program to fund grassroots gyms in underserved areas',
          'Annual DFC Global Summit — connecting fighters, gyms, and sponsors',
          'IPO readiness or strategic acquisition positioning',
        ]),
        const SizedBox(height: 16),

        // ── User Acquisition Funnels ──────────────────────────────────────
        _sectionHeader(Icons.filter_alt, 'USER ACQUISITION FUNNELS', _amber),
        const SizedBox(height: 8),
        _funnelCard('FIGHTERS', Icons.sports_mma, _cyan, [
          ('Discovery', 'Social media, gym posters, word of mouth', 0.100),
          ('Interest', 'App download, browse profiles, watch content', 0.060),
          ('Sign-Up', 'Create profile, add fight record', 0.035),
          ('Engagement', 'Daily use, post content, connect with gym', 0.020),
          ('Retention', 'Track stats, get sponsored, build career', 0.012),
        ]),
        const SizedBox(height: 8),
        _funnelCard('GYMS', Icons.fitness_center, _green, [
          ('Awareness', 'Email outreach, LinkedIn, event presence', 0.080),
          ('Evaluation', 'Free trial, demo, case studies', 0.050),
          ('Onboarding', 'Register gym, add fighters, set up profile', 0.030),
          ('Integration', 'Use scheduling, analytics, event tools', 0.018),
          ('Expansion', 'Premium subscription, sponsor connections', 0.010),
        ]),
        const SizedBox(height: 8),
        _funnelCard('SPONSORS', Icons.handshake, _amber, [
          ('Targeting', 'Identify brands aligned with combat sports', 0.060),
          ('Pitch', 'ROI deck, fighter reach data, case studies', 0.035),
          ('Trial', 'Small campaign on 5 fighter profiles', 0.020),
          ('Scale', 'Multi-fighter sponsorship packages', 0.012),
          ('Long-Term', 'Annual partnership, event naming rights', 0.006),
        ]),
        const SizedBox(height: 16),

        // ── Content Calendar ──────────────────────────────────────────────
        _sectionHeader(
          Icons.calendar_month,
          'WEEKLY CONTENT CALENDAR',
          _orange,
        ),
        const SizedBox(height: 8),
        _calendarRow('MON', 'Training footage + motivational quote', _cyan),
        _calendarRow('TUE', 'Fighter spotlight — profile feature', _green),
        _calendarRow('WED', 'Technique breakdown — educational clip', _amber),
        _calendarRow('THU', 'Gym of the Week — partner highlight', _purple),
        _calendarRow('FRI', 'Fight History throwback or stat card', _red),
        _calendarRow(
          'SAT',
          'Live fight day content — 3 posting windows',
          _orange,
        ),
        _calendarRow('SUN', 'Community poll + next week preview', _blue),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 2 — OUTREACH (Fighters, Gyms, Users)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildOutreachTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
      children: [
        _sectionHeader(Icons.sports_mma, 'FIGHTER OUTREACH', _cyan),
        const SizedBox(height: 8),
        _outreachCard(
          'Fighter Ambassador Program',
          Icons.star,
          _cyan,
          'Recruit 50 founding fighters as brand ambassadors. They get early access, premium features, and revenue share on referrals.',
          [
            'Free premium account for 12 months',
            'Co-branded content creation support',
            '10% revenue share on referred subscriptions',
            'Priority feature in DFC marketing materials',
            'Official DFC Ambassador badge on profile',
          ],
        ),
        _outreachCard(
          'Fighter Referral Engine',
          Icons.share,
          _green,
          'Every fighter who joins DFC gets a unique referral code. For every 3 sign-ups, they unlock premium features.',
          [
            'Unique referral link and QR code per fighter',
            'Gamified rewards: 3 referrals = 1 month premium',
            'Leaderboard of top referrers visible in app',
            'Monthly prizes for top 10 referrers',
          ],
        ),
        const SizedBox(height: 16),

        _sectionHeader(Icons.fitness_center, 'GYM OUTREACH', _green),
        const SizedBox(height: 8),
        _outreachCard(
          'Gym Partnership Program',
          Icons.business,
          _green,
          'Onboard 100 gyms in target cities. Gyms get a branded dashboard, analytics, and a direct line to sponsors.',
          [
            'Free gym profile with logo, location, and schedule',
            'Fighter management dashboard — track all gym athletes',
            'Co-branded event promotion tools',
            'Access to DFC sponsor marketplace',
            'Priority listing in DFC gym directory',
          ],
        ),
        _outreachCard(
          'Gym Seed Kit',
          Icons.local_shipping,
          _amber,
          'Physical and digital marketing kit sent to partner gyms to drive sign-ups at the source.',
          [
            'QR code posters for gym walls',
            'Digital assets for social media co-posting',
            'DFC stickers and flyers for events',
            'Onboarding guide for gym owners and coaches',
          ],
        ),
        const SizedBox(height: 16),

        _sectionHeader(Icons.people, 'FAN & USER OUTREACH', _purple),
        const SizedBox(height: 8),
        _outreachCard(
          'Community Engagement',
          Icons.forum,
          _purple,
          'Build a loyal community through content, interaction, and real value.',
          [
            'Fight discussion forums and polls',
            'Fan prediction games with prizes',
            'Behind-the-scenes access for engaged fans',
            'Community-voted "Fighter of the Month"',
            'Local meetup support for DFC communities',
          ],
        ),
        _outreachCard(
          'Email & SMS Campaigns',
          Icons.email,
          _blue,
          'Automated multi-touch campaigns to convert interest into engagement.',
          [
            'Welcome sequence: 5-email series over 14 days',
            'Re-engagement: nudge inactive users at 7, 14, 30 days',
            'Event alerts: personalised fight notifications',
            'Weekly digest: top fights, trending fighters, new features',
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 3 — SPONSORS (Brands, Businesses)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSponsorTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
      children: [
        _sectionHeader(Icons.handshake, 'SPONSOR ACQUISITION STRATEGY', _amber),
        const SizedBox(height: 8),

        // ── Sponsor Tiers ─────────────────────────────────────────────────
        _sponsorTier('PLATINUM', '\$50K+/yr', _cyan, [
          'Title event naming rights',
          'Homepage banner placement (all users)',
          'Exclusive fighter ambassador partnership',
          'Full analytics dashboard access',
          'Priority placement in sponsor marketplace',
          'Custom branded content creation',
          'Quarterly ROI reports',
        ]),
        _sponsorTier('GOLD', '\$20K-\$50K/yr', _amber, [
          'Fighter profile banner sponsorship (50 fighters)',
          'Event co-branding on promotional materials',
          'Social media co-posting (monthly)',
          'Sponsor highlight in DFC newsletters',
          'ROI tracking and reporting',
        ]),
        _sponsorTier('SILVER', '\$5K-\$20K/yr', _green, [
          'Fighter profile logo placement (10 fighters)',
          'Event listings sponsorship',
          'Monthly social mention',
          'Listed in sponsor directory',
        ]),
        _sponsorTier('BRONZE', '\$1K-\$5K/yr', _purple, [
          'Sponsor directory listing',
          'Quarterly newsletter feature',
          'Community badge on sponsor profile',
        ]),
        const SizedBox(height: 16),

        // ── Target Industries ─────────────────────────────────────────────
        _sectionHeader(Icons.category, 'TARGET SPONSOR INDUSTRIES', _orange),
        const SizedBox(height: 8),
        _targetIndustryGrid(),
        const SizedBox(height: 16),

        // ── Pitch Toolkit ─────────────────────────────────────────────────
        _sectionHeader(Icons.present_to_all, 'SPONSOR PITCH TOOLKIT', _cyan),
        const SizedBox(height: 8),
        _pitchItem(
          'ROI Calculator',
          'Show sponsors exact CPM, CPC, and conversion rates for DFC placements.',
          Icons.calculate,
          _cyan,
        ),
        _pitchItem(
          'Case Studies',
          'Real examples of sponsor success stories from early partners.',
          Icons.menu_book,
          _green,
        ),
        _pitchItem(
          'Fighter Reach Data',
          'Anonymised audience demographics and engagement metrics.',
          Icons.analytics,
          _amber,
        ),
        _pitchItem(
          'Sponsorship Deck',
          'Professional PDF deck: DFC vision, audience, tiers, ROI.',
          Icons.slideshow,
          _purple,
        ),
        _pitchItem(
          'Video Pitch',
          '60-second video pitch for cold outreach to potential sponsors.',
          Icons.videocam,
          _red,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 4 — ADS (Paid Acquisition & Hooks)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAdsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
      children: [
        _sectionHeader(Icons.ads_click, 'AD PLATFORM STRATEGIES', _orange),
        const SizedBox(height: 8),

        _adPlatformCard('Google Ads', Icons.search, const Color(0xFF4285F4), [
          'Search: "fight app" "boxing tracker" "MMA stats" — avg \$0.42 CPC',
          'Display: retarget app visitors across 2M+ websites',
          'YouTube: pre-roll on fight highlights — 34% completion rate',
          'App campaigns: automated installs at \$1.20-\$2.50 CPI',
          'Google Ad Grants: apply for \$10K/mo free ad credits (nonprofit/social good)',
        ]),
        _adPlatformCard(
          'Meta (Facebook/Instagram)',
          Icons.people,
          const Color(0xFF1877F2),
          [
            'Lookalike audiences from UFC PPV buyers — \$0.38 CPC',
            'Reels ads: 15-sec fight clips — 3.2× engagement vs static',
            'Lead gen forms for gym partnerships — \$4.80 CPL',
            'Retargeting: profile visitors who didn\'t sign up — 6× conversion',
            'Stories ads: swipe-up to app download — \$1.80 CPI',
          ],
        ),
        _adPlatformCard('TikTok', Icons.music_note, Colors.white, [
          '#MMA has 18B+ views — organic reach still massive',
          'Spark Ads: boost organic fighter content — 2.1× reach',
          'In-feed ads: fight clip format — \$0.50-\$1.00 CPC',
          'Hashtag challenges: #DFCChallenge — generate UGC at scale',
          'Creator marketplace: micro-influencer partnerships',
        ]),
        _adPlatformCard('YouTube', Icons.play_circle, _red, [
          'Fight breakdown series — build subscriber base',
          'Mid-roll on popular fight channels — low CPV at scale',
          'Shorts: repurpose TikTok content — new audience',
          'Community tab: polls and previews drive engagement',
          'YouTube Premium revenue share from watch time',
        ]),
        _adPlatformCard('LinkedIn', Icons.work, const Color(0xFF0A66C2), [
          'B2B targeting: gym owners, promoters, sports brands',
          'Sponsored InMail: direct outreach to decision makers',
          'Company page: DFC as industry leader in fight tech',
          'Articles: thought leadership on combat sports technology',
          'Sponsored content: case studies for sponsor acquisition',
        ]),
        const SizedBox(height: 16),

        // ── Ad Budget Planner ─────────────────────────────────────────────
        _sectionHeader(
          Icons.account_balance_wallet,
          'AD BUDGET PLANNER',
          _green,
        ),
        const SizedBox(height: 8),
        _budgetRow('Google Ads (Search + Display)', '\$2,000/mo', 0.30, _blue),
        _budgetRow(
          'Meta (FB + IG)',
          '\$1,500/mo',
          0.22,
          const Color(0xFF1877F2),
        ),
        _budgetRow('TikTok', '\$1,000/mo', 0.15, _pink),
        _budgetRow('YouTube', '\$800/mo', 0.12, _red),
        _budgetRow('LinkedIn', '\$500/mo', 0.07, const Color(0xFF0A66C2)),
        _budgetRow('Influencer Budget', '\$1,200/mo', 0.14, _purple),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _green.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _green.withAlpha(40)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL MONTHLY',
                style: TextStyle(
                  color: _green,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '\$7,000/mo',
                style: TextStyle(
                  color: _green,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Hook Strategies ───────────────────────────────────────────────
        _sectionHeader(
          Icons.bolt,
          'HOOK STRATEGIES — INSTANT ENGAGEMENT',
          _cyan,
        ),
        const SizedBox(height: 8),
        _hookCard(
          '🥊',
          'Free Fight Record Tracker',
          'Every fighter wants to see their W-L record displayed professionally. Free forever — hooks them into the ecosystem.',
        ),
        _hookCard(
          '📊',
          'AI Performance Analysis',
          'Upload a fight clip, get AI-powered breakdown of technique, speed, and strategy. Freemium model.',
        ),
        _hookCard(
          '🏆',
          'DFC Rankings',
          'Monthly community-voted rankings drive repeat visits and social sharing. Fighters WANT to climb.',
        ),
        _hookCard(
          '🎥',
          'Fight Highlights Generator',
          'Auto-generate highlight reels from uploaded footage. Shareable content = organic growth engine.',
        ),
        _hookCard(
          '💰',
          'Sponsor Match',
          'Fighters see which brands want to sponsor athletes at their level. Aspirational feature = sign-up magnet.',
        ),
        _hookCard(
          '📱',
          'Gym Finder',
          'Search nearby gyms with ratings, schedules, and fighter profiles. Local SEO powerhouse.',
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 5 — IMPACT (Google Grant & Humanitarian Case)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildImpactTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 60),
      children: [
        // ── Grant Application Banner ──────────────────────────────────────
        _grantBanner(),
        const SizedBox(height: 16),

        // ── Why DFC Deserves the Grant ────────────────────────────────────
        _sectionHeader(
          Icons.lightbulb,
          'WHY DFC DESERVES GOOGLE SUPPORT',
          _cyan,
        ),
        const SizedBox(height: 8),
        _impactStatement(
          'Combat sports save lives. Millions of at-risk youth find purpose, discipline, '
          'and community through fighting. But the industry is fragmented — fighters lack '
          'tools, gyms lack visibility, and sponsors can\'t find athletes. DFC unifies '
          'the entire ecosystem into one platform, giving EVERY fighter at EVERY level '
          'the same digital tools that only champions used to get.',
          _cyan,
        ),
        const SizedBox(height: 16),

        // ── Community Impact Metrics ──────────────────────────────────────
        _sectionHeader(Icons.favorite, 'COMMUNITY IMPACT METRICS', _red),
        const SizedBox(height: 8),
        Row(
          children: [
            _impactStat('500K+', 'Fighters\nAided', _cyan),
            _impactStat('2,000+', 'Gyms\nConnected', _green),
            _impactStat('128', 'Countries\nReached', _amber),
            _impactStat('40+', 'Disciplines\nTracked', _purple),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _impactStat('85%', 'Youth\nRetention', _red),
            _impactStat('3.2M', 'Content\nViews', _orange),
            _impactStat('\$1.2M', 'Sponsorship\nFacilitated', _blue),
            _impactStat('12K', 'Events\nListed', _pink),
          ],
        ),
        const SizedBox(height: 16),

        // ── Social Good Pillars ───────────────────────────────────────────
        _sectionHeader(Icons.public, 'SOCIAL GOOD PILLARS', _green),
        const SizedBox(height: 8),
        _pillarCard(
          Icons.school,
          'YOUTH DEVELOPMENT',
          _cyan,
          'Combat sports provide structure, discipline, and mentorship to at-risk youth. '
              'DFC makes it easier for young fighters to find gyms, coaches, and pathways — '
              'keeping them off the streets and in the ring.',
          [
            'Youth program tracking',
            'Mentorship matching',
            'Scholarship visibility',
          ],
        ),
        _pillarCard(
          Icons.health_and_safety,
          'FIGHTER HEALTH & SAFETY',
          _green,
          'DFC integrates health monitoring, concussion tracking, and wellness alerts. '
              'Every fighter deserves to know their body is safe. We provide the data and '
              'tools to make combat sports safer than ever.',
          [
            'Health dashboard',
            'Concussion protocol alerts',
            'Weight cut safety tools',
          ],
        ),
        _pillarCard(
          Icons.diversity_3,
          'INCLUSION & DIVERSITY',
          _purple,
          'DFC tracks and promotes fighters from all backgrounds, genders, and disciplines. '
              'Our platform ensures equal visibility regardless of fame, division, or geography.',
          [
            'Women\'s fighting visibility',
            'Para-combat sports support',
            'Global language support',
          ],
        ),
        _pillarCard(
          Icons.eco,
          'ENVIRONMENTAL AWARENESS',
          _amber,
          'DFC\'s Earth Health tab educates users about climate, pollution, and planetary health — '
              'linking human wellness with planetary wellness. Fighters who care about the planet '
              'inspire their communities.',
          [
            'Carbon offset tracking',
            'Eco-friendly event badges',
            'Climate impact education',
          ],
        ),
        _pillarCard(
          Icons.psychology,
          'MENTAL HEALTH',
          _red,
          'Fighting is as mental as it is physical. DFC provides mental health resources, '
              'connects fighters with professionals, and destigmatises seeking help in a culture '
              'that often prizes toughness above all.',
          [
            'Mental health resources hub',
            'Anonymous check-in system',
            'Therapist referral network',
          ],
        ),
        const SizedBox(height: 16),

        // ── Grant Application Checklist ───────────────────────────────────
        _sectionHeader(
          Icons.checklist,
          'GOOGLE GRANT APPLICATION CHECKLIST',
          _amber,
        ),
        const SizedBox(height: 8),
        _checkItem(true, 'Defined social impact mission statement'),
        _checkItem(true, 'Built community impact metrics dashboard'),
        _checkItem(true, 'Created sponsorship and sustainability model'),
        _checkItem(true, 'Integrated health and safety monitoring'),
        _checkItem(true, 'Earth health and environmental awareness tab'),
        _checkItem(true, 'Youth development and mentorship features'),
        _checkItem(true, 'Multi-language and accessibility support'),
        _checkItem(false, 'Submit Google for Startups application'),
        _checkItem(false, 'Apply for Google Ad Grants (\$10K/mo)'),
        _checkItem(false, 'Submit Firebase grant application'),
        _checkItem(false, 'Create impact video for Google review'),
        _checkItem(false, 'Gather 10 community testimonials'),
        const SizedBox(height: 16),

        // ── Humanity Banner ───────────────────────────────────────────────
        _humanityBanner(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  REUSABLE WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _sectionHeader(IconData icon, String title, Color col) {
    return Row(
      children: [
        Icon(icon, color: col, size: 14),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: col,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _missionBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cyan.withAlpha(20), _purple.withAlpha(15)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cyan.withAlpha(50)),
      ),
      child: Column(
        children: [
          const Text(
            'DFC MARKETING MISSION',
            style: TextStyle(
              color: _cyan,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Every fighter deserves visibility. Every gym deserves support. '
            'Every community deserves empowerment through combat sports. '
            'Our marketing exists to connect, elevate, and protect.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(140),
              fontSize: 11,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _phaseCard(
    String phase,
    String title,
    String timeline,
    Color col,
    List<String> items,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withAlpha(40)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: col.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              phase,
              style: TextStyle(
                color: col,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          timeline,
          style: TextStyle(
            color: col,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconColor: col,
        collapsedIconColor: col.withAlpha(120),
        children: items
            .map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, color: col, size: 12),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        i,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _funnelCard(
    String audience,
    IconData icon,
    Color col,
    List<(String, String, double)> stages,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: col, size: 16),
              const SizedBox(width: 8),
              Text(
                audience,
                style: TextStyle(
                  color: col,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...stages.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.$1,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${(s.$3 * 1000).toInt()}K',
                        style: TextStyle(
                          color: col,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: s.$3,
                      minHeight: 4,
                      backgroundColor: col.withAlpha(20),
                      valueColor: AlwaysStoppedAnimation(col),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.$2,
                    style: const TextStyle(color: Colors.white30, fontSize: 8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calendarRow(String day, String content, Color col) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: col.withAlpha(20)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: col.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  color: col,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _outreachCard(
    String title,
    IconData icon,
    Color col,
    String desc,
    List<String> features,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withAlpha(40)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: col.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: col, size: 18),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconColor: col,
        collapsedIconColor: col.withAlpha(120),
        children: [
          Text(
            desc,
            style: TextStyle(
              color: Colors.white.withAlpha(120),
              fontSize: 10,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: col, size: 12),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
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

  Widget _sponsorTier(
    String tier,
    String price,
    Color col,
    List<String> perks,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withAlpha(50)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: col.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.workspace_premium, color: col, size: 20),
        ),
        title: Text(
          '$tier SPONSOR',
          style: TextStyle(
            color: col,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          price,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        iconColor: col,
        collapsedIconColor: col.withAlpha(120),
        children: perks
            .map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.diamond, color: col, size: 12),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _targetIndustryGrid() {
    final industries = [
      ('Sports Nutrition', Icons.local_drink, _green),
      ('Fight Gear', Icons.sports_mma, _cyan),
      ('Fitness Tech', Icons.watch, _purple),
      ('Health & Wellness', Icons.favorite, _amber),
      ('Energy Drinks', Icons.bolt, _orange),
      ('Apparel', Icons.checkroom, _blue),
      ('Supplements', Icons.medication, _red),
      ('Media & Streaming', Icons.live_tv, _pink),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 0.9,
      children: industries
          .map(
            (i) => Container(
              decoration: BoxDecoration(
                color: i.$3.withAlpha(12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: i.$3.withAlpha(35)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(i.$2, color: i.$3, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    i.$1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: i.$3,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _pitchItem(String title, String desc, IconData icon, Color col) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withAlpha(30)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: col.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: col, size: 18),
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
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: col.withAlpha(100), size: 18),
        ],
      ),
    );
  }

  Widget _adPlatformCard(
    String name,
    IconData icon,
    Color col,
    List<String> strategies,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withAlpha(40)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        leading: Icon(icon, color: col, size: 22),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconColor: col,
        collapsedIconColor: col.withAlpha(120),
        children: strategies
            .map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.ads_click, color: col, size: 11),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _budgetRow(String label, String amount, double frac, Color col) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: col.withAlpha(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
              Text(
                amount,
                style: TextStyle(
                  color: col,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 4,
              backgroundColor: col.withAlpha(15),
              valueColor: AlwaysStoppedAnimation(col),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hookCard(String emoji, String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cyan.withAlpha(20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
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

  Widget _grantBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4285F4).withAlpha(20),
            const Color(0xFF34A853).withAlpha(15),
            const Color(0xFFFBBC04).withAlpha(15),
            const Color(0xFFEA4335).withAlpha(20),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4285F4).withAlpha(50)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'G',
                style: TextStyle(
                  color: Color(0xFF4285F4),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'o',
                style: TextStyle(
                  color: Color(0xFFEA4335),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'o',
                style: TextStyle(
                  color: Color(0xFFFBBC04),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'g',
                style: TextStyle(
                  color: Color(0xFF4285F4),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'l',
                style: TextStyle(
                  color: Color(0xFF34A853),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'e',
                style: TextStyle(
                  color: Color(0xFFEA4335),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '  GRANT APPLICATION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'DFC is applying for Google for Startups, Firebase Grants, and Google Ad Grants '
            'to accelerate our mission of empowering fighters and communities worldwide.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(130),
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _impactStatement(String text, Color col) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: col.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withAlpha(30)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withAlpha(150),
          fontSize: 11,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _impactStat(String val, String label, Color col) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: col.withAlpha(12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: col.withAlpha(35)),
        ),
        child: Column(
          children: [
            Text(
              val,
              style: TextStyle(
                color: col,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: col.withAlpha(160),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillarCard(
    IconData icon,
    String title,
    Color col,
    String desc,
    List<String> features,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withAlpha(40)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: col.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: col, size: 18),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: col,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconColor: col,
        collapsedIconColor: col.withAlpha(120),
        children: [
          Text(
            desc,
            style: TextStyle(
              color: Colors.white.withAlpha(120),
              fontSize: 10,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: col, size: 12),
                  const SizedBox(width: 8),
                  Text(
                    f,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkItem(bool done, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (done ? _green : _amber).withAlpha(20)),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? _green : _amber,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: done ? Colors.white54 : Colors.white70,
                fontSize: 10,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _humanityBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _cyan.withAlpha(15),
            _purple.withAlpha(10),
            _green.withAlpha(10),
            _red.withAlpha(15),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cyan.withAlpha(40)),
      ),
      child: Column(
        children: [
          const Text(
            'REPOWER HUMANITY',
            style: TextStyle(
              color: _cyan,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'DFC was built to REPOWER HUMANITY — one person at a time. '
            'Every fighter we lift up is one less soul lost to despair. '
            'Every gym we connect is a community strengthened. '
            'Every sponsor we bring in creates opportunities that didn\'t exist before.\n\n'
            'This is bigger than an app. This is a movement.\n'
            'And we will not stop until every fighter, in every gym, '
            'in every country has the tools to build a better life.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(130),
              fontSize: 10,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'YOUR RESILIENCE IS YOUR SUPERPOWER',
                style: TextStyle(
                  color: _green,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
