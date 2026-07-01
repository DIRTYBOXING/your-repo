import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Fight status
enum FightStatus { scheduled, live, completed, cancelled, noContest }

/// Fight outcome type
enum FightOutcome {
  ko,
  tko,
  submission,
  decisionUnanimous,
  decisionSplit,
  decisionMajority,
  draw,
  noContest,
  dq,
}

/// Fight model for individual bouts
class FightModel extends Equatable {
  final String id;
  final String eventId;
  final String fighter1Id;
  final String fighter2Id;
  final String? weightClass;
  final int? scheduledRounds;
  final int? roundMinutes;
  final String? sportType;
  final FightStatus status;
  final String? winnerId;
  final FightOutcome? outcome;
  final int? endRound;
  final String? endTime;
  final String? methodDescription;
  final bool isMainEvent;
  final bool isCoMainEvent;
  final bool isTitleFight;
  final String? titleOnTheLine;
  final int cardPosition; // Order on the fight card
  final Map<String, dynamic>? fighter1Stats;
  final Map<String, dynamic>? fighter2Stats;
  final Map<String, dynamic>? judgeScores;
  final DateTime? scheduledTime;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FightModel({
    required this.id,
    required this.eventId,
    required this.fighter1Id,
    required this.fighter2Id,
    this.weightClass,
    this.scheduledRounds,
    this.roundMinutes,
    this.sportType,
    this.status = FightStatus.scheduled,
    this.winnerId,
    this.outcome,
    this.endRound,
    this.endTime,
    this.methodDescription,
    this.isMainEvent = false,
    this.isCoMainEvent = false,
    this.isTitleFight = false,
    this.titleOnTheLine,
    this.cardPosition = 0,
    this.fighter1Stats,
    this.fighter2Stats,
    this.judgeScores,
    this.scheduledTime,
    this.actualStartTime,
    this.actualEndTime,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Is the fight completed
  bool get isCompleted => status == FightStatus.completed;

  /// Is the fight a finish (not decision)
  bool get isFinish =>
      outcome == FightOutcome.ko ||
      outcome == FightOutcome.tko ||
      outcome == FightOutcome.submission;

  /// Fight duration in minutes (if completed)
  int? get durationMinutes {
    if (actualStartTime != null && actualEndTime != null) {
      return actualEndTime!.difference(actualStartTime!).inMinutes;
    }
    return null;
  }

  factory FightModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FightModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      fighter1Id: data['fighter1Id'] ?? '',
      fighter2Id: data['fighter2Id'] ?? '',
      weightClass: data['weightClass'],
      scheduledRounds: data['scheduledRounds'],
      roundMinutes: data['roundMinutes'],
      sportType: data['sportType'],
      status: FightStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => FightStatus.scheduled,
      ),
      winnerId: data['winnerId'],
      outcome: data['outcome'] != null
          ? FightOutcome.values.firstWhere(
              (o) => o.name == data['outcome'],
              orElse: () => FightOutcome.noContest,
            )
          : null,
      endRound: data['endRound'],
      endTime: data['endTime'],
      methodDescription: data['methodDescription'],
      isMainEvent: data['isMainEvent'] ?? false,
      isCoMainEvent: data['isCoMainEvent'] ?? false,
      isTitleFight: data['isTitleFight'] ?? false,
      titleOnTheLine: data['titleOnTheLine'],
      cardPosition: data['cardPosition'] ?? 0,
      fighter1Stats: data['fighter1Stats'],
      fighter2Stats: data['fighter2Stats'],
      judgeScores: data['judgeScores'],
      scheduledTime: (data['scheduledTime'] as Timestamp?)?.toDate(),
      actualStartTime: (data['actualStartTime'] as Timestamp?)?.toDate(),
      actualEndTime: (data['actualEndTime'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'fighter1Id': fighter1Id,
      'fighter2Id': fighter2Id,
      'weightClass': weightClass,
      'scheduledRounds': scheduledRounds,
      'roundMinutes': roundMinutes,
      'sportType': sportType,
      'status': status.name,
      'winnerId': winnerId,
      'outcome': outcome?.name,
      'endRound': endRound,
      'endTime': endTime,
      'methodDescription': methodDescription,
      'isMainEvent': isMainEvent,
      'isCoMainEvent': isCoMainEvent,
      'isTitleFight': isTitleFight,
      'titleOnTheLine': titleOnTheLine,
      'cardPosition': cardPosition,
      'fighter1Stats': fighter1Stats,
      'fighter2Stats': fighter2Stats,
      'judgeScores': judgeScores,
      'scheduledTime': scheduledTime != null
          ? Timestamp.fromDate(scheduledTime!)
          : null,
      'actualStartTime': actualStartTime != null
          ? Timestamp.fromDate(actualStartTime!)
          : null,
      'actualEndTime': actualEndTime != null
          ? Timestamp.fromDate(actualEndTime!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  FightModel copyWith({
    String? id,
    String? eventId,
    String? fighter1Id,
    String? fighter2Id,
    String? weightClass,
    int? scheduledRounds,
    int? roundMinutes,
    String? sportType,
    FightStatus? status,
    String? winnerId,
    FightOutcome? outcome,
    int? endRound,
    String? endTime,
    String? methodDescription,
    bool? isMainEvent,
    bool? isCoMainEvent,
    bool? isTitleFight,
    String? titleOnTheLine,
    int? cardPosition,
    Map<String, dynamic>? fighter1Stats,
    Map<String, dynamic>? fighter2Stats,
    Map<String, dynamic>? judgeScores,
    DateTime? scheduledTime,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FightModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      fighter1Id: fighter1Id ?? this.fighter1Id,
      fighter2Id: fighter2Id ?? this.fighter2Id,
      weightClass: weightClass ?? this.weightClass,
      scheduledRounds: scheduledRounds ?? this.scheduledRounds,
      roundMinutes: roundMinutes ?? this.roundMinutes,
      sportType: sportType ?? this.sportType,
      status: status ?? this.status,
      winnerId: winnerId ?? this.winnerId,
      outcome: outcome ?? this.outcome,
      endRound: endRound ?? this.endRound,
      endTime: endTime ?? this.endTime,
      methodDescription: methodDescription ?? this.methodDescription,
      isMainEvent: isMainEvent ?? this.isMainEvent,
      isCoMainEvent: isCoMainEvent ?? this.isCoMainEvent,
      isTitleFight: isTitleFight ?? this.isTitleFight,
      titleOnTheLine: titleOnTheLine ?? this.titleOnTheLine,
      cardPosition: cardPosition ?? this.cardPosition,
      fighter1Stats: fighter1Stats ?? this.fighter1Stats,
      fighter2Stats: fighter2Stats ?? this.fighter2Stats,
      judgeScores: judgeScores ?? this.judgeScores,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    eventId,
    fighter1Id,
    fighter2Id,
    status,
    winnerId,
    outcome,
  ];
}
