import 'package:flutter/material.dart';

/// Admin Dashboard Quick Search — DFC Admin
/// Quickly search users, content, and logs from the admin dashboard.
class AdminQuickSearchPage extends StatelessWidget {
  const AdminQuickSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample search results (replace with backend integration)
    final results = [
      _Result('User', 'alice@dfc.com'),
      _Result('Post', 'Fight night was epic!'),
      _Result('Log', 'Banned user bob@dfc.com'),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Admin Dashboard Quick Search',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search users, content, logs...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.deepPurple.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.amber),
              ),
              onChanged: (query) {
                // Search filters applied on query change
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ...results.map(
                  (r) => Card(
                    color: Colors.deepPurple.shade800.withValues(alpha: 0.95),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(
                        r.type == 'User'
                            ? Icons.person
                            : r.type == 'Post'
                            ? Icons.article
                            : Icons.event_note,
                        color: Colors.amber,
                        size: 28,
                      ),
                      title: Text(
                        '${r.type}: ${r.value}',
                        style: const TextStyle(color: Colors.white),
                      ),
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
}

class _Result {
  final String type;
  final String value;
  _Result(this.type, this.value);
}
