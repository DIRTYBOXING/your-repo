import '../models/pickem_model.dart';

/// V12 STATE MACHINE: FAN PICK'EMS
sealed class PickemState {}

class PickemInitial extends PickemState {}

class PickemLoading extends PickemState {}

class PickemLoaded extends PickemState {
  final List<PickemModel> pickems;
  PickemLoaded(this.pickems);
}

class PickemError extends PickemState {
  final String message;
  PickemError(this.message);
}
