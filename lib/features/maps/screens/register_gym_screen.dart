import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/image_assets.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';

// ═════════════════════════════════════════════════════════════════════════════
// REGISTER YOUR GYM — DFC GYM FINDER ONBOARDING
// ═════════════════════════════════════════════════════════════════════════════
// Simple, clean, premium. Gym owner fills in details → logo → sports → done.
// Their pin appears on the DFC Satellite Map.
// ═════════════════════════════════════════════════════════════════════════════

class RegisterGymScreen extends StatefulWidget {
  const RegisterGymScreen({super.key});

  @override
  State<RegisterGymScreen> createState() => _RegisterGymScreenState();
}

class _RegisterGymScreenState extends State<RegisterGymScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // ── Form fields ──
  final _gymNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _logoUrlCtrl = TextEditingController();
  final _taglineCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();
  final _memberCountCtrl = TextEditingController();
  void _goBackSafely() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }

  final List<String> _selectedSports = [];
  String _selectedTier = 'Community';
  bool _isVictimSafe = false;
  bool _submitted = false;

  late AnimationController _pulseCtrl;
  late AnimationController _successCtrl;

  static const _allSports = [
    'MMA',
    'Boxing',
    'BJJ',
    'Muay Thai',
    'Wrestling',
    'Kickboxing',
    'Judo',
    'Karate',
    'Taekwondo',
    'Capoeira',
    'Sambo',
    'Krav Maga',
  ];

  static const _tierOptions = [
    'Community',
    'Bronze',
    'Silver',
    'Gold',
    'Platinum',
    'Diamond',
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
    _gymNameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _websiteCtrl.dispose();
    _logoUrlCtrl.dispose();
    _taglineCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactEmailCtrl.dispose();
    _memberCountCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: _buildAppBar(),
      body: _submitted ? _buildSuccessView() : _buildFormView(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // APP BAR
  // ─────────────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryBackground,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        color: AppTheme.neonCyan,
        onPressed: () {
          if (_submitted || _currentStep == 0) {
            _goBackSafely();
          } else {
            setState(() => _currentStep--);
          }
        },
      ),
      title: Column(
        children: [
          Text(
            _submitted ? 'REGISTRATION COMPLETE' : 'REGISTER YOUR GYM',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: AppTheme.neonCyan,
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
                    AppTheme.neonCyan.withValues(
                      alpha: (0.6 + _pulseCtrl.value * 0.4).clamp(0.0, 1.0),
                    ),
                  ),
                  minHeight: 3,
                ),
              ),
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FORM VIEW
  // ─────────────────────────────────────────────────────────────────────────
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
        return _buildStep1GymDetails();
      case 1:
        return _buildStep2LogoBranding();
      case 2:
        return _buildStep3Sports();
      case 3:
        return _buildStep4Review();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1: GYM DETAILS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep1GymDetails() {
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'GYM DETAILS',
              Icons.store_mall_directory,
              'Tell us about your gym',
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _gymNameCtrl,
              label: 'GYM NAME',
              hint: 'e.g. Iron Warrior MMA',
              icon: Icons.fitness_center,
              required: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressCtrl,
              label: 'STREET ADDRESS',
              hint: 'e.g. 123 Main St',
              icon: Icons.location_on,
              required: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _cityCtrl,
                    label: 'CITY',
                    hint: 'e.g. Brisbane',
                    icon: Icons.location_city,
                    required: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _countryCtrl,
                    label: 'COUNTRY',
                    hint: 'e.g. Australia',
                    icon: Icons.public,
                    required: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _taglineCtrl,
              label: 'TAGLINE',
              hint: 'e.g. Where Champions Are Made',
              icon: Icons.format_quote,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _websiteCtrl,
              label: 'WEBSITE',
              hint: 'https://yourgym.com',
              icon: Icons.language,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _memberCountCtrl,
              label: 'ACTIVE MEMBERS',
              hint: 'Approximate number',
              icon: Icons.groups,
              keyboardType: TextInputType.number,
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
              label: 'CONTACT EMAIL',
              hint: 'you@yourgym.com',
              icon: Icons.email,
              required: true,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 2: LOGO & BRANDING
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep2LogoBranding() {
    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'LOGO & BRANDING',
            Icons.image,
            'Your logo will appear on the satellite map',
          ),
          const SizedBox(height: 24),

          // Logo URL input
          _buildTextField(
            controller: _logoUrlCtrl,
            label: 'LOGO URL',
            hint: 'https://yourgym.com/logo.png',
            icon: Icons.link,
          ),
          const SizedBox(height: 16),

          // Logo preview
          Center(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, _) {
                final hasLogo = _logoUrlCtrl.text.trim().isNotEmpty;
                return Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryBackground,
                    border: Border.all(
                      color: hasLogo
                          ? AppTheme.neonCyan.withValues(
                              alpha: (0.4 + _pulseCtrl.value * 0.4).clamp(
                                0.0,
                                1.0,
                              ),
                            )
                          : Colors.white.withValues(alpha: 0.1),
                      width: 3,
                    ),
                    boxShadow: hasLogo
                        ? [
                            BoxShadow(
                              color: AppTheme.neonCyan.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasLogo
                      ? (ImageAssets.isLocalAsset(_logoUrlCtrl.text.trim())
                            ? Image.asset(
                                _logoUrlCtrl.text.trim(),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _buildLogoPlaceholder(),
                              )
                            : DfcNetworkImage(
                                url: _logoUrlCtrl.text.trim(),
                              ))
                      : _buildLogoPlaceholder(),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _logoUrlCtrl.text.trim().isNotEmpty
                  ? 'YOUR MAP PIN PREVIEW'
                  : 'PASTE YOUR LOGO URL ABOVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: _logoUrlCtrl.text.trim().isNotEmpty
                    ? AppTheme.neonCyan.withValues(alpha: 0.7)
                    : AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Tier selection
          _buildSectionSubHeader('DFC PARTNERSHIP TIER'),
          const SizedBox(height: 12),
          _buildTierSelector(),
          const SizedBox(height: 24),

          // Victim Safe toggle
          _buildToggleOption(
            icon: '💗',
            title: 'PINK DIAMOND SAFE SPACE',
            subtitle:
                'Certify as a victim-safe training environment. Support DFC\'s Pink Diamond initiative.',
            value: _isVictimSafe,
            color: Colors.pinkAccent,
            onChanged: (v) => setState(() => _isVictimSafe = v),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 3: SPORTS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep3Sports() {
    return SingleChildScrollView(
      key: const ValueKey('step3'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'COMBAT SPORTS',
            Icons.sports_mma,
            'Select all disciplines offered',
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
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
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.neonCyan.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.neonCyan.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.08),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.neonCyan.withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: AppTheme.neonCyan,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        sport,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.neonCyan
                              : AppTheme.textSecondary,
                          letterSpacing: isSelected ? 1 : 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedSports.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.neonCyan.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.neonCyan.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_mma, size: 18, color: AppTheme.neonCyan),
                  const SizedBox(width: 10),
                  Text(
                    '${_selectedSports.length} SPORT${_selectedSports.length != 1 ? 'S' : ''} SELECTED',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: AppTheme.neonCyan,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 4: REVIEW & SUBMIT
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep4Review() {
    return SingleChildScrollView(
      key: const ValueKey('step4'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'REVIEW',
            Icons.preview,
            'Confirm your gym details before submitting',
          ),
          const SizedBox(height: 20),

          // Mini preview card
          _buildPreviewCard(),
          const SizedBox(height: 24),

          // Details breakdown
          _buildReviewRow('Gym Name', _gymNameCtrl.text),
          _buildReviewRow(
            'Location',
            '${_addressCtrl.text}, ${_cityCtrl.text}, ${_countryCtrl.text}',
          ),
          if (_taglineCtrl.text.isNotEmpty)
            _buildReviewRow('Tagline', _taglineCtrl.text),
          if (_websiteCtrl.text.isNotEmpty)
            _buildReviewRow('Website', _websiteCtrl.text),
          if (_memberCountCtrl.text.isNotEmpty)
            _buildReviewRow('Members', _memberCountCtrl.text),
          _buildReviewRow('Contact', _contactNameCtrl.text),
          _buildReviewRow('Email', _contactEmailCtrl.text),
          _buildReviewRow('Sports', _selectedSports.join(', ')),
          _buildReviewRow('Tier', _selectedTier),
          if (_isVictimSafe)
            _buildReviewRow('Safe Space', '💗 Pink Diamond Certified'),
          const SizedBox(height: 24),

          // Terms notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.neonPurple.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.neonPurple.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.neonPurple.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'By submitting, you confirm you are an authorized representative of this gym. '
                    'DFC will verify your details before your pin goes live on the satellite map.',
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
  // PREVIEW CARD (Map Pin mockup)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPreviewCard() {
    final hasLogo = _logoUrlCtrl.text.trim().isNotEmpty;
    final tierColor = _getTierColor(_selectedTier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tierColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: tierColor.withValues(alpha: 0.1), blurRadius: 20),
        ],
      ),
      child: Row(
        children: [
          // Pin preview
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryBackground,
              border: Border.all(color: tierColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: tierColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: hasLogo
                ? (ImageAssets.isLocalAsset(_logoUrlCtrl.text.trim())
                      ? Image.asset(
                          _logoUrlCtrl.text.trim(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildMiniInitials(),
                        )
                      : DfcNetworkImage(
                          url: _logoUrlCtrl.text.trim(),
                        ))
                : _buildMiniInitials(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _gymNameCtrl.text.isNotEmpty ? _gymNameCtrl.text : 'Your Gym',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_cityCtrl.text.isNotEmpty ? _cityCtrl.text : 'City'}, '
                  '${_countryCtrl.text.isNotEmpty ? _countryCtrl.text : 'Country'}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: tierColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _selectedTier.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: tierColor,
                        ),
                      ),
                    ),
                    if (_isVictimSafe) ...[
                      const SizedBox(width: 8),
                      const Text('💗', style: TextStyle(fontSize: 14)),
                    ],
                    if (_selectedSports.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '🥊 ${_selectedSports.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInitials() {
    final text = _gymNameCtrl.text.trim();
    String initials = 'GYM';
    if (text.isNotEmpty) {
      final parts = text.split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = text.substring(0, text.length.clamp(0, 2)).toUpperCase();
      }
    }
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: AppTheme.neonCyan.withValues(alpha: 0.6),
          letterSpacing: 2,
        ),
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
            // Animated check
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, _) => Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonGreen.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.neonGreen.withValues(
                      alpha: (0.4 + _pulseCtrl.value * 0.4).clamp(0.0, 1.0),
                    ),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonGreen.withValues(alpha: 0.3),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Icon(Icons.check, size: 48, color: AppColors.neonGreen),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'GYM REGISTERED',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your gym is now in the DFC verification queue.\n'
              'Once approved, your pin will go live on the satellite map.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ESTIMATED REVIEW: 24 – 48 HOURS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppTheme.neonCyan.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 40),

            // What's included
            _buildSuccessFeature(
              Icons.location_on,
              'SATELLITE MAP PIN',
              'Your logo on the DFC satellite map',
            ),
            const SizedBox(height: 12),
            _buildSuccessFeature(
              Icons.verified,
              'DFC VERIFIED BADGE',
              'Verified partner badge on your listing',
            ),
            const SizedBox(height: 12),
            _buildSuccessFeature(
              Icons.trending_up,
              'NETWORK EXPOSURE',
              'Visible to the entire DFC fighter community',
            ),
            const SizedBox(height: 40),

            // Back to Map button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonCyan.withValues(alpha: 0.15),
                  foregroundColor: AppTheme.neonCyan,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: AppTheme.neonCyan.withValues(alpha: 0.4),
                    ),
                  ),
                  elevation: 0,
                ),
                onPressed: () => context.pop(),
                child: const Text(
                  'BACK TO GYM FINDER',
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
          Icon(icon, size: 20, color: AppTheme.neonCyan.withValues(alpha: 0.7)),
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
                    color: AppTheme.neonCyan.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
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
                    : AppTheme.neonCyan.withValues(alpha: 0.15),
                foregroundColor: isLast
                    ? AppColors.neonGreen
                    : AppTheme.neonCyan,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isLast
                        ? AppColors.neonGreen.withValues(alpha: 0.4)
                        : AppTheme.neonCyan.withValues(alpha: 0.4),
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

  // ─────────────────────────────────────────────────────────────────────────
  // NAVIGATION LOGIC
  // ─────────────────────────────────────────────────────────────────────────
  void _handleNext() {
    if (_currentStep == 0) {
      // Validate required fields
      if (_gymNameCtrl.text.trim().isEmpty ||
          _addressCtrl.text.trim().isEmpty ||
          _cityCtrl.text.trim().isEmpty ||
          _countryCtrl.text.trim().isEmpty ||
          _contactNameCtrl.text.trim().isEmpty ||
          _contactEmailCtrl.text.trim().isEmpty) {
        _showValidationSnackbar('Please fill in all required fields');
        return;
      }
    }
    if (_currentStep == 2 && _selectedSports.isEmpty) {
      _showValidationSnackbar('Select at least one sport');
      return;
    }
    if (_currentStep == 3) {
      _submitRegistration();
      return;
    }
    setState(() => _currentStep++);
  }

  void _showValidationSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFFF4757),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _submitRegistration() {
    // Firestore 'gym_registrations' write pending service wiring
    // Show success state for demo
    _successCtrl.forward();
    setState(() => _submitted = true);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHARED WIDGETS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.neonCyan),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white,
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

  Widget _buildSectionSubHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: AppTheme.neonCyan,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: AppTheme.neonCyan.withValues(alpha: 0.8),
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
            if (label == 'LOGO URL' || label == 'GYM NAME') {
              setState(() {});
            }
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
              color: AppTheme.neonCyan.withValues(alpha: 0.5),
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
                color: AppTheme.neonCyan.withValues(alpha: 0.5),
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

  Widget _buildTierSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tierOptions.map((tier) {
        final isSelected = _selectedTier == tier;
        final color = _getTierColor(tier);
        return GestureDetector(
          onTap: () => setState(() => _selectedTier = tier),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? color.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.08),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ]
                  : [],
            ),
            child: Text(
              tier.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 1.5,
                color: isSelected ? color : AppTheme.textMuted,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToggleOption({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: value
              ? color.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value
                ? color.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: value ? color : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: color,
              activeTrackColor: color.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 40,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 4),
          Text(
            'LOGO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
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
        return AppTheme.neonCyan;
    }
  }
}
