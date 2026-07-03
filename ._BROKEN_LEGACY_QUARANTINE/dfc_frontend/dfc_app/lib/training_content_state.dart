import '../models/training_content_model.dart';

/// V12 STATE MACHINE: TRAINING VAULT
sealed class TrainingContentState {}

class TrainingContentInitial extends TrainingContentState {}

class TrainingContentLoading extends TrainingContentState {}

class TrainingContentLoaded extends TrainingContentState {
  final List<TrainingContentModel> content;
  TrainingContentLoaded(this.content);
}

class TrainingContentError extends TrainingContentState {
  final String message;
  TrainingContentError(this.message);
}
