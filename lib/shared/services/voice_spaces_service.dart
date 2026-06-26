// ═══════════════════════════════════════════════════════════════════════════
// VOICE SPACES SERVICE — Live Audio Rooms & Social Audio
// ═══════════════════════════════════════════════════════════════════════════
//
// Twitter Spaces-style live audio rooms for combat sports:
//  • Room creation — scheduled or instant audio spaces
//  • Speaker management — host, co-host, speaker, listener roles
//  • Hand-raise queue — listeners request to speak
//  • Room moderation — mute, remove, ban participants
//  • Room discovery — trending, scheduled, following-based
//  • Recording — optional room recording for replay
//
// Complements existing LiveChatService with audio-first experience
// ═══════════════════════════════════════════════════════════════════════════

// ─── Enums ──────────────────────────────────────────────────────────────

enum SpaceRole {
  host('Host', '🎙️', true, true),
  coHost('Co-Host', '🎤', true, true),
  speaker('Speaker', '🗣️', true, false),
  listener('Listener', '👂', false, false);

  final String label;
  final String icon;
  final bool canSpeak;
  final bool canModerate;
  const SpaceRole(this.label, this.icon, this.canSpeak, this.canModerate);
}

enum SpaceStatus {
  scheduled('Scheduled', 'Upcoming space'),
  live('Live', 'Currently broadcasting'),
  ended('Ended', 'Space has concluded'),
  cancelled('Cancelled', 'Space was cancelled');

  final String label;
  final String description;
  const SpaceStatus(this.label, this.description);
}

enum SpaceCategory {
  fightPreview('Fight Preview', '🥊'),
  postFightBreakdown('Post-Fight Breakdown', '📊'),
  trainingTalk('Training Talk', '💪'),
  fanDebate('Fan Debate', '🔥'),
  ama('AMA / Q&A', '❓'),
  newsDiscussion('News Discussion', '📰'),
  coachSession('Coach Session', '🎯'),
  openMic('Open Mic', '🎤');

  final String label;
  final String emoji;
  const SpaceCategory(this.label, this.emoji);
}

// ─── Models ─────────────────────────────────────────────────────────────

class SpaceParticipant {
  final String userId;
  final String displayName;
  final SpaceRole role;
  final bool isMuted;
  final DateTime joinedAt;
  final bool isVerified;

  const SpaceParticipant({
    required this.userId,
    required this.displayName,
    required this.role,
    this.isMuted = false,
    required this.joinedAt,
    this.isVerified = false,
  });

  SpaceParticipant copyWith({SpaceRole? role, bool? isMuted}) =>
      SpaceParticipant(
        userId: userId,
        displayName: displayName,
        role: role ?? this.role,
        isMuted: isMuted ?? this.isMuted,
        joinedAt: joinedAt,
        isVerified: isVerified,
      );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'displayName': displayName,
    'role': role.name,
    'isMuted': isMuted,
    'isVerified': isVerified,
  };
}

class HandRaiseRequest {
  final String userId;
  final String displayName;
  final DateTime requestedAt;

  const HandRaiseRequest({
    required this.userId,
    required this.displayName,
    required this.requestedAt,
  });
}

class VoiceSpace {
  final String spaceId;
  final String title;
  final String? description;
  final SpaceCategory category;
  final SpaceStatus status;
  final String hostId;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final List<SpaceParticipant> participants;
  final List<HandRaiseRequest> handRaiseQueue;
  final int maxSpeakers;
  final bool isRecording;
  final int listenerCount;
  final List<String> tags;

  const VoiceSpace({
    required this.spaceId,
    required this.title,
    this.description,
    required this.category,
    required this.status,
    required this.hostId,
    required this.createdAt,
    this.scheduledFor,
    this.startedAt,
    this.endedAt,
    this.participants = const [],
    this.handRaiseQueue = const [],
    this.maxSpeakers = 10,
    this.isRecording = false,
    this.listenerCount = 0,
    this.tags = const [],
  });

  int get speakerCount => participants.where((p) => p.role.canSpeak).length;

  int get totalParticipants => participants.length;

  Duration? get duration {
    if (startedAt == null) return null;
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt!);
  }

  Map<String, dynamic> toMap() => {
    'spaceId': spaceId,
    'title': title,
    'category': category.name,
    'status': status.name,
    'hostId': hostId,
    'speakerCount': speakerCount,
    'listenerCount': listenerCount,
    'totalParticipants': totalParticipants,
    'isRecording': isRecording,
    'tags': tags,
    'durationMinutes': duration?.inMinutes,
  };
}

