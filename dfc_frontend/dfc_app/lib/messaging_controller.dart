import 'package:flutter/foundation.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/messaging_service.dart';

class MessagingController extends ChangeNotifier {
  final _service = MessagingService();

  bool isLoadingConversations = true;
  bool isLoadingMessages = true;

  List<ConversationModel> conversations = [];
  List<MessageModel> activeMessages = [];

  Future<void> loadConversations() async {
    isLoadingConversations = true;
    notifyListeners();
    conversations = await _service.fetchConversations();
    isLoadingConversations = false;
    notifyListeners();
  }

  Future<void> loadMessages(String conversationId) async {
    isLoadingMessages = true;
    notifyListeners();
    activeMessages = await _service.fetchMessages(conversationId);
    isLoadingMessages = false;
    notifyListeners();
  }

  Future<void> sendMessage(String conversationId, String text) async {
    if (text.trim().isEmpty) return;
    // Optimistic UI insert
    final msg = await _service.sendMessage(conversationId, text);
    activeMessages.add(msg);
    notifyListeners();
  }
}
