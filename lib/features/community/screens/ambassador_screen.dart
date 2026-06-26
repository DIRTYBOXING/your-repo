import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ═══════════════════════════════════════════════════════════════
/// DFC AMBASSADOR PROGRAM
///
/// Community champions who distribute Hope Cards, organise events,
/// represent DFC values, and help fighters & communities thrive.
///
/// Tiers: BRONZE → SILVER → GOLD → PLATINUM → CHAMPION
///
/// "Empowering everyday heroes to fight for their community"
/// ═══════════════════════════════════════════════════════════════

// ── Ambassador palette ──
const Color _ambCyan = Color(0xFF00F5FF);
const Color _ambGreen = Color(0xFF00FF88);
const Color _ambPink = Color(0xFFFF6B9D);
const Color _ambGold = Color(0xFFFFD700);
const Color _ambWarm = Color(0xFFFF8C42);
const Color _ambRed = Color(0xFFFF3366);
const Color _ambPurple = Color(0xFFBB86FC);
const Color _ambBlue = Color(0xFF4FC3F7);
const Color _ambBg = Color(0xFF050A14);
const Color _ambCard = Color(0xFF0D1B2A);

class AmbassadorScreen extends StatefulWidget {
  const AmbassadorScreen({super.key});

  @override
  State<AmbassadorScreen> createState() => _AmbassadorScreenState();
}

