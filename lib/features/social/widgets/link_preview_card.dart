import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/link_preview_service.dart';
import '../../../shared/widgets/dfc_network_image.dart';

/// Renders an Open Graph link preview card inside a post.
///
/// Two modes:
/// 1. **Static** — receives pre-fetched data (from Firestore fields on Post)
/// 2. **Async** — receives only a URL and fetches OG data on mount
class LinkPreviewCard extends StatefulWidget {
  /// Pre-fetched fields (used when rendering existing posts)
  final String? url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? domain;

  /// If true, fetch OG data from the URL on mount (compose screen mode).
  final bool fetchOnMount;

  /// Called when async fetch completes — lets compose screen store the data.
  final ValueChanged<LinkPreviewData>? onFetched;

  /// Called when the user dismisses the preview.
  final VoidCallback? onDismiss;

  const LinkPreviewCard({
    super.key,
    this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.domain,
    this.fetchOnMount = false,
    this.onFetched,
    this.onDismiss,
  });

  @override
  State<LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends State<LinkPreviewCard> {
  LinkPreviewData? _data;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.fetchOnMount && widget.url != null) {
      _fetchPreview();
    }
  }

  Future<void> _fetchPreview() async {
    setState(() => _loading = true);
    final data = await LinkPreviewService.instance.fetchPreview(widget.url!);
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
      _failed = data == null || !data.hasContent;
    });
    if (data != null && data.hasContent) {
      widget.onFetched?.call(data);
    }
  }

  String get _title => _data?.title ?? widget.title ?? '';
  String get _description => _data?.description ?? widget.description ?? '';
  String get _image => _data?.imageUrl ?? widget.imageUrl ?? '';
  String get _domain =>
      _data?.domain ?? widget.domain ?? _extractDomain(widget.url ?? '');
  String get _url => _data?.url ?? widget.url ?? '';

  static String _extractDomain(String url) {
    final uri = Uri.tryParse(url);
    return uri?.host ?? '';
  }

  @override
  Widget build(BuildContext context) {
    // Still loading
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: DesignTokens.neonCyan.withValues(alpha: 0.2),
            ),
          ),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: DesignTokens.neonCyan,
              ),
            ),
          ),
        ),
      );
    }

    // Nothing to show
    if (_failed && widget.title == null) return const SizedBox.shrink();
    if (_title.isEmpty && _description.isEmpty && _image.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: GestureDetector(
        onTap: _openUrl,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: DesignTokens.neonCyan.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // OG Image
              if (_image.isNotEmpty)
                Stack(
                  children: [
                    DfcNetworkImage(
                      url: _image,
                      width: double.infinity,
                      height: 160,
                    ),
                    // Dismiss button (compose mode)
                    if (widget.onDismiss != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: widget.onDismiss,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

              // Text content
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Domain
                    if (_domain.isNotEmpty)
                      Text(
                        _domain.toUpperCase(),
                        style: TextStyle(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),

                    // Title
                    if (_title.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    // Description
                    if (_description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl() async {
    if (_url.isEmpty) return;
    final uri = Uri.tryParse(_url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
