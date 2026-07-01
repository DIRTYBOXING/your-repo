import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

/// COMMUNITY HUB — Browse all fight communities by region.
/// Region directory · Community identity · Watch parties · Local gyms
/// Plugs into existing RegionFeedScreen for individual region deep-dives.
class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen> {
  int _selectedFilter = 0;
  static const _filters = ['ALL', 'ACTIVE', 'TRENDING', 'NEW'];

  static const _communities = [
    _Community(
      name: 'Logan',
      subtitle: 'The Fight Capital of Queensland',
      members: 12400,
      fighters: 84,
      gyms: 12,
      events: 8,
      color: DesignTokens.neonGreen,
      tags: ['BKFC', 'MMA', 'Islanders'],
      trending: true,
      description:
          'Where Islanders breed warriors. Logan backs its own — always.',
    ),
    _Community(
      name: 'Brisbane',
      subtitle: 'Combat Sports Capital',
      members: 8200,
      fighters: 56,
      gyms: 18,
      events: 5,
      color: DesignTokens.neonCyan,
      tags: ['IBC', 'Boxing', 'MMA'],
      trending: false,
      description: 'Australia\'s combat sports heartland. Event central.',
    ),
    _Community(
      name: 'Bronx Islanders',
      subtitle: 'NYC Islander Pride',
      members: 6800,
      fighters: 42,
      gyms: 8,
      events: 3,
      color: DesignTokens.neonMagenta,
      tags: ['Boxing', 'BKFC', 'Community'],
      trending: true,
      description: 'Pacific Islander warriors in the heart of NYC.',
    ),
    _Community(
      name: 'Townsville',
      subtitle: 'North Queensland Combat Hub',
      members: 3400,
      fighters: 28,
      gyms: 6,
      events: 4,
      color: DesignTokens.neonAmber,
      tags: ['BKFC', 'Boxing', 'Events'],
      trending: true,
      description:
          'BKFC Fight Night Australia HQ. April 18 belongs to Townsville.',
    ),
    _Community(
      name: 'Gold Coast',
      subtitle: 'Fight Tourism & Training Camps',
      members: 2100,
      fighters: 19,
      gyms: 10,
      events: 2,
      color: DesignTokens.neonCyan,
      tags: ['Training', 'Tourism', 'MMA'],
      trending: false,
      description: 'World-class training camps meet fight tourism.',
    ),
    _Community(
      name: 'Auckland',
      subtitle: 'NZ Combat Stronghold',
      members: 1800,
      fighters: 15,
      gyms: 7,
      events: 1,
      color: DesignTokens.neonGreen,
      tags: ['MMA', 'Boxing', 'Islanders'],
      trending: false,
      description: 'New Zealand\'s growing fight community.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Row(
          children: [
            Icon(Icons.groups, color: DesignTokens.neonMagenta, size: 22),
            SizedBox(width: 8),
            Text(
              'COMMUNITIES',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white54),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats banner
          _buildStatsBanner(),
          // Filters
          _buildFilters(),
          // Community list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _communities.length,
              itemBuilder: (context, index) =>
                  _buildCommunityCard(_communities[index]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGroupSheet,
        backgroundColor: DesignTokens.neonMagenta,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create Group',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showCreateGroupSheet() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'MMA';
    const types = [
      'MMA',
      'Boxing',
      'BKFC',
      'Muay Thai',
      'BJJ',
      'Wrestling',
      'Kickboxing',
      'General',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Create a Group',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Build your fight community',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  labelStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DesignTokens.neonCyan),
                  ),
                  prefixIcon: const Icon(
                    Icons.group_add,
                    color: DesignTokens.neonCyan,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DesignTokens.neonCyan),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Discipline selector
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: types.map((t) {
                  final selected = t == selectedType;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedType = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? DesignTokens.neonMagenta.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? DesignTokens.neonMagenta
                              : Colors.white12,
                        ),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          color: selected
                              ? DesignTokens.neonMagenta
                              : Colors.white38,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.neonMagenta,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (nameController.text.trim().isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Group "${nameController.text.trim()}" created!',
                          ),
                          backgroundColor: DesignTokens.neonGreen,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Create Group',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonMagenta.withValues(alpha: 0.1),
            DesignTokens.neonCyan.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DesignTokens.neonMagenta.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statCol('6', 'REGIONS', DesignTokens.neonCyan),
          _statCol('34.7K', 'MEMBERS', DesignTokens.neonGreen),
          _statCol('244', 'FIGHTERS', DesignTokens.neonMagenta),
          _statCol('61', 'GYMS', DesignTokens.neonAmber),
        ],
      ),
    );
  }

  Widget _statCol(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white30,
            fontWeight: FontWeight.w700,
            fontSize: 9,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final selected = index == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? DesignTokens.neonMagenta.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected
                      ? DesignTokens.neonMagenta.withValues(alpha: 0.3)
                      : Colors.white10,
                ),
              ),
              child: Text(
                _filters[index],
                style: TextStyle(
                  color: selected ? DesignTokens.neonMagenta : Colors.white30,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommunityCard(_Community c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: c.trending
              ? c.color.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c.color.withValues(alpha: 0.08), Colors.transparent],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: c.color.withValues(alpha: 0.15),
                  child: Text(
                    c.name[0],
                    style: TextStyle(
                      color: c.color,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            c.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          if (c.trending) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: DesignTokens.neonRed.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'TRENDING',
                                style: TextStyle(
                                  color: DesignTokens.neonRed,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 8,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        c.subtitle,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: c.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'JOIN',
                    style: TextStyle(
                      color: c.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              c.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _miniStat(Icons.people, _fmtK(c.members), c.color),
                const SizedBox(width: 16),
                _miniStat(Icons.sports_mma, '${c.fighters}', c.color),
                const SizedBox(width: 16),
                _miniStat(Icons.fitness_center, '${c.gyms}', c.color),
                const SizedBox(width: 16),
                _miniStat(Icons.event, '${c.events}', c.color),
              ],
            ),
          ),
          // Tags
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Wrap(
              spacing: 6,
              children: c.tags.map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: c.color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      color: c.color.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color.withValues(alpha: 0.5), size: 13),
        const SizedBox(width: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white38,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  String _fmtK(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
}

class _Community {
  final String name;
  final String subtitle;
  final int members;
  final int fighters;
  final int gyms;
  final int events;
  final Color color;
  final List<String> tags;
  final bool trending;
  final String description;

  const _Community({
    required this.name,
    required this.subtitle,
    required this.members,
    required this.fighters,
    required this.gyms,
    required this.events,
    required this.color,
    required this.tags,
    required this.trending,
    required this.description,
  });
}