class _AmbassadorScreenState extends State<AmbassadorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _glowAnim;
  int _selectedTierIndex = 0;

  // ── Ambassador Tiers ──
  final List<_AmbassadorTier> _tiers = [
    const _AmbassadorTier(
      name: 'BRONZE',
      title: 'Community Starter',
      icon: Icons.emoji_events,
      color: Color(0xFFCD7F32),
      requirements: [
        'Complete DFC Ambassador application',
        'Pass community guidelines quiz',
        'Distribute 10 Hope Cards in your area',
        'Attend 1 DFC online orientation session',
      ],
      perks: [
        'Official DFC Ambassador badge on profile',
        'Bronze-tier digital certificate',
        'Access to Ambassador Slack channel',
        'Monthly newsletter with community updates',
      ],
      hopeCardsTarget: 10,
      eventsTarget: 0,
      mentorTarget: 0,
    ),
    const _AmbassadorTier(
      name: 'SILVER',
      title: 'Community Builder',
      icon: Icons.workspace_premium,
      color: Color(0xFFC0C0C0),
      requirements: [
        'Bronze tier completed & active 30+ days',
        'Distribute 50 Hope Cards total',
        'Refer 3 new ambassadors',
        'Organise 1 community event or outreach',
      ],
      perks: [
        'Silver badge + verified ambassador profile',
        'Free DFC Ambassador merchandise pack',
        'Priority support channel access',
        'Feature in DFC Community Spotlight',
        'Early access to new DFC features',
      ],
      hopeCardsTarget: 50,
      eventsTarget: 1,
      mentorTarget: 0,
    ),
    const _AmbassadorTier(
      name: 'GOLD',
      title: 'Community Champion',
      icon: Icons.star,
      color: _ambGold,
      requirements: [
        'Silver tier completed & active 90+ days',
        'Distribute 200 Hope Cards total',
        'Organise 5 community events',
        'Mentor 2 Bronze ambassadors',
        'Verified by DFC Regional Coordinator',
      ],
      perks: [
        'Gold badge + Ambassador Hall of Fame',
        'Exclusive DFC Gold Ambassador jacket',
        'Free entry to all DFC partner events',
        'Monthly 1:1 with DFC leadership',
        'Ambassador stipend programme eligibility',
        'Co-brand community events with DFC',
      ],
      hopeCardsTarget: 200,
      eventsTarget: 5,
      mentorTarget: 2,
    ),
    const _AmbassadorTier(
      name: 'PLATINUM',
      title: 'Regional Leader',
      icon: Icons.diamond,
      color: _ambCyan,
      requirements: [
        'Gold tier completed & active 6+ months',
        'Distribute 500 Hope Cards total',
        'Organise 15 community events',
        'Recruit & mentor 10 ambassadors',
        'Lead a DFC Regional Chapter',
        'Complete DFC Leadership Training',
      ],
      perks: [
        'Platinum badge + Regional Lead title',
        'Quarterly DFC strategy call with founders',
        'Travel support for regional events',
        'Ambassador stipend (up to \$500/quarter)',
        'Seat on DFC Community Advisory Board',
        'VIP access to all DFC partner gyms',
        'Personalised DFC Ambassador kit',
      ],
      hopeCardsTarget: 500,
      eventsTarget: 15,
      mentorTarget: 10,
    ),
    const _AmbassadorTier(
      name: 'CHAMPION',
      title: 'DFC Legend',
      icon: Icons.military_tech,
      color: _ambPurple,
      requirements: [
        'Platinum tier completed & active 12+ months',
        'Distribute 1000+ Hope Cards total',
        'Organise 30+ community events',
        'Build a regional network of 25+ ambassadors',
        'Demonstrated measurable community impact',
        'Nominated by DFC Board',
      ],
      perks: [
        'Champion badge — rarest in DFC',
        'Lifetime VIP DFC membership',
        'Annual Ambassador Summit invitation (expenses paid)',
        'Full DFC brand partnership opportunities',
        'Public recognition in DFC marketing',
        'Priority for DFC employment opportunities',
        'Personal DFC documentary feature',
        'Community impact grant eligibility (\$2000/year)',
      ],
      hopeCardsTarget: 1000,
      eventsTarget: 30,
      mentorTarget: 25,
    ),
  ];

  // ── Ambassador Activities ──
  final List<_AmbassadorActivity> _activities = [
    const _AmbassadorActivity(
      'Hope Card Distribution',
      'Hand out Hope Cards to people in need at shelters, parks, libraries & community centres',
      Icons.card_giftcard,
      _ambWarm,
      '+5 pts/card',
    ),
    const _AmbassadorActivity(
      'Community Event',
      'Organise or co-host a DFC community event — fitness class, awareness talk, charity drive',
      Icons.event,
      _ambCyan,
      '+50 pts/event',
    ),
    const _AmbassadorActivity(
      'Gym Outreach',
      'Visit local gyms to share DFC fighter safety resources & build partnerships',
      Icons.fitness_center,
      _ambGold,
      '+25 pts/visit',
    ),
    const _AmbassadorActivity(
      'Social Media Post',
      'Share DFC content, Hope Card stories, or community wins on your social media',
      Icons.share,
      _ambPink,
      '+10 pts/post',
    ),
    const _AmbassadorActivity(
      'Mentor Session',
      'Mentor a new ambassador through their first month — guide, support, encourage',
      Icons.people,
      _ambGreen,
      '+30 pts/session',
    ),
    const _AmbassadorActivity(
      'Resource Hub Update',
      'Submit verified local resource information to add to the Community Resource Hub',
      Icons.hub,
      _ambBlue,
      '+15 pts/resource',
    ),
    const _AmbassadorActivity(
      'Fundraiser',
      'Organise or participate in a fundraiser for DFC community programmes',
      Icons.volunteer_activism,
      _ambPurple,
      '+40 pts/event',
    ),
    const _AmbassadorActivity(
      'Safety Report',
      'Report an unsafe fight event or training environment through DFC safety channels',
      Icons.security,
      _ambRed,
      '+20 pts/report',
    ),
  ];

  // ── Impact Stats (Demo) ──
  final List<_ImpactStat> _impactStats = [
    const _ImpactStat(
      'Hope Cards Distributed',
      '12,847',
      Icons.card_giftcard,
      _ambWarm,
    ),
    const _ImpactStat('Active Ambassadors', '347', Icons.people, _ambCyan),
    const _ImpactStat('Community Events', '89', Icons.event, _ambGold),
    const _ImpactStat('Lives Touched', '45,000+', Icons.favorite, _ambPink),
    const _ImpactStat('Partner Gyms', '62', Icons.fitness_center, _ambGreen),
    const _ImpactStat('Regions Active', '14', Icons.location_on, _ambPurple),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ambBg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildHero()),
          SliverToBoxAdapter(child: _buildImpactStats()),
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'AMBASSADOR TIERS',
              Icons.emoji_events,
              _ambGold,
            ),
          ),
          SliverToBoxAdapter(child: _buildTierSelector()),
          SliverToBoxAdapter(child: _buildTierDetail()),
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'EARN POINTS',
              Icons.auto_graph,
              _ambCyan,
            ),
          ),
          SliverToBoxAdapter(child: _buildActivitiesGrid()),
          SliverToBoxAdapter(
            child: _buildSectionHeader('HOW IT WORKS', Icons.route, _ambGreen),
          ),
          SliverToBoxAdapter(child: _buildHowItWorks()),
          SliverToBoxAdapter(child: _buildApplyBanner()),
          SliverToBoxAdapter(child: _buildFooter()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: _ambBg.withValues(alpha: 0.95),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_ambGold, _ambWarm]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.military_tech,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              'DFC AMBASSADOR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // HERO
  // ═══════════════════════════════════════════
  Widget _buildHero() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _ambGold.withValues(alpha: 0.12),
            _ambWarm.withValues(alpha: 0.06),
            _ambPurple.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ambGold.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (context, child) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [_ambGold, _ambWarm]),
                boxShadow: [
                  BoxShadow(
                    color: _ambGold.withValues(alpha: 0.3 * _glowAnim.value),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.military_tech,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 18),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_ambGold, _ambWarm, Colors.white],
            ).createShader(bounds),
            child: const Text(
              'DFC AMBASSADOR\nPROGRAM',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 3,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Empowering everyday heroes to fight for their community.\nDistribute Hope Cards · Organise Events · Save Lives.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _showApplicationForm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_ambGold, _ambWarm]),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _ambGold.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.rocket_launch, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Text(
                    'BECOME AN AMBASSADOR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
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

  // ═══════════════════════════════════════════
  // IMPACT STATS
  // ═══════════════════════════════════════════
  Widget _buildImpactStats() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _impactStats.length,
        itemBuilder: (context, index) {
          final stat = _impactStats[index];
          return Container(
            width: 130,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _ambCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: stat.color.withValues(alpha: 0.15)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(stat.icon, color: stat.color, size: 18),
                const SizedBox(height: 6),
                Text(
                  stat.value,
                  style: TextStyle(
                    color: stat.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat.label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SECTION HEADER
  // ═══════════════════════════════════════════
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TIER SELECTOR
  // ═══════════════════════════════════════════
  Widget _buildTierSelector() {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tiers.length,
        itemBuilder: (context, index) {
          final tier = _tiers[index];
          final isSelected = _selectedTierIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTierIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 80,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? tier.color.withValues(alpha: 0.15)
                    : _ambCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? tier.color
                      : Colors.white.withValues(alpha: 0.06),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: tier.color.withValues(alpha: 0.15),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    tier.icon,
                    color: isSelected ? tier.color : Colors.white38,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tier.name,
                    style: TextStyle(
                      color: isSelected ? tier.color : Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TIER DETAIL
  // ═══════════════════════════════════════════
  Widget _buildTierDetail() {
    final tier = _tiers[_selectedTierIndex];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ambCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tier.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tier.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(tier.icon, color: tier.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tier.name} TIER',
                      style: TextStyle(
                        color: tier.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      tier.title,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Targets
          Row(
            children: [
              _targetBadge(
                Icons.card_giftcard,
                '${tier.hopeCardsTarget}',
                'Cards',
                _ambWarm,
              ),
              const SizedBox(width: 8),
              _targetBadge(
                Icons.event,
                '${tier.eventsTarget}',
                'Events',
                _ambCyan,
              ),
              const SizedBox(width: 8),
              _targetBadge(
                Icons.people,
                '${tier.mentorTarget}',
                'Mentees',
                _ambGreen,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Requirements
          Text(
            'REQUIREMENTS',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...tier.requirements.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: tier.color.withValues(alpha: 0.5),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Perks
          Text(
            'PERKS & REWARDS',
            style: TextStyle(
              color: _ambGold.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...tier.perks.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.star,
                    color: _ambGold.withValues(alpha: 0.5),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        height: 1.4,
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

  Widget _targetBadge(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ACTIVITIES GRID
  // ═══════════════════════════════════════════
  Widget _buildActivitiesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.15,
        ),
        itemCount: _activities.length,
        itemBuilder: (context, index) {
          final activity = _activities[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _ambCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: activity.color.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: activity.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        activity.icon,
                        color: activity.color,
                        size: 18,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _ambGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        activity.points,
                        style: const TextStyle(
                          color: _ambGreen,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  activity.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  activity.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 9,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════
  // HOW IT WORKS
  // ═══════════════════════════════════════════
  Widget _buildHowItWorks() {
    final steps = [
      const _HowItWorksStep(
        '1',
        'Apply',
        'Submit your ambassador application — tell us why you want to fight for your community',
        Icons.edit_document,
        _ambCyan,
      ),
      const _HowItWorksStep(
        '2',
        'Onboard',
        'Complete the orientation quiz, learn DFC values & community guidelines',
        Icons.school,
        _ambGreen,
      ),
      const _HowItWorksStep(
        '3',
        'Act',
        'Start distributing Hope Cards, organising events & building your community network',
        Icons.rocket_launch,
        _ambGold,
      ),
      const _HowItWorksStep(
        '4',
        'Grow',
        'Earn points, level up tiers, unlock perks & expand your impact year after year',
        Icons.trending_up,
        _ambPurple,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: steps
            .map(
              (step) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _ambCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: step.color.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            step.color,
                            step.color.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                      child: Text(
                        step.number,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title.toUpperCase(),
                            style: TextStyle(
                              color: step.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      step.icon,
                      color: step.color.withValues(alpha: 0.3),
                      size: 22,
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // APPLY BANNER
  // ═══════════════════════════════════════════
  Widget _buildApplyBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _ambGold.withValues(alpha: 0.12),
            _ambPink.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ambGold.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.handshake, color: _ambGold, size: 30),
          const SizedBox(height: 12),
          const Text(
            'READY TO MAKE\nA DIFFERENCE?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Join 347 ambassadors across 14 regions\nwho are changing lives every day.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showApplicationForm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_ambGold, _ambWarm]),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.send, color: Colors.white, size: 16),
                  SizedBox(width: 10),
                  Text(
                    'APPLY NOW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
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

  // ═══════════════════════════════════════════
  // FOOTER
  // ═══════════════════════════════════════════
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _ambCard.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _ambCyan.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            const Icon(Icons.military_tech, color: _ambGold, size: 22),
            const SizedBox(height: 8),
            Text(
              'Every ambassador starts with a single act of kindness.\nYour community is waiting.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'DFC Ambassador Program · datafightcentral.com/ambassador',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // APPLICATION FORM DIALOG
  // ═══════════════════════════════════════════
  void _showApplicationForm() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF091420),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Icon(Icons.military_tech, color: _ambGold, size: 32),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'AMBASSADOR APPLICATION',
                  style: TextStyle(
                    color: _ambGold,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Tell us about yourself and your community',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _formField('Full Name', Icons.person, 'Your full legal name'),
              _formField('Email', Icons.email, 'DFC will contact you here'),
              _formField('Phone', Icons.phone, 'Australian number preferred'),
              _formField(
                'Location',
                Icons.location_on,
                'City, State, Postcode',
              ),
              _formField(
                'Gym / Club',
                Icons.fitness_center,
                'Your training gym or club (optional)',
              ),
              _formField(
                'Why DFC?',
                Icons.favorite,
                'Why do you want to be an ambassador? (2-3 sentences)',
                maxLines: 3,
              ),
              _formField(
                'Experience',
                Icons.work,
                'Any community, charity, or sports volunteering? (optional)',
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _showSnack('Application submitted! Check your email.');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_ambGold, _ambWarm]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'SUBMIT APPLICATION',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Applications reviewed within 48 hours\nDFC Community Team · support@datafightcentral.com',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formField(
    String label,
    IconData icon,
    String hint, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _ambGold.withValues(alpha: 0.5), size: 14),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _ambGold.withValues(alpha: 0.12)),
            ),
            child: TextField(
              maxLines: maxLines,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 12,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _ambCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: _ambGreen, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════

class _AmbassadorTier {
  final String name;
  final String title;
  final IconData icon;
  final Color color;
  final List<String> requirements;
  final List<String> perks;
  final int hopeCardsTarget;
  final int eventsTarget;
  final int mentorTarget;
  const _AmbassadorTier({
    required this.name,
    required this.title,
    required this.icon,
    required this.color,
    required this.requirements,
    required this.perks,
    required this.hopeCardsTarget,
    required this.eventsTarget,
    required this.mentorTarget,
  });
}

class _AmbassadorActivity {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String points;
  const _AmbassadorActivity(
    this.name,
    this.description,
    this.icon,
    this.color,
    this.points,
  );
}

class _ImpactStat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _ImpactStat(this.label, this.value, this.icon, this.color);
}

class _HowItWorksStep {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  const _HowItWorksStep(
    this.number,
    this.title,
    this.description,
    this.icon,
    this.color,
  );
}
