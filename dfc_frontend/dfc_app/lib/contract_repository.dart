import 'api_service.dart';
import 'contract_model.dart';

class ContractRepository {
  final ApiService api;
  ContractRepository({required this.api});

  Future<Map<String, dynamic>> getNegotiations() async {
    final data = await api.callFunction("getNegotiations");
    final list = data["contracts"] as List<dynamic>? ?? [];
    final budgetData = data["budget"] ?? {"total": 0, "committed": 0};

    return {
      "contracts": list.map((e) => ContractModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      "budget": BudgetModel(
        total: (budgetData["total"] ?? 0).toDouble(),
        committed: (budgetData["committed"] ?? 0).toDouble(),
      ),
    };
  }

  Future<void> sendOffer(String fighterId, double basePurse, double winBonus) async {
    await api.callFunction("sendContractOffer", {
      "fighterId": fighterId, "basePurse": basePurse, "winBonus": winBonus,
    });
  }
}