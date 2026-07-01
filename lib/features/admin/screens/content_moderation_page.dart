import 'package:flutter/material.dart';

/// Content Moderation — DFC Admin
/// Approve, remove, or edit posts, comments, and media.
class ContentModerationPage extends StatelessWidget {
  const ContentModerationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample content items (replace with backend integration)
    final items = [
      _ContentItem(
        'Post',
        'alice@dfc.com',
        '2026-02-17 09:00',
        'Pending',
        '"Fight night was epic!"',
      ),
      _ContentItem(
        'Comment',
        'bob@dfc.com',
        '2026-02-16 22:30',
        'Flagged',
        '"This is spam!"',
      ),
      _ContentItem(
        'Media',
        'eve@dfc.com',
        '2026-02-15 18:10',
        'Approved',
        'fight_photo.jpg',
      ),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Content Moderation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Review and moderate posts, comments, and media. Approve, remove, or edit as needed.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Card(
              color: item.status == 'Flagged'
                  ? Colors.red.shade900.withValues(alpha: 0.8)
                  : Colors.deepPurple.shade800.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(
                  item.type == 'Post'
                      ? Icons.article
                      : item.type == 'Comment'
                      ? Icons.comment
                      : Icons.image,
                  color: item.status == 'Flagged'
                      ? Colors.redAccent
                      : Colors.amber,
                  size: 32,
                ),
                title: Text(
                  '${item.type} by ${item.user}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'At: ${item.timestamp}\nStatus: ${item.status}\nContent: ${item.content}',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  color: Colors.deepPurple.shade900,
                  onSelected: (action) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.type} by ${item.user}: $action'),
                        backgroundColor: Colors.deepPurple.shade700,
                      ),
                    );
                  },
                  itemBuilder: (ctx) => [
                    if (item.status != 'Approved')
                      const PopupMenuItem(
                        value: 'approve',
                        child: Text('Approve'),
                      ),
                    const PopupMenuItem(value: 'remove', child: Text('Remove')),
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentItem {
  final String type;
  final String user;
  final String timestamp;
  final String status;
  final String content;
  _ContentItem(this.type, this.user, this.timestamp, this.status, this.content);
}
