import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// ═══════════════════════════════════════════════════════════════
/// DFC COMMUNITY RESOURCE HUB
///
/// A comprehensive directory of support services for anyone in
/// crisis or need. Categories include:
/// • Emergency & Crisis Lines
/// • Homelessness & Shelter
/// • Mental Health & Counselling
/// • Addiction & Recovery
/// • Domestic & Family Violence
/// • Food & Essentials
/// • Disability Support
/// • Youth & Children
/// • Veterans & First Responders
/// • Financial & Legal Aid
///
/// "You are not alone — help is always one call away"
/// ═══════════════════════════════════════════════════════════════

// ── Resource Hub palette ──
const Color _rhCyan = Color(0xFF00F5FF);
const Color _rhGreen = Color(0xFF00FF88);
const Color _rhPink = Color(0xFFFF6B9D);
const Color _rhGold = Color(0xFFFFD700);
const Color _rhWarm = Color(0xFFFF8C42);
const Color _rhRed = Color(0xFFFF3366);
const Color _rhPurple = Color(0xFFBB86FC);
const Color _rhBlue = Color(0xFF4FC3F7);
const Color _rhBg = Color(0xFF050A14);
const Color _rhCard = Color(0xFF0D1B2A);

class ResourceHubScreen extends StatefulWidget {
  const ResourceHubScreen({super.key});

  @override
  State<ResourceHubScreen> createState() => _ResourceHubScreenState();
}

