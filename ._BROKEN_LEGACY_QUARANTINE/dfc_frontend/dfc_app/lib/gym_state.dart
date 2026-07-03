import '../models/gym_model.dart';

/// V12 STATE MACHINE: GYM PROFILE
sealed class GymState {}

class GymInitial extends GymState {}

class GymLoading extends GymState {}

class GymLoaded extends GymState {
  final GymModel data;
  GymLoaded(this.data);
}

class GymError extends GymState {
  final String message;
  GymError(this.message);
}
