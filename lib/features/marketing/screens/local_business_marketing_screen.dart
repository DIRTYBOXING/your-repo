import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

/// Local Business Marketing toolkit — hyper-local growth tools for gyms,
/// fight promoters, and MMA studios.
class LocalBusinessMarketingScreen extends StatelessWidget {
  const LocalBusinessMarketingScreen({super.key});

  static const _tools = <_LocalTool>[
    _LocalTool(
      title: 'Google Business Profile',
      subtitle: 'Optimize your listing for fight-related searches',
      icon: Icons.business,
      color: DesignTokens.neonCyan,
      tips: [
        'Add "MMA Gym" and "Boxing" as primary categories',
        'Post weekly updates with class schedules & events',
        'Upload high-quality photos of your facility',
        'Respond to every review within 24 hours',
      ],
    ),
    _LocalTool(
      title: 'Local SEO Checklist',
      subtitle: 'Rank higher in "near me" searches',
      icon: Icons.search,
      color: DesignTokens.neonGreen,
      tips: [
        'Claim profiles on Yelp, Facebook, and Apple Maps',
        'Ensure NAP (Name, Address, Phone) is consistent everywhere',
        'Add location-specific keywords to your website',
        'Build backlinks from local sports directories',
      ],
    ),
    _LocalTool(
      title: 'Event Flyer Builder',
      subtitle: 'Create shareable fight night promotions',
      icon: Icons.image,
      color: DesignTokens.neonAmber,
      tips: [
        'Use bold, high-contrast colors for readability',
        'Include date, venue, ticket link, and card highlights',
        'Optimize for Instagram Stories (1080×1920)',
        'Add QR code linking to ticket purchase',
      ],
    ),
    _LocalTool(
      title: 'Neighborhood Targeting',
      subtitle: 'Reach fans within a 10-mile radius',
      icon: Icons.location_on,
      color: DesignTokens.neonRed,
      tips: [
        'Run geo-targeted Facebook/Instagram ads',
        'Partner with local restaurants for cross-promotion',
        'Sponsor community events and youth programs',
        'Distribute flyers at complementary businesses',
      ],
    ),
    _LocalTool(
      title: 'Review Management',
      subtitle: 'Build social proof and trust',
      icon: Icons.star,
      color: DesignTokens.neonGold,
      tips: [
        'Ask satisfied members for Google reviews after class',
        'Create a simple review link and share via SMS',
        'Feature testimonials on your website and social media',
        'Address negative reviews professionally and promptly',
      ],
    ),
    _LocalTool(
      title: 'Referral Program',
      subtitle: 'Turn members into ambassadors',
      icon: Icons.people,
      color: DesignTokens.neonMagenta,
      tips: [
        'Offer a free month for every successful referral',
        'Create shareable referral cards (physical + digital)',
        'Track referrals with unique promo codes',
        'Celebrate top referrers on social media',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'Local Marketing',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: DesignTokens.neonCyan),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tools.length,
        itemBuilder: (context, i) => _ToolCard(tool: _tools[i]),
      ),
    );
  }
}

// ── Tool Card ────────────────────────────────────────────────────────────────

class _ToolCard extends StatefulWidget {
  final _LocalTool tool;
  const _ToolCard({required this.tool});

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard> {
  bool _expanded = false;
  final Set<int> _checkedTips = {};

  @override
  Widget build(BuildContext context) {
    final t = widget.tool;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(
          color: _expanded ? t.color.withValues(alpha: 0.4) : Colors.white10,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: t.color.withValues(alpha: 0.12),
                    child: Icon(t.icon, color: t.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: t.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_checkedTips.length}/${t.tips.length}',
                      style: TextStyle(
                        color: t.color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white24,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Tips
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: List.generate(t.tips.length, (i) {
                  final checked = _checkedTips.contains(i);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (checked) {
                          _checkedTips.remove(i);
                        } else {
                          _checkedTips.add(i);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            checked
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: checked
                                ? DesignTokens.neonGreen
                                : Colors.white24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              t.tips[i],
                              style: TextStyle(
                                color: checked
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                                decoration: checked
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Model ────────────────────────────────────────────────────────────────────

class _LocalTool {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> tips;

  const _LocalTool({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.tips,
  });
}
