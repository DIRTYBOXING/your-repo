import 'package:flutter/material.dart';

/// Accessible Posting/Reading Screen
import 'services/post_service.dart';
import 'models/post_model.dart';

class HandicappedPostReadScreen extends StatefulWidget {
  const HandicappedPostReadScreen({super.key});
  @override
  State<HandicappedPostReadScreen> createState() =>
      _HandicappedPostReadScreenState();
}

class _HandicappedPostReadScreenState extends State<HandicappedPostReadScreen> {
  List<HandicappedPost> _posts = [];
  bool _loading = true;
  final String _userId = 'user_basic'; // Replace with real user logic

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() => _loading = true);
    final posts = await HandicappedPostService().fetchPosts(_userId);
    setState(() {
      _posts = posts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post & Read', style: TextStyle(fontSize: 24)),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.create, color: Colors.amber),
            tooltip: 'Create Post',
            onPressed: () {},
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              )
            : Column(
                children: [
                  if (_posts.isEmpty)
                    Card(
                      color: Colors.deepPurple.shade900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: ListTile(
                        leading: const Icon(
                          Icons.post_add,
                          color: Colors.amber,
                          size: 32,
                        ),
                        title: const Text(
                          'No posts yet.',
                          style: TextStyle(color: Colors.amber, fontSize: 20),
                        ),
                        subtitle: const Text(
                          'Create a post to share updates.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.create, color: Colors.amber),
                          tooltip: 'Create Post',
                          onPressed: _fetchPosts,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          final post = _posts[index];
                          return Card(
                            color: Colors.deepPurple.shade900,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            child: ListTile(
                              leading: const Icon(
                                Icons.post_add,
                                color: Colors.amber,
                                size: 32,
                              ),
                              title: Text(
                                post.content,
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Text(
                                'Posted: ${post.postedAt}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.amber,
                                ),
                                tooltip: 'Refresh',
                                onPressed: _fetchPosts,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image, color: Colors.black),
                    label: const Text(
                      'Add Image',
                      style: TextStyle(color: Colors.black, fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      minimumSize: const Size(200, 60),
                      textStyle: const TextStyle(fontSize: 22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.deepPurple.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: const ListTile(
                      leading: Icon(
                        Icons.info_outline,
                        color: Colors.amber,
                      ),
                      title: Text(
                        'Tips',
                        style: TextStyle(color: Colors.amber, fontSize: 18),
                      ),
                      subtitle: Text(
                        'Tap the create button to post updates. Add images for richer content.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
