import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreReadinessIssue {
  const FirestoreReadinessIssue({
    required this.collection,
    required this.documentId,
    required this.field,
    required this.message,
  });

  final String collection;
  final String documentId;
  final String field;
  final String message;
}

class FirestoreReadinessReport {
  const FirestoreReadinessReport({
    required this.checkedAt,
    required this.eventSamples,
    required this.postSamples,
    required this.conversationSamples,
    required this.legacyMessageSamples,
    required this.issues,
  });

  final DateTime checkedAt;
  final int eventSamples;
  final int postSamples;
  final int conversationSamples;
  final int legacyMessageSamples;
  final List<FirestoreReadinessIssue> issues;

  bool get isReady => issues.isEmpty;
}

class FirestoreReadinessValidatorService {
  FirestoreReadinessValidatorService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<FirestoreReadinessReport> run({int sampleLimit = 50}) async {
    final issues = <FirestoreReadinessIssue>[];

    final eventsSnap = await _firestore
        .collection('events')
        .limit(sampleLimit)
        .get();
    final postsSnap = await _firestore
        .collection('posts')
        .limit(sampleLimit)
        .get();
    final convSnap = await _firestore
        .collection('conversations')
        .limit(sampleLimit)
        .get();
    final legacyMessagesSnap = await _firestore
        .collection('messages')
        .limit(sampleLimit)
        .get();

    for (final doc in eventsSnap.docs) {
      final data = doc.data();
      if (_extractDate(data, ['eventDate', 'date']) == null) {
        issues.add(
          FirestoreReadinessIssue(
            collection: 'events',
            documentId: doc.id,
            field: 'eventDate/date',
            message: 'Missing or invalid event date.',
          ),
        );
      }
      if (!_hasString(data, ['title', 'name'])) {
        issues.add(
          FirestoreReadinessIssue(
            collection: 'events',
            documentId: doc.id,
            field: 'title/name',
            message: 'Missing event title.',
          ),
        );
      }
      if (!_hasString(data, ['posterUrl'])) {
        issues.add(
          FirestoreReadinessIssue(
            collection: 'events',
            documentId: doc.id,
            field: 'posterUrl',
            message: 'Poster URL not set.',
          ),
        );
      }
    }

    for (final doc in postsSnap.docs) {
      final data = doc.data();
      if (_extractDate(data, ['createdAt', 'date', 'publishedAt']) == null) {
        issues.add(
          FirestoreReadinessIssue(
            collection: 'posts',
            documentId: doc.id,
            field: 'createdAt/date/publishedAt',
            message: 'Missing or invalid post timestamp.',
          ),
        );
      }
      if (!_hasString(data, ['content', 'text', 'message'])) {
        issues.add(
          FirestoreReadinessIssue(
            collection: 'posts',
            documentId: doc.id,
            field: 'content/text/message',
            message: 'Missing post content.',
          ),
        );
      }
      if (!_hasString(data, ['userId', 'authorId'])) {
        issues.add(
          FirestoreReadinessIssue(
            collection: 'posts',
            documentId: doc.id,
            field: 'userId/authorId',
            message: 'Missing post author id.',
          ),
        );
      }
    }

    for (final doc in convSnap.docs) {
      final data = doc.data();
      final participants = data['participants'];
      if (participants is! List || participants.isEmpty) {
        issues.add(
          FirestoreReadinessIssue(
            collection: 'conversations',
            documentId: doc.id,
            field: 'participants',
            message: 'Conversation has no participants.',
          ),
        );
      }
    }

    for (final doc in legacyMessagesSnap.docs) {
      final data = doc.data();
      if (!_hasString(data, ['senderId'])) {
        issues.add(
          FirestoreReadinessIssue(
            collection: 'messages',
            documentId: doc.id,
            field: 'senderId',
            message: 'Legacy message missing senderId.',
          ),
        );
      }
      if (!_hasString(data, ['receiverId'])) {
        issues.add(
          FirestoreReadinessIssue(
            collection: 'messages',
            documentId: doc.id,
            field: 'receiverId',
            message: 'Legacy message missing receiverId.',
          ),
        );
      }
      if (_extractDate(data, ['sentAt', 'createdAt', 'date']) == null) {
        issues.add(
          FirestoreReadinessIssue(
            collection: 'messages',
            documentId: doc.id,
            field: 'sentAt/createdAt/date',
            message: 'Legacy message missing timestamp.',
          ),
        );
      }
    }

    return FirestoreReadinessReport(
      checkedAt: DateTime.now(),
      eventSamples: eventsSnap.docs.length,
      postSamples: postsSnap.docs.length,
      conversationSamples: convSnap.docs.length,
      legacyMessageSamples: legacyMessagesSnap.docs.length,
      issues: issues,
    );
  }

  bool _hasString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  DateTime? _extractDate(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}
