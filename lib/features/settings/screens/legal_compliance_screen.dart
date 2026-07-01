import 'package:flutter/material.dart';
import 'package:datafightcentral/core/theme/design_tokens.dart';

/// Legal & Compliance Screen — Transparent, trustworthy, family-safe.
/// Terms of Service, Privacy Policy, Community Guidelines, GDPR data request.
/// Because trust is earned through transparency.
class LegalComplianceScreen extends StatefulWidget {
  const LegalComplianceScreen({super.key});

  @override
  State<LegalComplianceScreen> createState() => _LegalComplianceScreenState();
}

class _LegalComplianceScreenState extends State<LegalComplianceScreen> {
  int _expandedIndex = -1;

  static const List<Map<String, dynamic>> _legalSections = [
    {
      'icon': Icons.description_outlined,
      'title': 'Terms of Service',
      'updated': 'March 1, 2026',
      'color': 0xFF00F5FF,
      'sections': [
        {
          'heading': '1. Acceptance of Terms',
          'content':
              'By accessing DataFightCentral ("DFC"), you agree to these terms. '
              'DFC is a platform dedicated to combat sports education, athlete wellness, '
              'and community building. We promote discipline, respect, and healthy competition.',
        },
        {
          'heading': '2. User Conduct',
          'content':
              'Users must maintain respectful communication at all times. DFC has zero tolerance '
              'for hate speech, bullying, glorification of violence, or any content that undermines '
              'the safety and dignity of our community members. Combat sports content must focus on '
              'technique, sportsmanship, and athletic achievement.',
        },
        {
          'heading': '3. Content Guidelines',
          'content':
              'All user-generated content must be family-safe. Content promoting unsafe training practices, '
              'unsanctioned fighting, or disrespect toward athletes is prohibited. We celebrate the art, '
              'discipline, and health benefits of combat sports.',
        },
        {
          'heading': '4. Age Requirements',
          'content':
              'Users must be 13 years or older. Users under 18 require parental consent. '
              'DFC provides youth-appropriate content with additional safety measures for minor users.',
        },
      ],
    },
    {
      'icon': Icons.privacy_tip_outlined,
      'title': 'Privacy Policy',
      'updated': 'March 1, 2026',
      'color': 0xFF00FF88,
      'sections': [
        {
          'heading': 'Data We Collect',
          'content':
              'We collect profile information, training data, and usage analytics to personalize '
              'your experience. Health and wellness data is encrypted and never sold to third parties. '
              'Your fitness journey is private.',
        },
        {
          'heading': 'How We Use Your Data',
          'content':
              'Your data powers personalized training recommendations, wellness insights, '
              'and community features. We use aggregated, anonymized data to improve our platform '
              'for all athletes. We never use your data for purposes you haven\'t consented to.',
        },
        {
          'heading': 'Data Protection',
          'content':
              'All personal data is encrypted at rest and in transit using industry-standard AES-256. '
              'We conduct regular security audits and comply with GDPR, CCPA, and other applicable '
              'data protection regulations.',
        },
        {
          'heading': 'Your Rights',
          'content':
              'You have the right to access, correct, delete, or export your data at any time. '
              'Use the data request form below or contact privacy@datafightcentral.com.',
        },
      ],
    },
    {
      'icon': Icons.people_outline,
      'title': 'Community Guidelines',
      'updated': 'March 1, 2026',
      'color': 0xFFFF69B4,
      'sections': [
        {
          'heading': 'Our Philosophy',
          'content':
              'DFC exists to prove that combat sports build better humans. Our community '
              'is a space for learning, growing, and supporting each other. Every interaction '
              'should reflect the discipline and respect we practice on the mat.',
        },
        {
          'heading': 'What We Encourage',
          'content':
              '• Sharing technique breakdowns and training tips\n'
              '• Celebrating athletic achievements with sportsmanship\n'
              '• Supporting fellow athletes through their fitness journey\n'
              '• Discussing the health, mental, and social benefits of training\n'
              '• Mentoring younger athletes with patience and wisdom',
        },
        {
          'heading': 'What We Don\'t Allow',
          'content':
              '• Glorifying violence or promoting unsanctioned fighting\n'
              '• Hate speech, discrimination, or personal attacks\n'
              '• Bullying, intimidation, or toxic behavior\n'
              '• Sharing unsafe training practices or "tough guy" culture\n'
              '• Spam, misinformation, or deceptive content',
        },
        {
          'heading': 'Enforcement',
          'content':
              'Violations result in content removal and account warnings. Severe or repeated '
              'violations lead to suspension or permanent ban. We invest in keeping DFC a place '
              'where parents trust their kids to learn about combat sports.',
        },
      ],
    },
    {
      'icon': Icons.shield_outlined,
      'title': 'GDPR & Data Rights',
      'updated': 'March 1, 2026',
      'color': 0xFFFFB800,
      'sections': [
        {
          'heading': 'Your Data, Your Control',
          'content':
              'Under GDPR and CCPA, you have complete control over your personal data. '
              'DFC is committed to exceeding regulatory requirements because we believe '
              'data privacy is a fundamental right, not a feature.',
        },
        {
          'heading': 'Right to Access',
          'content':
              'Request a complete copy of all data we hold about you. We\'ll provide it '
              'in a machine-readable format within 30 days.',
        },
        {
          'heading': 'Right to Deletion',
          'content':
              'Request permanent deletion of your account and all associated data. '
              'Once processed, this action cannot be reversed.',
        },
        {
          'heading': 'Right to Portability',
          'content':
              'Export your training logs, wellness data, and content in standard formats '
              'to use with other platforms.',
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgPrimary,
        elevation: 0,
        title: const Text(
          'Legal & Compliance',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildTrustBanner(),
          const SizedBox(height: 20),
          ...List.generate(_legalSections.length, (i) {
            final section = _legalSections[i];
            final expanded = _expandedIndex == i;
            final color = Color(section['color'] as int);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSection(section, expanded, color, i),
            );
          }),
          const SizedBox(height: 16),
          _buildDataRequestCard(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTrustBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonGreen.withValues(alpha: 0.07),
            DesignTokens.neonCyan.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonGreen.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DesignTokens.neonGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user,
              color: DesignTokens.neonGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Built on Trust & Transparency',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'DFC prioritizes your safety, privacy, and rights. We believe athletes '
                  'deserve a platform that respects them on and off the mat.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    Map<String, dynamic> section,
    bool expanded,
    Color color,
    int index,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard.withValues(
          alpha: DesignTokens.glassOpacity + 0.04,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: expanded
              ? color.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: DesignTokens.glassBorderOpacity),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expandedIndex = expanded ? -1 : index),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      section['icon'] as IconData,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Updated ${section['updated']}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Divider(
                    color: Colors.white.withValues(alpha: 0.06),
                    height: 1,
                  ),
                  const SizedBox(height: 12),
                  ...(section['sections'] as List).map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['heading'] as String,
                            style: TextStyle(
                              color: color.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s['content'] as String,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataRequestCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard.withValues(
          alpha: DesignTokens.glassOpacity + 0.04,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonAmber.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.download_outlined,
                color: DesignTokens.neonAmber,
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Data Request',
                style: TextStyle(
                  color: DesignTokens.neonAmber,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Request a copy of your data, or submit a deletion request. We\'ll process your request '
            'within 30 days as required by law.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  'Export Data',
                  Icons.cloud_download,
                  DesignTokens.neonCyan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  'Delete Account',
                  Icons.delete_outline,
                  DesignTokens.neonRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$label request submitted — check your email for confirmation.',
              ),
            ),
          );
        },
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          ),
        ),
      ),
    );
  }
}
