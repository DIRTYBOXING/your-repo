import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/widgets/dfc_glass_panel.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// STRIPE CONNECT ONBOARDING
/// The gateway for Promoters and Fighters to link their bank accounts.
/// ═══════════════════════════════════════════════════════════════════════════
class StripeConnectOnboardingScreen extends StatefulWidget {
  const StripeConnectOnboardingScreen({super.key});

  @override
  State<StripeConnectOnboardingScreen> createState() =>
      _StripeConnectOnboardingScreenState();
}

class _StripeConnectOnboardingScreenState
    extends State<StripeConnectOnboardingScreen> {
  bool _isLoading = false;

  Future<void> _startStripeOnboarding() async {
    setState(() => _isLoading = true);

    try {
      // Call your Firebase Function to generate the secure Stripe onboarding link
      final callable = FirebaseFunctions.instance.httpsCallable(
        'createAccountLink',
      );
      final response = await callable.call();

      final url = response.data['url'] as String?;

      if (url != null && url.isNotEmpty) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not launch Stripe portal.');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error connecting to Stripe: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.neonRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().userModel;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'PAYOUT SETUP',
          style: TextStyle(
            color: AppColors.neonGreen,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: DfcGlassPanel(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_balance,
                    color: AppColors.neonGreen,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'GET PAID DIRECTLY TO YOUR BANK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Data Fight Central partners with Stripe for secure, automated payouts. '
                    'Set up your Connect account to receive PPV revenue, sponsorships, and fight purses directly to your bank account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.neonGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock, color: AppColors.neonGreen, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You will be redirected to Stripe to securely verify your identity and enter banking details.',
                            style: TextStyle(
                              color: AppColors.neonGreen,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonGreen,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _isLoading ? null : _startStripeOnboarding,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              'VERIFY & CONNECT BANK',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 1,
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
    );
  }
}
