import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/cards/dfc_card.dart';
import '../../../core/layout/dfc_layout.dart';
import '../../../core/layout/dfc_padding.dart';

class StripeOnboardingScreen extends StatelessWidget {
  const StripeOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: DfcPadding(
        child: DfcLayout.constrain(
          child: ListView(
            children: [
              const SizedBox(height: 32),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'CREATOR EARNINGS',
                      style: TextStyle(
                        color: Color(0xFFFFD700), // Neon Gold
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              DfcCard(
                height: 220,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance,
                      color: Color(0xFFFFD700),
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'CONNECT YOUR BANK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'DFC uses Stripe Connect to securely route your earnings directly to your bank account. We never hold your funds. You get paid for your real qualities and discipline.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF635BFF), // Stripe blurple
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Redirecting to Stripe Express Onboarding...',
                      ),
                    ),
                  );
                  // TODO: Connect to backend API endpoint generating Stripe Connect onboarding link
                },
                child: const Text(
                  'CONNECT WITH STRIPE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
