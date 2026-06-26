import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: unused_import
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/widgets/dfc_poster_frame.dart';
import '../../ppv/widgets/fight_card_poster.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC LIVE & UPCOMING CAROUSEL — Kayo Sports–style horizontal event strip
///
/// Horizontal scrollable event cards showing LIVE badges, sport colors,
/// event thumbnails, titles, and sport types — just like Kayo/DAZN.
/// ═══════════════════════════════════════════════════════════════════════════
class DFCLiveUpcomingCarousel extends StatelessWidget {
  final List<EventModel> events;
  final void Function(EventModel event)? onEventTap;

  const DFCLiveUpcomingCarousel({
    super.key,
    required this.events,
    this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 380;

    // Sort: live first, then by date ascending
    final sorted = List<EventModel>.from(events)
      ..sort((a, b) {
        if (a.status == EventStatus.live && b.status != EventStatus.live) {
          return -1;
        }
        if (b.status == EventStatus.live && a.status != EventStatus.live) {
          return 1;
        }
        return a.eventDate.compareTo(b.eventDate);
      });

    // Only show upcoming + live (not completed), limit to 10
    final visible = sorted
        .where(
          (e) =>
              e.status == EventStatus.live || e.status == EventStatus.upcoming,
        )
        .take(10)
        .toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Text(
                'Live & Upcoming',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isNarrow ? 18 : 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_left,
                color: Colors.white.withValues(alpha: 0.4),
                size: 22,
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.4),
                size: 22,
              ),
            ],
          ),
        ),

        // ── Horizontal card strip ──
        SizedBox(
          height: isNarrow ? 224 : 216,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: visible.length,
            itemBuilder: (context, index) {
              return _CarouselEventCard(
                event: visible[index],
                onTap: () {
                  HapticFeedback.lightImpact();
                  onEventTap?.call(visible[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Single card in the Live & Upcoming carousel — Kayo style
class _CarouselEventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const _CarouselEventCard({required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLive = event.status == EventStatus.live;
    final isToday = _isToday(event.eventDate);
    final palette = _sportPalette();
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 380;
    final cardWidth = width > 700 ? 216.0 : (isNarrow ? 178.0 : 182.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail area ──
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Event poster image (or auto-generated poster fallback)
                    Positioned.fill(
                      child: DFCPosterFrame(
                        imageUrl: event.primaryPosterUrl,
                        borderRadius: BorderRadius.circular(10),
                        background: DfcEventPoster(event: event),
                        errorWidget: const SizedBox.shrink(),
                        loadingWidget: Container(
                          color: Colors.black.withValues(alpha: 0.16),
                        ),
                      ),
                    ),

                    // Large watermark icon
                    Positioned(
                      right: -15,
                      bottom: -10,
                      child: Icon(
                        _sportIcon(),
                        size: 110,
                        color: palette.accent.withValues(alpha: 0.1),
                      ),
                    ),

                    // Diagonal accent line
                    CustomPaint(
                      painter: _DiagonalAccentPainter(color: palette.accent),
                    ),

                    // Gradient scrim for text readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                          stops: const [0.0, 0.3, 1.0],
                        ),
                      ),
                    ),

                    // ── LIVE / TODAY badge (top-left) ──
                    if (isLive || isToday)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _buildStatusBadge(isLive),
                      ),

                    // ── Broadcast badge (top-right) ──
                    if (event.broadcastInfo != null &&
                        event.broadcastInfo!.isNotEmpty)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.live_tv,
                                size: 10,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _shortBroadcast(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── Event name overlay (bottom) ──
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            event.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isNarrow ? 12 : 13,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              shadows: const [
                                Shadow(
                                  blurRadius: 6,
                                  color: Colors.black87,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _timeLabel(),
                            style: TextStyle(
                              color: palette.accent.withValues(alpha: 0.9),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Below-card text ──
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 10, 2, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isNarrow ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${event.sportType ?? 'Event'} • ${event.city}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: isNarrow ? 10 : 11,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isLive) {
    if (isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.5),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    // TODAY badge
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: DesignTokens.neonAmber.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _isToday(event.eventDate) ? 'TODAY ${_shortTime()}' : _shortTime(),
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _shortTime() {
    return DateFormat('h:mm a').format(event.eventDate);
  }

  String _timeLabel() {
    final now = DateTime.now();
    final diff = event.eventDate.difference(now);

    if (event.status == EventStatus.live) return 'LIVE NOW';
    if (diff.inHours.abs() < 2) return 'Starting Soon';
    if (diff.inDays == 0) return 'Today • ${_shortTime()}';
    if (diff.inDays == 1) return 'Tomorrow • ${_shortTime()}';
    if (diff.inDays <= 7) {
      return '${DateFormat('EEEE').format(event.eventDate)} • ${_shortTime()}';
    }
    return DateFormat('MMM d').format(event.eventDate);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _shortBroadcast() {
    final info = event.broadcastInfo ?? '';
    // Take first channel only
    final first = info.split(',').first.trim();
    return first.length > 12 ? first.substring(0, 12) : first;
  }

  IconData _sportIcon() {
    switch (event.sportType?.toLowerCase()) {
      case 'mma':
        return Icons.sports_mma;
      case 'boxing':
        return Icons.sports_mma;
      case 'bare knuckle':
      case 'bkfc':
        return Icons.front_hand;
      case 'kickboxing':
      case 'muay thai':
        return Icons.sports_kabaddi;
      case 'brawling':
        return Icons.local_fire_department;
      default:
        return Icons.sports_mma;
    }
  }

  ({Color bg1, Color bg2, Color accent}) _sportPalette() {
    final name = event.name.toLowerCase();
    final sport = event.sportType?.toLowerCase() ?? '';

    if (name.contains('ufc') || (sport == 'mma' && !name.contains('eternal'))) {
      return (
        bg1: const Color(0xFF2D0A0A),
        bg2: const Color(0xFF0A0E1A),
        accent: const Color(0xFFD4AF37),
      );
    }
    if (name.contains('bkfc') ||
        name.contains('bare knuckle') ||
        sport == 'bare knuckle' ||
        sport == 'bkfc') {
      return (
        bg1: const Color(0xFF1A0A0A),
        bg2: const Color(0xFF0A0A1A),
        accent: const Color(0xFFE53935),
      );
    }
    if (sport == 'boxing' || name.contains('boxing')) {
      return (
        bg1: const Color(0xFF0A2D1A),
        bg2: const Color(0xFF0A0E1A),
        accent: const Color(0xFFFFD700),
      );
    }
    if (sport == 'kickboxing' || sport == 'muay thai') {
      return (
        bg1: const Color(0xFF2D1A0A),
        bg2: const Color(0xFF0A0E1A),
        accent: const Color(0xFFFF6B00),
      );
    }
    if (name.contains('brawl') || sport == 'brawling') {
      return (
        bg1: const Color(0xFF1A0A2D),
        bg2: const Color(0xFF0A0E1A),
        accent: DesignTokens.neonMagenta,
      );
    }
    if (name.contains('eternal')) {
      return (
        bg1: const Color(0xFF0A1A2D),
        bg2: const Color(0xFF0A0E1A),
        accent: DesignTokens.neonCyan,
      );
    }
    return (
      bg1: const Color(0xFF0A1628),
      bg2: const Color(0xFF050A14),
      accent: DesignTokens.neonCyan,
    );
  }
}

/// Diagonal accent line painter for carousel cards
class _DiagonalAccentPainter extends CustomPainter {
  final Color color;
  _DiagonalAccentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.25),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2.5;

    canvas.drawLine(
      Offset(size.width * 0.8, 0),
      Offset(0, size.height * 0.7),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
