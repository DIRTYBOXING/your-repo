import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/image_assets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// STORY VIEWER — Instagram-grade full-screen story viewer
///
/// • Progress bars at top (one per story in set)
/// • Tap left/right to navigate
/// • Swipe down to close
/// • Auto-advance timer (5 seconds per story)
/// • User info overlay (name + timestamp)
/// • Background branded images for demo stories
/// ═══════════════════════════════════════════════════════════════════════════

class StoryViewerScreen extends StatefulWidget {
  final String category;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.category,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressCtrl;
  late int _currentIndex;
  List<_DemoStory> _stories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
    _progressCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addStatusListener(_onProgressDone);
    _loadStories();
  }

  Future<void> _loadStories() async {
    List<_DemoStory> loaded = [];
    try {
      final snap = await FirebaseFirestore.instance
          .collection('stories')
          .where('category', isEqualTo: widget.category)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      if (snap.docs.isNotEmpty) {
        loaded = snap.docs.map((d) {
          final data = d.data();
          return _DemoStory(
            author: data['author'] ?? 'DFC',
            caption: data['caption'] ?? '',
            imageAsset: data['imageAsset'] ?? 'assets/logos/new_dfc_image_1.png',
            icon: Icons.sports_mma_rounded,
            timeAgo: data['timeAgo'] ?? 'Just now',
          );
        }).toList();
      }
    } catch (_) {
      // Firestore unavailable — use demo
    }
    if (loaded.isEmpty) {
      loaded = _storiesForCategory(widget.category);
    }
    _stories = loaded;
    _currentIndex = widget.initialIndex.clamp(0, _stories.length - 1);
    if (mounted) {
      setState(() => _loading = false);
      _progressCtrl.forward();
    }
  }

  void _onProgressDone(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _advance();
    }
  }

  void _advance() {
    if (_currentIndex < _stories.length - 1) {
      setState(() => _currentIndex++);
      _progressCtrl
        ..reset()
        ..forward();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goBack() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _progressCtrl
        ..reset()
        ..forward();
    } else {
      _progressCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _stories.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final story = _stories[_currentIndex];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onVerticalDragEnd: (d) {
            if (d.primaryVelocity != null && d.primaryVelocity! > 300) {
              Navigator.of(context).pop();
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.asset(
                story.imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF1A0030),
                        Color(0xFF050A14),
                      ],
                    ),
                  ),
                ),
              ),

              // Gradient overlays
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Tap zones
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _goBack,
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _advance,
                      behavior: HitTestBehavior.opaque,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),

              // Top: progress bars + user info
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress bars
                      Row(
                        children: List.generate(_stories.length, (i) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 1.5,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: SizedBox(
                                  height: 2.5,
                                  child: i < _currentIndex
                                      ? Container(color: Colors.white)
                                      : i == _currentIndex
                                      ? AnimatedBuilder(
                                          animation: _progressCtrl,
                                          builder: (_, _) =>
                                              LinearProgressIndicator(
                                                value: _progressCtrl.value,
                                                backgroundColor: Colors.white
                                                    .withValues(alpha: 0.3),
                                                valueColor:
                                                    const AlwaysStoppedAnimation(
                                                      Colors.white,
                                                    ),
                                                minHeight: 2.5,
                                              ),
                                        )
                                      : Container(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),

                      // User info row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: DesignTokens.neonCyan,
                            child: Icon(
                              story.icon,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  story.author,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  story.timeAgo,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom: story text + reply bar
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (story.caption.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          story.caption,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Reply bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      height: 44,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Reply to ${story.author}...',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.favorite_border,
                            color: Colors.white.withValues(alpha: 0.5),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.send_rounded,
                            color: Colors.white.withValues(alpha: 0.5),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Demo story data ──

  static List<_DemoStory> _storiesForCategory(String category) {
    switch (category) {
      case 'EVENTS':
        return const [
          _DemoStory(
            author: 'DFC Events',
            caption: 'UFC 325 is coming to Sydney! Get your tickets now.',
            imageAsset: 'assets/logos/new_dfc_image_1.png',
            icon: Icons.event_rounded,
            timeAgo: '2h ago',
          ),
          _DemoStory(
            author: 'IBC Events',
            caption: 'IBC 18 — Full card announced. 12 bouts, 4 title fights.',
            imageAsset: 'assets/logos/dfc2_image.png',
            icon: Icons.sports_mma_rounded,
            timeAgo: '4h ago',
          ),
          _DemoStory(
            author: 'BKFC Australia',
            caption: 'Weigh-ins LIVE tomorrow from Gold Coast.',
            imageAsset: 'assets/logos/dfc_and_back_ground.png',
            icon: Icons.monitor_weight_rounded,
            timeAgo: '6h ago',
          ),
        ];
      case 'FIGHTERS':
        return const [
          _DemoStory(
            author: 'Tai Tuivasa',
            caption: 'Back in camp. Heavy hands loading.',
            imageAsset: 'assets/logos/datafight_central_with_logo.png',
            icon: Icons.sports_mma_rounded,
            timeAgo: '1h ago',
          ),
          _DemoStory(
            author: 'Robert Whittaker',
            caption: 'Morning session done. 6 rounds sparring.',
            imageAsset: ImageAssets.dfcBrandedPlaceholder,
            icon: Icons.fitness_center_rounded,
            timeAgo: '3h ago',
          ),
          _DemoStory(
            author: 'Volk',
            caption: 'Recovery day. Cold plunge then pad work later.',
            imageAsset: 'assets/logos/new_dfc_image_1.png',
            icon: Icons.sports_mma_rounded,
            timeAgo: '5h ago',
          ),
        ];
      case 'BKFC':
        return const [
          _DemoStory(
            author: 'BKFC Official',
            caption: 'Bare knuckle is back! New season kicks off next month.',
            imageAsset: 'assets/logos/dfc2_image_.png',
            icon: Icons.local_fire_department_rounded,
            timeAgo: '30m ago',
          ),
          _DemoStory(
            author: 'Dirty Boxing',
            caption: 'Catch the highlights. No gloves, all heart.',
            imageAsset: 'assets/logos/dfc2_image.png',
            icon: Icons.sports_mma_rounded,
            timeAgo: '2h ago',
          ),
        ];
      case 'RECAPS':
        return const [
          _DemoStory(
            author: 'DFC Results',
            caption: 'Main event: KO in Round 2! What a finish.',
            imageAsset: 'assets/logos/dfc_and_back_ground.png',
            icon: Icons.emoji_events_rounded,
            timeAgo: '1h ago',
          ),
          _DemoStory(
            author: 'Fight Night Recap',
            caption: '5 finishes, 2 upsets, 1 new champion crowned.',
            imageAsset: 'assets/logos/datafight_central_with_logo.png',
            icon: Icons.emoji_events_rounded,
            timeAgo: '8h ago',
          ),
        ];
      case 'CITIES':
        return const [
          _DemoStory(
            author: 'Sydney MMA',
            caption:
                'New gym opening in Bondi. Grand open sparring this Saturday.',
            imageAsset: 'assets/logos/new_dfc_image_1.png',
            icon: Icons.location_city_rounded,
            timeAgo: '4h ago',
          ),
          _DemoStory(
            author: 'Melbourne Fight Scene',
            caption: 'Pop-up training camp at Docklands. Free entry.',
            imageAsset: ImageAssets.dfcBrandedPlaceholder,
            icon: Icons.location_city_rounded,
            timeAgo: '7h ago',
          ),
        ];
      default:
        return const [
          _DemoStory(
            author: 'DataFightCentral',
            caption: 'Welcome to the fight community.',
            imageAsset: 'assets/logos/new_dfc_image_1.png',
            icon: Icons.sports_mma_rounded,
            timeAgo: 'Just now',
          ),
        ];
    }
  }
}

class _DemoStory {
  final String author;
  final String caption;
  final String imageAsset;
  final IconData icon;
  final String timeAgo;

  const _DemoStory({
    required this.author,
    required this.caption,
    required this.imageAsset,
    required this.icon,
    required this.timeAgo,
  });
}
