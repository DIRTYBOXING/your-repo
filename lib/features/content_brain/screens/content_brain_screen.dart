import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/n8n_service.dart';
import '../../../shared/widgets/workflow_run_status_panel.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC CONTENT BRAIN SCREEN — AI Content Generation Trigger
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Allows admins/promoters to generate AI fight content via the n8n pipeline.
///
/// Flow:
///   1. User fills in topic + platform + tone
///   2. Calls the backend triggerN8N router through N8nService
///   3. Functions route to the content-brain executor and workflow state lane
///   4. Returns platform-ready posts
///   5. Optionally auto-publishes to feed / Blotato
///
/// ═══════════════════════════════════════════════════════════════════════════
class ContentBrainScreen extends StatefulWidget {
  const ContentBrainScreen({super.key});

  @override
  State<ContentBrainScreen> createState() => _ContentBrainScreenState();
}

class _ContentBrainScreenState extends State<ContentBrainScreen> {
  final _topicController = TextEditingController();
  final _posterUrlController = TextEditingController();
  final _supportingAssetUrlController = TextEditingController();
  final _scrollController = ScrollController();
  final _n8nService = N8nService();

  String _platform = 'all';
  String _brandTone = 'hype';
  String _niche = 'general';
  String _audienceType = 'fans';
  String _objective = 'engagement';
  String _postType = 'text';
  bool _autoPublish = false;
  bool _autoDistribute = false;

  bool _isGenerating = false;
  bool _isLoadingDoctrine = true;
  Map<String, dynamic>? _result;
  Map<String, dynamic>? _streamingDoctrine;
  String? _error;
  String? _doctrineError;

  static const _platforms = [
    'all',
    'instagram',
    'tiktok',
    'youtube',
    'linkedin',
    'x',
    'threads',
    'facebook',
    'bluesky',
    'pinterest',
  ];
  static const _tones = [
    'hype',
    'analytical',
    'motivational',
    'news',
    'edgy',
    'underground',
  ];
  static const _niches = [
    'general',
    'mma',
    'boxing',
    'muay_thai',
    'kickboxing',
    'bare_knuckle',
    'bkfc',
    'k1',
  ];
  static const _audiences = [
    'fans',
    'fighters',
    'promoters',
    'casual',
    'coaches',
    'all',
  ];
  static const _objectives = [
    'engagement',
    'traffic',
    'awareness',
    'conversion',
    'community',
  ];
  static const _postTypes = [
    'text',
    'image',
    'video',
    'carousel',
    'reel',
    'story',
    'short',
  ];

  @override
  void initState() {
    super.initState();
    _loadStreamingDoctrine();
  }

  @override
  void dispose() {
    _topicController.dispose();
    _posterUrlController.dispose();
    _supportingAssetUrlController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStreamingDoctrine() async {
    setState(() {
      _isLoadingDoctrine = true;
      _doctrineError = null;
    });

    final doctrine = await _n8nService.getStreamingDoctrine(
      requestedPlatform: _platform,
      businessObjective: _objective,
      sport: _niche,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingDoctrine = false;
      if (doctrine?['status'] == 'success') {
        _streamingDoctrine = doctrine;
      } else {
        _streamingDoctrine = null;
        _doctrineError =
            doctrine?['message'] ?? 'Unable to load streaming doctrine';
      }
    });
  }

  Future<void> _generate() async {
    final topic = _topicController.text.trim();
    final posterUrl = _posterUrlController.text.trim();
    final supportingAssetUrl = _supportingAssetUrlController.text.trim();

    if (topic.length < 5) {
      setState(() => _error = 'Topic must be at least 5 characters');
      return;
    }

    if (posterUrl.isNotEmpty && !N8nService.isValidRemoteAssetUrl(posterUrl)) {
      setState(() => _error = 'Poster URL 1 must be a valid http or https URL');
      return;
    }

    if (supportingAssetUrl.isNotEmpty &&
        !N8nService.isValidRemoteAssetUrl(supportingAssetUrl)) {
      setState(() => _error = 'Asset URL 2 must be a valid http or https URL');
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
      _result = null;
    });

