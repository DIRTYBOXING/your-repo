import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/auth_service.dart';

/// Wraps PPV content with an 18+ age verification check.
/// Checks the user's dateOfBirth from their profile.
/// If under 18, shows a restriction screen instead of the content.
class PpvAgeGate extends StatelessWidget {
  final Widget child;
  final String? eventTitle;

  const PpvAgeGate({super.key, required this.child, this.eventTitle});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.userModel;

    // Demo/guest mode — allow access (no real purchases possible)
    if (auth.isDemoUser || user == null) {
      return child;
    }

    final dob = user.dateOfBirth;
    if (dob == null) {
      // No DOB on file — prompt them to add it
      return _AgeVerificationRequired(eventTitle: eventTitle);
    }

    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }

    if (age < 18) {
      return _UnderageRestriction(age: age);
    }

    return child;
  }
}

/// Shown when user has no DOB on file
class _AgeVerificationRequired extends StatelessWidget {
  final String? eventTitle;

  const _AgeVerificationRequired({this.eventTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DesignTokens.neonAmber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DesignTokens.neonAmber.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: DesignTokens.neonAmber,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Age Verification Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pay-Per-View content requires age verification.\n'
                'Please update your profile with your date of birth to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 220,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/profile/edit'),
                  icon: const Icon(Icons.person, size: 18),
                  label: const Text('Update Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.neonAmber.withValues(
                      alpha: 0.2,
                    ),
                    foregroundColor: DesignTokens.neonAmber,
                    side: BorderSide(
                      color: DesignTokens.neonAmber.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Go Back',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when user is confirmed under 18
class _UnderageRestriction extends StatelessWidget {
  final int age;

  const _UnderageRestriction({required this.age});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DesignTokens.neonRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DesignTokens.neonRed.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.no_accounts,
                  color: DesignTokens.neonRed,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Age Restricted Content',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pay-Per-View events are restricted to users aged 18 and over.\n\n'
                'This content includes live combat sports that may not be '
                'suitable for viewers under 18.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Go Back',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
