import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/community/community_models.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/social_service.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../../social/widgets/follow_button.dart';

/// PAGES DISCOVERY — Browse gyms, promoters, fighters, and brands
/// Facebook-style "Pages" for DFC entities, driven by actual feed identity.
class PagesDiscoveryScreen extends StatefulWidget {
  const PagesDiscoveryScreen({super.key});

  @override
  State<PagesDiscoveryScreen> createState() => _PagesDiscoveryScreenState();
}

class _PagesDiscoveryScreenState extends State<PagesDiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategory = 0;
  bool _loading = true;
  String? _currentUserId;
  List<_PageEntry> _pages = const [];

  static const _categories = ['All', 'Gyms', 'Promoters', 'Fighters', 'Brands'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedCategory = _tabController.index);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPages());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<_PageEntry> get _filtered {
    if (_selectedCategory == 0) {
      return _pages;
    }

    final selected = _categories[_selectedCategory];
    final typeMap = {
      'Gyms': 'Gym',
      'Promoters': 'Promoter',
      'Fighters': 'Fighter',
      'Brands': 'Brand',
    };
    return _pages.where((page) => page.type == typeMap[selected]).toList();
  }

  Future<void> _loadPages() async {
    final auth = context.read<AuthService>();
    final social = context.read<SocialService>();

    try {
      final posts = await social.getFeed().first;
      var discovered = _buildPagesFromPosts(posts);
      discovered = await _enrichPagesFromUsers(discovered);

      discovered = await Future.wait(
        discovered.map((page) async {
          try {
            final followers = await social.getFollowerCount(page.userId);
            return page.copyWith(followers: followers);
          } catch (_) {
            return page;
          }
        }),
      );

      discovered.sort((a, b) {
        if (a.verified != b.verified) {
          return a.verified ? -1 : 1;
        }
        if (a.followers != b.followers) {
          return b.followers.compareTo(a.followers);
        }
        if (a.postCount != b.postCount) {
          return b.postCount.compareTo(a.postCount);
        }
        return a.name.compareTo(b.name);
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _currentUserId = auth.currentUser?.uid;
        _pages = discovered;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentUserId = auth.currentUser?.uid;
        _pages = const [];
        _loading = false;
      });
    }
  }

  List<_PageEntry> _buildPagesFromPosts(List<Post> posts) {
    final pagesByUser = <String, _PageAccumulator>{};

    for (final post in posts) {
      final type = _pageTypeForRole(post.userRole);
      if (post.userId.isEmpty || type == null) {
        continue;
      }

      final accumulator = pagesByUser.putIfAbsent(
        post.userId,
        () => _PageAccumulator(
          userId: post.userId,
          name: post.displayName,
          type: type,
          verified: post.isVerified,
          color: _pageColorForType(type),
          icon: _pageIconForType(type),
        ),
      );

      accumulator.name = post.displayName;
      accumulator.verified = accumulator.verified || post.isVerified;
      accumulator.avatarUrl ??= post.userAvatarUrl;
      accumulator.location ??= post.location;
      accumulator.description ??= _describePageFromPost(post.content);
      accumulator.postCount += 1;

      if (post.hasMedia) {
        accumulator.mediaPostCount += 1;
        accumulator.previewMediaUrl ??=
            post.thumbnailUrl ??
            post.primaryAttachment?.previewUrl ??
            post.primaryAttachment?.url;
      } else {
        accumulator.previewMediaUrl ??= post.userAvatarUrl;
      }
    }

    return pagesByUser.values
        .map((accumulator) => accumulator.build())
        .toList(growable: false);
  }

  Future<List<_PageEntry>> _enrichPagesFromUsers(List<_PageEntry> pages) async {
    final userIds = pages
        .map((page) => page.userId)
        .where((userId) => userId.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (userIds.isEmpty) {
      return pages;
    }

    final usersById = <String, Map<String, dynamic>>{};
    for (var index = 0; index < userIds.length; index += 10) {
      final end = index + 10 < userIds.length ? index + 10 : userIds.length;
      final chunk = userIds.sublist(index, end);
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        usersById[doc.id] = doc.data();
      }
    }

    return pages
        .map((page) {
          final user = usersById[page.userId];
          if (user == null) {
            return page;
          }

          final displayName = _firstNonEmptyField(user, const [
            'pageDisplayName',
            'displayName',
            'businessName',
          ]);
          final bio = _firstNonEmptyField(user, const [
            'pageBio',
            'bio',
            'tagline',
            'description',
          ]);
          final avatarUrl = _firstNonEmptyField(user, const [
            'pageAvatarUrl',
            'photoUrl',
            'photoURL',
            'brandLogoUrl',
            'logoUrl',
          ]);
          final coverUrl = _firstNonEmptyField(user, const [
            'pageCoverUrl',
            'pageBannerUrl',
            'coverPhotoUrl',
            'bannerUrl',
            'heroImageUrl',
            'headerImageUrl',
          ]);
          final city = _firstNonEmptyField(user, const ['city']);
          final country = _firstNonEmptyField(user, const ['country']);
          final location = [
            city,
            country,
          ].whereType<String>().where((value) => value.isNotEmpty).join(', ');
          final verified = user['isVerified'] == true || page.verified;

          return page.copyWith(
            name: displayName ?? page.name,
            description: bio ?? page.description,
            avatarUrl: avatarUrl ?? coverUrl ?? page.avatarUrl,
            previewMediaUrl: coverUrl ?? avatarUrl ?? page.previewMediaUrl,
            location: location.isNotEmpty ? location : page.location,
            verified: verified,
          );
        })
        .toList(growable: false);
  }

  String? _firstNonEmptyField(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String? _pageTypeForRole(String? role) {
    switch (role) {
      case 'gym':
      case 'coach':
        return 'Gym';
      case 'promoter':
      case 'organization':
        return 'Promoter';
      case 'fighter':
        return 'Fighter';
      case 'media':
      case 'admin':
      case 'community':
      case 'brand':
        return 'Brand';
      default:
        return null;
    }
  }

  Color _pageColorForType(String type) {
    switch (type) {
      case 'Gym':
        return DesignTokens.neonGreen;
      case 'Promoter':
        return DesignTokens.neonMagenta;
      case 'Fighter':
        return DesignTokens.neonCyan;
      case 'Brand':
        return DesignTokens.neonAmber;
      default:
        return Colors.white;
    }
  }

  IconData _pageIconForType(String type) {
    switch (type) {
      case 'Gym':
        return Icons.fitness_center;
      case 'Promoter':
        return Icons.campaign;
      case 'Fighter':
        return Icons.person;
      case 'Brand':
        return Icons.storefront;
      default:
        return Icons.flag;
    }
  }

  String _describePageFromPost(String content) {
    final normalized = content.trim().replaceAll('\n', ' ');
    if (normalized.isEmpty) {
      return 'Official DFC page.';
    }
    return normalized.length <= 120
        ? normalized
        : '${normalized.substring(0, 117)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgPrimary,
        elevation: 0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag, color: DesignTokens.neonMagenta, size: 20),
            SizedBox(width: 8),
            Text(
              'Pages',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: DesignTokens.neonMagenta,
          indicatorWeight: 3,
          labelColor: DesignTokens.neonMagenta,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
          tabs: _categories.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DesignTokens.neonMagenta),
            )
          : RefreshIndicator(
              color: DesignTokens.neonMagenta,
              backgroundColor: DesignTokens.bgCard,
              onRefresh: _loadPages,
              child: _filtered.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(32),
                      children: [
                        const SizedBox(height: 80),
                        Icon(
                          Icons.flag_circle_outlined,
                          size: 56,
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No page identities are visible yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) =>
                          _buildPageCard(_filtered[index]),
                    ),
            ),
    );
  }

  Widget _buildPageCard(_PageEntry page) {
    return InkWell(
      onTap: () => context.push('/user/${page.userId}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: page.verified
                ? page.color.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.04),
          ),
        ),
        child: Row(
          children: [
            _buildAvatar(page),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          page.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (page.verified) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          color: DesignTokens.neonCyan,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    page.location.isEmpty
                        ? page.type
                        : '${page.type} · ${page.location}',
                    style: TextStyle(
                      color: page.color.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    page.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatChip(
                        page.color,
                        page.followers > 0
                            ? '${_fmtK(page.followers)} followers'
                            : 'Page live',
                      ),
                      _buildStatChip(page.color, '${page.postCount} posts'),
                      if (page.mediaPostCount > 0)
                        _buildStatChip(
                          page.color,
                          '${page.mediaPostCount} media',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (page.previewMediaUrl != null &&
                    page.previewMediaUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: DfcNetworkImage(
                        url: page.previewMediaUrl!,
                        width: 72,
                        height: 72,
                        errorWidget: _buildPreviewFallback(page),
                      ),
                    ),
                  )
                else
                  _buildPreviewFallback(page),
                const SizedBox(height: 10),
                if (_currentUserId != null && _currentUserId != page.userId)
                  FollowButton(
                    currentUserId: _currentUserId!,
                    targetUserId: page.userId,
                    compact: true,
                  )
                else
                  OutlinedButton(
                    onPressed: () => context.push('/user/${page.userId}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: page.color,
                      side: BorderSide(
                        color: page.color.withValues(alpha: 0.35),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Open'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(_PageEntry page) {
    final avatarUrl =
        (page.previewMediaUrl != null && page.previewMediaUrl!.isNotEmpty)
        ? page.previewMediaUrl!
        : (page.avatarUrl != null && page.avatarUrl!.isNotEmpty)
        ? page.avatarUrl!
        : null;

    if (avatarUrl != null) {
      return ClipOval(
        child: SizedBox(
          width: 52,
          height: 52,
          child: DfcNetworkImage(
            url: avatarUrl,
            errorWidget: _buildAvatarFallback(page),
            width: 52,
            height: 52,
          ),
        ),
      );
    }

    return _buildAvatarFallback(page);
  }

  Widget _buildAvatarFallback(_PageEntry page) {
    return CircleAvatar(
      radius: 26,
      backgroundColor: page.color.withValues(alpha: 0.12),
      child: Icon(page.icon, color: page.color, size: 24),
    );
  }

  Widget _buildPreviewFallback(_PageEntry page) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: page.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(page.icon, color: page.color, size: 28),
    );
  }

  Widget _buildStatChip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _fmtK(int n) {
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}K';
    }
    return '$n';
  }
}

