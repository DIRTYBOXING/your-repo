import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/correspondence_service.dart';

/// Fan Question Submission — Send a message to a fighter.
/// All messages go through moderation before the fighter sees them.
class FanQuestionScreen extends StatefulWidget {
  final String? fighterId;
  final String? fighterName;
  const FanQuestionScreen({super.key, this.fighterId, this.fighterName});

  @override
  State<FanQuestionScreen> createState() => _FanQuestionScreenState();
}

class _FanQuestionScreenState extends State<FanQuestionScreen> {
  final CorrespondenceService _service = CorrespondenceService();
  final TextEditingController _messageController = TextEditingController();
  FanMessageType _selectedType = FanMessageType.question;
  QuestionTopic _selectedTopic = QuestionTopic.general;
  bool _sending = false;
  String? _selectedFighter;
  String? _selectedFighterName;

  // Demo fighters for selection
  static const List<Map<String, String>> _fighters = [
    {'id': 'haze_hepi', 'name': 'Haze Hepi', 'sport': 'BKFC · Heavyweight'},
    {
      'id': 'mark_flanagan',
      'name': 'Mark Flanagan',
      'sport': 'BKFC · Cruiserweight',
    },
    {
      'id': 'sam_soliman',
      'name': 'Sam Soliman',
      'sport': 'BKFC · Middleweight',
    },
    {'id': 'bk_bau', 'name': 'BK Bau', 'sport': 'BKFC · Heavyweight'},
    {
      'id': 'isaac_hardman',
      'name': 'Isaac Hardman',
      'sport': 'IBC · Middleweight',
    },
    {'id': 'corban_mita', 'name': 'Corban Mita', 'sport': 'IBC · Welterweight'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedFighter = widget.fighterId ?? 'haze_hepi';
    _selectedFighterName = widget.fighterName ?? 'Haze Hepi';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'SEND TO FIGHTER',
          style: TextStyle(
            color: DesignTokens.neonCyan,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Safety notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DesignTokens.neonGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DesignTokens.neonGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: DesignTokens.neonGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Messages are moderated before reaching the fighter. '
                      'Be respectful — abusive content will be blocked.',
                      style: TextStyle(
                        color: DesignTokens.neonGreen.withValues(alpha: 0.8),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Fighter selector
            _sectionLabel('CHOOSE FIGHTER'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: DesignTokens.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: _fighters.map((f) {
                  final isSelected = f['id'] == _selectedFighter;
                  return InkWell(
                    onTap: () => setState(() {
                      _selectedFighter = f['id'];
                      _selectedFighterName = f['name'];
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? DesignTokens.neonCyan.withValues(alpha: 0.1)
                            : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isSelected
                                ? DesignTokens.neonCyan.withValues(alpha: 0.3)
                                : Colors.white12,
                            child: Text(
                              f['name']![0],
                              style: TextStyle(
                                color: isSelected
                                    ? DesignTokens.neonCyan
                                    : Colors.white54,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f['name']!,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white70,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  f['sport']!,
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: DesignTokens.neonCyan,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Message type selector
            _sectionLabel('MESSAGE TYPE'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FanMessageType.values.map((type) {
                final isSelected = type == _selectedType;
                final icon = switch (type) {
                  FanMessageType.question => Icons.help_outline,
                  FanMessageType.support => Icons.favorite_outline,
                  FanMessageType.shoutout => Icons.campaign_outlined,
                  FanMessageType.reaction =>
                    Icons.local_fire_department_outlined,
                };
                final color = switch (type) {
                  FanMessageType.question => DesignTokens.neonCyan,
                  FanMessageType.support => DesignTokens.neonGreen,
                  FanMessageType.shoutout => DesignTokens.neonGold,
                  FanMessageType.reaction => DesignTokens.neonRed,
                };
                final label = switch (type) {
                  FanMessageType.question => 'Question',
                  FanMessageType.support => 'Support',
                  FanMessageType.shoutout => 'Shoutout',
                  FanMessageType.reaction => 'Reaction',
                };
                return ChoiceChip(
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedType = type),
                  avatar: Icon(
                    icon,
                    color: isSelected ? Colors.black : color,
                    size: 16,
                  ),
                  label: Text(label),
                  selectedColor: color,
                  backgroundColor: DesignTokens.bgCard,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  side: BorderSide(color: color.withValues(alpha: 0.3)),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Topic selector
            _sectionLabel('TOPIC'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: QuestionTopic.values.map((topic) {
                final isSelected = topic == _selectedTopic;
                final label = switch (topic) {
                  QuestionTopic.general => 'General',
                  QuestionTopic.fightPrep => 'Fight Prep',
                  QuestionTopic.lifestyle => 'Lifestyle',
                  QuestionTopic.advice => 'Advice',
                  QuestionTopic.shoutout => 'Shoutout',
                  QuestionTopic.event => 'Event',
                  QuestionTopic.career => 'Career',
                };
                return ChoiceChip(
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedTopic = topic),
                  label: Text(label),
                  selectedColor: DesignTokens.neonMagenta,
                  backgroundColor: DesignTokens.bgCard,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : DesignTokens.neonMagenta,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: DesignTokens.neonMagenta.withValues(alpha: 0.3),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Message input
            _sectionLabel('YOUR MESSAGE'),
            const SizedBox(height: 10),
            TextField(
              controller: _messageController,
              maxLines: 5,
              maxLength: 500,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: _getPlaceholder(),
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                filled: true,
                fillColor: DesignTokens.bgCard,
                counterStyle: const TextStyle(color: Colors.white38),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: DesignTokens.neonCyan),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Popular questions
            _sectionLabel('POPULAR QUESTIONS FANS ARE ASKING'),
            const SizedBox(height: 10),
            ..._buildPopularQuestions(),

            const SizedBox(height: 24),

            // Vote section
            _sectionLabel(
              'VOTE ON WHICH QUESTION ${_selectedFighterName?.toUpperCase() ?? "HEPI"} SHOULD ANSWER',
            ),
            const SizedBox(height: 10),
            _buildVoteSection(),

            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _sending ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.neonCyan,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.white12,
                ),
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'SUBMIT MESSAGE',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.5,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Your message will be reviewed before delivery',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white54,
        fontWeight: FontWeight.w800,
        fontSize: 11,
        letterSpacing: 1.5,
      ),
    );
  }

  String _getPlaceholder() {
    return switch (_selectedType) {
      FanMessageType.question =>
        'Ask ${_selectedFighterName ?? "the fighter"} a question...',
      FanMessageType.support => 'Send words of encouragement...',
      FanMessageType.shoutout => 'Request a shoutout (name, occasion)...',
      FanMessageType.reaction => 'Share your reaction to a fight or post...',
    };
  }

  List<Widget> _buildPopularQuestions() {
    final questions = [
      'What\'s your game plan for April 18?',
      'What does representing the Pacific Islands mean to you?',
      'How has bare knuckle changed you as a fighter?',
      'What advice do you have for young fighters?',
    ];
    return questions.map((q) {
      return InkWell(
        onTap: () {
          _messageController.text = q;
          setState(() => _selectedType = FanMessageType.question);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white38,
                size: 14,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  q,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white24,
                size: 12,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildVoteSection() {
    final votes = [
      {'q': 'What does Logan mean to you?', 'votes': 1245, 'answered': true},
      {'q': 'How do you beat Wisniewski?', 'votes': 567, 'answered': true},
      {
        'q': 'Can you give a shoutout to fans in Townsville?',
        'votes': 342,
        'answered': false,
      },
      {
        'q': 'What\'s your walk-out song going to be?',
        'votes': 298,
        'answered': false,
      },
    ];
    return Column(
      children: votes.map((v) {
        final answered = v['answered'] as bool;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: answered
                  ? DesignTokens.neonGreen.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  const Icon(
                    Icons.arrow_upward,
                    color: DesignTokens.neonAmber,
                    size: 16,
                  ),
                  Text(
                    '${v['votes']}',
                    style: const TextStyle(
                      color: DesignTokens.neonAmber,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${v['q']}',
                  style: TextStyle(
                    color: answered ? Colors.white70 : Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ),
              if (answered)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ANSWERED',
                    style: TextStyle(
                      color: DesignTokens.neonGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _handleSubmit() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a message'),
          backgroundColor: DesignTokens.neonRed,
        ),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await _service.submitMessage(
        fighterId: _selectedFighter ?? 'haze_hepi',
        fighterName: _selectedFighterName ?? 'Haze Hepi',
        content: content,
        type: _selectedType,
        topic: _selectedTopic,
      );
      if (mounted) {
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your question is under review. Approved questions may be answered publicly.',
            ),
            backgroundColor: DesignTokens.neonGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: DesignTokens.neonAmber,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
