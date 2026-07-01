import 'package:cloud_firestore/cloud_firestore.dart';
import 'feed_model.dart';

class FeedService {
  final FirebaseFirestore _db;
  FeedService(this._db);

  Stream<List<FeedItem>> watchFeed() {
    return _db
        .collection('feed')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => FeedItem.fromDoc(d.id, d.data())).toList(),
        );
  }
}
