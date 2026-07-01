import 'package:flutter/material.dart';
import '../../../shared/services/fighter_career_engine_service.dart';
import '../../../shared/services/fighter_brand_engine_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHTER CAREER DASHBOARD — AI career tracking + brand overview.
/// Connects: FighterCareerEngine + FighterBrandEngine → Fighter UI
/// ═══════════════════════════════════════════════════════════════════════════

const _kBg = Color(0xFF060A14);
const _kPanel = Color(0xFF0C1226);
const _kBorder = Color(0xFF1A2744);
const _kCyan = Color(0xFF00E5FF);
const _kGold = Color(0xFFFFD740);
const _kGreen = Color(0xFF00E676);
const _kMagenta = Color(0xFFE040FB);
const _kOrange = Color(0xFFFF9100);

class FighterCareerDashboardScreen extends StatefulWidget {
  final String fighterId;
  const FighterCareerDashboardScreen({super.key, required this.fighterId});

  @override
  State<FighterCareerDashboardScreen> createState() =>
      _FighterCareerDashboardScreenState();
}

class _FighterCareerDashboardScreenState
    extends State<FighterCareerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final FighterCareerEngineService _career = FighterCareerEngineService();
  final FighterBrandEngineService _brand = FighterBrandEngineService();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('CAREER DASHBOARD'),
        backgroundColor: _kBg,
        foregroundColor: _kCyan,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _kCyan,
          labelColor: _kCyan,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'OVERVIEW'),
            Tab(text: 'CAREER PATH'),
            Tab(text: 'BRAND'),
            Tab(text: 'OPPORTUNITIES'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildOverview(),
          _buildCareerPath(),
          _buildBrand(),
          _buildOpportunities(),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPhaseCard(),
        const SizedBox(height: 16),
        _buildStatsGrid(),
        const SizedBox(height: 16),
        _buildRecommendations(),
      ],
    );
  }

  Widget _buildPhaseCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kCyan.withValues(alpha: 0.15),
            _kMagenta.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kCyan.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Text(
            'CURRENT PHASE',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'RISING CONTENDER',
            style: TextStyle(
              color: _kGold,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_career.totalAssessments} assessments · DFC Career Engine',
            style: TextStyle(
              color: _kCyan.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: 0.62,
              backgroundColor: _kBorder,
              color: _kGold,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prospect',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
              Text(
                'Champion',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      const _StatCard('Win Rate', '78%', _kGreen),
      const _StatCard('Fight IQ', '85', _kCyan),
      const _StatCard('Marketability', '72', _kMagenta),
      const _StatCard('Global Rank', '#47', _kGold),
      const _StatCard('Finish Rate', '65%', _kOrange),
      const _StatCard('Activity', 'HIGH', _kGreen),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, i) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _kPanel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: stats[i].color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              stats[i].value,
              style: TextStyle(
                color: stats[i].color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stats[i].label,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: _kGold, size: 18),
              SizedBox(width: 8),
              Text(
                'AI RECOMMENDATIONS',
                style: TextStyle(
                  color: _kGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _recommendRow(
            Icons.sports_mma,
            'Take 2 more regional fights before title shot',
            _kCyan,
          ),
          _recommendRow(
            Icons.fitness_center,
            'Grappling needs improvement — train 3x/week',
            _kOrange,
          ),
          _recommendRow(
            Icons.camera_alt,
            'Post 3 training clips/week for brand growth',
            _kMagenta,
          ),
          _recommendRow(
            Icons.medical_services,
            'Schedule pre-fight medical by March 15',
            _kGreen,
          ),
        ],
      ),
    );
  }

  Widget _recommendRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerPath() {
    final milestones = [
      const _Milestone('First Amateur Fight', 'Completed', _kGreen, true),
      const _Milestone('Amateur Title', 'Completed', _kGreen, true),
      const _Milestone('Pro Debut', 'Completed', _kGreen, true),
      const _Milestone('10 Pro Fights', 'In Progress (7/10)', _kCyan, false),
      const _Milestone('Regional Title Shot', 'Upcoming', _kGold, false),
      const _Milestone('National Ranking', 'Future', Colors.white38, false),
      const _Milestone('Championship', 'Goal', _kMagenta, false),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'CAREER ROADMAP',
          style: TextStyle(
            color: _kCyan,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        ...milestones.asMap().entries.map(
          (e) => _milestoneRow(e.value, e.key == milestones.length - 1),
        ),
      ],
    );
  }

  Widget _milestoneRow(_Milestone m, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: m.done ? m.color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: m.color, width: 2),
              ),
              child: m.done
                  ? const Icon(Icons.check, color: Colors.black, size: 12)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: m.done ? m.color : _kBorder,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.title,
                  style: TextStyle(
                    color: m.done ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(m.status, style: TextStyle(color: m.color, fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrand() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kPanel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kMagenta.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              const Icon(Icons.palette, color: _kMagenta, size: 48),
              const SizedBox(height: 12),
              const Text(
                'FIGHTER BRAND',
                style: TextStyle(
                  color: _kMagenta,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_brand.totalBrandsCreated} brand profiles created on DFC',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('GENERATE BRAND REFRESH'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kMagenta,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _brandMetric('Brand Score', '72 / 100', _kMagenta),
        _brandMetric('Social Reach', '12.4K followers', _kCyan),
        _brandMetric('Merch Potential', 'HIGH', _kGold),
        _brandMetric('Sponsor Value', '\$2,800/fight', _kGreen),
      ],
    );
  }

  Widget _brandMetric(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunities() {
    final opportunities = [
      const _Opp('Regional Title Fight', 'Mar 22, Sydney', _kGold, 'Recommended'),
      const _Opp('Undercard Slot — DFC 14', 'Apr 5, Melbourne', _kCyan, 'Good Match'),
      const _Opp('Amateur Exhibition', 'Apr 18, Brisbane', _kGreen, 'Training'),
      const _Opp('International Card', 'May 10, Auckland NZ', _kMagenta, 'Stretch'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'AI-MATCHED OPPORTUNITIES',
          style: TextStyle(
            color: _kGold,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        ...opportunities.map(
          (o) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kPanel,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: o.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        o.subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
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
                    color: o.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    o.tag,
                    style: TextStyle(
                      color: o.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
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
}

class _StatCard {
  final String label;
  final String value;
  final Color color;
  const _StatCard(this.label, this.value, this.color);
}

class _Milestone {
  final String title;
  final String status;
  final Color color;
  final bool done;
  const _Milestone(this.title, this.status, this.color, this.done);
}

class _Opp {
  final String title;
  final String subtitle;
  final Color color;
  final String tag;
  const _Opp(this.title, this.subtitle, this.color, this.tag);
}
