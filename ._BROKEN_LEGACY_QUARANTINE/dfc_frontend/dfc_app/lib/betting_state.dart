import 'odd_model.dart';

abstract class BettingState {}

class BettingInitial extends BettingState {}

class BettingLoading extends BettingState {}

class BettingLoaded extends BettingState {
  final List<OddModel> odds;
  BettingLoaded(this.odds);
}

class BettingError extends BettingState {
  final String message;
  BettingError(this.message);
}
