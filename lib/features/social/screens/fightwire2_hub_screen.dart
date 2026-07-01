import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

/// FIGHTWIRE 2.0 HUB — Unified Social Feed Entry Point
/// Hero event banner · Region selector · Fighter spotlights
/// Category filters · Posting system · Combat reactions
/// This is the main social surface described in the FightWire 2.0 blueprint.
class FightWire2HubScreen extends StatefulWidget {
  const FightWire2HubScreen({super.key});

  @override
  State<FightWire2HubScreen> createState() => _FightWire2HubScreenState();
}

class _FightWire2HubScreenState extends State<FightWire2HubScreen> {
  int _selectedCategory = 0;
  String _selectedRegion = 'ALL';

  static const _categories = [
    'ALL',
    'FIGHTS',
    'STORIES',
    'Q&A',
    'EVENTS',
    'GYMS',
    'PROMOS',
    'BEHIND THE SCENES',
  ];

  static const _regions = [
    'ALL',
    'Logan',
    'Brisbane',
    'Bronx Islanders',
    'Townsville',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            backgroundColor: DesignTokens.bgSecondary,
            pinned: true,
            expandedHeight: 0,
            title: const Row(
              children: [
                Icon(Icons.bolt, color: DesignTokens.neonCyan, size: 22),
                SizedBox(width: 8),
                Text(
                  'FIGHTWIRE',
                  style: TextStyle(
                    color: DesignTokens.neonCyan,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 2.0,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  '2.0',
                  style: TextStyle(
                    color: DesignTokens.neonMagenta,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white54),
                onPressed: () {},
                tooltip: 'Search',
              ),
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white54,
                ),
                onPressed: () {},
                tooltip: 'Notifications',
              ),
            ],
          ),

          // ── Hero Event Banner ──
          SliverToBoxAdapter(child: _buildHeroBanner()),

          // ── Region Selector ──
          SliverToBoxAdapter(child: _buildRegionSelector()),

          // ── Category Filters ──
          SliverToBoxAdapter(child: _buildCategoryFilters()),

          // ── Compose Button ──
          SliverToBoxAdapter(child: _buildComposeBar()),

          // ── Fighter Spotlights (horizontal) ──
          SliverToBoxAdapter(child: _buildFighterSpotlights()),

