import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Fighter response — public content answering fan questions.
/// Subcollection: fighters/{fighterId}/responses/{responseId}
class FighterResponseModel extends Equatable {
  final String id;
  final String questionId;
  final String responseText;
  final String? mediaUrl;
  final DateTime createdAt;
  final bool publishedToFeed;

  const FighterResponseModel({
    required this.id,
    required this.questionId,
    required this.responseText,
    this.mediaUrl,
    required this.createdAt,
    this.publishedToFeed = false,
  });

  factory FighterResponseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FighterResponseModel(
      id: doc.id,
      questionId: data['questionId'] ?? '',
      responseText: data['responseText'] ?? '',
      mediaUrl: data['mediaUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      publishedToFeed: data['publishedToFeed'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'questionId': questionId,
      'responseText': responseText,
      'mediaUrl': mediaUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'publishedToFeed': publishedToFeed,
    };
  }

  FighterResponseModel copyWith({
    String? id,
    String? questionId,
    String? responseText,
    String? mediaUrl,
    DateTime? createdAt,
    bool? publishedToFeed,
  }) {
    return FighterResponseModel(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      responseText: responseText ?? this.responseText,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      createdAt: createdAt ?? this.createdAt,
      publishedToFeed: publishedToFeed ?? this.publishedToFeed,
    );
  }

  @override
  List<Object?> get props => [id, questionId, publishedToFeed];
}
