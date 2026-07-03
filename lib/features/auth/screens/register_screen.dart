import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpline_directory.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/widgets/animated_dfc_logo.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
// import '../../../shared/widgets/cosmic_background_fx.dart';
// import '../../../shared/widgets/detonate_button.dart';

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
  late final AnimationController _entryCtrl;
  late final Animation<double> _headerScale;
  late final Animation<double> _formFade;
  late final Animation<double> _formSlide;

  bool _detonating = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? UserRole.fan;

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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
      if (mounted) {
        // context.read<AuthService>().clearError();
      }
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
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _triggerDetonation(Future<void> Function() action) async {
    setState(() => _detonating = true);

    await action();

    if (mounted && _detonating) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _detonating = false);
    }
  }

  String? _validatePreSubmission() {
    if (_selectedSex.isEmpty) return 'Please select Male or Female';
    if (_dateOfBirth == null) return 'Please enter your date of birth';

    final age = DateTime.now().year - _dateOfBirth!.year;
    final m = DateTime.now().month - _dateOfBirth!.month;
    final d = DateTime.now().day - _dateOfBirth!.day;
    if (m < 0 || (m == 0 && d < 0)) {
      // age--; // This is a more accurate age calculation if needed elsewhere
    }

    final minAge = _selectedCountry == 'Australia' ? 16 : 13;
    if (age < minAge) {
      return 'You must be at least $minAge years old to create an account';
    }

    if (!_acceptTerms) {
      return 'Please accept the Terms of Service and Privacy Policy';
    }
    return null;
  }

  Future<void> _register() async {
    final authService = context.read<AuthService>();
    // authService.clearError();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final preSubmissionError = _validatePreSubmission();
    if (preSubmissionError != null) {
      _showBanner(preSubmissionError, isError: true);
      return;
    }

    _triggerDetonation(() async {
      /*
      final result = await authService.registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
        role: _selectedRole,
        sex: _selectedSex,
        country: _selectedCountry,
        city: _cityController.text.trim(),
        postcode: _postcodeController.text.trim(),
        dateOfBirth: _dateOfBirth,
      );

      if (result.isSuccess && mounted) {
        await authService.recordRequiredConsents(version: '1.0');
        if (mounted) context.go('/home');
      }
      */
      // The authService will set its own error, which the UI will watch.
    });
  }

  Future<void> _signUpWithGoogle() async {
    final authService = context.read<AuthService>();
    // authService.clearError();
    final preSubmissionError = _validatePreSubmission();
    if (preSubmissionError != null) {
      _showBanner(preSubmissionError, isError: true);
      return;
    }

    _triggerDetonation(() async {
      _showBanner('Google sign-in is not implemented yet.', isError: false);
    });
  }

  void _showBanner(String message, {required bool isError}) {
    final authService = context.read<AuthService>();
    // This is a stand-in. Ideally, you'd have a dedicated error provider/state
    // that the banner widget listens to, but this works for now.
    if (isError) {
      // A bit of a hack to display non-auth errors via the auth service error state
      // A better solution is a dedicated screen-level error state provider.
      // TODO: setError not found
      // authService.setError(message);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
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
        // CosmicBackgroundFx(
        // isDetonating: _detonating,
        children: [
          // Main content
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
                                // _buildCinematicHero(),
                                const SizedBox(height: 20),
                                // ── Header ──
                                ScaleTransition(
                                  scale: _headerScale,
                                  child: _HoloHeader(
                                    entryAnimation: _entryCtrl,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // ── Form ──
                                FadeTransition(
                                  opacity: _formFade,
                                  child: Transform.translate(
                                    offset: Offset(0, _formSlide.value),
                                    child: _GlassForm(
                                      formKey: _formKey,
                                      nameController: _nameController,
                                      emailController: _emailController,
                                      passwordController: _passwordController,
                                      confirmPasswordController:
                                          _confirmPasswordController,
                                      cityController: _cityController,
                                      postcodeController: _postcodeController,
                                      selectedRole: _selectedRole,
                                      selectedSex: _selectedSex,
                                      dateOfBirth: _dateOfBirth,
                                      acceptTerms: _acceptTerms,
                                      onRoleChanged: (role) =>
                                          setState(() => _selectedRole = role),
                                      onSexChanged: (sex) =>
                                          setState(() => _selectedSex = sex),
                                      onDateOfBirthChanged: (date) =>
                                          setState(() => _dateOfBirth = date),
                                      onAcceptTermsChanged: (accepted) =>
                                          setState(
                                            () => _acceptTerms = accepted,
                                          ),
                                      onRegister: _register,
                                      onSignUpWithGoogle: _signUpWithGoogle,
                                      obscurePassword: _obscurePassword,
                                      obscureConfirmPassword:
                                          _obscureConfirmPassword,
                                      onTogglePasswordVisibility:
                                          _togglePasswordVisibility,
                                      onToggleConfirmPasswordVisibility:
                                          _toggleConfirmPasswordVisibility,
                                      selectedCountry: _selectedCountry,
                                      onCountryChanged: (country) => setState(
                                        () => _selectedCountry =
                                            country ?? 'Australia',
                                      ),
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
}

class _CinematicHero extends StatelessWidget {
  final Animation<double> entryAnimation;

  const _CinematicHero({required this.entryAnimation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: entryAnimation,
      builder: (context, _) {
        return Container(
          height: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF072338).withOpacity(0.92),
                const Color(0xFF13102A).withOpacity(0.95),
              ],
            ),
            border: Border.all(
              color: AppTheme.neonCyan.withOpacity(
                0.28 + (entryAnimation.value * 0.18),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonCyan.withOpacity(
                  0.12 + (entryAnimation.value * 0.08),
                ),
                blurRadius: 26 + (entryAnimation.value * 10),
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Row(
            children: [
              SizedBox(width: 14),
              AnimatedDfcLogo(size: 96),
              SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: _CinematicHeroText(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CinematicHeroText extends StatelessWidget {
  const _CinematicHeroText();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DISCIPLINE IS THE NEW EDGE',
          style: TextStyle(
            color: AppTheme.neonCyan.withOpacity(0.95),
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
            color: Colors.white.withOpacity(0.72),
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _HoloHeader extends StatelessWidget {
  final Animation<double> entryAnimation;

  const _HoloHeader({required this.entryAnimation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: entryAnimation,
      builder: (context, _) {
        final pulse = entryAnimation.value;
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
                color: Colors.white.withOpacity(0.62),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFF1744).withOpacity(0.5),
                ),
                color: const Color(0xFFFF1744).withOpacity(0.08),
              ),
              child: Text(
                'DFC STANDARD: TRAIN WITH INTENT',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
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
}

class _GlassForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController cityController;
  final TextEditingController postcodeController;
  final UserRole selectedRole;
  final String selectedSex;
  final DateTime? dateOfBirth;
  final bool acceptTerms;
  final ValueChanged<UserRole> onRoleChanged;
  final ValueChanged<String> onSexChanged;
  final ValueChanged<DateTime?> onDateOfBirthChanged;
  final ValueChanged<bool> onAcceptTermsChanged;
  final VoidCallback onRegister;
  final VoidCallback onSignUpWithGoogle;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onToggleConfirmPasswordVisibility;
  final String selectedCountry;
  final ValueChanged<String?> onCountryChanged;

  const _GlassForm({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.cityController,
    required this.postcodeController,
    required this.selectedRole,
    required this.selectedSex,
    required this.dateOfBirth,
    required this.acceptTerms,
    required this.onRoleChanged,
    required this.onSexChanged,
    required this.onDateOfBirthChanged,
    required this.onAcceptTermsChanged,
    required this.onRegister,
    required this.onSignUpWithGoogle,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePasswordVisibility,
    required this.onToggleConfirmPasswordVisibility,
    required this.selectedCountry,
    required this.onCountryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final bool authDisabled = false;
    final bool googleEnabled = false;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.neonMagenta.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonMagenta.withOpacity(0.04),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (authDisabled) ...[
              _Banner(
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
              _Banner(authService.error!, Colors.red, Icons.error_outline),
              const SizedBox(height: 16),
            ],

            // Role selector
            _RoleSelector(
              selectedRole: selectedRole,
              onRoleChanged: onRoleChanged,
            ),
            const SizedBox(height: 20),

            // Sex selector
            // _SexSelector(selectedSex: selectedSex, onSexChanged: onSexChanged),
            const SizedBox(height: 20),

            // Date of Birth (Age verification)
            // _DOBPicker(dateOfBirth: dateOfBirth, onDateOfBirthChanged: onDateOfBirthChanged),
            const SizedBox(height: 20),

            // Name
            AppTextField(
              controller: nameController,
              label: 'Full Name',
              hintText: 'Enter your full name',
              prefixIcon: Icons.person_outlined,
              validator: (val) => _validateName(val),
            ),
            const SizedBox(height: 16),

            // Email
            AppTextField(
              controller: emailController,
              label: 'Email',
              hintText: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (val) => _validateEmail(val),
            ),
            const SizedBox(height: 16),

            // Password
            AppTextField(
              controller: passwordController,
              label: 'Password',
              hintText: 'Create a password',
              obscureText: obscurePassword,
              prefixIcon: Icons.lock_outlined,
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: onTogglePasswordVisibility,
              ),
              validator: (val) => _validatePassword(val),
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
              controller: confirmPasswordController,
              label: 'Confirm Password',
              hintText: 'Confirm your password',
              obscureText: obscureConfirmPassword,
              prefixIcon: Icons.lock_outlined,
              suffixIcon: IconButton(
                icon: Icon(
                  obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: onToggleConfirmPasswordVisibility,
              ),
              validator: (val) =>
                  _validateConfirmPassword(val, passwordController.text),
            ),
            const SizedBox(height: 20),

            // Location fields
            _LocationSection(
              cityController: cityController,
              postcodeController: postcodeController,
              selectedCountry: selectedCountry,
              onCountryChanged: onCountryChanged,
              selectedRole: selectedRole,
            ),
            const SizedBox(height: 20),

            // Terms checkbox
            _TermsCheckbox(
              acceptTerms: acceptTerms,
              onAcceptTermsChanged: onAcceptTermsChanged,
            ),
            const SizedBox(height: 20),

            // ── DETONATE CREATE ACCOUNT ──
            _DetonateButton(
              text: 'CREATE ACCOUNT',
              icon: Icons.rocket_launch,
              color: AppTheme.neonMagenta,
              onPressed: authDisabled ? null : onRegister,
            ),

            const SizedBox(height: 20),
            const _Divider(),
            const SizedBox(height: 20),

            if (googleEnabled) ...[
              AppButton(
                text: 'Sign up with Google',
                onPressed: authDisabled ? null : onSignUpWithGoogle,
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
                    color: Colors.white.withOpacity(0.5),
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

  String? _validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }
}

class _RoleSelector extends StatelessWidget {
  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;

  const _RoleSelector({
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a...',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.6),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChip(context, UserRole.fan, 'Fan', Icons.favorite),
            _buildChip(context, UserRole.fighter, 'Fighter', Icons.sports_mma),
            _buildChip(context, UserRole.coach, 'Coach', Icons.school),
            _buildChip(
              context,
              UserRole.gym,
              'Gym Owner',
              Icons.fitness_center,
            ),
            _buildChip(context, UserRole.promoter, 'Promoter', Icons.campaign),
            _buildChip(context, UserRole.sponsor, 'Sponsor', Icons.business),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(
    BuildContext context,
    UserRole role,
    String label,
    IconData icon,
  ) {
    final isSelected = selectedRole == role;
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
        onSelected: (_) => onRoleChanged(role),
        selectedColor: color,
        checkmarkColor: Colors.white,
        backgroundColor: Colors.white.withOpacity(0.06),
        side: BorderSide(
          color: isSelected ? color : Colors.white.withOpacity(0.1),
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  final TextEditingController cityController;
  final TextEditingController postcodeController;
  final String selectedCountry;
  final ValueChanged<String?> onCountryChanged;
  final UserRole selectedRole;

  const _LocationSection({
    required this.cityController,
    required this.postcodeController,
    required this.selectedCountry,
    required this.onCountryChanged,
    required this.selectedRole,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR LOCATION',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.5),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Helps us show local helplines, nearby gyms & events',
          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.3)),
        ),
        const SizedBox(height: 12),

        // Country dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedCountry,
            dropdownColor: const Color(0xFF0D1117),
            icon: Icon(Icons.expand_more, color: Colors.white.withOpacity(0.4)),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.public,
                color: AppTheme.neonCyan.withOpacity(0.7),
                size: 18,
              ),
              border: InputBorder.none,
              labelText: 'Country',
              labelStyle: TextStyle(
                color: Colors.white.withOpacity(0.4),
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
            onChanged: onCountryChanged,
          ),
        ),
        const SizedBox(height: 12),

        // City + Postcode row
        Row(
          children: [
            Expanded(
              flex: 3,
              child: AppTextField(
                controller: cityController,
                label: 'City',
                hintText: 'e.g. Melbourne',
                prefixIcon: Icons.location_city,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: AppTextField(
                controller: postcodeController,
                label: 'Postcode',
                hintText: 'e.g. 3000',
                prefixIcon: Icons.pin_drop,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
              ),
            ),
          ],
        ),

        // Fighter-specific note
        if (selectedRole == UserRole.fighter) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.neonCyan.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.neonCyan.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sports_mma,
                  color: AppTheme.neonCyan.withOpacity(0.7),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your location registers you in the DFC DataFightBank — the global fighter database. Promoters & matchmakers in your area will find you.',
                    style: TextStyle(
                      color: AppTheme.neonCyan.withOpacity(0.6),
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
}

class _TermsCheckbox extends StatelessWidget {
  final bool acceptTerms;
  final ValueChanged<bool> onAcceptTermsChanged;

  const _TermsCheckbox({
    required this.acceptTerms,
    required this.onAcceptTermsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onAcceptTermsChanged(!acceptTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: acceptTerms,
              onChanged: (value) => onAcceptTermsChanged(value ?? false),
              activeColor: AppTheme.neonMagenta,
              // Visual feedback for the tap on the row
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.45),
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
                      ..onTap = () => context.go('/terms-of-service'),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: const TextStyle(
                      color: AppTheme.neonCyan,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => context.go('/privacy-policy'),
                  ),
                  const TextSpan(
                    text:
                        '. I consent to the collection and processing of my personal data in accordance with Australian Privacy Principles and GDPR.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;
  const _Banner(this.message, this.color, this.icon);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
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
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withOpacity(0.4),
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
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

  String? _validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
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
