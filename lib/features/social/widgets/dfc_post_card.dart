import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/dfc_profile_identity.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/share_service.dart';
import '../../../core/constants/content_policy.dart';
import '../../../shared/models/community/community_models.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/content_safety_service.dart';
import '../../../shared/services/social_service.dart';
import 'link_preview_card.dart';
import 'og_preview_card.dart';
import 'poll_display_widget.dart';
import 'rich_text_content.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC POST CARD — Facebook-quality social card
///
/// • Avatar with gradient ring + role badge
/// • Verified tick
/// • Like count, comment count, share count displayed
/// • Bookmark toggle
/// • Expandable long content
/// • Media grid placeholder
/// • Optimistic like toggle with haptics
/// ═══════════════════════════════════════════════════════════════════════════
class DFCPostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onComment;
  final VoidCallback? onPostDeleted;
  final VoidCallback? onTap;

  const DFCPostCard({
    super.key,
    required this.post,
    this.onComment,
    this.onPostDeleted,
    this.onTap,
  });

  @override
  State<DFCPostCard> createState() => _DFCPostCardState();
}

class _DFCPostCardState extends State<DFCPostCard> {
  late final SocialService _socialService;
  bool _isLiked = false;
  bool _isBookmarked = false;
  bool _isLiking = false;
  int _likeCount = 0;
  bool _expanded = false;
  bool _depsInit = false;
  bool _showReactionPicker = false;

  // Combat reaction counts (local optimistic state)
  late int _respectCount;
  late int _strongCount;
  late int _supportCount;
  late int _warriorCount;
  late int _championCount;
  final Set<String> _myReactions = {};

  static const _reactionDefs = [
    ('respect', '\ud83e\udd4b', 'Respect'),
    ('strong', '\ud83d\udcaa', 'Power'),
    ('support', '\u2764\ufe0f', 'Support'),
    ('warrior', '\ud83d\udd25', 'Fire'),
    ('champion', '\ud83d\udc51', 'Legend'),
  ];

  Post get post => widget.post;

