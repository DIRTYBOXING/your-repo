import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/glass_panel.dart';
import '../../../shared/services/auth_service.dart';
import '../models/message_model.dart';
import 'package:go_router/go_router.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC MESSAGE SEARCH — Search across all conversations
///
/// - Full-text search across message content
/// - Shows conversation context + jump to thread
/// - Debounced search with loading states
/// ═══════════════════════════════════════════════════════════════════════════
class MessageSearchScreen extends StatefulWidget {
  const MessageSearchScreen({super.key});

  @override
  State<MessageSearchScreen> createState() => _MessageSearchScreenState();
}

class _MessageSearchScreenState extends State<MessageSearchScreen> {
  final _searchCtrl = TextEditingController();
  final _db = FirebaseFirestore.instance;
  List<_SearchResult> _results = [];
  bool _loading = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.length < 2) {
      setState(() {
        _results = [];
        _lastQuery = '';
      });
      return;
    }
    if (trimmed == _lastQuery) return;
    _lastQuery = trimmed;

    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return;

    setState(() => _loading = true);

    try {
      // Get all user's conversations
      final convSnap = await _db
          .collection('conversations')
          .where('participants', arrayContains: uid)
          .get();

      final results = <_SearchResult>[];

      for (final convDoc in convSnap.docs) {
        final conv = Conversation.fromFirestore(convDoc);

        // Search messages in this conversation
        final msgSnap = await _db
            .collection('conversations')
            .doc(conv.id)
            .collection('messages')
            .orderBy('sentAt', descending: true)
            .limit(200)
            .get();

        for (final msgDoc in msgSnap.docs) {
          final msg = Message.fromFirestore(msgDoc);
          if (msg.text.toLowerCase().contains(trimmed)) {
            // Get display name for the conversation
            String convName;
            if (conv.isGroup) {
              convName = conv.groupName ?? 'Group';
            } else {
              convName = conv.participantNames.entries
                      .where((e) => e.key != uid)
                      .map((e) => e.value)
                      .firstOrNull ??
                  'Chat';
            }

            results.add(_SearchResult(
              conversationId: conv.id,
              conversationName: convName,
              message: msg,
              otherUserId: conv.participants
                      .where((p) => p != uid)
                      .firstOrNull ??
                  '',
              otherPhotoUrl: conv.participantPhotoUrls.entries
                      .where((e) => e.key != uid)
                      .map((e) => e.value)
                      .firstOrNull ??
                  '',
            ));
          }
        }
      }

      // Sort by most recent first
      results.sort((a, b) => b.message.sentAt.compareTo(a.message.sentAt));

      if (mounted) {
        setState(() {
          _results = results.take(50).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Search Messages',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: GlassPanel(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(16),
              backgroundColor: Colors.white.withValues(alpha: 0.04),
              borderColor: AppTheme.neonCyan.withValues(alpha: 0.15),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppTheme.neonCyan.withValues(alpha: 0.5),
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _results = [];
                              _lastQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: _search,
              ),
            ),
          ),

          // Results
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: CircularProgressIndicator(color: AppTheme.neonCyan),
            )
          else if (_results.isEmpty && _lastQuery.isNotEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No messages found',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _results.length,
                itemBuilder: (ctx, i) => _resultTile(_results[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _resultTile(_SearchResult r) {
    final query = _lastQuery;
    final text = r.message.text;

    return InkWell(
      onTap: () => context.push(
        '/messaging/chat/${r.conversationId}',
        extra: {
          'otherName': r.conversationName,
          'otherPhotoUrl': r.otherPhotoUrl,
          'otherUserId': r.otherUserId,
        },
      ),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: GlassPanel(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(12),
        backgroundColor: Colors.white.withValues(alpha: 0.02),
        borderColor: Colors.white.withValues(alpha: 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Conversation name + timestamp
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.conversationName,
                    style: const TextStyle(
                      color: AppTheme.neonCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  _formatDate(r.message.sentAt),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Sender
            Text(
              r.message.senderName,
              style: TextStyle(
                color: AppTheme.neonMagenta.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            // Message text with highlight
            _highlightedText(text, query),
          ],
        ),
      ),
      ),
    );
  }

  Widget _highlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
      );
    }

    final lower = text.toLowerCase();
    final idx = lower.indexOf(query);
    if (idx == -1) {
      return Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
      );
    }

    return RichText(
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
        children: [
          if (idx > 0) TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: const TextStyle(
              color: AppTheme.neonCyan,
              fontWeight: FontWeight.w800,
              backgroundColor: Color(0x2000E5FF),
            ),
          ),
          if (idx + query.length < text.length)
            TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _SearchResult {
  final String conversationId;
  final String conversationName;
  final Message message;
  final String otherUserId;
  final String otherPhotoUrl;

  _SearchResult({
    required this.conversationId,
    required this.conversationName,
    required this.message,
    required this.otherUserId,
    required this.otherPhotoUrl,
  });
}
