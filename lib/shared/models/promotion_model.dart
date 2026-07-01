import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Enum for promotion channels
enum PromotionChannel { social, email, messaging, sms, posters, video }

/// Enum for promotion campaign status
enum PromotionStatus { pending, draft, active, scheduled, expired, completed }

/// Young fighter promotion campaigns with mentor approval workflow
class PromotionCampaign extends Equatable {
  final String id;
  final String fighterId;
  final String fighterName;
  final String title;
  final String description;
  final String? mentorId;
  final String? mentorName;
  final String? eventId;
  final String? eventTitle;
  final PromotionStatus status;
  final bool requiresMentorApproval;
  final bool isApproved;
  final List<Map<String, dynamic>>
  approvalChain; // {mentorId, action, timestamp}
  final List<PromotionChannel> channels;
  final Map<PromotionChannel, String> messages;
  final int targetReach;
  final int currentReach;
  final int engagements;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const PromotionCampaign({
    required this.id,
    required this.fighterId,
    required this.fighterName,
    required this.title,
    required this.description,
    this.mentorId,
    this.mentorName,
    this.eventId,
    this.eventTitle,
    this.status = PromotionStatus.draft,
    this.requiresMentorApproval = true,
    this.isApproved = false,
    this.approvalChain = const [],
    this.channels = const [],
    this.messages = const {},
    this.targetReach = 0,
    this.currentReach = 0,
    this.engagements = 0,
    required this.createdAt,
    this.expiresAt,
  });

  bool get isActive => status == PromotionStatus.active;
  bool get isExpired => status == PromotionStatus.expired;
  bool get isDraft => status == PromotionStatus.draft;

  double get reachPercentage =>
      targetReach > 0 ? (currentReach / targetReach) * 100 : 0.0;

  double get engagementRate =>
      currentReach > 0 ? (engagements / currentReach) * 100 : 0.0;

  PromotionCampaign copyWith({
    String? id,
    String? fighterId,
    String? fighterName,
    String? title,
    String? description,
    String? mentorId,
    String? mentorName,
    String? eventId,
    String? eventTitle,
    PromotionStatus? status,
    bool? requiresMentorApproval,
    bool? isApproved,
    List<Map<String, dynamic>>? approvalChain,
    List<PromotionChannel>? channels,
    Map<PromotionChannel, String>? messages,
    int? targetReach,
    int? currentReach,
    int? engagements,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) => PromotionCampaign(
    id: id ?? this.id,
    fighterId: fighterId ?? this.fighterId,
    fighterName: fighterName ?? this.fighterName,
    title: title ?? this.title,
    description: description ?? this.description,
    mentorId: mentorId ?? this.mentorId,
    mentorName: mentorName ?? this.mentorName,
    eventId: eventId ?? this.eventId,
    eventTitle: eventTitle ?? this.eventTitle,
    status: status ?? this.status,
    requiresMentorApproval:
        requiresMentorApproval ?? this.requiresMentorApproval,
    isApproved: isApproved ?? this.isApproved,
    approvalChain: approvalChain ?? this.approvalChain,
    channels: channels ?? this.channels,
    messages: messages ?? this.messages,
    targetReach: targetReach ?? this.targetReach,
    currentReach: currentReach ?? this.currentReach,
    engagements: engagements ?? this.engagements,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
  );

  // ── Firestore serialization ──────────────────────────────────────

  factory PromotionCampaign.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return PromotionCampaign(
      id: doc.id,
      fighterId: d['fighterId'] ?? '',
      fighterName: d['fighterName'] ?? '',
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      mentorId: d['mentorId'],
      mentorName: d['mentorName'],
      eventId: d['eventId'],
      eventTitle: d['eventTitle'],
      status: PromotionStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => PromotionStatus.draft,
      ),
      requiresMentorApproval: d['requiresMentorApproval'] ?? true,
      isApproved: d['isApproved'] ?? false,
      approvalChain: List<Map<String, dynamic>>.from(d['approvalChain'] ?? []),
      channels:
          (d['channels'] as List?)
              ?.map(
                (c) => PromotionChannel.values.firstWhere(
                  (e) => e.name == c,
                  orElse: () => PromotionChannel.social,
                ),
              )
              .toList() ??
          [],
      messages: Map<PromotionChannel, String>.fromEntries(
        (d['messages'] as Map?)?.entries.map(
              (e) => MapEntry(
                PromotionChannel.values.firstWhere(
                  (pc) => pc.name == e.key,
                  orElse: () => PromotionChannel.social,
                ),
                e.value as String,
              ),
            ) ??
            [],
      ),
      targetReach: d['targetReach'] ?? 0,
      currentReach: d['currentReach'] ?? 0,
      engagements: d['engagements'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'fighterId': fighterId,
    'fighterName': fighterName,
    'title': title,
    'description': description,
    if (mentorId != null) 'mentorId': mentorId,
    if (mentorName != null) 'mentorName': mentorName,
    if (eventId != null) 'eventId': eventId,
    if (eventTitle != null) 'eventTitle': eventTitle,
    'status': status.name,
    'requiresMentorApproval': requiresMentorApproval,
    'isApproved': isApproved,
    'approvalChain': approvalChain,
    'channels': channels.map((c) => c.name).toList(),
    'messages': messages.map((k, v) => MapEntry(k.name, v)),
    'targetReach': targetReach,
    'currentReach': currentReach,
    'engagements': engagements,
    'createdAt': Timestamp.fromDate(createdAt),
    if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
  };

  @override
  List<Object?> get props => [
    id,
    fighterId,
    fighterName,
    title,
    description,
    mentorId,
    mentorName,
    eventId,
    eventTitle,
    status,
    requiresMentorApproval,
    isApproved,
    approvalChain,
    channels,
    messages,
    targetReach,
    currentReach,
    engagements,
    createdAt,
    expiresAt,
  ];
}

/// Legacy promotion type used by promoter module.
enum PromotionType { gymPromo, sponsor, eventBoost, fighterHighlight }

/// Backward-compatible model used by existing promoter screens/services.
class PromotionModel extends Equatable {
  final String id;
  final String advertiserId;
  final PromotionType type;
  final String title;
  final String description;
  final String? mediaUrl;
  final String? targetUrl;
  final double? radiusKm;
  final GeoPoint? targetLocation;
  final PromotionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final int budget;
  final Map<String, int> metrics;

