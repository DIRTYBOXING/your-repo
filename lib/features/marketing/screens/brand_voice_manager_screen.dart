import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

/// Multi Brand Voice Manager — Create, switch, and manage distinct brand
/// voice profiles for AI content generation.
class BrandVoiceManagerScreen extends StatefulWidget {
  const BrandVoiceManagerScreen({super.key});

  @override
  State<BrandVoiceManagerScreen> createState() =>
      _BrandVoiceManagerScreenState();
}

class _BrandVoiceManagerScreenState extends State<BrandVoiceManagerScreen> {
  final _voices = <BrandVoice>[
    BrandVoice(
      id: '1',
      name: 'Fighter Persona',
      tone: 'Aggressive & Confident',
      description:
          'Bold, in-your-face content. Short punchy sentences. '
          'Heavy use of combat metaphors and call-to-action.',
      samplePhrase: 'I didn\'t come to participate. I came to dominate.',
      icon: Icons.sports_mma,
      color: DesignTokens.neonRed,
      isActive: true,
    ),
    BrandVoice(
      id: '2',
      name: 'Promoter Professional',
      tone: 'Hype & Business',
      description:
          'Event promotion energy with professional credibility. '
          'Builds urgency, sells tickets, creates FOMO.',
      samplePhrase: 'This card is STACKED. Limited seats. Don\'t miss history.',
      icon: Icons.campaign,
      color: DesignTokens.neonAmber,
    ),
    BrandVoice(
      id: '3',
      name: 'Coach / Mentor',
      tone: 'Motivational & Educational',
      description:
          'Wisdom-driven content that teaches and inspires. '
          'Longer form, technique breakdowns, athlete development.',
      samplePhrase:
          'Champions aren\'t born in the ring. They\'re forged in the gym.',
      icon: Icons.school,
      color: DesignTokens.neonGreen,
    ),
    BrandVoice(
      id: '4',
      name: 'Media / Analyst',
      tone: 'Objective & Insightful',
      description:
          'Data-driven fight analysis. Statistical breakdowns, '
          'fight predictions, and expert commentary.',
      samplePhrase:
          'The numbers don\'t lie — 78% takedown defense against elite wrestlers.',
      icon: Icons.analytics,
      color: DesignTokens.neonCyan,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'Brand Voices',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: DesignTokens.neonCyan),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: DesignTokens.neonCyan),
            tooltip: 'Create Voice',
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _voices.length,
        itemBuilder: (context, i) => _VoiceCard(
          voice: _voices[i],
          onActivate: () {
            setState(() {
              for (var v in _voices) {
                v.isActive = false;
              }
              _voices[i].isActive = true;
            });
          },
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final toneCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final sampleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'New Brand Voice',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(nameCtrl, 'Voice Name', 'e.g. Fight Camp Guru'),
              const SizedBox(height: 12),
              _dialogField(toneCtrl, 'Tone', 'e.g. Energetic & Fun'),
              const SizedBox(height: 12),
              _dialogField(
                descCtrl,
                'Description',
                'Describe the style and personality...',
              ),
              const SizedBox(height: 12),
              _dialogField(
                sampleCtrl,
                'Sample Phrase',
                'Write a phrase in this voice',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.neonCyan,
              foregroundColor: DesignTokens.bgPrimary,
            ),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              setState(() {
                _voices.add(
                  BrandVoice(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text.trim(),
                    tone: toneCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    samplePhrase: sampleCtrl.text.trim(),
                    icon: Icons.record_voice_over,
                    color: DesignTokens.neonMagenta,
                  ),
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        filled: true,
        fillColor: DesignTokens.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ── Voice Card ──────────────────────────────────────────────────────────────

class _VoiceCard extends StatelessWidget {
  final BrandVoice voice;
  final VoidCallback onActivate;

  const _VoiceCard({required this.voice, required this.onActivate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(
          color: voice.isActive
              ? voice.color.withValues(alpha: 0.6)
              : Colors.white10,
          width: voice.isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: voice.color.withValues(alpha: 0.15),
                child: Icon(voice.icon, color: voice.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voice.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      voice.tone,
                      style: TextStyle(
                        color: voice.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (voice.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: DesignTokens.neonGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: onActivate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Activate',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            voice.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          if (voice.samplePhrase.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: voice.color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: voice.color.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.format_quote,
                    size: 14,
                    color: voice.color.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      voice.samplePhrase,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Model ────────────────────────────────────────────────────────────────────

class BrandVoice {
  final String id;
  final String name;
  final String tone;
  final String description;
  final String samplePhrase;
  final IconData icon;
  final Color color;
  bool isActive;

  BrandVoice({
    required this.id,
    required this.name,
    required this.tone,
    required this.description,
    required this.samplePhrase,
    required this.icon,
    required this.color,
    this.isActive = false,
  });
}
