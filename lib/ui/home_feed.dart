// lib/ui/home_feed.dart
import 'package:flutter/material.dart';

import '../../lib/core/theme/app_colors.dart';
import '../feed/feed_service.dart';
import '../models/feed_item.dart';
import '../services/api_client.dart';

class HomeFeedPage extends StatefulWidget {
  const HomeFeedPage({Key? key}) : super(key: key);

  @override
  State<HomeFeedPage> createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends State<HomeFeedPage> {
  late final ApiClient _apiClient;
  late final FeedService _feedService;
  List<dynamic> _feedItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient('https://api.datafightcentral.com');
    _feedService = FeedService(_apiClient);
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _feedService.fetchHomeFeed(limit: 50);
      setState(() {
        _feedItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('DataFight Central Feed'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.neonCyan),
            )
          : _error != null
          ? Center(
              child: Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.redAccent),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadFeed,
              child: ListView.separated(
                itemCount: _feedItems.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Colors.white12, height: 1),
                itemBuilder: (context, i) {
                  final item = _feedItems[i];
                  final isPromotion =
                      item['type'] == 'promotion' || item['promotion'] == true;
                  return ListTile(
                    leading: item['image_url'] != null
                        ? Image.network(
                            item['image_url'] as String,
                            width: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image),
                          )
                        : const Icon(Icons.feed, color: Colors.white24),
                    title: Text(
                      item['title'] ?? 'No Title',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      item['subtitle'] ?? item['description'] ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: isPromotion
                        ? const Icon(Icons.campaign, color: Colors.orange)
                        : null,
                  );
                },
              ),
            ),
    );
  }
}
