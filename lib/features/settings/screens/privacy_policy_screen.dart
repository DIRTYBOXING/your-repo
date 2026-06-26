import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';

/// In-app Privacy Policy screen — required by Apple/Google app stores.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: DesignTokens.bgSecondary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _header('DataFightCentral Privacy Policy'),
          _lastUpdated('April 2, 2026'),
          const SizedBox(height: 20),
          _section(
            '1. Information We Collect',
            'We collect information you provide directly:\n\n'
                '• Account information (name, email, date of birth, country)\n'
                '• Profile data (bio, avatar, fight record, gym affiliation)\n'
                '• Content you create (posts, comments, messages, media uploads)\n'
                '• Training and wellness data (if you use those features)\n'
                '• Payment information (processed by Stripe — we never store card numbers)\n'
                '• Device and usage data (analytics, crash reports)',
          ),
          _section(
            '2. How We Use Your Information',
            '• Provide and improve the DFC platform\n'
                '• Personalize your feed and recommendations\n'
                '• Process payments for PPV events and subscriptions\n'
                '• Send notifications about events, messages, and updates\n'
                '• Enforce community standards and moderate content\n'
                '• Comply with legal obligations\n\n'
                'We do NOT sell your personal data to third parties.',
          ),
          _section(
            '3. Data Sharing',
            '• Service providers (Firebase, Stripe, Mux) — under strict data processing agreements\n'
                '• Law enforcement — only when legally required\n'
                '• Other users — only content you choose to make public\n'
                '• Combat sport organizations — only with your explicit consent',
          ),
          _section(
            '4. Your Rights',
            'Under GDPR (EU), Australian Privacy Act, and applicable laws:\n\n'
                '• Access — Request a copy of all your data (Settings → Export Data)\n'
                '• Correction — Edit your profile at any time\n'
                '• Deletion — Delete your account and all data (Settings → Delete Account)\n'
                '• Portability — Export your data in JSON format\n'
                '• Objection — Opt out of analytics tracking in Settings\n'
                '• Restrict processing — Contact us to limit how we use your data',
          ),
          _section(
            '5. Data Retention',
            '• Active accounts: Data retained while account is active\n'
                '• Deleted accounts: All data permanently deleted within 30 days\n'
                '• PPV purchase records: Retained for 7 years (tax/legal requirement)\n'
                '• Audit logs: Retained for 2 years for security purposes\n'
                '• Anonymized analytics: May be retained indefinitely',
          ),
          _section(
            '6. Children & Age Restrictions',
            '• Minimum age: 13 years (16 in Australia)\n'
                '• PPV content: Restricted to users 18 and over\n'
                '• We do not knowingly collect data from children under 13\n'
                '• If we discover an underage account, it will be suspended and data deleted',
          ),
          _section(
            '7. Security',
            '• All data encrypted in transit (TLS 1.3) and at rest\n'
                '• Firebase Authentication with industry-standard security\n'
                '• Content moderation pipeline (automated + human review)\n'
                '• Trust scoring system to protect the community\n'
                '• Regular security audits',
          ),
          _section(
            '8. Cookies & Tracking',
            '• Firebase Analytics — opt-out available in Settings\n'
                '• No third-party advertising trackers\n'
                '• Essential cookies only (authentication, preferences)\n'
                '• No cross-site tracking',
          ),
          _section(
            '9. International Data Transfers',
            'DFC uses Google Cloud (Firebase) infrastructure. Your data may be '
                'processed in data centers outside your country. We rely on '
                'Standard Contractual Clauses and Google\'s compliance certifications '
                'for lawful international transfers.',
          ),
          _section(
            '10. Contact Us',
            'For privacy inquiries or to exercise your rights:\n\n'
                'Email: privacy@datafightcentral.com\n'
                'Website: https://datafightcentral.web.app/privacy\n\n'
                'Complaints may also be directed to the Office of the Australian '
                'Information Commissioner (OAIC) or your local data protection authority.',
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              '© 2026 DataFightCentral. All rights reserved.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _header(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _lastUpdated(String date) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Last updated: $date',
        style: TextStyle(
          color: DesignTokens.neonCyan.withValues(alpha: 0.7),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: DesignTokens.neonCyan,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
