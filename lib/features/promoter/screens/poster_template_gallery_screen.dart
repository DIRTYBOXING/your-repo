import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/image_assets.dart';
import '../../../shared/services/poster_template_service.dart';
import '../../../core/config/router_config.dart' as app_router;

/// ═══════════════════════════════════════════════════════════════════════════
/// POSTER TEMPLATE GALLERY — Browse, select & use poster templates
///
/// Filterable grid of built-in + community poster templates.
/// Tap to preview, then launch PosterGeneratorScreen with template config.
/// ═══════════════════════════════════════════════════════════════════════════

class PosterTemplateGalleryScreen extends StatefulWidget {
  const PosterTemplateGalleryScreen({super.key});

  @override
  State<PosterTemplateGalleryScreen> createState() =>
      _PosterTemplateGalleryScreenState();
}

class _PosterTemplateGalleryScreenState
    extends State<PosterTemplateGalleryScreen> {
  final _service = PosterTemplateService();
  PosterStyle? _filterStyle;
  PosterLayout? _filterLayout;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _service.initialize();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'Poster Templates',
          style: TextStyle(
            color: DesignTokens.neonCyan,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_photo_alternate,
              color: DesignTokens.neonCyan,
            ),
            onPressed: () =>
                context.push(app_router.RouteConstants.posterGeneratorPath),
            tooltip: 'Create Poster',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DesignTokens.neonCyan),
            )
          : Column(
              children: [
                _buildFilters(),
                Expanded(child: _buildTemplateGrid()),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          // Style filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _styleChip(null, 'All Styles'),
                ...PosterStyle.values.map(
                  (s) => _styleChip(s, s.name.toUpperCase()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Layout filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _layoutChip(null, 'All Layouts'),
                ...PosterLayout.values.map(
                  (l) => _layoutChip(l, l.name.toUpperCase()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _styleChip(PosterStyle? style, String label) {
    final selected = _filterStyle == style;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        label: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : DesignTokens.neonCyan,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        selectedColor: DesignTokens.neonCyan,
        backgroundColor: DesignTokens.bgCard,
        side: BorderSide(color: DesignTokens.neonCyan.withValues(alpha: 0.3)),
        onSelected: (_) => setState(() {
          _filterStyle = _filterStyle == style ? null : style;
        }),
      ),
    );
  }

  Widget _layoutChip(PosterLayout? layout, String label) {
    final selected = _filterLayout == layout;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        label: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : DesignTokens.neonAmber,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        selectedColor: DesignTokens.neonAmber,
        backgroundColor: DesignTokens.bgCard,
        side: BorderSide(color: DesignTokens.neonAmber.withValues(alpha: 0.3)),
        onSelected: (_) => setState(() {
          _filterLayout = _filterLayout == layout ? null : layout;
        }),
      ),
    );
  }

  Widget _buildTemplateGrid() {
    var templates = _service.allTemplates;
    if (_filterStyle != null) {
      templates = templates.where((t) => t.style == _filterStyle).toList();
    }
    if (_filterLayout != null) {
      templates = templates.where((t) => t.layout == _filterLayout).toList();
    }

    if (templates.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, color: Colors.white24, size: 64),
            SizedBox(height: 16),
            Text(
              'No templates match filters',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: templates.length,
      itemBuilder: (ctx, i) => _buildTemplateCard(templates[i]),
    );
  }

  Widget _buildTemplateCard(PosterTemplate template) {
    final styleColor = _colorForStyle(template.style);

    return GestureDetector(
      onTap: () => _useTemplate(template),
      child: Container(
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: styleColor.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(color: styleColor.withValues(alpha: 0.1), blurRadius: 12),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Template preview
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image(
                      image: AssetImage(
                        template.backgroundAsset ?? ImageAssets.bgHero,
                      ),
                      fit: BoxFit.cover,
                    ),
                    // Dark overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                    // Sample text preview
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FIGHT NIGHT',
                            style: TextStyle(
                              color: styleColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              shadows: [
                                Shadow(
                                  color: styleColor.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'VS',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Style badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: styleColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          template.style.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (template.isPremium)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.neonGold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Template info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.description,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.neonCyan.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            template.layout.name.toUpperCase(),
                            style: const TextStyle(
                              color: DesignTokens.neonCyan,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (template.sportType != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            template.sportType!.toUpperCase(),
                            style: TextStyle(
                              color: styleColor.withValues(alpha: 0.7),
                              fontSize: 9,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (template.usageCount > 0)
                          Text(
                            '${template.usageCount}×',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _useTemplate(PosterTemplate template) {
    _service.recordUsage(template.id);
    context.push(
      app_router.RouteConstants.posterGeneratorPath,
      extra: {
        'templateId': template.id,
        'style': template.style.name,
        'config': template.config,
      },
    );
  }

  Color _colorForStyle(PosterStyle style) => switch (style) {
    PosterStyle.gritty => DesignTokens.neonRed,
    PosterStyle.cinematic => DesignTokens.neonAmber,
    PosterStyle.clean => DesignTokens.neonCyan,
    PosterStyle.neon => DesignTokens.neonMagenta,
    PosterStyle.vintage => const Color(0xFFC0392B),
    PosterStyle.minimal => DesignTokens.neonGreen,
  };
}
