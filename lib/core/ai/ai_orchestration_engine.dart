import '../auth/role_router.dart';

/// The brain that decides which AI personas activate for the logged-in user.
class AiOrchestrationEngine {
  final Set<String> activePersonas = {};

  /// Dynamically populates the active personas based on the user's role and identity.
  void activateForUser({
    required String gender,
    required UserRole role,
  }) {
    activePersonas.clear();

    // Female-only guardian (Shakura)
    if (gender.toLowerCase() == "female") {
      activePersonas.add("shakura");
    }

    // Fighters get performance + wellness + tactical AIs
    if (role == UserRole.fighter) {
      activePersonas.add("neuralCoach");
      activePersonas.add("wellnessMentor");
      activePersonas.add("mmaExpert");
      activePersonas.add("cutmanAi");
    }

    // Promoters get business + radar/discovery AIs
    if (role == UserRole.promoter) {
      activePersonas.add("promoterAi");
      activePersonas.add("creatorAi");
    }

    // Gyms get operational AI
    if (role == UserRole.gym) {
      activePersonas.add("gymAi");
    }
  }

  /// Check if a specific persona is currently active for the user session
  bool isActive(String personaId) {
    return activePersonas.contains(personaId);
  }
}
