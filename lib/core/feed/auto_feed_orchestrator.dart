import 'package:equatable/equatable.dart';

class FeedItem extends Equatable {
  final String id;
  final String type; // e.g. "news", "clip", "poster", "journal_prompt"
  final int basePriority;

  const FeedItem({
    required this.id,
    required this.type,
    required this.basePriority,
  });

  FeedItem copyWith({
    String? id,
    String? type,
    int? basePriority,
  }) {
    return FeedItem(
      id: id ?? this.id,
      type: type ?? this.type,
      basePriority: basePriority ?? this.basePriority,
    );
  }

  @override
  List<Object?> get props => [id, type, basePriority];
}

/// Bends the content gravity around the user's emotional state.
class AutoFeedOrchestrator {
  
  /// Re-ranks feed items based on AstroHealth/Shakura stress and mood telemetry.
  List<FeedItem> rank({
    required List<FeedItem> items,
    required int stressScore,
    required int moodScore,
  }) {
    return items.map((item) {
      int p = item.basePriority;

      // High stress: push soft/wellness content up, push aggressive news down
      if (stressScore >= 8) {
        if (item.type == "journal_prompt") p += 20;
        if (item.type == "news") p -= 10;
      }

      // High mood: let hype/adrenalin content rise
      if (moodScore >= 8) {
        if (item.type == "clip") p += 10;
      }

      return item.copyWith(basePriority: p);
    }).toList()
      ..sort((a, b) => b.basePriority.compareTo(a.basePriority)); // Descending sort
  }
}
