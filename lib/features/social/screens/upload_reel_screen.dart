import 'package:flutter/material.dart' hide RouterConfig;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/media_asset_model.dart';
import '../../../shared/models/community/short_video_model.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/media_upload_service.dart';
import '../../../shared/services/short_video_service.dart';

/// Screen for uploading a new Reel with canonical media ingestion.
class UploadReelScreen extends StatefulWidget {
  const UploadReelScreen({super.key});

  @override
  State<UploadReelScreen> createState() => _UploadReelScreenState();
}

class _UploadReelScreenState extends State<UploadReelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _videoUrlCtrl = TextEditingController();
  final _hashtagsCtrl = TextEditingController();
  XFile? _selectedVideo;
  XFile? _selectedThumbnail;

  VideoVisibility _visibility = VideoVisibility.public;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _videoUrlCtrl.dispose();
    _hashtagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null || !mounted) return;
    setState(() => _selectedVideo = video);
  }

  Future<void> _pickThumbnail() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;
    setState(() => _selectedThumbnail = image);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final auth = context.read<AuthService>();
    if (!auth.isDemoUser && _selectedVideo == null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select a reel video to upload through DFC media intake',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final service = context.read<ShortVideoService>();
    final nav = GoRouter.of(context);
    final uploader = MediaUploadService();
    final creatorId = auth.currentUser?.uid ?? 'current_user';
    final creatorName = auth.userModel?.displayName ?? 'Fighter';
    final rightsOwner = creatorName.isEmpty ? creatorId : creatorName;
    final reelId = FirebaseFirestore.instance
        .collection('short_videos')
        .doc()
        .id;

    final hashtags = _hashtagsCtrl.text
        .split(RegExp(r'[,\s]+'))
        .where((t) => t.isNotEmpty)
        .map((t) => t.startsWith('#') ? t : '#$t')
        .toList();

    String? videoAssetId;
    String? thumbnailAssetId;

    final resolvedVideoUrl = _selectedVideo != null
        ? (() async {
            final result = await uploader.ingestVideoBytesAsset(
              videoBytes: await _selectedVideo!.readAsBytes(),
              uploaderId: creatorId,
              uploaderRole: auth.userModel?.role.name,
              entityType: 'short_video',
              entityId: reelId,
              kind: MediaAssetKind.highlight,
              rightsOwner: rightsOwner,
              rightsType: MediaRightsType.permissioned,
              rightsDeclaration:
                  'Creator-uploaded reel content under DFC upload terms.',
              originalFileName: _selectedVideo!.name,
            );
            if (!result.success || result.asset == null) {
              throw Exception(result.error ?? 'Video upload failed');
            }
            videoAssetId = result.asset!.id;
            return result.asset!.downloadUrl;
          })()
        : Future.value(auth.isDemoUser ? _videoUrlCtrl.text.trim() : '');

    final resolvedThumbnailUrl = _selectedThumbnail != null
        ? (() async {
            final result = await uploader.ingestImageAsset(
              imageBytes: await _selectedThumbnail!.readAsBytes(),
              uploaderId: creatorId,
              uploaderRole: auth.userModel?.role.name,
              entityType: 'short_video',
              entityId: reelId,
              kind: MediaAssetKind.highlight,
              rightsOwner: rightsOwner,
              rightsType: MediaRightsType.permissioned,
              rightsDeclaration:
                  'Creator-uploaded reel thumbnail under DFC upload terms.',
              originalFileName: _selectedThumbnail!.name,
            );
            if (!result.success || result.asset == null) {
              throw Exception(result.error ?? 'Thumbnail upload failed');
            }
            thumbnailAssetId = result.asset!.id;
            return result.asset!.downloadUrl;
          })()
        : Future.value('');

    await service.createVideo(
      videoId: reelId,
      creatorId: creatorId,
      creatorName: creatorName,
      creatorAvatarUrl: auth.userModel?.photoUrl ?? '',
      videoUrl: await resolvedVideoUrl,
      videoAssetId: videoAssetId,
      thumbnailUrl: await resolvedThumbnailUrl,
      thumbnailAssetId: thumbnailAssetId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      hashtags: hashtags,
      visibility: _visibility,
    );

    if (!mounted) return;
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final allowFallbackUrl = context.watch<AuthService>().isDemoUser;
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'Upload Reel',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: DesignTokens.neonCyan),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DesignTokens.neonCyan.withValues(alpha: 0.15),
                      DesignTokens.neonMagenta.withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.slow_motion_video_rounded,
                      color: DesignTokens.neonCyan,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'New Fight Reel',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Share your best clips, highlights, or training footage',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildLabel('Video File'),
              const SizedBox(height: 8),
              _buildMediaPicker(
                title: _selectedVideo?.name ?? 'Select a reel video',
                subtitle: _selectedVideo != null
                    ? 'Local file selected for upload'
                    : allowFallbackUrl
                    ? 'Upload MP4, MOV, or WebM from your device'
                    : 'Required: upload MP4, MOV, or WebM through DFC intake',
                icon: Icons.video_library_outlined,
                actionLabel: 'Choose Video',
                onTap: _pickVideo,
              ),

              const SizedBox(height: 20),

              _buildLabel('Thumbnail Image'),
              const SizedBox(height: 8),
              _buildMediaPicker(
                title: _selectedThumbnail?.name ?? 'Optional thumbnail image',
                subtitle: _selectedThumbnail != null
                    ? 'Thumbnail will be uploaded with the reel'
                    : 'Add a custom cover instead of leaving it blank',
                icon: Icons.image_outlined,
                actionLabel: 'Choose Thumbnail',
                onTap: _pickThumbnail,
              ),

              const SizedBox(height: 20),

              // Video URL
              _buildLabel('Fallback Video URL'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _videoUrlCtrl,
                enabled: allowFallbackUrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  hint: allowFallbackUrl
                      ? 'Optional in demo mode: https://example.com/video.mp4'
                      : 'Disabled outside demo mode',
                  icon: Icons.link,
                ),
                validator: (v) {
                  if (_selectedVideo != null || !allowFallbackUrl) {
                    return null;
                  }
                  if (v == null || v.trim().isEmpty) {
                    return 'Select a video file or enter a video URL';
                  }
                  final uri = Uri.tryParse(v.trim());
                  if (uri == null || !uri.hasScheme) {
                    return 'Enter a valid URL';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Title
              _buildLabel('Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(color: Colors.white),
                maxLength: 80,
                decoration: _inputDecoration(
                  hint: 'KO highlight from last fight...',
                  icon: Icons.title,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),

              const SizedBox(height: 16),

              // Description
              _buildLabel('Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                maxLength: 300,
                decoration: _inputDecoration(
                  hint: 'Tell the story behind this clip...',
                  icon: Icons.description_outlined,
                ),
              ),

              const SizedBox(height: 16),

              // Hashtags
              _buildLabel('Hashtags'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _hashtagsCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  hint: '#MMA #KO #Highlight (comma or space separated)',
                  icon: Icons.tag,
                ),
              ),

              const SizedBox(height: 24),

              // Visibility
              _buildLabel('Visibility'),
              const SizedBox(height: 12),
              Row(
                children: VideoVisibility.values.map((vis) {
                  final selected = _visibility == vis;
                  final icon = switch (vis) {
                    VideoVisibility.public => Icons.public,
                    VideoVisibility.followers => Icons.people,
                    VideoVisibility.private => Icons.lock,
                  };
                  final label =
                      vis.name[0].toUpperCase() + vis.name.substring(1);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        selected: selected,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 16,
                              color: selected
                                  ? DesignTokens.bgPrimary
                                  : Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                color: selected
                                    ? DesignTokens.bgPrimary
                                    : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        selectedColor: DesignTokens.neonCyan,
                        backgroundColor: DesignTokens.bgCard,
                        side: BorderSide(
                          color: selected
                              ? DesignTokens.neonCyan
                              : Colors.white24,
                        ),
                        onSelected: (_) => setState(() => _visibility = vis),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: DesignTokens.bgPrimary,
                          ),
                        )
                      : const Icon(Icons.upload_rounded),
                  label: Text(_submitting ? 'Publishing...' : 'Publish Reel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.neonCyan,
                    foregroundColor: DesignTokens.bgPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: _submitting ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: DesignTokens.neonCyan,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }

  Widget _buildMediaPicker({
    required String title,
    required String subtitle,
    required IconData icon,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: DesignTokens.neonCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: DesignTokens.neonCyan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: _submitting ? null : onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: DesignTokens.neonCyan,
              side: const BorderSide(color: DesignTokens.neonCyan),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      prefixIcon: Icon(icon, color: DesignTokens.neonCyan, size: 20),
      filled: true,
      fillColor: DesignTokens.bgCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: DesignTokens.neonCyan),
      ),
      counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
    );
  }
}
