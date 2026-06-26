import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';

/// JOB DETAIL SCREEN — Full job/gig listing detail view
/// Shows description, requirements, pay, location, applicants & apply button
class JobDetailScreen extends StatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  bool _hasApplied = false;
  bool _isSaved = false;

  // Job data — reads from Firestore in production
  late Map<String, dynamic> _job;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
    _loadJob();
  }

  void _loadJob() {
    // Map of jobs keyed by ID — Firestore-backed in production
    final jobs = <String, Map<String, dynamic>>{
      'corner-crew-ufc': {
        'title': 'Corner Crew — UFC Fight Night Sydney',
        'company': 'DFC Events',
        'location': 'Sydney, NSW, Australia',
        'type': 'Contract',
        'pay': '\$800 – \$1,200 per event',
        'posted': '2 hours ago',
        'applicants': 14,
        'category': 'Corner Work',
        'urgency': 'Urgent',
        'description':
            'We need experienced corner crew for an upcoming UFC Fight Night event in Sydney. This includes cutmen, seconds, and corner coaches who can work a full 12-bout card. Must hold current Combat Sports Commission accreditation.',
        'requirements': [
          'Minimum 2 years corner experience',
          'Current first-aid certification',
          'State Combat Sports Commission licence',
          'Own corner kit (ice bags, enswell, adrenaline, vaseline)',
          'Available for full fight day (10am – 11pm)',
        ],
        'perks': [
          'Ringside access',
          'DFC Pro Network badge',
          'Future event priority listing',
          'Post-event athlete mixer invite',
        ],
      },
      'muay-thai-coach': {
        'title': 'Head Muay Thai Coach — DFC Partner Gym',
        'company': 'DFC Partner Gym',
        'location': 'Brisbane, QLD, Australia',
        'type': 'Full-Time',
        'pay': '\$65,000 – \$85,000 p.a.',
        'posted': '1 day ago',
        'applicants': 8,
        'category': 'Coaching',
        'urgency': 'Open',
        'description':
            'DFC Partner Gym is looking for a passionate Head Muay Thai Coach to lead our striking program. You will manage class schedules, fighter development, and competition prep for amateur and professional athletes.',
        'requirements': [
          '5+ years coaching experience',
          'Professional fighting record preferred',
          'Kru or Ajarn certification',
          'Working with Children Check',
          'Current CPR & first-aid',
        ],
        'perks': [
          'Gym membership for life',
          'Fighter profit share on PPV events',
          'Equipment sponsorship',
          'Annual Thailand training camp',
        ],
      },
      'ring-announcer': {
        'title': 'Ring Announcer — BKFC Australia Tour',
        'company': 'Bare Knuckle FC',
        'location': 'Perth, WA → Melbourne, VIC → Sydney, NSW',
        'type': 'Freelance',
        'pay': '\$500 per event + travel',
        'posted': '3 days ago',
        'applicants': 22,
        'category': 'Media',
        'urgency': 'Open',
        'description':
            'BKFC is expanding to Australia and needs a commanding ring announcer for the 3-city tour. Must have a powerful stage presence, ability to hype a crowd, and experience with combat sports event protocols.',
        'requirements': [
          'Prior ring or cage announcing experience',
          'Strong vocal projection (no mic dependency)',
          'Available for 3 consecutive weekends',
          'Own formal ringside attire',
          'Comfortable with graphic combat sports',
        ],
        'perks': [
          'All travel & hotel covered',
          'VIP backstage access',
          'Highlight reel inclusion',
          'Potential ongoing BKFC contract',
        ],
      },
      'sparring-partner': {
        'title': 'Sparring Partner — Heavyweight MMA Camp',
        'company': 'Team Tszyu HQ',
        'location': 'Rockdale, NSW, Australia',
        'type': 'Short-Term',
        'pay': '\$200 – \$350 per session',
        'posted': '5 hours ago',
        'applicants': 6,
        'category': 'Sparring',
        'urgency': 'Urgent',
        'description':
            'High-level sparring partner needed for a professional heavyweight preparing for a title fight. Must be 90kg+ and capable of simulating southpaw pressure wrestling style. Runs for 3 weeks, 4 sessions per week.',
        'requirements': [
          'Active amateur or professional MMA record',
          'Weight 90kg+',
          'Can simulate southpaw wrestling pressure',
          'Current medical clearance',
          'Reliable and punctual',
        ],
        'perks': [
          'Train alongside world-class coaches',
          'Access to full training facility',
          'Fight camp meal plan included',
          'Network with management team',
        ],
      },
      'referee-boxing': {
        'title': 'Boxing Referee — State Championship Card',
        'company': 'Boxing Australia',
        'location': 'Gold Coast, QLD, Australia',
        'type': 'Contract',
        'pay': '\$300 – \$600 per bout',
        'posted': '12 hours ago',
        'applicants': 4,
        'category': 'Officiating',
        'urgency': 'Open',
        'description':
            'Licensed boxing referees needed for the Queensland State Championship card. Must hold current Boxing Australia accreditation. Card includes 8 bouts from amateur to professional level.',
        'requirements': [
          'Boxing Australia Class A or B referee licence',
          'Minimum 20 bouts officiated',
          'Professional appearance and conduct',
          'Attend pre-event rules meeting',
          'Available full event day',
        ],
        'perks': [
          'National ranking points',
          'Priority selection for future Boxing Australia events',
          'Professional development session included',
        ],
      },
    };

    _job =
        jobs[widget.jobId] ??
        {
          'title': 'Combat Sports Opportunity',
          'company': 'DFC Network',
          'location': 'Australia',
          'type': 'Various',
          'pay': 'Competitive',
          'posted': 'Recently',
          'applicants': 0,
          'category': 'General',
          'urgency': 'Open',
          'description':
              'An exciting opportunity in the combat sports industry. Check back for more details or browse other listings in the DFC Work Hub.',
          'requirements': <String>[
            'Passion for combat sports',
            'Relevant experience or qualifications',
          ],
          'perks': <String>['DFC Network access', 'Industry connections'],
        };
  }

  @override
  void dispose() {
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
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildQuickInfo()),
              SliverToBoxAdapter(child: _buildDescription()),
              SliverToBoxAdapter(child: _buildRequirements()),
              SliverToBoxAdapter(child: _buildPerks()),
              SliverToBoxAdapter(child: _buildApplicantInfo()),
              SliverToBoxAdapter(child: _buildCompanyCard()),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: DesignTokens.bgPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Job Details',
        style: TextStyle(
          color: DesignTokens.neonCyan,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isSaved ? Icons.bookmark : Icons.bookmark_border,
            color: _isSaved ? DesignTokens.neonAmber : Colors.white54,
          ),
          onPressed: () => setState(() => _isSaved = !_isSaved),
        ),
        IconButton(
          icon: const Icon(Icons.share_rounded, color: Colors.white54),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Link copied to clipboard'),
                backgroundColor: DesignTokens.neonCyan.withValues(alpha: 0.8),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────
  Widget _buildHeader() {
    final isUrgent = _job['urgency'] == 'Urgent';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isUrgent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.redAccent, width: 0.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.redAccent,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'URGENT HIRE',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          Text(
            _job['title'] ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DesignTokens.neonCyan.withValues(alpha: 0.3),
                      DesignTokens.neonMagenta.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.business,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _job['company'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _job['posted'] ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
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

  // ── Quick Info Chips ─────────────────────────────────────────────
  Widget _buildQuickInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _infoChip(
            Icons.location_on,
            _job['location'] ?? '',
            DesignTokens.neonCyan,
          ),
          _infoChip(
            Icons.work_outline,
            _job['type'] ?? '',
            DesignTokens.neonGreen,
          ),
          _infoChip(
            Icons.attach_money,
            _job['pay'] ?? '',
            DesignTokens.neonAmber,
          ),
          _infoChip(
            Icons.category_outlined,
            _job['category'] ?? '',
            DesignTokens.neonMagenta,
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Description ──────────────────────────────────────────────────
  Widget _buildDescription() {
    return _sectionCard(
      'About This Opportunity',
      Icons.description_outlined,
      child: Text(
        _job['description'] ?? '',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }

  // ── Requirements ─────────────────────────────────────────────────
  Widget _buildRequirements() {
    final reqs = (_job['requirements'] as List<dynamic>?)?.cast<String>() ?? [];
    return _sectionCard(
      'Requirements',
      Icons.checklist_rounded,
      child: Column(
        children: reqs
            .map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: DesignTokens.neonGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.4,
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

  // ── Perks ────────────────────────────────────────────────────────
  Widget _buildPerks() {
    final perks = (_job['perks'] as List<dynamic>?)?.cast<String>() ?? [];
    return _sectionCard(
      'Perks & Benefits',
      Icons.card_giftcard_rounded,
      child: Column(
        children: perks
            .map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: DesignTokens.neonAmber,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.4,
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

  // ── Applicant Info ───────────────────────────────────────────────
  Widget _buildApplicantInfo() {
    final count = _job['applicants'] ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: DesignTokens.neonCyan.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: DesignTokens.neonCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.people_outline,
                color: DesignTokens.neonCyan,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count applicants so far',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count < 10
                        ? 'Low competition — apply now'
                        : 'High interest — stand out with your profile',
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
      ),
    );
  }

  // ── Company Card ─────────────────────────────────────────────────
  Widget _buildCompanyCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              DesignTokens.neonCyan.withValues(alpha: 0.06),
              DesignTokens.neonMagenta.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: DesignTokens.neonMagenta.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _job['company'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const Text(
                        'Verified DFC Partner',
                        style: TextStyle(
                          color: Color(0xFF00FF88),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'This employer is a verified member of the DFC Network. All listings are reviewed for safety and authenticity.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Apply Bar ─────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: DesignTokens.bgSecondary,
        border: Border(
          top: BorderSide(color: DesignTokens.neonCyan.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_hasApplied) {
                  setState(() => _hasApplied = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        '✅ Application submitted! You\'ll hear back soon.',
                      ),
                      backgroundColor: DesignTokens.neonGreen.withValues(
                        alpha: 0.85,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: _hasApplied
                      ? LinearGradient(
                          colors: [
                            DesignTokens.neonGreen.withValues(alpha: 0.3),
                            DesignTokens.neonGreen.withValues(alpha: 0.15),
                          ],
                        )
                      : const LinearGradient(
                          colors: [
                            DesignTokens.neonCyan,
                            DesignTokens.neonMagenta,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    _hasApplied ? '✓ APPLIED' : 'APPLY NOW',
                    style: TextStyle(
                      color: _hasApplied
                          ? DesignTokens.neonGreen
                          : Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('💬 Message sent to employer'),
                  backgroundColor: DesignTokens.neonMagenta.withValues(
                    alpha: 0.85,
                  ),
                ),
              );
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: DesignTokens.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: DesignTokens.neonMagenta.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: DesignTokens.neonMagenta,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Card Helper ──────────────────────────────────────────
  Widget _sectionCard(String title, IconData icon, {required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        width: double.infinity,
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
                Icon(icon, color: DesignTokens.neonCyan, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
