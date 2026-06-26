import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/n8n_service.dart';

class AIPostGeneratorCard extends StatefulWidget {
  const AIPostGeneratorCard({super.key});

  @override
  State<AIPostGeneratorCard> createState() => _AIPostGeneratorCardState();
}

class _AIPostGeneratorCardState extends State<AIPostGeneratorCard> {
  final _promptController = TextEditingController();
  final _posterUrlController = TextEditingController();
  final _supportingAssetUrlController = TextEditingController();
  N8nService? _n8nService;

  String _platform = 'all';
  String _tone = 'hype';
  bool _isGenerating = false;
  String? _error;
  Map<String, dynamic>? _contentPack;

  static const _platforms = [
    'all',
    'facebook',
    'instagram',
    'tiktok',
    'youtube',
  ];
  static const _tones = ['hype', 'analytical', 'news', 'edgy'];

  @override
  void dispose() {
    _promptController.dispose();
    _posterUrlController.dispose();
    _supportingAssetUrlController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    final posterUrl = _posterUrlController.text.trim();
    final supportingAssetUrl = _supportingAssetUrlController.text.trim();

    if (prompt.length < 5) {
      setState(() => _error = 'Prompt must be at least 5 characters.');
      return;
    }

    if (posterUrl.isNotEmpty && !N8nService.isValidRemoteAssetUrl(posterUrl)) {
      setState(
        () => _error = 'Poster URL 1 must be a valid http or https URL.',
      );
      return;
    }

    if (supportingAssetUrl.isNotEmpty &&
        !N8nService.isValidRemoteAssetUrl(supportingAssetUrl)) {
      setState(() => _error = 'Asset URL 2 must be a valid http or https URL.');
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
      _contentPack = null;
    });

