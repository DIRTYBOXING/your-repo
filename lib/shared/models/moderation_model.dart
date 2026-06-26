import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Moderation item type
enum ModerationType { post, comment, question }

/// Moderation status
enum ModerationStatus { pending, approved, rejected }

/// Moderation queue item — everything unsafe goes here before approval.
/// Collection: moderation/{itemId}
class ModerationModel extends Equatable {
  final String id;
  final ModerationType type;
  final String content;
  final String userId;
  final String? targetId; // fighterId or postId
  final DateTime createdAt;
  final ModerationStatus status;
  final String? moderatedBy;
  final DateTime? moderatedAt;

  const ModerationModel({
    required this.id,
    required this.type,
    required this.content,
    required this.userId,
    this.targetId,
    required this.createdAt,
    this.status = ModerationStatus.pending,
    this.moderatedBy,
    this.moderatedAt,
  });

  factory ModerationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ModerationModel(
      id: doc.id,
      type: ModerationType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => ModerationType.post,
      ),
      content: data['content'] ?? '',
      userId: data['userId'] ?? '',
      targetId: data['targetId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ModerationStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ModerationStatus.pending,
      ),
      moderatedBy: data['moderatedBy'],
      moderatedAt: (data['moderatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'content': content,
      'userId': userId,
      'targetId': targetId,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
      'moderatedBy': moderatedBy,
      'moderatedAt': moderatedAt != null
          ? Timestamp.fromDate(moderatedAt!)
          : null,
    };
  }

  ModerationModel copyWith({
    String? id,
    ModerationType? type,
    String? content,
    String? userId,
    String? targetId,
    DateTime? createdAt,
    ModerationStatus? status,
    String? moderatedBy,
    DateTime? moderatedAt,
  }) {
    return ModerationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      targetId: targetId ?? this.targetId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      moderatedBy: moderatedBy ?? this.moderatedBy,
      moderatedAt: moderatedAt ?? this.moderatedAt,
    );
  }

  @override
  List<Object?> get props => [id, type, userId, status];
}
