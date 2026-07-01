import 'package:flutter/material.dart' hide RouterConfig;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/cross_platform_posting_service.dart';
import '../../../shared/services/social_post_adapter_service.dart';
import '../../../shared/services/social_platform_specs.dart';
import '../../../shared/services/subscription_service.dart';

/// Cross-platform content composer — pick platforms, write caption, publish.
///
/// Enforces plan-based limits:
///   Free → blocked (upgrade CTA)
///   Warrior → 3/day, 4 platforms
///   Coach → 10/day, 6 platforms, scheduling
///   Gym → 25/day, all 9
///   Promoter → unlimited, all 9, scheduling
class CrossPlatformPublishScreen extends StatefulWidget {
  /// Pre-filled video URL (e.g. from ViralAiCoach or content pipeline)
  final String? videoUrl;

  /// Pre-filled caption text
  final String? caption;

  /// Pre-filled hashtags as a single composer string.
  final String? hashtags;

  /// Pre-filled direct media URLs for image or carousel posts.
  final List<String> mediaUrls;

  /// Optional media type hints for the pre-filled media URLs.
  final List<String> mediaTypes;

  /// Optional pre-selected post type key.
  final String? postType;

  /// Whether the composer should open in scheduling mode.
  final bool scheduleOnOpen;

  const CrossPlatformPublishScreen({
    super.key,
    this.videoUrl,
    this.caption,
    this.hashtags,
    this.mediaUrls = const [],
    this.mediaTypes = const [],
    this.postType,
    this.scheduleOnOpen = false,
  });

  @override
  State<CrossPlatformPublishScreen> createState() =>
      _CrossPlatformPublishScreenState();
}

