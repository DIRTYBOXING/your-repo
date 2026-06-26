import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';

/// Viral Post Template — Browse trending posts and remix them as your own.
/// Users can pick a viral template, customize copy, and publish to their feed.
class ViralPostTemplateScreen extends StatefulWidget {
  const ViralPostTemplateScreen({super.key});

  @override
  State<ViralPostTemplateScreen> createState() =>
      _ViralPostTemplateScreenState();
}

class _ViralPostTemplateScreenState extends State<ViralPostTemplateScreen> {
  String _selectedCategory = 'All';
  final _categories = [
    'All',
    'Fight Hype',
    'Training',
    'Event Promo',
    'Hot Takes',
    'Behind the Scenes',
    'Callouts',
  ];

  final _templates = <_ViralTemplate>[
    const _ViralTemplate(
      title: 'Fight Announcement Hype',
      hook: '🔥 BREAKING: [Fighter A] vs [Fighter B] is OFFICIAL for [Event]!',
      body:
          'This is the fight the fans have been BEGGING for. Two warriors, one cage, zero excuses.\n\nWho you got? Drop your prediction below 👇',
      category: 'Fight Hype',
      engagement: '12.4K avg likes',
      platform: 'All',
    ),
    const _ViralTemplate(
      title: 'Training Montage Caption',
      hook: 'Nobody sees the 5 AM sessions. Nobody sees the tears.',
      body:
          'They only see fight night.\n\nBut this is where champions are made — in the dark, when nobody\'s watching.\n\n💪 [Tag your training partner]',
      category: 'Training',
      engagement: '8.2K avg likes',
      platform: 'Instagram',
    ),
    const _ViralTemplate(
      title: 'Hot Take / Controversy',
      hook:
          'Unpopular opinion: [Fighter] is the most OVERRATED champion in history.',
      body:
          'Here\'s why:\n\n1️⃣ [Reason]\n2️⃣ [Reason]\n3️⃣ [Reason]\n\nChange my mind in the comments 🤷‍♂️',
      category: 'Hot Takes',
      engagement: '22.1K avg likes',
      platform: 'Twitter',
    ),
    const _ViralTemplate(
      title: 'PPV Event Countdown',
      hook: '⏰ [X] DAYS until [Event Name] — and this card is STACKED.',
      body:
          'Main Event: [Fighter A] vs [Fighter B]\nCo-Main: [Fighter C] vs [Fighter D]\n\nThis might be the best card of [Year]. Who else is hyped? 🎟️\n\n#DFC #MMA #PPV',
      category: 'Event Promo',
      engagement: '15.7K avg likes',
      platform: 'All',
    ),
    const _ViralTemplate(
      title: 'Behind the Scenes Access',
      hook:
          'POV: You\'re backstage at [Event] 30 minutes before the main event.',
      body:
          'The energy is ELECTRIC. ⚡\n\nFighters pacing. Coaches whispering. The crowd rumbling through the walls.\n\nThis is what they don\'t show on TV.',
      category: 'Behind the Scenes',
      engagement: '9.8K avg likes',
      platform: 'TikTok',
    ),
    const _ViralTemplate(
      title: 'Fighter Callout',
      hook: 'Hey @[Fighter], I got one question for you...',
      body:
          'You ducking me or what? 🦆\n\nI\'m ranked, I\'m ready, and I\'m coming for that belt.\n\nSign the contract. Let the fans decide. 🥊\n\n#CallOut #LetsGo',
      category: 'Callouts',
      engagement: '31.2K avg likes',
      platform: 'Twitter',
    ),
  ];

  List<_ViralTemplate> get _filtered => _selectedCategory == 'All'
      ? _templates
      : _templates.where((t) => t.category == _selectedCategory).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'Viral Post Templates',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: DesignTokens.neonCyan),
      ),
      body: Column(
        children: [
          // Category chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final selected = _categories[i] == _selectedCategory;
                return ChoiceChip(
                  label: Text(_categories[i]),
                  selected: selected,
                  selectedColor: DesignTokens.neonCyan,
                  backgroundColor: DesignTokens.bgCard,
                  labelStyle: TextStyle(
                    color: selected ? DesignTokens.bgPrimary : Colors.white70,
                    fontSize: 12,
                  ),
                  onSelected: (_) =>
                      setState(() => _selectedCategory = _categories[i]),
                );
              },
            ),
          ),

          // Template list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filtered.length,
              itemBuilder: (context, i) =>
                  _TemplateCard(template: _filtered[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final _ViralTemplate template;

  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Text(
                  template.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  template.platform,
                  style: const TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Hook
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignTokens.neonAmber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: DesignTokens.neonAmber.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              template.hook,
              style: const TextStyle(
                color: DesignTokens.neonAmber,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Body preview
          Text(
            template.body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Footer
          Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 14,
                color: DesignTokens.neonGreen.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
              Text(
                template.engagement,
                style: TextStyle(
                  color: DesignTokens.neonGreen.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              // Copy button
              _ActionChip(
                icon: Icons.copy,
                label: 'Copy',
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: '${template.hook}\n\n${template.body}'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Template copied — paste & customize!'),
                      backgroundColor: DesignTokens.neonCyan,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.edit,
                label: 'Use',
                color: DesignTokens.neonMagenta,
                onTap: () {
                  // Copy to clipboard and show guidance
                  Clipboard.setData(
                    ClipboardData(text: '${template.hook}\n\n${template.body}'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Template copied! Go to Compose Post to customize.',
                      ),
                      backgroundColor: DesignTokens.neonMagenta,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = DesignTokens.neonCyan,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViralTemplate {
  final String title;
  final String hook;
  final String body;
  final String category;
  final String engagement;
  final String platform;

  const _ViralTemplate({
    required this.title,
    required this.hook,
    required this.body,
    required this.category,
    required this.engagement,
    required this.platform,
  });
}
