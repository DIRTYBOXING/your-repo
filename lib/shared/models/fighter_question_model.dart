import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Question moderation status
enum QuestionStatus { pending, approved, rejected }

/// Fan → Fighter question — moderated before reaching the fighter.
/// Subcollection: fighters/{fighterId}/questions/{questionId}
class FighterQuestionModel extends Equatable {
  final String id;
  final String userId;
  final String questionText;
  final QuestionStatus status;
  final DateTime createdAt;
  final DateTime? moderatedAt;
  final String? moderatedBy;

  const FighterQuestionModel({
    required this.id,
    required this.userId,
    required this.questionText,
    this.status = QuestionStatus.pending,
    required this.createdAt,
    this.moderatedAt,
    this.moderatedBy,
  });

  factory FighterQuestionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FighterQuestionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      questionText: data['questionText'] ?? '',
      status: QuestionStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => QuestionStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      moderatedAt: (data['moderatedAt'] as Timestamp?)?.toDate(),
      moderatedBy: data['moderatedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'questionText': questionText,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'moderatedAt': moderatedAt != null
          ? Timestamp.fromDate(moderatedAt!)
          : null,
      'moderatedBy': moderatedBy,
    };
  }

  FighterQuestionModel copyWith({
    String? id,
    String? userId,
    String? questionText,
    QuestionStatus? status,
    DateTime? createdAt,
    DateTime? moderatedAt,
    String? moderatedBy,
  }) {
    return FighterQuestionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questionText: questionText ?? this.questionText,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      moderatedAt: moderatedAt ?? this.moderatedAt,
      moderatedBy: moderatedBy ?? this.moderatedBy,
    );
  }

  @override
  List<Object?> get props => [id, userId, status];
}
