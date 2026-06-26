import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC SEARCH BAR — Expandable search widget for top navigation
/// Compact icon that expands to a search field when tapped

/// ═══════════════════════════════════════════════════════════════════════════
class DFCSearchBar extends StatefulWidget {
  const DFCSearchBar({
    super.key,
    this.collapsedWidth = 40,
    this.expandedWidth = 260,
    this.showFilters = true,
  });

  final double collapsedWidth;
  final double expandedWidth;
  final bool showFilters;

  @override
  State<DFCSearchBar> createState() => _DFCSearchBarState();
}

class _DFCSearchBarState extends State<DFCSearchBar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late AnimationController _animController;
  late Animation<double> _widthAnimation;
  List<String> _suggestions = [];
  final List<String> _filters = ['MMA', 'Brawling', 'Bare Knuckle', 'BKFC'];
  String? _selectedFilter;

  void _updateSuggestions() {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    // Example: static suggestions, can be replaced with API call
    final staticSuggestions = [
      'MMA',
      'Brawling',
      'Bare Knuckle',
      'BKFC',
      'UFC',
      'Boxing',
      'Kickboxing',
      'Muay Thai',
      'Jiu Jitsu',
      'Wrestling',
      'Fight News',
      'Combat Stats',
      'Fighter Rankings',
      'Upcoming Events',
      'Live Streams',
    ];
    setState(() {
      _suggestions = staticSuggestions
          .where((s) => s.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _configureWidthAnimation();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _controller.text.isEmpty) {
        _collapse();
      }
    });
    _controller.addListener(_updateSuggestions);
  }

  @override
  void didUpdateWidget(covariant DFCSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collapsedWidth != widget.collapsedWidth ||
        oldWidget.expandedWidth != widget.expandedWidth) {
      _configureWidthAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _expand() {
    setState(() => _isExpanded = true);
    _animController.forward();
    Future.delayed(const Duration(milliseconds: 100), _focusNode.requestFocus);
  }

  void _collapse() {
    _focusNode.unfocus();
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isExpanded = false;
          _controller.clear();
        });
      }
    });
  }

  void _performSearch() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    _collapse();
    // Navigate to search results with filter
    final filter = _selectedFilter != null
        ? '&filter=${Uri.encodeComponent(_selectedFilter!)}'
        : '';
    context.push('/search?q=${Uri.encodeComponent(query)}$filter');
    _suggestions.clear();
  }

  void _configureWidthAnimation() {
    _widthAnimation =
        Tween<double>(
          begin: widget.collapsedWidth,
          end: widget.expandedWidth,
        ).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
  }

  @override
  Widget build(BuildContext context) {
    final useShellV2 = AppConstants.featureShellV2;
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          constraints: BoxConstraints(
            minHeight: 40,
            maxHeight: _isExpanded ? 300 : 40,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: useShellV2
                ? DesignTokens.shellSurface.withValues(alpha: 0.96)
                : const Color(0xFF0A0E1A).withValues(alpha: 0.95),
            border: Border.all(
              color: useShellV2
                  ? (_isExpanded
                        ? DesignTokens.ppvAccent.withValues(alpha: 0.55)
                        : DesignTokens.shellBorder)
                  : _isExpanded
                  ? AppTheme.neonCyan.withValues(alpha: 0.6)
                  : AppTheme.neonCyan.withValues(alpha: 0.3),
            ),
            boxShadow: !useShellV2 && _isExpanded
                ? [
                    BoxShadow(
                      color: AppTheme.neonCyan.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 38,
                child: Row(
                  children: [
                    // Search icon button
                    GestureDetector(
                      onTap: _isExpanded ? _performSearch : _expand,
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.search,
                          color: useShellV2
                              ? DesignTokens.shellTextMuted
                              : AppTheme.neonCyan.withValues(alpha: 0.9),
                          size: 20,
                        ),
                      ),
                    ),
                    // Expandable text field
                    if (_isExpanded)
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          style: const TextStyle(
                            color: DesignTokens.shellText,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            hintStyle: TextStyle(
                              color: useShellV2
                                  ? DesignTokens.shellTextSubtle
                                  : Colors.white.withValues(alpha: 0.4),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(bottom: 8),
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _performSearch(),
                        ),
                      ),
                    // Close button when expanded
                    if (_isExpanded)
                      GestureDetector(
                        onTap: _collapse,
                        child: Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(right: 4),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.close,
                            color: useShellV2
                                ? DesignTokens.shellTextSubtle
                                : Colors.white.withValues(alpha: 0.5),
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (_isExpanded && widget.showFilters)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((filter) {
                        final selected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              filter,
                              style: TextStyle(
                                color: selected
                                    ? Colors.black
                                    : useShellV2
                                    ? DesignTokens.shellText
                                    : Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            selected: selected,
                            onSelected: (val) {
                              setState(() {
                                _selectedFilter = val ? filter : null;
                              });
                            },
                            selectedColor: useShellV2
                                ? DesignTokens.ppvAccent
                                : AppTheme.neonCyan,
                            backgroundColor: useShellV2
                                ? DesignTokens.shellOverlay
                                : Colors.transparent,
                            side: BorderSide(
                              color: useShellV2
                                  ? DesignTokens.shellBorder
                                  : AppTheme.neonCyan.withValues(alpha: 0.5),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              if (_isExpanded && _suggestions.isNotEmpty)
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: useShellV2
                          ? DesignTokens.shellOverlay
                          : Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: useShellV2
                            ? DesignTokens.shellBorder
                            : AppTheme.neonCyan.withValues(alpha: 0.2),
                      ),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, idx) {
                        final suggestion = _suggestions[idx];
                        return ListTile(
                          title: Text(
                            suggestion,
                            style: const TextStyle(
                              color: DesignTokens.shellText,
                            ),
                          ),
                          onTap: () {
                            _controller.text = suggestion;
                            _performSearch();
                          },
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC SEARCH ICON — Simple search button that opens full search screen
/// ═══════════════════════════════════════════════════════════════════════════
class DFCSearchIcon extends StatelessWidget {
  const DFCSearchIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final useShellV2 = AppConstants.featureShellV2;
    return GestureDetector(
      onTap: () => context.push('/search'),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: useShellV2
              ? DesignTokens.shellSurfaceRaised.withValues(alpha: 0.96)
              : const Color(0xFF0A0E1A).withValues(alpha: 0.9),
          border: Border.all(
            color: useShellV2
                ? DesignTokens.shellBorder
                : AppTheme.neonCyan.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          Icons.search,
          color: useShellV2
              ? DesignTokens.shellTextMuted
              : AppTheme.neonCyan.withValues(alpha: 0.8),
          size: 20,
        ),
      ),
    );
  }
}
