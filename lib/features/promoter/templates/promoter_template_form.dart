import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/fight_card_template.dart';
import '../../../shared/services/fight_card_template_service.dart';
import '../../../shared/services/auth_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC FIGHTCARD BUILDER™ — Promoter Template Wizard
/// Step-by-step wizard: Event → Fight → Red → Blue → Sponsor → Poster → Preview
/// Collapsible card stack · Neon theme · Image upload · Export
/// ═══════════════════════════════════════════════════════════════════════════
class PromoterTemplateFormScreen extends StatefulWidget {
  const PromoterTemplateFormScreen({super.key});

  @override
  State<PromoterTemplateFormScreen> createState() =>
      _PromoterTemplateFormScreenState();
}

class _PromoterTemplateFormScreenState extends State<PromoterTemplateFormScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  int _currentStep = 0;
  bool _saving = false;

  // Step 1: Event Details
  final _eventNameCtrl = TextEditingController();
  final _promoterNameCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  DateTime _eventDate = DateTime.now().add(const Duration(days: 30));
  String _ruleSet = 'Full Contact MMA';

  // Step 2: Fight Details
  String _weightClass = 'Lightweight (70 kg / 155 lbs)';
  int _rounds = 3;
  int _roundMinutes = 5;
  String _sportType = 'MMA';
  bool _isTitleFight = false;

  // Step 3: Red Corner
  final _redNameCtrl = TextEditingController();
  final _redGymCtrl = TextEditingController();
  final _redRecordCtrl = TextEditingController();

  // Step 4: Blue Corner
  final _blueNameCtrl = TextEditingController();
  final _blueGymCtrl = TextEditingController();
  final _blueRecordCtrl = TextEditingController();

  // Step 5: Sponsor / Gym
  final _sponsorNameCtrl = TextEditingController();
  final _sponsorNoteCtrl = TextEditingController();

  // Step 6: Poster
  String? _posterPath;

  static const _weightClasses = [
    'Strawweight (52 kg / 115 lbs)',
    'Flyweight (57 kg / 125 lbs)',
    'Bantamweight (61 kg / 135 lbs)',
    'Featherweight (66 kg / 145 lbs)',
    'Lightweight (70 kg / 155 lbs)',
    'Welterweight (77 kg / 170 lbs)',
    'Middleweight (84 kg / 185 lbs)',
    'Light Heavyweight (93 kg / 205 lbs)',
    'Heavyweight (120 kg / 265 lbs)',
    'Super Heavyweight (120+ kg / 265+ lbs)',
  ];

  static const _sportTypes = [
    'MMA',
    'Boxing',
    'Kickboxing',
    'Muay Thai',
    'BJJ',
    'Wrestling',
    'Karate',
    'Taekwondo',
  ];

  static const _ruleSets = [
    'Full Contact MMA',
    'Amateur MMA',
    'Boxing (Professional)',
    'Boxing (Amateur)',
    'Muay Thai',
    'Kickboxing (K-1)',
    'Kickboxing (Full Contact)',
    'BJJ (Gi)',
    'BJJ (No-Gi)',
    'Wrestling (Freestyle)',
    'Exhibition',
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _eventNameCtrl.dispose();
    _promoterNameCtrl.dispose();
    _venueCtrl.dispose();
    _cityCtrl.dispose();
    _redNameCtrl.dispose();
    _redGymCtrl.dispose();
    _redRecordCtrl.dispose();
    _blueNameCtrl.dispose();
    _blueGymCtrl.dispose();
    _blueRecordCtrl.dispose();
    _sponsorNameCtrl.dispose();
    _sponsorNoteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, _) => Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.neonCyan.withValues(
                        alpha: (0.4 + _pulseCtrl.value * 0.5).clamp(0.0, 1.0),
                      ),
                      AppTheme.neonMagenta.withValues(
                        alpha: (0.3 + _pulseCtrl.value * 0.4).clamp(0.0, 1.0),
                      ),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.description,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [AppTheme.neonCyan, AppTheme.neonMagenta],
              ).createShader(b),
              child: const Text(
                'FIGHTCARD BUILDER',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _currentStep < 6
                ? null
                : _saving
                ? null
                : _saveFightCard,
            icon: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    Icons.save,
                    size: 16,
                    color: _currentStep < 6
                        ? Colors.white24
                        : AppTheme.neonCyan,
                  ),
            label: Text(
              'SAVE',
              style: TextStyle(
                color: _currentStep < 6 ? Colors.white24 : AppTheme.neonCyan,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Step indicator
          _buildStepIndicator(),
          // Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _buildStepContent(),
            ),
          ),
          // Navigation
          _buildNavButtons(),
        ],
      ),
    );
  }

  // ── Step Indicator ──────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    final steps = [
      '📋 Event',
      '🥊 Fight',
      '🟥 Red',
      '🟦 Blue',
      '💼 Sponsor',
      '🖼️ Poster',
      '👁️ Preview',
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: steps.length,
        itemBuilder: (_, i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return GestureDetector(
            onTap: () => setState(() => _currentStep = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.neonCyan.withValues(alpha: 0.15)
                    : isDone
                    ? AppTheme.neonGreen.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? AppTheme.neonCyan
                      : isDone
                      ? AppTheme.neonGreen.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.08),
                  width: isActive ? 1.5 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppTheme.neonCyan.withValues(alpha: 0.15),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDone)
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppTheme.neonGreen,
                    ),
                  if (isDone) const SizedBox(width: 4),
                  Text(
                    steps[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                      color: isActive
                          ? AppTheme.neonCyan
                          : isDone
                          ? AppTheme.neonGreen
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Step Content Router ─────────────────────────────────────────────────
  Widget _buildStepContent() {
    return switch (_currentStep) {
      0 => _buildEventStep(),
      1 => _buildFightStep(),
      2 => _buildRedCornerStep(),
      3 => _buildBlueCornerStep(),
      4 => _buildSponsorStep(),
      5 => _buildPosterStep(),
      6 => _buildPreviewStep(),
      _ => _buildEventStep(),
    };
  }

  // ── Step 1: Event Details ───────────────────────────────────────────────
  Widget _buildEventStep() {
    return _stepScroll(
      key: const ValueKey('event'),
      children: [
        _sectionTitle('EVENT DETAILS', Icons.event),
        const SizedBox(height: 12),
        _neonField(
          _eventNameCtrl,
          'Event Name',
          Icons.sports_mma,
          hint: 'e.g. DFC Fight Night 12',
        ),
        const SizedBox(height: 10),
        _neonField(
          _promoterNameCtrl,
          'Promoter / Organisation',
          Icons.business,
          hint: 'e.g. DFC Promotions',
        ),
        const SizedBox(height: 10),
        _neonField(
          _venueCtrl,
          'Venue',
          Icons.location_on,
          hint: 'e.g. Sydney Olympic Park',
        ),
        const SizedBox(height: 10),
        _neonField(
          _cityCtrl,
          'City / Region',
          Icons.map,
          hint: 'e.g. Sydney, NSW',
        ),
        const SizedBox(height: 10),
        _neonDropdown('Rule Set', _ruleSet, _ruleSets, (v) {
          setState(() => _ruleSet = v!);
        }),
        const SizedBox(height: 10),
        _datePickerTile(),
      ],
    );
  }

  // ── Step 2: Fight Details ───────────────────────────────────────────────
  Widget _buildFightStep() {
    return _stepScroll(
      key: const ValueKey('fight'),
      children: [
        _sectionTitle('FIGHT DETAILS', Icons.sports_mma),
        const SizedBox(height: 12),
        _neonDropdown('Sport', _sportType, _sportTypes, (v) {
          setState(() => _sportType = v!);
        }),
        const SizedBox(height: 10),
        _neonDropdown('Weight Class', _weightClass, _weightClasses, (v) {
          setState(() => _weightClass = v!);
        }),
        const SizedBox(height: 10),
        _inputRow('Rounds', _rounds, 1, 12, (v) => setState(() => _rounds = v)),
        const SizedBox(height: 10),
        _inputRow(
          'Minutes / Round',
          _roundMinutes,
          1,
          10,
          (v) => setState(() => _roundMinutes = v),
        ),
        const SizedBox(height: 10),
        _toggleTile('Title Fight', _isTitleFight, (v) {
          setState(() => _isTitleFight = v);
        }),
      ],
    );
  }

  // ── Step 3: Red Corner ──────────────────────────────────────────────────
  Widget _buildRedCornerStep() {
    return _stepScroll(
      key: const ValueKey('red'),
      children: [
        _sectionTitle('🟥 RED CORNER', Icons.person, color: Colors.red),
        const SizedBox(height: 12),
        _neonField(
          _redNameCtrl,
          'Fighter Name',
          Icons.person,
          color: Colors.red,
          hint: 'Full name',
        ),
        const SizedBox(height: 10),
        _neonField(
          _redGymCtrl,
          'Gym / Team',
          Icons.fitness_center,
          color: Colors.red,
          hint: 'e.g. Absolute MMA',
        ),
        const SizedBox(height: 10),
        _neonField(
          _redRecordCtrl,
          'Record',
          Icons.equalizer,
          color: Colors.red,
          hint: 'e.g. 12-3-0',
        ),
      ],
    );
  }

  // ── Step 4: Blue Corner ─────────────────────────────────────────────────
  Widget _buildBlueCornerStep() {
    return _stepScroll(
      key: const ValueKey('blue'),
      children: [
        _sectionTitle('🟦 BLUE CORNER', Icons.person, color: Colors.blue),
        const SizedBox(height: 12),
        _neonField(
          _blueNameCtrl,
          'Fighter Name',
          Icons.person,
          color: Colors.blue,
          hint: 'Full name',
        ),
        const SizedBox(height: 10),
        _neonField(
          _blueGymCtrl,
          'Gym / Team',
          Icons.fitness_center,
          color: Colors.blue,
          hint: 'e.g. Gracie Brisbane',
        ),
        const SizedBox(height: 10),
        _neonField(
          _blueRecordCtrl,
          'Record',
          Icons.equalizer,
          color: Colors.blue,
          hint: 'e.g. 8-2-1',
        ),
      ],
    );
  }

  // ── Step 5: Sponsor / Gym ───────────────────────────────────────────────
  Widget _buildSponsorStep() {
    return _stepScroll(
      key: const ValueKey('sponsor'),
      children: [
        _sectionTitle(
          'SPONSOR & GYM',
          Icons.handshake,
          color: AppTheme.neonMagenta,
        ),
        const SizedBox(height: 12),
        _neonField(
          _sponsorNameCtrl,
          'Sponsor / Partner Name',
          Icons.business_center,
          color: AppTheme.neonMagenta,
          hint: 'e.g. Venum, DFC',
        ),
        const SizedBox(height: 10),
        _neonField(
          _sponsorNoteCtrl,
          'Notes / Contact',
          Icons.notes,
          color: AppTheme.neonMagenta,
          hint: 'Optional details',
        ),
      ],
    );
  }

  // ── Step 6: Poster Upload ───────────────────────────────────────────────
  Widget _buildPosterStep() {
    return _stepScroll(
      key: const ValueKey('poster'),
      children: [
        _sectionTitle('EVENT POSTER', Icons.image, color: AppColors.neonAmber),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickPoster,
          child: Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.neonAmber.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonAmber.withValues(alpha: 0.05),
                  blurRadius: 12,
                ),
              ],
            ),
            child: _posterPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const Center(
                          child: Icon(
                            Icons.image,
                            size: 60,
                            color: AppColors.neonAmber,
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.neonAmber,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'CHANGE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color: AppColors.neonAmber.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'TAP TO UPLOAD POSTER',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: AppColors.neonAmber.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PNG, JPG — or use DFC default',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _actionChip('Use DFC Default', Icons.auto_awesome, () {
                setState(
                  () => _posterPath = 'assets/event_posters/default_event.png',
                );
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionChip('Auto-Generate', Icons.brush, () {
                setState(() => _posterPath = 'auto_generated');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Auto-generated DFC neon poster applied'),
                    backgroundColor: AppTheme.neonCyan,
                  ),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 7: Preview ─────────────────────────────────────────────────────
  Widget _buildPreviewStep() {
    return _stepScroll(
      key: const ValueKey('preview'),
      children: [
        _sectionTitle(
          'FIGHT CARD PREVIEW',
          Icons.preview,
          color: AppTheme.neonCyan,
        ),
        const SizedBox(height: 12),
        // Event poster area
        Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1628), Color(0xFF1A0A28)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.2)),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _posterPath != null ? '🖼️ EVENT POSTER' : 'DFC',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: AppTheme.neonCyan.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  'DATAFIGHT CENTRAL',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                    color: AppTheme.neonCyan.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Event info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: [
              Text(
                _eventNameCtrl.text.isEmpty
                    ? 'EVENT NAME'
                    : _eventNameCtrl.text.toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '${_eventDate.day}/${_eventDate.month}/${_eventDate.year}'
                '  •  ${_venueCtrl.text.isEmpty ? 'Venue' : _venueCtrl.text}'
                '  •  $_ruleSet',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        // Matchup
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              // Red corner
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withValues(alpha: 0.15),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _redNameCtrl.text.isEmpty
                          ? 'RED CORNER'
                          : _redNameCtrl.text.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      _redGymCtrl.text.isEmpty ? 'Gym' : _redGymCtrl.text,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    Text(
                      _redRecordCtrl.text.isEmpty
                          ? '0-0-0'
                          : _redRecordCtrl.text,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // VS
              Column(
                children: [
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Colors.red, Colors.blue],
                    ).createShader(b),
                    child: const Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.neonCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.neonCyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '$_weightClass • $_rounds × $_roundMinutes min',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.neonCyan.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  if (_isTitleFight) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFAA00)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '🏆 TITLE FIGHT',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              // Blue corner
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withValues(alpha: 0.15),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.blue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _blueNameCtrl.text.isEmpty
                          ? 'BLUE CORNER'
                          : _blueNameCtrl.text.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      _blueGymCtrl.text.isEmpty ? 'Gym' : _blueGymCtrl.text,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    Text(
                      _blueRecordCtrl.text.isEmpty
                          ? '0-0-0'
                          : _blueRecordCtrl.text,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Sponsor footer
        if (_sponsorNameCtrl.text.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.neonMagenta.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.neonMagenta.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.handshake,
                  size: 14,
                  color: AppTheme.neonMagenta.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Sponsored by ${_sponsorNameCtrl.text}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.neonMagenta.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        // Export buttons
        _sectionTitle(
          'EXPORT OPTIONS',
          Icons.ios_share,
          color: AppTheme.neonGreen,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _exportButton('Save as PNG', Icons.image, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Use Print → Save as PDF/Image from the preview screen',
                    ),
                    backgroundColor: AppTheme.neonCyan,
                  ),
                );
                _printCard();
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _exportButton('Export PDF', Icons.picture_as_pdf, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Use Print → Save as PDF from the preview screen',
                    ),
                    backgroundColor: AppTheme.neonCyan,
                  ),
                );
                _printCard();
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _exportButton('Print', Icons.print, _printCard),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _exportButton('Share', Icons.share, () {
                SharePlus.instance.share(
                  ShareParams(
                    text:
                        '${_eventNameCtrl.text} — ${_promoterNameCtrl.text}\n'
                        '${_venueCtrl.text}, ${_cityCtrl.text}\n'
                        '${_redNameCtrl.text} vs ${_blueNameCtrl.text}\n\n'
                        'Built with Data Fight Central\n'
                        '${AppConstants.publicWebBaseUrl}',
                  ),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }

  // ── Navigation Buttons ──────────────────────────────────────────────────
  Widget _buildNavButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBackground,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _currentStep--),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('BACK'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _currentStep < 6
                ? ElevatedButton.icon(
                    onPressed: () => setState(() => _currentStep++),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: Text(
                      _currentStep == 5 ? 'PREVIEW CARD' : 'NEXT',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _saving ? null : _saveFightCard,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.save, size: 16),
                    label: Text(
                      _saving ? 'SAVING...' : 'SAVE FIGHT CARD',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Save to Firestore ───────────────────────────────────────────────────
  Future<void> _saveFightCard() async {
    if (_eventNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter an event name first'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() => _currentStep = 0);
      return;
    }

    setState(() => _saving = true);
    try {
      final auth = context.read<AuthService>();
      final service = context.read<FightCardTemplateService>();
      final now = DateTime.now();

      final bout = FightCardBout(
        id: '${now.millisecondsSinceEpoch}',
        position: _isTitleFight ? BoutPosition.mainEvent : BoutPosition.prelim,
        redCornerName: _redNameCtrl.text,
        redCornerGym: _redGymCtrl.text,
        redCornerRecord: _redRecordCtrl.text,
        blueCornerName: _blueNameCtrl.text,
        blueCornerGym: _blueGymCtrl.text,
        blueCornerRecord: _blueRecordCtrl.text,
        weightClass: _weightClass,
        rounds: _rounds,
        roundMinutes: _roundMinutes,
        sportType: _sportType,
        rules: _ruleSet,
        titleFight: _isTitleFight ? '$_weightClass Championship' : null,
      );

      final card = FightCardTemplate(
        id: '',
        creatorId: auth.currentUser?.uid ?? 'demo_user',
        creatorName: auth.currentUser?.displayName ?? 'Promoter',
        eventName: _eventNameCtrl.text,
        promotionName: _promoterNameCtrl.text,
        venue: _venueCtrl.text,
        city: _cityCtrl.text,
        eventDate: _eventDate,
        sportType: _sportType,
        sanctioningBody: _ruleSet,
        bouts: [bout],
        logoUrl: _posterPath,
        notes: _sponsorNameCtrl.text.isNotEmpty
            ? 'Sponsor: ${_sponsorNameCtrl.text}. ${_sponsorNoteCtrl.text}'
            : null,
        createdAt: now,
        updatedAt: now,
      );

      await service.createCard(card);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fight card saved to Firestore!'),
            backgroundColor: AppTheme.neonGreen,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _printCard() async {
    try {
      final _ = context.read<FightCardTemplateService>();
      final now = DateTime.now();

      final bout = FightCardBout(
        id: 'preview_bout',
        position: BoutPosition.mainEvent,
        redCornerName: _redNameCtrl.text,
        blueCornerName: _blueNameCtrl.text,
        redCornerGym: _redGymCtrl.text,
        blueCornerGym: _blueGymCtrl.text,
        redCornerRecord: _redRecordCtrl.text,
        blueCornerRecord: _blueRecordCtrl.text,
        weightClass: _weightClass,
        rounds: _rounds,
        roundMinutes: _roundMinutes,
        sportType: _sportType,
        rules: _ruleSet,
        titleFight: _isTitleFight ? 'Title' : null,
      );

      final card = FightCardTemplate(
        id: 'preview',
        creatorId: 'preview',
        eventName: _eventNameCtrl.text,
        promotionName: _promoterNameCtrl.text,
        venue: _venueCtrl.text,
        city: _cityCtrl.text,
        eventDate: _eventDate,
        sportType: _sportType,
        bouts: [bout],
        createdAt: now,
        updatedAt: now,
      );

      // Navigate to built-in preview screen
      if (mounted) context.push('/fight-card-preview', extra: card);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _pickPoster() {
    // Image picker placeholder — shows DFC default for now
    setState(() {
      _posterPath = 'assets/event_posters/default_event.png';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image picker — using DFC default poster'),
        backgroundColor: AppTheme.neonCyan,
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═════════════════════════════════════════════════════════════════════════
  Widget _stepScroll({required Key key, required List<Widget> children}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _sectionTitle(String text, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? AppTheme.neonCyan),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: color ?? AppTheme.neonCyan,
          ),
        ),
      ],
    );
  }

  Widget _neonField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    Color? color,
    String? hint,
  }) {
    final c = color ?? AppTheme.neonCyan;
    return Container(
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.15)),
      ),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: c.withValues(alpha: 0.6), fontSize: 12),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
          prefixIcon: Icon(icon, color: c.withValues(alpha: 0.6), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _neonDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.neonCyan.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.15)),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppTheme.neonCyan.withValues(alpha: 0.6),
            fontSize: 12,
          ),
          border: InputBorder.none,
        ),
        dropdownColor: const Color(0xFF0D1B2A),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        iconEnabledColor: AppTheme.neonCyan,
      ),
    );
  }

  Widget _inputRow(
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.neonCyan.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline, size: 22),
            color: AppTheme.neonCyan,
            disabledColor: Colors.white24,
          ),
          Text(
            '$value',
            style: const TextStyle(
              color: AppTheme.neonCyan,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline, size: 22),
            color: AppTheme.neonCyan,
            disabledColor: Colors.white24,
          ),
        ],
      ),
    );
  }

  Widget _toggleTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: value
            ? const Color(0xFFFFD700).withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? const Color(0xFFFFD700).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events,
            size: 18,
            color: value ? const Color(0xFFFFD700) : Colors.white24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFFFFD700),
          ),
        ],
      ),
    );
  }

  Widget _datePickerTile() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _eventDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 730)),
        );
        if (picked != null) setState(() => _eventDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.neonCyan.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month,
              color: AppTheme.neonCyan.withValues(alpha: 0.6),
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              'Event Date: ${_eventDate.day}/${_eventDate.month}/${_eventDate.year}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.edit_calendar,
              size: 16,
              color: AppTheme.neonCyan.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.white54),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.neonGreen.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppTheme.neonGreen),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.neonGreen,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
