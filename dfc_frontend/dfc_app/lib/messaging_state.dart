import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// V12 STATE MACHINE: CONVERSATIONS
sealed class ConversationState {}

class ConversationInitial extends ConversationState {}

class ConversationLoading extends ConversationState {}

class ConversationLoaded extends ConversationState {
  final List<ConversationModel> conversations;
  ConversationLoaded(this.conversations);
}

class ConversationError extends ConversationState {
  final String message;
  ConversationError(this.message);
}

/// V12 STATE MACHINE: MESSAGES
sealed class MessageState {}

class MessageInitial extends MessageState {}

class MessageLoading extends MessageState {}

class MessageLoaded extends MessageState {
  final List<MessageModel> messages;
  MessageLoaded(this.messages);
}

class MessageError extends MessageState {
  final String message;
  MessageError(this.message);
}
