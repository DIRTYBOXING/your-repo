import 'dart:math';
import 'package:flutter/foundation.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SAMURAI CONTENT TRANSFORMER — AI Content Rewriting + 8-Platform Variants
// ═══════════════════════════════════════════════════════════════════════════════
// Transforms raw content into platform-optimised social variants.
// Queue → Transform → Approve → Publish pipeline.
// ═══════════════════════════════════════════════════════════════════════════════

/// A single piece of transformed content ready for social distribution.
class TransformedContentItem {
  final String id;
  final String title;
  final String body;
  final String transformedHeadline;
  final String transformedBody;
  final String contentStyle;
  final String sourceEngine;
  final double hypeScore;
  final List<String> generatedHashtags;
  final List<String> platforms;
  bool approved;
  bool published;
  final DateTime createdAt;

  TransformedContentItem({
    required this.id,
    required this.title,
    required this.body,
    required this.transformedHeadline,
    required this.transformedBody,
    required this.contentStyle,
    required this.sourceEngine,
    required this.hypeScore,
    required this.generatedHashtags,
    required this.platforms,
    this.approved = false,
    this.published = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class SamuraiContentTransformer {
  static final SamuraiContentTransformer _instance =
      SamuraiContentTransformer._internal();
  factory SamuraiContentTransformer() => _instance;
  SamuraiContentTransformer._internal();

  final Random _rng = Random();

  // ── State ──
  final List<TransformedContentItem> _queue = [];
  bool _isTransforming = false;
  bool _autoMode = false;
  int _totalTransformed = 0;
  int _totalPublished = 0;

  // ── Getters ──
  List<TransformedContentItem> get queue => List.unmodifiable(_queue);
  bool get isTransforming => _isTransforming;
  bool get autoMode => _autoMode;
  int get queueSize => _queue.length;
  int get totalTransformed => _totalTransformed;
  int get totalPublished => _totalPublished;
  List<TransformedContentItem> get approvedQueue =>
      _queue.where((i) => i.approved && !i.published).toList();

  // ── Platform targets ──
  static const allPlatforms = [
    'facebook',
    'instagram',
    'tiktok',
    'x',
    'youtube',
    'linkedin',
    'snapchat',
    'whatsapp',
  ];

  // ── Hashtag pools ──
  static const _hashtagPool = [
    'DFC',
    'DataFightCentral',
    'CombatSports',
    'MMA',
    'Boxing',
    'Kickboxing',
    'MuayThai',
    'BJJ',
    'FightNight',
    'KnockOut',
    'FighterLife',
    'WarriorMindset',
    'ChampionMade',
    'FightWeek',
    'CageSide',
    'RingWalk',
    'FightHype',
    'CombatReady',
    'TrainHardFightEasy',
    'FightFamily',
  ];

  // ── Headline transformers ──
  static const _headlinePrefixes = [
    '🔥 BREAKING:',
    '⚡ JUST IN:',
    '🥊 FIGHT ALERT:',
    '💥 EXPLOSIVE:',
    '🏆 CHAMPION UPDATE:',
    '📢 DFC EXCLUSIVE:',
    '🚨 FIGHT NEWS:',
    '⚔️ COMBAT WIRE:',
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // TRANSFORM — Take raw content and produce a hype-optimised variant
  // ═══════════════════════════════════════════════════════════════════════════

  void transform({
    required String title,
    required String body,
    String contentStyle = 'promo',
    String sourceEngine = 'manual',
  }) {
    _isTransforming = true;

    final prefix = _headlinePrefixes[_rng.nextInt(_headlinePrefixes.length)];
    final headline = title.isNotEmpty
        ? '$prefix $title'
        : '$prefix New DFC Content Drop';
    final hype = 0.5 + _rng.nextDouble() * 0.5; // 50-100% hype

    // Generate 4-8 random hashtags
    final tags = List<String>.from(_hashtagPool)..shuffle(_rng);
    final selectedTags = tags.take(4 + _rng.nextInt(5)).toList();

    final item = TransformedContentItem(
      id: 'tf_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(9999)}',
      title: title,
      body: body,
      transformedHeadline: headline,
      transformedBody: body.isNotEmpty
          ? body
          : 'DataFightCentral delivers another round of combat sports excellence. Stay locked in.',
      contentStyle: contentStyle,
      sourceEngine: sourceEngine,
      hypeScore: hype,
      generatedHashtags: selectedTags,
      platforms: List<String>.from(allPlatforms),
    );

    _queue.insert(0, item);
    _totalTransformed++;
    _isTransforming = false;
    debugPrint(
      'Samurai Transform: queued "$headline" (hype: ${(hype * 100).toInt()}%)',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCAN ALL ENGINES — Generate content from every AI engine at once
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<TransformedContentItem>> transformFromAllEngines() async {
    _isTransforming = true;
    final results = <TransformedContentItem>[];

    final engines = [
      'FightWire',
      'CombatIntel',
      'HealthIntel',
      'SocialEngine',
      'SponsorFeed',
      'ContentRotation',
      'MetaverseAds',
      'Nexus',
    ];

    for (final engine in engines) {
      await Future.delayed(const Duration(milliseconds: 50));
      transform(
        title: '$engine Auto-Scan Content',
        body:
            'AI-generated content from the $engine engine. Combat sports intelligence, delivered by DataFightCentral.',
        contentStyle: 'auto',
        sourceEngine: engine.toLowerCase(),
      );
      if (_queue.isNotEmpty) results.add(_queue.first);
    }

    _isTransforming = false;
    debugPrint(
      'Samurai: Scanned ${results.length} engines, ${_queue.length} items in queue',
    );
    return results;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GENERATE PLATFORM PROMO CAMPAIGN
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<TransformedContentItem>> generatePlatformPromoCampaign() async {
    _isTransforming = true;
    final results = <TransformedContentItem>[];

    final promos = [
      'DFC Launch: The future of combat sports is HERE',
      'Fighter Registration OPEN — claim your profile now',
      'AI-powered fight analytics — only on DFC',
      'Promoters: list your events FREE on DataFightCentral',
      'Join the global combat sports community',
      'DFC: Where fighters, coaches, and fans unite',
    ];

    for (final promo in promos) {
      await Future.delayed(const Duration(milliseconds: 30));
      transform(
        title: promo,
        body:
            '$promo. DataFightCentral — The Promotional Engine for Combat Sports. Join the revolution.',
        contentStyle: 'campaign',
        sourceEngine: 'promo-generator',
      );
      if (_queue.isNotEmpty) results.add(_queue.first);
    }

    _isTransforming = false;
    debugPrint('Samurai: Generated ${results.length} campaign posts');
    return results;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APPROVE / PUBLISH / FIRE ALL
  // ═══════════════════════════════════════════════════════════════════════════

  void approve(String id) {
    final idx = _queue.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _queue[idx].approved = true;
      debugPrint('Samurai: Approved "${_queue[idx].transformedHeadline}"');
    }
  }

  Future<void> publishToSocial(String id) async {
    final idx = _queue.indexWhere((i) => i.id == id);
    if (idx != -1) {
      // Simulate API publish delay
      await Future.delayed(const Duration(milliseconds: 200));
      _queue[idx].published = true;
      _queue[idx].approved = true;
      _totalPublished++;
      debugPrint(
        'Samurai: Published "${_queue[idx].transformedHeadline}" to ${_queue[idx].platforms.length} platforms',
      );
    }
  }

  Future<int> fireAll() async {
    final toFire = approvedQueue;
    int count = 0;
    for (final item in toFire) {
      await Future.delayed(const Duration(milliseconds: 100));
      item.published = true;
      _totalPublished++;
      count++;
    }
    debugPrint('Samurai: FIRE ALL — $count posts blasted across all platforms');
    return count;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTO MODE
  // ═══════════════════════════════════════════════════════════════════════════

  void startAutoMode() {
    _autoMode = true;
    debugPrint('Samurai: AUTO MODE ENGAGED — content machine running');
  }

  void stopAutoMode() {
    _autoMode = false;
    debugPrint('Samurai: AUTO MODE DISENGAGED');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEAR / RESET
  // ═══════════════════════════════════════════════════════════════════════════

  void clearQueue() {
    _queue.clear();
    debugPrint('Samurai: Queue cleared');
  }

  void reset() {
    _queue.clear();
    _totalTransformed = 0;
    _totalPublished = 0;
    _autoMode = false;
    _isTransforming = false;
    debugPrint('Samurai: Full reset');
  }
}
