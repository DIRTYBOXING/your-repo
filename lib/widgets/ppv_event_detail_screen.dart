import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/design_tokens.dart';

class PpvEventDetailScreen extends StatefulWidget {
  final String eventId;
  final String ppvTitle;
  final bool isLive;

  const PpvEventDetailScreen({
    super.key,
    this.eventId = 'test_event',
    this.ppvTitle = 'Data Fight Main Event',
    this.isLive = false,
  });

  @override
  State<PpvEventDetailScreen> createState() => _PpvEventDetailScreenState();
}

class _PpvEventDetailScreenState extends State<PpvEventDetailScreen> {
  final TextEditingController _chatController = TextEditingController();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  final String _userName =
      FirebaseAuth.instance.currentUser?.displayName ?? 'Fight Fan';

  Future<void> _sendMessage() async {
    if (_chatController.text.trim().isEmpty) return;

    final message = _chatController.text.trim();
    _chatController.clear();

    await FirebaseFirestore.instance
        .collection('ppv_events')
        .doc(widget.eventId)
        .collection('live_chat')
        .add({
          'userId': _userId ?? 'anonymous',
          'userName': _userName,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.ppvTitle,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. THE STREAM / PLAYER AREA
          Container(
            width: double.infinity,
            height: 250,
            color: const Color(0xFF111111),
            child: widget.isLive
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_fill,
                          color: Colors.white24,
                          size: 64,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'STREAMING LIVE',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_clock, color: Colors.white24, size: 48),
                        SizedBox(height: 8),
                        Text(
                          'EVENT HAS NOT STARTED YET',
                          style: TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          Container(height: 2, color: DesignTokens.neonCyan),

          // 2. LIVE SOCIAL CHAT FEED
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF1A1A1A),
            width: double.infinity,
            child: const Text(
              'GLOBAL FIGHT CHAT',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ppv_events')
                  .doc(widget.eventId)
                  .collection('live_chat')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['userId'] == _userId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            const CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.white12,
                              child: Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.white54,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? DesignTokens.neonCyan.withValues(
                                        alpha: 0.2,
                                      )
                                    : Colors.white12,
                                borderRadius: BorderRadius.circular(12)
                                    .copyWith(
                                      bottomRight: isMe
                                          ? const Radius.circular(0)
                                          : const Radius.circular(12),
                                      bottomLeft: !isMe
                                          ? const Radius.circular(0)
                                          : const Radius.circular(12),
                                    ),
                                border: Border.all(
                                  color: isMe
                                      ? DesignTokens.neonCyan.withValues(
                                          alpha: 0.5,
                                        )
                                      : Colors.transparent,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe) ...[
                                    Text(
                                      data['userName'] ?? 'Unknown',
                                      style: const TextStyle(
                                        color: DesignTokens.neonCyan,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                  Text(
                                    data['message'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 3. CHAT INPUT
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            color: Colors.black,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Say something...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.greenAccent.shade700,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
