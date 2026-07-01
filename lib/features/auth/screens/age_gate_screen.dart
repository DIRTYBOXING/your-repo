import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AGE GATE — wraps any child widget and only renders it if the viewer is 16+.
// Usage:
//   AgeGateWrapper(child: MyRestrictedScreen())
// Also usable as a standalone route via AgeGateScreen.
// ─────────────────────────────────────────────────────────────────────────────

/// Full screen age gate used as a standalone route.
class AgeGateScreen extends StatelessWidget {
  const AgeGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: _AgeGateBody(explicitlyBlocked: true),
    );
  }
}

/// Wrapper widget — renders [child] if the current user is 16+,
/// otherwise renders the age gate UI in place.
class AgeGateWrapper extends StatelessWidget {
  final Widget child;

  const AgeGateWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final dob = auth.userModel?.dateOfBirth;
    final isBlocked = _isUnderMinAge(dob);

    if (!isBlocked) return child;
    return const _AgeGateBody(explicitlyBlocked: false);
  }

  static bool _isUnderMinAge(DateTime? dob) {
    if (dob == null) return false; // If unknown, don't block
    final today = DateTime.now();
    final age =
        today.year -
        dob.year -
        ((today.month < dob.month ||
                (today.month == dob.month && today.day < dob.day))
            ? 1
            : 0);
    return age < 16;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared gate body
// ─────────────────────────────────────────────────────────────────────────────

class _AgeGateBody extends StatelessWidget {
  final bool explicitlyBlocked; // true = navigated here directly as a screen

  const _AgeGateBody({required this.explicitlyBlocked});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lock icon with neon glow
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DesignTokens.neonRed.withAlpha(20),
                border: Border.all(
                  color: DesignTokens.neonRed.withAlpha(120),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.neonRed.withAlpha(60),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_outline,
                color: DesignTokens.neonRed,
                size: 44,
              ),
            ),
            const SizedBox(height: 32),

            // Heading
            const Text(
              'AGE-RESTRICTED CONTENT',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DesignTokens.neonRed,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.5,
              ),
            ),
            const SizedBox(height: 16),

            // Sub-message
            const Text(
              'This content is available to viewers aged 16 and over.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'DataFightCentral is committed to responsible combat sport '
              'content. Some sections require age verification to access.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 40),

            // Update DOB or go back options
            _ActionButton(
              label: 'UPDATE DATE OF BIRTH',
              icon: Icons.edit_calendar_outlined,
              color: DesignTokens.neonCyan,
              onTap: () => _showDobSheet(context),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                'Go Back',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),

            const SizedBox(height: 40),

            // DFC info link
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: DesignTokens.bgSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white38, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Questions? Contact info@datafightcentral.com',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
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

  void _showDobSheet(BuildContext context) {
    DateTime? picked;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CONFIRM YOUR DATE OF BIRTH',
                style: TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: DesignTokens.neonCyan),
                  foregroundColor: DesignTokens.neonCyan,
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  picked == null
                      ? 'Select Date'
                      : '${picked!.day}/${picked!.month}/${picked!.year}',
                ),
                onPressed: () async {
                  final result = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().subtract(
                      const Duration(days: 365 * 18),
                    ),
                    firstDate: DateTime(1920),
                    lastDate: DateTime.now(),
                    builder: (context, child) => Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: DesignTokens.neonCyan,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (result != null) {
                    setLocal(() => picked = result);
                  }
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.neonCyan,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: picked == null
                    ? null
                    : () async {
                        final auth = context.read<AuthService>();
                        final uid = auth.userModel?.id;
                        if (uid != null) {
                          await FirebaseFirestore.instance
                              .collection(AppConstants.usersCollection)
                              .doc(uid)
                              .update({
                                'dateOfBirth': Timestamp.fromDate(picked!),
                              });
                          await auth.refreshUserProfile();
                        }
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                child: const Text('SAVE & VERIFY'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(180)),
          color: color.withAlpha(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
