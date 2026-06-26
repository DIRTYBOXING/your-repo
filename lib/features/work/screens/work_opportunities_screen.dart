import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';

/// WORK OPPORTUNITIES SCREEN - Airtasker-style gig marketplace v3.0
/// For: Fighters, Coaches, Cornermen, Cutmen, Referees, Judges, Promoters
class WorkOpportunitiesScreen extends StatefulWidget {
  const WorkOpportunitiesScreen({super.key});

  @override
  State<WorkOpportunitiesScreen> createState() =>
      _WorkOpportunitiesScreenState();
}

class _WorkOpportunitiesScreenState extends State<WorkOpportunitiesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  String _selectedCategory = 'All';

  // Filter states
  bool _filterFights = true;
  bool _filterCornerWork = true;
  bool _filterCoaching = true;
  bool _filterSparring = true;
  bool _filterOfficiating = true;
  bool _filterMedia = true;
  bool _filterRemote = false;
  bool _filterOnsite = false;

  final List<String> _categories = [
    'All',
    'Fights',
    'Corner Work',
    'Coaching',
    'Sparring',
    'Officiating',
    'Media',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildAppBar(),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildBrowseTab(),
                _buildMyGigsTab(),
                _buildPostGigTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: DesignTokens.bgPrimary,
      expandedHeight: 130,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [DesignTokens.neonAmber, Color(0xFFFF8800)],
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.neonAmber.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.work_outline,
              color: DesignTokens.textPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'WORK HUB',
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: DesignTokens.fontSizeTitle,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                'Find & Post Opportunities',
                style: TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeSubtitle,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.filter_list,
            color: DesignTokens.textSecondary,
          ),
          onPressed: _showFilters,
        ),
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: DesignTokens.textSecondary,
          ),
          onPressed: () => context.push('/notification-settings'),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: DesignTokens.neonAmber,
        labelColor: DesignTokens.neonAmber,
        unselectedLabelColor: DesignTokens.textMuted,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: DesignTokens.fontSizeSubtitleLarge,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: DesignTokens.fontSizeSubtitle,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.search, size: 20), text: 'Browse'),
          Tab(icon: Icon(Icons.assignment, size: 20), text: 'My Gigs'),
          Tab(icon: Icon(Icons.add_circle_outline, size: 20), text: 'Post'),
        ],
      ),
    );
  }

  // =========================================================================
  // BROWSE TAB
  // =========================================================================
  Widget _buildBrowseTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Category Filter
        SliverToBoxAdapter(
          child: Container(
            height: 50,
            margin: const EdgeInsets.only(top: DesignTokens.spacingL),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingL,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: DesignTokens.spacingS),
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingL,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? DesignTokens.neonAmber.withValues(alpha: 0.15)
                          : DesignTokens.bgCard,
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusPill,
                      ),
                      border: Border.all(
                        color: isSelected
                            ? DesignTokens.neonAmber.withValues(alpha: 0.5)
                            : DesignTokens.textDisabled.withValues(alpha: 0.15),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected
                            ? DesignTokens.neonAmber
                            : DesignTokens.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: DesignTokens.fontSizeSubtitleLarge,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Urgent Opportunities Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: DesignTokens.neonRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: DesignTokens.neonRed.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Urgent Opportunities',
                      style: TextStyle(
                        color: DesignTokens.textPrimary,
                        fontSize: DesignTokens.fontSizeBody,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_getUrgentOpportunities().length} available',
                  style: const TextStyle(
                    color: DesignTokens.neonAmber,
                    fontSize: DesignTokens.fontSizeSubtitle,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Urgent Opportunities Horizontal Scroll
        SliverToBoxAdapter(
          child: SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingL,
              ),
              itemCount: _getUrgentOpportunities().length,
              itemBuilder: (context, index) {
                return _UrgentOpportunityCard(
                  opportunity: _getUrgentOpportunities()[index],
                );
              },
            ),
          ),
        ),

        // All Opportunities Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'All Opportunities',
                  style: TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opportunities are sorted by relevance \u2014 newest first'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text(
                    'Sort by',
                    style: TextStyle(
                      color: DesignTokens.neonCyan,
                      fontSize: DesignTokens.fontSizeSubtitleLarge,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Opportunity List
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingL,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final opportunities = _getAllOpportunities();
              if (index >= opportunities.length) return null;
              return Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.spacingM),
                child: _OpportunityCard(opportunity: opportunities[index]),
              );
            }, childCount: _getAllOpportunities().length),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  // =========================================================================
  // MY GIGS TAB
  // =========================================================================
  Widget _buildMyGigsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Overview
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Active', '2', DesignTokens.neonGreen),
              ),
              const SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: _buildStatCard('Pending', '3', DesignTokens.neonAmber),
              ),
              const SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: _buildStatCard('Completed', '12', DesignTokens.neonCyan),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingXXL),

          // Active Gigs
          const Text(
            'Active Gigs',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          _buildActiveGigCard(
            title: 'Corner Work — BKFC KnuckleMania 6',
            date: 'Mar 22, 2026',
            location: 'Miami, FL',
            pay: '\$500',
            status: 'Confirmed',
          ),
          const SizedBox(height: DesignTokens.spacingM),
          _buildActiveGigCard(
            title: 'Sparring Partner — UFC Camp',
            date: 'Mar 10-14, 2026',
            location: 'Melbourne, AU',
            pay: '\$300/day',
            status: 'In Progress',
          ),
          const SizedBox(height: DesignTokens.spacingXXL),

          // Pending Applications
          const Text(
            'Pending Applications',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          _buildPendingApplicationCard(
            title: 'MMA Coach — UFC Title Camp',
            applied: '2 days ago',
            competition: '8 applicants',
          ),
          const SizedBox(height: DesignTokens.spacingM),
          _buildPendingApplicationCard(
            title: 'Cutman — ONE Championship Bangkok',
            applied: '5 days ago',
            competition: '3 applicants',
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: DesignTokens.fontSizeStatLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: DesignTokens.fontSizeSubtitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveGigCard({
    required String title,
    required String date,
    required String location,
    required String pay,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.neonGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: DesignTokens.neonGreen,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: DesignTokens.textMuted,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                date,
                style: const TextStyle(
                  color: DesignTokens.textSecondary,
                  fontSize: DesignTokens.fontSizeSubtitle,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingL),
              const Icon(
                Icons.location_on,
                color: DesignTokens.textMuted,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                location,
                style: const TextStyle(
                  color: DesignTokens.textSecondary,
                  fontSize: DesignTokens.fontSizeSubtitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pay,
                style: const TextStyle(
                  color: DesignTokens.neonGreen,
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message sent to poster'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Color(0xFF1B5E20),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DesignTokens.textSecondary,
                      side: BorderSide(
                        color: DesignTokens.textDisabled.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusSmall,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Message',
                      style: TextStyle(fontSize: DesignTokens.fontSizeSubtitle),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingS),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening details for: $title'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.neonGreen,
                      foregroundColor: DesignTokens.bgPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusSmall,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeSubtitle,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApplicationCard({
    required String title,
    required String applied,
    required String competition,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.textDisabled.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: DesignTokens.neonAmber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            ),
            child: const Icon(
              Icons.hourglass_empty,
              color: DesignTokens.neonAmber,
              size: 24,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Applied $applied',
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: DesignTokens.fontSizeCaption,
                      ),
                    ),
                    const Text(
                      ' \u2022 ',
                      style: TextStyle(color: DesignTokens.textDisabled),
                    ),
                    Text(
                      competition,
                      style: const TextStyle(
                        color: DesignTokens.neonAmber,
                        fontSize: DesignTokens.fontSizeCaption,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_right,
              color: DesignTokens.textMuted,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tap the listing title for full details'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // POST GIG TAB
  // =========================================================================
  Widget _buildPostGigTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(DesignTokens.cardPaddingLarge),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.neonAmber.withValues(alpha: 0.12),
                  DesignTokens.neonAmber.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              border: Border.all(
                color: DesignTokens.neonAmber.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DesignTokens.neonAmber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.campaign,
                        color: DesignTokens.neonAmber,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Post an Opportunity',
                            style: TextStyle(
                              color: DesignTokens.textPrimary,
                              fontSize: DesignTokens.fontSizeTitle,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Connect with combat sports professionals',
                            style: TextStyle(
                              color: DesignTokens.textSecondary,
                              fontSize: DesignTokens.fontSizeSubtitleLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXXL),

          // Quick Post Options
          const Text(
            'What do you need?',
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Wrap(
            spacing: DesignTokens.spacingM,
            runSpacing: DesignTokens.spacingM,
            children: [
              _buildQuickPostOption(
                'Fighter',
                Icons.sports_mma,
                DesignTokens.neonRed,
              ),
              _buildQuickPostOption(
                'Corner',
                Icons.people,
                DesignTokens.neonCyan,
              ),
              _buildQuickPostOption(
                'Coach',
                Icons.school,
                DesignTokens.neonGreen,
              ),
              _buildQuickPostOption(
                'Sparring',
                Icons.fitness_center,
                DesignTokens.neonAmber,
              ),
              _buildQuickPostOption(
                'Cutman',
                Icons.healing,
                DesignTokens.neonMagenta,
              ),
              _buildQuickPostOption(
                'Referee',
                Icons.gavel,
                const Color(0xFF9C27B0),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingXXL),

          // Form Fields
          _buildFormField(
            'Title',
            'e.g., Welterweight fighter needed for Feb 20',
          ),
          const SizedBox(height: DesignTokens.spacingL),
          _buildFormField(
            'Description',
            'Describe the opportunity...',
            maxLines: 4,
          ),
          const SizedBox(height: DesignTokens.spacingL),
          Row(
            children: [
              Expanded(child: _buildFormField('Location', 'City, State')),
              const SizedBox(width: DesignTokens.spacingM),
              Expanded(child: _buildFormField('Date', 'When needed')),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingL),
          Row(
            children: [
              Expanded(child: _buildFormField('Pay', 'e.g., \$500')),
              const SizedBox(width: DesignTokens.spacingM),
              Expanded(child: _buildFormField('Duration', 'e.g., 1 day')),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingXXL),

          // Post Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opportunity posted successfully!'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Color(0xFF1B5E20),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.neonAmber,
                foregroundColor: DesignTokens.bgPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                ),
              ),
              child: const Text(
                'POST OPPORTUNITY',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildQuickPostOption(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: DesignTokens.fontSizeSubtitleLarge,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: DesignTokens.textSecondary,
            fontSize: DesignTokens.fontSizeSubtitle,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          maxLines: maxLines,
          style: const TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: DesignTokens.fontSizeBody,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: DesignTokens.textDisabled),
            filled: true,
            fillColor: DesignTokens.bgCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              borderSide: BorderSide(
                color: DesignTokens.textDisabled.withValues(alpha: 0.15),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              borderSide: BorderSide(
                color: DesignTokens.textDisabled.withValues(alpha: 0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              borderSide: const BorderSide(color: DesignTokens.neonAmber),
            ),
          ),
        ),
      ],
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Opportunities',
                        style: TextStyle(
                          color: DesignTokens.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: DesignTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Divider
                  Container(height: 1, color: DesignTokens.borderSubtle),
                  const SizedBox(height: 20),
                  // Opportunity Types
                  const Text(
                    'Opportunity Types',
                    style: TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFilterCheckbox(
                    'Fights',
                    _filterFights,
                    (val) => setModalState(() => _filterFights = val),
                    Icons.sports_mma,
                    DesignTokens.neonCyan,
                  ),
                  _buildFilterCheckbox(
                    'Corner Work',
                    _filterCornerWork,
                    (val) => setModalState(() => _filterCornerWork = val),
                    Icons.medical_services,
                    DesignTokens.neonGreen,
                  ),
                  _buildFilterCheckbox(
                    'Coaching',
                    _filterCoaching,
                    (val) => setModalState(() => _filterCoaching = val),
                    Icons.school,
                    DesignTokens.neonMagenta,
                  ),
                  _buildFilterCheckbox(
                    'Sparring',
                    _filterSparring,
                    (val) => setModalState(() => _filterSparring = val),
                    Icons.fitness_center,
                    DesignTokens.neonAmber,
                  ),
                  _buildFilterCheckbox(
                    'Officiating',
                    _filterOfficiating,
                    (val) => setModalState(() => _filterOfficiating = val),
                    Icons.gavel,
                    DesignTokens.neonGold,
                  ),
                  _buildFilterCheckbox(
                    'Media',
                    _filterMedia,
                    (val) => setModalState(() => _filterMedia = val),
                    Icons.camera_alt,
                    DesignTokens.neonMagenta,
                  ),
                  const SizedBox(height: 24),
                  // Location Type
                  const Text(
                    'Location Type',
                    style: TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFilterCheckbox(
                    'Remote',
                    _filterRemote,
                    (val) => setModalState(() => _filterRemote = val),
                    Icons.wifi,
                    DesignTokens.neonCyan,
                  ),
                  _buildFilterCheckbox(
                    'On-site',
                    _filterOnsite,
                    (val) => setModalState(() => _filterOnsite = val),
                    Icons.location_on,
                    DesignTokens.neonGreen,
                  ),
                  const SizedBox(height: 24),
                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          // Update main state with modal state
                          // Filters are already applied via setModalState
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.neonCyan,
                        foregroundColor: DesignTokens.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Reset Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        setModalState(() {
                          _filterFights = true;
                          _filterCornerWork = true;
                          _filterCoaching = true;
                          _filterSparring = true;
                          _filterOfficiating = true;
                          _filterMedia = true;
                          _filterRemote = false;
                          _filterOnsite = false;
                        });
                      },
                      child: const Text(
                        'Reset Filters',
                        style: TextStyle(
                          color: DesignTokens.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildFilterCheckbox(
    String label,
    bool value,
    Function(bool) onChanged,
    IconData icon,
    Color color,
  ) {
    return CheckboxListTile(
      value: value,
      onChanged: (val) => onChanged(val ?? false),
      title: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      activeColor: color,
      checkColor: DesignTokens.bgPrimary,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }

  List<Map<String, dynamic>> _getUrgentOpportunities() {
    return [
      {
        'title': 'Short Notice Fighter — 77 kg / 170 lbs',
        'type': 'Fight',
        'location': 'Tampa, FL',
        'date': 'Mar 7',
        'pay': '\$2,500',
        'weight': 'Welterweight',
        'urgency': 'ASAP',
      },
      {
        'title': 'Cornerman Needed — PFL Card',
        'type': 'Corner Work',
        'location': 'Sydney, AU',
        'date': 'Mar 15',
        'pay': '\$500',
        'weight': null,
        'urgency': '10 days',
      },
      {
        'title': 'Cutman — BKFC KnuckleMania',
        'type': 'Medical',
        'location': 'Miami, FL',
        'date': 'Mar 22',
        'pay': '\$800',
        'weight': null,
        'urgency': '17 days',
      },
    ];
  }

  List<Map<String, dynamic>> _getAllOpportunities() {
    return [
      {
        'title': 'MMA Coach for 8-Week Title Camp',
        'type': 'Coaching',
        'location': 'Melbourne, AU',
        'date': 'Mar 10 - May 4',
        'pay': '\$5,000',
        'description':
            'Experienced MMA coach needed for fight camp with ranked UFC contender',
        'applicants': 5,
        'posted': '1 day ago',
      },
      {
        'title': 'Sparring Partners — Heavyweight',
        'type': 'Sparring',
        'location': 'Las Vegas, NV',
        'date': 'Mar 15-28',
        'pay': '\$300/day',
        'description':
            'UFC heavyweight needs quality sparring for UFC 315 prep',
        'applicants': 8,
        'posted': '2 days ago',
      },
      {
        'title': 'Boxing Trainer — Online Sessions',
        'type': 'Coaching',
        'location': 'Remote/Online',
        'date': 'Flexible',
        'pay': '\$75/hour',
        'description':
            'Online boxing technique sessions for amateur fighters worldwide',
        'applicants': 12,
        'posted': '3 days ago',
      },
      {
        'title': 'Referee — Amateur MMA Event',
        'type': 'Officiating',
        'location': 'Brisbane, AU',
        'date': 'Mar 22',
        'pay': '\$400',
        'description': 'Licensed referee needed for Eternal MMA amateur card',
        'applicants': 3,
        'posted': '4 days ago',
      },
      {
        'title': 'Strength & Conditioning Coach',
        'type': 'Coaching',
        'location': 'New York, NY',
        'date': 'Ongoing',
        'pay': '\$80/hour',
        'description':
            'S&C specialist for pro MMA team at Legacy Grappling Academy',
        'applicants': 7,
        'posted': '5 days ago',
      },
    ];
  }
}

/// Urgent Opportunity Card - Horizontal scroll
class _UrgentOpportunityCard extends StatelessWidget {
  final Map<String, dynamic> opportunity;

  const _UrgentOpportunityCard({required this.opportunity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: DesignTokens.spacingM),
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.neonRed.withValues(alpha: 0.12),
            DesignTokens.neonAmber.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: DesignTokens.neonRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.neonRed,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                ),
                child: Text(
                  opportunity['urgency'],
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: DesignTokens.fontSizeMicro,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                opportunity['type'],
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeCaption,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            opportunity['title'],
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (opportunity['weight'] != null) ...[
            const SizedBox(height: 4),
            Text(
              opportunity['weight'],
              style: const TextStyle(
                color: DesignTokens.neonAmber,
                fontSize: DesignTokens.fontSizeSubtitle,
              ),
            ),
          ],
          const Spacer(),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: DesignTokens.textMuted,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                opportunity['location'],
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeCaption,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                opportunity['pay'],
                style: const TextStyle(
                  color: DesignTokens.neonGreen,
                  fontSize: DesignTokens.fontSizeTitle,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Application submitted!'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Color(0xFF1B5E20),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.neonRed,
                  foregroundColor: DesignTokens.textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusSmall,
                    ),
                  ),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeSubtitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Standard Opportunity Card
class _OpportunityCard extends StatelessWidget {
  final Map<String, dynamic> opportunity;

  const _OpportunityCard({required this.opportunity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.textDisabled.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                ),
                child: Text(
                  opportunity['type'],
                  style: const TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: DesignTokens.fontSizeMicro,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                opportunity['posted'],
                style: const TextStyle(
                  color: DesignTokens.textDisabled,
                  fontSize: DesignTokens.fontSizeCaption,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            opportunity['title'],
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            opportunity['description'],
            style: const TextStyle(
              color: DesignTokens.textMuted,
              fontSize: DesignTokens.fontSizeSubtitleLarge,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: DesignTokens.textDisabled,
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                opportunity['date'],
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeCaption,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingL),
              const Icon(
                Icons.location_on,
                color: DesignTokens.textDisabled,
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                opportunity['location'],
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeCaption,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    opportunity['pay'],
                    style: const TextStyle(
                      color: DesignTokens.neonGreen,
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingM),
                  const Icon(
                    Icons.people,
                    color: DesignTokens.textDisabled,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${opportunity['applicants']} applied',
                    style: const TextStyle(
                      color: DesignTokens.textDisabled,
                      fontSize: DesignTokens.fontSizeCaption,
                    ),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: () {
                  final jobId =
                      (opportunity['title'] as String?)
                          ?.toLowerCase()
                          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                          .replaceAll(RegExp(r'^-|-$'), '') ??
                      'unknown';
                  context.push('/jobs/$jobId');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: DesignTokens.neonCyan,
                  side: const BorderSide(color: DesignTokens.neonCyan),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusSmall,
                    ),
                  ),
                ),
                child: const Text(
                  'View',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeSubtitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