class _PageEntry {
  final String userId;
  final String name;
  final String type;
  final int followers;
  final int postCount;
  final int mediaPostCount;
  final String location;
  final bool verified;
  final Color color;
  final IconData icon;
  final String description;
  final String? avatarUrl;
  final String? previewMediaUrl;

  const _PageEntry({
    required this.userId,
    required this.name,
    required this.type,
    required this.followers,
    required this.postCount,
    required this.mediaPostCount,
    required this.location,
    required this.verified,
    required this.color,
    required this.icon,
    required this.description,
    this.avatarUrl,
    this.previewMediaUrl,
  });

  _PageEntry copyWith({
    int? followers,
    String? name,
    String? description,
    String? avatarUrl,
    String? previewMediaUrl,
    String? location,
    bool? verified,
  }) {
    return _PageEntry(
      userId: userId,
      name: name ?? this.name,
      type: type,
      followers: followers ?? this.followers,
      postCount: postCount,
      mediaPostCount: mediaPostCount,
      location: location ?? this.location,
      verified: verified ?? this.verified,
      color: color,
      icon: icon,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      previewMediaUrl: previewMediaUrl ?? this.previewMediaUrl,
    );
  }
}

class _PageAccumulator {
  final String userId;
  final String type;
  final Color color;
  final IconData icon;
  String name;
  bool verified;
  String? location;
  String? description;
  String? avatarUrl;
  String? previewMediaUrl;
  int postCount = 0;
  int mediaPostCount = 0;

  _PageAccumulator({
    required this.userId,
    required this.name,
    required this.type,
    required this.verified,
    required this.color,
    required this.icon,
  });

  _PageEntry build() {
    return _PageEntry(
      userId: userId,
      name: name,
      type: type,
      followers: 0,
      postCount: postCount,
      mediaPostCount: mediaPostCount,
      location: location ?? '',
      verified: verified,
      color: color,
      icon: icon,
      description: description ?? 'Official DFC page.',
      avatarUrl: avatarUrl,
      previewMediaUrl: previewMediaUrl,
    );
  }
}
