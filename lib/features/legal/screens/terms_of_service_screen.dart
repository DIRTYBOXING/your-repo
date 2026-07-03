import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// TERMS OF SERVICE — Full Legal Document
/// Route: /terms-of-service
/// ═══════════════════════════════════════════════════════════════════════════
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
            Icon(
              Icons.description_outlined,
              color: Colors.cyanAccent,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Terms of Service',
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
                  'Terms of Service',
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
            '1. Acceptance of Terms',
            'By accessing or using DataFight Central ("DFC", "the Platform"), '
                'located at datafightcentral.web.app, you agree to be bound by these '
                'Terms of Service ("Terms"). If you do not agree to these Terms, you '
                'must not use the Platform.\n\n'
                'DFC reserves the right to modify these Terms at any time. Continued '
                'use of the Platform following any changes constitutes acceptance of '
                'those changes. We will provide notice of material changes via '
                'platform notification or email.',
          ),

          _section(
            '2. Description of Service',
            'DataFight Central is a digital platform for combat sports fans, '
                'fighters, coaches, promoters, and media. The Platform provides:\n\n'
                '• Fight cards, live scoring, rankings, and event coverage\n'
                '• Pay-per-view (PPV) streaming and event access\n'
                '• Fighter profiles, statistics, and analytics\n'
                '• Social features, community engagement, and fan interaction\n'
                '• AI-powered predictions and content\n'
                '• News, press, and media distribution\n'
                '• Marketplace and promotional features\n\n'
                'DFC partners with combat sports organisations including the '
                'International Brawling Championship (IBC) to deliver co-branded '
                'content and event coverage. Partnership content is clearly marked '
                'with the DFC × Partner badge.',
          ),

          _section(
            '3. User Accounts',
            '• You must be at least 16 years old to create an account\n'
                '• You are responsible for maintaining the confidentiality of your '
                'account credentials\n'
                '• You are responsible for all activity that occurs under your account\n'
                '• You must provide accurate, current, and complete information during '
                'registration\n'
                '• You must not create accounts for fraudulent purposes or impersonate '
                'any person or entity\n'
                '• DFC reserves the right to suspend or terminate accounts that violate '
                'these Terms or our Community Guidelines',
          ),

          _section(
            '4. User Content & Conduct',
            'You may post content including comments, social posts, predictions, '
                'and media. By posting content, you:\n\n'
                '• Grant DFC a non-exclusive, worldwide, royalty-free licence to use, '
                'display, and distribute your content on the Platform\n'
                '• Represent that you own or have the right to share the content\n'
                '• Agree not to post content that is illegal, defamatory, harassing, '
                'threatening, or violates any third-party rights\n\n'
                'Prohibited conduct includes:\n'
                '• Harassment, bullying, or targeted abuse of any user\n'
                '• Posting violence, hate speech, or discriminatory content\n'
                '• Spam, phishing, or distributing malware\n'
                '• Attempting to access other users\' accounts or data\n'
                '• Scraping, data mining, or automated access without permission\n'
                '• Circumventing security measures, access controls, or paywalls\n'
                '• Impersonating fighters, coaches, promoters, or DFC staff',
          ),

          _section(
            '5. Payments & Subscriptions',
            'Certain features require payment, including PPV events and premium '
                'subscriptions. All payments are processed securely through Stripe.\n\n'
                '• Prices are displayed in Australian Dollars (AUD) unless otherwise stated\n'
                '• PPV purchases are for single-event access and are non-transferable\n'
                '• Subscription billing occurs on a recurring basis as specified at '
                'time of purchase\n'
                '• You may cancel subscriptions at any time through your account settings\n'
                '• Refund requests for PPV events must be made before the event starts; '
                'no refunds are available once streaming begins\n'
                '• DFC reserves the right to modify pricing with reasonable notice\n\n'
                'Stripe handles all payment processing. DFC does not store credit card '
                'numbers or sensitive payment information on its servers.',
          ),

          _section(
            '6. Intellectual Property',
            'The Platform, including its design, code, logos, content, and the '
                '"DataFight Central" name, is owned by DFC and protected by copyright, '
                'trademark, and other intellectual property laws.\n\n'
                '• You may not copy, modify, distribute, or create derivative works '
                'from any DFC content without written permission\n'
                '• Fighter data, statistics, and analytics presented on DFC are compiled '
                'from publicly available sources and proprietary analysis\n'
                '• Partner logos and trademarks (including IBC, TrillerTV, Kayo Sports, '
                'Fox Sports, RVCA) belong to their respective owners and are used under '
                'partnership or editorial fair use\n'
                '• User-generated content remains the property of the creator, subject '
                'to the licence granted in Section 4',
          ),

          _section(
            '7. Cookies and Tracking Technologies',
            'DFC uses cookies and similar tracking technologies to operate and improve '
                'the Platform. This includes cookies for authentication, security, '
                'preferences, and analytics. By using the Platform, you consent to '
                'the use of these technologies as described in our Cookie Policy.\n\n'
                'For detailed information on the types of cookies we use and how to '
                'manage your preferences, please review our full Cookie Policy.',
          ),

          _section(
            '8. Third-Party Content & Links',
            'DFC may contain links to third-party websites, services, and content '
                'including:\n\n'
                '• Streaming platforms (TrillerTV+, Kayo Sports, Amazon Prime Video)\n'
                '• Ticketing services (Eventbrite)\n'
                '• Social media platforms\n'
                '• External news articles and media\n\n'
                'DFC is not responsible for the content, accuracy, or practices of '
                'third-party services. Accessing third-party links is at your own risk '
                'and subject to those services\' terms and policies.',
          ),

          _section(
            '9. AI-Generated Content',
            'DFC uses artificial intelligence to generate predictions, content '
                'suggestions, and analytics. AI-generated content:\n\n'
                '• Is provided for entertainment and informational purposes only\n'
                '• Should not be relied upon for gambling, financial, or medical decisions\n'
                '• May not always be accurate or up-to-date\n'
                '• Is clearly labelled as AI-generated where applicable\n\n'
                'DFC makes no warranty as to the accuracy of AI predictions or '
                'AI-generated content.',
          ),

          _section(
            '10. Combat Sports Disclaimer',
            'DFC provides coverage of combat sports events. By using the Platform:\n\n'
                '• You acknowledge that combat sports involve inherent risks of injury\n'
                '• Content may include depictions of physical contact and fighting that '
                'some viewers may find confronting\n'
                '• DFC is a media and technology platform — we do not promote, organise, '
                'or sanction fights (event promotion is handled by partner organisations '
                'such as IBC)\n'
                '• Event data, fight cards, and results are sourced from official '
                'promoters and verified public records\n'
                '• DFC is not liable for the actions of fighters, promoters, or '
                'event organisers',
          ),

          _section(
            '11. Limitation of Liability',
            'To the maximum extent permitted by Australian law:\n\n'
                '• DFC is provided "as is" without warranties of any kind, express '
                'or implied\n'
                '• DFC does not guarantee uninterrupted, secure, or error-free service\n'
                '• DFC is not liable for any indirect, incidental, special, '
                'consequential, or punitive damages arising from your use of the Platform\n'
                '• DFC\'s total liability shall not exceed the amount you paid to DFC '
                'in the 12 months preceding the claim\n\n'
                'Nothing in these Terms excludes or limits liability that cannot be '
                'excluded or limited under the Australian Consumer Law (Schedule 2 of '
                'the Competition and Consumer Act 2010).',
          ),

          _section(
            '12. Indemnification',
            'You agree to indemnify and hold harmless DFC, its officers, directors, '
                'employees, and partners from any claims, losses, damages, liabilities, '
                'and expenses (including legal fees) arising from:\n\n'
                '• Your use of the Platform\n'
                '• Your violation of these Terms\n'
                '• Your violation of any third-party rights\n'
                '• Content you post or share on the Platform',
          ),

          _section(
            '13. Termination',
            'DFC may suspend or terminate your account at any time for:\n\n'
                '• Violation of these Terms or Community Guidelines\n'
                '• Fraudulent, abusive, or illegal activity\n'
                '• Extended inactivity (with prior notice)\n'
                '• At DFC\'s sole discretion with reasonable notice\n\n'
                'Upon termination, your right to use the Platform ceases immediately. '
                'Sections regarding intellectual property, limitation of liability, '
                'indemnification, and governing law survive termination.',
          ),

          _section(
            '14. Copyright & DMCA Takedown Policy',
            'DFC respects intellectual property rights and complies with the '
                'Australian Copyright Act 1968, the US Digital Millennium Copyright '
                'Act (DMCA), and applicable international treaties.\n\n'
                'USER-UPLOADED CONTENT\n'
                '• Users are solely responsible for ensuring they have the right to '
                'share any content they upload, including images, posters, logos, and '
                'fight media.\n'
                '• By uploading content, users confirm they own it or have permission '
                'from the rights holder (see Section 4).\n'
                '• DFC acts as a platform host and is not liable for user-uploaded '
                'content that infringes third-party rights.\n\n'
                'EDITORIAL & AGGREGATED CONTENT\n'
                '• Event information (dates, venues, fight cards, results) is sourced '
                'from publicly available records and presented under fair dealing for '
                'news reporting and commentary.\n'
                '• Where DFC displays promotional materials provided by partner '
                'promoters, these are used under licence or with written permission.\n'
                '• Typographic (text-only) event posters are original DFC works and do '
                'not incorporate third-party copyrighted material.\n\n'
                'HOW TO FILE A TAKEDOWN NOTICE\n'
                'If you believe content on DFC infringes your copyright, send a written '
                'notice to legal@datafightcentral.com containing:\n\n'
                '1. Your name and contact information\n'
                '2. A description of the copyrighted work you claim is infringed\n'
                '3. The URL or location of the infringing content on DFC\n'
                '4. A statement that you have a good-faith belief the use is not '
                'authorised by the copyright owner\n'
                '5. A statement, under penalty of perjury, that the information in '
                'the notice is accurate and you are authorised to act on behalf of '
                'the copyright owner\n'
                '6. Your physical or electronic signature\n\n'
                'DFC RESPONSE\n'
                '• We will acknowledge receipt within 2 business days\n'
                '• Infringing content will be removed or disabled within 3 business '
                'days of receiving a valid notice\n'
                '• The uploader will be notified and may file a counter-notice\n'
                '• Repeat infringers will have their accounts suspended or terminated\n\n'
                'COUNTER-NOTICE\n'
                'If you believe your content was removed in error, you may send a '
                'counter-notice to legal@datafightcentral.com with:\n'
                '1. Your name and contact information\n'
                '2. Identification of the removed content and its prior location\n'
                '3. A statement under penalty of perjury that the content was removed '
                'by mistake or misidentification\n'
                '4. Consent to the jurisdiction of the courts of Queensland, Australia\n'
                '5. Your physical or electronic signature\n\n'
                'Content will be restored within 10-14 business days unless the '
                'complainant files a court action.',
          ),

          _section(
            '15. Governing Law',
            'These Terms are governed by and construed in accordance with the '
                'laws of Queensland, Australia. Any disputes arising from these Terms '
                'or your use of the Platform shall be subject to the exclusive '
                'jurisdiction of the courts of Queensland.\n\n'
                'If any provision of these Terms is found to be unenforceable, the '
                'remaining provisions shall continue in full force and effect.',
          ),

          _section(
            '16. Contact',
            'For questions about these Terms of Service:\n\n'
                'DataFight Central\n'
                'Email: legal@datafightcentral.com\n'
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
              color: Colors.white.withOpacity(0.7),
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
        color: Colors.white.withOpacity(0.04),
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
                  'Privacy Policy',
                  Icons.shield_outlined,
                  '/privacy-policy',
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
          color: Colors.cyanAccent.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.15)),
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
                '• Partner logos and trademarks (including IBC, TrillerTV, Kayo Sports, '
                'Fox Sports, RVCA) belong to their respective owners and are used under '
                'partnership or editorial fair use\n'
                '• User-generated content remains the property of the creator, subject '
                'to the licence granted in Section 4',
          ),

          _section(
            '7. Third-Party Content & Links',
            'DFC may contain links to third-party websites, services, and content '
                'including:\n\n'
                '• Streaming platforms (TrillerTV+, Kayo Sports, Amazon Prime Video)\n'
                '• Ticketing services (Eventbrite)\n'
                '• Social media platforms\n'
                '• External news articles and media\n\n'
                'DFC is not responsible for the content, accuracy, or practices of '
                'third-party services. Accessing third-party links is at your own risk '
                'and subject to those services\' terms and policies.',
          ),

          _section(
            '8. AI-Generated Content',
            'DFC uses artificial intelligence to generate predictions, content '
                'suggestions, and analytics. AI-generated content:\n\n'
                '• Is provided for entertainment and informational purposes only\n'
                '• Should not be relied upon for gambling, financial, or medical decisions\n'
                '• May not always be accurate or up-to-date\n'
                '• Is clearly labelled as AI-generated where applicable\n\n'
                'DFC makes no warranty as to the accuracy of AI predictions or '
                'AI-generated content.',
          ),

          _section(
            '9. Combat Sports Disclaimer',
            'DFC provides coverage of combat sports events. By using the Platform:\n\n'
                '• You acknowledge that combat sports involve inherent risks of injury\n'
                '• Content may include depictions of physical contact and fighting that '
                'some viewers may find confronting\n'
                '• DFC is a media and technology platform — we do not promote, organise, '
                'or sanction fights (event promotion is handled by partner organisations '
                'such as IBC)\n'
                '• Event data, fight cards, and results are sourced from official '
                'promoters and verified public records\n'
                '• DFC is not liable for the actions of fighters, promoters, or '
                'event organisers',
          ),

          _section(
            '10. Limitation of Liability',
            'To the maximum extent permitted by Australian law:\n\n'
                '• DFC is provided "as is" without warranties of any kind, express '
                'or implied\n'
                '• DFC does not guarantee uninterrupted, secure, or error-free service\n'
                '• DFC is not liable for any indirect, incidental, special, '
                'consequential, or punitive damages arising from your use of the Platform\n'
                '• DFC\'s total liability shall not exceed the amount you paid to DFC '
                'in the 12 months preceding the claim\n\n'
                'Nothing in these Terms excludes or limits liability that cannot be '
                'excluded or limited under the Australian Consumer Law (Schedule 2 of '
                'the Competition and Consumer Act 2010).',
          ),

          _section(
            '11. Indemnification',
            'You agree to indemnify and hold harmless DFC, its officers, directors, '
                'employees, and partners from any claims, losses, damages, liabilities, '
                'and expenses (including legal fees) arising from:\n\n'
                '• Your use of the Platform\n'
                '• Your violation of these Terms\n'
                '• Your violation of any third-party rights\n'
                '• Content you post or share on the Platform',
          ),

          _section(
            '12. Termination',
            'DFC may suspend or terminate your account at any time for:\n\n'
                '• Violation of these Terms or Community Guidelines\n'
                '• Fraudulent, abusive, or illegal activity\n'
                '• Extended inactivity (with prior notice)\n'
                '• At DFC\'s sole discretion with reasonable notice\n\n'
                'Upon termination, your right to use the Platform ceases immediately. '
                'Sections regarding intellectual property, limitation of liability, '
                'indemnification, and governing law survive termination.',
          ),

          _section(
            '13. Copyright & DMCA Takedown Policy',
            'DFC respects intellectual property rights and complies with the '
                'Australian Copyright Act 1968, the US Digital Millennium Copyright '
                'Act (DMCA), and applicable international treaties.\n\n'
                'USER-UPLOADED CONTENT\n'
                '• Users are solely responsible for ensuring they have the right to '
                'share any content they upload, including images, posters, logos, and '
                'fight media.\n'
                '• By uploading content, users confirm they own it or have permission '
                'from the rights holder (see Section 4).\n'
                '• DFC acts as a platform host and is not liable for user-uploaded '
                'content that infringes third-party rights.\n\n'
                'EDITORIAL & AGGREGATED CONTENT\n'
                '• Event information (dates, venues, fight cards, results) is sourced '
                'from publicly available records and presented under fair dealing for '
                'news reporting and commentary.\n'
                '• Where DFC displays promotional materials provided by partner '
                'promoters, these are used under licence or with written permission.\n'
                '• Typographic (text-only) event posters are original DFC works and do '
                'not incorporate third-party copyrighted material.\n\n'
                'HOW TO FILE A TAKEDOWN NOTICE\n'
                'If you believe content on DFC infringes your copyright, send a written '
                'notice to legal@datafightcentral.com containing:\n\n'
                '1. Your name and contact information\n'
                '2. A description of the copyrighted work you claim is infringed\n'
                '3. The URL or location of the infringing content on DFC\n'
                '4. A statement that you have a good-faith belief the use is not '
                'authorised by the copyright owner\n'
                '5. A statement, under penalty of perjury, that the information in '
                'the notice is accurate and you are authorised to act on behalf of '
                'the copyright owner\n'
                '6. Your physical or electronic signature\n\n'
                'DFC RESPONSE\n'
                '• We will acknowledge receipt within 2 business days\n'
                '• Infringing content will be removed or disabled within 3 business '
                'days of receiving a valid notice\n'
                '• The uploader will be notified and may file a counter-notice\n'
                '• Repeat infringers will have their accounts suspended or terminated\n\n'
                'COUNTER-NOTICE\n'
                'If you believe your content was removed in error, you may send a '
                'counter-notice to legal@datafightcentral.com with:\n'
                '1. Your name and contact information\n'
                '2. Identification of the removed content and its prior location\n'
                '3. A statement under penalty of perjury that the content was removed '
                'by mistake or misidentification\n'
                '4. Consent to the jurisdiction of the courts of Queensland, Australia\n'
                '5. Your physical or electronic signature\n\n'
                'Content will be restored within 10-14 business days unless the '
                'complainant files a court action.',
          ),

          _section(
            '14. Governing Law',
            'These Terms are governed by and construed in accordance with the '
                'laws of Queensland, Australia. Any disputes arising from these Terms '
                'or your use of the Platform shall be subject to the exclusive '
                'jurisdiction of the courts of Queensland.\n\n'
                'If any provision of these Terms is found to be unenforceable, the '
                'remaining provisions shall continue in full force and effect.',
          ),

          _section(
            '15. Contact',
            'For questions about these Terms of Service:\n\n'
                'DataFight Central\n'
                'Email: legal@datafightcentral.com\n'
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
                  'Privacy Policy',
                  Icons.shield_outlined,
                  '/privacy-policy',
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
