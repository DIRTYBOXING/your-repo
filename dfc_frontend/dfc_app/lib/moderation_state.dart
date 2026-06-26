import '../models/moderation_model.dart';

/// V12 STATE MACHINE: MODERATION
sealed class ModerationState {}

class ModerationInitial extends ModerationState {}

class ModerationLoading extends ModerationState {}

class ModerationLoaded extends ModerationState {
  final List<ReportModel> reports;
  ModerationLoaded(this.reports);
}

class ModerationError extends ModerationState {
  final String message;
  ModerationError(this.message);
}
