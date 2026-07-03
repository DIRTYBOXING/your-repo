enum UserRole { fan, fighter, promoter, gym, sponsor }

class RoleRouter {
  /// Returns the GoRouter path for the user's specific dashboard/home.
  static String getInitialRoute(UserRole role) {
    switch (role) {
      case UserRole.fan:
        return '/feed'; // Fans go straight to social/PPV feed
      case UserRole.fighter:
        return '/fighter/journal'; // Fighters go to AstroHealth / Wellness Journal
      case UserRole.promoter:
        return '/promoter'; // Promoters go to Control Room
      case UserRole.gym:
        return '/gym'; // Gyms go to Dojo Manager / Gym Hub
      case UserRole.sponsor:
        return '/revenue'; // Sponsors go to Commercial Revenue Dashboard
    }
  }
}