class SpaceDiscoveryResult {
  final List<VoiceSpace> liveSpaces;
  final List<VoiceSpace> scheduledSpaces;
  final List<VoiceSpace> recommended;
  final int totalLive;

  const SpaceDiscoveryResult({
    required this.liveSpaces,
    required this.scheduledSpaces,
    this.recommended = const [],
    this.totalLive = 0,
  });
}

// ─── Service ────────────────────────────────────────────────────────────

class VoiceSpacesService {
  VoiceSpacesService._();
  static final VoiceSpacesService instance = VoiceSpacesService._();

  static const int _maxSpeakersDefault = 10;
  static const int _maxListeners = 1000;

  final _spaces = <String, VoiceSpace>{};

  /// Create a new voice space (instant or scheduled).
  VoiceSpace createSpace({
    required String hostId,
    required String hostName,
    required String title,
    String? description,
    required SpaceCategory category,
    DateTime? scheduledFor,
    int maxSpeakers = _maxSpeakersDefault,
    bool isRecording = false,
    List<String> tags = const [],
  }) {
    final now = DateTime.now();
    final isScheduled = scheduledFor != null && scheduledFor.isAfter(now);

    final space = VoiceSpace(
      spaceId: 'space_${now.millisecondsSinceEpoch}',
      title: title,
      description: description,
      category: category,
      status: isScheduled ? SpaceStatus.scheduled : SpaceStatus.live,
      hostId: hostId,
      createdAt: now,
      scheduledFor: scheduledFor,
      startedAt: isScheduled ? null : now,
      maxSpeakers: maxSpeakers,
      isRecording: isRecording,
      tags: tags,
      participants: [
        SpaceParticipant(
          userId: hostId,
          displayName: hostName,
          role: SpaceRole.host,
          joinedAt: now,
        ),
      ],
    );

    _spaces[space.spaceId] = space;
    return space;
  }

  /// Join a voice space as a listener.
  VoiceSpace? joinSpace({
    required String spaceId,
    required String userId,
    required String displayName,
    bool isVerified = false,
  }) {
    final space = _spaces[spaceId];
    if (space == null || space.status != SpaceStatus.live) return null;
    if (space.totalParticipants >= _maxListeners) return null;
    if (space.participants.any((p) => p.userId == userId)) return space;

    final updated = VoiceSpace(
      spaceId: space.spaceId,
      title: space.title,
      description: space.description,
      category: space.category,
      status: space.status,
      hostId: space.hostId,
      createdAt: space.createdAt,
      scheduledFor: space.scheduledFor,
      startedAt: space.startedAt,
      maxSpeakers: space.maxSpeakers,
      isRecording: space.isRecording,
      tags: space.tags,
      listenerCount: space.listenerCount + 1,
      handRaiseQueue: space.handRaiseQueue,
      participants: [
        ...space.participants,
        SpaceParticipant(
          userId: userId,
          displayName: displayName,
          role: SpaceRole.listener,
          joinedAt: DateTime.now(),
          isVerified: isVerified,
        ),
      ],
    );
    _spaces[spaceId] = updated;
    return updated;
  }

  /// Raise hand to request speaker role.
  bool raiseHand({
    required String spaceId,
    required String userId,
    required String displayName,
  }) {
    final space = _spaces[spaceId];
    if (space == null || space.status != SpaceStatus.live) return false;

    // Already a speaker
    final participant = space.participants
        .where((p) => p.userId == userId)
        .firstOrNull;
    if (participant != null && participant.role.canSpeak) return false;

    // Already in queue
    if (space.handRaiseQueue.any((r) => r.userId == userId)) return false;

    final updatedQueue = [
      ...space.handRaiseQueue,
      HandRaiseRequest(
        userId: userId,
        displayName: displayName,
        requestedAt: DateTime.now(),
      ),
    ];

    _spaces[spaceId] = VoiceSpace(
      spaceId: space.spaceId,
      title: space.title,
      description: space.description,
      category: space.category,
      status: space.status,
      hostId: space.hostId,
      createdAt: space.createdAt,
      scheduledFor: space.scheduledFor,
      startedAt: space.startedAt,
      maxSpeakers: space.maxSpeakers,
      isRecording: space.isRecording,
      tags: space.tags,
      listenerCount: space.listenerCount,
      participants: space.participants,
      handRaiseQueue: updatedQueue,
    );
    return true;
  }

