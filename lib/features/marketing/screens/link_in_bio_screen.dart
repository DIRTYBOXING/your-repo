import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

/// Link-in-Bio Screen — Smart link page for DFC.
/// Shows primary DFC links + social icons + copy to clipboard.
class LinkInBioScreen extends StatelessWidget {
  const LinkInBioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('LINK-IN-BIO'),
        backgroundColor: AppTheme.cardBackground,
        foregroundColor: AppTheme.neonOrange,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar / Brand
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.neonCyan, AppTheme.neonMagenta],
                ),
              ),
              child: const Icon(
                Icons.sports_mma,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'DATA FIGHT CENTRAL',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'The Combat Sports Intelligence Platform',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 24),

            // Primary links
            ..._primaryLinks.map((link) => _buildLinkCard(context, link)),

            const SizedBox(height: 20),

            // Social icons row
            const Text(
              'FOLLOW US',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _socialLinks
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: GestureDetector(
                        onTap: () => _copyUrl(context, s.url),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: s.color.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Icon(s.icon, color: s.color, size: 20),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),

            // Copy all links
            OutlinedButton.icon(
              onPressed: () {
                final allLinks = _primaryLinks
                    .map((l) => '${l.label}: ${l.url}')
                    .join('\n');
                Clipboard.setData(ClipboardData(text: allLinks));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All links copied!'),
                    backgroundColor: AppTheme.neonGreen,
                  ),
                );
              },
              icon: const Icon(Icons.copy_all),
              label: const Text('COPY ALL LINKS'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.neonCyan,
                side: BorderSide(
                  color: AppTheme.neonCyan.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard(BuildContext context, _BioLink link) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _copyUrl(context, link.url),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: link.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(link.icon, color: link.color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.label,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        link.subtitle,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.copy,
                  color: link.color.withValues(alpha: 0.6),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _copyUrl(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $url'),
        backgroundColor: AppTheme.neonGreen,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

final _primaryLinks = [
  _BioLink(
    label: 'DFC Public Launch Page',
    subtitle: 'Mission, product value, and movement narrative',
    url: AppConstants.launchPageContentUrl,
    icon: Icons.rocket_launch,
    color: AppTheme.neonGreen,
  ),
  _BioLink(
    label: 'Sponsor Tier Matrix',
    subtitle: 'Partnership packages, value, and reporting model',
    url: AppConstants.sponsorTierMatrixUrl,
    icon: Icons.handshake,
    color: AppTheme.neonOrange,
  ),
  _BioLink(
    label: 'Sponsor Pitch Deck',
    subtitle: '12-slide sponsor narrative for partner decision-makers',
    url: AppConstants.sponsorPitchDeckUrl,
    icon: Icons.slideshow,
    color: AppTheme.neonMagenta,
  ),
  _BioLink(
    label: 'Sponsor Outreach Pack',
    subtitle: 'Email + DM sequences + pilot call workflow',
    url: AppConstants.sponsorOutreachPackUrl,
    icon: Icons.outbound,
    color: AppTheme.neonCyan,
  ),
  _BioLink(
    label: 'Grant Application Pack',
    subtitle: 'Google, NVIDIA, Meta, Microsoft application narrative',
    url: AppConstants.grantApplicationPackUrl,
    icon: Icons.request_page,
    color: AppTheme.neonPurple,
  ),
  _BioLink(
    label: 'Grant Submission Calendar',
    subtitle: 'Owner-driven deadlines and 16-week execution cadence',
    url: AppConstants.grantSubmissionCalendarUrl,
    icon: Icons.calendar_month,
    color: AppTheme.neonGreen,
  ),
  _BioLink(
    label: 'Partner Onboarding',
    subtitle: 'How partners launch with DFC, assets, timeline, and KPIs',
    url: AppConstants.partnerOnboardingUrl,
    icon: Icons.handshake_outlined,
    color: AppTheme.neonOrange,
  ),
  _BioLink(
    label: 'Contributor Quickstart',
    subtitle: 'Fast path for developers to clone, run, test, and contribute',
    url: AppConstants.contributorQuickstartUrl,
    icon: Icons.integration_instructions,
    color: AppTheme.neonCyan,
  ),
  _BioLink(
    label: 'DFC Public Roadmap',
    subtitle: 'Transparent delivery plan for sponsors, contributors, and fans',
    url: AppConstants.publicRoadmapUrl,
    icon: Icons.map,
    color: AppTheme.neonPurple,
  ),
  _BioLink(
    label: 'Sponsor DFC',
    subtitle: 'Support DFC through GitHub Sponsors',
    url: AppConstants.sponsorProgramUrl,
    icon: Icons.favorite,
    color: AppTheme.neonMagenta,
  ),
  _BioLink(
    label: 'Open-Source Repository',
    subtitle: 'Source code, issues, and contributor pathway',
    url: AppConstants.publicRepositoryUrl,
    icon: Icons.code,
    color: AppTheme.neonCyan,
  ),
  _BioLink(
    label: 'DataFightCentral App',
    subtitle: 'The full platform experience',
    url: AppConstants.publicWebBaseUrl,
    icon: Icons.sports_mma,
    color: AppTheme.neonCyan,
  ),
  _BioLink(
    label: 'Events',
    subtitle: 'Live fights, tickets & results',
    url: '${AppConstants.publicWebBaseUrl}/events',
    icon: Icons.event,
    color: AppTheme.neonOrange,
  ),
  _BioLink(
    label: 'Marketplace',
    subtitle: 'Gear, services & fighter marketplace',
    url: '${AppConstants.publicWebBaseUrl}/marketplace',
    icon: Icons.storefront,
    color: AppTheme.neonMagenta,
  ),
  _BioLink(
    label: 'FightWire News',
    subtitle: 'Breaking combat sports news',
    url: '${AppConstants.publicWebBaseUrl}/fightwire',
    icon: Icons.newspaper,
    color: AppTheme.neonGreen,
  ),
  _BioLink(
    label: 'For Promoters',
    subtitle: 'Run events, promote fights',
    url: '${AppConstants.publicWebBaseUrl}/promoter',
    icon: Icons.campaign,
    color: AppTheme.neonPurple,
  ),
  _BioLink(
    label: 'For Gyms',
    subtitle: 'Register your gym, train champions',
    url: '${AppConstants.publicWebBaseUrl}/register-gym',
    icon: Icons.fitness_center,
    color: const Color(0xFFFFD700),
  ),
];

final _socialLinks = [
  _SocialIcon(
    icon: Icons.camera_alt,
    url: 'https://instagram.com/DataFightCentral',
    color: AppTheme.neonMagenta,
  ),
  _SocialIcon(
    icon: Icons.facebook,
    url: 'https://facebook.com/DataFightCentral',
    color: const Color(0xFF4267B2),
  ),
  _SocialIcon(
    icon: Icons.tag,
    url: 'https://twitter.com/DataFightCntrl',
    color: AppTheme.neonCyan,
  ),
  _SocialIcon(
    icon: Icons.music_note,
    url: 'https://tiktok.com/@DataFightCentral',
    color: AppTheme.neonGreen,
  ),
  _SocialIcon(
    icon: Icons.play_circle,
    url: 'https://youtube.com/@DataFightCentral',
    color: AppTheme.error,
  ),
];

class _BioLink {
  final String label;
  final String subtitle;
  final String url;
  final IconData icon;
  final Color color;
  _BioLink({
    required this.label,
    required this.subtitle,
    required this.url,
    required this.icon,
    required this.color,
  });
}

class _SocialIcon {
  final IconData icon;
  final String url;
  final Color color;
  _SocialIcon({required this.icon, required this.url, required this.color});
}
