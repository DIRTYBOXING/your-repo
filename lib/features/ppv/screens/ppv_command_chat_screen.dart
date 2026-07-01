import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/ppv_command_chat_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV COMMAND CHAT SCREEN — Owner Live Chat + Bot Control Center
/// ═══════════════════════════════════════════════════════════════════════════
///
/// YOUR war room for PPV live events:
///   • GO LIVE button — chat directly with users
///   • Bot mode — after hours auto-responder
///   • Announcements — blast to all viewers
///   • Polls — gauge crowd opinion live
///   • Fight updates — round results, KO alerts
///   • Social shares — FightPipe, IG, FB links
///   • User controls — mute, ban, VIP, mod
///   • Quick replies — pre-loaded fight responses
///   • Chat stats — viewers, messages, engagement
/// ═══════════════════════════════════════════════════════════════════════════
class PPVCommandChatScreen extends StatefulWidget {
  final String ppvId;
  final String eventTitle;
  const PPVCommandChatScreen({
    super.key,
    required this.ppvId,
    this.eventTitle = 'PPV Event',
  });

  @override
  State<PPVCommandChatScreen> createState() => _PPVCommandChatScreenState();
}

class _PPVCommandChatScreenState extends State<PPVCommandChatScreen>
    with SingleTickerProviderStateMixin {
  final PPVCommandChatService _chatService = PPVCommandChatService();
  final TextEditingController _messageCtrl = TextEditingController();
  final TextEditingController _announcementCtrl = TextEditingController();
  final TextEditingController _pollQuestionCtrl = TextEditingController();
  final List<TextEditingController> _pollOptionCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];
  final ScrollController _scrollCtrl = ScrollController();
  late TabController _tabCtrl;
  bool _showQuickReplies = false;
  bool _showUserControls = false;
  String? _selectedUserId;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _chatService.addListener(_onChatUpdate);
    _chatService.openRoom(widget.ppvId);
    _loadStats();
  }

  @override
  void dispose() {
    _chatService.removeListener(_onChatUpdate);
    _messageCtrl.dispose();
    _announcementCtrl.dispose();
    _pollQuestionCtrl.dispose();
    for (final c in _pollOptionCtrls) {
      c.dispose();
    }
    _scrollCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onChatUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadStats() async {
    final s = await _chatService.getRoomStats();
    if (mounted) setState(() => _stats = s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.eventTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                _statusDot(),
                const SizedBox(width: 6),
                Text(
                  _statusLabel(),
                  style: TextStyle(fontSize: 11, color: _statusColor()),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.visibility, size: 12, color: DesignTokens.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${_chatService.activeViewers}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // GO LIVE / GO AWAY / GO OFFLINE toggle
          _buildStatusToggle(),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: DesignTokens.neonCyan,
          labelColor: DesignTokens.neonCyan,
          unselectedLabelColor: DesignTokens.textMuted,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'CHAT', icon: Icon(Icons.chat_bubble, size: 16)),
            Tab(text: 'COMMAND', icon: Icon(Icons.rocket_launch, size: 16)),
            Tab(text: 'BOT', icon: Icon(Icons.smart_toy, size: 16)),
            Tab(text: 'STATS', icon: Icon(Icons.analytics, size: 16)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildChatTab(),
          _buildCommandTab(),
          _buildBotTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 1: LIVE CHAT — Messages + Input
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildChatTab() {
    return Column(
      children: [
        // Pinned messages bar
        if (_chatService.pinnedMessages.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: DesignTokens.neonAmber.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: DesignTokens.neonAmber.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.push_pin,
                  size: 14,
                  color: DesignTokens.neonAmber,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _chatService.pinnedMessages.last.content,
                    style: const TextStyle(
                      fontSize: 12,
                      color: DesignTokens.neonAmber,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

        // Active poll banner
        if (_chatService.activePoll != null) _buildPollBanner(),

        // Messages
        Expanded(
          child: _chatService.messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No messages yet',
                        style: TextStyle(color: DesignTokens.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _chatService.isOwnerLive
                            ? 'You\'re LIVE — start chatting!'
                            : 'Go LIVE to open the chat',
                        style: TextStyle(
                          fontSize: 12,
                          color: DesignTokens.neonCyan.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: _chatService.messages.length,
                  itemBuilder: (ctx, i) =>
                      _buildMessageBubble(_chatService.messages[i]),
                ),
        ),

        // Quick replies
        if (_showQuickReplies) _buildQuickRepliesBar(),

        // Input bar
        _buildInputBar(),
      ],
    );
  }

  Widget _buildMessageBubble(CommandChatMessage msg) {
    final isSystem =
        msg.type == CommandMessageType.system ||
        msg.type == CommandMessageType.announcement ||
        msg.type == CommandMessageType.fightUpdate ||
        msg.type == CommandMessageType.promoBlast ||
        msg.type == CommandMessageType.socialLink;

    if (isSystem) return _buildSystemMessage(msg);

    final isOwnerMsg = msg.isOwner;
    final isBot = msg.isBot;

    return GestureDetector(
      onLongPress: () {
        setState(() {
          _showUserControls = true;
          _selectedUserId = msg.userId;
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 14,
              backgroundColor: isOwnerMsg
                  ? DesignTokens.neonCyan.withValues(alpha: 0.2)
                  : isBot
                  ? DesignTokens.neonGreen.withValues(alpha: 0.2)
                  : DesignTokens.bgCard.withValues(alpha: 0.5),
              child: Icon(
                isOwnerMsg
                    ? Icons.verified
                    : isBot
                    ? Icons.smart_toy
                    : Icons.person,
                size: 14,
                color: isOwnerMsg
                    ? DesignTokens.neonCyan
                    : isBot
                    ? DesignTokens.neonGreen
                    : DesignTokens.textMuted,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        msg.username,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isOwnerMsg
                              ? DesignTokens.neonCyan
                              : isBot
                              ? DesignTokens.neonGreen
                              : DesignTokens.textPrimary,
                        ),
                      ),
                      if (isOwnerMsg) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.neonCyan.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: DesignTokens.neonCyan.withValues(
                                alpha: 0.4,
                              ),
                              width: 0.5,
                            ),
                          ),
                          child: const Text(
                            'OWNER',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: DesignTokens.neonCyan,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                      if (isBot) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.neonGreen.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BOT',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: DesignTokens.neonGreen,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                      if (msg.isPinned) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.push_pin,
                          size: 10,
                          color: DesignTokens.neonAmber,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isOwnerMsg
                          ? DesignTokens.neonCyan.withValues(alpha: 0.08)
                          : isBot
                          ? DesignTokens.neonGreen.withValues(alpha: 0.06)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: isOwnerMsg
                          ? Border.all(
                              color: DesignTokens.neonCyan.withValues(
                                alpha: 0.2,
                              ),
                              width: 0.5,
                            )
                          : null,
                    ),
                    child: Text(
                      msg.content,
                      style: const TextStyle(
                        fontSize: 13,
                        color: DesignTokens.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemMessage(CommandChatMessage msg) {
    Color accent;
    IconData icon;
    switch (msg.type) {
      case CommandMessageType.announcement:
        accent = DesignTokens.neonAmber;
        icon = Icons.campaign;
      case CommandMessageType.fightUpdate:
        accent = DesignTokens.neonRed;
        icon = Icons.sports_mma;
      case CommandMessageType.promoBlast:
        accent = DesignTokens.neonMagenta;
        icon = Icons.local_fire_department;
      case CommandMessageType.socialLink:
        accent = DesignTokens.neonBlue;
        icon = Icons.share;
      case CommandMessageType.pollStart:
        accent = DesignTokens.neonGreen;
        icon = Icons.poll;
      default:
        accent = DesignTokens.textMuted;
        icon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.username,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  msg.content,
                  style: TextStyle(
                    fontSize: 12,
                    color: accent.withValues(alpha: 0.9),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollBanner() {
    final poll = _chatService.activePoll!;
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.neonGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DesignTokens.neonGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.poll, size: 16, color: DesignTokens.neonGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  poll.question,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.neonGreen,
                  ),
                ),
              ),
              Text(
                '${poll.totalVotes} votes',
                style: TextStyle(
                  fontSize: 10,
                  color: DesignTokens.neonGreen.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...poll.options.asMap().entries.map((e) {
            final voteKey = 'option_${e.key}';
            final votes = poll.votes[voteKey] ?? 0;
            final pct = poll.totalVotes > 0 ? votes / poll.totalVotes : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.value,
                        style: const TextStyle(
                          fontSize: 12,
                          color: DesignTokens.textPrimary,
                        ),
                      ),
                      Text(
                        '${(pct * 100).round()}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: DesignTokens.neonGreen.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation(
                        DesignTokens.neonGreen.withValues(alpha: 0.6),
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickRepliesBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...PPVCommandChatService.quickRepliesFight.map(
            _quickReplyChip,
          ),
          ...PPVCommandChatService.quickRepliesPromo.map(
            (r) => _quickReplyChip(r, isPromo: true),
          ),
        ],
      ),
    );
  }

  Widget _quickReplyChip(String text, {bool isPromo = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
      child: GestureDetector(
        onTap: () {
          _messageCtrl.text = text;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: (isPromo ? DesignTokens.neonMagenta : DesignTokens.neonCyan)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  (isPromo ? DesignTokens.neonMagenta : DesignTokens.neonCyan)
                      .withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isPromo ? DesignTokens.neonMagenta : DesignTokens.neonCyan,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: DesignTokens.bgSecondary,
        border: Border(
          top: BorderSide(color: DesignTokens.neonCyan.withValues(alpha: 0.1)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Quick replies toggle
            GestureDetector(
              onTap: () =>
                  setState(() => _showQuickReplies = !_showQuickReplies),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _showQuickReplies
                      ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bolt,
                  size: 20,
                  color: _showQuickReplies
                      ? DesignTokens.neonCyan
                      : DesignTokens.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _messageCtrl,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                decoration: InputDecoration(
                  hintText: _chatService.isOwnerLive
                      ? 'Message as owner...'
                      : 'Message...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: DesignTokens.textMuted.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.04),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  size: 18,
                  color: DesignTokens.neonCyan,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;
    _messageCtrl.clear();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_chatService.isOwnerLive) {
      await _chatService.sendOwnerMessage(
        userId: user.uid,
        username: user.displayName ?? 'DFC Owner',
        content: text,
        avatarUrl: user.photoURL,
      );
    } else {
      await _chatService.sendViewerMessage(
        userId: user.uid,
        username: user.displayName ?? 'User',
        content: text,
        avatarUrl: user.photoURL,
      );
    }

    // Auto-scroll to bottom
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 2: COMMAND CENTER — Announcements, Polls, Fight Updates, Socials
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildCommandTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Announcement Panel
        _sectionHeader('📢 ANNOUNCEMENT', DesignTokens.neonAmber),
        const SizedBox(height: 8),
        TextField(
          controller: _announcementCtrl,
          maxLines: 3,
          style: const TextStyle(fontSize: 13, color: Colors.white),
          decoration: _inputDecoration('Type announcement...'),
        ),
        const SizedBox(height: 8),
        _actionButton(
          'BLAST TO ALL VIEWERS',
          DesignTokens.neonAmber,
          Icons.campaign,
          () async {
            final text = _announcementCtrl.text.trim();
            if (text.isEmpty) return;
            await _chatService.sendAnnouncement(text);
            _announcementCtrl.clear();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Announcement sent!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
        ),

        const SizedBox(height: 24),

        // Fight Update Panel
        _sectionHeader('🥊 FIGHT UPDATE', DesignTokens.neonRed),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _quickCommandChip('Round 1 Complete', Icons.timer, () {
              _chatService.sendFightUpdate('🔔 Round 1 Complete!');
            }),
            _quickCommandChip('KNOCKOUT!', Icons.flash_on, () {
              _chatService.sendFightUpdate('💥 KNOCKOUT! It\'s over!');
            }),
            _quickCommandChip('Decision', Icons.gavel, () {
              _chatService.sendFightUpdate('📋 Going to the scorecards...');
            }),
            _quickCommandChip('Submission', Icons.sports_martial_arts, () {
              _chatService.sendFightUpdate('🔒 SUBMISSION! Tap out!');
            }),
            _quickCommandChip('TKO', Icons.cancel, () {
              _chatService.sendFightUpdate('🛑 TKO! Referee stops the fight!');
            }),
            _quickCommandChip('Split Decision', Icons.balance, () {
              _chatService.sendFightUpdate(
                '⚖️ SPLIT DECISION — controversial!',
              );
            }),
          ],
        ),

        const SizedBox(height: 24),

        // Live Poll Panel
        _sectionHeader('📊 LIVE POLL', DesignTokens.neonGreen),
        const SizedBox(height: 8),
        TextField(
          controller: _pollQuestionCtrl,
          style: const TextStyle(fontSize: 13, color: Colors.white),
          decoration: _inputDecoration('Poll question...'),
        ),
        const SizedBox(height: 8),
        ..._pollOptionCtrls.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: TextField(
              controller: e.value,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              decoration: _inputDecoration('Option ${e.key + 1}'),
            ),
          ),
        ),
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _pollOptionCtrls.add(TextEditingController());
                });
              },
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add Option', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: DesignTokens.neonGreen,
              ),
            ),
            const Spacer(),
            _actionButton(
              'START POLL',
              DesignTokens.neonGreen,
              Icons.poll,
              () async {
                final q = _pollQuestionCtrl.text.trim();
                final opts = _pollOptionCtrls
                    .map((c) => c.text.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
                if (q.isEmpty || opts.length < 2) return;
                await _chatService.createPoll(question: q, options: opts);
                _pollQuestionCtrl.clear();
                for (final c in _pollOptionCtrls) {
                  c.clear();
                }
              },
            ),
          ],
        ),

        if (_chatService.activePoll != null) ...[
          const SizedBox(height: 8),
          _actionButton(
            'CLOSE POLL',
            DesignTokens.neonRed,
            Icons.close,
            _chatService.closePoll,
          ),
        ],

        const SizedBox(height: 24),

        // Social Shares
        _sectionHeader('📱 SOCIAL BLAST', DesignTokens.neonBlue),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _socialChip(
              'FightPipe YouTube',
              Icons.play_circle_fill,
              Colors.red,
              SocialPlatform.youtube,
            ),
            _socialChip(
              'DFC Instagram',
              Icons.camera_alt,
              Colors.purple,
              SocialPlatform.instagram,
            ),
            _socialChip(
              'DFC Facebook',
              Icons.facebook,
              Colors.blue,
              SocialPlatform.facebook,
            ),
            _socialChip(
              'DFC TikTok',
              Icons.music_note,
              Colors.pink,
              SocialPlatform.tiktok,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Promo Blast
        _sectionHeader('🎫 PROMO BLAST', DesignTokens.neonMagenta),
        const SizedBox(height: 8),
        _actionButton(
          'PROMOTE NEXT EVENT',
          DesignTokens.neonMagenta,
          Icons.local_fire_department,
          () async {
            await _chatService.sendPromoBlast(
              eventName: 'Next DFC Event',
              eventDate: 'Coming Soon',
              ticketUrl: 'https://datafightcentral.com/ppv',
            );
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 3: BOT CONFIG — Auto-reply rules
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildBotTab() {
    return Column(
      children: [
        // Bot status header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _chatService.botModeActive
                ? DesignTokens.neonGreen.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.02),
            border: Border(
              bottom: BorderSide(
                color: DesignTokens.neonGreen.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.smart_toy,
                color: _chatService.botModeActive
                    ? DesignTokens.neonGreen
                    : DesignTokens.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _chatService.botModeActive
                          ? 'DFC Bot is ACTIVE'
                          : 'DFC Bot is OFF',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _chatService.botModeActive
                            ? DesignTokens.neonGreen
                            : DesignTokens.textMuted,
                      ),
                    ),
                    Text(
                      _chatService.botModeActive
                          ? 'Responding to user questions automatically'
                          : 'Go AWAY or OFFLINE to activate bot',
                      style: TextStyle(
                        fontSize: 11,
                        color: DesignTokens.textMuted.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bot reply rules
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Text(
                'AUTO-REPLY RULES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.textMuted,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bot responds when users type messages containing trigger words. '
                'Replies are matched by priority (highest first).',
                style: TextStyle(
                  fontSize: 11,
                  color: DesignTokens.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Default rules info
              _botRuleCard(
                'Welcome',
                'Triggers: hello, hi, hey, gday',
                'Greets new users with DFC intro',
                DesignTokens.neonCyan,
              ),
              _botRuleCard(
                'Schedule',
                'Triggers: next event, upcoming, when',
                'Directs to PPV Hub for all events',
                DesignTokens.neonAmber,
              ),
              _botRuleCard(
                'Buy PPV',
                'Triggers: buy, purchase, price, ticket',
                'Links to PPV Store with tier info',
                DesignTokens.neonGreen,
              ),
              _botRuleCard(
                'Social Follow',
                'Triggers: youtube, instagram, follow',
                'FightPipe + DFC social links',
                DesignTokens.neonBlue,
              ),
              _botRuleCard(
                'Fighter Signup',
                'Triggers: fighter, sign up, join',
                'Fighter profile creation info',
                DesignTokens.neonMagenta,
              ),
              _botRuleCard(
                'Promoter Info',
                'Triggers: promote, host event',
                'Sliding agreement 30-50% DFC, event creation flow',
                Colors.orange,
              ),
              _botRuleCard(
                'All Combat Sports',
                'Triggers: mma, boxing, bkfc, kickboxing...',
                'Full sport coverage list — no bias',
                DesignTokens.neonRed,
              ),
              _botRuleCard(
                'Aussie & Kiwi',
                'Triggers: aussie, australia, kiwi, nz, dan hooker',
                'ANZAC shows promoted globally — HEX, Eternal, AFC',
                DesignTokens.neonGold,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _botRuleCard(
    String title,
    String triggers,
    String description,
    Color accent,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            triggers,
            style: TextStyle(
              fontSize: 10,
              color: DesignTokens.textMuted.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11,
              color: DesignTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 4: STATS — Live analytics
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildStatsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('📊 LIVE STATS', DesignTokens.neonCyan),
        const SizedBox(height: 12),
        Row(
          children: [
            _statCard(
              '${_chatService.activeViewers}',
              'VIEWERS',
              Icons.visibility,
              DesignTokens.neonCyan,
            ),
            const SizedBox(width: 8),
            _statCard(
              '${_stats['totalMessages'] ?? 0}',
              'MESSAGES',
              Icons.chat,
              DesignTokens.neonGreen,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _statCard(
              '${_stats['uniqueUsers'] ?? 0}',
              'UNIQUE USERS',
              Icons.people,
              DesignTokens.neonAmber,
            ),
            const SizedBox(width: 8),
            _statCard(
              '${_chatService.pinnedMessages.length}',
              'PINNED',
              Icons.push_pin,
              DesignTokens.neonMagenta,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _actionButton(
          'REFRESH STATS',
          DesignTokens.neonCyan,
          Icons.refresh,
          _loadStats,
        ),

        const SizedBox(height: 24),

        // User controls
        if (_showUserControls && _selectedUserId != null) ...[
          _sectionHeader('👤 USER CONTROLS', DesignTokens.neonRed),
          const SizedBox(height: 8),
          Text(
            'Selected: $_selectedUserId',
            style: const TextStyle(fontSize: 11, color: DesignTokens.textMuted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickCommandChip('Mute 10min', Icons.volume_off, () {
                _chatService.muteUser(_selectedUserId!);
              }),
              _quickCommandChip('Ban', Icons.block, () {
                _chatService.banUser(_selectedUserId!);
              }),
              _quickCommandChip('Unban', Icons.check_circle, () {
                _chatService.unbanUser(_selectedUserId!);
              }),
              _quickCommandChip('Make Mod', Icons.shield, () {
                _chatService.promoteToMod(_selectedUserId!);
              }),
              _quickCommandChip('Grant VIP', Icons.star, () {
                _chatService.grantVIP(_selectedUserId!);
              }),
            ],
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildStatusToggle() {
    return PopupMenuButton<OwnerStatus>(
      onSelected: (status) async {
        switch (status) {
          case OwnerStatus.live:
            await _chatService.goLive();
          case OwnerStatus.away:
            await _chatService.goAway();
          case OwnerStatus.offline:
            await _chatService.goOffline();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: OwnerStatus.live,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text('GO LIVE', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem(
          value: OwnerStatus.away,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'GO AWAY (Bot On)',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: OwnerStatus.offline,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text('GO OFFLINE', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _statusColor().withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _statusColor().withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusDot(),
            const SizedBox(width: 6),
            Text(
              _statusLabel(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _statusColor(),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: _statusColor()),
          ],
        ),
      ),
    );
  }

  Widget _statusDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _statusColor(),
        shape: BoxShape.circle,
        boxShadow: [
          if (_chatService.isOwnerLive)
            BoxShadow(color: Colors.red.withValues(alpha: 0.6), blurRadius: 6),
        ],
      ),
    );
  }

  String _statusLabel() => switch (_chatService.ownerStatus) {
    OwnerStatus.live => 'LIVE',
    OwnerStatus.away => 'AWAY',
    OwnerStatus.offline => 'OFFLINE',
  };

  Color _statusColor() => switch (_chatService.ownerStatus) {
    OwnerStatus.live => Colors.red,
    OwnerStatus.away => Colors.amber,
    OwnerStatus.offline => Colors.grey,
  };

  Widget _sectionHeader(String title, Color accent) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: accent,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _actionButton(
    String label,
    Color accent,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.35), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accent,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickCommandChip(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: DesignTokens.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: DesignTokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialChip(
    String label,
    IconData icon,
    Color color,
    SocialPlatform platform,
  ) {
    return GestureDetector(
      onTap: () => _chatService.shareSocialLink(platform),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: accent),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: accent.withValues(alpha: 0.7),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 13,
        color: DesignTokens.textMuted.withValues(alpha: 0.4),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: DesignTokens.neonCyan.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