  const PromotionModel({
    required this.id,
    required this.advertiserId,
    required this.type,
    required this.title,
    required this.description,
    this.mediaUrl,
    this.targetUrl,
    this.radiusKm,
    this.targetLocation,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.budget = 0,
    this.metrics = const {'impressions': 0, 'clicks': 0},
  });

  factory PromotionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return PromotionModel(
      id: doc.id,
      advertiserId: d['advertiserId'] ?? '',
      type: PromotionType.values.firstWhere(
        (e) => e.name == d['type'],
        orElse: () => PromotionType.gymPromo,
      ),
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      mediaUrl: d['mediaUrl'],
      targetUrl: d['targetUrl'],
      radiusKm: (d['radiusKm'] as num?)?.toDouble(),
      targetLocation: d['targetLocation'] as GeoPoint?,
      status: PromotionStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => PromotionStatus.pending,
      ),
      startDate: (d['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate:
          (d['endDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      budget: d['budget'] ?? 0,
      metrics: Map<String, int>.from(
        d['metrics'] ?? {'impressions': 0, 'clicks': 0},
      ),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'advertiserId': advertiserId,
    'type': type.name,
    'title': title,
    'description': description,
    if (mediaUrl != null) 'mediaUrl': mediaUrl,
    if (targetUrl != null) 'targetUrl': targetUrl,
    if (radiusKm != null) 'radiusKm': radiusKm,
    if (targetLocation != null) 'targetLocation': targetLocation,
    'status': status.name,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'budget': budget,
    'metrics': metrics,
  };

  int get impressions => metrics['impressions'] ?? 0;
  int get clicks => metrics['clicks'] ?? 0;

  @override
  List<Object?> get props => [
    id,
    advertiserId,
    type,
    title,
    description,
    mediaUrl,
    targetUrl,
    radiusKm,
    targetLocation,
    status,
    startDate,
    endDate,
    budget,
    metrics,
  ];
}
