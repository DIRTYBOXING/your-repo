import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

/// Region Feed — The heart of fight city identity.
/// Each region (Logan, Brisbane, Bronx Islanders, etc.) gets its own
/// page with feed, events, gyms, and fighters.
class RegionFeedScreen extends StatefulWidget {
  final String regionId;
  final String regionName;

  const RegionFeedScreen({
    super.key,
    required this.regionId,
    required this.regionName,
  });

  @override
  State<RegionFeedScreen> createState() => _RegionFeedScreenState();
}

class _RegionFeedScreenState extends State<RegionFeedScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late TabController _tabController;
  bool _isFollowing = false;

  // Demo region data
  static const _regions = {
    'logan': _RegionData(
      name: 'Logan',
      subtitle: 'The Fight Capital of Queensland',
      bannerGradient: [Color(0xFF0A1628), Color(0xFF1A0A2E)],
      followers: 12400,
      fighters: 84,
      gyms: 12,
      events: 6,
      description:
          'Home of the Pacific Islander fight community. Logan breeds warriors — Hepi, Mita, Hardman, and the next generation train here.',
      tags: ['Islanders', 'BKFC', 'MMA', 'Boxing', 'Bare Knuckle'],
    ),
    'brisbane': _RegionData(
      name: 'Brisbane',
      subtitle: 'Queensland Combat Hub',
      bannerGradient: [Color(0xFF0A1628), Color(0xFF0A2818)],
      followers: 8200,
      fighters: 56,
      gyms: 18,
      events: 9,
      description:
          'The capital of Queensland combat sports. From UFC contenders to grassroots MMA, Brisbane powers the fight scene.',
      tags: ['UFC', 'MMA', 'Kickboxing', 'BJJ'],
    ),
    'bronx_islanders': _RegionData(
      name: 'Bronx Islanders',
      subtitle: 'Pacific Power in New York',
      bannerGradient: [Color(0xFF0A1628), Color(0xFF280A0A)],
      followers: 6800,
      fighters: 42,
      gyms: 8,
      events: 4,
      description:
          'The Polynesian fight diaspora in the Bronx. Samoan, Tongan, Maori warriors bringing island strength to NYC.',
      tags: ['Boxing', 'MMA', 'Polynesian', 'Street'],
    ),
    'townsville': _RegionData(
      name: 'Townsville',
      subtitle: 'North Queensland Fight Night',
      bannerGradient: [Color(0xFF0A1628), Color(0xFF1A1A0A)],
      followers: 3400,
      fighters: 28,
      gyms: 6,
      events: 3,
      description:
          'BKFC Australia home base. Hepi vs Wisniewski II, Mark Flanagan debut — Townsville Entertainment Centre is the new fight capital.',
      tags: ['BKFC', 'Bare Knuckle', 'Boxing'],
    ),
  };

  _RegionData get _data =>
      _regions[widget.regionId] ??
      _RegionData(
        name: widget.regionName,
        subtitle: 'Fight Region',
        bannerGradient: const [Color(0xFF0A1628), Color(0xFF1A0A28)],
        followers: 0,
        fighters: 0,
        gyms: 0,
        events: 0,
        description: 'A DFC fight region.',
        tags: const [],
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
    final data = _data;
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: DesignTokens.bgSecondary,
            flexibleSpace: FlexibleSpaceBar(background: _buildBanner(data)),
            title: innerBoxIsScrolled
                ? Text(
                    data.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  )
                : null,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.share_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: DesignTokens.neonCyan,
                labelColor: DesignTokens.neonCyan,
                unselectedLabelColor: Colors.white38,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
                tabs: const [
                  Tab(text: 'FEED'),
                  Tab(text: 'EVENTS'),
                  Tab(text: 'GYMS'),
                  Tab(text: 'FIGHTERS'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFeedTab(data),
            _buildEventsTab(data),
            _buildGymsTab(data),
            _buildFightersTab(data),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(_RegionData data) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: data.bannerGradient,
        ),
      ),
      child: Stack(
        children: [
          // Grid pattern overlay
          Positioned.fill(child: CustomPaint(painter: _GridPatternPainter())),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.location_city,
                          color: DesignTokens.neonCyan,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                              ),
                            ),
                            Text(
                              data.subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildFollowButton(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statChip(_formatCount(data.followers), 'Followers'),
                      const SizedBox(width: 16),
                      _statChip('${data.fighters}', 'Fighters'),
                      const SizedBox(width: 16),
                      _statChip('${data.gyms}', 'Gyms'),
                      const SizedBox(width: 16),
                      _statChip('${data.events}', 'Events'),
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

  Widget _buildFollowButton() {
    return GestureDetector(
      onTap: () => setState(() => _isFollowing = !_isFollowing),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: _isFollowing
              ? Colors.white.withValues(alpha: 0.1)
              : DesignTokens.neonCyan,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _isFollowing ? 'FOLLOWING' : 'FOLLOW',
          style: TextStyle(
            color: _isFollowing ? DesignTokens.neonCyan : Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _statChip(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ─── FEED TAB ──────────────────────────────────────────────

  Widget _buildFeedTab(_RegionData data) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('posts')
          .where('regionId', isEqualTo: widget.regionId)
          .orderBy('timestamp', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: DesignTokens.neonCyan),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    color: Colors.white.withValues(alpha: 0.2),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No posts yet in ${data.name}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to post in your region.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final d = docs[index].data() as Map<String, dynamic>;
            return _buildPostCard(d);
          },
        );
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final author =
        post['authorName'] as String? ??
        post['userId'] as String? ??
        'DFC Member';
    final content = post['content'] as String? ?? post['text'] as String? ?? '';
    final tag = post['tag'] as String? ?? post['type'] as String? ?? 'POST';
    final likes =
        (post['likes'] as num?)?.toInt() ??
        (post['likesCount'] as num?)?.toInt() ??
        0;
    final comments =
        (post['commentsCount'] as num?)?.toInt() ??
        (post['comments'] as num?)?.toInt() ??
        0;
    final ts = post['timestamp'] is Timestamp
        ? (post['timestamp'] as Timestamp).toDate()
        : DateTime.now();
    final timeAgo = _formatTimeAgo(ts);
    final avatarUrl =
        post['authorAvatarUrl'] as String? ?? post['photoUrl'] as String?;
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
              CircleAvatar(
                radius: 16,
                backgroundColor: DesignTokens.neonCyan.withValues(alpha: 0.15),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        author.isNotEmpty ? author[0].toUpperCase() : 'D',
                        style: const TextStyle(
                          color: DesignTokens.neonCyan,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag.toUpperCase(),
                  style: const TextStyle(
                    color: DesignTokens.neonCyan,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _engagementChip(Icons.favorite_outline, '$likes'),
              const SizedBox(width: 16),
              _engagementChip(Icons.chat_bubble_outline, '$comments'),
              const SizedBox(width: 16),
              _engagementChip(Icons.share_outlined, 'Share'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _engagementChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white38, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }

  // ─── EVENTS TAB ────────────────────────────────────────────

  Widget _buildEventsTab(_RegionData data) {
    return FutureBuilder<QuerySnapshot>(
      future: _db
          .collection('events')
          .where('regionId', isEqualTo: widget.regionId)
          .orderBy('startTime', descending: false)
          .limit(20)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: DesignTokens.neonCyan),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_outlined,
                    color: Colors.white.withValues(alpha: 0.2),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No upcoming events in ${data.name}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final d = docs[index].data() as Map<String, dynamic>;
            return _buildEventCard(d);
          },
        );
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    DateTime? eventDate;
    final raw = event['startTime'] ?? event['eventDate'] ?? event['date'];
    if (raw is Timestamp) eventDate = raw.toDate();
    final day = eventDate != null ? eventDate.day.toString() : '--';
    final month = eventDate != null
        ? [
            'JAN',
            'FEB',
            'MAR',
            'APR',
            'MAY',
            'JUN',
            'JUL',
            'AUG',
            'SEP',
            'OCT',
            'NOV',
            'DEC',
          ][eventDate.month - 1]
        : '---';
    final title =
        event['title'] as String? ?? event['name'] as String? ?? 'Event';
    final venue =
        event['venue'] as String? ?? event['location'] as String? ?? '';
    final promotion =
        event['promotionName'] as String? ??
        event['organizer'] as String? ??
        '';
    final fighters = (event['fighters'] as List<dynamic>? ?? [])
        .map((f) => f.toString())
        .toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.neonCyan.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        day,
                        style: const TextStyle(
                          color: DesignTokens.neonAmber,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        month,
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
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      if (venue.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          venue,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                      if (promotion.isNotEmpty)
                        Text(
                          promotion,
                          style: const TextStyle(
                            color: DesignTokens.neonCyan,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
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
                    color: DesignTokens.neonGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'VIEW',
                    style: TextStyle(
                      color: DesignTokens.neonGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (fighters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Wrap(
                spacing: 6,
                children: fighters
                    .map(
                      (f) => Chip(
                        label: Text(
                          f,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide.none,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ─── GYMS TAB ──────────────────────────────────────────────

  Widget _buildGymsTab(_RegionData data) {
    return FutureBuilder<QuerySnapshot>(
      future: _db
          .collection('gyms')
          .where('regionId', isEqualTo: widget.regionId)
          .limit(20)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: DesignTokens.neonCyan),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fitness_center_outlined,
                    color: Colors.white.withValues(alpha: 0.2),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No gyms listed in ${data.name} yet',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final gym = docs[index].data() as Map<String, dynamic>;
            final name = gym['name'] as String? ?? 'Gym';
            final styles = (gym['martialArts'] as List<dynamic>? ?? []).join(
              ' · ',
            );
            final members = (gym['memberCount'] as num?)?.toInt() ?? 0;
            final pinkShield = gym['pinkShield'] as bool? ?? false;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DesignTokens.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: DesignTokens.neonMagenta.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: DesignTokens.neonMagenta,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        if (styles.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            styles,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if (members > 0)
                          Text(
                            '$members members',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (pinkShield)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: DesignTokens.neonMagenta.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shield,
                        color: DesignTokens.neonMagenta,
                        size: 16,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── FIGHTERS TAB ──────────────────────────────────────────

  Widget _buildFightersTab(_RegionData data) {
    return FutureBuilder<QuerySnapshot>(
      future: _db
          .collection('fighters')
          .where('regionId', isEqualTo: widget.regionId)
          .limit(20)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: DesignTokens.neonCyan),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sports_mma_outlined,
                    color: Colors.white.withValues(alpha: 0.2),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No fighters registered in ${data.name} yet',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final f = docs[index].data() as Map<String, dynamic>;
            final name =
                f['displayName'] as String? ??
                f['name'] as String? ??
                'Fighter';
            final wins = (f['wins'] as num?)?.toInt() ?? 0;
            final losses = (f['losses'] as num?)?.toInt() ?? 0;
            final draws = (f['draws'] as num?)?.toInt() ?? 0;
            final record = '$wins-$losses-$draws';
            final styles = (f['fightingStyles'] as List<dynamic>? ?? []).join(
              ' · ',
            );
            final gym =
                f['gymName'] as String? ?? f['primaryGym'] as String? ?? '';
            final photoUrl =
                f['photoUrl'] as String? ?? f['avatarUrl'] as String?;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DesignTokens.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: DesignTokens.neonCyan.withValues(
                      alpha: 0.12,
                    ),
                    backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl == null || photoUrl.isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'F',
                            style: const TextStyle(
                              color: DesignTokens.neonCyan,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              record,
                              style: const TextStyle(
                                color: DesignTokens.neonAmber,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                            if (styles.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                styles,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (gym.isNotEmpty)
                          Text(
                            gym,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 10,
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
                      color: DesignTokens.neonCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'FOLLOW',
                      style: TextStyle(
                        color: DesignTokens.neonCyan,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── HELPERS ───────────────────────────────────────────────

  String _formatCount(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─── DATA CLASSES ────────────────────────────────────────────

class _RegionData {
  final String name, subtitle, description;
  final List<Color> bannerGradient;
  final int followers, fighters, gyms, events;
  final List<String> tags;

  const _RegionData({
    required this.name,
    required this.subtitle,
    required this.bannerGradient,
    required this.followers,
    required this.fighters,
    required this.gyms,
    required this.events,
    required this.description,
    required this.tags,
  });
}

// ─── TAB BAR DELEGATE ────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

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
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

// ─── GRID PATTERN PAINTER ────────────────────────────────────

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
