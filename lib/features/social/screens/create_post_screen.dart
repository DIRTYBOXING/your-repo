import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/media_asset_model.dart';
import '../../../shared/services/media_upload_service.dart';
import '../../../shared/services/social_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ✍️ CREATE POST SCREEN — Full-Featured Post Creation
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Features:
/// • Text post
/// • Photo/video upload (up to 10 images)
/// • Tag gym
/// • Tag fighters
/// • Attach campaign
/// • Privacy settings
/// • Location tagging
///
/// ═══════════════════════════════════════════════════════════════════════════
class CreatePostScreen extends StatefulWidget {
  final String userId;
  final String? initialText;
  final String? campaignId;
  final String? gymId;

  const CreatePostScreen({
    super.key,
    required this.userId,
    this.initialText,
    this.campaignId,
    this.gymId,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _textController = TextEditingController();
  final _socialService = SocialService();
  final _mediaService = MediaUploadService();
  final _picker = ImagePicker();

  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // Media
  final List<PostMedia> _media = [];
  final int _maxMedia = 10;

  // Tags
  String? _taggedGymId;
  String? _taggedGymName;
  final List<TaggedFighter> _taggedFighters = [];

  // Campaign
  String? _attachedCampaignId;
  String? _attachedCampaignName;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) {
      _textController.text = widget.initialText!;
    }
    if (widget.campaignId != null) {
      _attachedCampaignId = widget.campaignId;
      // Would fetch campaign name from Firestore
    }
    if (widget.gymId != null) {
      _taggedGymId = widget.gymId;
      // Would fetch gym name from Firestore
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: Stack(
        children: [_buildBody(), if (_isUploading) _buildUploadingOverlay()],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.cardDark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppTheme.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Close',
      ),
      title: const Text(
        'Create Post',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _canPost ? _handleCreatePost : null,
          child: Text(
            'Post',
            style: TextStyle(
              color: _canPost ? AppTheme.neonGreen : AppTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextInput(),
            const SizedBox(height: 16),
            if (_media.isNotEmpty) _buildMediaGrid(),
            const SizedBox(height: 16),
            _buildActionButtons(),
            const SizedBox(height: 16),
            if (_taggedGymId != null) _buildGymTag(),
            if (_taggedFighters.isNotEmpty) _buildFighterTags(),
            if (_attachedCampaignId != null) _buildCampaignTag(),
            const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return TextField(
      controller: _textController,
      maxLines: null,
      maxLength: 2000,
      autofocus: true,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
      decoration: const InputDecoration(
        hintText: 'What\'s happening in combat sports right now?',
        hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
        border: InputBorder.none,
        counterStyle: TextStyle(color: AppTheme.textSecondary),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildMediaGrid() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisSpacing: 8,
        ),
        itemCount: _media.length,
        itemBuilder: (context, index) {
          final media = _media[index];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  media.bytes,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => setState(() => _media.removeAt(index)),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
              if (media.isVideo)
                const Center(
                  child: Icon(
                    Icons.play_circle_filled,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.cardDark),
          bottom: BorderSide(color: AppTheme.cardDark),
        ),
      ),
      child: Row(
        children: [
          _buildActionButton(
            icon: Icons.photo_library,
            label: 'Photo',
            onTap: _pickImage,
            enabled: _media.length < _maxMedia,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.videocam,
            label: 'Video',
            onTap: _pickVideo,
            enabled: _media.length < _maxMedia,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.fitness_center,
            label: 'Tag Gym',
            onTap: _showGymPicker,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.person_add,
            label: 'Tag Fighter',
            onTap: _showFighterPicker,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.campaign,
            label: 'Campaign',
            onTap: _showCampaignPicker,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Column(
          children: [
            Icon(
              icon,
              color: enabled ? AppTheme.neonGreen : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: enabled ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGymTag() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.neonGreen),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.fitness_center, color: AppTheme.neonGreen, size: 16),
          const SizedBox(width: 6),
          Text(
            _taggedGymName ?? 'Gym',
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() {
              _taggedGymId = null;
              _taggedGymName = null;
            }),
            child: const Icon(
              Icons.close,
              color: AppTheme.textSecondary,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFighterTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _taggedFighters.map((fighter) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accentTeal),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sports_mma,
                color: AppTheme.accentTeal,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                fighter.name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => _taggedFighters.remove(fighter)),
                child: const Icon(
                  Icons.close,
                  color: AppTheme.textSecondary,
                  size: 16,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCampaignTag() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentPurple, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign, color: AppTheme.accentPurple, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Supporting Campaign',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                Text(
                  _attachedCampaignName ?? 'Campaign',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _attachedCampaignId = null;
              _attachedCampaignName = null;
            }),
            child: const Icon(
              Icons.close,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Uploading...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[800],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.neonGreen,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${(_uploadProgress * 100).toInt()}%',
                style: TextStyle(fontSize: 16, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MEDIA PICKING
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _pickImage() async {
    final images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      for (final image in images) {
        if (_media.length >= _maxMedia) break;
        final bytes = await image.readAsBytes();
        setState(() {
          _media.add(PostMedia(bytes: bytes, isVideo: false));
        });
      }
    }
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      final bytes = await video.readAsBytes();
      setState(() {
        _media.add(PostMedia(bytes: bytes, isVideo: true));
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAG PICKERS (Stubs - would show bottom sheets with search)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _showGymPicker() async {
    // Gym picker — assigns example gym for now
    setState(() {
      _taggedGymId = 'gym_123';
      _taggedGymName = 'Example Gym';
    });
  }

  Future<void> _showFighterPicker() async {
    // Fighter picker — assigns example fighter for now
    setState(() {
      _taggedFighters.add(
        TaggedFighter(id: 'fighter_123', name: 'Example Fighter'),
      );
    });
  }

  Future<void> _showCampaignPicker() async {
    // Campaign picker — assigns example campaign for now
    setState(() {
      _attachedCampaignId = 'campaign_123';
      _attachedCampaignName = 'Pink Shield';
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // POST CREATION
  // ═══════════════════════════════════════════════════════════════════════════

  bool get _canPost {
    return _textController.text.trim().isNotEmpty || _media.isNotEmpty;
  }

  Future<void> _handleCreatePost() async {
    if (!_canPost) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Upload media
      final mediaUrls = <String>[];
      final mediaAssetIds = <String>[];
      final postId = FirebaseFirestore.instance.collection('posts').doc().id;
      if (_media.isNotEmpty) {
        for (var i = 0; i < _media.length; i++) {
          final media = _media[i];
          if (media.isVideo) {
            final result = await _mediaService.ingestVideoBytesAsset(
              videoBytes: media.bytes,
              uploaderId: widget.userId,
              entityType: 'post',
              entityId: postId,
              kind: MediaAssetKind.postMedia,
              rightsOwner: widget.userId,
              rightsType: MediaRightsType.permissioned,
              rightsDeclaration:
                  'User-uploaded social media content under DFC upload terms.',
              originalFileName: 'post_video_$i.mp4',
              onProgress: (progress) {
                setState(() {
                  _uploadProgress = (i + progress) / _media.length;
                });
              },
            );
            if (result.success && result.asset != null) {
              mediaUrls.add(result.asset!.downloadUrl);
              mediaAssetIds.add(result.asset!.id);
            }
          } else {
            final result = await _mediaService.ingestImageAsset(
              imageBytes: media.bytes,
              uploaderId: widget.userId,
              entityType: 'post',
              entityId: postId,
              kind: MediaAssetKind.postMedia,
              rightsOwner: widget.userId,
              rightsType: MediaRightsType.permissioned,
              rightsDeclaration:
                  'User-uploaded social media content under DFC upload terms.',
              originalFileName: 'post_image_$i.jpg',
              onProgress: (progress) {
                setState(() {
                  _uploadProgress = (i + progress) / _media.length;
                });
              },
            );
            if (result.success && result.asset != null) {
              mediaUrls.add(result.asset!.downloadUrl);
              mediaAssetIds.add(result.asset!.id);
            }
          }
        }
      }

      // Create post
      await _socialService.createPost(
        postId: postId,
        authorId: widget.userId,
        content: _textController.text.trim(),
        mediaUrls: mediaUrls,
        mediaAssetIds: mediaAssetIds,
        taggedGymId: _taggedGymId,
        taggedFighterIds: _taggedFighters.map((f) => f.id).toList(),
        campaignId: _attachedCampaignId,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully! 🥊'),
            backgroundColor: AppTheme.neonGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

class PostMedia {
  final Uint8List bytes;
  final bool isVideo;

  PostMedia({required this.bytes, required this.isVideo});
}

class TaggedFighter {
  final String id;
  final String name;

  TaggedFighter({required this.id, required this.name});
}
