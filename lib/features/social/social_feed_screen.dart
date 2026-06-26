import 'package:flutter/material.dart';
import '../../shared/models/community/community_models.dart';
import '../../shared/services/social_service.dart';
import 'widgets/dfc_post_card.dart';

class SocialFeedScreen extends StatefulWidget {
  final String currentUserId;
  const SocialFeedScreen({required this.currentUserId, super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final SocialService _service = SocialService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Social Feed')),
      body: StreamBuilder(
        stream: _service.getFeed(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data!.whereType<Post>().toList();
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return DFCPostCard(post: post, onTap: () {}, onComment: () {});
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await _service.createPost(
            authorId: widget.currentUserId,
            content: 'New post from ${widget.currentUserId}',
          );
        },
      ),
    );
  }
}
