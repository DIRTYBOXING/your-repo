class GrowthDataModel {
  final int streakDays;
  final int nextMilestone;
  final int milestoneReward;
  final String referralCode;
  final int totalReferrals;
  final List<MissionModel> missions;

  GrowthDataModel({
    required this.streakDays,
    required this.nextMilestone,
    required this.milestoneReward,
    required this.referralCode,
    required this.totalReferrals,
    required this.missions,
  });

  factory GrowthDataModel.fromJson(Map<String, dynamic> json) =>
      GrowthDataModel(
        streakDays: json['streakDays'] ?? 0,
        nextMilestone: json['nextMilestone'] ?? 7,
        milestoneReward: json['milestoneReward'] ?? 0,
        referralCode: json['referralCode'] ?? '',
        totalReferrals: json['totalReferrals'] ?? 0,
        missions:
            (json['missions'] as List<dynamic>?)
                ?.map(
                  (e) => MissionModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList() ??
            [],
      );
}

class MissionModel {
  final String id;
  final String title;
  final String description;
  final int rewardTokens;
  final String status; // INCOMPLETE, CLAIMABLE, COMPLETED

  MissionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardTokens,
    required this.status,
  });

  factory MissionModel.fromJson(Map<String, dynamic> json) => MissionModel(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    rewardTokens: json['rewardTokens'] ?? 0,
    status: json['status'] ?? 'INCOMPLETE',
  );
}
