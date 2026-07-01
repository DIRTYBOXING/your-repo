import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/image_assets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// POSTER TEMPLATE SERVICE — Template Library for Fight Poster Generation
///
/// Manages poster templates: built-in DFC styles + community templates,
/// configurable layouts, sport-specific defaults, and template metadata.
/// Used by PosterGeneratorScreen and poster-worker for consistent output.
/// ═══════════════════════════════════════════════════════════════════════════

final _db = FirebaseFirestore.instance;

enum PosterStyle { gritty, cinematic, clean, neon, vintage, minimal }

enum PosterLayout { portrait, landscape, square, banner, story }

class PosterTemplate {
  final String id;
  final String name;
  final String description;
  final PosterStyle style;
  final PosterLayout layout;
  final String? thumbnailUrl;
  final String? backgroundAsset;
  final String? overlayAsset;
  final Map<String, dynamic> config;
  final bool isBuiltIn;
  final bool isPremium;
  final String? creatorId;
  final String? sportType;
  final int usageCount;
  final DateTime createdAt;

  const PosterTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.style,
    required this.layout,
    this.thumbnailUrl,
    this.backgroundAsset,
    this.overlayAsset,
    this.config = const {},
    this.isBuiltIn = false,
    this.isPremium = false,
    this.creatorId,
    this.sportType,
    this.usageCount = 0,
    required this.createdAt,
  });

  factory PosterTemplate.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PosterTemplate(
      id: doc.id,
      name: d['name'] ?? 'Template',
      description: d['description'] ?? '',
      style: PosterStyle.values.firstWhere(
        (s) => s.name == d['style'],
        orElse: () => PosterStyle.gritty,
      ),
      layout: PosterLayout.values.firstWhere(
        (l) => l.name == d['layout'],
        orElse: () => PosterLayout.portrait,
      ),
      thumbnailUrl: d['thumbnailUrl'],
      backgroundAsset: d['backgroundAsset'],
      overlayAsset: d['overlayAsset'],
      config: Map<String, dynamic>.from(d['config'] ?? {}),
      isBuiltIn: d['isBuiltIn'] ?? false,
      isPremium: d['isPremium'] ?? false,
      creatorId: d['creatorId'],
      sportType: d['sportType'],
      usageCount: d['usageCount'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'description': description,
    'style': style.name,
    'layout': layout.name,
    'thumbnailUrl': thumbnailUrl,
    'backgroundAsset': backgroundAsset,
    'overlayAsset': overlayAsset,
    'config': config,
    'isBuiltIn': isBuiltIn,
    'isPremium': isPremium,
    'creatorId': creatorId,
    'sportType': sportType,
    'usageCount': usageCount,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

class PosterTemplateService with ChangeNotifier {
  static final PosterTemplateService _instance =
      PosterTemplateService._internal();
  factory PosterTemplateService() => _instance;
  PosterTemplateService._internal();

  bool _initialized = false;
  final List<PosterTemplate> _builtInTemplates = [];
  final List<PosterTemplate> _communityTemplates = [];

  bool get initialized => _initialized;
  List<PosterTemplate> get builtInTemplates =>
      List.unmodifiable(_builtInTemplates);
  List<PosterTemplate> get communityTemplates =>
      List.unmodifiable(_communityTemplates);
  List<PosterTemplate> get allTemplates => [
    ..._builtInTemplates,
    ..._communityTemplates,
  ];

  Future<void> initialize() async {
    if (_initialized) return;
    debugPrint('🎨 PosterTemplateService: Initializing...');
    _loadBuiltInTemplates();
    await _loadCommunityTemplates();
    _initialized = true;
    notifyListeners();
  }

  void _loadBuiltInTemplates() {
    _builtInTemplates.clear();
    _builtInTemplates.addAll([
      PosterTemplate(
        id: 'gritty_portrait',
        name: 'Gritty Fight Night',
        description:
            'Dark, textured with distressed typography. Underground fight feel.',
        style: PosterStyle.gritty,
        layout: PosterLayout.portrait,
        backgroundAsset: ImageAssets.bgAction,
        config: {
          'fontFamily': 'BebasNeue',
          'titleSize': 72,
          'subtitleSize': 28,
          'textColor': '#FFFFFF',
          'accentColor': '#FF3366',
          'overlayOpacity': 0.7,
          'grainIntensity': 0.3,
        },
        isBuiltIn: true,
        sportType: 'mma',
        createdAt: DateTime(2026),
      ),
      PosterTemplate(
        id: 'cinematic_portrait',
        name: 'Cinematic Showdown',
        description:
            'Movie-poster style with dramatic lighting and gradient overlays.',
        style: PosterStyle.cinematic,
        layout: PosterLayout.portrait,
        backgroundAsset: ImageAssets.bgHero,
        config: {
          'fontFamily': 'Oswald',
          'titleSize': 64,
          'subtitleSize': 24,
          'textColor': '#FFFFFF',
          'accentColor': '#FFB800',
          'overlayOpacity': 0.5,
          'vignetteIntensity': 0.4,
        },
        isBuiltIn: true,
        sportType: 'boxing',
        createdAt: DateTime(2026),
      ),
      PosterTemplate(
        id: 'clean_portrait',
        name: 'Clean Professional',
        description: 'Minimalist design with clear hierarchy. Promotion-ready.',
        style: PosterStyle.clean,
        layout: PosterLayout.portrait,
        backgroundAsset: ImageAssets.bgEvent,
        config: {
          'fontFamily': 'Montserrat',
          'titleSize': 56,
          'subtitleSize': 20,
          'textColor': '#FFFFFF',
          'accentColor': '#00E5FF',
          'overlayOpacity': 0.3,
        },
        isBuiltIn: true,
        createdAt: DateTime(2026),
      ),
      PosterTemplate(
        id: 'neon_portrait',
        name: 'Neon Arena',
        description:
            'Cyberpunk-inspired with neon outlines and glitch effects.',
        style: PosterStyle.neon,
        layout: PosterLayout.portrait,
        backgroundAsset: ImageAssets.bgPromo,
        config: {
          'fontFamily': 'Rajdhani',
          'titleSize': 68,
          'subtitleSize': 26,
          'textColor': '#00F5FF',
          'accentColor': '#FF00FF',
          'overlayOpacity': 0.6,
          'neonGlow': true,
          'glowRadius': 20,
        },
        isBuiltIn: true,
        createdAt: DateTime(2026),
      ),
      PosterTemplate(
        id: 'vintage_portrait',
        name: 'Vintage Fight Poster',
        description:
            'Retro boxing poster style with aged paper texture and classic fonts.',
        style: PosterStyle.vintage,
        layout: PosterLayout.portrait,
        backgroundAsset: ImageAssets.bgCentral,
        config: {
          'fontFamily': 'PressStart2P',
          'titleSize': 48,
          'subtitleSize': 18,
          'textColor': '#F5E6D3',
          'accentColor': '#C0392B',
          'overlayOpacity': 0.4,
          'sepiaTone': 0.5,
        },
        isBuiltIn: true,
        sportType: 'boxing',
        createdAt: DateTime(2026),
      ),
      PosterTemplate(
        id: 'minimal_landscape',
        name: 'Wide-screen Minimal',
        description:
            'Landscape banner format. Perfect for social media headers.',
        style: PosterStyle.minimal,
        layout: PosterLayout.landscape,
        backgroundAsset: ImageAssets.bgLogoSmall,
        config: {
          'fontFamily': 'Inter',
          'titleSize': 44,
          'subtitleSize': 16,
          'textColor': '#FFFFFF',
          'accentColor': '#00FF88',
        },
        isBuiltIn: true,
        createdAt: DateTime(2026),
      ),
      PosterTemplate(
        id: 'gritty_banner',
        name: 'Fight Banner',
        description: 'Full-width banner for event promotion across platforms.',
        style: PosterStyle.gritty,
        layout: PosterLayout.banner,
        backgroundAsset: ImageAssets.bgAction,
        config: {
          'fontFamily': 'BebasNeue',
          'titleSize': 52,
          'subtitleSize': 20,
          'textColor': '#FFFFFF',
          'accentColor': '#FF3366',
        },
        isBuiltIn: true,
        createdAt: DateTime(2026),
      ),
      PosterTemplate(
        id: 'neon_story',
        name: 'Story Promo',
        description: '9:16 story format with bold neon. IG/TikTok ready.',
        style: PosterStyle.neon,
        layout: PosterLayout.story,
        backgroundAsset: ImageAssets.bgPromo,
        config: {
          'fontFamily': 'Rajdhani',
          'titleSize': 60,
          'subtitleSize': 22,
          'textColor': '#00F5FF',
          'accentColor': '#FF00FF',
          'neonGlow': true,
        },
        isBuiltIn: true,
        createdAt: DateTime(2026),
      ),
    ]);
  }

  Future<void> _loadCommunityTemplates() async {
    try {
      final snap = await _db
          .collection('poster_templates')
          .where('approved', isEqualTo: true)
          .orderBy('usageCount', descending: true)
          .limit(30)
          .get();
      _communityTemplates.clear();
      for (final doc in snap.docs) {
        _communityTemplates.add(PosterTemplate.fromFirestore(doc));
      }
    } catch (e) {
      debugPrint('PosterTemplateService: Load community templates failed: $e');
    }
  }

  /// Get templates by style.
  List<PosterTemplate> getByStyle(PosterStyle style) =>
      allTemplates.where((t) => t.style == style).toList();

  /// Get templates by layout format.
  List<PosterTemplate> getByLayout(PosterLayout layout) =>
      allTemplates.where((t) => t.layout == layout).toList();

  /// Get templates for a specific sport.
  List<PosterTemplate> getForSport(String sport) => allTemplates
      .where((t) => t.sportType == null || t.sportType == sport)
      .toList();

  /// Record a template usage (for ranking).
  Future<void> recordUsage(String templateId) async {
    try {
      await _db.collection('poster_templates').doc(templateId).update({
        'usageCount': FieldValue.increment(1),
      });
    } catch (_) {
      // Built-in templates won't be in Firestore — that's fine
    }
  }

  /// Save a user-created template.
  Future<PosterTemplate?> saveTemplate({
    required String name,
    required String description,
    required PosterStyle style,
    required PosterLayout layout,
    required Map<String, dynamic> config,
    required String creatorId,
    String? sportType,
    String? thumbnailUrl,
    String? backgroundAsset,
  }) async {
    try {
      final ref = _db.collection('poster_templates').doc();
      final template = PosterTemplate(
        id: ref.id,
        name: name,
        description: description,
        style: style,
        layout: layout,
        thumbnailUrl: thumbnailUrl,
        backgroundAsset: backgroundAsset,
        config: config,
        creatorId: creatorId,
        sportType: sportType,
        createdAt: DateTime.now(),
      );
      await ref.set({...template.toFirestore(), 'approved': false});
      _communityTemplates.insert(0, template);
      notifyListeners();
      return template;
    } catch (e) {
      debugPrint('PosterTemplateService: Save template failed: $e');
      return null;
    }
  }

  /// Suggested template based on sport and event type.
  PosterTemplate suggestTemplate({String? sport, PosterLayout? layout}) {
    final pool = allTemplates.where((t) {
      if (sport != null && t.sportType != null && t.sportType != sport) {
        return false;
      }
      if (layout != null && t.layout != layout) return false;
      return true;
    }).toList();

    if (pool.isEmpty) return _builtInTemplates.first;
    pool.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return pool.first;
  }
}
