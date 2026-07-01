import '../models/moderation_item.dart';
import 'ai_moderation_service.dart';

class ModerationService {
  // Integrate AI moderation for posts/images
  final _aiService = AIModerationService();

  // Process new moderation item (text or image)
  Future<ModerationStatus> processModerationItem(ModerationItem item) async {
    if (item.type == ModerationType.post || item.type == ModerationType.event) {
      return _aiService.moderateText(item.content);
    } else if (item.type == ModerationType.image) {
      return _aiService.moderateImage(item.content);
    }
    return ModerationStatus.approved;
  }

  // Only flagged items go to manual review
  Future<List<ModerationItem>> fetchModerationQueue(
    List<ModerationItem> allItems,
  ) async {
    return allItems
        .where((item) => item.status == ModerationStatus.flagged)
        .toList();
  }

  // Approve item
  Future<void> approveItem(String id) async {
    // Update status in backend when service is wired
  }

  // Reject item
  Future<void> rejectItem(String id) async {
    // Update status in backend when service is wired
  }

  // Flag item
  Future<void> flagItem(String id) async {
    // Update status in backend when service is wired
  }
}
