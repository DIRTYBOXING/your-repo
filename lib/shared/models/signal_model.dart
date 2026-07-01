import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Signal Types - Every piece of content in DataFightCentral is a Signal
enum SignalType {
  event, // Fight cards, events, shows
  opportunity, // Fighters needed, short notice, sponsors
  news, // Boxing, MMA, ONE, BK, Kickboxing news
  camp, // Training updates, camp signals
  mentor, // Coach insights, mentor recognition
  culture, // MCs, refs, honours, legacy
  honour, // Recognition, fallen heroes, legends
  aiInsight, // AI Coach wisdom, health interpretation
  safety, // Mental health, support, redlines
  community, // General community signals
}

/// Combat Verticals - Different sports have different tones
enum CombatVertical {
  boxing,
  mma,
  oneChampionship, // Traditional martial arts, honour, discipline
  kickboxing,
  muayThai,
  bareKnuckle, // BKB, raw, gritty
  dirtyBoxing, // DBX, underground
  internationalBrawling,
  regional, // AU/NZ local shows
}

/// Signal Priority - Determines urgency and visibility
enum SignalPriority { low, normal, high, urgent, critical }

/// Signal State - Lifecycle management
enum SignalState {
  live, // Active in feeds
  escalated, // Boosted due to urgency
  expired, // Past expiry, hidden from feeds
  archived, // Historical record, searchable
}

/// The core Signal model - used everywhere in DataFightCentral
/// FightWire, Events, Opportunities, AI Insights - all are Signals
class Signal extends Equatable {
  final String id;
  final SignalType type;
  final SignalPriority priority;
  final SignalState state;
  final CombatVertical? vertical;

  final String title;
  final String summary;
  final String? body;

  // Source identification
  final String? sourceId; // Who created this
  final String? sourceRole; // fighter, promoter, gym, ai, system
  final bool verified;

  // Location relevance
  final String? country;
  final String? region;
  final String? city;

  // Timing
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? escalatedAt;

  // Call to Action
  final String? ctaLabel;
  final String? ctaUrl;

  // Related entities
  final String? eventId;
  final String? promotionId;
  final String? fighterId;
  final String? gymId;

  // Visual assets
  final String? imageUrl;

  // Metadata
  final List<String> tags;
  final Map<String, dynamic>? payload;

  const Signal({
    required this.id,
    required this.type,
    this.priority = SignalPriority.normal,
    this.state = SignalState.live,
    this.vertical,
    required this.title,
    required this.summary,
    this.body,
    this.sourceId,
    this.sourceRole,
    this.verified = false,
    this.country,
    this.region,
    this.city,
    required this.createdAt,
    this.expiresAt,
    this.escalatedAt,
    this.ctaLabel,
    this.ctaUrl,
    this.eventId,
    this.promotionId,
    this.fighterId,
    this.gymId,
    this.imageUrl,
    this.tags = const [],
    this.payload,
  });

  /// Evaluate signal lifecycle state based on time
  static SignalState evaluateLifecycle({
    required DateTime createdAt,
    DateTime? expiresAt,
    bool urgent = false,
  }) {
    final now = DateTime.now();

    // Check expiry first
    if (expiresAt != null && now.isAfter(expiresAt)) {
      return SignalState.expired;
    }

    // Urgent signals escalate within first 24 hours
    if (urgent && now.difference(createdAt).inHours < 24) {
      return SignalState.escalated;
    }

    // Auto-archive after 30 days
    if (now.difference(createdAt).inDays > 30) {
      return SignalState.archived;
    }

    return SignalState.live;
  }

