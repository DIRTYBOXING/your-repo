import '../services/gym_service.dart';

class GymController {
  GymController(this.service);

  final GymService service;

  Future<List<Map<String, dynamic>>> search(String query) => service.search(query);
}
