class GymDirectoryModel {
  final String id;
  final String name;
  final String location;
  final String bannerUrl;
  final String logoUrl;
  final int fighterCount;
  final int championCount;
  final List<String> tags;

  GymDirectoryModel({
    required this.id,
    required this.name,
    required this.location,
    required this.bannerUrl,
    required this.logoUrl,
    required this.fighterCount,
    required this.championCount,
    required this.tags,
  });
}