import '../models/gym_directory_model.dart';

class GymDirectoryService {
  Future<List<GymDirectoryModel>> fetchGyms() async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate V12 fetch

    return [
      GymDirectoryModel(
        id: "GYM-001",
        name: "ELITE SPARRING TEAM",
        location: "Melbourne, VIC",
        bannerUrl: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&q=80&w=800",
        logoUrl: "https://ui-avatars.com/api/?name=ES&background=0A0E17&color=00E5FF",
        fighterCount: 42,
        championCount: 3,
        tags: ["MMA", "Striking", "Pro Team"],
      ),
      GymDirectoryModel(
        id: "GYM-002",
        name: "ROUGE GRAPPLING ACADEMY",
        location: "Sydney, NSW",
        bannerUrl: "https://images.unsplash.com/photo-1517438476312-10d79c077509?auto=format&fit=crop&q=80&w=800",
        logoUrl: "https://ui-avatars.com/api/?name=RG&background=0A0E17&color=FF3B30",
        fighterCount: 120,
        championCount: 1,
        tags: ["BJJ", "Wrestling", "No-Gi"],
      ),
      GymDirectoryModel(
        id: "GYM-003",
        name: "IRON CHIN BOXING",
        location: "Brisbane, QLD",
        bannerUrl: "https://images.unsplash.com/photo-1549719386-74dfcbf7dbed?auto=format&fit=crop&q=80&w=800",
        logoUrl: "https://ui-avatars.com/api/?name=IC&background=0A0E17&color=FFD600",
        fighterCount: 85,
        championCount: 4,
        tags: ["Boxing", "Cardio", "Youth"],
      ),
    ];
  }
}