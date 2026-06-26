import 'dart:math';

/// A lightweight item that can be clustered on a map.
class ClusterItem {
  final String id;
  final double lat;
  final double lng;
  final Map<String, dynamic> data;

  const ClusterItem({
    required this.id,
    required this.lat,
    required this.lng,
    this.data = const {},
  });
}

/// A cluster of one or more [ClusterItem]s positioned at their centroid.
class Cluster {
  final double lat;
  final double lng;
  final List<ClusterItem> items;

  Cluster({required this.lat, required this.lng, required this.items});

  bool get isCluster => items.length > 1;
  int get count => items.length;
}

/// Simple grid-based clustering tuned for Google Maps zoom levels 0–21.
///
/// Projects items to Mercator world coordinates, buckets them into a grid
/// whose cell size is [gridSizePx] pixels at the given [zoom], then returns
/// one [Cluster] per non-empty cell positioned at the centroid of its items.
List<Cluster> clusterMarkers({
  required List<ClusterItem> items,
  required double zoom,
  int gridSizePx = 80,
}) {
  if (items.isEmpty) return [];

  double lonToX(double lon) => (lon + 180.0) / 360.0;
  double latToY(double lat) {
    final sinLat = sin(lat * pi / 180.0);
    return 0.5 - (log((1 + sinLat) / (1 - sinLat)) / (4 * pi));
  }

  final worldSize = 256 * pow(2, zoom);
  final cellSize = gridSizePx.toDouble();

  final Map<String, List<ClusterItem>> buckets = {};

  for (final item in items) {
    final x = (lonToX(item.lng) * worldSize / cellSize).floor();
    final y = (latToY(item.lat) * worldSize / cellSize).floor();
    final key = '$x:$y';
    buckets.putIfAbsent(key, () => []).add(item);
  }

  return buckets.values.map((list) {
    double sumLat = 0, sumLng = 0;
    for (final it in list) {
      sumLat += it.lat;
      sumLng += it.lng;
    }
    return Cluster(
      lat: sumLat / list.length,
      lng: sumLng / list.length,
      items: list,
    );
  }).toList();
}
