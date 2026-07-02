class RankingSnapshot {
  RankingSnapshot({
    required this.fighterId,
    required this.oldPosition,
    required this.newPosition,
    required this.timestamp,
  });

  final String fighterId;
  final int oldPosition;
  final int newPosition;
  final DateTime timestamp;
}
