import 'package:flutter/material.dart';
import '../../../shared/services/social_platform_config_service.dart';

class SocialMediaWidget extends StatelessWidget {
  const SocialMediaWidget({super.key});

  static const _cyan = Color(0xFF00E5FF);
  static const _card = Color(0xFF181848);

  @override
  Widget build(BuildContext context) {
    final fightOrgs = SocialPlatformConfigService.fightOrgs
        .where((o) => o.socials.containsKey('Facebook'))
        .take(6)
        .toList();

    return Container(
      width: 220,
      color: _card,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Official Social',
            style: TextStyle(
              color: _cyan,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          ...fightOrgs.map(
            (org) => _socialLink(
              org.name,
              'https://www.facebook.com/${org.socials['Facebook']}',
              Icons.sports_mma,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Fight Wire',
            style: TextStyle(
              color: _cyan,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          _socialLink(
            'MMA Fighting',
            'https://www.mmafighting.com/',
            Icons.public,
          ),
          _socialLink('Sherdog', 'https://www.sherdog.com/', Icons.public),
          _socialLink('Combat Press', 'https://combatpress.com/', Icons.public),
        ],
      ),
    );
  }

  Widget _socialLink(String label, String url, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () => _launchUrl(url),
        child: Row(
          children: [
            Icon(icon, color: _cyan, size: 22),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchUrl(String url) {
    // URL launcher deferred to url_launcher package integration
  }
}
