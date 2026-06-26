import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Singleton that serves precomputed cluster-icon PNGs (1–100) as
/// [BitmapDescriptor]s.  Icons live in `assets/cluster_icons/`.
///
/// Usage:
///   final icon = await ClusterIconLoader.instance.forCount(count);
class ClusterIconLoader {
  ClusterIconLoader._();
  static final ClusterIconLoader instance = ClusterIconLoader._();

  final Map<int, BitmapDescriptor> _cache = {};

  /// Returns the [BitmapDescriptor] for a cluster with [count] items.
  /// Counts 1–100 use precomputed PNGs; counts >100 reuse the icon for 100.
  Future<BitmapDescriptor> forCount(int count) async {
    final clamped = count.clamp(1, 100);
    if (_cache.containsKey(clamped)) return _cache[clamped]!;

    final byteData = await rootBundle.load(
      'assets/cluster_icons/cluster_$clamped.png',
    );
    final icon = BitmapDescriptor.bytes(byteData.buffer.asUint8List());
    _cache[clamped] = icon;
    return icon;
  }
}
