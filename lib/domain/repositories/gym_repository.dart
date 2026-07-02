import '../entities/gym.dart';

abstract class GymRepository {
  Future<List<Gym>> listGyms();
  Future<List<Gym>> searchGyms(String query);
}
