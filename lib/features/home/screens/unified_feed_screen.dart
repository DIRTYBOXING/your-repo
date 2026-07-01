import 'package:flutter/material.dart';
import 'package:datafightcentral/features/social/screens/dfc_feed_screen.dart';
import 'package:datafightcentral/features/fightwire/screens/fightwire_master_screen.dart';

class UnifiedFeedScreen extends StatefulWidget {
  const UnifiedFeedScreen({super.key});

  @override
  State<UnifiedFeedScreen> createState() => _UnifiedFeedScreenState();
}

class _UnifiedFeedScreenState extends State<UnifiedFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Smart Highlights'),
            Tab(text: 'Official'),
            Tab(text: 'Community'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SmartHighlightsTab(),
          FightWireMasterScreen(),
          DFCFeedScreen(),
        ],
      ),
    );
  }
}

class _SmartHighlightsTab extends StatelessWidget {
  const _SmartHighlightsTab();

  @override
  Widget build(BuildContext context) {
    // Blend both feeds into one scrollable highlights view
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00D9FF).withValues(alpha: 0.1),
                  const Color(0xFFFF00FF).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00D9FF).withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF00D9FF), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Smart Highlights — top trending from Official news and Community posts, blended by engagement.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'OFFICIAL HIGHLIGHTS',
              style: TextStyle(
                color: Color(0xFF00D9FF),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 280, child: FightWireMasterScreen()),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'COMMUNITY HIGHLIGHTS',
              style: TextStyle(
                color: Color(0xFFFF00FF),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SliverFillRemaining(child: DFCFeedScreen()),
      ],
    );
  }
}
