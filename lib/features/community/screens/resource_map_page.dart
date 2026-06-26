import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// RESOURCE MAP PAGE — Find gyms, mentors, coffee & shelters near you
/// Navigates to main DFC Gym Map / Mentor Map when user taps "Show Map"
/// ═══════════════════════════════════════════════════════════════════════════
class ResourceMapPage extends StatelessWidget {
  const ResourceMapPage({super.key});

  static const _bg = Color(0xFF030810);
  static const _card = Color(0xFF0A1628);
  static const _cyan = Color(0xFF00E5FF);
  static const _green = Color(0xFF00E676);
  static const _pink = Color(0xFFFF4081);
  static const _amber = Color(0xFFFFD600);
  static const _purple = Color(0xFF9C6FFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg.withValues(alpha: 0.95),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RESOURCE MAP',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'GYMS · MENTORS · SHELTERS · COMMUNITY',
              style: TextStyle(
                fontSize: 7,
                color: Color(0xFF607090),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Hero icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _cyan.withValues(alpha: 0.1),
                border: Border.all(color: _cyan.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.public, color: _cyan, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Find Combat Sports Resources Near You',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'DFC-tagged gyms, Pink Diamond mentors, safe shelters & community hubs — all on the map.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.5),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Action cards
            _resourceCard(
              context,
              '🗺',
              'DFC GYM MAP',
              'Find DFC-tagged gyms worldwide with real logos, tiers & certifications',
              _cyan,
              () => context.push('/map'),
            ),
            const SizedBox(height: 12),
            _resourceCard(
              context,
              '💎',
              'MENTOR MAP',
              'Pink Diamond & Gold Diamond mentors near you — safe spaces',
              _pink,
              () => context.push('/mentor-map'),
            ),
            const SizedBox(height: 12),
            _resourceCard(
              context,
              '🌍',
              'DFC EXPLORE',
              'Global fight news, events & shows geo-tagged to your location',
              _green,
              () => context.push('/google-earth'),
            ),
            const SizedBox(height: 12),
            _resourceCard(
              context,
              '🥊',
              'FIGHT EVENTS',
              'Upcoming fight events & gyms near you this weekend',
              _amber,
              () => context.push('/fight-events'),
            ),
            const SizedBox(height: 12),
            _resourceCard(
              context,
              '🌐',
              'EARTH MAP',
              'FlightRadar24-style world map of DFC fighters & conflict zones',
              _purple,
              () => context.push('/google-earth'),
            ),

            const SizedBox(height: 24),
            // Educational disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _amber.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school, color: _amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For educational & informational purposes only. Resource data is curated by the DFC community.',
                      style: TextStyle(
                        fontSize: 9,
                        color: _amber.withValues(alpha: 0.7),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _resourceCard(
    BuildContext context,
    String emoji,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.45),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color.withValues(alpha: 0.5),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
