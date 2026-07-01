import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/app_logger.dart';

/// ═══════════════════════════════════════════════════════════════════════
/// DFC Bundle Cache Service
///
/// Optimizes Firestore reads by pre-loading bundles and querying from cache.
/// Reduces costs and improves offline-first experience.
/// ═══════════════════════════════════════════════════════════════════════
class BundleCacheService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch a bundle from the server and load it into Firestore cache
  ///
  /// Example:
  /// ```dart
  /// await bundleService.loadBundleFromUrl('/api/createBundle');
  /// ```
  Future<void> loadBundleFromUrl(String bundleUrl) async {
    try {
      AppLogger.info(
        'Fetching bundle from: $bundleUrl',
        tag: 'BundleCacheService',
      );

      // Fetch the bundle from the server
      final uri = Uri.parse(bundleUrl);
      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw Exception('Bundle fetch timeout after 30 seconds'),
          );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch bundle: ${response.statusCode} ${response.reasonPhrase}',
        );
      }

      // Load the bundle contents into Firestore
      final task = _firestore.loadBundle(response.bodyBytes);
      await task.stream.toList();

      AppLogger.info('Bundle loaded successfully', tag: 'BundleCacheService');
    } catch (e) {
      AppLogger.error('Failed to load bundle: $e', tag: 'BundleCacheService');
      rethrow;
    }
  }

  /// Query live data with cache source priority
  ///
  /// Example:
  /// ```dart
  /// final snapshot = await bundleService.queryWithCache(
  ///   collectionPath: 'fighters',
  /// );
  /// ```
  Future<QuerySnapshot<Map<String, dynamic>>> queryWithCache(
    String collectionPath,
  ) async {
    try {
      AppLogger.info(
        'Querying cache for: $collectionPath',
        tag: 'BundleCacheService',
      );

      final snapshot = await _firestore
          .collection(collectionPath)
          .get(const GetOptions(source: Source.cache));

      AppLogger.info(
        'Retrieved ${snapshot.docs.length} documents from cache',
        tag: 'BundleCacheService',
      );

      return snapshot;
    } catch (e) {
      AppLogger.error('Failed to query cache: $e', tag: 'BundleCacheService');
      rethrow;
    }
  }

  /// Load a bundle and immediately query it
  ///
  /// Example:
  /// ```dart
  /// final snapshot = await bundleService.loadAndQuery(
  ///   bundleUrl: '/api/createBundle',
  ///   collectionPath: 'fighters',
  /// );
  /// ```
  Future<QuerySnapshot<Map<String, dynamic>>> loadAndQuery({
    required String bundleUrl,
    required String collectionPath,
  }) async {
    await loadBundleFromUrl(bundleUrl);
    return queryWithCache(collectionPath);
  }

  /// Wait for pending writes to complete
  /// Useful for ensuring data is persisted before app closes
  Future<void> waitForPendingWrites() async {
    try {
      await _firestore.waitForPendingWrites();
      AppLogger.info('Pending writes completed', tag: 'BundleCacheService');
    } catch (e) {
      AppLogger.warning(
        'Error waiting for pending writes: $e',
        tag: 'BundleCacheService',
      );
    }
  }
}
