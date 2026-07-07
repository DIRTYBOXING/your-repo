import 'achievement_model.dart';

abstract class AchievementState {}

class AchievementInitial extends AchievementState {}
class AchievementLoading extends AchievementState {}
class AchievementLoaded extends AchievementState {
  final List<AchievementModel> achievements;
  AchievementLoaded(this.achievements);
}
class AchievementError extends AchievementState {
  final String message;
  AchievementError(this.message);
}