import '../../api_service.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class MessagingRepository {
  final ApiService api;
  MessagingRepository({required this.api});

  Future<List<ConversationModel>> getConversations() async {
    final data = await api.callFunction("getConversations");
    final list = data["conversations"] as List<dynamic>? ?? [];
    return list.map((e) => ConversationModel.fromJson(e)).toList();
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    final data = await api.callFunction("getMessages", {"conversationId": conversationId});
    final list = data["messages"] as List<dynamic>? ?? [];
    return list.map((e) => MessageModel.fromJson(e)).toList();
  }

  Future<void> sendMessage(String conversationId, String text) async {
    await api.callFunction("sendMessage", {
      "conversationId": conversationId,
      "text": text,
    });
  }

  Future<String> createConversation(String otherId) async {
    final data = await api.callFunction("createConversation", {"otherId": otherId});
    return data["id"];
  }
}