import '../models/weight_cut_model.dart';

/// V12 STATE MACHINE: WEIGHT CUT
sealed class WeightCutState {}

class WeightCutInitial extends WeightCutState {}

class WeightCutLoading extends WeightCutState {}

class WeightCutLoaded extends WeightCutState {
  final WeightCutModel data;
  WeightCutLoaded(this.data);
}

class WeightCutError extends WeightCutState {
  final String message;
  WeightCutError(this.message);
}