class _ResourceHubScreenState extends State<ResourceHubScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<_ResourceCategory> _categories = [
    const _ResourceCategory('All', Icons.apps, _rhCyan),
    const _ResourceCategory('Emergency', Icons.emergency, _rhRed),
    const _ResourceCategory('Shelter', Icons.night_shelter, _rhWarm),
    const _ResourceCategory('Mental Health', Icons.psychology, _rhPurple),
    const _ResourceCategory('Addiction', Icons.healing, _rhPink),
    const _ResourceCategory('Violence', Icons.shield, _rhRed),
    const _ResourceCategory('Food', Icons.restaurant, _rhGold),
    const _ResourceCategory('Disability', Icons.accessible, _rhBlue),
    const _ResourceCategory('Youth', Icons.child_care, _rhGreen),
    const _ResourceCategory('Veterans', Icons.military_tech, _rhWarm),
    const _ResourceCategory('Financial', Icons.account_balance, _rhCyan),
    const _ResourceCategory('Fighter Safety', Icons.sports_mma, _rhGold),
  ];

  final List<_Resource> _resources = [
    // ── Emergency & Crisis ──
    const _Resource(
      'Emergency Services',
      '000',
      'Police, Fire, Ambulance — life-threatening emergencies',
      'Emergency',
      Icons.emergency,
      _rhRed,
      true,
      'Australia-wide',
      '24/7',
    ),
    const _Resource(
      'Lifeline Australia',
      '13 11 14',
      'Crisis support & suicide prevention for anyone in distress',
      'Emergency',
      Icons.phone_in_talk,
      _rhPink,
      true,
      'Australia-wide',
      '24/7',
    ),
    const _Resource(
      'Beyond Blue',
      '1300 22 4636',
      'Anxiety, depression & mental health support',
      'Mental Health',
      Icons.psychology,
      _rhPurple,
      true,
      'Australia-wide',
      '24/7',
    ),
    const _Resource(
      'Crisis Text Line',
      'Text 0477 13 11 14',
      'Free text-based crisis counselling',
      'Emergency',
      Icons.sms,
      _rhCyan,
      true,
      'Australia-wide',
      '24/7',
    ),
    const _Resource(
      '13YARN',
      '13 92 76',
      'Aboriginal & Torres Strait Islander crisis support',
      'Emergency',
      Icons.diversity_3,
      _rhWarm,
      true,
      'Australia-wide',
      '24/7',
    ),

    // ── Homelessness & Shelter ──
    const _Resource(
      'Homeless Hotline QLD',
      '1800 474 753',
      'Emergency accommodation & housing referrals in Queensland',
      'Shelter',
      Icons.night_shelter,
      _rhWarm,
      true,
      'Queensland',
      '24/7',
    ),
    const _Resource(
      'National Homeless Line',
      '1800 152 152',
      'Connect to nearest shelter, housing & support services',
      'Shelter',
      Icons.home,
      _rhWarm,
      true,
      'Australia-wide',
      '24/7',
    ),
    const _Resource(
      'Mission Australia',
      '1800 88 88 68',
      'Emergency housing, meals, job support & community services',
      'Shelter',
      Icons.church,
      _rhGreen,
      true,
      'Australia-wide',
      'Mon-Fri 9am-5pm',
    ),
    const _Resource(
      'St Vincent de Paul (Vinnies)',
      '13 18 12',
      'Emergency assistance, food, clothing & shelter referrals',
      'Shelter',
      Icons.volunteer_activism,
      _rhBlue,
      true,
      'Australia-wide',
      'Mon-Fri 9am-5pm',
    ),
    const _Resource(
      'Salvation Army',
      '13 72 58',
      'Crisis accommodation, meals & family support',
      'Shelter',
      Icons.house,
      _rhRed,
      true,
      'Australia-wide',
      '24/7 crisis line',
    ),
    const _Resource(
      'Micah Projects (Brisbane)',
      '(07) 3029 7000',
      'Homelessness outreach, domestic violence & disability support',
      'Shelter',
      Icons.groups,
      _rhPurple,
      false,
      'Brisbane',
      'Mon-Fri 9am-5pm',
    ),

    // ── Mental Health ──
    const _Resource(
      'SANE Australia',
      '1800 187 263',
      'Complex mental health conditions & support for carers',
      'Mental Health',
      Icons.psychology,
      _rhPurple,
      true,
      'Australia-wide',
      'Mon-Fri 10am-10pm',
    ),
    const _Resource(
      'Head to Health',
      '1800 595 212',
      'Government mental health phone service & referrals',
      'Mental Health',
      Icons.health_and_safety,
      _rhBlue,
      true,
      'Australia-wide',
      '24/7',
    ),
    const _Resource(
      'MensLine Australia',
      '1300 78 99 78',
      'Mental health, relationship & family violence support for men',
      'Mental Health',
      Icons.man,
      _rhCyan,
      true,
      'Australia-wide',
      '24/7',
    ),
    const _Resource(
      'Headspace',
      '1800 650 890',
      'Mental health support for young people aged 12-25',
      'Mental Health',
      Icons.spa,
      _rhGreen,
      true,
      'Australia-wide',
      'Mon-Fri 9am-1am; Weekends 9am-midnight',
    ),
    const _Resource(
      'Black Dog Institute',
      'blackdoginstitute.org.au',
      'Evidence-based mental health resources & self-help tools',
      'Mental Health',
      Icons.school,
      _rhGold,
      false,
      'Online',
      '24/7 online',
    ),

    // ── Addiction & Recovery ──
    const _Resource(
      'Alcohol Drug Info Service',
      '1800 250 015',
      'Confidential advice, counselling & rehab referrals',
      'Addiction',
      Icons.healing,
      _rhPink,
      true,
      'Australia-wide',
      '24/7',
    ),
    const _Resource(
      'Narcotics Anonymous',
      '1300 652 820',
      'Peer support meetings for people recovering from drug addiction',
      'Addiction',
      Icons.groups,
      _rhGreen,
      true,
      'Australia-wide',
      '24/7',
    ),
    const _Resource(
      'Alcoholics Anonymous',
      '1300 222 222',
      'Peer support & meeting finder for alcohol recovery',
      'Addiction',
      Icons.group,
      _rhBlue,
      true,
      'Australia-wide',
      '24/7',
    ),
    const _Resource(
      'Gambling Help Online',
      '1800 858 858',
      'Counselling & support for problem gambling',
      'Addiction',
      Icons.casino,
      _rhGold,
      true,
      'Australia-wide',
      '24/7',
    ),
    const _Resource(
      'SMART Recovery',
      'smartrecoveryaustralia.com.au',
      'Science-based addiction recovery program & groups',
      'Addiction',
      Icons.auto_graph,
      _rhCyan,
      false,
      'Australia-wide',
      'Group schedule online',
    ),
    const _Resource(
      'DirectLine (VIC)',
      '1800 888 236',
      'Drug & alcohol counselling, referrals & needle exchange info',
      'Addiction',
      Icons.medical_services,
      _rhPurple,
      true,
      'Victoria',
      '24/7',
    ),

    // ── Domestic & Family Violence ──
    const _Resource(
      '1800RESPECT',
      '1800 737 732',
      'Sexual assault, domestic & family violence counselling',
      'Violence',
      Icons.shield,
      _rhRed,
      true,
      'Australia-wide',
      '24/7',
    ),
    const _Resource(
      'DV Connect (QLD)',
      '1800 811 811',
      'Domestic violence crisis support & safe accommodation for women',
      'Violence',
      Icons.security,
      _rhPink,
      true,
      'Queensland',
      '24/7',
    ),
    const _Resource(
      'DV Connect Mensline',
      '1800 600 636',
      'Support for men experiencing domestic violence',
      'Violence',
      Icons.man,
      _rhBlue,
      true,
      'Queensland',
      '9am-midnight',
    ),
    const _Resource(
      'Safe Steps (VIC)',
      '1800 015 188',
      'Family violence response centre — crisis & ongoing support',
      'Violence',
      Icons.home,
      _rhGreen,
      true,
      'Victoria',
      '24/7',
    ),

    // ── Food & Essentials ──
    const _Resource(
      'Foodbank Australia',
      '1800 268 233',
      'Emergency food hampers & pantry staples — no ID required',
      'Food',
      Icons.inventory_2,
      _rhGold,
      true,
      'Australia-wide',
      'Mon-Fri 9am-3pm',
    ),
    const _Resource(
      'OzHarvest',
      'ozharvest.org',
      'Free community meals & food rescue programs in major cities',
      'Food',
      Icons.restaurant,
      _rhWarm,
      false,
      'Major cities',
      'Various',
    ),
    const _Resource(
      'SecondBite',
      'secondbite.org',
      'Fresh food distribution to community food programs',
      'Food',
      Icons.local_dining,
      _rhGreen,
      false,
      'Australia-wide',
      'Mon-Fri',
    ),
    const _Resource(
      'Ask Izzy',
      'askizzy.org.au',
      'Find food, shelter, health, money help & more near you',
      'Food',
      Icons.search,
      _rhCyan,
      false,
      'Online',
      '24/7 online',
    ),

    // ── Disability Support ──
    const _Resource(
      'NDIS',
      '1800 800 110',
      'National Disability Insurance Scheme information & access',
      'Disability',
      Icons.accessible,
      _rhBlue,
      true,
      'Australia-wide',
      'Mon-Fri 8am-8pm',
    ),
    const _Resource(
      'Disability Gateway',
      '1800 643 787',
      'Information & referral service for people with disabilities',
      'Disability',
      Icons.accessibility_new,
      _rhCyan,
      true,
      'Australia-wide',
      'Mon-Fri 8am-8pm',
    ),
    const _Resource(
      'People with Disability Australia',
      '1800 422 015',
      'Individual advocacy & systemic advocacy for disability rights',
      'Disability',
      Icons.gavel,
      _rhPurple,
      true,
      'Australia-wide',
      'Mon-Fri 9am-5pm',
    ),
    const _Resource(
      'Vision Australia',
      '1300 84 74 66',
      'Support for people who are blind or have low vision',
      'Disability',
      Icons.visibility,
      _rhGold,
      true,
      'Australia-wide',
      'Mon-Fri 8:30am-5pm',
    ),

    // ── Youth & Children ──
    const _Resource(
      'Kids Helpline',
      '1800 55 1800',
      'Free counselling for young people aged 5-25',
      'Youth',
      Icons.child_care,
      _rhGreen,
      true,
      'Australia-wide',
      '24/7',
    ),
    const _Resource(
      'ReachOut',
      'reachout.com',
      'Online mental health service for young people & parents',
      'Youth',
      Icons.phone_android,
      _rhCyan,
      false,
      'Online',
      '24/7 online',
    ),
    const _Resource(
      'Parentline',
      '1300 30 1300',
      'Counselling & support for parents and carers',
      'Youth',
      Icons.family_restroom,
      _rhPurple,
      true,
      'Australia-wide',
      'Mon-Fri 8am-midnight; Weekends 10am-10pm',
    ),
    const _Resource(
      'Youth Beyond Blue',
      '1300 22 4636',
      'Mental health support specifically for young Australians',
      'Youth',
      Icons.school,
      _rhBlue,
      true,
      'Australia-wide',
      '24/7',
    ),

    // ── Veterans & First Responders ──
    const _Resource(
      'Open Arms',
      '1800 011 046',
      'Free counselling for veterans, ADF members & families',
      'Veterans',
      Icons.military_tech,
      _rhWarm,
      true,
      'Australia-wide',
      '24/7',
    ),
    const _Resource(
      'Police Citizens Youth Clubs',
      '(07) 3909 9700',
      'Youth programs & community support through QLD PCYC',
      'Veterans',
      Icons.local_police,
      _rhBlue,
      false,
      'Queensland',
      'Mon-Fri 9am-5pm',
    ),
    const _Resource(
      'Fortem',
      'fortemaustralia.org.au',
      'Mental health & wellbeing for first responders & families',
      'Veterans',
      Icons.local_fire_department,
      _rhRed,
      false,
      'Australia-wide',
      'Mon-Fri 9am-5pm',
    ),
    const _Resource(
      'RSL',
      '1300 775 753',
      'Veteran welfare, employment, housing & community services',
      'Veterans',
      Icons.flag,
      _rhGold,
      true,
      'Australia-wide',
      'Mon-Fri 9am-5pm',
    ),

    // ── Financial & Legal ──
    const _Resource(
      'National Debt Helpline',
      '1800 007 007',
      'Free financial counselling for people in financial difficulty',
      'Financial',
      Icons.account_balance,
      _rhCyan,
      true,
      'Australia-wide',
      'Mon-Fri 9:30am-4:30pm',
    ),
    const _Resource(
      'Legal Aid QLD',
      '1300 65 11 88',
      'Free legal advice for people who cannot afford a lawyer',
      'Financial',
      Icons.gavel,
      _rhGold,
      true,
      'Queensland',
      'Mon-Fri 9am-5pm',
    ),
    const _Resource(
      'Centrelink Crisis Payment',
      '132 850',
      'Immediate financial support in extreme circumstances',
      'Financial',
      Icons.payments,
      _rhGreen,
      true,
      'Australia-wide',
      'Mon-Fri 8am-5pm',
    ),
    const _Resource(
      'Good Shepherd Microfinance',
      '13 64 57',
      'No-interest loans for essential items & financial coaching',
      'Financial',
      Icons.savings,
      _rhWarm,
      true,
      'Australia-wide',
      'Mon-Fri 9am-5pm',
    ),

    // ── Fighter Safety ──
    const _Resource(
      'DFC Fighter Safety Line',
      '1300 DFC SAFE',
      'Report unsafe fight conditions, unlicensed events, or abuse',
      'Fighter Safety',
      Icons.sports_mma,
      _rhGold,
      true,
      'Australia-wide',
      '24/7',
    ),
    const _Resource(
      'Combat Sports Authority QLD',
      '(07) 3008 3497',
      'Report combat sports safety concerns & licensing issues',
      'Fighter Safety',
      Icons.verified_user,
      _rhCyan,
      false,
      'Queensland',
      'Mon-Fri 9am-5pm',
    ),
    const _Resource(
      'SportAUS Integrity',
      '1800 574 599',
      'Report match fixing, doping & athlete abuse in sport',
      'Fighter Safety',
      Icons.security,
      _rhRed,
      true,
      'Australia-wide',
      'Mon-Fri 9am-5pm',
    ),
    const _Resource(
      'Concussion Foundation',
      'concussionfoundation.com.au',
      'Brain injury awareness, CTE research & fighter health resources',
      'Fighter Safety',
      Icons.medical_information,
      _rhPurple,
      false,
      'Online',
      '24/7 online',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<_Resource> get _filteredResources {
    var results = _resources;
    if (_selectedCategory != 'All') {
      results = results.where((r) => r.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      results = results
          .where(
            (r) =>
                r.name.toLowerCase().contains(q) ||
                r.description.toLowerCase().contains(q) ||
                r.category.toLowerCase().contains(q) ||
                r.contact.toLowerCase().contains(q) ||
                r.coverage.toLowerCase().contains(q),
          )
          .toList();
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _rhBg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildHeroBanner()),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildCategoryChips()),
          SliverToBoxAdapter(child: _buildQuickDial()),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final resources = _filteredResources;
              if (index >= resources.length) return null;
              return _buildResourceCard(resources[index]);
            }, childCount: _filteredResources.length),
          ),
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
      backgroundColor: _rhBg.withValues(alpha: 0.95),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_rhCyan, _rhGreen]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.hub, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              'RESOURCE HUB',
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
      actions: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) {
            return IconButton(
              icon: Icon(
                Icons.emergency,
                color: _rhRed.withValues(alpha: _pulseAnim.value),
              ),
              onPressed: _showEmergencySheet,
            );
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // HERO BANNER
  // ═══════════════════════════════════════════
  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _rhCyan.withValues(alpha: 0.1),
            _rhGreen.withValues(alpha: 0.06),
            _rhPurple.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _rhCyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [_rhCyan, _rhGreen]),
              boxShadow: [
                BoxShadow(
                  color: _rhCyan.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.hub, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_rhCyan, _rhGreen, Colors.white],
            ).createShader(bounds),
            child: const Text(
              'COMMUNITY RESOURCE HUB',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help is always one call away\n${_resources.length} verified support services across Australia',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SEARCH
  // ═══════════════════════════════════════════
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: _rhCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _rhCyan.withValues(alpha: 0.15)),
        ),
        child: TextField(
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search services, locations, categories...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: Icon(
              Icons.search,
              color: _rhCyan.withValues(alpha: 0.5),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // CATEGORY CHIPS
  // ═══════════════════════════════════════════
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat.name;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat.name),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cat.color.withValues(alpha: 0.2)
                      : _rhCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? cat.color
                        : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.icon,
                      color: isSelected ? cat.color : Colors.white54,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.name,
                      style: TextStyle(
                        color: isSelected ? cat.color : Colors.white54,
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : FontWeight.w600,
                        letterSpacing: isSelected ? 0.5 : 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════
  // QUICK DIAL EMERGENCY ROW
  // ═══════════════════════════════════════════
  Widget _buildQuickDial() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _quickDialButton('000', 'EMERGENCY', _rhRed),
          const SizedBox(width: 8),
          _quickDialButton('13 11 14', 'LIFELINE', _rhPink),
          const SizedBox(width: 8),
          _quickDialButton('1300 22 4636', 'BEYOND BLUE', _rhPurple),
        ],
      ),
    );
  }

  Widget _quickDialButton(String number, String label, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: number.replaceAll(' ', '')));
          _showSnack('$number copied — call now');
        },
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withValues(alpha: 0.3 * _pulseAnim.value),
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.08 * _pulseAnim.value),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.phone, color: color, size: 18),
                  const SizedBox(height: 4),
                  Text(
                    number,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // RESOURCE CARD
  // ═══════════════════════════════════════════
  Widget _buildResourceCard(_Resource resource) {
    return GestureDetector(
      onTap: () => _showResourceDetail(resource),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _rhCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: resource.color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: resource.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(resource.icon, color: resource.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          resource.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (resource.isPhoneLine)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _rhGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'CALL',
                            style: TextStyle(
                              color: _rhGreen,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resource.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: resource.color.withValues(alpha: 0.4),
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        resource.coverage,
                        style: TextStyle(
                          color: resource.color.withValues(alpha: 0.6),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.schedule,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          resource.hours,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 9,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: resource.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: resource.color.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                resource.contact.length > 14
                    ? resource.contact.substring(0, 12)
                    : resource.contact,
                style: TextStyle(
                  color: resource.color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // FOOTER
  // ═══════════════════════════════════════════
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _rhCard.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _rhCyan.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            const Icon(Icons.favorite, color: _rhPink, size: 24),
            const SizedBox(height: 10),
            Text(
              'You are not alone. You matter.\nHelp is always one call away.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Powered by DFC Community · datafightcentral.com/resources',
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
  // DIALOGS
  // ═══════════════════════════════════════════
  void _showResourceDetail(_Resource resource) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF091420),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: resource.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(resource.icon, color: resource.color, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              resource.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: resource.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                resource.category.toUpperCase(),
                style: TextStyle(
                  color: resource.color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              resource.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Contact
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: resource.contact));
                Navigator.pop(context);
                _showSnack('${resource.contact} copied to clipboard');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      resource.color.withValues(alpha: 0.15),
                      resource.color.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: resource.color.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      resource.isPhoneLine ? Icons.phone : Icons.link,
                      color: resource.color,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      resource.contact,
                      style: TextStyle(
                        color: resource.color,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  resource.coverage,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.schedule,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  resource.hours,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to copy · You are not alone',
              style: TextStyle(
                color: _rhPink.withValues(alpha: 0.7),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEmergencySheet() {
    final emergencyResources = _resources
        .where((r) => r.category == 'Emergency')
        .toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF091420),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.emergency, color: _rhRed, size: 32),
            const SizedBox(height: 10),
            const Text(
              'EMERGENCY CONTACTS',
              style: TextStyle(
                color: _rhRed,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'If you are in immediate danger, call 000',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            ...emergencyResources.map(
              (r) => GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: r.contact));
                  Navigator.pop(context);
                  _showSnack('${r.contact} copied — call now');
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: r.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: r.color.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(r.icon, color: r.color, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              r.description,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [r.color, r.color.withValues(alpha: 0.7)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          r.contact,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _rhCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: _rhGreen, size: 18),
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

class _ResourceCategory {
  final String name;
  final IconData icon;
  final Color color;
  const _ResourceCategory(this.name, this.icon, this.color);
}

class _Resource {
  final String name;
  final String contact;
  final String description;
  final String category;
  final IconData icon;
  final Color color;
  final bool isPhoneLine;
  final String coverage;
  final String hours;
  const _Resource(
    this.name,
    this.contact,
    this.description,
    this.category,
    this.icon,
    this.color,
    this.isPhoneLine,
    this.coverage,
    this.hours,
  );
}
