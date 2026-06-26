import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../services/auth_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC 18+ AGE VERIFICATION BADGE
/// Shows verification status and triggers age gate when tapped
/// ═══════════════════════════════════════════════════════════════════════════
class AgeVerificationBadge extends StatefulWidget {
  final double size;
  const AgeVerificationBadge({super.key, this.size = 36});

  @override
  State<AgeVerificationBadge> createState() => _AgeVerificationBadgeState();
}

class _AgeVerificationBadgeState extends State<AgeVerificationBadge> {
  bool _isVerified = false;
  bool _loading = true;
  static const _verifiedKey = 'dfc_age_verified_18plus';

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    // Check local storage first
    final prefs = await SharedPreferences.getInstance();
    final localVerified = prefs.getBool(_verifiedKey) ?? false;

    if (localVerified) {
      if (mounted) {
        setState(() {
          _isVerified = true;
          _loading = false;
        });
      }
      return;
    }

    // Check user's DOB from profile
    try {
      if (!mounted) return;
      final auth = context.read<AuthService>();
      final user = auth.userModel;
      if (user != null && user.dateOfBirth != null) {
        final age = _calculateAge(user.dateOfBirth!);
        if (age >= 18) {
          await prefs.setBool(_verifiedKey, true);
          if (mounted) {
            setState(() {
              _isVerified = true;
              _loading = false;
            });
          }
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isVerified = false;
        _loading = false;
      });
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _showVerificationDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AgeVerificationSheet(
        onVerified: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_verifiedKey, true);
          if (!context.mounted) return;
          setState(() => _isVerified = true);
          Navigator.of(ctx).pop();
        },
        onLoginRequired: () {
          Navigator.of(ctx).pop();
          context.push('/login');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Colors.white38,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _isVerified ? null : _showVerificationDialog,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.size / 2),
          color: const Color(0xFF0A0E1A).withValues(alpha: 0.95),
          border: Border.all(
            color: _isVerified
                ? AppTheme.neonGreen.withValues(alpha: 0.6)
                : AppTheme.neonOrange.withValues(alpha: 0.5),
          ),
          boxShadow: _isVerified
              ? [
                  BoxShadow(
                    color: AppTheme.neonGreen.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: _isVerified
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '18+',
                      style: TextStyle(
                        color: AppTheme.neonGreen,
                        fontSize: widget.size * 0.32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Icon(
                        Icons.check_circle,
                        color: AppTheme.neonGreen,
                        size: widget.size * 0.28,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '18+',
                      style: TextStyle(
                        color: AppTheme.neonOrange,
                        fontSize: widget.size * 0.32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'VERIFY',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: widget.size * 0.16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Age Verification Bottom Sheet
/// ═══════════════════════════════════════════════════════════════════════════
class _AgeVerificationSheet extends StatefulWidget {
  final VoidCallback onVerified;
  final VoidCallback onLoginRequired;

  const _AgeVerificationSheet({
    required this.onVerified,
    required this.onLoginRequired,
  });

  @override
  State<_AgeVerificationSheet> createState() => _AgeVerificationSheetState();
}

class _AgeVerificationSheetState extends State<_AgeVerificationSheet> {
  DateTime? _selectedDate;
  bool _termsAccepted = false;
  String? _error;

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _verify() {
    if (_selectedDate == null) {
      setState(() => _error = 'Please select your date of birth');
      return;
    }
    if (!_termsAccepted) {
      setState(() => _error = 'Please accept the terms');
      return;
    }

    final age = _calculateAge(_selectedDate!);
    if (age < 18) {
      setState(() => _error = 'You must be 18 or older to access this content');
      return;
    }

    widget.onVerified();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.read<AuthService>().currentUser != null;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1117),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.white24,
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.neonOrange.withValues(alpha: 0.3),
                  AppTheme.neonOrange.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: const Text(
              '18+',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Age Verification Required',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This content requires you to be 18 years or older.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Date of Birth picker
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(2000),
                firstDate: DateTime(1920),
                lastDate: DateTime.now(),
                builder: (ctx, child) => Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppTheme.neonCyan,
                      surface: Color(0xFF1A1A2E),
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                  _error = null;
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF0A0E1A),
                border: Border.all(
                  color: _error != null
                      ? Colors.redAccent
                      : AppTheme.neonCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppTheme.neonCyan.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate == null
                        ? 'Select Date of Birth'
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    style: TextStyle(
                      color: _selectedDate == null
                          ? Colors.white54
                          : Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Terms checkbox
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _termsAccepted
                          ? AppTheme.neonCyan
                          : Colors.white38,
                    ),
                    color: _termsAccepted
                        ? AppTheme.neonCyan.withValues(alpha: 0.2)
                        : Colors.transparent,
                  ),
                  child: _termsAccepted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'I confirm I am 18+ and agree to the Terms of Service',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ],

          const SizedBox(height: 24),

          // Verify button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _verify,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Verify My Age',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),

          if (!isLoggedIn) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: widget.onLoginRequired,
              child: Text(
                'Login for persistent verification',
                style: TextStyle(
                  color: AppTheme.neonCyan.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
