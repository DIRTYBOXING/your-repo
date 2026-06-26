import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/enhanced_friends_service.dart';
import '../../../shared/services/friend_suggestions_engine.dart';
import '../../../shared/widgets/dfc_network_image.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FRIEND SUGGESTIONS SCREEN — AI-Powered Recommendations
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Features:
/// - AI-powered friend suggestions with compatibility scores
/// - Visual score indicators (0-100)
/// - Mutual friends display
/// - Reason explanations
/// - Quick add friend button
/// - Pull to refresh suggestions
/// - Location-aware recommendations
/// ═══════════════════════════════════════════════════════════════════════════
class FriendSuggestionsScreen extends StatefulWidget {
  const FriendSuggestionsScreen({super.key});

  @override
  State<FriendSuggestionsScreen> createState() =>
      _FriendSuggestionsScreenState();
}

class _FriendSuggestionsScreenState extends State<FriendSuggestionsScreen> {
  final FriendSuggestionsEngine _suggestionsEngine = FriendSuggestionsEngine();
  List<FriendSuggestion>? _suggestions;
  bool _isLoading = true;
  bool _isRefreshing = false;
  Position? _userPosition;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Try to get user location (optional)
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          _userPosition = await Geolocator.getCurrentPosition();
        }
      } catch (e) {
        // Location not available, continue without it
      }

      // Generate suggestions
      final suggestions = await _suggestionsEngine.generateSuggestions(
        userPosition: _userPosition,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshSuggestions() async {
    if (!mounted) {
      return;
    }
    setState(() => _isRefreshing = true);

    try {
      await _suggestionsEngine.refreshSuggestions(userPosition: _userPosition);
      await _loadSuggestions();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Suggestions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshSuggestions,
            tooltip: 'Refresh suggestions',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Finding great matches for you...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSuggestions,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_suggestions == null || _suggestions!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No suggestions available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Check back later for new recommendations'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshSuggestions,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshSuggestions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _suggestions!.length,
        itemBuilder: (context, index) {
          return SuggestionCard(
            suggestion: _suggestions![index],
            onFriendAdded: () {
              // Remove from list after adding
              setState(() {
                _suggestions!.removeAt(index);
              });
            },
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SUGGESTION CARD — Individual friend suggestion
// ═══════════════════════════════════════════════════════════════════════════
class SuggestionCard extends StatefulWidget {
  final FriendSuggestion suggestion;
  final VoidCallback onFriendAdded;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.onFriendAdded,
  });

  @override
  State<SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<SuggestionCard> {
  bool _isProcessing = false;
  bool _isAdded = false;

  @override
  Widget build(BuildContext context) {
    final suggestion = widget.suggestion;
    final scoreColor = _getScoreColor(suggestion.score);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with score badge
                Stack(
                  children: [
                    DfcCircleAvatar(
                      imageUrl: suggestion.userPhotoUrl,
                      radius: 36,
                      backgroundColor: AppTheme.cardBackground,
                      gradientColors: const [
                        Color(0x3300E5FF),
                        Color(0x3326F596),
                      ],
                      borderColor: Colors.white.withValues(alpha: 0.08),
                      borderWidth: 1,
                      fallbackText: suggestion.userName.isNotEmpty
                          ? suggestion.userName[0].toUpperCase()
                          : '?',
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scoreColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).cardColor,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '${suggestion.score.round()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 16),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _getRoleIcon(suggestion.userRole),
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            suggestion.userRole.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Compatibility score bar
                      _buildScoreBar(suggestion.score, scoreColor),
                    ],
                  ),
                ),
              ],
            ),

            // Reason
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, size: 16, color: scoreColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion.reason,
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Mutual friends
            if (suggestion.mutualFriendsCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.neonCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.neonCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.people,
                      size: 16,
                      color: AppTheme.neonCyan,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${suggestion.mutualFriendsCount} mutual ${suggestion.mutualFriendsCount == 1 ? "friend" : "friends"}',
                      style: const TextStyle(
                        color: AppTheme.neonCyan,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _isAdded
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.success),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: AppTheme.success),
                              SizedBox(width: 8),
                              Text(
                                'Request Sent',
                                style: TextStyle(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _handleAddFriend(context),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add Friend'),
                        ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () {
                    context.push('/user/${suggestion.userId}');
                  },
                  tooltip: 'View Profile',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBar(double score, Color color) {
    final percentage = score / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${score.round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _getScoreLabel(score),
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppTheme.success;
    if (score >= 60) return AppTheme.neonCyan;
    if (score >= 40) return AppTheme.warning;
    return Colors.grey;
  }

  String _getScoreLabel(double score) {
    if (score >= 80) return 'Excellent match';
    if (score >= 60) return 'Great match';
    if (score >= 40) return 'Good match';
    return 'Potential match';
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'fighter':
        return Icons.sports_mma;
      case 'coach':
        return Icons.school;
      case 'judge':
        return Icons.gavel;
      case 'fan':
        return Icons.favorite;
      default:
        return Icons.person;
    }
  }

  Future<void> _handleAddFriend(BuildContext context) async {
    if (_isProcessing) {
      return;
    }
    setState(() => _isProcessing = true);

    final service = context.read<EnhancedFriendsService>();

    try {
      await service.sendFriendRequest(
        recipientId: widget.suggestion.userId,
        message: 'Hi! Found you in friend suggestions. Let\'s connect!',
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _isAdded = true;
        _isProcessing = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Friend request sent to ${widget.suggestion.userName}!',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }

      // Notify parent to remove from list
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          widget.onFriendAdded();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
