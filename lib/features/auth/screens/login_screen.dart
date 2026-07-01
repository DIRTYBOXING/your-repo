import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/video_intro_service.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/animated_dfc_logo.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// LOGIN SCREEN — Cage Detonation Protocol v4.0
///
/// Explosive particle storm background, shockwave on sign-in,
/// glassmorphic form, zero video dependency.
///
/// When the user taps "Sign In", a radial shockwave + particle burst
/// erupts from the button, creating a cage-break visual detonation.
/// ═══════════════════════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Animations
  late final AnimationController _pulseCtrl;
  late final AnimationController _entryCtrl;
  late final AnimationController _detonateCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _formFade;
  late final Animation<double> _formSlide;

  // Explosion state
  bool _detonating = false;
  final _rng = math.Random();
  late final List<_ExplosionShard> _shards;
  late final List<_Ember> _embers;

  @override
  void initState() {
    super.initState();

    // Pre-generate explosion particles
    _shards = List.generate(40, (_) => _ExplosionShard.random(_rng));
    _embers = List.generate(80, (_) => _Ember.random(_rng));

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

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _formSlide = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _entryCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthService>().clearError();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    _detonateCtrl.dispose();
    super.dispose();
  }

  // ── Detonate: visual explosion on sign-in ──
  Future<void> _triggerDetonation(Future<void> Function() action) async {
    setState(() => _detonating = true);
    _detonateCtrl.forward(from: 0);

    try {
      await action();
    } catch (e) {
      debugPrint('Auth action error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sign-in error: ${e.toString().length > 120 ? e.toString().substring(0, 120) : e}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }

    // If still mounted and auth didn't navigate, reset
    if (mounted && _detonating) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _detonating = false);
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    _triggerDetonation(() async {
      final authService = context.read<AuthService>();
      final result = await authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (result != null && mounted) {
        await _showPowerIntroIfFirstSignIn(authService);
        if (!mounted) return;
        context.go('/home');
      } else if (mounted && authService.shouldUseEmergencyLocalSession()) {
        authService.enableEmergencyLocalSession(
          emailHint: _emailController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.shield, color: Colors.white, size: 18),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Operating in demo mode. Full Firebase sync when available.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.deepPurple.withValues(alpha: 0.8),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
        context.go('/home');
      }
      // Error is displayed via authService.error in the UI automatically
    });
  }

  Future<void> _showPowerIntroIfFirstSignIn(AuthService authService) async {
    final uid = authService.currentUser?.uid;
    if (uid == null || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final introKey = 'dfc_power_intro_seen_$uid';
    final alreadySeen = prefs.getBool(introKey) ?? false;
    if (alreadySeen || !mounted) return;

    // Mark first to prevent repeat loops if navigation changes mid-intro.
    await prefs.setBool(introKey, true);
    if (!mounted) return;

    try {
      await DfcVideoIntroService.showVideoIntro(
        context,
        DfcVideoType.welcome,
      );
    } catch (_) {
      // Keep login flow resilient even if video intro fails.
    }
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
    final bool authDisabled = authService.isAuthTemporarilyDisabled;

    return Scaffold(
      backgroundColor: const Color(0xFF020810),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 0: Cosmic background ──
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, _) => CustomPaint(
              painter: _CosmicStormPainter(
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
                  Colors.black.withValues(alpha: 0.45),
                  Colors.black.withValues(alpha: 0.65),
                  const Color(0xFF020810).withValues(alpha: 0.90),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Layer 2: Detonation shockwave ──
          if (_detonating)
            AnimatedBuilder(
              animation: _detonateCtrl,
              builder: (context, _) => CustomPaint(
                painter: _DetonationPainter(
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
                return LayoutBuilder(
                  builder: (context, viewport) {
                    return _buildAuthStage(authService, authDisabled, viewport);
                  },
                );
              },
            ),
          ),

          // ── Back button ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
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
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DFC BRAND LOGO — Hexagonal badge with pulsing neon cyan glow
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHoloLogo({
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final pulse = _pulseCtrl.value;
        return Column(
          crossAxisAlignment: crossAxisAlignment,
          children: [
            // ── DFC Hexagonal Brand Logo (the real one) ──
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonCyan.withValues(
                      alpha: 0.18 + pulse * 0.12,
                    ),
                    blurRadius: 60 + pulse * 20,
                    spreadRadius: 8 + pulse * 4,
                  ),
                  BoxShadow(
                    color: AppTheme.neonMagenta.withValues(
                      alpha: 0.10 + pulse * 0.08,
                    ),
                    blurRadius: 40 + pulse * 10,
                    spreadRadius: 4 + pulse * 2,
                  ),
                ],
              ),
              child: const AnimatedDfcLogo(
                size: 160,
                rotate: true,
              ),
            ),
            const SizedBox(height: 24),
            // ── DATAFIGHT CENTRAL wordmark ──
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
                'DATAFIGHT CENTRAL',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 7,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: AppTheme.neonCyan,
                      blurRadius: 18,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No shortcuts. No excuses. Build your life through discipline.',
              textAlign: crossAxisAlignment == CrossAxisAlignment.center
                  ? TextAlign.center
                  : TextAlign.left,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.55),
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    color: AppTheme.neonMagenta.withValues(alpha: 0.18),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFF1744).withValues(alpha: 0.5),
                ),
                color: const Color(0xFFFF1744).withValues(alpha: 0.08),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF1744).withValues(alpha: 0.16),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: Text(
                'DFC STANDARD: DISCIPLINE OVER NOISE',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.35),
                ),
                color: const Color(0xFF00FF88).withValues(alpha: 0.06),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user,
                    size: 13,
                    color: const Color(0xFF00FF88).withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'FIGHTERS ARE SAFER WITH DFC',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                      color: const Color(0xFF00FF88).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAuthStage(
    AuthService authService,
    bool authDisabled,
    BoxConstraints viewport,
  ) {
    final isSplitLayout = viewport.maxWidth >= 980;
    final shellMaxWidth = isSplitLayout
        ? 1020.0
        : (viewport.maxWidth >= 640 ? 560.0 : 480.0);
    final horizontalPadding = viewport.maxWidth >= 640 ? 28.0 : 20.0;
    final verticalPadding = isSplitLayout ? 12.0 : 20.0;
    final brandPane = ScaleTransition(
      scale: _logoScale,
      child: _buildHoloLogo(
        crossAxisAlignment: isSplitLayout
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
      ),
    );
    final formPane = FadeTransition(
      opacity: _formFade,
      child: Transform.translate(
        offset: Offset(0, _formSlide.value),
        child: SizedBox(
          width: isSplitLayout ? 430 : double.infinity,
          child: _buildGlassForm(authService, authDisabled),
        ),
      ),
    );

    return Align(
      alignment: isSplitLayout
          ? const Alignment(0, -0.08)
          : const Alignment(0, -0.02),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: shellMaxWidth),
          child: isSplitLayout
              ? Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 52),
                        child: brandPane,
                      ),
                    ),
                    formPane,
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [brandPane, const SizedBox(height: 36), formPane],
                ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GLASS FORM
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildGlassForm(AuthService authService, bool authDisabled) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: 0.04),
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
              hintText: 'Enter your password',
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
            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: authDisabled
                    ? null
                    : () => context.push('/forgot-password'),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: AppTheme.neonCyan, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── DETONATE SIGN IN ──
            _DetonateButton(
              text: 'SIGN IN',
              icon: Icons.sports_mma,
              color: AppTheme.neonCyan,
              isLoading: authService.isLoading,
              onPressed: authDisabled ? null : _signInWithEmail,
            ),

            const SizedBox(height: 20),

            // ── Social divider ──
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'secure sign-in options',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                      letterSpacing: 0.5,
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
            ),

            const SizedBox(height: 16),

            // ── Social sign-in row ──
            Row(
              children: [
                Expanded(
                  child: _SocialSignInButton(
                    label: 'Google',
                    icon: Icons.g_mobiledata_rounded,
                    color: const Color(0xFF4285F4),
                    onPressed: authDisabled
                        ? null
                        : () async {
                            _triggerDetonation(() async {
                              final result = await authService
                                  .signInWithGoogle();
                              if (result != null && mounted) {
                                await _showPowerIntroIfFirstSignIn(authService);
                                if (!mounted) return;
                                context.go('/home');
                              } else if (mounted &&
                                  authService
                                      .shouldUseEmergencyLocalSession()) {
                                authService.enableEmergencyLocalSession(
                                  emailHint: _emailController.text.trim(),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Google auth API is blocked. Emergency local session enabled.',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                context.go('/home');
                              }
                            });
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SocialSignInButton(
                    label: 'Facebook',
                    icon: Icons.facebook_rounded,
                    color: const Color(0xFF1877F2),
                    onPressed: authDisabled
                        ? null
                        : () async {
                            _triggerDetonation(() async {
                              final result = await authService
                                  .signInWithFacebook();
                              if (result != null && mounted) {
                                await _showPowerIntroIfFirstSignIn(authService);
                                if (!mounted) return;
                                context.go('/home');
                              } else if (mounted &&
                                  authService
                                      .shouldUseEmergencyLocalSession()) {
                                authService.enableEmergencyLocalSession(
                                  emailHint: _emailController.text.trim(),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Facebook auth API is blocked. Emergency local session enabled.',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                context.go('/home');
                              }
                            });
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SocialSignInButton(
                    label: 'Apple',
                    icon: Icons.apple_rounded,
                    color: Colors.white,
                    onPressed: authDisabled
                        ? null
                        : () async {
                            _triggerDetonation(() async {
                              final result = await authService
                                  .signInWithApple();
                              if (result != null && mounted) {
                                await _showPowerIntroIfFirstSignIn(authService);
                                if (!mounted) return;
                                context.go('/home');
                              } else if (mounted &&
                                  authService
                                      .shouldUseEmergencyLocalSession()) {
                                authService.enableEmergencyLocalSession(
                                  emailHint: _emailController.text.trim(),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Apple auth API is blocked. Emergency local session enabled.',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                context.go('/home');
                              }
                            });
                          },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      color: AppTheme.neonCyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Guest / Explore mode ──
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  authService.enableEmergencyLocalSession(
                    emailHint: 'guest@datafightcentral.app',
                  );
                  context.go('/home');
                },
                icon: const Icon(Icons.explore, size: 18),
                label: const Text(
                  'EXPLORE AS GUEST',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.neonGreen,
                  side: BorderSide(
                    color: AppTheme.neonGreen.withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
  final bool isLoading;
  final VoidCallback? onPressed;

  const _DetonateButton({
    required this.text,
    required this.icon,
    required this.color,
    this.isLoading = false,
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
          onTap: widget.isLoading ? null : widget.onPressed,
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
                child: widget.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
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
                              fontSize: 15,
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
// SOCIAL SIGN-IN BUTTON
// ═════════════════════════════════════════════════════════════════════════════
class _SocialSignInButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _SocialSignInButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// EXPLOSION DATA CLASSES
// ═════════════════════════════════════════════════════════════════════════════

class _ExplosionShard {
  final double angle;
  final double speed;
  final double size;
  final Color color;
  final double rotSpeed;

  _ExplosionShard({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotSpeed,
  });

  factory _ExplosionShard.random(math.Random r) {
    const colors = [
      AppTheme.neonCyan,
      AppTheme.neonMagenta,
      AppTheme.neonGreen,
      Color(0xFFFF2D55),
      Color(0xFFFF9800),
      Colors.white,
    ];
    return _ExplosionShard(
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
      AppTheme.neonCyan,
      AppTheme.neonMagenta,
      Color(0xFF00D9FF),
      Color(0xFFB100FF),
    ];
    return _Ember(
      x: r.nextDouble(),
      y: r.nextDouble(),
      speed: 0.1 + r.nextDouble() * 0.5,
      size: 0.5 + r.nextDouble() * 2.0,
      color: colors[r.nextInt(colors.length)],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// COSMIC STORM PAINTER — ambient background
// ═════════════════════════════════════════════════════════════════════════════
class _CosmicStormPainter extends CustomPainter {
  final double pulse;
  final List<_Ember> embers;
  _CosmicStormPainter({required this.pulse, required this.embers});

  @override
  void paint(Canvas canvas, Size size) {
    // Deep space gradient
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF050D1A), Color(0xFF0A0518), Color(0xFF020810)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    // Nebula glows
    for (final n in [
      [0.3, 0.2, AppTheme.neonCyan, 0.05],
      [0.75, 0.55, AppTheme.neonMagenta, 0.04],
      [0.5, 0.85, AppTheme.neonGreen, 0.03],
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
    final rng = math.Random(42);
    for (int i = 0; i < 80; i++) {
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
  bool shouldRepaint(covariant _CosmicStormPainter old) => old.pulse != pulse;
}

// ═════════════════════════════════════════════════════════════════════════════
// DETONATION PAINTER — Shockwave + fragment burst on sign-in
// ═════════════════════════════════════════════════════════════════════════════
class _DetonationPainter extends CustomPainter {
  final double progress;
  final List<_ExplosionShard> shards;

  _DetonationPainter({required this.progress, required this.shards});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.65);

    // ── Shockwave rings ──
    for (int i = 0; i < 3; i++) {
      final delay = i * 0.12;
      final t = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final radius = t * size.width * 0.8;
      final alpha = ((1.0 - t) * 0.35).clamp(0.0, 1.0);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = [
            AppTheme.neonCyan,
            AppTheme.neonMagenta,
            AppTheme.neonGreen,
          ][i].withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1.0 - t),
      );

      // Glow ring
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = [
            AppTheme.neonCyan,
            AppTheme.neonMagenta,
            AppTheme.neonGreen,
          ][i].withValues(alpha: alpha * 0.15)
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
      final py =
          center.dy + math.sin(shard.angle) * dist + t * t * 80; // gravity

      // Glow
      canvas.drawCircle(
        Offset(px, py),
        shard.size + 3,
        Paint()
          ..color = shard.color.withValues(alpha: alpha * 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      // Core
      canvas.drawCircle(
        Offset(px, py),
        shard.size * 0.5,
        Paint()..color = shard.color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DetonationPainter old) =>
      old.progress != progress;
}