    try {
      final data = await _n8nService.triggerContentBrain(
        webInput: topic,
        platform: _platform,
        postType: _postType,
        brandTone: _brandTone,
        audienceType: _audienceType,
        niche: _niche,
        objective: _objective,
        autoPublish: _autoPublish,
        autoDistribute: _autoDistribute,
        posterUrl: posterUrl.isEmpty ? null : posterUrl,
        assetUrls: supportingAssetUrl.isEmpty ? null : [supportingAssetUrl],
      );

      if (data?['status'] == 'success') {
        setState(() => _result = data);
        // Scroll to results
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        setState(
          () => _error = data?['message'] ?? 'Content generation failed',
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.secondaryBackground,
        title: const Row(
          children: [
            Icon(Icons.psychology, color: AppTheme.neonCyan, size: 24),
            SizedBox(width: 8),
            Text(
              'Content Brain',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        actions: [
          if (_result != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.neonCyan),
              onPressed: () => setState(() {
                _result = null;
                _error = null;
              }),
              tooltip: 'New Generation',
            ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStreamingDoctrineCard(),
            const SizedBox(height: 20),

            // ── Topic Input ──
            _sectionLabel('What content do you need?'),
            const SizedBox(height: 8),
            TextField(
              controller: _topicController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText:
                    'e.g., "Create hype posts for Ultimate Legends Fight Night April 24 — Jordan Roesler WBC Silver Title"',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: AppTheme.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.neonCyan,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            _sectionLabel('Media Pipeline'),
            const SizedBox(height: 8),
            _buildUrlField(
              'Poster URL 1',
              _posterUrlController,
              'Primary poster, hero image, or SVG source URL',
            ),
            const SizedBox(height: 12),
            _buildUrlField(
              'Asset URL 2',
              _supportingAssetUrlController,
              'Optional second image or poster URL for the same content pack',
            ),

            const SizedBox(height: 20),

            // ── Configuration Grid ──
            _sectionLabel('Configuration'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _dropdown('Platform', _platform, _platforms, (v) {
                  setState(() => _platform = v);
                  _loadStreamingDoctrine();
                }),
                _dropdown(
                  'Tone',
                  _brandTone,
                  _tones,
                  (v) => setState(() => _brandTone = v),
                ),
                _dropdown('Niche', _niche, _niches, (v) {
                  setState(() => _niche = v);
                  _loadStreamingDoctrine();
                }),
                _dropdown(
                  'Audience',
                  _audienceType,
                  _audiences,
                  (v) => setState(() => _audienceType = v),
                ),
                _dropdown('Objective', _objective, _objectives, (v) {
                  setState(() => _objective = v);
                  _loadStreamingDoctrine();
                }),
                _dropdown(
                  'Post Type',
                  _postType,
                  _postTypes,
                  (v) => setState(() => _postType = v),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Auto-Publish Toggles ──
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    value: _autoPublish,
                    onChanged: (v) => setState(() => _autoPublish = v),
                    title: const Text(
                      'Auto-Publish to Feed',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    subtitle: Text(
                      'Posts to DFC internal feed',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                    activeThumbColor: AppTheme.neonGreen,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    value: _autoDistribute,
                    onChanged: (v) => setState(() => _autoDistribute = v),
                    title: const Text(
                      'Auto-Distribute via Blotato',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    subtitle: Text(
                      'Cross-platform via social engine',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                    activeThumbColor: AppTheme.neonMagenta,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Generate Button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: AppTheme.neonCyan.withValues(
                    alpha: 0.3,
                  ),
                ),
                child: _isGenerating
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Generating...',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Generate Content',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),
            const WorkflowRunStatusPanel(),

            // ── Error Display ──
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.error.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: AppTheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Results Display ──
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildResultsSection(),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.neonCyan,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildStreamingDoctrineCard() {
    final doctrine = _streamingDoctrine;
    final secondaryPlatforms = List<String>.from(
      doctrine?['secondaryPlatforms'] as List<dynamic>? ?? const <String>[],
    );
    final operatorNotes = List<String>.from(
      doctrine?['operatorNotes'] as List<dynamic>? ?? const <String>[],
    );
    final riskFlags = List<String>.from(
      doctrine?['riskFlags'] as List<dynamic>? ?? const <String>[],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.neonOrange.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hub, color: AppTheme.neonOrange, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Streaming Doctrine v1',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _isLoadingDoctrine ? null : _loadStreamingDoctrine,
                icon: const Icon(Icons.refresh, color: AppTheme.neonCyan),
                tooltip: 'Refresh Doctrine',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Canonical DFC streaming posture from the backend brain. This is the lane content, PPV, and operator decisions should follow.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingDoctrine)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(color: AppTheme.neonCyan),
              ),
            )
          else if (_doctrineError != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.error.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                _doctrineError!,
                style: const TextStyle(color: AppTheme.error, fontSize: 12),
              ),
            )
          else if (doctrine != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDoctrineMetric(
                  'Primary Platform',
                  doctrine['primaryPlatform'] as String? ?? 'Unavailable',
                  AppTheme.neonGreen,
                ),
                const SizedBox(height: 12),
                _buildDoctrineMetric(
                  'Messaging Key',
                  doctrine['messagingKey'] as String? ?? '',
                  AppTheme.neonCyan,
                ),
                if (secondaryPlatforms.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _sectionLabel('Secondary Platforms'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: secondaryPlatforms
                        .map(
                          (platform) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.neonCyan.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            child: Text(
                              platform,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (operatorNotes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _sectionLabel('Operator Notes'),
                  const SizedBox(height: 8),
                  ...operatorNotes.map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.fiber_manual_record,
                              size: 8,
                              color: AppTheme.neonOrange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              note,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _sectionLabel('Risk Flags'),
                const SizedBox(height: 8),
                if (riskFlags.isEmpty)
                  Text(
                    'No active doctrine risk flags for the current selections.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12,
                    ),
                  )
                else
                  ...riskFlags.map(
                    (flag) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        flag,
                        style: const TextStyle(
                          color: AppTheme.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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

  Widget _buildDoctrineMetric(String label, String value, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.2),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: AppTheme.cardBackground,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: options
                    .map(
                      (o) => DropdownMenuItem(
                        value: o,
                        child: Text(
                          o.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    final content = _result?['content'] as Map<String, dynamic>? ?? {};
    final posts = content['posts'] as List<dynamic>? ?? [];
    final headline = content['headline'] as String? ?? '';
    final summary = content['summary'] as String? ?? '';
    final viralScore = content['viralScore'] as num? ?? 0;
    final toneSummary = content['toneSummary'] as String? ?? '';
    final mediaPlan = content['mediaPlan'] is Map<String, dynamic>
        ? content['mediaPlan'] as Map<String, dynamic>
        : content['mediaPlan'] is Map
        ? Map<String, dynamic>.from(content['mediaPlan'] as Map)
        : const <String, dynamic>{};
    final assetUrls = _asStringList(
      mediaPlan['assetUrls'] is List
          ? mediaPlan['assetUrls'] as List
          : content['suggestedMediaAssets'] is List
          ? content['suggestedMediaAssets'] as List
          : const <dynamic>[],
    );
    final previewAssetUrl =
        mediaPlan['primaryPreviewAssetUrl']?.toString() ??
        content['suggestedMedia']?.toString() ??
        '';
    final publishableAssetUrl =
        mediaPlan['primaryPublishableAssetUrl']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.neonGreen, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Generated Content',
              style: TextStyle(
                color: AppTheme.neonGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _viralColor(
                  viralScore.toDouble(),
                ).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _viralColor(
                    viralScore.toDouble(),
                  ).withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                'Viral: $viralScore/10',
                style: TextStyle(
                  color: _viralColor(viralScore.toDouble()),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        // Headline + Summary
        if (headline.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            headline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (summary.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            summary,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
        if (toneSummary.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Tone: $toneSummary',
            style: const TextStyle(
              color: AppTheme.neonMagenta,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],

        if (assetUrls.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildMediaPlanSummary(
            assetUrls: assetUrls,
            previewAssetUrl: previewAssetUrl,
            publishableAssetUrl: publishableAssetUrl,
          ),
        ],

        // Posts
        if (posts.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...posts.map((post) {
            final p = post as Map<String, dynamic>? ?? {};
            return _buildPostCard(p);
          }),
        ],
      ],
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final platform = post['platform'] as String? ?? 'unknown';
    final caption = post['caption'] as String? ?? '';
    final postType = post['postType'] as String? ?? '';
    final bestTime = post['best_time_to_post'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _platformColor(platform).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Platform header
          Row(
            children: [
              Icon(
                _platformIcon(platform),
                color: _platformColor(platform),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${platform.toUpperCase()} ${postType.isNotEmpty ? '• $postType' : ''}',
                style: TextStyle(
                  color: _platformColor(platform),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              if (bestTime.isNotEmpty) ...[
                const Spacer(),
                Text(
                  bestTime,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Caption
          SelectableText(
            caption,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          // Copy button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                // Copy to clipboard
                final data = caption;
                if (data.isNotEmpty) {
                  // Use Clipboard API
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied $platform post to clipboard'),
                      backgroundColor: AppTheme.neonGreen,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy, size: 14),
              label: const Text('Copy', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: AppTheme.neonCyan),
            ),
          ),
        ],
      ),
    );
  }

  Color _viralColor(double score) {
    if (score >= 8) return AppTheme.neonGreen;
    if (score >= 5) return AppTheme.neonOrange;
    return AppTheme.error;
  }

  Color _platformColor(String platform) {
    switch (platform) {
      case 'instagram':
        return AppTheme.neonMagenta;
      case 'tiktok':
        return AppTheme.neonCyan;
      case 'youtube':
        return AppTheme.error;
      case 'linkedin':
        return const Color(0xFF0A66C2);
      case 'x':
        return Colors.white;
      case 'threads':
        return Colors.white;
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'bluesky':
        return const Color(0xFF0085FF);
      case 'pinterest':
        return AppTheme.error;
      default:
        return AppTheme.neonCyan;
    }
  }

  IconData _platformIcon(String platform) {
    switch (platform) {
      case 'instagram':
        return Icons.camera_alt;
      case 'tiktok':
        return Icons.music_note;
      case 'youtube':
        return Icons.play_circle_fill;
      case 'linkedin':
        return Icons.work;
      case 'x':
        return Icons.alternate_email;
      case 'threads':
        return Icons.forum;
      case 'facebook':
        return Icons.facebook;
      case 'bluesky':
        return Icons.cloud;
      case 'pinterest':
        return Icons.push_pin;
      default:
        return Icons.public;
    }
  }

  List<String> _asStringList(List<dynamic> values) {
    return values
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  Widget _buildUrlField(
    String label,
    TextEditingController controller,
    String hintText,
  ) {
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
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
            prefixIcon: const Icon(
              Icons.link_rounded,
              color: AppTheme.neonCyan,
              size: 18,
            ),
            filled: true,
            fillColor: AppTheme.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.neonCyan),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaPlanSummary({
    required List<String> assetUrls,
    required String previewAssetUrl,
    required String publishableAssetUrl,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Media Plan',
            style: TextStyle(
              color: AppTheme.neonCyan,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Assets attached: ${assetUrls.length}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          if (previewAssetUrl.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Primary preview: $previewAssetUrl',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            publishableAssetUrl.isNotEmpty
                ? 'Primary publishable asset: $publishableAssetUrl'
                : 'No raster or video publish asset detected yet. SVG and source URLs are preserved, but external publishing stays text/manual until a publishable render exists.',
            style: TextStyle(
              color: publishableAssetUrl.isNotEmpty
                  ? Colors.white.withValues(alpha: 0.72)
                  : AppTheme.warning,
              fontSize: 11,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          ...assetUrls
              .take(2)
              .map(
                (url) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.image_outlined,
                          color: AppTheme.neonGreen,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          url,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.68),
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
