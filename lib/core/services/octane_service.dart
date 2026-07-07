import 'dart:io';

/// Minimal Octane service stub to satisfy Creative Hub dependencies in CI.
class OctaneService {
  Future<String?> generatePromoVideo({
    required String eventId,
    required List<File> images,
    required String theme,
  }) async {
    if (images.isEmpty) return null;
    return 'https://example.invalid/octane/$eventId/$theme';
  }
}
