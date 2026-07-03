import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// COOKIE POLICY — Full Legal Document
/// Route: /cookie-policy
/// ═══════════════════════════════════════════════════════════════════════════
class CookiePolicyScreen extends StatelessWidget {
  const CookiePolicyScreen({super.key});

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
            Icon(Icons.cookie_outlined, color: Colors.cyanAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'Cookie Policy',
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
                  Colors.deepPurple.shade900.withOpacity(0.6),
                  const Color(0xFF0A0A20),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
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
                  'Cookie Policy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Last Updated: July 3, 2026',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _section(
            '1. What Are Cookies?',
            'Cookies are small text files stored on your device (computer, tablet, mobile) when you visit certain websites and applications. They are used to "remember" you and your preferences, either for a single visit (through a "session cookie") or for multiple repeat visits (using a "persistent cookie").',
          ),

          _section(
            '2. How We Use Cookies',
            'Data Fight Central uses cookies for several essential purposes:\n\n'
                '• **Authentication:** We use cookies to identify you when you log in to our service, keeping you signed in as you navigate the platform.\n'
                '• **Preferences:** Cookies are used to store your settings, such as theme preferences, language, and notification settings, so you don’t have to re-configure them on each visit.\n'
                '• **Analytics:** We use Google Analytics, which uses cookies to collect anonymous data about how users interact with our platform. This helps us understand usage patterns and improve our services.\n'
                '• **Security:** Cookies help us enable and support our security features, such as Firebase App Check, and to detect malicious activity and violations of our Terms of Service.',
          ),

          _section(
            '3. Your Choices',
            'Most web browsers automatically accept cookies, but you can usually modify your browser setting to decline cookies if you prefer. However, please note that if you choose to disable cookies, you may not be able to use the full functionality of the Data Fight Central platform, particularly features that require you to be logged in.',
          ),
          
          const SizedBox(height: 20),
          _buildRelatedLinks(context),
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
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedLinks(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Related Documents',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.gavel, color: Colors.cyanAccent),
            title: const Text('Terms of Service', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
            onTap: () => context.go('/terms-of-service'),
          ),
          Divider(color: Colors.white.withOpacity(0.1)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip, color: Colors.cyanAccent),
            title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
            onTap: () => context.go('/privacy-policy'),
          ),
        ],
      ),
    );
  }
}
