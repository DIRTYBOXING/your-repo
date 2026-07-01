import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared compatibility helpers for mixed Firestore schemas.
class FirestoreCompat {
  FirestoreCompat._();

  /// Parses flexible date fields used across legacy and normalized docs.
  static DateTime? parseFlexibleDate(Map<String, dynamic> data) {
    final dynamic value =
        data['eventDate'] ??
        data['date'] ??
        data['publishedAt'] ??
        data['createdAt'] ??
        data['sentAt'];

    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }

  /// Converts flexible values to Firestore Timestamp for write paths.
  static Timestamp? toTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value;
    if (value is DateTime) return Timestamp.fromDate(value);
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return Timestamp.fromDate(parsed);
      return null;
    }
    if (value is int) return Timestamp.fromMillisecondsSinceEpoch(value);
    if (value is double) {
      return Timestamp.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }
}
