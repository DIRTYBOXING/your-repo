import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/article_service.dart';
import '../../../shared/services/content_pipeline_service.dart';
import '../../../shared/services/promoter_ai_service.dart';
import '../../../shared/models/news_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC NEWSROOM — The Daily Planet of Combat Sports
///
/// • Auto-generated articles from PromoterAI bots
/// • Manual article compose with rich editor
/// • Image upload / URL attach
/// • Live article feed with engagement metrics
/// • One-tap publish to pipeline + feed
/// • Breaking news / featured toggle
/// • Category & sport tagging
/// ═══════════════════════════════════════════════════════════════════════════
class DfcNewsroomScreen extends StatefulWidget {
  const DfcNewsroomScreen({super.key});

  @override
  State<DfcNewsroomScreen> createState() => _DfcNewsroomScreenState();
}

class _DfcNewsroomScreenState extends State<DfcNewsroomScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final ArticleService _articleService = ArticleService();
  final ContentPipelineService _pipeline = ContentPipelineService();
  final PromoterAIService _promoterAI = PromoterAIService();

  // Compose state
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _sourceUrlController = TextEditingController();

  String _selectedCategory = 'Fight News';
  String _selectedSport = 'MMA';
  bool _isFeatured = false;
  bool _isBreaking = false;
  bool _isPublishing = false;
  bool _isAutoGenerating = false;

  // Auto-gen queue
  final List<_AutoArticle> _autoQueue = [];
  Timer? _autoTimer;

  static const List<String> _categories = [
    'Fight News',
    'Event Preview',
    'Post-Fight',
    'Fighter Spotlight',
    'Training',
    'Rankings',
    'Business',
    'Opinion',
    'Breaking',
    'Transfers',
  ];

  static const List<String> _sports = [
    'MMA',
    'Boxing',
    'BKFC',
    'Brawling',
    'Muay Thai',
    'Kickboxing',
    'BJJ',
    'Wrestling',
    'Karate',
    'All Combat',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _promoterAI.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _summaryController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
    _sourceUrlController.dispose();
    _autoTimer?.cancel();
    super.dispose();
  }

  // ── PUBLISH ──────────────────────────────────────────────────────
  Future<void> _publishArticle() async {
    final title = _titleController.text.trim();
    final summary = _summaryController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) return;

    setState(() => _isPublishing = true);
    HapticFeedback.heavyImpact();

    try {
      // 1. Publish to ArticleService (feed_content collection)
      await _articleService.publishArticle(
        title: title,
        summary: summary.isNotEmpty
            ? summary
            : '${body.substring(0, body.length > 120 ? 120 : body.length)}...',
        content: body,
        featuredImageUrl: _imageUrlController.text.trim().isNotEmpty
            ? _imageUrlController.text.trim()
            : null,
        categories: [_selectedCategory],
        tags: [_selectedSport, _selectedCategory],
        isFeatured: _isFeatured,
        isBreaking: _isBreaking,
        sourceUrl: _sourceUrlController.text.trim().isNotEmpty
            ? _sourceUrlController.text.trim()
            : null,
      );

      // 2. Fire into content pipeline
      await _pipeline.intake(
        contentType: 'news',
        title: title,
        body: body,
        imageUrl: _imageUrlController.text.trim().isNotEmpty
            ? _imageUrlController.text.trim()
            : null,
        targetPlatforms: ['dfc_app', 'dfc_web'],
        metadata: {
          'category': _selectedCategory,
          'sport': _selectedSport,
          'isBreaking': _isBreaking,
          'isFeatured': _isFeatured,
        },
      );

      // Clear form
      _titleController.clear();
      _summaryController.clear();
      _bodyController.clear();
      _imageUrlController.clear();
      _sourceUrlController.clear();
      setState(() {
        _isFeatured = false;
        _isBreaking = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title — PUBLISHED & IN PIPELINE'),
            backgroundColor: DesignTokens.neonGreen.withValues(alpha: 0.9),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Publish failed: $e'),
            backgroundColor: DesignTokens.neonRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  // ── AUTO-GENERATE ARTICLES ──────────────────────────────────────
  Future<void> _runAutoGeneration() async {
    setState(() => _isAutoGenerating = true);
    HapticFeedback.mediumImpact();

    try {
      // Generate multiple article types from PromoterAI bots
      final futures = <Future<PromoContent?>>[];

      futures.add(
        _promoterAI.generateHypeViaCF(
          eventName: 'UFC 325',
          mainEvent: 'Santos vs Aliyev',
          date: 'April 2026',
          venue: 'T-Mobile Arena, Las Vegas',
          discipline: 'MMA',
        ),
      );

      futures.add(
        _promoterAI.generateSpotlightViaCF(
          fighterName: 'Zhang Weili',
          record: '25-3-0',
          discipline: 'MMA',
          gym: 'Black Tiger Fight Club',
          achievements: 'UFC Strawweight Champion',
          country: 'China',
        ),
      );

      futures.add(
        _promoterAI.generateMatchupViaCF(
          fighter1: 'Amanda Serrano',
          fighter2: 'Katie Taylor',
          discipline: 'Boxing',
          stakes: 'Undisputed Lightweight Championship',
          event: 'Taylor vs Serrano III — Croke Park',
        ),
      );

      final results = await Future.wait(futures);

      for (final promo in results) {
        if (promo != null) {
          _autoQueue.add(
            _AutoArticle(
              title: promo.headline,
              body: promo.body,
              category: _promoCategoryMap(promo.type),
              sport: promo.sport?.name ?? 'MMA',
              botName: promo.botName,
              hypeScore: promo.hypeScore,
              hashtags: promo.hashtags,
              status: _ArticleStatus.ready,
            ),
          );
        }
      }

      // Also generate local demo articles if CF returns nothing
      if (_autoQueue.isEmpty) {
        _autoQueue.addAll(_generateDemoArticles());
      }

      setState(() {});
    } catch (_) {
      // Fallback to demo articles
      _autoQueue.addAll(_generateDemoArticles());
      setState(() {});
    } finally {
      if (mounted) setState(() => _isAutoGenerating = false);
    }
  }

  String _promoCategoryMap(PromoType type) {
    switch (type) {
      case PromoType.hypePosts:
        return 'Event Preview';
      case PromoType.fighterSpotlight:
        return 'Fighter Spotlight';
      case PromoType.dreamMatchup:
        return 'Fight News';
      case PromoType.eventCountdown:
        return 'Event Preview';
      case PromoType.trendingTopic:
        return 'Rankings';
      default:
        return 'Fight News';
    }
  }

  List<_AutoArticle> _generateDemoArticles() {
    return [
      _AutoArticle(
        title: 'UFC 325: Pereira vs Ankalaev — Full Card Preview & Predictions',
        body:
            'The T-Mobile Arena in Las Vegas prepares for one of the most stacked cards of 2026. '
            'Alex "Poatan" Pereira defends his light heavyweight crown against the dangerous Magomed Ankalaev '
            'in a bout that could define the division for years to come.\n\n'
            'Pereira (12-2) enters on a devastating knockout streak, with five consecutive finishes. His power '
            'has been described as "once in a generation" by commentators. Ankalaev (19-1-1) brings elite wrestling '
            'credentials from Dagestan and has dominated his last six opponents.\n\n'
            'The co-main features Zhang Weili defending her strawweight title against rising contender Tatiana '
            'Suarez in what promises to be a striking vs grappling masterclass.\n\n'
            'Full card breakdown, odds analysis, and DFC prediction model outputs available in the FightWire section.',
        category: 'Event Preview',
        sport: 'MMA',
        botName: 'HypeBot',
        hypeScore: 0.92,
        hashtags: ['#UFC325', '#MMA', '#LasVegas'],
        status: _ArticleStatus.ready,
      ),
      _AutoArticle(
        title:
            'IBC IV Announced: Gold Coast Returns for International Brawling',
        body:
            'International Brawling Championship has officially confirmed IBC IV for July 2026, '
            'returning to the Gold Coast Sports & Leisure Centre after the record-breaking IBC III event.\n\n'
            'IBC III delivered an \$1.2M gate, 8,400 fans, and +340% social engagement growth. '
            'Danny Mac and the IBC team have confirmed a 12-fight card with three title bouts.\n\n'
            'The main event will feature the newly crowned light heavyweight champion Cutler defending '
            'against an international challenger to be announced. DFC amplification lanes are already active '
            'for IBC IV promotional content.\n\n'
            'Ticket pre-sale begins May 1. Streaming confirmed across MainEvent (AU), Sky (NZ), '
            'Prime Video (USA), and Plex worldwide.',
        category: 'Fight News',
        sport: 'Brawling',
        botName: 'EventBot',
        hypeScore: 0.88,
        hashtags: ['#IBC4', '#Brawling', '#GoldCoast'],
        status: _ArticleStatus.ready,
      ),
      _AutoArticle(
        title:
            'Fighter Spotlight: Christine "Misfit" Ferea — Bare Knuckle Queen',
        body:
            'From the streets of Las Vegas to the BKFC world championship, Christine Ferea has '
            'redefined what it means to be a combat sports icon.\n\n'
            'Known as the "Queen of Violence," Ferea holds the BKFC women\'s world title and has '
            'become the face of women\'s bare knuckle fighting globally. Her Misfit Mafia brand has '
            'grown to 27K followers and counting.\n\n'
            'In an exclusive DFC interview, Ferea shared her training regimen, her vision for women '
            'in combat sports, and her plans for 2026 — including potential cross-promotion appearances '
            'and a collaboration with DFC for fighter analytics.\n\n'
            '"Women in combat sports are not a sideshow. We ARE the show," Ferea stated. "BKFC gave '
            'me the stage, but I earned every moment on it with my fists."',
        category: 'Fighter Spotlight',
        sport: 'BKFC',
        botName: 'SpotlightBot',
        hypeScore: 0.85,
        hashtags: ['#BKFC', '#MisfitMafia', '#WomenInCombat'],
        status: _ArticleStatus.ready,
      ),
      _AutoArticle(
        title:
            'Ultimate Legends: WBC Australasian Silver Title on the Line April 24',
        body:
            'Ultimate Legends Promotions — 30+ years of elite combat sports in Melbourne — '
            'brings another stacked card to Racecourse Road, Kensington VIC.\n\n'
            'The headline bout features the WBC Australasian Silver Title in professional '
            'bantamweight boxing: Ramirez vs Costello. Both fighters are undefeated in their '
            'last five bouts and bring contrasting styles that promise fireworks.\n\n'
            'The undercard features K1 kickboxing and Muay Thai bouts showcasing Melbourne\'s '
            'deep talent pool. John Scida and the UL team continue to deliver world-class events '
            'from one of Australia\'s most respected promotion houses.\n\n'
            'DFC powers distribution, social visibility, and pipeline amplification for Ultimate Legends.',
        category: 'Event Preview',
        sport: 'Boxing',
        botName: 'CampaignBot',
        hypeScore: 0.82,
        hashtags: ['#UltimateLegends', '#WBC', '#Melbourne'],
        status: _ArticleStatus.ready,
      ),
      _AutoArticle(
        title:
            'P4P Rankings March 2026: Women Crack the Top 10 for the First Time',
        body:
            'The DFC consensus pound-for-pound rankings for March 2026 mark a historic moment '
            'in combat sports: women fighters have entered the overall top 10 for the first time.\n\n'
            '1. Islam Makhachev (MMA)\n2. Alex Pereira (MMA)\n3. Alexander Volkanovski (MMA)\n'
            '4. Naoya Inoue (Boxing)\n5. Zhang Weili (MMA)\n6. Jai Opetaia (Boxing)\n'
            '7. Ilia Topuria (MMA)\n8. Stamp Fairtex (Muay Thai/MMA)\n'
            '9. Canelo Alvarez (Boxing)\n10. Sean O\'Malley (MMA)\n\n'
            'Zhang Weili at #5 and Stamp Fairtex at #8 represent the highest women\'s rankings '
            'in any major multi-discipline P4P list. The era of separate rankings is ending — '
            'skill is skill, regardless of gender.',
        category: 'Rankings',
        sport: 'All Combat',
        botName: 'AnalyticsBot',
        hypeScore: 0.90,
        hashtags: ['#P4P', '#Rankings', '#WomenInCombat'],
        status: _ArticleStatus.ready,
      ),
    ];
  }

  Future<void> _publishAutoArticle(_AutoArticle article) async {
    setState(() => article.status = _ArticleStatus.publishing);

    try {
      await _articleService.publishArticle(
        title: article.title,
        summary:
            '${article.body.substring(0, article.body.length > 150 ? 150 : article.body.length)}...',
        content: article.body,
        categories: [article.category],
        tags: [article.sport, ...article.hashtags],
        isFeatured: article.hypeScore > 0.85,
        isBreaking: article.hypeScore > 0.90,
      );

      await _pipeline.intake(
        contentType: 'news',
        title: article.title,
        body: article.body,
        targetPlatforms: ['dfc_app', 'dfc_web'],
        metadata: {
          'category': article.category,
          'sport': article.sport,
          'botName': article.botName,
          'hypeScore': article.hypeScore,
        },
      );

      setState(() => article.status = _ArticleStatus.published);
      HapticFeedback.lightImpact();
    } catch (_) {
      setState(() => article.status = _ArticleStatus.failed);
    }
  }

  Future<void> _publishAllAuto() async {
    for (final article in _autoQueue) {
      if (article.status == _ArticleStatus.ready) {
        await _publishAutoArticle(article);
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.newspaper, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DFC NEWSROOM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'THE DAILY PLANET OF COMBAT SPORTS',
                  style: TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: DesignTokens.neonCyan,
          labelColor: DesignTokens.neonCyan,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          tabs: const [
            Tab(text: 'COMPOSE'),
            Tab(text: 'AUTO-GEN'),
            Tab(text: 'PUBLISHED'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildComposeTab(),
          _buildAutoGenTab(),
          _buildPublishedTab(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 1: COMPOSE — Manual article editor
  // ══════════════════════════════════════════════════════════════════
  Widget _buildComposeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DesignTokens.neonCyan.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.edit_note,
                  color: DesignTokens.neonCyan,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Write once → publishes to Feed + Pipeline + All Platforms',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: DesignTokens.neonGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Article Title
          TextField(
            controller: _titleController,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'HEADLINE...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.15),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.06)),

          // Summary
          TextField(
            controller: _summaryController,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Brief summary (auto-generated if left empty)...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.12),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
          const SizedBox(height: 8),

          // Body
          Container(
            constraints: const BoxConstraints(minHeight: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: TextField(
              controller: _bodyController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.6,
              ),
              maxLines: null,
              minLines: 10,
              decoration: InputDecoration(
                hintText:
                    'Write your article...\n\nFull story, fight analysis, event preview, fighter interview — anything worthy of the Daily Planet.',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.1),
                  fontSize: 14,
                  height: 1.6,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Image URL
          TextField(
            controller: _imageUrlController,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Featured image URL (optional)',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.12),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.image,
                color: DesignTokens.neonMagenta,
                size: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: DesignTokens.neonMagenta),
              ),
              filled: true,
              fillColor: DesignTokens.bgCard,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Source URL
          TextField(
            controller: _sourceUrlController,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Source URL (optional)',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.12),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.link,
                color: DesignTokens.neonCyan,
                size: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: DesignTokens.neonCyan),
              ),
              filled: true,
              fillColor: DesignTokens.bgCard,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Category + Sport chips
          const Text(
            'CATEGORY',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _categories.map((cat) {
              final selected = cat == _selectedCategory;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? DesignTokens.neonCyan.withValues(alpha: 0.2)
                        : DesignTokens.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? DesignTokens.neonCyan
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: selected ? DesignTokens.neonCyan : Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          const Text(
            'SPORT',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _sports.map((sport) {
              final selected = sport == _selectedSport;
              return GestureDetector(
                onTap: () => setState(() => _selectedSport = sport),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? DesignTokens.neonMagenta.withValues(alpha: 0.2)
                        : DesignTokens.bgCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? DesignTokens.neonMagenta
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    sport,
                    style: TextStyle(
                      color: selected
                          ? DesignTokens.neonMagenta
                          : Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Toggles
          Row(
            children: [
              _buildToggle('FEATURED', _isFeatured, DesignTokens.neonGold, (v) {
                setState(() => _isFeatured = v);
              }),
              const SizedBox(width: 12),
              _buildToggle('BREAKING', _isBreaking, DesignTokens.neonRed, (v) {
                setState(() => _isBreaking = v);
              }),
            ],
          ),
          const SizedBox(height: 24),

          // PUBLISH BUTTON
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isPublishing ? null : _publishArticle,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.neonCyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isPublishing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.publish, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'PUBLISH TO DFC',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildToggle(
    String label,
    bool value,
    Color color,
    ValueChanged<bool> onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value ? color.withValues(alpha: 0.2) : DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? color : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_circle : Icons.circle_outlined,
              color: value ? color : Colors.white38,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: value ? color : Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 2: AUTO-GEN — AI Bot Generated Articles
  // ══════════════════════════════════════════════════════════════════
  Widget _buildAutoGenTab() {
    return Column(
      children: [
        // Control bar
        Container(
          padding: const EdgeInsets.all(14),
          color: DesignTokens.bgSecondary,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isAutoGenerating ? null : _runAutoGeneration,
                  icon: _isAutoGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(
                    _isAutoGenerating ? 'GENERATING...' : 'GENERATE ARTICLES',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.neonMagenta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              if (_autoQueue
                  .where((a) => a.status == _ArticleStatus.ready)
                  .isNotEmpty) ...[
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _publishAllAuto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.neonGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'PUBLISH ALL',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Bot status bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: DesignTokens.bgCard,
          child: Row(
            children: [
              _botChip('HypeBot', '🔥', DesignTokens.neonRed),
              _botChip('SpotlightBot', '⭐', DesignTokens.neonGold),
              _botChip('EventBot', '⏱️', DesignTokens.neonCyan),
              _botChip('AnalyticsBot', '📊', DesignTokens.neonGreen),
              const Spacer(),
              Text(
                '${_autoQueue.length} articles',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),

        // Article queue
        Expanded(
          child: _autoQueue.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Hit GENERATE to unleash the bots',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'HypeBot • SpotlightBot • EventBot • AnalyticsBot',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.1),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _autoQueue.length,
                  itemBuilder: (_, i) => _buildAutoArticleCard(_autoQueue[i]),
                ),
        ),
      ],
    );
  }

  Widget _botChip(String name, String emoji, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$emoji $name',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAutoArticleCard(_AutoArticle article) {
    final statusColor = switch (article.status) {
      _ArticleStatus.ready => DesignTokens.neonCyan,
      _ArticleStatus.publishing => DesignTokens.neonAmber,
      _ArticleStatus.published => DesignTokens.neonGreen,
      _ArticleStatus.failed => DesignTokens.neonRed,
    };

    final statusLabel = switch (article.status) {
      _ArticleStatus.ready => 'READY',
      _ArticleStatus.publishing => 'FIRING...',
      _ArticleStatus.published => 'PUBLISHED',
      _ArticleStatus.failed => 'FAILED',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: bot + category + status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: DesignTokens.neonMagenta.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  article.botName,
                  style: const TextStyle(
                    color: DesignTokens.neonMagenta,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  article.category,
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  article.sport,
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
              ),
              const Spacer(),
              // Hype score
              Text(
                '${(article.hypeScore * 100).toInt()}%',
                style: TextStyle(
                  color: article.hypeScore > 0.85
                      ? DesignTokens.neonGreen
                      : DesignTokens.neonAmber,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'HYPE',
                style: TextStyle(color: Colors.white24, fontSize: 8),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            article.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),

          // Body preview
          Text(
            article.body.length > 200
                ? '${article.body.substring(0, 200)}...'
                : article.body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),

          // Hashtags
          if (article.hashtags.isNotEmpty)
            Wrap(
              spacing: 4,
              children: article.hashtags
                  .map(
                    (h) => Text(
                      h,
                      style: const TextStyle(
                        color: DesignTokens.neonCyan,
                        fontSize: 10,
                      ),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 10),

          // Action row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              if (article.status == _ArticleStatus.ready)
                GestureDetector(
                  onTap: () => _publishAutoArticle(article),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: DesignTokens.neonGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.publish,
                          color: DesignTokens.neonGreen,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'PUBLISH',
                          style: TextStyle(
                            color: DesignTokens.neonGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (article.status == _ArticleStatus.failed)
                GestureDetector(
                  onTap: () => _publishAutoArticle(article),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'RETRY',
                      style: TextStyle(
                        color: DesignTokens.neonAmber,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 3: PUBLISHED — Live article feed
  // ══════════════════════════════════════════════════════════════════
  Widget _buildPublishedTab() {
    return StreamBuilder<List<NewsModel>>(
      stream: _articleService.articlesStream(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: DesignTokens.neonCyan),
          );
        }

        final articles = snapshot.data ?? [];

        if (articles.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                const SizedBox(height: 12),
                Text(
                  'No articles published yet',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Compose or auto-generate to start',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.1),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: articles.length,
          itemBuilder: (_, i) => _buildPublishedArticleCard(articles[i]),
        );
      },
    );
  }

  Widget _buildPublishedArticleCard(NewsModel article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: article.isBreakingNews
              ? DesignTokens.neonRed.withValues(alpha: 0.3)
              : article.isFeatured
              ? DesignTokens.neonGold.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges
          Row(
            children: [
              if (article.isBreakingNews)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '🔴 BREAKING',
                    style: TextStyle(
                      color: DesignTokens.neonRed,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              if (article.isFeatured)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '⭐ FEATURED',
                    style: TextStyle(
                      color: DesignTokens.neonGold,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              if (article.categories.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    article.categories.first,
                    style: const TextStyle(color: Colors.white38, fontSize: 9),
                  ),
                ),
              const Spacer(),
              if (article.readTime != null)
                Text(
                  article.readTime!,
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            article.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),

          // Summary
          Text(
            article.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),

          // Engagement metrics
          Row(
            children: [
              _metricBadge(
                Icons.visibility,
                article.viewsCount,
                DesignTokens.neonCyan,
              ),
              const SizedBox(width: 12),
              _metricBadge(
                Icons.favorite,
                article.likesCount,
                DesignTokens.neonRed,
              ),
              const SizedBox(width: 12),
              _metricBadge(
                Icons.comment,
                article.commentsCount,
                DesignTokens.neonMagenta,
              ),
              const SizedBox(width: 12),
              _metricBadge(
                Icons.share,
                article.sharesCount,
                DesignTokens.neonGreen,
              ),
              const Spacer(),
              if (article.publishedAt != null)
                Text(
                  _timeAgo(article.publishedAt!),
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricBadge(IconData icon, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color.withValues(alpha: 0.6), size: 14),
        const SizedBox(width: 3),
        Text(
          _formatCount(count),
          style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 11),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════
enum _ArticleStatus { ready, publishing, published, failed }

class _AutoArticle {
  final String title;
  final String body;
  final String category;
  final String sport;
  final String botName;
  final double hypeScore;
  final List<String> hashtags;
  _ArticleStatus status;

  _AutoArticle({
    required this.title,
    required this.body,
    required this.category,
    required this.sport,
    required this.botName,
    required this.hypeScore,
    required this.hashtags,
    required this.status,
  });
}
