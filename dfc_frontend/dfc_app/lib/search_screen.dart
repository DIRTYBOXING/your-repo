import 'package:flutter/material.dart';
import '../../../../dfc_theme.dart';
import '../controllers/search_controller.dart';
import '../models/search_result_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'ALL';

  final List<String> _filters = ['ALL', 'FIGHTERS', 'EVENTS', 'GYMS', 'NEWS'];
  late final SearchController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SearchController();
  }

  void _triggerSearch() {
    _controller.performSearch(_searchQuery, _activeFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            _buildHeader(),
            const SizedBox(height: 24),
            _buildFilters(),
            const SizedBox(height: 24),
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  if (_controller.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentCyan,
                      ),
                    );
                  }
                  if (_controller.error != null) {
                    return Center(
                      child: Text(
                        _controller.error!,
                        style: const TextStyle(color: AppColors.accentRed),
                      ),
                    );
                  }
                  if (_searchQuery.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildResultsState(_controller.results);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              autofocus: true,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _triggerSearch();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search fighters, events, gyms...',
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.normal,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.accentCyan,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _triggerSearch();
                          });
                        },
                      )
                    : const Icon(Icons.mic, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accentCyan),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isActive = _activeFilter == filter;
          return GestureDetector(
            onTap: () {
              setState(() {
                _activeFilter = filter;
                _triggerSearch();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.accentCyan : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppColors.accentCyan : Colors.transparent,
                ),
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isActive ? Colors.black : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      children: [
        _buildSectionHeader(
          Icons.history,
          'RECENT SEARCHES',
          AppColors.textSecondary,
        ),
        _buildRecentSearchItem('Heath Ewart'),
        _buildRecentSearchItem('DFC 2 Location'),
        _buildRecentSearchItem('Elite MMA Gym'),
      ],
    );
  }

  Widget _buildResultsState(List<SearchResultModel> results) {
    if (results.isEmpty) {
      return const Center(
        child: Text(
          "No results found.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      children: results.map((result) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildResultCard(result),
        );
      }).toList(),
    );
  }

  Widget _buildResultCard(SearchResultModel result) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.border,
            backgroundImage: result.imageUrl.isNotEmpty
                ? NetworkImage(result.imageUrl)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  result.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  result.subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearchItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          const Icon(Icons.close, color: AppColors.textMuted, size: 16),
        ],
      ),
    );
  }
}
