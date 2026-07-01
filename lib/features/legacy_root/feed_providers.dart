import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'feed_service.dart';
import 'feed_model.dart';

final feedServiceProvider = Provider<FeedService>((ref) {
  return FeedService(FirebaseFirestore.instance);
});

final feedProvider = StreamProvider<List<FeedItem>>((ref) {
  final service = ref.watch(feedServiceProvider);
  return service.watchFeed();
});
