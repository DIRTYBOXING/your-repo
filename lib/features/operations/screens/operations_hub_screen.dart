import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ═══════════════════════════════════════════════════════════════
/// DFC OPERATIONS HUB v1.0
/// "Buy a Coffee, Not a Coffin" — Business, Donations & Partnerships
///
/// Modules:
/// 1. Coffee Not Coffin Campaign — QR-powered donation drive
/// 2. Sponsored Retailers — Maccas, 7-Eleven, partner deals
/// 3. Payment & Donations Tracker — All money in/out
/// 4. Expense Manager — Business costs, receipts, budgets
/// 5. Email & Comms Bot — Automated outreach, inbox mgmt
/// 6. Office Bot — Paperwork, forms, compliance docs
/// 7. QR Code Generator — For sponsors, donations, merch
/// ═══════════════════════════════════════════════════════════════

const Color _opsOrange = Color(0xFFFF6B00);
const Color _opsGold = Color(0xFFFFD700);
const Color _opsCyan = Color(0xFF00F5FF);
const Color _opsGreen = Color(0xFF00FF88);
const Color _opsMagenta = Color(0xFFFF00FF);
const Color _opsBg = Color(0xFF050A14);
const Color _opsCard = Color(0xFF0D1B2A);

class OperationsHubScreen extends StatefulWidget {
  const OperationsHubScreen({super.key});

  @override
  State<OperationsHubScreen> createState() => _OperationsHubScreenState();
}

