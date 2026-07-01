// lib/features/feed/screens/feed_screen.dart
// Feed section for Adrenaline Gateway.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/services/ai_content_service.dart';
import '../../../shared/widgets/dfc_network_image.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  static const _card = Color(0xFF0A1228);
  static const _cyan = Color(0xFF00E5FF);

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  Object? _lastError;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _lastError = null;
    });
    try {
      final service = context.read<AiContentService>();
      final posts = await service.getMainFeed();
      if (!mounted) return;
      setState(() {
        _items = posts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _lastError = e;
      });
    }
  }

  Future<void> _reload() async {
    await _loadFeed();
  }

  @override
  Widget build(BuildContext context) {
    final visibleCount = _items.length > 8 ? 8 : _items.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cyan.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dynamic_feed, color: _cyan, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'FEED',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loading ? null : _reload,
                icon: Icon(
                  Icons.refresh,
                  size: 18,
                  color: _loading ? Colors.white24 : _cyan.withAlpha(220),
                ),
              ),
            ],
          ),
          if (_loading) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.white10,
              color: _cyan.withAlpha(200),
            ),
          ],
          if (_lastError != null) ...[
            const SizedBox(height: 12),
            const Text(
              'Feed unavailable',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _lastError.toString(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ] else if (!_loading && _items.isEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Nothing published yet.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When the pipeline publishes, posts will appear here.',
              style: TextStyle(
                color: _cyan.withAlpha(160),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleCount,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _buildFeedItemCard(context, _items[index]),
            ),
            if (_items.length > visibleCount) ...[
              const SizedBox(height: 10),
              Text(
                '+${_items.length - visibleCount} more items not shown',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildFeedItemCard(BuildContext context, Map<String, dynamic> item) {
    final type = item['type']?.toString() ?? 'news';
    final source = item['profiles']?['display_name'] ?? 'DFC Network';
    final publishedAtStr = item['created_at']?.toString();
    final publishedAt = publishedAtStr != null
        ? DateTime.tryParse(publishedAtStr) ?? DateTime.now()
        : DateTime.now();
    final imageUrl = item['media_url']?.toString();
    final title = item['headline']?.toString() ?? '';
    final body = item['body']?.toString() ?? '';

    return Material(
      color: const Color(0xFF0D0D1A),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _cyan.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_iconForType(type), size: 16, color: _cyan),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          source,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatPublishedAt(publishedAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withAlpha(140),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: DfcNetworkImage(
                    url: imageUrl,
                    height: 180,
                    width: double.infinity,
                  ),
                ),
              ],
              if (title.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
              if (body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  body,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'clip':
        return Icons.play_circle_outline;
      case 'news':
        return Icons.article_outlined;
      case 'ppvpromo':
        return Icons.live_tv;
      case 'result':
        return Icons.emoji_events;
      case 'sponsor':
        return Icons.verified;
      default:
        return Icons.forum_outlined;
    }
  }

  String _formatPublishedAt(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 48) return '${diff.inHours}h';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
