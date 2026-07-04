import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'feed_providers.dart';
import 'feed_components.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      appBar: AppBar(
        title: const Text(
          'DFC FEED',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF05060A),
        elevation: 0,
        centerTitle: false,
      ),
      body: feedAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
        ),
        error: (e, st) => Center(
          child: Text(
            'Error loading feed: $e',
            style: const TextStyle(color: Colors.white54),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No content yet. The swarm is sleeping.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(
              bottom: 120,
              top: 8,
            ), // Padding for the glass dock
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return FeedCard(
                item: item,
                onTap: () {
                  // Route safely depending on the type using GoRouter
                  if (item.type == 'event') context.push('/event/${item.id}');
                  if (item.type == 'fighter') {
                    context.push('/fighter/${item.id}');
                  }
                  if (item.type == 'gym') context.push('/gym/${item.id}');
                },
              );
            },
          );
        },
      ),
    );
  }
}
