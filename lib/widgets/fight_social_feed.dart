import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/theme/design_tokens.dart';
import '../shared/widgets/dfc_network_image.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT SOCIAL FEED — Real-time PPV chat & reactions widget
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Live social stream scoped to a specific PPV event. Users can post
/// text messages and combat-themed reactions in real time.
///
/// Data source: Firestore `ppv_events/{eventId}/chat` subcollection
///
/// Place next to or below [LiveStreamPlayer] on fight night.
///
/// Usage:
///   FightSocialFeed(
///     eventId: 'ibc-04-melbourne',
///     maxHeight: 400,
///   )
/// ═══════════════════════════════════════════════════════════════════════════
class FightSocialFeed extends StatefulWidget {
  final String eventId;
  final double? maxHeight;
  final bool showReactionBar;

  const FightSocialFeed({
    super.key,
    required this.eventId,
    this.maxHeight,
    this.showReactionBar = true,
  });

  @override
  State<FightSocialFeed> createState() => _FightSocialFeedState();
}

class _FightSocialFeedState extends State<FightSocialFeed> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _sending = false;

  /// Combat-themed quick reactions
  static const List<_Reaction> _reactions = [
    _Reaction('🥊', 'KO'),
    _Reaction('🔥', 'FIRE'),
    _Reaction('💀', 'DEAD'),
    _Reaction('👊', 'PUNCH'),
    _Reaction('🏆', 'CHAMP'),
    _Reaction('😤', 'WAR'),
  ];

  CollectionReference<Map<String, dynamic>> get _chatRef =>
      _db.collection('ppv_events').doc(widget.eventId).collection('chat');

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final user = _currentUser;
    if (user == null || text.trim().isEmpty) return;

    setState(() => _sending = true);
    try {
      await _chatRef.add({
        'uid': user.uid,
        'displayName': user.displayName ?? 'Fighter',
        'photoUrl': user.photoURL ?? '',
        'text': text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'message',
      });
      _msgController.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendReaction(String emoji) async {
    final user = _currentUser;
    if (user == null) return;

    await _chatRef.add({
      'uid': user.uid,
      'displayName': user.displayName ?? 'Fighter',
      'photoUrl': user.photoURL ?? '',
      'text': emoji,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'reaction',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: widget.maxHeight != null
          ? BoxConstraints(maxHeight: widget.maxHeight!)
          : const BoxConstraints(),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        border: Border.all(color: DesignTokens.borderSubtle),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(child: _buildMessageStream()),
          if (widget.showReactionBar) _buildReactionBar(),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.cardPaddingMedium,
        vertical: DesignTokens.spacingS,
      ),
      decoration: const BoxDecoration(
        color: DesignTokens.bgOverlay,
        border: Border(bottom: BorderSide(color: DesignTokens.borderSubtle)),
      ),
      child: const Row(
        children: [
          Icon(Icons.forum, color: DesignTokens.neonCyan, size: 16),
          SizedBox(width: 8),
          Text(
            'DATA FIGHT SOCIAL',
            style: TextStyle(
              color: DesignTokens.neonCyan,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          Spacer(),
          Icon(Icons.circle, color: DesignTokens.neonGreen, size: 8),
          SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              color: DesignTokens.neonGreen,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGE STREAM — real-time Firestore
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMessageStream() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _chatRef
          .orderBy('timestamp', descending: false)
          .limitToLast(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                color: DesignTokens.neonCyan,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sports_mma,
                    color: DesignTokens.textMuted,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Be the first to drop a message',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Auto-scroll to bottom on new messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final isReaction = data['type'] == 'reaction';
            final isMe = data['uid'] == _currentUser?.uid;

            if (isReaction) {
              return _buildReactionBubble(data, isMe);
            }
            return _buildMessageBubble(data, isMe);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
    final displayName = (data['displayName'] as String?) ?? 'Fighter';
    final text = (data['text'] as String?) ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          DfcCircleAvatar(
            imageUrl: data['photoUrl'] as String?,
            radius: 14,
            backgroundColor: isMe
                ? DesignTokens.neonCyan.withValues(alpha: 0.2)
                : DesignTokens.bgSurface,
            fallbackText: displayName.isNotEmpty
                ? displayName[0].toUpperCase()
                : '?',
            fallbackTextStyle: TextStyle(
              color: isMe ? DesignTokens.neonCyan : DesignTokens.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          // Message body
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: isMe
                        ? DesignTokens.neonCyan
                        : DesignTokens.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? DesignTokens.neonCyan.withValues(alpha: 0.08)
                        : DesignTokens.bgSurface,
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusSmall,
                    ),
                    border: Border.all(
                      color: isMe
                          ? DesignTokens.neonCyan.withValues(alpha: 0.2)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionBubble(Map<String, dynamic> data, bool isMe) {
    final displayName = (data['displayName'] as String?) ?? 'Fighter';
    final emoji = (data['text'] as String?) ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const SizedBox(width: 36), // aligned with message avatar offset
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Text(
            displayName,
            style: TextStyle(
              color: isMe ? DesignTokens.neonCyan : DesignTokens.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REACTION BAR — quick combat emojis
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildReactionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: DesignTokens.bgOverlay,
        border: Border(top: BorderSide(color: DesignTokens.borderSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _reactions.map((r) {
          return Tooltip(
            message: r.label,
            child: InkWell(
              onTap: () => _sendReaction(r.emoji),
              borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(r.emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INPUT BAR — text compose
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingS),
      decoration: const BoxDecoration(
        color: DesignTokens.bgOverlay,
        border: Border(top: BorderSide(color: DesignTokens.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              style: const TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Drop your take...',
                hintStyle: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: DesignTokens.bgSurface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                  borderSide: BorderSide.none,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              onPressed: _sending
                  ? null
                  : () => _sendMessage(_msgController.text),
              icon: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DesignTokens.neonCyan,
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: DesignTokens.neonCyan,
                      size: 18,
                    ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal reaction model
class _Reaction {
  final String emoji;
  final String label;
  const _Reaction(this.emoji, this.label);
}