  /// Get accent color based on signal type
  static int getAccentColorValue(SignalType type) {
    switch (type) {
      case SignalType.event:
        return 0xFFE74C3C; // Red
      case SignalType.opportunity:
        return 0xFFF39C12; // Orange
      case SignalType.news:
        return 0xFF3498DB; // Blue
      case SignalType.camp:
        return 0xFF2ECC71; // Green
      case SignalType.mentor:
        return 0xFF9B59B6; // Purple
      case SignalType.culture:
        return 0xFFE91E63; // Pink
      case SignalType.honour:
        return 0xFFFFD700; // Gold
      case SignalType.aiInsight:
        return 0xFF00F5FF; // Cyan (neon)
      case SignalType.safety:
        return 0xFFE74C3C; // Red
      case SignalType.community:
        return 0xFF1ABC9C; // Teal
    }
  }

  /// Create from Firestore document
  factory Signal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Signal(
      id: doc.id,
      type: SignalType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => SignalType.community,
      ),
      priority: SignalPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => SignalPriority.normal,
      ),
      state: SignalState.values.firstWhere(
        (e) => e.name == data['state'],
        orElse: () => SignalState.live,
      ),
      vertical: data['vertical'] != null
          ? CombatVertical.values.firstWhere(
              (e) => e.name == data['vertical'],
              orElse: () => CombatVertical.mma,
            )
          : null,
      title: data['title'] ?? '',
      summary: data['summary'] ?? '',
      body: data['body'],
      sourceId: data['sourceId'],
      sourceRole: data['sourceRole'],
      verified: data['verified'] ?? false,
      country: data['country'],
      region: data['region'],
      city: data['city'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      escalatedAt: (data['escalatedAt'] as Timestamp?)?.toDate(),
      ctaLabel: data['ctaLabel'],
      ctaUrl: data['ctaUrl'],
      eventId: data['eventId'],
      promotionId: data['promotionId'],
      fighterId: data['fighterId'],
      gymId: data['gymId'],
      imageUrl: data['imageUrl'] ?? data['posterUrl'] ?? data['heroImageUrl'],
      tags: List<String>.from(data['tags'] ?? []),
      payload: data['payload'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'priority': priority.name,
      'state': state.name,
      'vertical': vertical?.name,
      'title': title,
      'summary': summary,
      'body': body,
      'sourceId': sourceId,
      'sourceRole': sourceRole,
      'verified': verified,
      'country': country,
      'region': region,
      'city': city,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'escalatedAt': escalatedAt != null
          ? Timestamp.fromDate(escalatedAt!)
          : null,
      'ctaLabel': ctaLabel,
      'ctaUrl': ctaUrl,
      'eventId': eventId,
      'promotionId': promotionId,
      'fighterId': fighterId,
      'gymId': gymId,
      'imageUrl': imageUrl,
      'tags': tags,
      'payload': payload,
    };
  }

  Signal copyWith({
    String? id,
    SignalType? type,
    SignalPriority? priority,
    SignalState? state,
    CombatVertical? vertical,
    String? title,
    String? summary,
    String? body,
    String? sourceId,
    String? sourceRole,
    bool? verified,
    String? country,
    String? region,
    String? city,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? escalatedAt,
    String? ctaLabel,
    String? ctaUrl,
    String? eventId,
    String? promotionId,
    String? fighterId,
    String? gymId,
    String? imageUrl,
    List<String>? tags,
    Map<String, dynamic>? payload,
  }) {
    return Signal(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      state: state ?? this.state,
      vertical: vertical ?? this.vertical,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      body: body ?? this.body,
      sourceId: sourceId ?? this.sourceId,
      sourceRole: sourceRole ?? this.sourceRole,
      verified: verified ?? this.verified,
      country: country ?? this.country,
      region: region ?? this.region,
      city: city ?? this.city,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      escalatedAt: escalatedAt ?? this.escalatedAt,
      ctaLabel: ctaLabel ?? this.ctaLabel,
      ctaUrl: ctaUrl ?? this.ctaUrl,
      eventId: eventId ?? this.eventId,
      promotionId: promotionId ?? this.promotionId,
      fighterId: fighterId ?? this.fighterId,
      gymId: gymId ?? this.gymId,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      payload: payload ?? this.payload,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    priority,
    state,
    vertical,
    title,
    summary,
    createdAt,
  ];
}
