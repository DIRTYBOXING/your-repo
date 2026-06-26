import '../models/media_library_item.dart';

/// AutoTaggingService — keyword & metadata-based tagging for fighters, gyms,
/// events, locations, and combat styles.
class AutoTaggingService {
  static final AutoTaggingService _instance = AutoTaggingService._internal();
  factory AutoTaggingService() => _instance;
  AutoTaggingService._internal();

  // ── Combat-sport keyword dictionaries ──────────────────────────────────────

  static const _combatStyles = <String, String>{
    'muay thai': 'style:Muay Thai',
    'boxing': 'style:Boxing',
    'mma': 'style:MMA',
    'bjj': 'style:BJJ',
    'jiu jitsu': 'style:BJJ',
    'jiu-jitsu': 'style:BJJ',
    'wrestling': 'style:Wrestling',
    'kickboxing': 'style:Kickboxing',
    'karate': 'style:Karate',
    'judo': 'style:Judo',
    'taekwondo': 'style:Taekwondo',
    'bare knuckle': 'style:Bare Knuckle',
    'bkfc': 'style:BKFC',
    'brawling': 'style:Brawling',
    'sanda': 'style:Sanda',
    'sambo': 'style:Sambo',
    'lethwei': 'style:Lethwei',
  };

  static const _eventKeywords = <String, String>{
    'ufc': 'org:UFC',
    'bellator': 'org:Bellator',
    'one championship': 'org:ONE Championship',
    'one fc': 'org:ONE Championship',
    'pfl': 'org:PFL',
    'ibc': 'org:IBC',
    'ultimate legends': 'org:Ultimate Legends',
    'glory': 'org:GLORY',
    'k-1': 'org:K-1',
    'rizin': 'org:Rizin',
    'cage warriors': 'org:Cage Warriors',
  };

  static const _contentTypes = <String, String>{
    'highlight': 'content:Highlight',
    'knockout': 'content:Knockout',
    'ko': 'content:Knockout',
    'tko': 'content:TKO',
    'submission': 'content:Submission',
    'decision': 'content:Decision',
    'training': 'content:Training',
    'sparring': 'content:Sparring',
    'weigh-in': 'content:Weigh-In',
    'weigh in': 'content:Weigh-In',
    'walkout': 'content:Walkout',
    'interview': 'content:Interview',
    'press conference': 'content:Press Conference',
    'promo': 'content:Promo',
  };

  /// Returns a list of tags for a given media item based on caption,
  /// existing tags, type, and platform metadata.
  List<String> autoTag(MediaLibraryItem item) {
    final tags = <String>{};
    final searchText =
        '${item.caption} ${item.tags.join(' ')} ${item.type}'.toLowerCase();

    // Match combat styles
    for (final entry in _combatStyles.entries) {
      if (searchText.contains(entry.key)) {
        tags.add(entry.value);
      }
    }

    // Match organisations / events
    for (final entry in _eventKeywords.entries) {
      if (searchText.contains(entry.key)) {
        tags.add(entry.value);
      }
    }

    // Match content types
    for (final entry in _contentTypes.entries) {
      if (searchText.contains(entry.key)) {
        tags.add(entry.value);
      }
    }

    // Tag by platform source
    if (item.platform.isNotEmpty) {
      tags.add('platform:${item.platform}');
    }

    // Tag by media type
    if (item.type.isNotEmpty) {
      tags.add('type:${item.type}');
    }

    // Carry over any existing manual tags
    for (final t in item.tags) {
      if (t.isNotEmpty) tags.add(t);
    }

    return tags.toList();
  }
}
