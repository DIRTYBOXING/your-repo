import 'package:flutter/foundation.dart';
import 'betting_repository.dart';
import 'betting_state.dart';

class BettingController extends ChangeNotifier {
  final BettingRepository repo;
  BettingState _state = BettingInitial();
  BettingState get state => _state;

  int slipCount = 0;
  double totalWagered = 0.0;
  double potentialPayout = 0.0;
  final List<Map<String, dynamic>> _bets = [];

  BettingController({required this.repo});

  Future<void> loadOdds() async {
    _state = BettingLoading();
    notifyListeners();
    try {
      final data = await repo.getOdds();
      _state = BettingLoaded(data);
    } catch (e) {
      _state = BettingError(e.toString());
    }
    notifyListeners();
  }

  void addToSlip(String pick, String odds, double wager, double payout) {
    _bets.add({"pick": pick, "odds": odds, "wager": wager, "payout": payout});
    slipCount++;
    totalWagered += wager;
    potentialPayout += payout;
    notifyListeners();
  }

  Future<void> submitBets() async {
    await repo.placeBet(_bets, totalWagered);
    _bets.clear();
    slipCount = 0;
    totalWagered = 0;
    potentialPayout = 0;
    notifyListeners();
  }
}
