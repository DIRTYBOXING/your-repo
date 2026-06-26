// Core data models for DFC foundation

class GymProfile {
  final String id;
  final String name;
  final String location;
  final String contactEmail;
  final List<FighterProfile> fighters;
  final List<Event> events;
  final List<String> memberships;

  GymProfile({
    required this.id,
    required this.name,
    required this.location,
    required this.contactEmail,
    required this.fighters,
    required this.events,
    required this.memberships,
  });
}

class FighterProfile {
  final String id;
  final String name;
  final String gymId;
  final Map<String, dynamic> stats;
  final List<String> fightHistory;
  final Map<String, dynamic> biometrics;
  final double trainingLoad;
  final double injuryRisk;
  final String coachNotes;
  final Map<String, dynamic> aiPredictions;
  final List<String> sponsorships;

  FighterProfile({
    required this.id,
    required this.name,
    required this.gymId,
    required this.stats,
    required this.fightHistory,
    required this.biometrics,
    required this.trainingLoad,
    required this.injuryRisk,
    required this.coachNotes,
    required this.aiPredictions,
    required this.sponsorships,
  });
}

class Event {
  final String id;
  final String name;
  final DateTime date;
  final String location;
  final List<String> participants;
  final String results;
  final List<String> mediaLinks;
  final String ticketingInfo;

  Event({
    required this.id,
    required this.name,
    required this.date,
    required this.location,
    required this.participants,
    required this.results,
    required this.mediaLinks,
    required this.ticketingInfo,
  });
}

class User {
  final String uid;
  final String email;
  final String role;
  final DateTime createdAt;

  User({
    required this.uid,
    required this.email,
    required this.role,
    required this.createdAt,
  });
}

class Fighter {
  final String uid;
  final String name;
  final String weightClass;
  final String style;

  Fighter({
    required this.uid,
    required this.name,
    required this.weightClass,
    required this.style,
  });
}

class Gym {
  final String id;
  final String name;
  final String location;

  Gym({required this.id, required this.name, required this.location});
}

class Fight {
  final String id;
  final String eventId;
  final String fighter1Id;
  final String fighter2Id;
  final String winnerId;

  Fight({
    required this.id,
    required this.eventId,
    required this.fighter1Id,
    required this.fighter2Id,
    required this.winnerId,
  });
}

class Ranking {
  final String fighterId;
  final int rank;
  final String weightClass;

  Ranking({
    required this.fighterId,
    required this.rank,
    required this.weightClass,
  });
}

class FighterBranding {
  final String fighterId;
  final String brandName;
  final String logoUrl;

  FighterBranding({
    required this.fighterId,
    required this.brandName,
    required this.logoUrl,
  });
}
