import '../../api_service.dart';
import '../models/odd_model.dart';

class BettingRepository {
  final ApiService api;
  BettingRepository({required this.api});

  Future<List<OddModel>> getOdds() async {
    final data = await api.callFunction("getOdds");
    final list = data["odds"] as List<dynamic>? ?? [];
    return list
        .map((e) => OddModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> placeBet(
    List<Map<String, dynamic>> bets,
    double totalWagered,
  ) async {
    await api.callFunction("placeBet", {
      "bets": bets,
      "totalWagered": totalWagered,
    });
  }
}
