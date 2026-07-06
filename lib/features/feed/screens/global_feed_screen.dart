import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/community/community_models.dart';
import '../../../shared/services/social_service.dart';
import '../../social/widgets/dfc_post_card.dart';

/// Global discovery feed — platform-wide timeline of the latest posts.
/// Uses the real Firestore-backed [SocialService.getFeed] stream.
class GlobalFeedScreen extends StatefulWidget {
  const GlobalFeedScreen({super.key});

  @override
  State<GlobalFeedScreen> createState() => _GlobalFeedScreenState();
}

class _GlobalFeedScreenState extends State<GlobalFeedScreen> {
  static const List<String> _filters = ['All', 'Following', 'Trending', 'Live'];
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    final social = context.read<SocialService>();

    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgPrimary,
        title: const Text(
          "GLOBAL FEED",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: social.getFeed(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: DesignTokens.neonCyan,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: DesignTokens.neonRed),
                    ),
                  );
                }
                final list = snapshot.data ?? const <Post>[];
                if (list.isEmpty) {
                  return const Center(
                    child: Text(
                      "No posts yet",
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DFCPostCard(post: list[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: DesignTokens.neonCyan,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => context.push('/feed/compose'),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final selected = i == _selectedFilter;
          return ChoiceChip(
            label: Text(_filters[i]),
            selected: selected,
            onSelected: (_) => setState(() => _selectedFilter = i),
            backgroundColor: DesignTokens.bgCard,
            selectedColor: DesignTokens.neonCyan,
            labelStyle: TextStyle(
              color: selected ? Colors.black : Colors.white70,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: selected
                    ? DesignTokens.neonCyan
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
          );
        },
      ),
    );
  }
}
