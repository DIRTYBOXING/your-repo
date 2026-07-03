import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/result.dart';
import '../../../core/utils/helpline_directory.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/animated_dfc_logo.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// REGISTER SCREEN — Arena Ignition Protocol v4.0
///
/// Explosive cosmic background + glassmorphic registration form.
/// Particle shockwave detonation on "Create Account" press.
/// Zero video dependency — all custom-painted effects.
/// ═══════════════════════════════════════════════════════════════════════════
class RegisterScreen extends StatefulWidget {
  final UserRole? initialRole;

  const RegisterScreen({super.key, this.initialRole});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cityController = TextEditingController();
  final _postcodeController = TextEditingController();
  String _selectedCountry = 'Australia';
  String _selectedSex = 'female';
  DateTime? _dateOfBirth;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  late UserRole _selectedRole;

  // Animations
  late final AnimationController _pulseCtrl;
  late final AnimationController _entryCtrl;
  late final AnimationController _detonateCtrl;
  late final Animation<double> _headerScale;
  late final Animation<double> _formFade;
  late final Animation<double> _formSlide;

  bool _detonating = false;
  final _rng = math.Random();
  late final List<_Shard> _shards;
  late final List<_Ember> _embers;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? UserRole.fan;

    _shards = List.generate(40, (_) => _Shard.random(_rng));
    _embers = List.generate(60, (_) => _Ember.random(_rng));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _detonateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _headerScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
      ),
    );

    _formSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.25, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _entryCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthService>().clearError();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cityController.dispose();
    _postcodeController.dispose();
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    _detonateCtrl.dispose();
    super.dispose();
  }

  Future<void> _triggerDetonation(Future<void> Function() action) async {
    setState(() => _detonating = true);
    _detonateCtrl.forward(from: 0);

    await action();

    if (mounted && _detonating) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _detonating = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSex.isEmpty) {
      _showSnackBar('Please select Male or Female');
      return;
    }
    if (_dateOfBirth == null) {
      _showSnackBar('Please enter your date of birth');
      return;
    }

    // Age verification check
    final age = DateTime.now().year - _dateOfBirth!.year;
    final minAge = _selectedCountry == 'Australia' ? 16 : 13;
    if (age < minAge) {
      _showSnackBar(
        'You must be at least $minAge years old to create an account',
      );
      return;
    }

    if (!_acceptTerms) {
      _showSnackBar('Please accept the Terms of Service and Privacy Policy');
      return;
    }

    _triggerDetonation(() async {
      final authService = context.read<AuthService>();
      try {
        final result = await authService.registerWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(), // This was correct
          role: _selectedRole,
          sex: _selectedSex,
          country: _selectedCountry,
          city: _cityController.text.trim(),
          postcode: _postcodeController.text.trim(),
          dateOfBirth: _dateOfBirth,
        );

        if (result is Success && mounted) {
          await authService.recordRequiredConsents(version: '1.0');
          if (mounted) context.go('/home');
        }
      } catch (e) {
        _showSnackBar('Registration failed: $e');
      }
    });
  }

  Future<void> _signUpWithGoogle() async {
    if (_selectedSex.isEmpty) {
      _showSnackBar('Please select Male or Female');
      return;
    }
    if (!_acceptTerms) {
      _showSnackBar('Please accept the Terms of Service and Privacy Policy');
      return;
    }

    _triggerDetonation(() async {
      _showSnackBar('Google sign-in is not implemented yet.');
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _goBackSafely() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/landing');
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final bool authDisabled = false;
    final bool googleEnabled = false;

    return Scaffold(
      backgroundColor: const Color(0xFF020810),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 0: Cosmic background ──
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, _) => CustomPaint(
              painter: _CosmicBackgroundPainter(
                pulse: _pulseCtrl.value,
                embers: _embers,
              ),
              size: Size.infinite,
            ),
          ),

          // ── Layer 1: Dark overlay ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.7),
                  const Color(0xFF020810).withValues(alpha: 0.9),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Layer 2: Detonation FX ──
          if (_detonating)
            AnimatedBuilder(
              animation: _detonateCtrl,
              builder: (context, _) => CustomPaint(
                painter: _IgnitionPainter(
                  progress: _detonateCtrl.value,
                  shards: _shards,
                ),
                size: Size.infinite,
              ),
            ),

          // ── Layer 3: Main content ──
          SafeArea(
            child: AnimatedBuilder(
              animation: _entryCtrl,
              builder: (context, _) {
                return Column(
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: IconButton(
                          tooltip: 'Back',
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppTheme.neonCyan,
                            size: 24,
                          ),
                          onPressed: _goBackSafely,
                        ),
                      ),
                    ),

                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Column(
                              children: [
                                // ── Cinematic Hero (no video dependency) ──
                                _buildCinematicHero(),
                                const SizedBox(height: 20),

                                // ── Header ──
                                ScaleTransition(
                                  scale: _headerScale,
                                  child: _buildHoloHeader(),
                                ),
                                const SizedBox(height: 24),

                                // ── Form ──
                                FadeTransition(
                                  opacity: _formFade,
                                  child: Transform.translate(
                                    offset: Offset(0, _formSlide.value),
                                    child: _buildGlassForm(
                                      authService,
                                      authDisabled,
                                      googleEnabled,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCinematicHero() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final pulse = _pulseCtrl.value;
        return Container(
          height: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF072338).withValues(alpha: 0.92),
                const Color(0xFF13102A).withValues(alpha: 0.95),
              ],
            ),
            border: Border.all(
              color: AppTheme.neonCyan.withValues(alpha: 0.28 + pulse * 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonCyan.withValues(alpha: 0.12 + pulse * 0.08),
                blurRadius: 26 + pulse * 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              const AnimatedDfcLogo(size: 96),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DISCIPLINE IS THE NEW EDGE',
                        style: TextStyle(
                          color: AppTheme.neonCyan.withValues(alpha: 0.95),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'BUILD THE FIGHTER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create your profile and start real progress.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HOLOGRAPHIC HEADER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHoloHeader() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final pulse = _pulseCtrl.value;
        return Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: const [
                  AppTheme.neonCyan,
                  AppTheme.neonMagenta,
                  AppTheme.neonCyan,
                ],
                stops: [0.0, (0.3 + pulse * 0.4).clamp(0.0, 1.0), 1.0],
              ).createShader(bounds),
              child: const Text(
                'JOIN THE FIGHT',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No shortcuts. No excuses. Earn your level.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.62),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFF1744).withValues(alpha: 0.5),
                ),
                color: const Color(0xFFFF1744).withValues(alpha: 0.08),
              ),
              child: Text(
                'DFC STANDARD: TRAIN WITH INTENT',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GLASS FORM
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildGlassForm(
    AuthService authService,
    bool authDisabled,
    bool googleEnabled,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.neonMagenta.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonMagenta.withValues(alpha: 0.04),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (authDisabled) ...[
              _buildBanner(
                'Demo Mode — explore everything DFC has to offer.',
                AppTheme.neonCyan,
                Icons.explore,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.rocket_launch, size: 20),
                  label: const Text(
                    'ENTER DFC — DEMO MODE',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (authService.error != null) ...[
              _buildBanner(authService.error!, Colors.red, Icons.error_outline),
              const SizedBox(height: 16),
            ],

            // Role selector
            _buildRoleSelector(),
            const SizedBox(height: 20),

            // Sex selector
            _buildSexSelector(),
            const SizedBox(height: 20),

            // Date of Birth (Age verification)
            _buildDOBPicker(),
            const SizedBox(height: 20),

            // Name
            AppTextField(
              controller: _nameController,
              label: 'Full Name',
              hintText: 'Enter your full name',
              prefixIcon: Icons.person_outlined,
              validator: _validateName,
            ),
            const SizedBox(height: 16),

            // Email
            AppTextField(
              controller: _emailController,
              label: 'Email',
              hintText: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),

            // Password
            AppTextField(
              controller: _passwordController,
              label: 'Password',
              hintText: 'Create a password',
              obscureText: _obscurePassword,
              prefixIcon: Icons.lock_outlined,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '8+ chars • uppercase • lowercase • number • special char (!@#\$%&*)',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
            const SizedBox(height: 12),

            // Confirm Password
            AppTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hintText: 'Confirm your password',
              obscureText: _obscureConfirmPassword,
              prefixIcon: Icons.lock_outlined,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
              validator: _validateConfirmPassword,
            ),
            const SizedBox(height: 20),

            // Location fields
            _buildLocationSection(),
            const SizedBox(height: 20),

            // Terms checkbox
            _buildTermsCheckbox(),
            const SizedBox(height: 20),

            // ── DETONATE CREATE ACCOUNT ──
            _DetonateButton(
              text: 'CREATE ACCOUNT',
              icon: Icons.rocket_launch,
              color: AppTheme.neonMagenta,
              onPressed: authDisabled ? null : _register,
            ),

            const SizedBox(height: 20),
            _buildDivider(),
            const SizedBox(height: 20),

            if (googleEnabled) ...[
              AppButton(
                text: 'Sign up with Google',
                onPressed: authDisabled ? null : _signUpWithGoogle,
                variant: ButtonVariant.outlined,
                icon: Icons.g_mobiledata,
              ),
              const SizedBox(height: 16),
            ],

            // Login link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                      return;
                    }
                    context.go('/login');
                  },
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      color: AppTheme.neonCyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ROLE SELECTOR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a...',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.6),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildRoleChip(UserRole.fan, 'Fan', Icons.favorite),
            _buildRoleChip(UserRole.fighter, 'Fighter', Icons.sports_mma),
            _buildRoleChip(UserRole.coach, 'Coach', Icons.school),
            _buildRoleChip(UserRole.gym, 'Gym Owner', Icons.fitness_center),
            _buildRoleChip(UserRole.promoter, 'Promoter', Icons.campaign),
            _buildRoleChip(UserRole.sponsor, 'Sponsor', Icons.business),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleChip(UserRole role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    final color = AppTheme.getRoleColor(role.name);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? Colors.white : color),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedRole = role),
        selectedColor: color,
        checkmarkColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        side: BorderSide(
          color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
        ),
        labelStyle: TextStyle(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.7),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSexSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sex',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.6),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildSexChip('female', 'Female', Icons.female)),
            const SizedBox(width: 10),
            Expanded(child: _buildSexChip('male', 'Male', Icons.male)),
          ],
        ),
      ],
    );
  }

  Widget _buildSexChip(String value, String label, IconData icon) {
    final isSelected = _selectedSex == value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      child: FilterChip(
        label: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppTheme.neonCyan,
            ),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedSex = value),
        selectedColor: AppTheme.neonCyan,
        checkmarkColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        side: BorderSide(
          color: isSelected
              ? AppTheme.neonCyan
              : Colors.white.withValues(alpha: 0.1),
        ),
        labelStyle: TextStyle(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.7),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DATE OF BIRTH PICKER — Age verification (13+/16+ compliance)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDOBPicker() {
    return GestureDetector(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppTheme.neonCyan,
                  surface: Color(0xFF1A1A2E),
                ),
                dialogTheme: const DialogThemeData(
                  backgroundColor: Color(0xFF1A1A2E),
                ),
              ),
              child: child!,
            );
          },
        );

        if (pickedDate != null) {
          setState(() => _dateOfBirth = pickedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _dateOfBirth != null
                ? AppTheme.neonCyan.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cake_outlined,
              color: _dateOfBirth != null
                  ? AppTheme.neonCyan
                  : Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _dateOfBirth != null
                    ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                    : 'Date of Birth (Required)',
                style: TextStyle(
                  color: _dateOfBirth != null
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.calendar_today,
              size: 16,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOCATION SECTION — Country, City, Postcode
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR LOCATION',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Helps us show local helplines, nearby gyms & events',
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(height: 12),

        // Country dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCountry,
            dropdownColor: const Color(0xFF0D1117),
            icon: Icon(
              Icons.expand_more,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.public,
                color: AppTheme.neonCyan.withValues(alpha: 0.7),
                size: 18,
              ),
              border: InputBorder.none,
              labelText: 'Country',
              labelStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
            items: HelplineDirectory.supportedCountries.map((c) {
              final h = HelplineDirectory.forCountry(c);
              return DropdownMenuItem(
                value: c,
                child: Text('${h?.flag ?? '🌍'}  $c'),
              );
            }).toList(),
            onChanged: (v) =>
                setState(() => _selectedCountry = v ?? 'Australia'),
          ),
        ),
        const SizedBox(height: 12),

        // City + Postcode row
        Row(
          children: [
            Expanded(
              flex: 3,
              child: AppTextField(
                controller: _cityController,
                label: 'City',
                hintText: 'e.g. Melbourne',
                prefixIcon: Icons.location_city,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: AppTextField(
                controller: _postcodeController,
                label: 'Postcode',
                hintText: 'e.g. 3000',
                prefixIcon: Icons.pin_drop,
                keyboardType: TextInputType.text,
              ),
            ),
          ],
        ),

        // Fighter-specific note
        if (_selectedRole == UserRole.fighter) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.neonCyan.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sports_mma,
                  color: AppTheme.neonCyan.withValues(alpha: 0.7),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your location registers you in the DFC DataFightBank — the global fighter database. Promoters & matchmakers in your area will find you.',
                    style: TextStyle(
                      color: AppTheme.neonCyan.withValues(alpha: 0.6),
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _acceptTerms,
            onChanged: (value) => setState(() => _acceptTerms = value ?? false),
            activeColor: AppTheme.neonMagenta,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _acceptTerms = !_acceptTerms),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: const TextStyle(
                      color: AppTheme.neonCyan,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => context.push('/terms-of-service'),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: const TextStyle(
                      color: AppTheme.neonCyan,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => context.push('/privacy'),
                  ),
                  const TextSpan(
                    text:
                        '. I consent to the collection and processing of my personal data in accordance with Australian Privacy Principles and GDPR.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBanner(String message, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Name is required';
    if (value.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain an uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain a lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain a number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain a special character (!@#\$%&*)';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DETONATE BUTTON — Pulsing neon CTA with shockwave tap effect
// ═════════════════════════════════════════════════════════════════════════════
class _DetonateButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _DetonateButton({
    required this.text,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  State<_DetonateButton> createState() => _DetonateButtonState();
}

class _DetonateButtonState extends State<_DetonateButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final p = _pulseCtrl.value;
        return GestureDetector(
          onTap: widget.onPressed,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 80),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    widget.color.withValues(alpha: 0.7 + p * 0.1),
                    widget.color.withValues(alpha: 0.4 + p * 0.1),
                  ],
                ),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.3 + p * 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.15 + p * 0.2),
                    blurRadius: 16 + p * 12,
                    spreadRadius: 2 + p * 4,
                  ),
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.05),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.icon,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// EXPLOSION DATA CLASSES
// ═════════════════════════════════════════════════════════════════════════════

class _Shard {
  final double angle, speed, size, rotSpeed;
  final Color color;

  _Shard({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotSpeed,
  });

  factory _Shard.random(math.Random r) {
    const colors = [
      AppTheme.neonMagenta,
      AppTheme.neonCyan,
      AppTheme.neonGreen,
      Color(0xFFFF2D55),
      Color(0xFFFF9800),
      Colors.white,
    ];
    return _Shard(
      angle: r.nextDouble() * math.pi * 2,
      speed: 0.3 + r.nextDouble() * 0.7,
      size: 1.0 + r.nextDouble() * 4.0,
      color: colors[r.nextInt(colors.length)],
      rotSpeed: (r.nextDouble() - 0.5) * 6,
    );
  }
}

class _Ember {
  final double x, y, speed, size;
  final Color color;

  _Ember({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
  });

  factory _Ember.random(math.Random r) {
    const colors = [
      AppTheme.neonMagenta,
      AppTheme.neonCyan,
      Color(0xFFB100FF),
      Color(0xFF00D9FF),
    ];
    return _Ember(
      x: r.nextDouble(),
      y: r.nextDouble(),
      speed: 0.1 + r.nextDouble() * 0.5,
      size: 0.5 + r.nextDouble() * 1.8,
      color: colors[r.nextInt(colors.length)],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// COSMIC BACKGROUND PAINTER
// ═════════════════════════════════════════════════════════════════════════════
class _CosmicBackgroundPainter extends CustomPainter {
  final double pulse;
  final List<_Ember> embers;
  _CosmicBackgroundPainter({required this.pulse, required this.embers});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF0A0518), Color(0xFF050D1A), Color(0xFF020810)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    // Nebula glows
    for (final n in [
      [0.25, 0.3, AppTheme.neonMagenta, 0.05],
      [0.75, 0.55, AppTheme.neonCyan, 0.04],
      [0.5, 0.8, AppTheme.neonGreen, 0.03],
    ]) {
      canvas.drawCircle(
        Offset((n[0] as double) * size.width, (n[1] as double) * size.height),
        size.width * 0.35,
        Paint()
          ..color = (n[2] as Color).withValues(
            alpha: (n[3] as double).clamp(0.0, 1.0),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80),
      );
    }

    // Floating embers
    for (final e in embers) {
      final t = (pulse * e.speed + e.x * 3) % 1.0;
      final px = (e.x + t * 0.15) % 1.0 * size.width;
      final py = (e.y - t * 0.3 + 1.0) % 1.0 * size.height;
      final a = (0.15 + math.sin(t * math.pi) * 0.25).clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(px, py),
        e.size + 2,
        Paint()
          ..color = e.color.withValues(alpha: a * 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        Offset(px, py),
        e.size * 0.4,
        Paint()..color = e.color.withValues(alpha: a),
      );
    }

    // Stars
    final rng = math.Random(77);
    for (int i = 0; i < 60; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final s = rng.nextDouble() * 1.2 + 0.3;
      final b = (rng.nextDouble() * 0.6 + 0.2).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(x, y),
        s,
        Paint()..color = Colors.white.withValues(alpha: b),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicBackgroundPainter old) =>
      old.pulse != pulse;
}

// ═════════════════════════════════════════════════════════════════════════════
// IGNITION PAINTER — Shockwave + fragment burst on account creation
// ═════════════════════════════════════════════════════════════════════════════
class _IgnitionPainter extends CustomPainter {
  final double progress;
  final List<_Shard> shards;

  _IgnitionPainter({required this.progress, required this.shards});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.6);

    // ── Shockwave rings ──
    for (int i = 0; i < 3; i++) {
      final delay = i * 0.12;
      final t = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final radius = t * size.width * 0.8;
      final alpha = ((1.0 - t) * 0.35).clamp(0.0, 1.0);
      final ringColor = [
        AppTheme.neonMagenta,
        AppTheme.neonCyan,
        AppTheme.neonGreen,
      ][i];

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = ringColor.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1.0 - t),
      );

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = ringColor.withValues(alpha: alpha * 0.15)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 * (1.0 - t)),
      );
    }

    // ── Core flash ──
    if (progress < 0.3) {
      final flashAlpha = ((0.3 - progress) / 0.3 * 0.4).clamp(0.0, 1.0);
      canvas.drawCircle(
        center,
        30 + progress * 100,
        Paint()
          ..color = Colors.white.withValues(alpha: flashAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
    }

    // ── Shard fragments ──
    for (final shard in shards) {
      final t = progress;
      final dist = shard.speed * t * size.width * 0.5;
      final fadeIn = (t / 0.1).clamp(0.0, 1.0);
      final fadeOut = ((1.0 - t) / 0.4).clamp(0.0, 1.0);
      final alpha = (fadeIn * fadeOut * 0.8).clamp(0.0, 1.0);

      final px = center.dx + math.cos(shard.angle) * dist;
      final py = center.dy + math.sin(shard.angle) * dist + t * t * 80;

      canvas.drawCircle(
        Offset(px, py),
        shard.size + 3,
        Paint()
          ..color = shard.color.withValues(alpha: alpha * 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(
        Offset(px, py),
        shard.size * 0.5,
        Paint()..color = shard.color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IgnitionPainter old) =>
      old.progress != progress;
}