  /// Promote a listener to speaker (host/co-host action).
  VoiceSpace? promoteSpeaker({
    required String spaceId,
    required String userId,
    required String promotedBy,
  }) {
    final space = _spaces[spaceId];
    if (space == null) return null;

    // Check promoter has moderation rights
    final promoter = space.participants
        .where((p) => p.userId == promotedBy)
        .firstOrNull;
    if (promoter == null || !promoter.role.canModerate) return null;

    // Check speaker limit
    if (space.speakerCount >= space.maxSpeakers) return null;

    final updatedParticipants = space.participants.map((p) {
      if (p.userId == userId && p.role == SpaceRole.listener) {
        return p.copyWith(role: SpaceRole.speaker);
      }
      return p;
    }).toList();

    // Remove from hand raise queue
    final updatedQueue = space.handRaiseQueue
        .where((r) => r.userId != userId)
        .toList();

    final updated = VoiceSpace(
      spaceId: space.spaceId,
      title: space.title,
      description: space.description,
      category: space.category,
      status: space.status,
      hostId: space.hostId,
      createdAt: space.createdAt,
      scheduledFor: space.scheduledFor,
      startedAt: space.startedAt,
      maxSpeakers: space.maxSpeakers,
      isRecording: space.isRecording,
      tags: space.tags,
      listenerCount: space.listenerCount,
      participants: updatedParticipants,
      handRaiseQueue: updatedQueue,
    );
    _spaces[spaceId] = updated;
    return updated;
  }

  /// End a voice space.
  VoiceSpace? endSpace({required String spaceId, required String endedBy}) {
    final space = _spaces[spaceId];
    if (space == null) return null;
    if (space.hostId != endedBy) return null;

    final updated = VoiceSpace(
      spaceId: space.spaceId,
      title: space.title,
      description: space.description,
      category: space.category,
      status: SpaceStatus.ended,
      hostId: space.hostId,
      createdAt: space.createdAt,
      scheduledFor: space.scheduledFor,
      startedAt: space.startedAt,
      endedAt: DateTime.now(),
      maxSpeakers: space.maxSpeakers,
      isRecording: space.isRecording,
      tags: space.tags,
      listenerCount: space.listenerCount,
      participants: space.participants,
    );
    _spaces[spaceId] = updated;
    return updated;
  }

  /// Get a space by ID.
  VoiceSpace? getSpace(String spaceId) => _spaces[spaceId];

  /// Discover live and upcoming spaces.
  SpaceDiscoveryResult discover({
    Set<String> followingIds = const {},
    SpaceCategory? category,
  }) {
    final now = DateTime.now();

    var live = _spaces.values
        .where((s) => s.status == SpaceStatus.live)
        .toList();

    var scheduled = _spaces.values
        .where(
          (s) =>
              s.status == SpaceStatus.scheduled &&
              s.scheduledFor != null &&
              s.scheduledFor!.isAfter(now),
        )
        .toList();

    if (category != null) {
      live = live.where((s) => s.category == category).toList();
      scheduled = scheduled.where((s) => s.category == category).toList();
    }

    // Sort live by participant count (most popular first)
    live.sort((a, b) => b.totalParticipants.compareTo(a.totalParticipants));

    // Sort scheduled by time (soonest first)
    scheduled.sort((a, b) => a.scheduledFor!.compareTo(b.scheduledFor!));

    // Recommended: spaces from followed users
    final recommended = live
        .where((s) => followingIds.contains(s.hostId))
        .toList();

    return SpaceDiscoveryResult(
      liveSpaces: live,
      scheduledSpaces: scheduled,
      recommended: recommended,
      totalLive: live.length,
    );
  }

  /// Get stats summary.
  Map<String, dynamic> get stats => {
    'totalSpaces': _spaces.length,
    'liveSpaces': _spaces.values
        .where((s) => s.status == SpaceStatus.live)
        .length,
    'scheduledSpaces': _spaces.values
        .where((s) => s.status == SpaceStatus.scheduled)
        .length,
    'totalParticipants': _spaces.values
        .where((s) => s.status == SpaceStatus.live)
        .fold<int>(0, (sum, s) => sum + s.totalParticipants),
  };
}
