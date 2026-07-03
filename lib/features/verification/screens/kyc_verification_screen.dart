import 'package:flutter/material.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/neon_glow_button.dart';

class KycVerificationScreen extends StatelessWidget {
  const KycVerificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('ACCOUNT VERIFICATION', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield, color: Colors.blueAccent, size: 64),
            const SizedBox(height: 16),
            const Text(
              'KEEPING THE PLATFORM 100% REAL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'To keep Data Fight Central free from fakes and scammers, everyone who earns money or creates events on the platform must verify their real-world identity.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Who needs to verify?
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'REQUIRED FOR MONETIZATION:',
                      style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildRequirementRow(Icons.sports_mma, 'Fighters', 'Receiving "Thank You" bonuses & tips'),
                    _buildRequirementRow(Icons.business_center, 'Promoters', 'Selling PPV tickets & event passes'),
                    _buildRequirementRow(Icons.camera_alt, 'Creators', 'Selling subscriptions & premium content'),
                    _buildRequirementRow(Icons.fitness_center, 'Gyms', 'Accepting class bookings & drop-ins'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Verification Steps
            const Text(
              'HOW IT WORKS',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStep(
              step: '1',
              title: 'Government ID',
              description: 'Upload a driver\'s license, passport, or state ID.',
              isDone: false,
            ),
            _buildStep(
              step: '2',
              title: 'Selfie Check',
              description: 'Take a quick 3D face scan to prove you are human.',
              isDone: false,
            ),
            _buildStep(
              step: '3',
              title: 'Bank / Stripe Connect',
              description: 'Link your actual bank account to receive payouts safely.',
              isDone: false,
            ),

            const SizedBox(height: 40),
            NeonGlowButton(
              text: 'Start Verification with Stripe Identity',
              onPressed: () {
                // Launch Stripe Identity Verification Flow
              },
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Data Fight Central does not store your ID on our servers.\nVerification is securely handled by Stripe Identity.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white30, fontSize: 10),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementRow(IconData icon, String role, String reason) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(reason, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStep({required String step, required String title, required String description, required bool isDone}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? Colors.blueAccent : Colors.white10,
            ),
            child: Center(
              child: Text(
                step,
                style: TextStyle(color: isDone ? Colors.white : Colors.white54, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
