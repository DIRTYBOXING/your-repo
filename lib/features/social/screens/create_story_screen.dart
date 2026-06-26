import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/media_asset_model.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/media_upload_service.dart';
import '../../../shared/services/social_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CREATE STORY SCREEN — Full-screen story creator
///
/// Instagram/Facebook grade story creation:
/// • Camera / Gallery picker for photos & videos
/// • Text overlay with style presets
/// • Story type selector (Fight Moment / Training / Behind Scenes / Promo)
/// • Live preview with media background
/// • Upload progress with animated bar
/// • Posts to social feed as a story-type post
/// ═══════════════════════════════════════════════════════════════════════════

const _kBg = Color(0xFF050A14);
const _kCard = Color(0xFF0D1B2A);
const _kCyan = Color(0xFF00F5FF);
const _kMagenta = Color(0xFFFF00FF);
const _kRed = Color(0xFFFF3366);
const _kGold = Color(0xFFFFD700);
const _kGreen = Color(0xFF00FF88);

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  late AnimationController _animCtrl;

  XFile? _selectedMedia;
  Uint8List? _mediaBytes;
  bool _isVideo = false;
  bool _posting = false;
  double _uploadProgress = 0;
  String _selectedType = 'moment';
  bool _showTextInput = false;
  int _textStyleIndex = 0;

  static const _storyTypes = <String, _StoryTypeData>{
    'moment': _StoryTypeData('Fight Moment', Icons.sports_mma_rounded, _kRed),
    'training': _StoryTypeData(
      'Training',
      Icons.fitness_center_rounded,
      _kCyan,
    ),
    'behind': _StoryTypeData(
      'Behind Scenes',
      Icons.videocam_rounded,
      _kMagenta,
    ),
    'promo': _StoryTypeData('Promo', Icons.campaign_rounded, _kGold),
    'weigh_in': _StoryTypeData(
      'Weigh-In',
      Icons.monitor_weight_rounded,
      _kGreen,
    ),
  };

  static const _textStyles = <_TextStylePreset>[
    _TextStylePreset('Bold White', Colors.white, 28, FontWeight.w900, null),
    _TextStylePreset('Neon Cyan', _kCyan, 24, FontWeight.w700, null),
    _TextStylePreset('Fire', _kRed, 26, FontWeight.w800, null),
    _TextStylePreset('Gold', _kGold, 24, FontWeight.w700, null),
    _TextStylePreset('Tag', Colors.white, 18, FontWeight.w600, Colors.black54),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  // MEDIA PICKERS
  // ══════════════════════════════════════════════════════════════

  Future<void> _pickPhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _selectedMedia = file;
          _mediaBytes = bytes;
          _isVideo = false;
        });
      }
    }
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _selectedMedia = file;
          _mediaBytes = bytes;
          _isVideo = true;
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _selectedMedia = file;
          _mediaBytes = bytes;
          _isVideo = false;
        });
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  // PUBLISH STORY
  // ══════════════════════════════════════════════════════════════

  Future<void> _publishStory() async {
    if (_selectedMedia == null && _textController.text.trim().isEmpty) return;
    setState(() {
      _posting = true;
      _uploadProgress = 0;
    });
    HapticFeedback.heavyImpact();

    final auth = context.read<AuthService>();
    final social = context.read<SocialService>();
    final user = auth.currentUser;
    final userModel = auth.userModel;
    final userId =
        user?.uid ?? (auth.isDemoUser ? AuthService.demoUserId : null);

    if (userId == null) {
      if (mounted) {
        setState(() => _posting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in to share your story'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final mediaUrls = <String>[];
      final mediaAssetIds = <String>[];
      final postId = FirebaseFirestore.instance.collection('posts').doc().id;

      // Upload media to canonical asset pipeline
      if (_selectedMedia != null && !auth.isDemoUser) {
        setState(() => _uploadProgress = 0.1);
        final bytes = await _selectedMedia!.readAsBytes();
        final uploader = MediaUploadService();
        final rightsOwner =
            userModel?.displayName ?? user?.displayName ?? userId;
        final result = _isVideo
            ? await uploader.ingestVideoBytesAsset(
                videoBytes: bytes,
                uploaderId: userId,
                uploaderRole: userModel?.role.name,
                entityType: 'story',
                entityId: postId,
                kind: MediaAssetKind.story,
                rightsOwner: rightsOwner,
                rightsType: MediaRightsType.permissioned,
                rightsDeclaration:
                    'User-uploaded story content under DFC upload terms.',
                originalFileName: _selectedMedia!.name,
                onProgress: (progress) {
                  if (mounted) {
                    setState(() {
                      _uploadProgress = 0.1 + (progress * 0.8);
                    });
                  }
                },
              )
            : await uploader.ingestImageAsset(
                imageBytes: bytes,
                uploaderId: userId,
                uploaderRole: userModel?.role.name,
                entityType: 'story',
                entityId: postId,
                kind: MediaAssetKind.story,
                rightsOwner: rightsOwner,
                rightsType: MediaRightsType.permissioned,
                rightsDeclaration:
                    'User-uploaded story content under DFC upload terms.',
                originalFileName: _selectedMedia!.name,
                onProgress: (progress) {
                  if (mounted) {
                    setState(() {
                      _uploadProgress = 0.1 + (progress * 0.8);
                    });
                  }
                },
              );
        if (!result.success || result.asset == null) {
          throw Exception(result.error ?? 'Story media upload failed');
        }
        mediaUrls.add(result.asset!.downloadUrl);
        mediaAssetIds.add(result.asset!.id);
        if (mounted) setState(() => _uploadProgress = 0.95);
      } else if (_selectedMedia != null && auth.isDemoUser) {
        // Demo mode: use a placeholder
        mediaUrls.add('demo://story/${DateTime.now().millisecondsSinceEpoch}');
        setState(() => _uploadProgress = 0.9);
      }

      // Build story content text
      final storyCaption = _textController.text.trim();
      final typeLabel = _storyTypes[_selectedType]?.label ?? 'Moment';
      final content = storyCaption.isNotEmpty
          ? '📸 $typeLabel: $storyCaption'
          : '📸 $typeLabel';

      await social.createPost(
        postId: postId,
        authorId: userId,
        content: content,
        displayName: userModel?.displayName ?? user?.displayName ?? 'Fighter',
        avatarUrl: userModel?.photoUrl ?? user?.photoURL,
        mediaUrls: mediaUrls,
        mediaAssetIds: mediaAssetIds,
        postType: 'media',
      );

      if (mounted) {
        setState(() => _uploadProgress = 1.0);
        HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Story shared!'),
                ],
              ),
              backgroundColor: _kGreen.withValues(alpha: 0.9),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _posting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final hasMedia = _selectedMedia != null;
    final typeData = _storyTypes[_selectedType]!;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background: media preview or picker ──
          if (hasMedia && _mediaBytes != null && !_isVideo)
            Image.memory(
              _mediaBytes!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            )
          else if (hasMedia && _isVideo)
            // Video placeholder with icon
            Container(
              color: _kCard,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_rounded,
                    size: 64,
                    color: _kMagenta.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Video ready',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedMedia!.name,
                    style: TextStyle(
                      color: _kMagenta.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
          else
            _buildMediaPicker(),

          // ── Dark gradient overlay for readability ──
          if (hasMedia)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.25, 0.6, 1.0],
                ),
              ),
            ),

          // ── Text overlay on media ──
          if (hasMedia && _showTextInput)
            Positioned(
              left: 24,
              right: 24,
              bottom: 200,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      _textStyles[_textStyleIndex].bgColor ??
                      Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _textController,
                  autofocus: true,
                  maxLines: 3,
                  maxLength: 200,
                  style: TextStyle(
                    color: _textStyles[_textStyleIndex].color,
                    fontSize: _textStyles[_textStyleIndex].size,
                    fontWeight: _textStyles[_textStyleIndex].weight,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Add text to your story...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 18,
                    ),
                    counterStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),

          // ── Caption input (no media or bottom of screen) ──
          if (!hasMedia)
            Positioned(
              left: 20,
              right: 20,
              bottom: 160,
              child: TextField(
                controller: _textController,
                maxLines: 4,
                maxLength: 300,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: 'What\'s your fight story?',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 18,
                  ),
                  border: InputBorder.none,
                  counterStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 10,
                  ),
                ),
              ),
            ),

          // ── Top bar: close + story type + text toggle ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    // Close
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    // Text toggle (only when media selected)
                    if (hasMedia)
                      IconButton(
                        icon: Icon(
                          _showTextInput
                              ? Icons.text_fields
                              : Icons.text_fields_outlined,
                          color: _showTextInput ? _kCyan : Colors.white,
                          size: 26,
                        ),
                        onPressed: () =>
                            setState(() => _showTextInput = !_showTextInput),
                      ),
                    // Text style cycle
                    if (hasMedia && _showTextInput)
                      IconButton(
                        icon: const Icon(
                          Icons.format_color_text,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() {
                            _textStyleIndex =
                                (_textStyleIndex + 1) % _textStyles.length;
                          });
                        },
                      ),
                    // Remove media
                    if (hasMedia)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.white54,
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedMedia = null;
                            _mediaBytes = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom controls ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      _kBg.withValues(alpha: 0.9),
                      _kBg,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Story Type selector chips
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _storyTypes.entries.map((e) {
                          final active = _selectedType == e.key;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedType = e.key),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? e.value.color.withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: active
                                        ? e.value.color.withValues(alpha: 0.6)
                                        : Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      e.value.icon,
                                      size: 14,
                                      color: active
                                          ? e.value.color
                                          : Colors.white.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      e.value.label,
                                      style: TextStyle(
                                        color: active
                                            ? e.value.color
                                            : Colors.white.withValues(
                                                alpha: 0.5,
                                              ),
                                        fontSize: 11,
                                        fontWeight: active
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Upload progress bar
                    if (_posting)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _uploadProgress,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.1,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  typeData.color,
                                ),
                                minHeight: 4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _uploadProgress < 0.9
                                  ? 'Uploading ${(_uploadProgress * 100).toInt()}%...'
                                  : 'Publishing...',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Action row: media buttons + share
                    Row(
                      children: [
                        // Camera
                        _buildMediaButton(
                          Icons.camera_alt_rounded,
                          'Camera',
                          _kCyan,
                          _posting ? null : _takePhoto,
                        ),
                        const SizedBox(width: 8),
                        // Photo gallery
                        _buildMediaButton(
                          Icons.photo_library_rounded,
                          'Photo',
                          _kGreen,
                          _posting ? null : _pickPhoto,
                        ),
                        const SizedBox(width: 8),
                        // Video
                        _buildMediaButton(
                          Icons.videocam_rounded,
                          'Video',
                          _kMagenta,
                          _posting ? null : _pickVideo,
                        ),
                        const Spacer(),
                        // SHARE button
                        _buildShareButton(typeData),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // MEDIA PICKER (empty state)
  // ══════════════════════════════════════════════════════════════

  Widget _buildMediaPicker() {
    return Container(
      decoration: const BoxDecoration(
        color: _kCard,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kCard, _kBg],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Big icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _kCyan.withValues(alpha: 0.2),
                  _kMagenta.withValues(alpha: 0.2),
                ],
              ),
              border: Border.all(
                color: _kCyan.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.add_a_photo_rounded,
              size: 40,
              color: _kCyan,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'CREATE YOUR STORY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share a fight moment, training clip, or behind-the-scenes',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          // Quick action large buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBigPickerButton(
                Icons.camera_alt_rounded,
                'Camera',
                _kCyan,
                _takePhoto,
              ),
              const SizedBox(width: 16),
              _buildBigPickerButton(
                Icons.photo_library_rounded,
                'Gallery',
                _kGreen,
                _pickPhoto,
              ),
              const SizedBox(width: 16),
              _buildBigPickerButton(
                Icons.videocam_rounded,
                'Video',
                _kMagenta,
                _pickVideo,
              ),
            ],
          ),
          const SizedBox(height: 80), // space for bottom controls
        ],
      ),
    );
  }

  Widget _buildBigPickerButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton(_StoryTypeData typeData) {
    final canShare =
        !_posting &&
        (_selectedMedia != null || _textController.text.trim().isNotEmpty);

    return GestureDetector(
      onTap: canShare ? _publishStory : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: canShare
              ? LinearGradient(
                  colors: [
                    typeData.color,
                    typeData.color.withValues(alpha: 0.7),
                  ],
                )
              : null,
          color: canShare ? null : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
          boxShadow: canShare
              ? [
                  BoxShadow(
                    color: typeData.color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _posting ? Icons.hourglass_top : Icons.send_rounded,
              size: 18,
              color: canShare
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 6),
            Text(
              _posting ? 'Sharing...' : 'Share Story',
              style: TextStyle(
                color: canShare
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper data classes ──

class _StoryTypeData {
  final String label;
  final IconData icon;
  final Color color;
  const _StoryTypeData(this.label, this.icon, this.color);
}

class _TextStylePreset {
  final String name;
  final Color color;
  final double size;
  final FontWeight weight;
  final Color? bgColor;
  const _TextStylePreset(
    this.name,
    this.color,
    this.size,
    this.weight,
    this.bgColor,
  );
}
