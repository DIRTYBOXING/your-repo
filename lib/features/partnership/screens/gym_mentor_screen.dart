import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/image_assets.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';

// ═════════════════════════════════════════════════════════════════════════════
// GYM MENTOR — DFC PINK DIAMOND CERTIFICATION
// ═════════════════════════════════════════════════════════════════════════════
// Certified mentors who train and support athletes through the Pink Diamond
// initiative — domestic violence recovery, youth development, and victim-safe
// training environments. Premium map presence + community trust badges.
// ═════════════════════════════════════════════════════════════════════════════

class GymMentorScreen extends StatefulWidget {
  const GymMentorScreen({super.key});

  @override
  State<GymMentorScreen> createState() => _GymMentorScreenState();
}

class _GymMentorScreenState extends State<GymMentorScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // ── Form fields ──
  final _fullNameCtrl = TextEditingController();
  final _gymNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _motivationCtrl = TextEditingController();
  final _certCtrl = TextEditingController();
  final _profileUrlCtrl = TextEditingController();

  String _mentorTier = 'Gold Diamond';
  final List<String> _selectedPrograms = [];
  final List<String> _selectedSports = [];
  bool _hasWorkingWithChildren = false;
  bool _hasMentalHealthTraining = false;
  bool _hasFirstAid = false;
  bool _submitted = false;

  late AnimationController _pulseCtrl;
  late AnimationController _successCtrl;

  static const _mentorTiers = [
    {
      'name': 'Gold Diamond',
      'desc': 'Standard mentor — community trust badge & map listing',
      'icon': '💛',
    },
    {
      'name': 'Pink Diamond',
      'desc': 'DV recovery specialist — Pink Diamond safe space certification',
      'icon': '💗',
    },
    {
      'name': 'Black Diamond',
      'desc': 'Elite mentor — multi-program leadership & featured profile',
      'icon': '🖤',
    },
  ];

  static const _programs = [
    'Youth Development',
    'DV Recovery Support',
    'Mental Health & Resilience',
    'Women\'s Self Defense',
    'Rehabilitation Training',
    'Community Outreach',
    'At-Risk Youth Mentoring',
    'Veteran Support',
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
    'Krav Maga',
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
    _fullNameCtrl.dispose();
    _gymNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _experienceCtrl.dispose();
    _motivationCtrl.dispose();
    _certCtrl.dispose();
    _profileUrlCtrl.dispose();
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
        color: Colors.pinkAccent,
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
            _submitted ? 'APPLICATION SENT' : 'GYM MENTOR',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: Colors.pinkAccent,
            ),
          ),
          if (!_submitted)
            Text(
              'STEP ${_currentStep + 1} OF 5',
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
                  value: (_currentStep + 1) / 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.pinkAccent.withValues(
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
        return _buildStep1PersonalDetails();
      case 1:
        return _buildStep2Experience();
      case 2:
        return _buildStep3Programs();
      case 3:
        return _buildStep4MentorTier();
      case 4:
        return _buildStep5Review();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1: PERSONAL DETAILS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep1PersonalDetails() {
    return SingleChildScrollView(
      key: const ValueKey('mentor_step1'),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'ABOUT YOU',
              Icons.person,
              'Tell us who you are',
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _fullNameCtrl,
              label: 'FULL NAME',
              hint: 'Your full name',
              icon: Icons.person,
              required: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _gymNameCtrl,
              label: 'GYM / ORGANIZATION',
              hint: 'Where do you train or mentor?',
              icon: Icons.store_mall_directory,
              required: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailCtrl,
              label: 'EMAIL',
              hint: 'you@email.com',
              icon: Icons.email,
              required: true,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneCtrl,
              label: 'PHONE (OPTIONAL)',
              hint: '+61 400 000 000',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _locationCtrl,
              label: 'LOCATION',
              hint: 'City, Country',
              icon: Icons.location_on,
              required: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _profileUrlCtrl,
              label: 'PROFILE PHOTO URL (OPTIONAL)',
              hint: 'https://yourphoto.com/photo.jpg',
              icon: Icons.camera_alt,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 2: EXPERIENCE & QUALIFICATIONS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep2Experience() {
    return SingleChildScrollView(
      key: const ValueKey('mentor_step2'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'EXPERIENCE',
            Icons.workspace_premium,
            'Your qualifications and background',
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _experienceCtrl,
            label: 'MENTORING EXPERIENCE',
            hint:
                'Describe your experience as a mentor, coach, or community leader...',
            icon: Icons.history_edu,
            required: true,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _certCtrl,
            label: 'CERTIFICATIONS',
            hint:
                'Any relevant certifications (coaching, first aid, mental health, etc.)',
            icon: Icons.verified,
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // Combat sports
          _buildSectionHeader(
            'COMBAT SPORTS',
            Icons.sports_mma,
            'Which disciplines do you coach?',
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
                        ? Colors.pinkAccent.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? Colors.pinkAccent.withValues(alpha: 0.5)
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
                          ? Colors.pinkAccent
                          : AppTheme.textMuted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Credentials checkboxes
          _buildSectionHeader(
            'CREDENTIALS',
            Icons.shield,
            'Important background checks',
          ),
          const SizedBox(height: 16),
          _buildCheckItem(
            'Working With Children Check',
            'Required for youth programs',
            _hasWorkingWithChildren,
            (v) => setState(() => _hasWorkingWithChildren = v),
          ),
          const SizedBox(height: 10),
          _buildCheckItem(
            'Mental Health First Aid Training',
            'Recommended for all mentors',
            _hasMentalHealthTraining,
            (v) => setState(() => _hasMentalHealthTraining = v),
          ),
          const SizedBox(height: 10),
          _buildCheckItem(
            'First Aid / CPR Certification',
            'Recommended for all mentors',
            _hasFirstAid,
            (v) => setState(() => _hasFirstAid = v),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 3: PROGRAMS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep3Programs() {
    return SingleChildScrollView(
      key: const ValueKey('mentor_step3'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'PROGRAMS',
            Icons.volunteer_activism,
            'Which programs will you support?',
          ),
          const SizedBox(height: 24),
          ...List.generate(_programs.length, (i) {
            final prog = _programs[i];
            final isSelected = _selectedPrograms.contains(prog);
            final icons = [
              Icons.child_care,
              Icons.healing,
              Icons.psychology,
              Icons.shield_moon,
              Icons.accessibility_new,
              Icons.diversity_3,
              Icons.emoji_people,
              Icons.military_tech,
            ];

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedPrograms.remove(prog);
                    } else {
                      _selectedPrograms.add(prog);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isSelected
                        ? Colors.pinkAccent.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.02),
                    border: Border.all(
                      color: isSelected
                          ? Colors.pinkAccent.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.06),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icons[i],
                        size: 22,
                        color: isSelected
                            ? Colors.pinkAccent
                            : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          prog,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.pinkAccent
                                : AppTheme.textSecondary,
                            letterSpacing: isSelected ? 0.5 : 0,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.pinkAccent,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          if (_selectedPrograms.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.pinkAccent.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.volunteer_activism,
                    size: 18,
                    color: Colors.pinkAccent,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${_selectedPrograms.length} PROGRAM${_selectedPrograms.length != 1 ? 'S' : ''} SELECTED',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: Colors.pinkAccent,
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
  // STEP 4: MENTOR TIER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep4MentorTier() {
    return SingleChildScrollView(
      key: const ValueKey('mentor_step4'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'MENTOR TIER',
            Icons.diamond,
            'Choose your certification level',
          ),
          const SizedBox(height: 24),
          ...List.generate(_mentorTiers.length, (i) {
            final tier = _mentorTiers[i];
            final name = tier['name']!;
            final isSelected = _mentorTier == name;
            final color = _getMentorColor(name);

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GestureDetector(
                onTap: () => setState(() => _mentorTier = name),
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, _) => Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isSelected
                          ? color.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.02),
                      border: Border.all(
                        color: isSelected
                            ? color.withValues(
                                alpha: (0.3 + _pulseCtrl.value * 0.3).clamp(
                                  0.0,
                                  1.0,
                                ),
                              )
                            : Colors.white.withValues(alpha: 0.06),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.15),
                                blurRadius: 20,
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Text(
                          tier['icon']!,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: isSelected
                                      ? color
                                      : AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tier['desc']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: color, size: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Motivation
          _buildTextField(
            controller: _motivationCtrl,
            label: 'WHY DO YOU WANT TO MENTOR?',
            hint: 'Share your motivation and what drives you to help others...',
            icon: Icons.favorite,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 5: REVIEW
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStep5Review() {
    final tierColor = _getMentorColor(_mentorTier);
    return SingleChildScrollView(
      key: const ValueKey('mentor_step5'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'REVIEW APPLICATION',
            Icons.preview,
            'Confirm your mentor details',
          ),
          const SizedBox(height: 20),

          // Profile card
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
                  child: _profileUrlCtrl.text.trim().isNotEmpty
                      ? ClipOval(
                          child:
                              ImageAssets.isLocalAsset(
                                _profileUrlCtrl.text.trim(),
                              )
                              ? Image.asset(
                                  _profileUrlCtrl.text.trim(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Icon(
                                    Icons.shield,
                                    color: tierColor,
                                    size: 26,
                                  ),
                                )
                              : DfcNetworkImage(
                                  url: _profileUrlCtrl.text.trim(),
                                ),
                        )
                      : Icon(Icons.shield, color: tierColor, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fullNameCtrl.text.isNotEmpty
                            ? _fullNameCtrl.text
                            : 'Your Name',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _gymNameCtrl.text.isNotEmpty
                            ? _gymNameCtrl.text
                            : 'Your Gym',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
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
                          '${_mentorTier.toUpperCase()} MENTOR',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: tierColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildReviewRow('Name', _fullNameCtrl.text),
          _buildReviewRow('Gym', _gymNameCtrl.text),
          _buildReviewRow('Email', _emailCtrl.text),
          if (_phoneCtrl.text.isNotEmpty)
            _buildReviewRow('Phone', _phoneCtrl.text),
          _buildReviewRow('Location', _locationCtrl.text),
          _buildReviewRow('Tier', _mentorTier),
          if (_selectedSports.isNotEmpty)
            _buildReviewRow('Sports', _selectedSports.join(', ')),
          if (_selectedPrograms.isNotEmpty)
            _buildReviewRow('Programs', _selectedPrograms.join(', ')),

          // Credentials
          if (_hasWorkingWithChildren ||
              _hasMentalHealthTraining ||
              _hasFirstAid) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (_hasWorkingWithChildren)
                  _buildCredBadge('WWC Check', Icons.child_care),
                if (_hasMentalHealthTraining)
                  _buildCredBadge('Mental Health', Icons.psychology),
                if (_hasFirstAid)
                  _buildCredBadge('First Aid', Icons.medical_services),
              ],
            ),
            const SizedBox(height: 16),
          ],

          if (_motivationCtrl.text.isNotEmpty) ...[
            _buildReviewRow('Motivation', _motivationCtrl.text),
          ],

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.pinkAccent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.pinkAccent.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.pinkAccent.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'DFC will review your credentials and may request a brief video call '
                    'to verify your background. Approved mentors receive a certified badge '
                    'and premium satellite map presence.',
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

  Widget _buildCredBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.neonGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.neonGreen.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppColors.neonGreen.withValues(alpha: 0.8),
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
                  color: Colors.pinkAccent.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.pinkAccent.withValues(
                      alpha: (0.4 + _pulseCtrl.value * 0.4).clamp(0.0, 1.0),
                    ),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pinkAccent.withValues(alpha: 0.3),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield,
                  size: 48,
                  color: Colors.pinkAccent,
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
              'Your mentor application is being reviewed.\n'
              'We\'ll verify your credentials and get back to you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'VERIFICATION: 3 – 5 BUSINESS DAYS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Colors.pinkAccent.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 40),
            _buildSuccessFeature(
              Icons.verified,
              'CERTIFIED BADGE',
              'DFC-verified mentor badge on your profile',
            ),
            const SizedBox(height: 12),
            _buildSuccessFeature(
              Icons.satellite_alt,
              'MAP PRESENCE',
              'Premium mentor pin on the satellite map',
            ),
            const SizedBox(height: 12),
            _buildSuccessFeature(
              Icons.favorite,
              'COMMUNITY TRUST',
              'Graduates connected to your safe space',
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent.withValues(alpha: 0.15),
                  foregroundColor: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: Colors.pinkAccent.withValues(alpha: 0.4),
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
          Icon(icon, size: 20, color: Colors.pinkAccent.withValues(alpha: 0.7)),
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
                    color: Colors.pinkAccent.withValues(alpha: 0.8),
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
    final isLast = _currentStep == 4;
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
                    : Colors.pinkAccent.withValues(alpha: 0.15),
                foregroundColor: isLast
                    ? AppColors.neonGreen
                    : Colors.pinkAccent,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isLast
                        ? AppColors.neonGreen.withValues(alpha: 0.4)
                        : Colors.pinkAccent.withValues(alpha: 0.4),
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
      if (_fullNameCtrl.text.trim().isEmpty ||
          _gymNameCtrl.text.trim().isEmpty ||
          _emailCtrl.text.trim().isEmpty ||
          _locationCtrl.text.trim().isEmpty) {
        _showSnackbar('Please fill in all required fields');
        return;
      }
    }
    if (_currentStep == 1 && _experienceCtrl.text.trim().isEmpty) {
      _showSnackbar('Please describe your mentoring experience');
      return;
    }
    if (_currentStep == 2 && _selectedPrograms.isEmpty) {
      _showSnackbar('Select at least one program');
      return;
    }
    if (_currentStep == 4) {
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
      await FirebaseFirestore.instance.collection('mentor_applications').add({
        'userId': uid,
        'fullName': _fullNameCtrl.text.trim(),
        'gymName': _gymNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'experience': _experienceCtrl.text.trim(),
        'motivation': _motivationCtrl.text.trim(),
        'certifications': _certCtrl.text.trim(),
        'profileUrl': _profileUrlCtrl.text.trim(),
        'mentorTier': _mentorTier,
        'selectedPrograms': _selectedPrograms,
        'selectedSports': _selectedSports,
        'hasWorkingWithChildren': _hasWorkingWithChildren,
        'hasMentalHealthTraining': _hasMentalHealthTraining,
        'hasFirstAid': _hasFirstAid,
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
  Widget _buildSectionHeader(String title, IconData icon, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.pinkAccent),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.pinkAccent,
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
            if (label.contains('PHOTO')) setState(() {});
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
              color: Colors.pinkAccent.withValues(alpha: 0.5),
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
                color: Colors.pinkAccent.withValues(alpha: 0.5),
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

  Widget _buildCheckItem(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: value
              ? AppColors.neonGreen.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.02),
          border: Border.all(
            color: value
                ? AppColors.neonGreen.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              size: 22,
              color: value ? AppColors.neonGreen : AppTheme.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: value
                          ? AppColors.neonGreen
                          : AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted,
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

  Color _getMentorColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'pink diamond':
        return Colors.pinkAccent;
      case 'black diamond':
        return const Color(0xFFB0BEC5);
      default:
        return const Color(0xFFFFD700);
    }
  }
}
