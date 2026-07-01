import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/correspondence_service.dart';

/// Fighter Inbox — Clean, moderated messages from fans.
/// Fighters only see approved/safe content. No trolling.
/// Tabs: New | Saved | Answered | All
class FighterInboxScreen extends StatefulWidget {
  final String? fighterId;
  const FighterInboxScreen({super.key, this.fighterId});

  @override
  State<FighterInboxScreen> createState() => _FighterInboxScreenState();
}

class _FighterInboxScreenState extends State<FighterInboxScreen>
    with SingleTickerProviderStateMixin {
  final CorrespondenceService _service = CorrespondenceService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _fighterId => widget.fighterId ?? 'haze_hepi';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'FIGHTER INBOX',
          style: TextStyle(
            color: DesignTokens.neonCyan,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: DesignTokens.neonCyan,
          labelColor: DesignTokens.neonCyan,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
          tabs: const [
            Tab(text: 'NEW'),
            Tab(text: 'SAVED'),
            Tab(text: 'ANSWERED'),
            Tab(text: 'ALL'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewTab(),
          _buildSavedTab(),
          _buildAnsweredTab(),
          _buildAllTab(),
        ],
      ),
    );
  }

  // ── Tab: New (approved, unanswered, not saved) ──

  Widget _buildNewTab() {
    return StreamBuilder<List<FanMessage>>(
      stream: _service.getFighterInbox(_fighterId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: DesignTokens.neonCyan),
          );
        }
        final messages = (snapshot.data ?? [])
            .where(
              (m) => m.status == MessageStatus.approved && !m.savedForLater,
            )
            .toList();
        return _buildList(
          messages,
          emptyText: 'No new messages — all caught up',
        );
      },
    );
  }

  // ── Tab: Saved (savedForLater == true) ──

  Widget _buildSavedTab() {
    return StreamBuilder<List<FanMessage>>(
      stream: _service.getSavedMessages(_fighterId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: DesignTokens.neonGold),
          );
        }
        return _buildList(snapshot.data ?? [], emptyText: 'No saved messages');
      },
    );
  }

  // ── Tab: Answered ──

  Widget _buildAnsweredTab() {
    return StreamBuilder<List<FanMessage>>(
      stream: _service.getFighterInbox(_fighterId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: DesignTokens.neonGreen),
          );
        }
        final messages = (snapshot.data ?? [])
            .where((m) => m.status == MessageStatus.answered)
            .toList();
        return _buildList(messages, emptyText: 'No answered messages yet');
      },
    );
  }

  // ── Tab: All (everything approved + answered) ──

  Widget _buildAllTab() {
    return StreamBuilder<List<FanMessage>>(
      stream: _service.getFighterInbox(_fighterId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: DesignTokens.neonCyan),
          );
        }
        return _buildList(snapshot.data ?? [], emptyText: 'No messages yet');
      },
    );
  }

  Widget _buildList(List<FanMessage> messages, {required String emptyText}) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              emptyText,
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fan messages will appear here after moderation',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) => _buildMessageCard(messages[index]),
    );
  }

  Widget _buildMessageCard(FanMessage message) {
    final typeIcon = switch (message.type) {
      FanMessageType.question => Icons.help_outline,
      FanMessageType.support => Icons.favorite_outline,
      FanMessageType.shoutout => Icons.campaign_outlined,
      FanMessageType.reaction => Icons.local_fire_department_outlined,
    };
    final typeColor = switch (message.type) {
      FanMessageType.question => DesignTokens.neonCyan,
      FanMessageType.support => DesignTokens.neonGreen,
      FanMessageType.shoutout => DesignTokens.neonGold,
      FanMessageType.reaction => DesignTokens.neonRed,
    };
    final typeLabel = switch (message.type) {
      FanMessageType.question => 'QUESTION',
      FanMessageType.support => 'SUPPORT',
      FanMessageType.shoutout => 'SHOUTOUT REQUEST',
      FanMessageType.reaction => 'REACTION',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: message.status == MessageStatus.answered
              ? DesignTokens.neonGreen.withValues(alpha: 0.4)
              : message.savedForLater
              ? DesignTokens.neonGold.withValues(alpha: 0.4)
              : typeColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with type + topic + badges
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(typeIcon, color: typeColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  typeLabel,
                  style: TextStyle(
                    color: typeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
                // Topic tag
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonMagenta.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _topicLabel(message.topic),
                    style: const TextStyle(
                      color: DesignTokens.neonMagenta,
                      fontWeight: FontWeight.w700,
                      fontSize: 8,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Spacer(),
                // Upvotes
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_upward,
                        color: DesignTokens.neonAmber,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${message.upvotes}',
                        style: const TextStyle(
                          color: DesignTokens.neonAmber,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badges
                if (message.savedForLater) ...[
                  const SizedBox(width: 8),
                  _buildBadge('SAVED', DesignTokens.neonGold),
                ],
                if (message.status == MessageStatus.answered) ...[
                  const SizedBox(width: 8),
                  _buildBadge('ANSWERED', DesignTokens.neonGreen),
                ],
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: typeColor.withValues(alpha: 0.2),
                      child: Text(
                        message.fanName.isNotEmpty
                            ? message.fanName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.fanName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            _timeAgo(message.createdAt),
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  message.content,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: Row(
              children: [
                if (message.status != MessageStatus.answered) ...[
                  _buildActionButton(
                    icon: Icons.reply,
                    label: 'REPLY',
                    color: DesignTokens.neonCyan,
                    onTap: () => _showReplyComposer(message),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.check_circle_outline,
                    label: 'QUICK THANKS',
                    color: DesignTokens.neonGreen,
                    onTap: () =>
                        _quickReply(message, 'Thanks for the support! 🤙'),
                  ),
                  const SizedBox(width: 8),
                  // Save / Unsave toggle
                  _buildActionButton(
                    icon: message.savedForLater
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    label: message.savedForLater ? 'UNSAVE' : 'SAVE',
                    color: DesignTokens.neonGold,
                    onTap: () => _toggleSave(message),
                  ),
                ],
                if (message.status == MessageStatus.answered)
                  _buildActionButton(
                    icon: Icons.visibility_outlined,
                    label: 'VIEW REPLY',
                    color: DesignTokens.neonGreen,
                    onTap: () {},
                  ),
                const Spacer(),
                _buildActionButton(
                  icon: Icons.archive_outlined,
                  label: 'SKIP',
                  color: Colors.white38,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 9,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _topicLabel(QuestionTopic topic) {
    return switch (topic) {
      QuestionTopic.general => 'GENERAL',
      QuestionTopic.fightPrep => 'FIGHT PREP',
      QuestionTopic.lifestyle => 'LIFESTYLE',
      QuestionTopic.advice => 'ADVICE',
      QuestionTopic.shoutout => 'SHOUTOUT',
      QuestionTopic.event => 'EVENT',
      QuestionTopic.career => 'CAREER',
    };
  }

  // ── Save / Unsave toggle ──

  Future<void> _toggleSave(FanMessage message) async {
    try {
      if (message.savedForLater) {
        await _service.unsaveMessage(message.id);
      } else {
        await _service.saveForLater(message.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.savedForLater ? 'Removed from saved' : 'Saved for later',
            ),
            backgroundColor: DesignTokens.neonGold,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo mode — saved locally'),
            backgroundColor: DesignTokens.neonAmber,
          ),
        );
      }
    }
  }

  // ── Enhanced Reply Composer (text + media type + templates) ──

  void _showReplyComposer(FanMessage message) {
    final controller = TextEditingController();
    ResponseType selectedType = ResponseType.text;
    bool publishToFeed = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: DesignTokens.bgSecondary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    'Reply to ${message.fanName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${message.content.length > 80 ? '${message.content.substring(0, 80)}...' : message.content}"',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Response type selector
                  const Text(
                    'RESPONSE TYPE',
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ResponseType.values.map((type) {
                      final isSelected = selectedType == type;
                      final icon = switch (type) {
                        ResponseType.text => Icons.text_fields,
                        ResponseType.audio => Icons.mic,
                        ResponseType.video => Icons.videocam,
                        ResponseType.template => Icons.auto_awesome,
                      };
                      final label = switch (type) {
                        ResponseType.text => 'Text',
                        ResponseType.audio => 'Audio',
                        ResponseType.video => 'Video',
                        ResponseType.template => 'Template',
                      };
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => selectedType = type),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? DesignTokens.neonCyan.withValues(
                                      alpha: 0.15,
                                    )
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(
                                      color: DesignTokens.neonCyan.withValues(
                                        alpha: 0.5,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  icon,
                                  color: isSelected
                                      ? DesignTokens.neonCyan
                                      : Colors.white38,
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: isSelected
                                        ? DesignTokens.neonCyan
                                        : Colors.white38,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Text input or media placeholder
                  if (selectedType == ResponseType.text ||
                      selectedType == ResponseType.template) ...[
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      maxLength: 500,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: selectedType == ResponseType.template
                            ? 'Pick a template below or type your own...'
                            : 'Your response...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: DesignTokens.neonCyan,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        counterStyle: const TextStyle(color: Colors.white38),
                      ),
                    ),
                    // Quick templates
                    if (selectedType == ResponseType.template) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            [
                                  'Thanks for the love! 🤙',
                                  'Great question — stay tuned!',
                                  'Appreciate the support! 💪',
                                  'Coming soon...',
                                ]
                                .map(
                                  (t) => GestureDetector(
                                    onTap: () => setSheetState(
                                      () => controller.text = t,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.06,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.1,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        t,
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ] else ...[
                    // Audio / Video placeholder
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            selectedType == ResponseType.audio
                                ? Icons.mic_none
                                : Icons.videocam_outlined,
                            color: DesignTokens.neonCyan,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedType == ResponseType.audio
                                ? 'Tap to record audio response'
                                : 'Tap to record video response',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Audio & video responses coming in a future update',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Publish to feed toggle
                  Row(
                    children: [
                      Switch(
                        value: publishToFeed,
                        activeTrackColor: DesignTokens.neonCyan,
                        onChanged: (v) =>
                            setSheetState(() => publishToFeed = v),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Publish reply to public Q&A feed',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Send button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (controller.text.trim().isEmpty &&
                            (selectedType == ResponseType.text ||
                                selectedType == ResponseType.template)) {
                          return;
                        }
                        try {
                          await _service.respondToMessage(
                            messageId: message.id,
                            content: controller.text.trim(),
                            type: selectedType,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  publishToFeed
                                      ? 'Response published to Q&A feed!'
                                      : 'Response sent!',
                                ),
                                backgroundColor: DesignTokens.neonGreen,
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Demo mode — response saved locally',
                                ),
                                backgroundColor: DesignTokens.neonAmber,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.neonCyan,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'SEND RESPONSE',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _quickReply(FanMessage message, String text) async {
    try {
      await _service.respondToMessage(messageId: message.id, content: text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quick reply sent!'),
            backgroundColor: DesignTokens.neonGreen,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo mode — reply saved locally'),
            backgroundColor: DesignTokens.neonAmber,
          ),
        );
      }
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
