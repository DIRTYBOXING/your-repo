import '../models/growth_model.dart';

/// V12 STATE MACHINE: DISTRIBUTION & GROWTH
sealed class GrowthState {}

class GrowthInitial extends GrowthState {}

class GrowthLoading extends GrowthState {}

class GrowthLoaded extends GrowthState {
  final GrowthDataModel data;
  GrowthLoaded(this.data);
}

class GrowthError extends GrowthState {
  final String message;
  GrowthError(this.message);
}
