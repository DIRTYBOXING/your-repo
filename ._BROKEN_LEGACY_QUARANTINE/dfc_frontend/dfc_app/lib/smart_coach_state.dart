import '../models/smart_coach_model.dart';

/// V12 STATE MACHINE: SMART COACH
sealed class SmartCoachState {}

class SmartCoachInitial extends SmartCoachState {}

class SmartCoachLoading extends SmartCoachState {}

class SmartCoachLoaded extends SmartCoachState {
  final SmartCoachModel data;
  SmartCoachLoaded(this.data);
}

class SmartCoachError extends SmartCoachState {
  final String message;
  SmartCoachError(this.message);
}
