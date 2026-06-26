class PickemModel {
  final String id;
  final String eventName;
  final String redCorner;
  final String blueCorner;
  final int rewardTokens;
  final String? userPick;
  final String status; // OPEN, LOCKED, WON, LOST

  PickemModel({
    required this.id,
    required this.eventName,
    required this.redCorner,
    required this.blueCorner,
    required this.rewardTokens,
    this.userPick,
    required this.status,
  });

  factory PickemModel.fromJson(Map<String, dynamic> json) => PickemModel(
    id: json['id'] ?? '',
    eventName: json['eventName'] ?? '',
    redCorner: json['redCorner'] ?? '',
    blueCorner: json['blueCorner'] ?? '',
    rewardTokens: json['rewardTokens'] ?? 0,
    userPick: json['userPick'],
    status: json['status'] ?? 'OPEN',
  );
}
