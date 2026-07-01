import '../models/moderation_item.dart';

class AIModerationService {
  // Example keyword list for risky content
  static const List<String> riskyKeywords = [
    'violence',
    'hate',
    'nudity',
    'drugs',
    'gambling',
    'abuse',
    'illegal',
  ];

  // Simulated AI text moderation
  ModerationStatus moderateText(String text) {
    for (final keyword in riskyKeywords) {
      if (text.toLowerCase().contains(keyword)) {
        return ModerationStatus.flagged;
      }
    }
    return ModerationStatus.approved;
  }

  // Simulated AI image moderation (stub)
  ModerationStatus moderateImage(String imageUrl) {
    // Image analysis API integration pending (e.g. Google Vision)
    // Returns approved for demo mode
    return ModerationStatus.approved;
  }
}
