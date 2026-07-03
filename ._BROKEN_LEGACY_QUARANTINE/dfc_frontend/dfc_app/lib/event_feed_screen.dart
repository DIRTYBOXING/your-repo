import 'package:flutter/material.dart';

class EventFeedScreen extends StatelessWidget {
  const EventFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          children: [
            const SizedBox(height: 32),

            // ─── 1. HEADER ───────────────────────────────────────────────────
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'EVENT FEED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const Icon(Icons.filter_list, color: Colors.white54),
              ],
            ),
            const SizedBox(height: 24),

            // ─── 2. CATEGORIES ───────────────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryPill('ALL', isActive: true),
                  const SizedBox(width: 12),
                  _buildCategoryPill('ANNOUNCEMENTS'),
                  const SizedBox(width: 12),
                  _buildCategoryPill('NEWS'),
                  const SizedBox(width: 12),
                  _buildCategoryPill('HIGHLIGHTS'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ─── 3. FEED CONTENT ─────────────────────────────────────────────

            // Announcement Card
            _buildAnnouncementCard(
              tag: 'BREAKING NEWS',
              tagColor: Colors.redAccent,
              title: 'DFC 2 Main Event Finalized: Ewart vs. Torres',
              description:
                  'The lightweight title eliminator is officially set for Melbourne Arena this October. Tickets go on sale this Friday.',
              time: '2 hours ago',
            ),
            const SizedBox(height: 24),

            // Highlight / Media Card
            _buildHighlightCard(
              tag: 'HIGHLIGHT',
              tagColor: Colors.purpleAccent,
              title: 'Top 5 Knockouts of DFC 1',
              imageUrl:
                  'https://images.unsplash.com/photo-1599552375245-298069501538?auto=format&fit=crop&q=80&w=800',
              duration: '04:12',
              time: '5 hours ago',
            ),
            const SizedBox(height: 24),

            // Standard News Card
            _buildNewsCard(
              tag: 'ROSTER UPDATE',
              tagColor: Colors.blueAccent,
              title: 'Mason Lee signs multi-fight extension',
              description:
                  'The middleweight contender has officially inked a new 4-fight deal with the promotion following his spectacular submission victory.',
              time: 'Yesterday',
            ),
            const SizedBox(height: 24),

            // Another Media Card
            _buildHighlightCard(
              tag: 'INTERVIEW',
              tagColor: Colors.cyanAccent,
              title: 'Kai Johnson: "I\'m coming for the belt"',
              imageUrl:
                  'https://images.unsplash.com/photo-1555597673-b21d5c935865?auto=format&fit=crop&q=80&w=800',
              duration: '12:45',
              time: '2 days ago',
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // ─── HELPER WIDGETS ────────────────────────────────────────────────────────

  Widget _buildCategoryPill(String title, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.cyanAccent : Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard({
    required String tag,
    required Color tagColor,
    required String title,
    required String description,
    required String time,
  }) {
    return _DfcCard(
      glow: true,
      glowColor: tagColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: tagColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                time,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCard({
    required String tag,
    required Color tagColor,
    required String title,
    required String imageUrl,
    required String duration,
    required String time,
  }) {
    return _DfcCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.3),
                      BlendMode.darken,
                    ),
                  ),
                ),
              ),
              Icon(
                Icons.play_circle_fill,
                color: Colors.white.withValues(alpha: 0.9),
                size: 54,
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    duration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tag,
                  style: TextStyle(
                    color: tagColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard({
    required String tag,
    required Color tagColor,
    required String title,
    required String description,
    required String time,
  }) {
    return _buildAnnouncementCard(
      tag: tag,
      tagColor: tagColor,
      title: title,
      description: description,
      time: time,
    );
  }
}

class _DfcCard extends StatelessWidget {
  final Widget child;
  final bool glow;
  final Color glowColor;
  final EdgeInsetsGeometry padding;

  const _DfcCard({
    required this.child,
    this.glow = false,
    this.glowColor = Colors.cyanAccent,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: child,
    );
  }
}
