import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';

/// Gathers all user data and packages it for download.
/// GDPR Article 20 · AU Privacy Principle 12
class DataExportService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  String _status = '';
  String get status => _status;

  double _progress = 0.0;
  double get progress => _progress;

  /// Collect all user data into a structured Map, then return as JSON string.
  Future<String?> exportUserData(
    String userId, {
    bool includePosts = true,
    bool includeMessages = true,
    bool includeProfile = true,
    bool includeTraining = true,
    bool includeWellness = true,
    bool includePurchases = true,
    bool includeAnalytics = true,
  }) async {
    _isExporting = true;
    _progress = 0.0;
    _status = 'Gathering your data...';
    notifyListeners();

    try {
      final export = <String, dynamic>{
        'exportDate': DateTime.now().toIso8601String(),
        'userId': userId,
        'format': 'DFC_DATA_EXPORT_v1',
      };

      var step = 0;
      final totalSteps = [
        includeProfile,
        includePosts,
        includeMessages,
        includeTraining,
        includeWellness,
        includePurchases,
        includeAnalytics,
      ].where((b) => b).length;

      // Profile
      if (includeProfile) {
        _status = 'Exporting profile...';
        notifyListeners();
        export['profile'] = await _getDoc(AppConstants.usersCollection, userId);
        export['consents'] = await _getCollection('consents', 'userId', userId);
        step++;
        _progress = step / totalSteps;
        notifyListeners();
      }

      // Posts & Comments
      if (includePosts) {
        _status = 'Exporting posts & comments...';
        notifyListeners();
        export['posts'] = await _getCollection('posts', 'authorId', userId);
        export['comments'] = await _getCollection(
          'comments',
          'authorId',
          userId,
        );
        export['fightwire_posts'] = await _getCollection(
          'fightwire_posts',
          'authorId',
          userId,
        );
        export['articles'] = await _getCollection(
          'articles',
          'authorId',
          userId,
        );
        export['stories'] = await _getCollection('stories', 'authorId', userId);
        export['saved_posts'] = await _getCollection(
          'saved_posts',
          'userId',
          userId,
        );
        step++;
        _progress = step / totalSteps;
        notifyListeners();
      }

      // Messages
      if (includeMessages) {
        _status = 'Exporting messages...';
        notifyListeners();
        export['messages_sent'] = await _getCollection(
          'messages',
          'senderId',
          userId,
        );
        export['messages_received'] = await _getCollection(
          'messages',
          'receiverId',
          userId,
        );
        step++;
        _progress = step / totalSteps;
        notifyListeners();
      }

      // Training
      if (includeTraining) {
        _status = 'Exporting training data...';
        notifyListeners();
        export['training_logs'] = await _getCollection(
          'training_logs',
          'userId',
          userId,
        );
        export['fighter_stats'] = await _getDoc('fighter_stats', userId);
        step++;
        _progress = step / totalSteps;
        notifyListeners();
      }

      // Wellness
      if (includeWellness) {
        _status = 'Exporting wellness data...';
        notifyListeners();
        export['wellness_logs'] = await _getCollection(
          'wellness_logs',
          'userId',
          userId,
        );
        step++;
        _progress = step / totalSteps;
        notifyListeners();
      }

      // Purchases
      if (includePurchases) {
        _status = 'Exporting purchase history...';
        notifyListeners();
        export['ppv_purchases'] = await _getCollection(
          'ppv_purchases',
          'userId',
          userId,
        );
        export['ppv_access'] = await _getCollection(
          'ppv_access',
          'userId',
          userId,
        );
        step++;
        _progress = step / totalSteps;
        notifyListeners();
      }

      // Analytics
      if (includeAnalytics) {
        _status = 'Exporting analytics...';
        notifyListeners();
        export['watch_history'] = await _getCollection(
          'watch_history',
          'userId',
          userId,
        );
        step++;
        _progress = step / totalSteps;
        notifyListeners();
      }

      _status = 'Packaging data...';
      _progress = 1.0;
      notifyListeners();

      final jsonString = const JsonEncoder.withIndent('  ').convert(export);

      _isExporting = false;
      _status = 'Export ready!';
      notifyListeners();

      return jsonString;
    } catch (e) {
      _isExporting = false;
      _status = 'Export failed: ${e.toString()}';
      notifyListeners();
      debugPrint('DataExport error: $e');
      return null;
    }
  }

  /// Get a single document as Map
  Future<Map<String, dynamic>?> _getDoc(String collection, String docId) async {
    final doc = await _db.collection(collection).doc(docId).get();
    if (!doc.exists) return null;
    final data = doc.data();
    return _sanitizeForJson(data);
  }

  /// Get all documents matching a field query
  Future<List<Map<String, dynamic>>> _getCollection(
    String collection,
    String field,
    String userId,
  ) async {
    final snapshot = await _db
        .collection(collection)
        .where(field, isEqualTo: userId)
        .get();
    return snapshot.docs.map((d) => _sanitizeForJson(d.data()) ?? {}).toList();
  }

  /// Convert Firestore types (Timestamp, GeoPoint) to JSON-safe values
  Map<String, dynamic>? _sanitizeForJson(Map<String, dynamic>? data) {
    if (data == null) return null;
    return data.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.toDate().toIso8601String());
      } else if (value is GeoPoint) {
        return MapEntry(key, {'lat': value.latitude, 'lng': value.longitude});
      } else if (value is Map<String, dynamic>) {
        return MapEntry(key, _sanitizeForJson(value));
      } else if (value is List) {
        return MapEntry(
          key,
          value.map((v) {
            if (v is Timestamp) return v.toDate().toIso8601String();
            if (v is Map<String, dynamic>) return _sanitizeForJson(v);
            return v;
          }).toList(),
        );
      }
      return MapEntry(key, value);
    });
  }
}