  void _viewMedia(String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: DfcNetworkImage(url: url, fit: BoxFit.contain),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsInit) {
      _depsInit = true;
      _socialService = context.read<SocialService>();
      _likeCount = post.likes;
      _respectCount = post.respectCount;
      _strongCount = post.strongCount;
      _supportCount = post.supportCount;
      _warriorCount = post.warriorCount;
      _championCount = post.championCount;
      _checkStatuses();
    }
  }

  Future<void> _checkStatuses() async {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return;
    final liked = post.likedBy.contains(uid);
    final bookmarked = post.bookmarkedBy.contains(uid);
    // Check which reactions user has already placed
    for (final entry in post.reactions.entries) {
      if (entry.value.contains(uid)) _myReactions.add(entry.key);
    }
    if (mounted) {
      setState(() {
        _isLiked = liked;
        _isBookmarked = bookmarked;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_isLiking) return;
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _isLiking = true;
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    HapticFeedback.lightImpact();

    try {
      await _socialService.toggleLike(post.id, uid);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likeCount += _isLiked ? 1 : -1;
        });
      }
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  Future<void> _toggleBookmark() async {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return;
    setState(() => _isBookmarked = !_isBookmarked);
    HapticFeedback.selectionClick();
    try {
      await _socialService.toggleBookmark(post.id, uid);
    } catch (_) {
      if (mounted) setState(() => _isBookmarked = !_isBookmarked);
    }
  }

  int _reactionCount(String type) {
    switch (type) {
      case 'respect':
        return _respectCount;
      case 'strong':
        return _strongCount;
      case 'support':
        return _supportCount;
      case 'warrior':
        return _warriorCount;
      case 'champion':
        return _championCount;
      default:
        return 0;
    }
  }

  void _setReactionCount(String type, int value) {
    switch (type) {
      case 'respect':
        _respectCount = value;
      case 'strong':
        _strongCount = value;
      case 'support':
        _supportCount = value;
      case 'warrior':
        _warriorCount = value;
      case 'champion':
        _championCount = value;
    }
  }

  Future<void> _toggleReaction(String type) async {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return;
    HapticFeedback.lightImpact();

    final wasActive = _myReactions.contains(type);
    setState(() {
      if (wasActive) {
        _myReactions.remove(type);
        _setReactionCount(type, _reactionCount(type) - 1);
      } else {
        _myReactions.add(type);
        _setReactionCount(type, _reactionCount(type) + 1);
      }
      _showReactionPicker = false;
    });

    try {
      await _socialService.toggleReaction(post.id, uid, type);
    } catch (_) {
      if (mounted) {
        setState(() {
          if (wasActive) {
            _myReactions.add(type);
            _setReactionCount(type, _reactionCount(type) + 1);
          } else {
            _myReactions.remove(type);
            _setReactionCount(type, _reactionCount(type) - 1);
          }
        });
      }
    }
  }

  Future<void> _handleShare() async {
    HapticFeedback.mediumImpact();
    final socialService = _socialService;
    final uid = context.read<AuthService>().currentUser?.uid;
    await ShareService.instance.sharePost(
      postId: post.id,
      authorDisplayName: post.displayName,
      contentPreview: post.content,
    );
    if (!mounted) return;
    // Record share count in Firestore
    if (uid != null) {
      try {
        await socialService.sharePost(post.id, uid);
      } catch (_) {}
    }
  }

  Color get _roleColor {
    switch (post.userRole) {
      case 'fighter':
        return DesignTokens.neonCyan;
      case 'coach':
        return DesignTokens.neonGreen;
      case 'promoter':
        return DesignTokens.neonMagenta;
      case 'gym':
        return DesignTokens.neonAmber;
      case 'media':
        return const Color(0xFF74B9FF);
      case 'admin':
        return DesignTokens.neonGold;
      default:
        return Colors.grey;
    }
  }

  /// Post is "trending" if total engagement exceeds threshold
  bool get _isTrending {
    final total = _likeCount + post.commentCount + post.shareCount;
    return total >= 25;
  }

  void _openUserProfile() {
    if (post.userId.isEmpty) return;
    context.push('/user/${post.userId}');
  }

  @override
  Widget build(BuildContext context) {
    final contentTooLong = post.content.length > 280;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: DesignTokens.borderThin,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _openUserProfile,
                    child: _buildAvatar(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _openUserProfile,
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  post.displayName,
                                  style: const TextStyle(
                                    color: DesignTokens.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (post.isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  size: 14,
                                  color: DesignTokens.neonCyan,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: _roleColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusPill,
                                ),
                              ),
                              child: Text(
                                post.roleBadge,
                                style: TextStyle(
                                  color: _roleColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              post.timeAgo,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 11,
                              ),
                            ),
                            if (post.isEdited) ...[
                              const SizedBox(width: 4),
                              Text(
                                '· edited',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.more_horiz,
                      color: Colors.white.withValues(alpha: 0.35),
                      size: 20,
                    ),
                    onPressed: _showOptions,
                  ),
                ],
              ),
            ),

            // ── Trending badge ──
            if (_isTrending)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B00), Color(0xFFFF3366)],
                    ),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusPill,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 12,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'TRENDING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Content (tappable #hashtags + @mentions) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: RichTextContent(
                text: post.content,
                maxLength: contentTooLong ? 280 : null,
                expanded: _expanded,
                onToggleExpand: () => setState(() => _expanded = !_expanded),
              ),
            ),

            // ── Poll display ──
            if (post.postType == 'poll') PollDisplayWidget(post: post),

            // ── Media (aspect-ratio responsive) ──
            if (post.hasMedia)
              GestureDetector(
                onTap: () => _viewMedia(post.mediaUrls.first),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // 16:9 aspect ratio, clamped between 180-400px
                      final h = (constraints.maxWidth * 9 / 16).clamp(
                        180.0,
                        400.0,
                      );
                      return DfcNetworkImage(
                        url: post.mediaUrls.first,
                        width: double.infinity,
                        height: h,
                      );
                    },
                  ),
                ),
              ),

            // ── Link preview ──
            if (post.hasLinkPreview)
              LinkPreviewCard(
                url: post.linkPreviewUrl,
                title: post.linkPreviewTitle,
                description: post.linkPreviewDescription,
                imageUrl: post.linkPreviewImage,
                domain: post.linkPreviewDomain,
              )
            else if (post.hasOgPreview)
              OgPreviewCard(ogData: post.ogPreview!),

            // ── Location tag ──
            if (post.location != null && post.location!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      post.location!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Engagement counts ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  if (_likeCount > 0) ...[
                    const Icon(
                      Icons.favorite,
                      size: 14,
                      color: DesignTokens.neonMagenta,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatCount(_likeCount),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (post.commentCount > 0)
                    Text(
                      '${_formatCount(post.commentCount)} comments',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11,
                      ),
                    ),
                  if (post.shareCount > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${_formatCount(post.shareCount)} shares',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Combat Reaction summary ──
            _buildReactionSummary(),

            // ── Divider ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),

            // ── Action bar ──
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Reaction picker (appears above Like button on long-press)
                if (_showReactionPicker)
                  Positioned(
                    left: 4,
                    bottom: 48,
                    child: _buildReactionPicker(),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onLongPress: () =>
                            setState(() => _showReactionPicker = true),
                        child: _ActionButton(
                          icon: _isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          label: 'Like',
                          color: _isLiked
                              ? DesignTokens.neonMagenta
                              : Colors.white.withValues(alpha: 0.45),
                          onTap: _toggleLike,
                        ),
                      ),
                      _ActionButton(
                        icon: Icons.chat_bubble_outline,
                        label: 'Comment',
                        color: Colors.white.withValues(alpha: 0.45),
                        onTap: widget.onComment ?? () {},
                      ),
                      _ActionButton(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        color: Colors.white.withValues(alpha: 0.45),
                        onTap: _handleShare,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: _isBookmarked
                              ? DesignTokens.neonAmber
                              : Colors.white.withValues(alpha: 0.35),
                          size: 20,
                        ),
                        onPressed: _toggleBookmark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ), // End Container (child of GestureDetector)
    ); // End GestureDetector
  } // End build

  Widget _buildAvatar() {
    // Use post.id to ensure unique hero tag per post (not per user)
    return Hero(
      tag: 'post_avatar_${post.id}',
      child: DfcProfileIdentityAvatar(
        imageUrl: post.userAvatarUrl,
        displayName: post.displayName,
        radius: 19,
        accentColor: _roleColor,
        ringPadding: 2,
        gradientColors: [_roleColor, _roleColor.withValues(alpha: 0.4)],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  void _showOptions() {
    final uid = context.read<AuthService>().currentUser?.uid;
    final isOwner = uid == post.userId;

    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (isOwner) ...[
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: DesignTokens.neonCyan,
                ),
                title: const Text(
                  'Edit Post',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditDialog();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: DesignTokens.neonRed,
                ),
                title: const Text(
                  'Delete Post',
                  style: TextStyle(color: DesignTokens.neonRed),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete();
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.orange),
                title: const Text(
                  'Report Post',
                  style: TextStyle(color: Colors.orange),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showReportDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text(
                  'Block User',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showBlockDialog();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.volume_off,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                title: Text(
                  'Mute User',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showMuteDialog();
                },
              ),
            ],
            ListTile(
              leading: Icon(
                Icons.link,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              title: Text(
                'Copy Link',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(
                  ClipboardData(
                    text: 'https://datafightcentral.com/post/${post.id}',
                  ),
                );
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Link copied')));
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEditDialog() {
    final controller = TextEditingController(text: post.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgCard,
        title: const Text('Edit Post', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: 'Edit your post...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await _socialService.editPost(post.id, controller.text.trim());
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Post updated')));
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: DesignTokens.neonCyan),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgCard,
        title: const Text('Delete Post', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _socialService.deletePost(post.id);
              widget.onPostDeleted?.call();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: DesignTokens.neonRed),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return;
    String? selected;
    final reasons = ContentPolicy.reportReasons;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: DesignTokens.bgCard,
          title: const Text(
            'Report Post',
            style: TextStyle(color: Colors.white),
          ),
          content: RadioGroup<String>(
            groupValue: selected,
            onChanged: (v) => ss(() => selected = v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: reasons
                  .map(
                    (r) => RadioListTile<String>(
                      title: Text(
                        r,
                        style: const TextStyle(color: Colors.white),
                      ),
                      value: r,
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (selected == null) return;
                Navigator.pop(ctx);
                final safety = context.read<ContentSafetyService>();
                await safety.reportPost(
                  post.id,
                  uid,
                  selected!,
                  targetUserId: post.userId,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted')),
                  );
                }
              },
              child: const Text(
                'Submit',
                style: TextStyle(color: DesignTokens.neonCyan),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog() {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgCard,
        title: const Text('Block User', style: TextStyle(color: Colors.white)),
        content: Text(
          'Block ${post.displayName}?\nThey won\'t see your content.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final safety = context.read<ContentSafetyService>();
              await safety.blockUser(
                currentUserId: uid,
                targetUserId: post.userId,
              );
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('User blocked')));
              }
            },
            child: const Text(
              'Block',
              style: TextStyle(color: DesignTokens.neonRed),
            ),
          ),
        ],
      ),
    );
  }

  void _showMuteDialog() {
    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgCard,
        title: const Text('Mute User', style: TextStyle(color: Colors.white)),
        content: Text(
          'Mute ${post.displayName}?\nYou won\'t see their posts in your feed.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final safety = context.read<ContentSafetyService>();
              await safety.muteUser(
                currentUserId: uid,
                targetUserId: post.userId,
              );
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('User muted')));
              }
            },
            child: const Text(
              'Mute',
              style: TextStyle(color: DesignTokens.neonAmber),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reaction summary row (shows emoji badges with counts) ──
  Widget _buildReactionSummary() {
    final active = _reactionDefs
        .where((r) => _reactionCount(r.$1) > 0)
        .toList();
    if (active.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: active.map((r) {
          final isMine = _myReactions.contains(r.$1);
          return GestureDetector(
            onTap: () => _toggleReaction(r.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isMine
                    ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: isMine
                    ? Border.all(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.4),
                      )
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(r.$2, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 3),
                  Text(
                    _formatCount(_reactionCount(r.$1)),
                    style: TextStyle(
                      color: isMine
                          ? DesignTokens.neonCyan
                          : Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Floating reaction picker (long-press on Like) ──
  Widget _buildReactionPicker() {
    return TapRegion(
      onTapOutside: (_) => setState(() => _showReactionPicker = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: DesignTokens.neonCyan.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _reactionDefs.map((r) {
            final isMine = _myReactions.contains(r.$1);
            return GestureDetector(
              onTap: () => _toggleReaction(r.$1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(r.$2, style: TextStyle(fontSize: isMine ? 28 : 24)),
                    Text(
                      r.$3,
                      style: TextStyle(
                        color: isMine
                            ? DesignTokens.neonCyan
                            : Colors.white.withValues(alpha: 0.5),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// ─── Action button for the engagement bar ─────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
