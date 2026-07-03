import 'fighter_model.dart';

/// V12 STATE MACHINE: FIGHTERS
sealed class FighterState {}

class FighterInitial extends FighterState {}

class FighterLoading extends FighterState {}

class FighterLoaded extends FighterState {
  final List<FighterModel> fighters;
  FighterLoaded(this.fighters);
}

class FighterError extends FighterState {
  final String message;
  FighterError(this.message);
}
