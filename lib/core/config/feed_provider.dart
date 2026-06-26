import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feed_post.dart';

final mockPosts = [
  FeedPost(
    id: '1',
    authorName: 'Jay Cutler',
    authorRole: 'fighter',
    content:
        'And NEW! What a war at IBC III. Thanks to everyone who supported me. The brawling revolution is here. 🪓🔥',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    isEventLinked: true,
    eventId: 'ibc-03',
    passedSafety: true,
  ),
  FeedPost(
    id: '2',
    authorName: 'Data Fight Central',
    authorRole: 'org',
    content:
        'Check out the official results from last night\'s event. 8,400 fans in attendance! The energy was unmatched.',
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    isEventLinked: false,
    passedSafety: true,
  ),
  FeedPost(
    id: '3',
    authorName: 'Spam Bot',
    authorRole: 'fan',
    content: 'Click here for free money and crypto investments!!!',
    createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    isEventLinked: false,
    passedSafety: false, // Mod-flagged: will be filtered out by the provider
  ),
];

final globalFeedProvider = FutureProvider<List<FeedPost>>((ref) async {
  await Future.delayed(
    const Duration(milliseconds: 600),
  ); // Simulate network latency
  return mockPosts.where((p) => p.passedSafety).toList();
});
