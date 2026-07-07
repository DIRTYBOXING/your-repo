import '../services/maps_service.dart';

class MapsController {
  MapsController(this.service);

  final MapsService service;

  Future<Map<String, List<Map<String, dynamic>>>> load() async {
    final events = await service.loadEventMarkers();
    final gyms = await service.loadGymMarkers();
    return {'events': events, 'gyms': gyms};
  }
}