class _OperationsHubScreenState extends State<OperationsHubScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  // ── Coffee Not Coffin Campaign ──
  final double _totalDonations = 47832.50;
  final int _coffeesServed = 3241;
  final int _livesImpacted = 186;

  // ── Expenses ──
  final List<_ExpenseItem> _expenses = [
    _ExpenseItem(
      'Firebase Hosting',
      'Infrastructure',
      29.99,
      DateTime(2026, 3),
      true,
    ),
    _ExpenseItem(
      'Google Cloud API',
      'Infrastructure',
      48.50,
      DateTime(2026, 3),
      true,
    ),
    _ExpenseItem(
      'Apple Dev License',
      'Platform Fees',
      149.00,
      DateTime(2026, 2, 15),
      true,
    ),
    _ExpenseItem(
      'Google Play Console',
      'Platform Fees',
      25.00,
      DateTime(2026, 2, 15),
      true,
    ),
    _ExpenseItem(
      'Domain: datafightcentral.com',
      'Web',
      14.99,
      DateTime(2026, 2, 10),
      true,
    ),
    _ExpenseItem('Figma Pro', 'Design', 15.00, DateTime(2026, 3), false),
    _ExpenseItem('SendGrid Email', 'Comms', 19.95, DateTime(2026, 3), false),
    _ExpenseItem(
      'Stripe Fees (Feb)',
      'Payments',
      127.30,
      DateTime(2026, 3, 2),
      true,
    ),
    _ExpenseItem(
      'Insurance Premium',
      'Legal',
      450.00,
      DateTime(2026, 2, 20),
      true,
    ),
    _ExpenseItem(
      'Office Supplies',
      'Operations',
      87.20,
      DateTime(2026, 2, 25),
      true,
    ),
  ];

  // ── Sponsor Partners ──
  final List<_SponsorPartner> _sponsors = [
    const _SponsorPartner(
      "McDonald's 24hr",
      'Coffee Partner',
      '24hr coffee for athletes post-training',
      Icons.coffee,
      _opsOrange,
      true,
      'MACCAS-DFC-2026',
    ),
    const _SponsorPartner(
      '7-Eleven',
      'Hydration Partner',
      'Free Slurpee for event attendees',
      Icons.local_drink,
      Color(0xFF00875A),
      true,
      '7ELEVEN-DFC',
    ),
    const _SponsorPartner(
      'Red Bull',
      'Energy Partner',
      'Ring-walk energy sponsorship',
      Icons.bolt,
      Color(0xFF1E3264),
      false,
      null,
    ),
    const _SponsorPartner(
      'Guzman y Gomez',
      'Nutrition Partner',
      'Post-fight recovery meals',
      Icons.restaurant,
      _opsGold,
      true,
      'GYG-DFC-2026',
    ),
    const _SponsorPartner(
      'Rebel Sport',
      'Equipment Partner',
      'Discount gear for DFC fighters',
      Icons.sports_mma,
      Color(0xFFFF0000),
      false,
      null,
    ),
    const _SponsorPartner(
      'Chemist Warehouse',
      'Health Partner',
      'First aid & supplements',
      Icons.local_pharmacy,
      Color(0xFF00B140),
      true,
      'CW-DFC-HEALTH',
    ),
    const _SponsorPartner(
      'Uber Eats',
      'Delivery Partner',
      'Post-event meal delivery codes',
      Icons.delivery_dining,
      _opsGreen,
      false,
      null,
    ),
    const _SponsorPartner(
      'Boost Juice',
      'Recovery Partner',
      'Fighter smoothie sponsorship',
      Icons.blender,
      Color(0xFFFF6B9D),
      true,
      'BOOST-DFC',
    ),
  ];

  // ── Email Templates ──
  final List<_EmailTemplate> _emailTemplates = [
    const _EmailTemplate(
      'Sponsor Outreach',
      'Partnership proposal for potential sponsors',
      Icons.handshake,
      _opsGold,
    ),
    const _EmailTemplate(
      'Donation Thank You',
      'Auto-reply to donors with impact report',
      Icons.favorite,
      _opsGreen,
    ),
    const _EmailTemplate(
      'Event Invitation',
      'Invite VIPs/media to DFC events',
      Icons.event,
      _opsCyan,
    ),
    const _EmailTemplate(
      'Fighter Welcome',
      'Onboarding email for new fighters',
      Icons.sports_mma,
      _opsOrange,
    ),
    const _EmailTemplate(
      'Expense Report',
      'Monthly expense summary for stakeholders',
      Icons.receipt_long,
      _opsMagenta,
    ),
    const _EmailTemplate(
      'Safety Update',
      'Quarterly safety protocol updates',
      Icons.health_and_safety,
      _opsGreen,
    ),
    const _EmailTemplate(
      'Grant Application',
      'Google/Meta/AWS grant proposals',
      Icons.description,
      _opsCyan,
    ),
    const _EmailTemplate(
      'Media Kit',
      'Press release & brand assets package',
      Icons.campaign,
      _opsGold,
    ),
  ];

  // ── Office Bot Tasks ──
  final List<_OfficeBotTask> _botTasks = [
    const _OfficeBotTask(
      'Process Donations',
      'Auto-reconcile Stripe donations',
      Icons.monetization_on,
      _opsGreen,
      true,
      '2 min ago',
    ),
    const _OfficeBotTask(
      'Sort Inbox',
      'Categorize 47 unread emails',
      Icons.mail,
      _opsCyan,
      true,
      '5 min ago',
    ),
    const _OfficeBotTask(
      'Generate Receipts',
      'Create Feb tax receipts',
      Icons.receipt,
      _opsGold,
      false,
      'Pending',
    ),
    const _OfficeBotTask(
      'Compliance Check',
      'Review event insurance docs',
      Icons.gavel,
      _opsOrange,
      false,
      'Scheduled',
    ),
    const _OfficeBotTask(
      'Expense Report',
      'Compile March expense summary',
      Icons.analytics,
      _opsMagenta,
      true,
      '1 hr ago',
    ),
    const _OfficeBotTask(
      'QR Code Batch',
      'Generate sponsor QR pack',
      Icons.qr_code_2,
      _opsCyan,
      false,
      'Queued',
    ),
    const _OfficeBotTask(
      'Social Scheduler',
      'Queue 12 posts for the week',
      Icons.schedule,
      _opsOrange,
      true,
      '30 min ago',
    ),
    const _OfficeBotTask(
      'Invoice Sponsors',
      'Send monthly partner invoices',
      Icons.request_quote,
      _opsGold,
      false,
      'Due Mar 10',
    ),
  ];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _opsBg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildHeroSection()),
          SliverToBoxAdapter(child: _buildTabBar()),
          SliverToBoxAdapter(child: _buildTabContent()),
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
      backgroundColor: _opsBg.withValues(alpha: 0.95),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_opsOrange, _opsGold]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.business_center,
              color: Colors.black,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'DFC OPS HUB',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_active, color: _opsGold),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.smart_toy, color: _opsCyan),
          onPressed: _showBotDialog,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // HERO — "BUY A COFFEE, NOT A COFFIN"
  // ═══════════════════════════════════════════
  Widget _buildHeroSection() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _opsOrange.withValues(alpha: 0.15 * _pulseAnim.value),
                _opsGold.withValues(alpha: 0.1),
                _opsGreen.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _opsOrange.withValues(alpha: 0.3 * _pulseAnim.value),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _opsOrange.withValues(alpha: 0.15 * _pulseAnim.value),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Coffee cup icon with glow
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [_opsOrange, _opsGold]),
                  boxShadow: [
                    BoxShadow(
                      color: _opsOrange.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.coffee, color: Colors.black, size: 36),
              ),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [_opsOrange, _opsGold, Colors.white],
                ).createShader(bounds),
                child: const Text(
                  'BUY A COFFEE',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [_opsGreen, _opsCyan],
                ).createShader(bounds),
                child: const Text(
                  'NOT A COFFIN',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Every coffee funds fighter safety protocols',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _heroStat(
                    '\$${_totalDonations.toStringAsFixed(0)}',
                    'RAISED',
                    _opsGold,
                  ),
                  _heroStat('$_coffeesServed', 'COFFEES', _opsOrange),
                  _heroStat('$_livesImpacted', 'LIVES', _opsGreen),
                ],
              ),
              const SizedBox(height: 20),

              // CTA Buttons
              Row(
                children: [
                  Expanded(
                    child: _heroButton(
                      'DONATE NOW',
                      Icons.favorite,
                      _opsOrange,
                      _showDonationSheet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _heroButton(
                      'SCAN QR',
                      Icons.qr_code_scanner,
                      _opsCyan,
                      _showQRScanner,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Hope Cards CTA
              SizedBox(
                width: double.infinity,
                child: _heroButton(
                  '❤️ HOPE CARDS — NO ONE SUFFERS ALONE',
                  Icons.card_giftcard,
                  const Color(0xFFFF6B9D),
                  () => context.push('/hope-cards'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _heroStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _heroButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TAB BAR
  // ═══════════════════════════════════════════
  Widget _buildTabBar() {
    final tabs = [
      const _TabItem(Icons.coffee, 'COFFEE'),
      const _TabItem(Icons.storefront, 'SPONSORS'),
      const _TabItem(Icons.account_balance_wallet, 'EXPENSES'),
      const _TabItem(Icons.mail, 'EMAIL'),
      const _TabItem(Icons.smart_toy, 'BOTS'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: _opsOrange,
        indicatorWeight: 3,
        labelColor: _opsOrange,
        unselectedLabelColor: Colors.white54,
        tabAlignment: TabAlignment.start,
        tabs: tabs
            .map(
              (t) => Tab(
                child: Row(
                  children: [
                    Icon(t.icon, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      t.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
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

  // ═══════════════════════════════════════════
  // TAB CONTENT
  // ═══════════════════════════════════════════
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildCoffeeTab();
      case 1:
        return _buildSponsorsTab();
      case 2:
        return _buildExpensesTab();
      case 3:
        return _buildEmailTab();
      case 4:
        return _buildBotsTab();
      default:
        return _buildCoffeeTab();
    }
  }

  // ──────────────────────────────────────────
  // TAB 1: COFFEE NOT COFFIN CAMPAIGN
  // ──────────────────────────────────────────
  Widget _buildCoffeeTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('CAMPAIGN DASHBOARD', Icons.campaign, _opsOrange),
          const SizedBox(height: 12),

          // QR Code Cards
          _buildQRCard(
            'DONATION QR',
            'Scan to donate — funds fighter medical checks, insurance & safety gear',
            Icons.qr_code_2,
            _opsGold,
            'https://datafightcentral.com/donate',
          ),
          const SizedBox(height: 12),
          _buildQRCard(
            'MERCH QR',
            '"Buy a Coffee Not a Coffin" T-shirts, mugs & hoodies',
            Icons.shopping_bag,
            _opsOrange,
            'https://datafightcentral.com/merch',
          ),
          const SizedBox(height: 12),
          _buildQRCard(
            'EVENT SPONSOR QR',
            'Businesses scan to become event sponsors instantly',
            Icons.handshake,
            _opsCyan,
            'https://datafightcentral.com/sponsor',
          ),
          const SizedBox(height: 20),

          _sectionHeader('DONATION TIERS', Icons.star, _opsGold),
          const SizedBox(height: 12),

          _donationTier(
            'ESPRESSO',
            '\$5',
            'Funds one fighter safety briefing',
            Icons.coffee,
            _opsOrange,
          ),
          _donationTier(
            'FLAT WHITE',
            '\$25',
            'Pays for one medical check',
            Icons.local_cafe,
            _opsGold,
          ),
          _donationTier(
            'COLD BREW',
            '\$50',
            'Covers ringside first-aid kit',
            Icons.icecream,
            _opsCyan,
          ),
          _donationTier(
            'BARISTA BLEND',
            '\$100',
            'Full fighter safety pack',
            Icons.emoji_food_beverage,
            _opsGreen,
          ),
          _donationTier(
            'GOLD ROAST',
            '\$500',
            'Event safety sponsorship',
            Icons.workspace_premium,
            _opsMagenta,
          ),

          const SizedBox(height: 20),
          _sectionHeader('RECENT DONATIONS', Icons.history, _opsGreen),
          const SizedBox(height: 12),

          ..._buildRecentDonations(),
        ],
      ),
    );
  }

  Widget _buildQRCard(
    String title,
    String desc,
    IconData icon,
    Color color,
    String url,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _opsCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(Icons.qr_code_2, color: color, size: 40),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  url,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.share, color: color.withValues(alpha: 0.7)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _donationTier(
    String name,
    String price,
    String desc,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _opsCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      price,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecentDonations() {
    final donations = [
      ('Anonymous Fighter', '\$50', '2 hrs ago', _opsCyan),
      ('DFC HQ', '\$250', '5 hrs ago', _opsGold),
      ('Sarah M.', '\$25', '1 day ago', _opsGreen),
      ('Coach Rodriguez', '\$100', '2 days ago', _opsOrange),
      ('DFC Community Fund', '\$500', '3 days ago', _opsMagenta),
    ];

    return donations
        .map(
          (d) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _opsCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: d.$4.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: d.$4.withValues(alpha: 0.15),
                  child: Icon(Icons.person, color: d.$4, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.$1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        d.$3,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  d.$2,
                  style: TextStyle(
                    color: d.$4,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  // ──────────────────────────────────────────
  // TAB 2: SPONSORED RETAILERS
  // ──────────────────────────────────────────
  Widget _buildSponsorsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('SPONSOR PARTNERS', Icons.storefront, _opsGold),
          const SizedBox(height: 8),
          Text(
            'QR-powered partner deals for fighters, fans & event attendees',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),

          // Active sponsors count
          Row(
            children: [
              _sponsorStat(
                '${_sponsors.where((s) => s.isActive).length}',
                'ACTIVE',
                _opsGreen,
              ),
              const SizedBox(width: 12),
              _sponsorStat(
                '${_sponsors.where((s) => !s.isActive).length}',
                'PENDING',
                _opsOrange,
              ),
              const SizedBox(width: 12),
              _sponsorStat('${_sponsors.length}', 'TOTAL', _opsCyan),
            ],
          ),
          const SizedBox(height: 20),

          // Sponsor cards
          ..._sponsors.map(_buildSponsorCard),

          const SizedBox(height: 20),
          // Add new sponsor button
          GestureDetector(
            onTap: _showAddSponsorSheet,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _opsCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _opsOrange.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, color: _opsOrange, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'ADD NEW SPONSOR PARTNER',
                    style: TextStyle(
                      color: _opsOrange,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
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

  Widget _sponsorStat(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSponsorCard(_SponsorPartner sponsor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _opsCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sponsor.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sponsor.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(sponsor.icon, color: sponsor.color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      sponsor.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: sponsor.isActive
                            ? _opsGreen.withValues(alpha: 0.15)
                            : _opsOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sponsor.isActive ? 'ACTIVE' : 'PENDING',
                        style: TextStyle(
                          color: sponsor.isActive ? _opsGreen : _opsOrange,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  sponsor.tier,
                  style: TextStyle(
                    color: sponsor.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sponsor.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
                if (sponsor.qrCode != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.qr_code,
                        color: sponsor.color.withValues(alpha: 0.5),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sponsor.qrCode!,
                        style: TextStyle(
                          color: sponsor.color.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: Icon(
                  Icons.qr_code_2,
                  color: sponsor.color.withValues(alpha: 0.7),
                  size: 22,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 18,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // TAB 3: EXPENSE TRACKER
  // ──────────────────────────────────────────
  Widget _buildExpensesTab() {
    final totalExpenses = _expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final paidExpenses = _expenses
        .where((e) => e.isPaid)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final unpaidExpenses = totalExpenses - paidExpenses;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'EXPENSE DASHBOARD',
            Icons.account_balance_wallet,
            _opsMagenta,
          ),
          const SizedBox(height: 16),

          // Summary cards
          Row(
            children: [
              _expenseSummary(
                'TOTAL',
                '\$${totalExpenses.toStringAsFixed(2)}',
                _opsCyan,
              ),
              const SizedBox(width: 10),
              _expenseSummary(
                'PAID',
                '\$${paidExpenses.toStringAsFixed(2)}',
                _opsGreen,
              ),
              const SizedBox(width: 10),
              _expenseSummary(
                'UNPAID',
                '\$${unpaidExpenses.toStringAsFixed(2)}',
                _opsOrange,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Category breakdown
          _sectionHeader('BY CATEGORY', Icons.pie_chart, _opsCyan),
          const SizedBox(height: 12),
          _buildCategoryBreakdown(),
          const SizedBox(height: 20),

          // Expense list
          _sectionHeader('ALL EXPENSES', Icons.receipt_long, _opsGold),
          const SizedBox(height: 12),
          ..._expenses.map(_buildExpenseItem),

          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showAddExpenseSheet,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _opsCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _opsMagenta.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle, color: _opsMagenta, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'ADD EXPENSE',
                    style: TextStyle(
                      color: _opsMagenta,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
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

  Widget _expenseSummary(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final categories = <String, double>{};
    for (final e in _expenses) {
      categories[e.category] = (categories[e.category] ?? 0) + e.amount;
    }

    final colors = [
      _opsOrange,
      _opsCyan,
      _opsGold,
      _opsGreen,
      _opsMagenta,
      Colors.purple,
    ];
    int colorIdx = 0;

    return Column(
      children: categories.entries.map((entry) {
        final color = colors[colorIdx % colors.length];
        colorIdx++;
        final percentage =
            (entry.value /
            _expenses.fold<double>(0, (sum, e) => sum + e.amount) *
            100);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '\$${entry.value.toStringAsFixed(0)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExpenseItem(_ExpenseItem expense) {
    final categoryColors = {
      'Infrastructure': _opsCyan,
      'Platform Fees': _opsOrange,
      'Web': _opsGold,
      'Design': _opsMagenta,
      'Comms': _opsGreen,
      'Payments': _opsOrange,
      'Legal': Colors.redAccent,
      'Operations': _opsCyan,
    };
    final color = categoryColors[expense.category] ?? _opsCyan;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _opsCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              expense.isPaid ? Icons.check_circle : Icons.schedule,
              color: expense.isPaid ? _opsGreen : _opsOrange,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        expense.category,
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${expense.date.day}/${expense.date.month}/${expense.date.year}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '\$${expense.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: expense.isPaid ? Colors.white : _opsOrange,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // TAB 4: EMAIL & COMMS
  // ──────────────────────────────────────────
  Widget _buildEmailTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('EMAIL COMMAND CENTER', Icons.mail, _opsCyan),
          const SizedBox(height: 8),
          Text(
            'Auto-generate & send professional emails for DFC operations',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),

          // Email stats
          Row(
            children: [
              _emailStat('47', 'UNREAD', Icons.mark_email_unread, _opsOrange),
              const SizedBox(width: 10),
              _emailStat('312', 'SENT', Icons.send, _opsGreen),
              const SizedBox(width: 10),
              _emailStat('89%', 'OPEN RATE', Icons.visibility, _opsCyan),
            ],
          ),
          const SizedBox(height: 20),

          _sectionHeader('QUICK TEMPLATES', Icons.description, _opsGold),
          const SizedBox(height: 12),

          ..._emailTemplates.map(_buildEmailTemplateCard),

          const SizedBox(height: 16),

          // Compose button
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_opsCyan, _opsCyan.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _opsCyan.withValues(alpha: 0.2),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit, color: Colors.black, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'COMPOSE NEW EMAIL',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Key contacts
          _sectionHeader('KEY CONTACTS', Icons.contacts, _opsGreen),
          const SizedBox(height: 12),
          _contactCard(
            'support@datafightcentral.com',
            'Main Support',
            Icons.headset_mic,
            _opsCyan,
          ),
          _contactCard(
            'sponsors@datafightcentral.com',
            'Sponsor Enquiries',
            Icons.handshake,
            _opsGold,
          ),
          _contactCard(
            'safety@datafightcentral.com',
            'Safety Reports',
            Icons.health_and_safety,
            _opsGreen,
          ),
          _contactCard(
            'media@datafightcentral.com',
            'Press & Media',
            Icons.campaign,
            _opsMagenta,
          ),
          _contactCard(
            'legal@datafightcentral.com',
            'Legal & Compliance',
            Icons.gavel,
            _opsOrange,
          ),
        ],
      ),
    );
  }

  Widget _emailStat(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailTemplateCard(_EmailTemplate template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _opsCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: template.color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: template.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(template.icon, color: template.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  template.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: template.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'USE',
              style: TextStyle(
                color: template.color,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCard(String email, String role, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _opsCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.content_copy,
            color: Colors.white.withValues(alpha: 0.3),
            size: 18,
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // TAB 5: OFFICE & PAYMENT BOTS
  // ──────────────────────────────────────────
  Widget _buildBotsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('DFC OFFICE BOTS', Icons.smart_toy, _opsCyan),
          const SizedBox(height: 8),
          Text(
            'Automated assistants handling paperwork, payments & operations 24/7',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),

          // Bot fleet overview
          Row(
            children: [
              _botOverview('PAPERWORK', Icons.description, _opsGold),
              const SizedBox(width: 10),
              _botOverview('PAYMENT', Icons.payment, _opsGreen),
              const SizedBox(width: 10),
              _botOverview('OFFICE', Icons.business, _opsCyan),
            ],
          ),
          const SizedBox(height: 20),

          _sectionHeader('BOT TASK QUEUE', Icons.playlist_play, _opsOrange),
          const SizedBox(height: 12),

          ..._botTasks.map(_buildBotTaskCard),

          const SizedBox(height: 20),

          // Payment Bot section
          _sectionHeader('PAYMENT BOT', Icons.payment, _opsGreen),
          const SizedBox(height: 12),

          _paymentBotCard(
            'Stripe Connect',
            'Process donations & sponsor payments',
            Icons.credit_card,
            _opsGreen,
            true,
          ),
          _paymentBotCard(
            'PayPal Business',
            'International donor payments',
            Icons.account_balance,
            _opsCyan,
            true,
          ),
          _paymentBotCard(
            'Bank Transfer',
            'Westpac BSB 032-586 Acc 596038',
            Icons.account_balance_wallet,
            _opsGold,
            true,
          ),
          _paymentBotCard(
            'Crypto Wallet',
            'BTC/ETH donations (coming soon)',
            Icons.currency_bitcoin,
            _opsOrange,
            false,
          ),

          const SizedBox(height: 20),

          // Paperwork Bot section
          _sectionHeader('PAPERWORK BOT', Icons.description, _opsGold),
          const SizedBox(height: 12),

          _paperworkCard(
            'Fighter Waivers',
            '47 active',
            Icons.assignment,
            _opsOrange,
            98,
          ),
          _paperworkCard(
            'Event Insurance',
            '12 policies',
            Icons.security,
            _opsGreen,
            100,
          ),
          _paperworkCard(
            'Sponsor Contracts',
            '8 active',
            Icons.handshake,
            _opsGold,
            85,
          ),
          _paperworkCard(
            'Tax Documents',
            'FY 2025-26',
            Icons.receipt_long,
            _opsCyan,
            72,
          ),
          _paperworkCard(
            'Safety Audits',
            'Monthly review',
            Icons.health_and_safety,
            _opsMagenta,
            91,
          ),
        ],
      ),
    );
  }

  Widget _botOverview(String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _opsGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'ONLINE',
                style: TextStyle(
                  color: _opsGreen,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotTaskCard(_OfficeBotTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _opsCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: task.color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: task.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(task.icon, color: task.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (task.isComplete ? _opsGreen : _opsOrange).withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.isComplete ? 'DONE' : 'PENDING',
                  style: TextStyle(
                    color: task.isComplete ? _opsGreen : _opsOrange,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                task.timestamp,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentBotCard(
    String name,
    String desc,
    IconData icon,
    Color color,
    bool active,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _opsCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: active ? 0.2 : 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
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
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (active ? _opsGreen : Colors.white24).withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (active ? _opsGreen : Colors.white24).withValues(
                  alpha: 0.2,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active ? Icons.check_circle : Icons.schedule,
                  color: active ? _opsGreen : Colors.white38,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  active ? 'LIVE' : 'SOON',
                  style: TextStyle(
                    color: active ? _opsGreen : Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paperworkCard(
    String name,
    String status,
    IconData icon,
    Color color,
    int completion,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _opsCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: completion / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$completion%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════
  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
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
    );
  }

  // ═══════════════════════════════════════════
  // DIALOGS & SHEETS
  // ═══════════════════════════════════════════
  void _showDonationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _opsCard,
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
            const Text(
              'BUY A COFFEE, NOT A COFFIN',
              style: TextStyle(
                color: _opsGold,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Every dollar protects a fighter',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _donateChip('\$5', _opsOrange),
                _donateChip('\$25', _opsGold),
                _donateChip('\$50', _opsCyan),
                _donateChip('\$100', _opsGreen),
                _donateChip('\$500', _opsMagenta),
                _donateChip('Custom', Colors.white54),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_opsOrange, _opsGold]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'DONATE NOW',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'Secured by Stripe | Tax deductible receipt sent automatically',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _donateChip(String amount, Color color) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          amount,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _showQRScanner() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _opsCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: _opsCyan),
            SizedBox(width: 10),
            Text(
              'QR SCANNER',
              style: TextStyle(color: _opsCyan, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _opsCyan.withValues(alpha: 0.3)),
              ),
              child: const Center(
                child: Icon(Icons.camera_alt, color: _opsCyan, size: 48),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Point camera at sponsor/donation QR code',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: _opsCyan)),
          ),
        ],
      ),
    );
  }

  void _showBotDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _opsCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.smart_toy, color: _opsCyan),
            SizedBox(width: 10),
            Text(
              'DFC BOT STATUS',
              style: TextStyle(
                color: _opsCyan,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _botStatusRow('Paperwork Bot', _opsGold, true),
            _botStatusRow('Payment Bot', _opsGreen, true),
            _botStatusRow('Office Bot', _opsCyan, true),
            _botStatusRow('Email Bot', _opsMagenta, true),
            _botStatusRow('QR Generator', _opsOrange, true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: _opsCyan)),
          ),
        ],
      ),
    );
  }

  Widget _botStatusRow(String name, Color color, bool online) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.smart_toy, color: color, size: 18),
          const SizedBox(width: 10),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: online ? _opsGreen : Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (online ? _opsGreen : Colors.red).withValues(
                    alpha: 0.5,
                  ),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            online ? 'ONLINE' : 'OFFLINE',
            style: TextStyle(
              color: online ? _opsGreen : Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSponsorSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _opsCard,
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
            const Text(
              'ADD SPONSOR PARTNER',
              style: TextStyle(
                color: _opsGold,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            _sheetTextField('Business Name', Icons.business),
            const SizedBox(height: 12),
            _sheetTextField('Contact Email', Icons.email),
            const SizedBox(height: 12),
            _sheetTextField('Partnership Type', Icons.category),
            const SizedBox(height: 12),
            _sheetTextField('Proposed Deal', Icons.description),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_opsGold, _opsOrange]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'SEND PROPOSAL',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _opsCard,
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
            const Text(
              'ADD EXPENSE',
              style: TextStyle(
                color: _opsMagenta,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            _sheetTextField('Expense Name', Icons.label),
            const SizedBox(height: 12),
            _sheetTextField('Amount (\$)', Icons.attach_money),
            const SizedBox(height: 12),
            _sheetTextField('Category', Icons.category),
            const SizedBox(height: 12),
            _sheetTextField('Receipt / Notes', Icons.note),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_opsMagenta, _opsMagenta.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'LOG EXPENSE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sheetTextField(String hint, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _opsBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.white38, size: 20),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════
class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem(this.icon, this.label);
}

class _ExpenseItem {
  final String name;
  final String category;
  final double amount;
  final DateTime date;
  final bool isPaid;
  const _ExpenseItem(
    this.name,
    this.category,
    this.amount,
    this.date,
    this.isPaid,
  );
}

class _SponsorPartner {
  final String name;
  final String tier;
  final String description;
  final IconData icon;
  final Color color;
  final bool isActive;
  final String? qrCode;
  const _SponsorPartner(
    this.name,
    this.tier,
    this.description,
    this.icon,
    this.color,
    this.isActive,
    this.qrCode,
  );
}

class _EmailTemplate {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  const _EmailTemplate(this.name, this.description, this.icon, this.color);
}

class _OfficeBotTask {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isComplete;
  final String timestamp;
  const _OfficeBotTask(
    this.name,
    this.description,
    this.icon,
    this.color,
    this.isComplete,
    this.timestamp,
  );
}
