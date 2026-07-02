import '../services/rankings_service.dart';

class RankingsController {
  RankingsController(this.service);

  final RankingsService service;

  Future<List<Map<String, dynamic>>> load(String division) => service.loadDivision(division);
}
