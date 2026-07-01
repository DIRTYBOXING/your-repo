/// V4 STATE MACHINE:
/// Sealed classes guarantee that the UI always handles every possible state.
/// No more impossible states (like isLoading == true AND error != null).
library;
import '../models/dashboard_models.dart';

sealed class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardModel data;

  DashboardLoaded(this.data);
}

class DashboardError extends DashboardState {
  final String message;

  DashboardError(this.message);
}