class _CrossPlatformPublishScreenState
    extends State<CrossPlatformPublishScreen> {
  final _service = CrossPlatformPostingService();
  final _subscriptionService = SubscriptionService();
  final _captionController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _hashtagController = TextEditingController();

  String _userId = 'anonymous';
  String _userTier = 'free';

  final Map<SocialPlatform, bool> _selectedPlatforms = {};
  PostType _postType = PostType.video;
  bool _isLoadingAccess = true;
  bool _isPublishing = false;
  bool _showScheduler = false;
  DateTime? _scheduledAt;
  PostingUsage? _usage;
  String? _error;
  Map<String, dynamic>? _publishResult;

  PostingLimits _limits = CrossPlatformPostingService.limitsForTier('free');

  @override
  void initState() {
    super.initState();
    _captionController.text = widget.caption ?? '';
    _videoUrlController.text = widget.mediaUrls.isNotEmpty
        ? widget.mediaUrls.join('\n')
        : widget.videoUrl ?? '';
    _hashtagController.text = widget.hashtags ?? '';
    _postType = _resolveInitialPostType();

    _captionController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadAccess();
      if (widget.scheduleOnOpen && mounted) {
        await _pickScheduleAt();
      }
    });
  }

  Future<void> _loadAccess() async {
    final auth = context.read<AuthService>();
    final subscription = await _subscriptionService.getCurrentSubscription();
    final resolvedTier = _resolvePostingTier(
      role: auth.userModel?.role,
      subscriptionTier: subscription.tier,
      isAdmin: auth.isAdmin,
    );
    final resolvedUserId =
        auth.currentUser?.uid ?? auth.userModel?.id ?? subscription.odUserId;

    _configurePlatformsForTier(resolvedTier);

    if (!mounted) return;
    setState(() {
      _userId = resolvedUserId;
      _userTier = resolvedTier;
      _limits = CrossPlatformPostingService.limitsForTier(resolvedTier);
      _isLoadingAccess = false;
    });

    await _loadUsage();
  }

  void _configurePlatformsForTier(String tier) {
    final available = CrossPlatformPostingService.platformsForTier(tier);
    _selectedPlatforms
      ..clear()
      ..addEntries(
        CrossPlatformPostingService.supportedPlatforms.map(
          (platform) => MapEntry(platform, available.contains(platform)),
        ),
      );
  }

  String _resolvePostingTier({
    required UserRole? role,
    required SubscriptionTier subscriptionTier,
    required bool isAdmin,
  }) {
    if (isAdmin) return 'promoter';

    switch (subscriptionTier) {
      case SubscriptionTier.free:
        return 'free';
      case SubscriptionTier.fighterPro:
        return 'warrior';
      case SubscriptionTier.coachMentor:
        return role == UserRole.gym ? 'gym' : 'coach';
      case SubscriptionTier.promoterGym:
      case SubscriptionTier.legacy:
        if (role == UserRole.promoter) return 'promoter';
        if (role == UserRole.gym) return 'gym';
        if (role == UserRole.coach) return 'coach';
        return 'warrior';
    }
  }

  Future<void> _loadUsage() async {
    final usage = await _service.getUsageToday(_userId);
    if (mounted) setState(() => _usage = usage);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoUrlController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  List<SocialPlatform> get _enabledPlatforms => _selectedPlatforms.entries
      .where((e) => e.value)
      .map((e) => e.key)
      .toList();

  int get _selectedCount => _enabledPlatforms.length;

  PostType _resolveInitialPostType() {
    final configuredType = _parseInitialPostType(widget.postType);
    if (configuredType != null) {
      return configuredType;
    }

    final normalizedTypes = widget.mediaTypes
        .map((type) => type.trim().toLowerCase())
        .where((type) => type.isNotEmpty)
        .toList(growable: false);
    if (normalizedTypes.any((type) => type.contains('video'))) {
      return PostType.video;
    }

    final prefilledMediaUrls = widget.mediaUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    if (prefilledMediaUrls.length > 1) {
      return PostType.carousel;
    }
    if (prefilledMediaUrls.length == 1) {
      return PostType.image;
    }

    final videoUrl = widget.videoUrl?.trim();
    if (videoUrl != null && videoUrl.isNotEmpty) {
      return PostType.video;
    }

    return PostType.text;
  }

  PostType? _parseInitialPostType(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'text':
        return PostType.text;
      case 'image':
        return PostType.image;
      case 'video':
        return PostType.video;
      case 'carousel':
        return PostType.carousel;
      case 'story':
        return PostType.story;
      case 'reel':
        return PostType.reel;
      case 'short':
      case 'short_':
        return PostType.short_;
      default:
        return null;
    }
  }

  List<String> _parseMediaUrls() {
    return _videoUrlController.text
        .split('\n')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  bool _usesImageMedia(PostType type) {
    return type == PostType.image || type == PostType.carousel;
  }

  bool _usesSingleUrl(PostType type) {
    return type == PostType.image ||
        type == PostType.video ||
        type == PostType.reel ||
        type == PostType.story ||
        type == PostType.short_;
  }

  String _postTypeLabel(PostType type) {
    switch (type) {
      case PostType.text:
        return 'Text';
      case PostType.image:
        return 'Image';
      case PostType.video:
        return 'Video';
      case PostType.carousel:
        return 'Carousel';
      case PostType.story:
        return 'Story';
      case PostType.reel:
        return 'Reel';
      case PostType.short_:
        return 'Short';
    }
  }

  NormalizedPostMedia _buildNormalizedMedia(List<String> parsedMediaUrls) {
    if (_postType == PostType.text) {
      return const NormalizedPostMedia();
    }

    if (_usesImageMedia(_postType)) {
      final imageUrls = _postType == PostType.image
          ? parsedMediaUrls.take(1).toList(growable: false)
          : parsedMediaUrls;
      return SocialPostMediaAdapter.normalizeFields(
        mediaUrls: imageUrls,
        mediaTypes: List<String>.filled(imageUrls.length, 'image'),
      );
    }

    return SocialPostMediaAdapter.normalizeFields(
      externalVideoUrl: parsedMediaUrls.isEmpty ? null : parsedMediaUrls.first,
    );
  }

  Future<void> _publish() async {
    final caption = _captionController.text.trim();
    final parsedMediaUrls = _parseMediaUrls();

    // Text posts only need a caption; all other types need media
    if (_selectedCount == 0) {
      setState(() => _error = 'Select at least one platform.');
      return;
    }
    if (_postType != PostType.text && parsedMediaUrls.isEmpty) {
      setState(
        () => _error =
            'Media URL is required for ${_postTypeLabel(_postType)} posts.',
      );
      return;
    }
    if (_postType == PostType.carousel && parsedMediaUrls.length < 2) {
      setState(() => _error = 'Carousel posts need at least 2 media URLs.');
      return;
    }
    if (_usesSingleUrl(_postType) && parsedMediaUrls.length > 1) {
      setState(
        () => _error =
            '${_postTypeLabel(_postType)} posts accept one media URL. '
            'Use Carousel for multiple images.',
      );
      return;
    }
    if (caption.isEmpty) {
      setState(() => _error = 'Caption is required.');
      return;
    }
    if (_showScheduler && _scheduledAt == null) {
      setState(() => _error = 'Pick a date and time to schedule this post.');
      return;
    }

    final normalizedMedia = _buildNormalizedMedia(parsedMediaUrls);

    // Caption overflow check
    final overflows = PlatformValidator.captionOverflows(
      caption,
      _enabledPlatforms,
    );
    if (overflows.isNotEmpty) {
      final worst = overflows.entries.first;
      setState(
        () => _error =
            'Caption is ${worst.value} chars over the '
            '${platformSpecs[worst.key]!.maxCaptionLength}-char limit '
            'for ${worst.key.label}.',
      );
      return;
    }

    setState(() {
      _isPublishing = true;
      _error = null;
      _publishResult = null;
    });

    try {
      if (_showScheduler && _scheduledAt != null) {
        await _service.scheduleNormalizedPost(
          userId: _userId,
          tier: _userTier,
          caption: caption,
          media: normalizedMedia,
          scheduledAt: _scheduledAt!,
          hashtags: _parseHashtags(),
          platforms: _enabledPlatforms,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Scheduled for ${_formatDate(_scheduledAt!)} to $_selectedCount platforms',
              ),
              backgroundColor: DesignTokens.neonAmber,
            ),
          );
          context.pop();
        }
      } else {
        final result = await _service.publishNormalizedPost(
          userId: _userId,
          tier: _userTier,
          caption: caption,
          media: normalizedMedia,
          hashtags: _parseHashtags(),
          platforms: _enabledPlatforms,
        );
        if (mounted) {
          setState(() => _publishResult = result);
          await _loadUsage();
        }
      }
    } on PostingLimitException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Publishing failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  List<String> _parseHashtags() {
    final text = _hashtagController.text.trim();
    if (text.isEmpty) return [];
    return text
        .split(RegExp(r'[\s,]+'))
        .map((t) => t.startsWith('#') ? t.substring(1) : t)
        .where((t) => t.isNotEmpty)
        .toList();
  }

  Future<void> _pickScheduleAt() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) {
      return;
    }

    setState(() {
      _scheduledAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
      _showScheduler = true;
    });
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAccess) {
      return const Scaffold(
        backgroundColor: DesignTokens.bgPrimary,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final remainingPosts = _usage != null
        ? _usage!.remaining(_limits.postsPerDay)
        : _limits.postsPerDay;

    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        title: const Text('PUBLISH'),
        backgroundColor: DesignTokens.bgSecondary,
        foregroundColor: DesignTokens.neonCyan,
        centerTitle: true,
        actions: [
          if (_usage != null && !_limits.isUnlimited)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: remainingPosts > 0
                        ? DesignTokens.neonGreen.withValues(alpha: 0.15)
                        : DesignTokens.neonRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$remainingPosts left today',
                    style: TextStyle(
                      color: remainingPosts > 0
                          ? DesignTokens.neonGreen
                          : DesignTokens.neonRed,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _limits.isBlocked ? _buildUpgradeCta() : _buildComposer(),
    );
  }

  Widget _buildUpgradeCta() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              color: DesignTokens.neonAmber.withValues(alpha: 0.5),
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Cross-Platform Publishing',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upgrade to Warrior (\$7.99/mo) to publish your content '
              'across TikTok, Instagram, YouTube and more.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/subscription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.neonCyan,
                foregroundColor: DesignTokens.bgPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.rocket_launch),
              label: const Text(
                'View Plans',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Tier Banner ──
        _buildTierBanner(),
        const SizedBox(height: 16),

        // ── Post Type Selector ──
        _buildPostTypePicker(),
        const SizedBox(height: 16),

        // ── Media URL (label adapts to post type) ──
        if (_postType != PostType.text)
          _buildField(
            label: _postType == PostType.carousel
                ? 'Media URLs (one per line)'
                : _usesImageMedia(_postType)
                ? 'Image URL'
                : 'Video URL',
            hint: _postType == PostType.carousel
                ? 'https://cdn.example.com/image-1.jpg\nhttps://cdn.example.com/image-2.jpg'
                : 'https://storage.googleapis.com/...',
            controller: _videoUrlController,
            icon: _postType == PostType.image
                ? Icons.image
                : _postType == PostType.carousel
                ? Icons.view_carousel
                : Icons.videocam,
            maxLines: _postType == PostType.carousel ? 4 : 1,
          ),
        if (_postType != PostType.text) const SizedBox(height: 12),

        // ── Caption ──
        _buildField(
          label: 'Caption',
          hint: 'Write your caption...',
          controller: _captionController,
          icon: Icons.edit,
          maxLines: 4,
          maxLength: PlatformValidator.tightestCaptionLimit(_enabledPlatforms),
        ),

        // ── Live Per-Platform Char Counter ──
        if (_captionController.text.isNotEmpty) _buildCharCounters(),
        const SizedBox(height: 12),

        // ── Hashtags ──
        _buildField(
          label: 'Hashtags',
          hint: '#MMA #UFC #FightNight (space or comma separated)',
          controller: _hashtagController,
          icon: Icons.tag,
        ),
        const SizedBox(height: 20),

        // ── Platform Picker ──
        _buildPlatformPicker(),
        const SizedBox(height: 16),

        // ── Schedule Toggle (if plan allows) ──
        if (_limits.canSchedule) _buildScheduleSection(),

        // ── Error ──
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignTokens.neonRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: DesignTokens.neonRed.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber,
                  color: DesignTokens.neonRed,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: DesignTokens.neonRed,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── Publish Result ──
        if (_publishResult != null) ...[
          const SizedBox(height: 12),
          _buildResultCard(),
        ],

        const SizedBox(height: 20),

        // ── Publish Button ──
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isPublishing ? null : _publish,
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.neonGreen,
              foregroundColor: DesignTokens.bgPrimary,
              disabledBackgroundColor: DesignTokens.neonGreen.withValues(
                alpha: 0.3,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isPublishing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(_showScheduler ? Icons.schedule_send : Icons.send),
            label: Text(
              _isPublishing
                  ? 'Publishing...'
                  : _showScheduler && _scheduledAt != null
                  ? 'Schedule to $_selectedCount Platforms'
                  : 'Publish to $_selectedCount Platforms',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPostTypePicker() {
    const types = [
      (PostType.text, Icons.text_fields, 'Text'),
      (PostType.image, Icons.image, 'Image'),
      (PostType.video, Icons.videocam, 'Video'),
      (PostType.carousel, Icons.view_carousel, 'Carousel'),
      (PostType.reel, Icons.slow_motion_video, 'Reel'),
      (PostType.short_, Icons.short_text, 'Short'),
      (PostType.story, Icons.amp_stories, 'Story'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Post Type',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: types.map((t) {
              final selected = _postType == t.$1;
              final supported = PlatformValidator.platformsSupporting(
                t.$1,
              ).isNotEmpty;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  selected: selected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        t.$2,
                        size: 14,
                        color: selected
                            ? DesignTokens.bgPrimary
                            : Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t.$3,
                        style: TextStyle(
                          fontSize: 11,
                          color: selected
                              ? DesignTokens.bgPrimary
                              : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                  selectedColor: DesignTokens.neonCyan,
                  backgroundColor: DesignTokens.bgCard,
                  side: BorderSide(
                    color: selected
                        ? DesignTokens.neonCyan
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                  onSelected: supported
                      ? (v) => setState(() => _postType = t.$1)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCharCounters() {
    final caption = _captionController.text;
    if (_enabledPlatforms.isEmpty) return const SizedBox.shrink();

    final overflows = PlatformValidator.captionOverflows(
      caption,
      _enabledPlatforms,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: _enabledPlatforms.map((p) {
          final spec = platformSpecs[p];
          if (spec == null) return const SizedBox.shrink();
          final remaining = spec.maxCaptionLength - caption.length;
          final isOver = overflows.containsKey(p);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isOver
                  ? DesignTokens.neonRed.withValues(alpha: 0.12)
                  : DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isOver
                    ? DesignTokens.neonRed.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _platformIcon(p),
                  size: 12,
                  color: isOver ? DesignTokens.neonRed : _platformColor(p),
                ),
                const SizedBox(width: 4),
                Text(
                  isOver ? '−${-remaining}' : '$remaining',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOver
                        ? DesignTokens.neonRed
                        : remaining < 50
                        ? DesignTokens.neonAmber
                        : Colors.white38,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTierBanner() {
    final tierName = _userTier[0].toUpperCase() + _userTier.substring(1);
    final platformText = _limits.maxPlatforms == 9
        ? 'all 9 platforms'
        : '${_limits.maxPlatforms} platforms';
    final postText = _limits.isUnlimited
        ? 'unlimited posts'
        : '${_limits.postsPerDay} posts/day';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified,
            color: DesignTokens.neonCyan.withValues(alpha: 0.7),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            '$tierName Plan',
            style: const TextStyle(
              color: DesignTokens.neonCyan,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            '$postText · $platformText',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
            prefixIcon: Icon(
              icon,
              color: DesignTokens.neonCyan.withValues(alpha: 0.5),
              size: 20,
            ),
            filled: true,
            fillColor: DesignTokens.bgCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: DesignTokens.neonCyan),
            ),
            counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformPicker() {
    final available = CrossPlatformPostingService.platformsForTier(_userTier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Platforms',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$_selectedCount / ${_limits.maxPlatforms}',
              style: TextStyle(
                color: _selectedCount <= _limits.maxPlatforms
                    ? DesignTokens.neonGreen
                    : DesignTokens.neonRed,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...CrossPlatformPostingService.supportedPlatforms.map((platform) {
          final isAvailable = available.contains(platform);
          final isSelected = _selectedPlatforms[platform] ?? false;
          return _platformTile(platform, isSelected, isAvailable);
        }),
      ],
    );
  }

  Widget _platformTile(SocialPlatform platform, bool selected, bool available) {
    final color = _platformColor(platform);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: SwitchListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          secondary: Icon(
            _platformIcon(platform),
            color: available ? color : Colors.white24,
            size: 22,
          ),
          title: Text(
            platform.label,
            style: TextStyle(
              color: available ? Colors.white : Colors.white38,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          subtitle: available
              ? null
              : const Text(
                  'Upgrade to unlock',
                  style: TextStyle(color: DesignTokens.neonAmber, fontSize: 10),
                ),
          value: selected,
          activeTrackColor: DesignTokens.neonGreen,
          onChanged: available
              ? (v) {
                  if (v &&
                      _selectedCount >= _limits.maxPlatforms &&
                      !(_selectedPlatforms[platform] ?? false)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Max ${_limits.maxPlatforms} platforms on your plan',
                        ),
                        backgroundColor: DesignTokens.neonAmber,
                      ),
                    );
                    return;
                  }
                  setState(() => _selectedPlatforms[platform] = v);
                }
              : null,
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: DesignTokens.neonAmber.withValues(alpha: 0.15),
            ),
          ),
          child: SwitchListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            secondary: const Icon(
              Icons.schedule,
              color: DesignTokens.neonAmber,
              size: 22,
            ),
            title: const Text(
              'Schedule for Later',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            subtitle: _scheduledAt != null
                ? Text(
                    _formatDate(_scheduledAt!),
                    style: const TextStyle(
                      color: DesignTokens.neonAmber,
                      fontSize: 10,
                    ),
                  )
                : null,
            value: _showScheduler,
            activeTrackColor: DesignTokens.neonAmber,
            onChanged: (v) async {
              if (v) {
                await _pickScheduleAt();
              } else {
                setState(() {
                  _showScheduler = false;
                  _scheduledAt = null;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.neonGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: DesignTokens.neonGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: DesignTokens.neonGreen, size: 18),
              SizedBox(width: 8),
              Text(
                'Published!',
                style: TextStyle(
                  color: DesignTokens.neonGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_publishResult != null)
            ...(_publishResult!.entries.where((e) => e.value is Map).map((e) {
              final status =
                  (e.value as Map)['status']?.toString() ?? 'unknown';
              final isOk = status == 'success' || status == 'published';
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      isOk ? Icons.check : Icons.close,
                      color: isOk
                          ? DesignTokens.neonGreen
                          : DesignTokens.neonRed,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      e.key,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      status,
                      style: TextStyle(
                        color: isOk
                            ? DesignTokens.neonGreen
                            : DesignTokens.neonRed,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            })),
        ],
      ),
    );
  }

  // ── Platform helpers ──
  Color _platformColor(SocialPlatform p) {
    switch (p) {
      case SocialPlatform.tiktok:
        return DesignTokens.neonRed;
      case SocialPlatform.instagram:
        return DesignTokens.neonMagenta;
      case SocialPlatform.youtube:
        return DesignTokens.neonRed;
      case SocialPlatform.facebook:
        return DesignTokens.neonCyan;
      case SocialPlatform.xTwitter:
        return Colors.white70;
      case SocialPlatform.linkedin:
        return DesignTokens.neonCyan;
      case SocialPlatform.threads:
        return Colors.white70;
      case SocialPlatform.bluesky:
        return DesignTokens.neonCyan;
      case SocialPlatform.pinterest:
        return DesignTokens.neonRed;
    }
  }

  IconData _platformIcon(SocialPlatform p) {
    switch (p) {
      case SocialPlatform.tiktok:
        return Icons.music_note;
      case SocialPlatform.instagram:
        return Icons.camera_alt;
      case SocialPlatform.youtube:
        return Icons.play_circle;
      case SocialPlatform.facebook:
        return Icons.facebook;
      case SocialPlatform.xTwitter:
        return Icons.tag;
      case SocialPlatform.linkedin:
        return Icons.work;
      case SocialPlatform.threads:
        return Icons.alternate_email;
      case SocialPlatform.bluesky:
        return Icons.cloud;
      case SocialPlatform.pinterest:
        return Icons.push_pin;
    }
  }
}
