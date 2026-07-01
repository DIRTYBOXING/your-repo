import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PRIVACY POLICY — Full Legal Document
/// Route: /privacy-policy
/// ═══════════════════════════════════════════════════════════════════════════
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Row(
          children: [
            Icon(Icons.shield, color: Colors.cyanAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'Privacy Policy',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade900.withValues(alpha: 0.6),
                  const Color(0xFF0A0A20),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.3),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DATAFIGHT CENTRAL',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 10,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Last Updated: March 7, 2026',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _section(
            '1. Introduction',
            'DataFight Central ("DFC", "we", "us", or "our") operates the '
                'datafightcentral.web.app platform and related services. This Privacy '
                'Policy explains how we collect, use, disclose, and safeguard your '
                'information when you visit our platform, including any mobile application '
                'or web service.\n\n'
                'Please read this policy carefully. By using DFC, you agree to the '
                'collection and use of information in accordance with this policy.',
          ),

          _section(
            '2. Information We Collect',
            'Personal Information:\n'
                '• Name, email address, and profile details provided during registration\n'
                '• Fighter profiles, records, and statistics voluntarily submitted\n'
                '• Payment information processed securely via Stripe\n'
                '• Profile photos and media uploaded to the platform\n\n'
                'Automatically Collected Information:\n'
                '• Device type, browser type, operating system\n'
                '• IP address and approximate geographic location\n'
                '• Pages visited, time spent, and navigation patterns\n'
                '• Firebase Analytics data including session duration and feature usage\n\n'
                'Third-Party Information:\n'
                '• Google Sign-In profile data (name, email, profile photo)\n'
                '• Social login data from authorized providers',
          ),

          _section(
            '3. How We Use Your Information',
            '• To provide, maintain, and improve platform services\n'
                '• To process transactions and manage subscriptions via Stripe\n'
                '• To deliver PPV content, live scoring, and fight card features\n'
                '• To personalize your experience including AI-powered predictions\n'
                '• To send notifications about events, features, and platform updates\n'
                '• To analyze platform usage and improve performance\n'
                '• To enforce our Terms of Service and Community Guidelines\n'
                '• To comply with legal obligations and protect user safety',
          ),

          _section(
            '4. Data Sharing & Disclosure',
            'We do not sell your personal information. We may share data with:\n\n'
                '• Service Providers: Firebase (Google), Stripe, and analytics partners '
                'who process data on our behalf under strict agreements\n'
                '• Event Partners: IBC and other combat sports organizations for '
                'co-branded event features (limited to public fighter data)\n'
                '• Legal Requirements: When required by law, court order, or to protect '
                'the rights, safety, or property of DFC or its users\n'
                '• Business Transfers: In connection with a merger, acquisition, or sale '
                'of assets, with notice provided to users',
          ),

          _section(
            '5. Data Storage & Security',
            'Your data is stored securely using Google Firebase infrastructure with:\n\n'
                '• Encryption in transit (TLS/SSL) and at rest\n'
                '• Firebase Authentication for secure account management\n'
                '• Firestore Security Rules enforcing role-based access control\n'
                '• Firebase Storage rules protecting uploaded media\n'
                '• Regular security audits and monitoring\n\n'
                'While we implement industry-standard safeguards, no method of '
                'electronic storage is 100% secure. We cannot guarantee absolute security.',
          ),

          _section(
            '6. Your Rights & Choices',
            '• Access: Request a copy of your personal data at any time\n'
                '• Correction: Update or correct inaccurate information via profile settings\n'
                '• Deletion: Request account deletion through Settings > Privacy\n'
                '• Opt-Out: Manage marketing, analytics, and push notification preferences\n'
                '• Data Portability: Request your data in a portable format\n'
                '• Consent Withdrawal: Revoke previously granted permissions\n\n'
                'For Australian residents: You have rights under the Privacy Act 1988 (Cth) '
                'and the Australian Privacy Principles (APPs). Contact us to exercise these rights.',
          ),

          _section(
            '7. Children\'s Privacy',
            'DFC is not intended for users under 16 years of age. We do not knowingly '
                'collect personal information from children under 16. If we discover that '
                'a child under 16 has provided us with personal information, we will '
                'promptly delete it. If you believe a child has provided information to us, '
                'please contact us immediately.',
          ),

          _section(
            '8. International Data Transfers',
            'DFC is operated from Australia. If you access our platform from outside '
                'Australia, your information may be transferred to and processed in Australia '
                'and other countries where our service providers operate (including the United '
                'States for Firebase/Google services). We ensure appropriate safeguards are '
                'in place for international data transfers.',
          ),

          _section(
            '9. Third-Party Services',
            'Our platform integrates with third-party services including:\n\n'
                '• Google Firebase (Authentication, Firestore, Analytics, Storage)\n'
                '• Stripe (Payment processing)\n'
                '• Google Analytics (Usage analytics)\n'
                '• YouTube (Video content)\n\n'
                'Each service has its own privacy policy. We encourage you to review them.',
          ),

          _section(
            '10. Changes to This Policy',
            'We may update this Privacy Policy from time to time. Changes will be '
                'posted on this page with an updated "Last Updated" date. Continued use '
                'of DFC after changes constitutes acceptance of the revised policy. '
                'For material changes, we will provide prominent notice via platform '
                'notification or email.',
          ),

          _section(
            '11. Contact Us',
            'For privacy-related inquiries or to exercise your rights:\n\n'
                'DataFight Central\n'
                'Email: privacy@datafightcentral.com\n'
                'Platform: datafightcentral.web.app\n'
                'Location: Gold Coast, Queensland, Australia',
          ),

          const SizedBox(height: 16),
          _legalLinks(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legalLinks(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Related Legal Documents',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _linkBtn(
                  context,
                  'Terms of Service',
                  Icons.description_outlined,
                  '/terms-of-service',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _linkBtn(
                  context,
                  'Cookie Policy',
                  Icons.cookie_outlined,
                  '/cookie-policy',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _linkBtn(
    BuildContext context,
    String label,
    IconData icon,
    String route,
  ) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.cyanAccent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.cyanAccent, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
