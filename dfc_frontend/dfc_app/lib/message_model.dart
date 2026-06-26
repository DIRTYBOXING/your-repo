class MessageModel {
  final String id;
  final String text;
  final bool isMe;
  final String timestamp;

  MessageModel({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}
