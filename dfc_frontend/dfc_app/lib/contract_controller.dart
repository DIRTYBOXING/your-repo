import 'package:flutter/foundation.dart';
import 'contract_repository.dart';
import 'contract_state.dart';

class ContractController extends ChangeNotifier {
  final ContractRepository repo;

  ContractState _state = ContractInitial();
  ContractState get state => _state;

  ContractController({required this.repo});

  Future<void> loadNegotiations() async {
    _state = ContractLoading();
    notifyListeners();
    try {
      final data = await repo.getNegotiations();
      _state = ContractLoaded(data['contracts'], data['budget']);
    } catch (e) {
      _state = ContractError(e.toString());
    } finally {
      notifyListeners();
    }
  }

  Future<void> sendOffer(String fighterId, double basePurse, double winBonus) async {
    try {
      await repo.sendOffer(fighterId, basePurse, winBonus);
      await loadNegotiations();
    } catch (e) {
      _state = ContractError("Failed to send offer: $e");
      notifyListeners();
    }
  }
}