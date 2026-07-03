import '../../../dfc_theme.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class MessagingService {
  Future<List<ConversationModel>> fetchConversations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      ConversationModel(
        id: 'c1',
        name: 'Coach Marcus',
        role: 'HEAD COACH',
        lastMessage:
            "Make sure you hit the target weight by Friday. Don't slack on the water loading.",
        timeAgo: '10:42 AM',
        unreadCount: 2,
        color: AppColors.accentCyan,
        avatarUrl:
            'https://ui-avatars.com/api/?name=Marcus&background=0A0E17&color=00E5FF',
      ),
      ConversationModel(
        id: 'c2',
        name: 'Matchmaker Davis',
        role: 'PROMOTION',
        lastMessage:
            "Contract for the UFC 300 fight is ready to be signed. Check your email.",
        timeAgo: 'Yesterday',
        unreadCount: 0,
        color: AppColors.championGold,
        avatarUrl:
            'https://ui-avatars.com/api/?name=Davis&background=0A0E17&color=FFD600',
      ),
      ConversationModel(
        id: 'c3',
        name: 'Dr. Stevens',
        role: 'MEDICAL',
        lastMessage:
            "Your recent bloodwork looks good. Sodium levels are optimal.",
        timeAgo: 'Monday',
        unreadCount: 0,
        color: AppColors.accentRed,
        avatarUrl:
            'https://ui-avatars.com/api/?name=Dr+Stevens&background=0A0E17&color=FF3B30',
      ),
    ];
  }

  Future<List<MessageModel>> fetchMessages(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      MessageModel(
        id: 'm1',
        text: 'Hey, checking in on your weight cut.',
        isMe: false,
        timestamp: '10:30 AM',
      ),
      MessageModel(
        id: 'm2',
        text: 'All good coach, dropping the water now.',
        isMe: true,
        timestamp: '10:35 AM',
      ),
      MessageModel(
        id: 'm3',
        text:
            'Make sure you hit the target weight by Friday. Don\'t slack on the water loading.',
        isMe: false,
        timestamp: '10:42 AM',
      ),
    ];
  }

  Future<MessageModel> sendMessage(String conversationId, String text) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    return MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isMe: true,
      timestamp: 'Just now',
    );
  }
}
