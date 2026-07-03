import 'api_service.dart';

class PpvRepository {
  final ApiService api;
  PpvRepository({required this.api});

  Future<bool> checkEntitlement(String eventId) async {
    final data = await api.callFunction("checkPpvEntitlement", {"eventId": eventId});
    return data["hasAccess"] == true;
  }

  Future<Map<String, dynamic>> getStatus(String eventId) async {
    return await api.callFunction("getPPVStatus", {"eventId": eventId});
  }

  Future<String?> getStream(String eventId) async {
    final data = await api.callFunction("getPPVStream", {"eventId": eventId});
    return data["playbackId"];
  }

  Future<void> purchase(String eventId) async {
    await api.callFunction("purchasePpv", {"eventId": eventId});
  }
}