    Map<String, dynamic>? result;
    try {
      result = await (_n8nService ??= N8nService()).triggerContentBrain(
        webInput: prompt,
        platform: _platform,
        brandTone: _tone,
        posterUrl: posterUrl.isEmpty ? null : posterUrl,
        assetUrls: supportingAssetUrl.isEmpty ? null : [supportingAssetUrl],
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isGenerating = false;
        _error =
            'The AI composer is unavailable until Firebase is initialized for this session.';
      });
      return;
    }

    if (!mounted) {
      return;
    }

    final content = result?['content'];
    if (content is Map) {
      setState(() {
        _isGenerating = false;
        _contentPack = Map<String, dynamic>.from(content);
      });
      return;
    }

    setState(() {
      _isGenerating = false;
      _error =
          result?['message']?.toString() ??
          'The AI composer could not generate a content pack right now.';
    });
  }

  List<Map<String, dynamic>> _postsFromContent() {
    final rawPosts = _contentPack?['posts'];
    if (rawPosts is! List) {
      return const [];
    }

    return rawPosts
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList();
  }

  List<String> _mediaPreviewUrlsFromContent() {
    final mediaPlan = _contentPack?['mediaPlan'];
    if (mediaPlan is Map) {
      final assetUrls = mediaPlan['assetUrls'];
      if (assetUrls is List) {
        return assetUrls
            .whereType<String>()
            .map((url) => url.trim())
            .where((url) => url.isNotEmpty)
            .toList();
      }
    }

    final suggestedMediaAssets = _contentPack?['suggestedMediaAssets'];
    if (suggestedMediaAssets is List) {
      return suggestedMediaAssets
          .whereType<String>()
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty)
          .toList();
    }

    final suggestedMedia =
        _contentPack?['suggestedMedia']?.toString().trim() ?? '';
    return suggestedMedia.isEmpty ? const [] : [suggestedMedia];
  }

  Future<void> _copyCaption(String caption) async {
    await Clipboard.setData(ClipboardData(text: caption));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Caption copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final posts = _postsFromContent();
    final mediaPreviewUrls = _mediaPreviewUrlsFromContent();
    final headline = _contentPack?['headline']?.toString() ?? '';
    final summary = _contentPack?['summary']?.toString() ?? '';
    final toneSummary = _contentPack?['toneSummary']?.toString() ?? _tone;
    final viralScore = _contentPack?['viralScore'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF11253A),
              DesignTokens.bgCard.withValues(alpha: 0.98),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: DesignTokens.neonCyan.withValues(alpha: 0.24),
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.neonCyan.withValues(alpha: 0.08),
              blurRadius: 22,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: DesignTokens.neonCyan,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fight Facebook Engine',
                        style: TextStyle(
                          color: DesignTokens.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Generate fight-night hype without leaving the feed.',
                        style: TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.push('/content-brain'),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Full Brain'),
                  style: TextButton.styleFrom(
                    foregroundColor: DesignTokens.neonCyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _promptController,
              minLines: 2,
              maxLines: 4,
              style: const TextStyle(color: DesignTokens.textPrimary),
              decoration: InputDecoration(
                hintText:
                    'Example: Build a Facebook and Instagram hype burst for Ultimate Legends this Friday night.',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.42),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AppTheme.cardBackground.withValues(alpha: 0.86),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: DesignTokens.neonCyan),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _AssetUrlField(
              controller: _posterUrlController,
              label: 'Poster URL 1',
              hintText:
                  'Primary poster or hero image URL. SVG is accepted and preserved in the pipeline.',
            ),
            const SizedBox(height: 10),
            _AssetUrlField(
              controller: _supportingAssetUrlController,
              label: 'Asset URL 2',
              hintText:
                  'Optional second image or poster URL for the same content pack.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ConfigDropdown(
                    label: 'Platform',
                    value: _platform,
                    options: _platforms,
                    onChanged: (value) => setState(() => _platform = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ConfigDropdown(
                    label: 'Tone',
                    value: _tone,
                    options: _tones,
                    onChanged: (value) => setState(() => _tone = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generate,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.bolt_rounded, size: 18),
                    label: Text(_isGenerating ? 'Generating' : 'Generate Hype'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.neonCyan,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: posts.isEmpty
                      ? null
                      : () => _copyCaption(
                          posts.first['caption']?.toString() ?? '',
                        ),
                  icon: const Icon(Icons.copy_all_rounded, size: 18),
                  label: const Text('Copy First'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(
                  color: Color(0xFFFF7B7B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (_contentPack != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoPill(
                          label: 'Tone',
                          value: toneSummary,
                          color: DesignTokens.neonCyan,
                        ),
                        _InfoPill(
                          label: 'Posts',
                          value: posts.length.toString(),
                          color: DesignTokens.neonAmber,
                        ),
                        if (mediaPreviewUrls.isNotEmpty)
                          _InfoPill(
                            label: 'Assets',
                            value: mediaPreviewUrls.length.toString(),
                            color: DesignTokens.neonGreen,
                          ),
                        if (viralScore != null)
                          _InfoPill(
                            label: 'Viral',
                            value: viralScore.toString(),
                            color: DesignTokens.neonMagenta,
                          ),
                      ],
                    ),
                    if (headline.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        headline,
                        style: const TextStyle(
                          color: DesignTokens.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (summary.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        summary,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.76),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                    if (mediaPreviewUrls.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: mediaPreviewUrls
                            .take(2)
                            .map(_MediaAssetPreviewCard.new)
                            .toList(),
                      ),
                    ],
                    if (posts.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      ...posts.take(2).map(_PostPreviewCard.new),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AssetUrlField extends StatelessWidget {
  const _AssetUrlField({
    required this.controller,
    required this.label,
    required this.hintText,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.66),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          style: const TextStyle(color: DesignTokens.textPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.42),
              fontSize: 12,
            ),
            filled: true,
            fillColor: AppTheme.cardBackground.withValues(alpha: 0.86),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: DesignTokens.neonCyan),
            ),
            prefixIcon: const Icon(
              Icons.link_rounded,
              color: DesignTokens.neonCyan,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfigDropdown extends StatelessWidget {
  const _ConfigDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.66),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: AppTheme.cardBackground,
          style: const TextStyle(color: DesignTokens.textPrimary),
          iconEnabledColor: Colors.white70,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppTheme.cardBackground.withValues(alpha: 0.86),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ),
              )
              .toList(),
          onChanged: (next) {
            if (next != null) {
              onChanged(next);
            }
          },
        ),
      ],
    );
  }
}

class _MediaAssetPreviewCard extends StatelessWidget {
  const _MediaAssetPreviewCard(this.url);

  final String url;

  bool get _isSvg =>
      RegExp(r'\.svg(?:$|\?)', caseSensitive: false).hasMatch(url);
  bool get _isVideo => RegExp(
    r'\.(?:mp4|mov|m4v|webm|m3u8)(?:$|\?)',
    caseSensitive: false,
  ).hasMatch(url);

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url);
    final host = uri?.host.isNotEmpty == true ? uri!.host : 'remote asset';
    final assetType = _isSvg
        ? 'SVG'
        : _isVideo
        ? 'VIDEO'
        : 'IMAGE';

    return Container(
      width: 148,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: SizedBox(
              height: 92,
              width: double.infinity,
              child: _isSvg || _isVideo
                  ? Container(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.08),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isSvg
                                ? Icons.gesture_rounded
                                : Icons.ondemand_video_rounded,
                            color: DesignTokens.neonCyan,
                            size: 26,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            assetType,
                            style: const TextStyle(
                              color: DesignTokens.neonCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: DesignTokens.neonAmber.withValues(alpha: 0.08),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_not_supported_rounded,
                            color: DesignTokens.neonAmber,
                            size: 24,
                          ),
                        );
                      },
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonGreen.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    assetType,
                    style: const TextStyle(
                      color: DesignTokens.neonGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  host,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  url,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostPreviewCard extends StatelessWidget {
  const _PostPreviewCard(this.post);

  final Map<String, dynamic> post;

  @override
  Widget build(BuildContext context) {
    final platform = post['platform']?.toString() ?? 'platform';
    final caption = post['caption']?.toString() ?? '';
    final postType = post['postType']?.toString() ?? 'text';

    if (caption.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  platform.toUpperCase(),
                  style: const TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                postType,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.58),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            caption,
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
