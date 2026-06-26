import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/ppv_model.dart';
import '../../../shared/services/ppv_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV LIBRARY SCREEN — My Purchased Content
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Kayo "My List" equivalent. Shows all PPV events the user has purchased
/// with watch/replay access, download status, and expiry info.
///
/// Sections:
///   • Currently Live (pulse red)
///   • Ready to Watch (replays)
///   • Expired (greyed out)
///
/// Route: /ppv/library
/// ═══════════════════════════════════════════════════════════════════════════
class PPVLibraryScreen extends StatefulWidget {
  const PPVLibraryScreen({super.key});

  @override
  State<PPVLibraryScreen> createState() => _PPVLibraryScreenState();
}

class _PPVLibraryScreenState extends State<PPVLibraryScreen> {
  final PPVService _ppvService = PPVService();
  bool _isLoading = true;
  List<PPVEvent> _liveEvents = [];
  List<PPVEvent> _replayEvents = [];
  List<PPVEvent> _expiredEvents = [];

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    await _ppvService.loadUserPurchases(uid);
    final purchases = _ppvService.userPurchases;

    final List<PPVEvent> live = [];
    final List<PPVEvent> replay = [];
    final List<PPVEvent> expired = [];

    for (final purchase in purchases) {
      final event = await _ppvService.getPPVEvent(purchase.ppvEventId);
      if (event == null) continue;
      switch (event.status) {
        case PPVStatus.live:
          live.add(event);
        case PPVStatus.replay:
          replay.add(event);
        case PPVStatus.expired:
          expired.add(event);
        default:
          replay.add(event); // Upcoming purchases go to "ready" section
      }
    }

    if (mounted) {
      setState(() {
        _liveEvents = live;
        _replayEvents = replay;
        _expiredEvents = expired;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: DesignTokens.neonCyan),
              ),
            )
          else if (_liveEvents.isEmpty &&
              _replayEvents.isEmpty &&
              _expiredEvents.isEmpty)
            _buildEmptyState()
          else ...[
            if (_liveEvents.isNotEmpty) ...[
              _buildSectionHeader('🔴 Live Now', Colors.red),
              _buildEventList(_liveEvents, isLive: true),
            ],
            if (_replayEvents.isNotEmpty) ...[
              _buildSectionHeader('📺 Ready to Watch', DesignTokens.neonCyan),
              _buildEventList(_replayEvents),
            ],
            if (_expiredEvents.isNotEmpty) ...[
              _buildSectionHeader('⏰ Expired', Colors.grey),
              _buildEventList(_expiredEvents, isExpired: true),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: DesignTokens.bgPrimary,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
      ),
      title: const Text(
        'My PPV Library',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => context.push('/ppv'),
          icon: const Icon(
            Icons.add_circle_outline,
            color: DesignTokens.neonCyan,
            size: 24,
          ),
          tooltip: 'Browse PPV Events',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  SliverToBoxAdapter _buildSectionHeader(String title, Color color) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverList _buildEventList(
    List<PPVEvent> events, {
    bool isLive = false,
    bool isExpired = false,
  }) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildLibraryCard(
          events[index],
          isLive: isLive,
          isExpired: isExpired,
        ),
        childCount: events.length,
      ),
    );
  }

  Widget _buildLibraryCard(
    PPVEvent event, {
    bool isLive = false,
    bool isExpired = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (isLive) {
          context.push('/ppv/${event.id}/watch');
        } else if (!isExpired) {
          context.push('/ppv/event/${event.id}');
        }
      },
      child: Opacity(
        opacity: isExpired ? 0.5 : 1.0,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isLive
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.06),
            ),
            boxShadow: isLive
                ? [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.1),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Left: Poster
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
                child: SizedBox(
                  width: 110,
                  height: 130,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1A0A2E),
                              DesignTokens.bgPrimary,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.sports_mma,
                            size: 36,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      // Play overlay
                      if (!isExpired)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLive
                                  ? Colors.red.withValues(alpha: 0.8)
                                  : Colors.black.withValues(alpha: 0.5),
                            ),
                            child: Icon(
                              isLive ? Icons.live_tv : Icons.play_arrow,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      // Live badge
                      if (isLive)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Right: Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (event.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.subtitle!,
                          style: TextStyle(
                            color: DesignTokens.neonCyan.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 10),
                      // Date + Fights
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, yyyy').format(event.eventDate),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Platforms
                      Row(
                        children: event.streamPlatforms.take(3).map((p) {
                          return Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              p,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              // Watch button
              if (!isExpired)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLive
                          ? Colors.red.withValues(alpha: 0.15)
                          : DesignTokens.neonCyan.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: isLive ? Colors.red : DesignTokens.neonCyan,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  SliverFillRemaining _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DesignTokens.neonCyan.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.live_tv,
                size: 48,
                color: DesignTokens.neonCyan.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No PPV Events Yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Purchase a PPV event to start watching\nlive fights and exclusive replays.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/ppv'),
              icon: const Icon(Icons.sports_mma, size: 18),
              label: const Text('Browse PPV Events'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.neonCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
