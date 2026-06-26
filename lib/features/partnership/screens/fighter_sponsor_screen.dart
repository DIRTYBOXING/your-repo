import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/image_assets.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';

// ═════════════════════════════════════════════════════════════════════════════
// FIGHTER SPONSOR — DFC PARTNERSHIP ONBOARDING
// ═════════════════════════════════════════════════════════════════════════════
// Brands and businesses sponsor individual fighters or teams.
// Premium placement on profiles, fight cards, walkout content,
// and the DFC satellite map.
// ═════════════════════════════════════════════════════════════════════════════

class FighterSponsorScreen extends StatefulWidget {
  const FighterSponsorScreen({super.key});

  @override
  State<FighterSponsorScreen> createState() => _FighterSponsorScreenState();
}

class _FighterSponsorScreenState extends State<FighterSponsorScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // ── Form fields ──
  final _companyNameCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _logoUrlCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  String _selectedTier = 'Silver';
  String _sponsorType = 'Individual Fighter';
  final List<String> _selectedSports = [];
  bool _submitted = false;

  late AnimationController _pulseCtrl;
  late AnimationController _successCtrl;

  static const _tierOptions = [
    {'name': 'Bronze', 'price': '\$99/mo', 'desc': 'Logo on 1 fighter profile'},
    {
      'name': 'Silver',
      'price': '\$249/mo',
      'desc': 'Profile + fight card branding',
    },
    {'name': 'Gold', 'price': '\$499/mo', 'desc': 'Full brand suite + map pin'},
    {
      'name': 'Platinum',
      'price': '\$999/mo',
      'desc': 'Team sponsorship + analytics',
    },
    {
      'name': 'Diamond',
      'price': 'Custom',
      'desc': 'Enterprise-level partnership',
    },
  ];

  static const _sponsorTypes = [
    'Individual Fighter',
    'Fight Team',
    'Event Sponsor',
    'Multi-Fighter',
  ];

  static const _allSports = [
    'MMA',
    'Boxing',
    'BJJ',
    'Muay Thai',
    'Wrestling',
    'Kickboxing',
    'Judo',
    'Karate',
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _successCtrl.dispose();
    _companyNameCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactEmailCtrl.dispose();
    _websiteCtrl.dispose();
    _logoUrlCtrl.dispose();
    _budgetCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: _buildAppBar(),
      body: _submitted ? _buildSuccessView() : _buildFormView(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryBackground,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        color: AppColors.neonAmber,
        onPressed: () {
          if (_submitted || _currentStep == 0) {
            context.pop();
          } else {
            setState(() => _currentStep--);
          }
        },
      ),
      title: Column(
        children: [
          Text(
            _submitted ? 'APPLICATION SENT' : 'FIGHTER SPONSOR',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: AppColors.neonAmber,
            ),
          ),
          if (!_submitted)
            Text(
              'STEP ${_currentStep + 1} OF 4',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: AppTheme.textMuted,
              ),
            ),
        ],
      ),
      centerTitle: true,
      bottom: _submitted
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, _) => LinearProgressIndicator(
                  value: (_currentStep + 1) / 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.neonAmber.withValues(
                      alpha: (0.6 + _pulseCtrl.value * 0.4).clamp(0.0, 1.0),
                    ),
                  ),
                  minHeight: 3,
                ),
              ),
            ),
    );
  }

  Widget _buildFormView() {
    return Column(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStepContent(),
          ),
        ),
        _buildNavigationBar(),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1CompanyDetails();
      case 1:
        return _buildStep2SponsorshipType();
      case 2:
        return _buildStep3TierSelection();
      case 3:
        return _buildStep4Review();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1: COMPANY DETAILS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep1CompanyDetails() {
    return SingleChildScrollView(
      key: const ValueKey('sponsor_step1'),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'YOUR BRAND',
              Icons.business,
              'Tell us about your company or brand',
              AppColors.neonAmber,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _companyNameCtrl,
              label: 'COMPANY / BRAND NAME',
              hint: 'e.g. Iron Supplements Co.',
              icon: Icons.business,
              required: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _contactNameCtrl,
              label: 'CONTACT NAME',
              hint: 'Your name',
              icon: Icons.person,
              required: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _contactEmailCtrl,
              label: 'EMAIL',
              hint: 'you@company.com',
              icon: Icons.email,
              required: true,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _websiteCtrl,
              label: 'WEBSITE',
              hint: 'https://yourcompany.com',
              icon: Icons.language,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _logoUrlCtrl,
              label: 'BRAND LOGO URL',
              hint: 'https://yourcompany.com/logo.png',
              icon: Icons.image,
            ),
            const SizedBox(height: 16),

            // Logo preview
            if (_logoUrlCtrl.text.trim().isNotEmpty)
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withValues(alpha: 0.03),
                    border: Border.all(
                      color: AppColors.neonAmber.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonAmber.withValues(alpha: 0.15),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ImageAssets.isLocalAsset(_logoUrlCtrl.text.trim())
                      ? Image.asset(
                          _logoUrlCtrl.text.trim(),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: AppTheme.textMuted,
                              size: 32,
                            ),
                          ),
                        )
                      : DfcNetworkImage(
                          url: _logoUrlCtrl.text.trim(),
                          fit: BoxFit.contain,
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 2: SPONSORSHIP TYPE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep2SponsorshipType() {
    return SingleChildScrollView(
      key: const ValueKey('sponsor_step2'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'SPONSORSHIP TYPE',
            Icons.military_tech,
            'How do you want to sponsor?',
            AppColors.neonAmber,
          ),
          const SizedBox(height: 24),

          // Sponsor type selector
          ...List.generate(_sponsorTypes.length, (i) {
            final type = _sponsorTypes[i];
            final isSelected = _sponsorType == type;
            final icons = [
              Icons.person,
              Icons.groups,
              Icons.event,
              Icons.diversity_3,
            ];
            final descs = [
              'Sponsor a single fighter — your logo on their profile, fight card, and walkout.',
              'Back an entire fight team for maximum brand coverage across multiple athletes.',
              'Headline sponsor for DFC-listed events. Your brand on all promotional material.',
              'Sponsor 3-5 fighters across different weight classes and sports for broad reach.',
            ];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _sponsorType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isSelected
                        ? AppColors.neonAmber.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.02),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.neonAmber.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.06),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.neonAmber.withValues(alpha: 0.1),
                              blurRadius: 12,
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected
                              ? AppColors.neonAmber.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.03),
                        ),
                        child: Icon(
                          icons[i],
                          size: 20,
                          color: isSelected
                              ? AppColors.neonAmber
                              : AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: isSelected
                                    ? AppColors.neonAmber
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              descs[i],
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.neonAmber,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Preferred sports
          _buildSectionHeader(
            'PREFERRED SPORTS',
            Icons.sports_mma,
            'Which disciplines interest you?',
            AppColors.neonAmber,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allSports.map((sport) {
              final isSelected = _selectedSports.contains(sport);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSports.remove(sport);
                    } else {
                      _selectedSports.add(sport);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.neonAmber.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.neonAmber.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    sport,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.neonAmber
                          : AppTheme.textMuted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Budget
          _buildTextField(
            controller: _budgetCtrl,
            label: 'MONTHLY BUDGET (OPTIONAL)',
            hint: 'e.g. \$500',
            icon: Icons.attach_money,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 3: TIER SELECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep3TierSelection() {
    return SingleChildScrollView(
      key: const ValueKey('sponsor_step3'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'SPONSOR TIER',
            Icons.workspace_premium,
            'Choose your sponsorship level',
            AppColors.neonAmber,
          ),
          const SizedBox(height: 24),
          ...List.generate(_tierOptions.length, (i) {
            final tier = _tierOptions[i];
            final name = tier['name']!;
            final isSelected = _selectedTier == name;
            final color = _getTierColor(name);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _selectedTier = name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isSelected
                        ? color.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.02),
                    border: Border.all(
                      color: isSelected
                          ? color.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.06),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.15),
                              blurRadius: 16,
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.15),
                          border: Border.all(
                            color: color.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Icon(
                          Icons.military_tech,
                          size: 22,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    color: isSelected
                                        ? color
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  tier['price']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? color
                                        : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tier['desc']!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // Message to DFC
          _buildTextField(
            controller: _messageCtrl,
            label: 'MESSAGE TO DFC (OPTIONAL)',
            hint: 'Anything else we should know about your goals...',
            icon: Icons.message,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 4: REVIEW
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep4Review() {
    final tierColor = _getTierColor(_selectedTier);
    return SingleChildScrollView(
      key: const ValueKey('sponsor_step4'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'REVIEW APPLICATION',
            Icons.preview,
            'Confirm your sponsorship details',
            AppColors.neonAmber,
          ),
          const SizedBox(height: 20),

          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [tierColor.withValues(alpha: 0.08), Colors.transparent],
              ),
              border: Border.all(color: tierColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tierColor.withValues(alpha: 0.15),
                    border: Border.all(color: tierColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: tierColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: _logoUrlCtrl.text.trim().isNotEmpty
                      ? ClipOval(
                          child:
                              ImageAssets.isLocalAsset(_logoUrlCtrl.text.trim())
                              ? Image.asset(
                                  _logoUrlCtrl.text.trim(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Icon(
                                    Icons.military_tech,
                                    color: tierColor,
                                    size: 26,
                                  ),
                                )
                              : DfcNetworkImage(
                                  url: _logoUrlCtrl.text.trim(),
                                ),
                        )
                      : Icon(Icons.military_tech, color: tierColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _companyNameCtrl.text.isNotEmpty
                            ? _companyNameCtrl.text
                            : 'Your Brand',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: tierColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: tierColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '${_selectedTier.toUpperCase()} SPONSOR',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: tierColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _sponsorType,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildReviewRow('Company', _companyNameCtrl.text),
          _buildReviewRow('Contact', _contactNameCtrl.text),
          _buildReviewRow('Email', _contactEmailCtrl.text),
          if (_websiteCtrl.text.isNotEmpty)
            _buildReviewRow('Website', _websiteCtrl.text),
          _buildReviewRow('Type', _sponsorType),
          _buildReviewRow('Tier', _selectedTier),
          if (_selectedSports.isNotEmpty)
            _buildReviewRow('Sports', _selectedSports.join(', ')),
          if (_budgetCtrl.text.isNotEmpty)
            _buildReviewRow('Budget', _budgetCtrl.text),
          if (_messageCtrl.text.isNotEmpty)
            _buildReviewRow('Message', _messageCtrl.text),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.neonAmber.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.neonAmber.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.neonAmber.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'DFC will review your application and connect you with suitable fighters or '
                    'teams within 48 hours. Sponsorship billing starts only after mutual agreement.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUCCESS VIEW
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, _) => Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonAmber.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.neonAmber.withValues(
                      alpha: (0.4 + _pulseCtrl.value * 0.4).clamp(0.0, 1.0),
                    ),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonAmber.withValues(alpha: 0.3),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.military_tech,
                  size: 48,
                  color: AppColors.neonAmber,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'APPLICATION SENT',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your fighter sponsorship application is being reviewed.\n'
              'We\'ll match you with the right athletes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'RESPONSE TIME: 24 – 48 HOURS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppColors.neonAmber.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 40),
            _buildSuccessFeature(
              Icons.person_pin,
              'FIGHTER MATCHING',
              'We\'ll match your brand with compatible athletes',
            ),
            const SizedBox(height: 12),
            _buildSuccessFeature(
              Icons.satellite_alt,
              'MAP PRESENCE',
              'Your brand pin on the DFC satellite map',
            ),
            const SizedBox(height: 12),
            _buildSuccessFeature(
              Icons.analytics,
              'ROI DASHBOARD',
              'Track impressions, engagement & conversions',
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonAmber.withValues(alpha: 0.15),
                  foregroundColor: AppColors.neonAmber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: AppColors.neonAmber.withValues(alpha: 0.4),
                    ),
                  ),
                  elevation: 0,
                ),
                onPressed: () => context.pop(),
                child: const Text(
                  'BACK TO PARTNERSHIPS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessFeature(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.neonAmber.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: AppColors.neonAmber.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOTTOM NAVIGATION BAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildNavigationBar() {
    final isLast = _currentStep == 3;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.primaryBackground,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: () => setState(() => _currentStep--),
              child: const Text(
                'BACK',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          const Spacer(),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isLast
                    ? AppColors.neonGreen.withValues(alpha: 0.2)
                    : AppColors.neonAmber.withValues(alpha: 0.15),
                foregroundColor: isLast
                    ? AppColors.neonGreen
                    : AppColors.neonAmber,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isLast
                        ? AppColors.neonGreen.withValues(alpha: 0.4)
                        : AppColors.neonAmber.withValues(alpha: 0.4),
                  ),
                ),
                elevation: 0,
              ),
              onPressed: _handleNext,
              child: Text(
                isLast ? 'SUBMIT' : 'NEXT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: isLast ? 2 : 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() {
    if (_currentStep == 0) {
      if (_companyNameCtrl.text.trim().isEmpty ||
          _contactNameCtrl.text.trim().isEmpty ||
          _contactEmailCtrl.text.trim().isEmpty) {
        _showSnackbar('Please fill in all required fields');
        return;
      }
    }
    if (_currentStep == 3) {
      _submitApplication();
      return;
    }
    setState(() => _currentStep++);
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFFF4757),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submitApplication() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await FirebaseFirestore.instance.collection('sponsor_applications').add({
        'userId': uid,
        'companyName': _companyNameCtrl.text.trim(),
        'contactName': _contactNameCtrl.text.trim(),
        'contactEmail': _contactEmailCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'logoUrl': _logoUrlCtrl.text.trim(),
        'budget': _budgetCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'selectedTier': _selectedTier,
        'sponsorType': _sponsorType,
        'selectedSports': _selectedSports,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });
      _successCtrl.forward();
      setState(() => _submitted = true);
    } catch (e) {
      _showSnackbar('Submission failed: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHARED WIDGETS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(
    String title,
    IconData icon,
    String subtitle,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppTheme.textMuted,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(fontSize: 10, color: Color(0xFFFF4757)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: Colors.white),
          onChanged: (_) {
            if (label.contains('LOGO')) setState(() {});
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 13,
            ),
            prefixIcon: Icon(
              icon,
              size: 18,
              color: AppColors.neonAmber.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.neonAmber.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'platinum':
        return const Color(0xFFE040FB);
      case 'diamond':
        return const Color(0xFF00E5FF);
      default:
        return AppColors.neonAmber;
    }
  }
}
