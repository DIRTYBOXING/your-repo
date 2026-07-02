// backend/rights/middleware/region_block_middleware.dart
// Minimal middleware stub that checks region and blocks requests if necessary.
// Adapt the signature to your web framework's middleware shape.
import '../rights/enforcement_service.dart';

typedef NextHandler = Future<dynamic> Function();

class RegionBlockMiddleware {
  final EnforcementService _service;

  RegionBlockMiddleware(this._service);

  /// Example middleware function. Adapt to your framework.
  /// `getRegion` should extract the client's region code (e.g., from headers or IP geolocation).
  Future<dynamic> handle(String contentId, String Function() getRegion, NextHandler next) async {
    final region = getRegion().toUpperCase();
    final result = await _service.evaluateForRegion(contentId, region);
    if (!result.allowed) {
      // Return a framework-agnostic block response. Replace with HTTP 403 in real controller.
      return <String, dynamic>{'allowed': false, 'reason': result.reason};
    }
    return await next();
  }
}
