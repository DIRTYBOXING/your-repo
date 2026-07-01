import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

/// AI Coach + Training Camp Screen
/// Old-school, tough-love corner energy - gritty, disciplined, supportive
class TrainingCampScreen extends StatefulWidget {
  const TrainingCampScreen({super.key});

  @override
  State<TrainingCampScreen> createState() => _TrainingCampScreenState();
}

class _TrainingCampScreenState extends State<TrainingCampScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      isCoach: true,
      text: "Day 12. You're still here. That matters more than you know.",
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ChatMessage(
      isCoach: true,
      text:
          "Sleep dropped three nights straight. Power follows rest. Fix it tonight.",
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  // Camp data
  final Map<String, dynamic> _campData = {
    'name': '8-Week Fight Camp',
    'day': 12,
    'totalDays': 56,
    'status': 'on_track', // on_track, slipping, falling_behind
    'phase': 'Build',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Camp Status
            _buildCampStatus(),
            const Divider(height: 1, color: AppTheme.surfaceColor),
            // Chat
            Expanded(child: _buildChatList()),
            // Quick Actions
            _buildQuickActions(),
            // Input
            _buildChatInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE17055), Color(0xFFD63031)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sports_mma, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Training Camp',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Your Coach. Your Discipline.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          // Status badge
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final status = _campData['status'] as String;
    Color color;
    String label;

    switch (status) {
      case 'on_track':
        color = AppTheme.neonGreen;
        label = 'ON TRACK';
        break;
      case 'slipping':
        color = Colors.orange;
        label = 'SLIPPING';
        break;
      default:
        color = Colors.red;
        label = 'FALLING BEHIND';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildCampStatus() {
    final day = _campData['day'] as int;
    final total = _campData['totalDays'] as int;
    final progress = day / total;

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.cardBackground,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _campData['name'] as String,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Day $day of $total • ${_campData['phase']} Phase',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.neonCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: AppTheme.neonCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.surfaceColor,
              valueColor: const AlwaysStoppedAnimation(AppTheme.neonCyan),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      reverse: true,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[_messages.length - 1 - index];
        return _buildChatBubble(message);
      },
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Align(
      alignment: message.isCoach ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: message.isCoach
              ? AppTheme.cardBackground
              : AppTheme.neonCyan.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: message.isCoach
              ? Border.all(
                  color: const Color(0xFFE17055).withValues(alpha: 0.3),
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isCoach)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE17055).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.psychology,
                        color: Color(0xFFE17055),
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Coach',
                      style: TextStyle(
                        color: Color(0xFFE17055),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                color: message.isCoach
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildActionChip('Check In', Icons.wb_sunny_outlined, () {
            context.push('/daily-check-in');
          }, highlight: true),
          const SizedBox(width: 8),
          _buildActionChip('Motivate Me', Icons.local_fire_department, () {
            _addCoachMessage(
              "Discipline beats motivation every time. "
              "Motivation is a feeling. Discipline is a decision. "
              "Make the decision.",
            );
          }),
          const SizedBox(width: 8),
          _buildActionChip("I'm Struggling", Icons.support, () {
            _addCoachMessage(
              "Good. That means you're honest. "
              "Struggle isn't weakness — quitting is. "
              "Tell me what's heavy.",
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionChip(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool highlight = false,
  }) {
    return Expanded(
      child: Material(
        color: highlight
            ? AppTheme.neonCyan.withValues(alpha: 0.15)
            : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: highlight
                    ? AppTheme.neonCyan.withValues(alpha: 0.3)
                    : AppTheme.surfaceColor,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: highlight ? AppTheme.neonCyan : AppTheme.neonCyan,
                  size: 18,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: highlight
                        ? AppTheme.neonCyan
                        : AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(top: BorderSide(color: AppTheme.surfaceColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.surfaceColor),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Talk to your coach...',
                    hintStyle: TextStyle(color: AppTheme.textMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.neonCyan, AppTheme.neonMagenta],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(isCoach: false, text: text, timestamp: DateTime.now()),
      );
    });
    _messageController.clear();

    // Get AI coach response via Gemini CF
    _getCoachResponse(text);
  }

  Future<void> _getCoachResponse(String userMessage) async {
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'australia-southeast1',
      ).httpsCallable('generateSocialPost');
      final result = await callable.call<Map<String, dynamic>>({
        'topic': 'Fighter asks: $userMessage',
        'tone': 'motivational_coach',
        'platform': 'training_camp',
      });
      final post = (result.data['post'] as String?) ?? '';
      if (post.isNotEmpty && mounted) {
        _addCoachMessage(post);
        return;
      }
    } catch (_) {
      // Fall through to local fallback
    }
    // Local fallback
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      _addCoachMessage(
        "I hear you. Now let's do something about it. "
        "What's the one thing you can control right now?",
      );
    }
  }

  void _addCoachMessage(String text) {
    setState(() {
      _messages.add(
        ChatMessage(isCoach: true, text: text, timestamp: DateTime.now()),
      );
    });
  }
}

class ChatMessage {
  final bool isCoach;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.isCoach,
    required this.text,
    required this.timestamp,
  });
}
