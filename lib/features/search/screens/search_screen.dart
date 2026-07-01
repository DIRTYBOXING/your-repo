import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/debouncer.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC SEARCH SCREEN — Universal search across fighters, events, gyms, news
/// ═══════════════════════════════════════════════════════════════════════════
class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _debouncer = DFCDebouncer();
  String _selectedCategory = 'all';
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _lastQuery;

  final _categories = [
    {'id': 'all', 'label': 'All', 'icon': Icons.search},
    {'id': 'fighters', 'label': 'Fighters', 'icon': Icons.sports_mma},
    {'id': 'events', 'label': 'Events', 'icon': Icons.event},
    {'id': 'gyms', 'label': 'Gyms', 'icon': Icons.fitness_center},
    {'id': 'news', 'label': 'News', 'icon': Icons.newspaper},
    {'id': 'users', 'label': 'Users', 'icon': Icons.people},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _controller.text = widget.initialQuery!;
      _performSearch();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _debouncer.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty || query.length < 2) {
      setState(() => _results = []);
      return;
    }
    if (query == _lastQuery && _results.isNotEmpty) return;

    setState(() {
      _isLoading = true;
      _lastQuery = query;
    });

    final results = <Map<String, dynamic>>[];
    final db = FirebaseFirestore.instance;

    try {
      // Search Fighters — try searchKeywords array, then searchTerms, then name prefix
      if (_selectedCategory == 'all' || _selectedCategory == 'fighters') {
        QuerySnapshot<Map<String, dynamic>>? fightersSnap;
        // Try searchKeywords first (written by databank_service)
        try {
          fightersSnap = await db
              .collection('fighters')
              .where('searchKeywords', arrayContains: query)
              .limit(10)
              .get();
        } catch (_) {
          fightersSnap = null;
        }
        // Fallback to searchTerms field
        if (fightersSnap == null || fightersSnap.docs.isEmpty) {
          try {
            fightersSnap = await db
                .collection('fighters')
                .where('searchTerms', arrayContains: query)
                .limit(10)
                .get();
          } catch (_) {
            fightersSnap = null;
          }
        }
        if (fightersSnap != null) {
          for (final doc in fightersSnap.docs) {
            results.add({
              'type': 'fighter',
              'id': doc.id,
              'title':
                  doc.data()['displayName'] ?? doc.data()['name'] ?? 'Unknown',
              'subtitle': doc.data()['discipline'] ?? 'Fighter',
              'imageUrl': doc.data()['photoUrl'],
              'route': '/fighter/${doc.id}',
            });
          }
        }
        // Final fallback: name prefix (case-sensitive on Firestore)
        if (results.where((r) => r['type'] == 'fighter').isEmpty) {
          final nameSnap = await db
              .collection('fighters')
              .orderBy('name')
              .startAt([query])
              .endAt(['$query\uf8ff'])
              .limit(10)
              .get();
          for (final doc in nameSnap.docs) {
            results.add({
              'type': 'fighter',
              'id': doc.id,
              'title':
                  doc.data()['displayName'] ?? doc.data()['name'] ?? 'Unknown',
              'subtitle': doc.data()['discipline'] ?? 'Fighter',
              'imageUrl': doc.data()['photoUrl'],
              'route': '/fighter/${doc.id}',
            });
          }
        }
      }

      // Search Events — try case-insensitive by searching both casings
      if (_selectedCategory == 'all' || _selectedCategory == 'events') {
        final seen = <String>{};
        // Try uppercase prefix (many events stored uppercase)
        for (final prefix in [
          query.toUpperCase(),
          query,
          query.substring(0, 1).toUpperCase() + query.substring(1),
        ]) {
          final eventsSnap = await db
              .collection('events')
              .orderBy('name')
              .startAt([prefix])
              .endAt(['$prefix\uf8ff'])
              .limit(10)
              .get();
          for (final doc in eventsSnap.docs) {
            if (seen.add(doc.id)) {
              results.add({
                'type': 'event',
                'id': doc.id,
                'title': doc.data()['name'] ?? 'Event',
                'subtitle': doc.data()['venue'] ?? doc.data()['date'] ?? '',
                'imageUrl': doc.data()['imageUrl'],
                'route': '/event/${doc.id}',
              });
            }
          }
          if (results.where((r) => r['type'] == 'event').length >= 10) break;
        }
      }

      // Search Gyms
      if (_selectedCategory == 'all' || _selectedCategory == 'gyms') {
        final gymsSnap = await db
            .collection('gyms')
            .orderBy('name')
            .startAt([query])
            .endAt(['$query\uf8ff'])
            .limit(10)
            .get();
        for (final doc in gymsSnap.docs) {
          results.add({
            'type': 'gym',
            'id': doc.id,
            'title': doc.data()['name'] ?? 'Gym',
            'subtitle': doc.data()['city'] ?? doc.data()['region'] ?? '',
            'imageUrl': doc.data()['logoUrl'],
            'route': '/gym/${doc.id}',
          });
        }
      }

      // Search News/Feed
      if (_selectedCategory == 'all' || _selectedCategory == 'news') {
        final newsSnap = await db
            .collection('feed_content')
            .where('status', isEqualTo: 'published')
            .orderBy('title')
            .startAt([query])
            .endAt(['$query\uf8ff'])
            .limit(10)
            .get();
        for (final doc in newsSnap.docs) {
          results.add({
            'type': 'news',
            'id': doc.id,
            'title': doc.data()['title'] ?? 'Article',
            'subtitle': doc.data()['source'] ?? '',
            'imageUrl': doc.data()['imageUrl'],
            'route': '/article/${doc.id}',
          });
        }
      }

      // Search Users
      if (_selectedCategory == 'all' || _selectedCategory == 'users') {
        final usersSnap = await db
            .collection('users')
            .orderBy('displayName')
            .startAt([query])
            .endAt(['$query\uf8ff'])
            .limit(10)
            .get();
        for (final doc in usersSnap.docs) {
          results.add({
            'type': 'user',
            'id': doc.id,
            'title': doc.data()['displayName'] ?? 'User',
            'subtitle': doc.data()['role'] ?? 'Member',
            'imageUrl': doc.data()['photoUrl'],
            'route': '/profile/${doc.id}',
          });
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
    }

    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'fighter':
        return Icons.sports_mma;
      case 'event':
        return Icons.event;
      case 'gym':
        return Icons.fitness_center;
      case 'news':
        return Icons.newspaper;
      case 'user':
        return Icons.person;
      default:
        return Icons.search;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'fighter':
        return AppTheme.neonCyan;
      case 'event':
        return AppTheme.neonPurple;
      case 'gym':
        return AppTheme.neonGreen;
      case 'news':
        return AppTheme.neonOrange;
      case 'user':
        return AppTheme.neonPink;
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            color: const Color(0xFF0A0E1A),
            border: Border.all(
              color: AppTheme.neonCyan.withValues(alpha: 0.4),
            ),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search fighters, events, gyms...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 15,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: AppTheme.neonCyan.withValues(alpha: 0.7),
                size: 20,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 18,
                      ),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _results = []);
                      },
                    )
                  : null,
            ),
            textInputAction: TextInputAction.search,
            onChanged: (_) => _debouncer.run(_performSearch),
            onSubmitted: (_) => _performSearch(),
          ),
        ),
      ),
      body: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat['icon'] as IconData,
                          size: 14,
                          color: isSelected ? Colors.black : Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          cat['label'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF0A0E1A),
                    selectedColor: AppTheme.neonCyan,
                    checkmarkColor: Colors.black,
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.neonCyan
                          : AppTheme.neonCyan.withValues(alpha: 0.3),
                    ),
                    onSelected: (_) {
                      setState(() => _selectedCategory = cat['id'] as String);
                      _lastQuery = null;
                      _performSearch();
                    },
                  ),
                );
              },
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.neonCyan,
                      strokeWidth: 2,
                    ),
                  )
                : _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _controller.text.isEmpty
                              ? 'Start typing to search'
                              : 'No results found',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      final color = _colorForType(item['type'] as String);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF0A0E1A),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: ListTile(
                          onTap: () {
                            final route = item['route'] as String?;
                            if (route != null) context.push(route);
                          },
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: color.withValues(alpha: 0.15),
                              border: Border.all(
                                color: color.withValues(alpha: 0.4),
                              ),
                            ),
                            child: item['imageUrl'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(9),
                                    child: DfcNetworkImage(
                                      url: item['imageUrl'] as String,
                                    ),
                                  )
                                : Icon(
                                    _iconForType(item['type'] as String),
                                    color: color,
                                    size: 22,
                                  ),
                          ),
                          title: Text(
                            item['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            item['subtitle'] as String,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: color.withValues(alpha: 0.15),
                            ),
                            child: Text(
                              (item['type'] as String).toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
