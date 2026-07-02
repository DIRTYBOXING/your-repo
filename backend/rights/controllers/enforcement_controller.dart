// backend/rights/controllers/enforcement_controller.dart
// Framework-agnostic controller scaffold. Adapt to your HTTP framework (Express, FastAPI, Spring, etc.)
import '../rights/enforcement_service.dart';

class EnforcementController {
  final EnforcementService _service;

  EnforcementController(this._service);

  /// Handler for GET /rights/{contentId}
  /// Returns a JSON representation of rights (stubbed).
  Future<Map<String, dynamic>> getRights(String contentId) async {
    final rights = await _service.loadContentRights(contentId);
    if (rights == null) {
      return <String, dynamic>{'error': 'not_found'};
    }
    return <String, dynamic>{
      'contentId': rights.contentId,
      'ownerId': rights.ownerId,
      'allowedRegions': rights.allowedRegions,
      'rights': rights.rights,
    };
  }

  /// Handler for GET /rights/enforce/{contentId}?region={code}
  Future<Map<String, dynamic>> enforceForRegion(String contentId, String regionCode) async {
    final result = await _service.evaluateForRegion(contentId, regionCode);
    return <String, dynamic>{
      'contentId': contentId,
      'region': regionCode,
      'allowed': result.allowed,
      'reason': result.reason,
    };
  }

  /// Handler for POST /rights/takedown
  Future<Map<String, dynamic>> takedown(String contentId, {String? reason}) async {
    final req = await _service.createTakedown(contentId, reason: reason);
    return <String, dynamic>{
      'requestId': req.requestId,
      'contentId': req.contentId,
      'status': req.status,
    };
  }
}
