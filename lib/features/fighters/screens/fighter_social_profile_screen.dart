import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/correspondence_service.dart';

/// Fighter Social Profile — The public face of a fighter on DFC.
/// Bio, record, region, gym, feed, Q&A, events.
/// Fans can follow, send questions, send support — never DM.
class FighterSocialProfileScreen extends StatefulWidget {
  final String fighterId;
  final String? fighterName;

  const FighterSocialProfileScreen({
    super.key,
    required this.fighterId,
    this.fighterName,
  });

  @override
  State<FighterSocialProfileScreen> createState() =>
      _FighterSocialProfileScreenState();
}

class _FighterSocialProfileScreenState extends State<FighterSocialProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CorrespondenceService _correspondence = CorrespondenceService();
  bool _isFollowing = false;

  _FighterProfile get _profile =>
      _demoProfiles[widget.fighterId] ??
      _FighterProfile(
        name: widget.fighterName ?? 'Fighter',
        record: '0-0-0',
        region: 'Unknown',
        gym: 'Independent',
        style: 'MMA',
        bio: 'Fighter on DFC.',
        tags: [],
        followers: 0,
        fights: 0,
      );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: DesignTokens.bgSecondary,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(profile),
            ),
            title: innerBoxIsScrolled
                ? Text(
                    profile.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  )
                : null,
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: DesignTokens.neonCyan,
                labelColor: DesignTokens.neonCyan,
                unselectedLabelColor: Colors.white38,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
                tabs: const [
                  Tab(text: 'ABOUT'),
                  Tab(text: 'FEED'),
                  Tab(text: 'Q&A'),
                  Tab(text: 'EVENTS'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAboutTab(profile),
            _buildFeedTab(profile),
            _buildQATab(profile),
            _buildEventsTab(profile),
          ],
        ),
      ),
    );
  }

  // ─── PROFILE HEADER ───────────────────────────────────────

  Widget _buildProfileHeader(_FighterProfile profile) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A1628), Color(0xFF050A14)],
        ),
      ),
      child: Stack(
        children: [
          // Hexagon pattern
          Positioned.fill(child: CustomPaint(painter: _HexPatternPainter())),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    DesignTokens.bgPrimary,
                    DesignTokens.bgPrimary.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Fighter avatar
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: DesignTokens.neonCyan.withValues(alpha: 0.12),
                          border: Border.all(
                            color: DesignTokens.neonCyan,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            profile.name[0],
                            style: const TextStyle(
                              color: DesignTokens.neonCyan,
                              fontWeight: FontWeight.w900,
                              fontSize: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: DesignTokens.neonAmber.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    profile.record,
                                    style: const TextStyle(
                                      color: DesignTokens.neonAmber,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  profile.style,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.white.withValues(alpha: 0.4),
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  profile.region,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.fitness_center,
                                  color: Colors.white.withValues(alpha: 0.4),
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  profile.gym,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _isFollowing = !_isFollowing),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isFollowing
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : DesignTokens.neonCyan,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                _isFollowing ? 'FOLLOWING' : 'FOLLOW',
                                style: TextStyle(
                                  color: _isFollowing
                                      ? DesignTokens.neonCyan
                                      : Colors.black,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: DesignTokens.neonAmber.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: DesignTokens.neonAmber.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'ASK QUESTION',
                              style: TextStyle(
                                color: DesignTokens.neonAmber,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: DesignTokens.neonGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: DesignTokens.neonGreen.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: const Icon(
                          Icons.favorite_outline,
                          color: DesignTokens.neonGreen,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _stat('${profile.followers}', 'Followers'),
                      _stat('${profile.fights}', 'Fights'),
                      _stat('${profile.tags.length}', 'Tags'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ─── ABOUT TAB ─────────────────────────────────────────────

  Widget _buildAboutTab(_FighterProfile profile) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Bio
        _sectionCard('BIO', [
          Text(
            profile.bio,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ]),
        const SizedBox(height: 14),
        // Tags
        _sectionCard('IDENTITY', [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.tags
                .map(
                  (t) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(
                        color: DesignTokens.neonCyan,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ]),
        const SizedBox(height: 14),
        // Details
        _sectionCard('DETAILS', [
          _detailRow('Region', profile.region),
          _detailRow('Gym', profile.gym),
          _detailRow('Style', profile.style),
          _detailRow('Record', profile.record),
        ]),
      ],
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: DesignTokens.neonCyan,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ─── FEED TAB ──────────────────────────────────────────────

  Widget _buildFeedTab(_FighterProfile profile) {
    final posts = _demoFighterPosts(profile.name);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final p = posts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
                      color: p.$3.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.$2,
                      style: TextStyle(
                        color: p.$3,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    p.$4,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                p.$1,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.favorite_outline,
                    color: Colors.white38,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${p.$5}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white38,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${p.$6}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Q&A TAB ───────────────────────────────────────────────

  Widget _buildQATab(_FighterProfile profile) {
    return StreamBuilder<List<FighterResponse>>(
      stream: _correspondence.getPublicResponses(fighterId: widget.fighterId),
      builder: (context, snapshot) {
        final responses = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Prompt to ask
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DesignTokens.neonAmber.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: DesignTokens.neonAmber.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.question_answer,
                    color: DesignTokens.neonAmber,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ask this fighter a question',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Questions are filtered before the fighter sees them.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonAmber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ASK',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (responses.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.forum_outlined,
                      color: Colors.white.withValues(alpha: 0.15),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No Q&A answers yet',
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                    const Text(
                      'Be the first to ask!',
                      style: TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ...responses.map(_buildQACard),
          ],
        );
      },
    );
  }

  Widget _buildQACard(FighterResponse response) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: DesignTokens.neonCyan, width: 2),
                ),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: DesignTokens.neonCyan.withValues(alpha: 0.2),
                  child: Text(
                    response.fighterName[0],
                    style: const TextStyle(
                      color: DesignTokens.neonCyan,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                response.fighterName,
                style: const TextStyle(
                  color: DesignTokens.neonCyan,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'FIGHTER',
                  style: TextStyle(
                    color: DesignTokens.neonCyan,
                    fontWeight: FontWeight.w800,
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            response.content,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.favorite_outline,
                color: Colors.white30,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${response.likes}',
                style: const TextStyle(color: Colors.white30, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── EVENTS TAB ────────────────────────────────────────────

  Widget _buildEventsTab(_FighterProfile profile) {
    final events = _demoFighterEvents(profile.name);
    if (events.isEmpty) {
      return const Center(
        child: Text(
          'No upcoming events',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final e = events[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DesignTokens.neonAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      e.$1,
                      style: const TextStyle(
                        color: DesignTokens.neonAmber,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      e.$2,
                      style: const TextStyle(
                        color: DesignTokens.neonAmber,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.$3,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      e.$4,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      e.$5,
                      style: const TextStyle(
                        color: DesignTokens.neonCyan,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── DEMO DATA ─────────────────────────────────────────────

  static final _demoProfiles = {
    'haze_hepi': const _FighterProfile(
      name: 'Haze Hepi',
      record: '8-2-0',
      region: 'Logan, QLD',
      gym: 'Island Warriors MMA',
      style: 'Bare Knuckle · MMA',
      bio:
          'Pacific Islander warrior from Logan, New Zealand roots. Representing the islands with bare fists. April 18, Townsville — Hepi vs Wisniewski II. No gloves, no excuses.',
      tags: ['Islander', 'Logan', 'BKFC', 'Bare Knuckle', 'NZ', 'Pacific'],
      followers: 4200,
      fights: 10,
    ),
    'mark_flanagan': const _FighterProfile(
      name: 'Mark Flanagan',
      record: '24-7-0 (17 KOs)',
      region: 'Sydney, NSW',
      gym: 'Independent',
      style: 'Boxing · Bare Knuckle',
      bio:
          'Former WBA Oceania heavyweight champion. 24 wins, 17 by knockout. Now making the bare-knuckle debut. Townsville, April 18.',
      tags: ['Boxing', 'Heavyweight', 'BKFC', 'Sydney'],
      followers: 3100,
      fights: 31,
    ),
    'sam_soliman': const _FighterProfile(
      name: 'Sam Soliman',
      record: '44-13-0',
      region: 'Melbourne, VIC',
      gym: 'Independent',
      style: 'Boxing',
      bio:
          'Former IBF middleweight world champion. 44 wins across a legendary career. Coming out of retirement for BKFC Townsville.',
      tags: ['Boxing', 'World Champion', 'BKFC', 'Melbourne'],
      followers: 8900,
      fights: 57,
    ),
    'wisniewski': const _FighterProfile(
      name: 'Krzysztof Wisniewski',
      record: '4-0-0',
      region: 'Poland',
      gym: 'Polish Fight Team',
      style: 'Bare Knuckle',
      bio:
          'Undefeated Polish bare-knuckle heavyweight. 4-0 with no losses. Coming to Townsville to defend his streak against Haze Hepi.',
      tags: ['BKFC', 'Bare Knuckle', 'Poland', 'Heavyweight'],
      followers: 1800,
      fights: 4,
    ),
    'bk_bau': const _FighterProfile(
      name: 'BK Bau',
      record: '6-3-0',
      region: 'Logan, QLD',
      gym: 'Island Warriors MMA',
      style: 'Bare Knuckle',
      bio:
          'Logan-bred bare-knuckle scrapper. Island blood, Logan heart. On the Townsville card April 18.',
      tags: ['Islander', 'Logan', 'BKFC', 'Bare Knuckle'],
      followers: 1200,
      fights: 9,
    ),
  };

  List<(String, String, Color, String, int, int)> _demoFighterPosts(
    String name,
  ) {
    if (name == 'Haze Hepi') {
      return [
        (
          'Camp is locked in. 6 weeks out from April 18. Wisniewski is tough but Logan made me tougher. 🇳🇿',
          'TRAINING',
          DesignTokens.neonGreen,
          '2h',
          342,
          28,
        ),
        (
          'Thank you Logan. Thank you the Islands. This fight is for the community.',
          'UPDATE',
          DesignTokens.neonCyan,
          '1d',
          567,
          45,
        ),
        (
          'Bare knuckle is the purest form of combat. No hiding behind gloves. Just you and your hands.',
          'MINDSET',
          DesignTokens.neonAmber,
          '3d',
          234,
          18,
        ),
      ];
    }
    return [
      (
        'Training hard. Fight coming soon.',
        'UPDATE',
        DesignTokens.neonCyan,
        '1d',
        45,
        3,
      ),
    ];
  }

  List<(String, String, String, String, String)> _demoFighterEvents(
    String name,
  ) {
    if (name == 'Haze Hepi' ||
        name == 'Mark Flanagan' ||
        name == 'Sam Soliman' ||
        name == 'Krzysztof Wisniewski' ||
        name == 'BK Bau') {
      return [
        (
          '18',
          'APR',
          'BKFC Fight Night Australia',
          'Townsville Entertainment Centre',
          'BKFC',
        ),
      ];
    }
    return [];
  }
}

// ─── DATA CLASS ──────────────────────────────────────────────

class _FighterProfile {
  final String name, record, region, gym, style, bio;
  final List<String> tags;
  final int followers, fights;
  const _FighterProfile({
    required this.name,
    required this.record,
    required this.region,
    required this.gym,
    required this.style,
    required this.bio,
    required this.tags,
    required this.followers,
    required this.fights,
  });
}

// ─── STICKY TAB BAR DELEGATE ─────────────────────────────────

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTabBarDelegate(this.tabBar);

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
    return Container(color: DesignTokens.bgPrimary, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) => false;
}

// ─── HEX PATTERN ─────────────────────────────────────────────

class _HexPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DesignTokens.neonCyan.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    const s = 30.0;
    for (double y = 0; y < size.height + s; y += s * 1.5) {
      for (double x = 0; x < size.width + s; x += s * 1.73) {
        final offsetX = (y ~/ (s * 1.5)).isOdd ? s * 0.87 : 0.0;
        _drawHex(canvas, Offset(x + offsetX, y), s * 0.5, paint);
      }
    }
  }

  void _drawHex(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (60.0 * i - 30) * 3.14159 / 180;
      final p = Offset(
        center.dx + r * _cos(angle),
        center.dy + r * _sin(angle),
      );
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double _cos(double r) => r >= 0 ? _cosImpl(r) : _cosImpl(-r);
  double _sin(double r) => r >= 0 ? _sinImpl(r) : -_sinImpl(-r);
  // Simple approximation using dart:math would be cleaner but avoids import
  double _cosImpl(double x) {
    // Taylor series approximation good enough for painting
    x = x % (2 * 3.14159);
    return 1 - x * x / 2 + x * x * x * x / 24;
  }

  double _sinImpl(double x) {
    x = x % (2 * 3.14159);
    return x - x * x * x / 6 + x * x * x * x * x / 120;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
