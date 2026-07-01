import 'package:equatable/equatable.dart';

enum ModerationStatus { pending, approved, rejected, flagged }

enum ModerationType { post, image, event }

class ModerationItem extends Equatable {
  final String id;
  final ModerationType type;
  final String content;
  final ModerationStatus status;
  final String submittedBy;
  final DateTime submittedAt;

  const ModerationItem({
    required this.id,
    required this.type,
    required this.content,
    required this.status,
    required this.submittedBy,
    required this.submittedAt,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    content,
    status,
    submittedBy,
    submittedAt,
  ];
}
