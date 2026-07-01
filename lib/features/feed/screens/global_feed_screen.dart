import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../providers/feed_provider.dart';
import '../widgets/feed_post_card.dart';
import '../widgets/feed_filter_bar.dart';

class GlobalFeedScreen extends ConsumerStatefulWidget {
  const GlobalFeedScreen({super.key});

  @override
  ConsumerState<GlobalFeedScreen> createState() => _GlobalFeedScreenState();
}

class _GlobalFeedScreenState extends ConsumerState<GlobalFeedScreen> {
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(globalFeedProvider);

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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: FeedFilterBar(
              selected: _selectedFilter,
              onSelect: (val) => setState(() => _selectedFilter = val),
            ),
          ),
          Expanded(
            child: posts.when(
              data: (list) => ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => FeedPostCard(post: list[i]),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: DesignTokens.neonCyan),
              ),
              error: (e, _) => Center(
                child: Text(
                  "Error: $e",
                  style: const TextStyle(color: DesignTokens.neonRed),
                ),
              ),
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
}
