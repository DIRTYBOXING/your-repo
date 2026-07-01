import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/media_asset_model.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/link_preview_service.dart';
import '../../../shared/services/media_upload_service.dart';
import '../../../shared/services/social_service.dart';
import '../../../shared/widgets/dfc_profile_identity.dart';
import '../widgets/link_preview_card.dart';
import '../widgets/mention_autocomplete_overlay.dart';
import 'create_poll_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// COMPOSE POST SCREEN — Full-screen create post
///
/// • Text input with character counter
/// • Post type selector (General, Training, Fight, News)
/// • Location stub
/// • Posts via SocialService.createPost()
/// ═══════════════════════════════════════════════════════════════════════════
class ComposePostScreen extends StatefulWidget {
  const ComposePostScreen({super.key});

  @override
  State<ComposePostScreen> createState() => _ComposePostScreenState();
}

class _ComposePostScreenState extends State<ComposePostScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  String _selectedType = 'general';
  bool _posting = false;
  double _uploadProgress = 0.0;
  final List<XFile> _attachedMedia = [];
  String? _attachedLocation;
  final List<String> _tags = [];
  final _picker = ImagePicker();

  // Link preview state
  String? _detectedUrl;
  LinkPreviewData? _linkPreviewData;
  bool _linkPreviewDismissed = false;

  static const _maxChars = 2000;
  static const _postTypes = <String, IconData>{
    'general': Icons.public,
    'training': Icons.fitness_center,
    'fight': Icons.sports_mma,
    'news': Icons.newspaper,
    'poll': Icons.poll,
  };

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    // Auto-focus the text field after the frame so keyboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onTextChanged() {
    final url = LinkPreviewService.instance.extractFirstUrl(
      _textController.text,
    );
    if (url != _detectedUrl) {
      setState(() {
        _detectedUrl = url;
        _linkPreviewData = null;
        _linkPreviewDismissed = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _canPost => _textController.text.trim().isNotEmpty && !_posting;

  Future<void> _submitPost() async {
    if (!_canPost) return;
    setState(() => _posting = true);
    HapticFeedback.mediumImpact();

    final auth = context.read<AuthService>();
    final social = context.read<SocialService>();
    final user = auth.currentUser;
    final userModel = auth.userModel;

    // In demo mode use a fallback ID; in real mode require auth
    final userId =
        user?.uid ?? (auth.isDemoUser ? AuthService.demoUserId : null);
    if (userId == null) {
      if (mounted) {
        setState(() => _posting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to create a post'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Upload media via MediaUploadService with progress
      final mediaUrls = <String>[];
      final mediaAssetIds = <String>[];
      final postId = FirebaseFirestore.instance.collection('posts').doc().id;
      if (!auth.isDemoUser && _attachedMedia.isNotEmpty) {
        final uploader = MediaUploadService();
        final totalFiles = _attachedMedia.length;
        final rightsOwner =
            userModel?.displayName ?? user?.displayName ?? userId;
        for (var i = 0; i < totalFiles; i++) {
          final file = _attachedMedia[i];
          try {
            final bytes = await file.readAsBytes();
            final ext = file.name.split('.').last.toLowerCase();
            final isVideo = ['mp4', 'mov', 'avi'].contains(ext);

            if (isVideo) {
              final result = await uploader.ingestVideoBytesAsset(
                videoBytes: bytes,
                uploaderId: userId,
                uploaderRole: userModel?.role.name,
                entityType: 'post',
                entityId: postId,
                kind: MediaAssetKind.postMedia,
                rightsOwner: rightsOwner,
                rightsType: MediaRightsType.permissioned,
                rightsDeclaration:
                    'User-uploaded social media content under DFC upload terms.',
                originalFileName: file.name,
                onProgress: (progress) {
                  if (mounted) {
                    setState(() {
                      _uploadProgress = (i + progress) / totalFiles;
                    });
                  }
                },
              );
              if (result.success && result.asset != null) {
                mediaUrls.add(result.asset!.downloadUrl);
                mediaAssetIds.add(result.asset!.id);
              } else {
                debugPrint('⚠️ Video ingestion failed: ${result.error}');
              }
            } else {
              final result = await uploader.ingestImageAsset(
                imageBytes: bytes,
                uploaderId: userId,
                uploaderRole: userModel?.role.name,
                entityType: 'post',
                entityId: postId,
                kind: MediaAssetKind.postMedia,
                rightsOwner: rightsOwner,
                rightsType: MediaRightsType.permissioned,
                rightsDeclaration:
                    'User-uploaded social media content under DFC upload terms.',
                originalFileName: file.name,
                onProgress: (progress) {
                  if (mounted) {
                    setState(() {
                      _uploadProgress = (i + progress) / totalFiles;
                    });
                  }
                },
              );
              if (result.success && result.asset != null) {
                mediaUrls.add(result.asset!.downloadUrl);
                mediaAssetIds.add(result.asset!.id);
              } else {
                debugPrint('⚠️ Image ingestion failed: ${result.error}');
              }
            }
          } catch (e) {
            debugPrint('⚠️ Media upload failed: $e');
          }
        }
      }

      await social.createPost(
        postId: postId,
        authorId: userId,
        content: _textController.text.trim(),
        displayName: userModel?.displayName ?? user?.displayName ?? 'Fighter',
        avatarUrl: userModel?.photoUrl ?? user?.photoURL,
        mediaUrls: mediaUrls,
        mediaAssetIds: mediaAssetIds,
        postType: mediaUrls.isNotEmpty ? 'media' : _selectedType,
        location: _attachedLocation,
        linkPreviewUrl: _linkPreviewData?.url,
        linkPreviewTitle: _linkPreviewData?.title,
        linkPreviewDescription: _linkPreviewData?.description,
        linkPreviewImage: _linkPreviewData?.imageUrl,
        linkPreviewDomain: _linkPreviewData?.domain,
      );
      if (mounted) Navigator.of(context).pop(true); // true = posted
    } catch (e) {
      if (mounted) {
        setState(() => _posting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickPhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file != null && mounted) {
      setState(() => _attachedMedia.add(file));
    }
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    if (file != null && mounted) {
      setState(() => _attachedMedia.add(file));
    }
  }

  Future<void> _takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (file != null && mounted) {
      setState(() => _attachedMedia.add(file));
    }
  }

  Future<void> _pickMultipleImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 80);
    if (files.isNotEmpty && mounted) {
      setState(() => _attachedMedia.addAll(files));
    }
  }

  void _attachLocation() {
    final auth = context.read<AuthService>();
    final userLoc = auth.userModel?.metadata?['location'] as String?;
    final city = auth.userModel?.metadata?['city'] as String? ?? '';
    final country = auth.userModel?.metadata?['country'] as String? ?? '';
    final location = userLoc ?? (city.isNotEmpty ? '$city, $country' : null);

    if (location != null && location.isNotEmpty) {
      setState(
        () => _attachedLocation = _attachedLocation == null ? location : null,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add your location in Profile to tag posts'),
        ),
      );
    }
  }

  void _showTagDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgCard,
        title: const Text(
          'Tag People',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter name or @username',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 13,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: DesignTokens.neonCyan.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: DesignTokens.neonCyan),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          TextButton(
            onPressed: () {
              final tag = controller.text.trim();
              if (tag.isNotEmpty && !_tags.contains(tag)) {
                setState(() => _tags.add(tag));
              }
              Navigator.pop(ctx);
            },
            child: const Text(
              'Add',
              style: TextStyle(
                color: DesignTokens.neonCyan,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final charCount = _textController.text.length;
    final charRemaining = _maxChars - charCount;

    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close',
        ),
        title: const Text(
          'Create Post',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AnimatedOpacity(
              opacity: _canPost ? 1.0 : 0.35,
              duration: const Duration(milliseconds: 200),
              child: TextButton(
                onPressed: _canPost ? _submitPost : null,
                style: TextButton.styleFrom(
                  backgroundColor: _canPost
                      ? DesignTokens.neonCyan
                      : Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                ),
                child: _posting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Post',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── User header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Builder(
              builder: (ctx) {
                final auth = ctx.read<AuthService>();
                return DfcProfileIdentityRow(
                  displayName: auth.currentUser?.displayName ?? 'Anonymous',
                  imageUrl: auth.userModel?.photoUrl,
                  subtitle: 'Posting to Feed',
                  avatarRadius: 22,
                  ringPadding: 1.5,
                );
              },
            ),
          ),

          // ── Text area with @mention autocomplete ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: MentionAutocompleteOverlay(
                textController: _textController,
                focusNode: _focusNode,
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: null,
                  maxLength: _maxChars,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  buildCounter:
                      (
                        _, {
                        required currentLength,
                        required isFocused,
                        required maxLength,
                      }) => null,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText:
                        'What\'s happening in the fight world? Type @ to mention',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Link preview (auto-detected) ──
          if (_detectedUrl != null && !_linkPreviewDismissed)
            LinkPreviewCard(
              url: _detectedUrl,
              fetchOnMount: true,
              onFetched: (data) => setState(() => _linkPreviewData = data),
              onDismiss: () => setState(() => _linkPreviewDismissed = true),
            ),

          // ── Bottom toolbar ──
          Container(
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Post type pills
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _postTypes.entries.map((e) {
                        final active = _selectedType == e.key;
                        final color = _typeColor(e.key);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            selected: active,
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  e.value,
                                  size: 14,
                                  color: active
                                      ? Colors.black
                                      : color.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  e.key[0].toUpperCase() + e.key.substring(1),
                                  style: TextStyle(
                                    color: active
                                        ? Colors.black
                                        : Colors.white.withValues(alpha: 0.6),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            selectedColor: color,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.06,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            side: BorderSide(
                              color: active
                                  ? Colors.transparent
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                            onSelected: (_) {
                              if (e.key == 'poll') {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const CreatePollScreen(),
                                  ),
                                );
                                return;
                              }
                              setState(() => _selectedType = e.key);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Attached media preview — REAL THUMBNAILS like Instagram
                  if (_attachedMedia.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        height: 88,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _attachedMedia.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final file = _attachedMedia[i];
                            final isVideo =
                                file.name.endsWith('.mp4') ||
                                file.name.endsWith('.mov') ||
                                file.name.endsWith('.avi');
                            final accentColor = isVideo
                                ? DesignTokens.neonMagenta
                                : DesignTokens.neonCyan;
                            return Stack(
                              children: [
                                // Thumbnail container
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: accentColor.withValues(alpha: 0.4),
                                      width: 1.5,
                                    ),
                                    color: DesignTokens.bgSecondary,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: isVideo
                                      // Video: show icon overlay
                                      ? Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.videocam_rounded,
                                                size: 28,
                                                color: accentColor,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'VIDEO',
                                                style: TextStyle(
                                                  color: accentColor,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      // Image: actual thumbnail via FutureBuilder
                                      : FutureBuilder<dynamic>(
                                          future: file.readAsBytes(),
                                          builder: (ctx, snap) {
                                            if (snap.hasData) {
                                              return Image.memory(
                                                snap.data!,
                                                fit: BoxFit.cover,
                                                width: 80,
                                                height: 80,
                                                errorBuilder: (_, _, _) =>
                                                    _placeholderThumb(
                                                      accentColor,
                                                    ),
                                              );
                                            }
                                            return _placeholderThumb(
                                              accentColor,
                                            );
                                          },
                                        ),
                                ),
                                // Delete button (top-right)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _attachedMedia.removeAt(i),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.7,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),
                                // Index badge (bottom-left)
                                Positioned(
                                  bottom: 2,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${i + 1}/${_attachedMedia.length}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  // Location + Tags chips
                  if (_attachedLocation != null || _tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (_attachedLocation != null)
                            _chipWidget(
                              Icons.location_on,
                              _attachedLocation!,
                              DesignTokens.neonGreen,
                              onRemove: () =>
                                  setState(() => _attachedLocation = null),
                            ),
                          ..._tags.map(
                            (t) => _chipWidget(
                              Icons.person,
                              '@$t',
                              DesignTokens.neonCyan,
                              onRemove: () => setState(() => _tags.remove(t)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Upload progress indicator
                  if (_posting && _attachedMedia.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: DesignTokens.neonCyan,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Uploading ${(_uploadProgress * 100).round()}%',
                                style: const TextStyle(
                                  color: DesignTokens.neonCyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: _uploadProgress,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.08,
                              ),
                              color: DesignTokens.neonCyan,
                              minHeight: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Attachment row + char counter
                  Row(
                    children: [
                      _ToolbarIcon(
                        Icons.camera_alt_outlined,
                        'Camera',
                        _takePhoto,
                      ),
                      _ToolbarIcon(Icons.image_outlined, 'Photo', _pickPhoto),
                      _ToolbarIcon(
                        Icons.photo_library_outlined,
                        'Multi',
                        _pickMultipleImages,
                      ),
                      _ToolbarIcon(
                        Icons.videocam_outlined,
                        'Video',
                        _pickVideo,
                      ),
                      _ToolbarIcon(
                        Icons.location_on_outlined,
                        'Location',
                        _attachLocation,
                      ),
                      _ToolbarIcon(Icons.tag, 'Tag', _showTagDialog),
                      const Spacer(),
                      Text(
                        '$charRemaining',
                        style: TextStyle(
                          color: charRemaining < 100
                              ? (charRemaining < 0
                                    ? DesignTokens.neonRed
                                    : Colors.orange)
                              : Colors.white.withValues(alpha: 0.3),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _placeholderThumb(Color color) {
    return Container(
      color: color.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.image_rounded,
          size: 24,
          color: color.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'training':
        return DesignTokens.neonCyan;
      case 'fight':
        return DesignTokens.neonMagenta;
      case 'news':
        return DesignTokens.neonGreen;
      default:
        return DesignTokens.neonCyan;
    }
  }

  Widget _chipWidget(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close,
                size: 11,
                color: color.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolbarIcon(this.icon, this.tooltip, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 22),
        onPressed: onTap,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }
}
