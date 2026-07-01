import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/design_tokens.dart';
import '../../features/ppv/widgets/dfc_video_player.dart';
import '../models/community/community_models.dart';
import 'dfc_network_image.dart';

class DfcPostMedia extends StatelessWidget {
  final Post post;
  final EdgeInsetsGeometry? padding;
  final double maxHeight;
  final double galleryHeight;
  final BorderRadius? borderRadius;

  const DfcPostMedia({
    super.key,
    required this.post,
    this.padding,
    this.maxHeight = 340,
    this.galleryHeight = 240,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final attachments = post.mediaAttachments;
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    Widget child;
    if (attachments.length == 1) {
      child = _buildSingleAttachment(context, attachments);
    } else {
      child = _buildAttachmentGrid(context, attachments);
    }

    if (padding != null) {
      child = Padding(padding: padding!, child: child);
    }

    return child;
  }

  Widget _buildSingleAttachment(
    BuildContext context,
    List<PostMediaAttachment> attachments,
  ) {
    return GestureDetector(
      onTap: () => _openViewer(context, attachments, 0),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: _buildAttachmentTile(
            context,
            attachments: attachments,
            index: 0,
            borderRadius: borderRadius,
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentGrid(
    BuildContext context,
    List<PostMediaAttachment> attachments,
  ) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: SizedBox(
        height: galleryHeight,
        child: Row(
          children: [
            Expanded(
              child: _buildAttachmentTile(
                context,
                attachments: attachments,
                index: 0,
              ),
            ),
            if (attachments.length > 1) ...[
              const SizedBox(width: 2),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _buildAttachmentTile(
                        context,
                        attachments: attachments,
                        index: 1,
                      ),
                    ),
                    if (attachments.length > 2) ...[
                      const SizedBox(height: 2),
                      Expanded(
                        child: _buildAttachmentTile(
                          context,
                          attachments: attachments,
                          index: 2,
                          extraCount: attachments.length - 3,
                        ),
                      ),
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

  Widget _buildAttachmentTile(
    BuildContext context, {
    required List<PostMediaAttachment> attachments,
    required int index,
    BorderRadius? borderRadius,
    int extraCount = 0,
  }) {
    final attachment = attachments[index];

    return GestureDetector(
      onTap: () => _openViewer(context, attachments, index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildAttachmentPreview(attachment, borderRadius: borderRadius),
          if (attachment.isVideo)
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.54),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  attachment.isExternalVideo
                      ? Icons.open_in_new
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          if (extraCount > 0)
            Container(
              color: Colors.black.withValues(alpha: 0.55),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+$extraCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'more',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentPreview(
    PostMediaAttachment attachment, {
    BorderRadius? borderRadius,
  }) {
    final previewUrl = attachment.previewUrl;
    if (previewUrl != null && previewUrl.isNotEmpty) {
      return DfcNetworkImage(
        url: previewUrl,
        width: double.infinity,
        borderRadius: borderRadius,
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2137), Color(0xFF0A1628)],
        ),
      ),
      child: Center(
        child: Icon(
          attachment.isVideo ? Icons.videocam_rounded : Icons.image_outlined,
          color: Colors.white.withValues(alpha: 0.68),
          size: 34,
        ),
      ),
    );
  }

  void _openViewer(
    BuildContext context,
    List<PostMediaAttachment> attachments,
    int initialIndex,
  ) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.94),
      builder: (_) => _DfcPostMediaViewer(
        attachments: attachments,
        initialIndex: initialIndex,
      ),
    );
  }
}

class _DfcPostMediaViewer extends StatefulWidget {
  final List<PostMediaAttachment> attachments;
  final int initialIndex;

  const _DfcPostMediaViewer({
    required this.attachments,
    required this.initialIndex,
  });

  @override
  State<_DfcPostMediaViewer> createState() => _DfcPostMediaViewerState();
}

class _DfcPostMediaViewerState extends State<_DfcPostMediaViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attachment = widget.attachments[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: widget.attachments.length > 1
            ? Text(
                '${_currentIndex + 1} / ${widget.attachments.length}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              )
            : null,
        actions: [
          if (attachment.isExternalVideo)
            IconButton(
              icon: const Icon(Icons.open_in_new, color: Colors.white),
              onPressed: () => _launchExternal(context, attachment.url),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.attachments.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final item = widget.attachments[index];
          if (item.isImage) {
            return GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: DfcNetworkImage(url: item.url, fit: BoxFit.contain),
                ),
              ),
            );
          }

          if (item.isEmbeddableVideo) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DFCVideoPlayer(
                  streamUrl: item.url,
                  posterUrl: item.previewUrl,
                  eventTitle: 'DFC Media',
                ),
              ),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.previewUrl != null && item.previewUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: DfcNetworkImage(
                        url: item.previewUrl!,
                        width: double.infinity,
                        height: 240,
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 240,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0D2137), Color(0xFF0A1628)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.open_in_new,
                          color: Colors.white70,
                          size: 46,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'This video is hosted on an external platform.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _launchExternal(context, item.url),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Video'),
                    style: FilledButton.styleFrom(
                      backgroundColor: DesignTokens.neonCyan,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _launchExternal(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open external media link')),
    );
  }
}