          // ── Feed Items ──
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildFeedItem(_feedItems[index]),
              childCount: _feedItems.length,
            ),
          ),

          // ── Load More ──
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Pull to load more',
                  style: TextStyle(color: Colors.white24, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Event Banner ──

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.neonRed.withValues(alpha: 0.15),
            DesignTokens.neonGold.withValues(alpha: 0.08),
            DesignTokens.bgCard,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DesignTokens.neonRed.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.neonRed.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LIVE EVENT',
                    style: TextStyle(
                      color: DesignTokens.neonRed,
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'APR 18, 2026',
                  style: TextStyle(
                    color: Colors.white38,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BKFC FIGHT NIGHT AUSTRALIA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hepi vs Wisniewski · Townsville Entertainment Centre',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Logan backs Hepi. Islanders rise together. The biggest BKFC event in Australian history.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // CTAs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Row(
              children: [
                _ctaBtn('WATCH', DesignTokens.neonRed, Icons.play_arrow),
                const SizedBox(width: 8),
                _ctaBtn('EVENT PAGE', DesignTokens.neonCyan, Icons.event),
                const SizedBox(width: 8),
                _ctaBtn('SHARE', DesignTokens.neonGold, Icons.share),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Region Selector ──

  Widget _buildRegionSelector() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _regions.length,
        itemBuilder: (context, index) {
          final r = _regions[index];
          final selected = r == _selectedRegion;
          final color = switch (r) {
            'Logan' => DesignTokens.neonGreen,
            'Brisbane' => DesignTokens.neonCyan,
            'Bronx Islanders' => DesignTokens.neonMagenta,
            'Townsville' => DesignTokens.neonAmber,
            _ => DesignTokens.neonCyan,
          };
          return GestureDetector(
            onTap: () => setState(() => _selectedRegion = r),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
                border: selected
                    ? Border.all(color: color.withValues(alpha: 0.3))
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (r != 'ALL')
                    Icon(
                      Icons.location_city,
                      color: selected ? color : Colors.white24,
                      size: 12,
                    ),
                  if (r != 'ALL') const SizedBox(width: 4),
                  Text(
                    r,
                    style: TextStyle(
                      color: selected ? color : Colors.white38,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
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

  // ── Category Filters ──

  Widget _buildCategoryFilters() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final selected = index == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? DesignTokens.neonCyan.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected
                      ? DesignTokens.neonCyan.withValues(alpha: 0.3)
                      : Colors.white10,
                ),
              ),
              child: Text(
                _categories[index],
                style: TextStyle(
                  color: selected ? DesignTokens.neonCyan : Colors.white30,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Compose Bar ──

  Widget _buildComposeBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: DesignTokens.neonCyan.withValues(alpha: 0.12),
            child: const Icon(
              Icons.person,
              color: DesignTokens.neonCyan,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "What's on your mind, warrior?",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 13,
              ),
            ),
          ),
          _miniBtn(Icons.image, DesignTokens.neonGreen),
          const SizedBox(width: 6),
          _miniBtn(Icons.videocam, DesignTokens.neonMagenta),
          const SizedBox(width: 6),
          _miniBtn(Icons.poll, DesignTokens.neonAmber),
        ],
      ),
    );
  }

  // ── Fighter Spotlights ──

  Widget _buildFighterSpotlights() {
    const spotlights = [
      ('Haze Hepi', '8-2-0', 'BKFC · Logan', true),
      ('BK Bau', '6-3-0', 'BKFC · Logan', false),
      ('Isaac Hardman', '12-2-0', 'IBC · Brisbane', false),
      ('Mark Flanagan', '4-1-0', 'BKFC · Townsville', false),
      ('Sione T.', '7-2-0', 'MMA · Bronx', false),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'FIGHTER SPOTLIGHTS',
            style: TextStyle(
              color: DesignTokens.neonCyan,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 2.0,
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: spotlights.length,
            itemBuilder: (context, index) {
              final (name, record, meta, featured) = spotlights[index];
              return Container(
                width: 130,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DesignTokens.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: featured
                        ? DesignTokens.neonGold.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: DesignTokens.neonCyan.withValues(
                            alpha: 0.12,
                          ),
                          child: Text(
                            name[0],
                            style: const TextStyle(
                              color: DesignTokens.neonCyan,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (featured) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star,
                            color: DesignTokens.neonGold,
                            size: 12,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      record,
                      style: const TextStyle(
                        color: DesignTokens.neonGreen,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      meta,
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Feed Items ──

  static final _feedItems = [
    const _FeedItem(
      author: 'Haze Hepi',
      authorType: 'fighter',
      region: 'Logan',
      content:
          'Getting ready for Townsville. Can\'t wait to represent Logan and the Islanders. April 18 is OUR night.',
      type: 'text',
      timeAgo: '2h',
      reactions: {
        'respect': 47,
        'strong': 23,
        'support': 89,
        'warrior': 12,
        'champion': 7,
      },
      comments: 14,
      shares: 8,
      isPinned: true,
      tags: ['BKFC', 'Logan', 'Islanders'],
    ),
    const _FeedItem(
      author: 'DFC Official',
      authorType: 'admin',
      region: 'Global',
      content:
          'BKFC FIGHT NIGHT AUSTRALIA — Full card announced. Hepi vs Wisniewski headlines. BK Bau on the undercard. Townsville Entertainment Centre, April 18.',
      type: 'promo',
      timeAgo: '5h',
      reactions: {
        'respect': 123,
        'strong': 56,
        'support': 201,
        'warrior': 34,
        'champion': 19,
      },
      comments: 42,
      shares: 67,
      isPinned: true,
      tags: ['BKFC', 'Event', 'Townsville'],
    ),
    const _FeedItem(
      author: 'Island Warriors MMA',
      authorType: 'gym',
      region: 'Logan',
      content:
          'Training camp day 21. The squad is sharp. Logan breeds warriors — always has, always will. Support your local fighters.',
      type: 'photo',
      timeAgo: '8h',
      reactions: {
        'respect': 34,
        'strong': 45,
        'support': 67,
        'warrior': 28,
        'champion': 3,
      },
      comments: 9,
      shares: 5,
      isPinned: false,
      tags: ['Training', 'Logan', 'Gym'],
    ),
    const _FeedItem(
      author: 'DFC Stories',
      authorType: 'admin',
      region: 'Global',
      content:
          'LONG READ: "Logan Backs Hepi — How a Queensland Suburb Became the Heart of Australian Bare Knuckle." The full story of Islanders, identity, and the fight for respect.',
      type: 'article',
      timeAgo: '1d',
      reactions: {
        'respect': 234,
        'strong': 89,
        'support': 456,
        'warrior': 67,
        'champion': 45,
      },
      comments: 78,
      shares: 112,
      isPinned: false,
      tags: ['Story', 'Logan', 'Islanders', 'BKFC'],
    ),
    const _FeedItem(
      author: 'BK Bau',
      authorType: 'fighter',
      region: 'Logan',
      content:
          'Logan warriors never back down. April 18 — see you in Townsville. War ready.',
      type: 'text',
      timeAgo: '1d',
      reactions: {
        'respect': 28,
        'strong': 19,
        'support': 41,
        'warrior': 15,
        'champion': 2,
      },
      comments: 6,
      shares: 3,
      isPinned: false,
      tags: ['BKFC', 'Logan'],
    ),
    const _FeedItem(
      author: 'Mark Flanagan',
      authorType: 'fighter',
      region: 'Townsville',
      content:
          'Training camp day 14. Feeling sharp. BKFC debut is coming and I\'m not leaving anything to chance.',
      type: 'text',
      timeAgo: '2d',
      reactions: {
        'respect': 19,
        'strong': 12,
        'support': 34,
        'warrior': 8,
        'champion': 1,
      },
      comments: 4,
      shares: 2,
      isPinned: false,
      tags: ['BKFC', 'Training', 'Townsville'],
    ),
    const _FeedItem(
      author: 'Bronx Islanders',
      authorType: 'community',
      region: 'Bronx Islanders',
      content:
          'NYC stand up! Watching the BKFC card together at the community centre. All Islanders welcome. Bring the energy.',
      type: 'event',
      timeAgo: '2d',
      reactions: {
        'respect': 56,
        'strong': 23,
        'support': 78,
        'warrior': 19,
        'champion': 5,
      },
      comments: 11,
      shares: 9,
      isPinned: false,
      tags: ['Bronx', 'Islanders', 'Watch Party'],
    ),
    const _FeedItem(
      author: 'Hepi Q&A',
      authorType: 'fighter',
      region: 'Logan',
      content:
          'Q: "What does Logan mean to you?" A: "Everything. Logan raised me. The Islanders gave me purpose. Fighting is how I give back."',
      type: 'qna',
      timeAgo: '3d',
      reactions: {
        'respect': 189,
        'strong': 67,
        'support': 312,
        'warrior': 45,
        'champion': 28,
      },
      comments: 56,
      shares: 34,
      isPinned: false,
      tags: ['Q&A', 'Logan', 'Islanders'],
    ),
  ];

  Widget _buildFeedItem(_FeedItem item) {
    final authorColor = switch (item.authorType) {
      'fighter' => DesignTokens.neonCyan,
      'gym' => DesignTokens.neonMagenta,
      'admin' => DesignTokens.neonGold,
      'community' => DesignTokens.neonGreen,
      _ => Colors.white54,
    };

    final typeIcon = switch (item.type) {
      'article' => Icons.article,
      'promo' => Icons.campaign,
      'photo' => Icons.image,
      'video' => Icons.videocam,
      'event' => Icons.event,
      'qna' => Icons.question_answer,
      _ => Icons.chat_bubble_outline,
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isPinned
              ? DesignTokens.neonGold.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: authorColor.withValues(alpha: 0.12),
                  child: Text(
                    item.author[0],
                    style: TextStyle(
                      color: authorColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.author,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: authorColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.authorType.toUpperCase(),
                              style: TextStyle(
                                color: authorColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${item.region} · ${item.timeAgo}',
                        style: const TextStyle(
                          color: Colors.white30,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.isPinned)
                  const Icon(
                    Icons.push_pin,
                    color: DesignTokens.neonGold,
                    size: 14,
                  ),
                const SizedBox(width: 4),
                Icon(typeIcon, color: Colors.white24, size: 14),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Text(
              item.content,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          // Tags
          if (item.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Wrap(
                spacing: 6,
                children: item.tags.map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#$t',
                      style: TextStyle(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          // Combat reactions row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            child: Row(
              children: [
                _reactionBtn('🥋', item.reactions['respect'] ?? 0),
                _reactionBtn('💪', item.reactions['strong'] ?? 0),
                _reactionBtn('❤️', item.reactions['support'] ?? 0),
                _reactionBtn('🔥', item.reactions['warrior'] ?? 0),
                _reactionBtn('👑', item.reactions['champion'] ?? 0),
              ],
            ),
          ),
          // Action row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
            child: Row(
              children: [
                _actionChip(Icons.chat_bubble_outline, '${item.comments}'),
                const SizedBox(width: 12),
                _actionChip(Icons.repeat, '${item.shares}'),
                const Spacer(),
                _actionChip(Icons.bookmark_outline, ''),
                const SizedBox(width: 8),
                _actionChip(Icons.flag_outlined, ''),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared Widgets ──

  Widget _ctaBtn(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBtn(IconData icon, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Widget _reactionBtn(String emoji, int count) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: const TextStyle(color: Colors.white30, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white24, size: 16),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(color: Colors.white30, fontSize: 10),
          ),
        ],
      ],
    );
  }
}

class _FeedItem {
  final String author;
  final String authorType;
  final String region;
  final String content;
  final String type;
  final String timeAgo;
  final Map<String, int> reactions;
  final int comments;
  final int shares;
  final bool isPinned;
  final List<String> tags;

  const _FeedItem({
    required this.author,
    required this.authorType,
    required this.region,
    required this.content,
    required this.type,
    required this.timeAgo,
    required this.reactions,
    required this.comments,
    required this.shares,
    required this.isPinned,
    required this.tags,
  });
}
