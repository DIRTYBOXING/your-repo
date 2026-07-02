import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../core/constants/image_assets.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/glass_panel.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/services/feed_prioritization_service.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/widgets/dfc_network_image.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC EVENT CARD — AI Bruce Buffer style event promotion in feed
///
/// • Dynamic hype messages ("🔴 LIVE NOW!", "🚨 IT'S FIGHT DAY!")
/// • Location badges with country flags
/// • Urgency styling based on event proximity
/// • Matches DFCPostCard design pattern
/// ═══════════════════════════════════════════════════════════════════════════
class DFCEventCard extends StatefulWidget {
  final EventModel event;
  final String? userCity;
  final String? userState;
  final String? userCountry;
  final VoidCallback? onTap;

  const DFCEventCard({
    super.key,
    required this.event,
    this.userCity,
    this.userState,
    this.userCountry,
    this.onTap,
  });

  @override
  State<DFCEventCard> createState() => _DFCEventCardState();
}

class _DFCEventCardState extends State<DFCEventCard> {
  late final FeedPrioritizationService _prioritizationService;
  bool _depsInit = false;
  bool _isReminded = false;

  EventModel get event => widget.event;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_depsInit) {
      _depsInit = true;
      _prioritizationService = FeedPrioritizationService();
      _checkReminderStatus();
    }
  }

  /// Check Firestore for existing reminder so bell persists across rebuilds
  Future<void> _checkReminderStatus() async {
    final userId = context.read<AuthService>().currentUser?.uid;
    if (userId == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('event_reminders')
          .doc('${userId}_${event.id}')
          .get();
      if (mounted && doc.exists) {
        setState(() => _isReminded = true);
      }
    } catch (_) {}
  }

  Color get _sportColor {
    switch (event.sportType?.toLowerCase()) {
      case 'mma':
        return DesignTokens.neonCyan;
      case 'bkfc':
        return const Color(0xFFFF6B00);
      case 'boxing':
        return const Color(0xFFFFD700);
      case 'kickboxing':
        return const Color(0xFFE84393);
      case 'pro wrestling':
        return const Color(0xFF9D00FF);
      default:
        return DesignTokens.neonCyan;
    }
  }

  Color get _urgencyColor {
    final urgency = _prioritizationService.getUrgencyLevel(
      event: event,
      currentTime: DateTime.now(),
    );
    switch (urgency) {
      case 3: // Live/today
        return Colors.red;
      case 2: // Tomorrow/next few days
        return DesignTokens.neonMagenta;
      case 1: // This week
        return DesignTokens.neonCyan;
      default:
        return DesignTokens.neonGreen;
    }
  }

  String get _resolvedPosterUrl {
    final currentPoster = event.primaryThumbnailUrl?.trim();
    if (currentPoster != null &&
        currentPoster.isNotEmpty &&
        !ImageAssets.isGenericPosterAsset(currentPoster)) {
      if (ImageAssets.isSpecificEventPosterAsset(currentPoster)) {
        return ImageAssets.posterVariantFromUrl(
          currentPoster,
          variant: 'banner',
        );
      }
      return currentPoster;
    }
    return ImageAssets.posterAssetForEventMetadataVariant(
          eventId: event.id,
          title: event.name,
          promoter: event.promotionName ?? event.promoterId,
          eventDate: event.eventDate,
          streamUrl: event.streamUrl,
          ticketUrl: event.ticketUrl,
          variant: 'banner',
        ) ??
        ImageAssets.posterForSport(event.sportType);
  }

  String _formatEventDateTime() {
    final date = event.eventDate;
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.inHours.abs() < 2) {
      return 'Now';
    } else if (diff.inDays == 0) {
      return 'Today • ${DateFormat('h:mm a').format(date)}';
    } else if (diff.inDays == 1) {
      return 'Tomorrow • ${DateFormat('h:mm a').format(date)}';
    } else if (diff.inDays <= 7) {
      return '${DateFormat('EEEE').format(date)} • ${DateFormat('h:mm a').format(date)}';
    } else {
      return '${DateFormat('MMM dd').format(date)} • ${DateFormat('h:mm a').format(date)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hypeMessage = _prioritizationService.generateHypeMessage(
      event: event,
      currentTime: DateTime.now(),
    );
    final urgency = _prioritizationService.getUrgencyLevel(
      event: event,
      currentTime: DateTime.now(),
    );

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: GlassPanel(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        backgroundColor: DesignTokens.bgCard,
        borderColor: urgency >= 2
            ? _urgencyColor.withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.06),
        borderWidth: urgency >= 2 ? 1.5 : DesignTokens.borderThin,
        shadows: urgency >= 2
            ? [
                BoxShadow(
                  color: _urgencyColor.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Row(
                children: [
                  // Event Type Icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _sportColor.withValues(alpha: 0.8),
                          _sportColor.withValues(alpha: 0.4),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _sportColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(_getSportIcon(), color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sport Type
                        Text(
                          event.sportType?.toUpperCase() ?? 'EVENT',
                          style: TextStyle(
                            color: _sportColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Event Name
                        Text(
                          event.name,
                          style: const TextStyle(
                            color: DesignTokens.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Live/Status Badge
                  if (event.status == EventStatus.live)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.5),
                            blurRadius: 8,
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
                          const SizedBox(width: 6),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ── Hype Message (AI Bruce Buffer Style) ──
            if (hypeMessage.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _urgencyColor.withValues(alpha: 0.15),
                      _urgencyColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _urgencyColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      urgency >= 3
                          ? Icons.campaign
                          : urgency >= 2
                          ? Icons.notifications_active
                          : Icons.event,
                      color: _urgencyColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hypeMessage,
                        style: TextStyle(
                          color: _urgencyColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Event Poster Image ──
            _buildEventImage(),

            // ── Sponsor Strip ──
            if (event.sponsors.isNotEmpty) _buildSponsorStrip(),

            // ── Action Buttons ──
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.confirmation_number_outlined,
                      label: 'Tickets',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/ticket-purchase/${event.id}');
                      },
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  Expanded(
                    child: _buildActionButton(
                      icon: _isReminded
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      label: _isReminded ? 'Reminded' : 'Remind',
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        final messenger = ScaffoldMessenger.of(context);
                        final userId = context
                            .read<AuthService>()
                            .currentUser
                            ?.uid;

                        // Save to Firestore if authenticated
                        if (userId != null) {
                          try {
                            await FirebaseFirestore.instance
                                .collection('event_reminders')
                                .doc('${userId}_${event.id}')
                                .set({
                                  'userId': userId,
                                  'eventId': event.id,
                                  'eventTitle': event.title,
                                  'eventStartTime': event.eventDate,
                                  'reminderTime': event.eventDate.subtract(
                                    const Duration(hours: 1),
                                  ),
                                  'notificationSent': false,
                                  'timestamp': FieldValue.serverTimestamp(),
                                });
                          } catch (_) {
                            // Firestore write failed — still show local confirmation
                          }
                        }

                        setState(() => _isReminded = true);
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                '🔔 Reminder set for ${event.title}!',
                              ),
                              backgroundColor: DesignTokens.neonMagenta,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        final eventDate = DateFormat(
                          'MMM d, yyyy',
                        ).format(event.eventDate);
                        final eventTime = DateFormat(
                          'h:mm a',
                        ).format(event.eventDate);
                        final shareText =
                            '🥊 ${event.name}\n'
                            '📅 $eventDate at $eventTime\n'
                            '📍 ${event.venue}, ${event.city}\n'
                            'Check it out on DataFightCentral!';

                        final messenger = ScaffoldMessenger.of(context);
                        final userId = context
                            .read<AuthService>()
                            .currentUser
                            ?.uid;

                        await Clipboard.setData(ClipboardData(text: shareText));

                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                '📋 Event details copied to clipboard!',
                              ),
                              backgroundColor: DesignTokens.neonMagenta,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                        if (userId != null) {
                          try {
                            await FirebaseFirestore.instance
                                .collection('shared_events')
                                .add({
                                  'eventId': event.id,
                                  'eventTitle': event.title,
                                  'sharedBy': userId,
                                  'platform': kIsWeb ? 'clipboard' : 'share',
                                  'timestamp': FieldValue.serverTimestamp(),
                                });
                          } catch (_) {}
                        }
                      },
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

  Widget _buildSponsorStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.white.withValues(alpha: 0.04),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'PRESENTED BY  ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          ...event.sponsors.take(4).map((s) {
            final logoUrl = s['logoUrl'];
            final name = s['name'] ?? '';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: logoUrl != null && logoUrl.isNotEmpty
                  ? DfcNetworkImage(
                      url: logoUrl,
                      height: 16,
                      fit: BoxFit.contain,
                      errorWidget: Text(
                        name.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    )
                  : Text(
                      name.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEventImage() {
    final palette = _eventPosterPalette();
    final dateStr = _formatEventDateTime();

    final posterUrl = _resolvedPosterUrl;
    final hasRealPoster = posterUrl.trim().isNotEmpty;

    return Container(
      height: 200,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Background ──
          // Real poster if available, else sport-specific gradient with DFC branding
          if (hasRealPoster)
            Positioned.fill(
              child: Image(
                image: ImageAssets.resolveImage(posterUrl),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) {
                  debugPrint(
                    '[DFCEventCard] Poster load FAILED for '
                    '"$posterUrl" — $error',
                  );
                  // Fall back to sport-specific gradient
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [palette.bg1, palette.bg2, Colors.black],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [palette.bg1, palette.bg2, Colors.black],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  // Large watermark sport icon
                  Positioned(
                    right: -20,
                    top: -10,
                    child: Icon(
                      _getSportIcon(),
                      size: 160,
                      color: palette.accent.withValues(alpha: 0.08),
                    ),
                  ),
                  // DFC branded corner badge
                  Positioned(
                    left: 0,
                    bottom: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            palette.accent.withValues(alpha: 0.6),
                            palette.accent.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // ── Layer 2: Diagonal slash accent (programmatic only) ──
          if (!hasRealPoster)
            CustomPaint(painter: _EventSlashPainter(color: palette.accent)),

          // ── Layer 4: Full-height gradient scrim (ensures text readability) ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: hasRealPoster ? 0.3 : 0.1),
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.35, 1.0],
              ),
            ),
          ),

          // ── Layer 5: Sport type badge (top-left) with glow ──
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: palette.accent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: palette.accent.withValues(alpha: 0.6),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                event.sportType?.toUpperCase() ?? 'EVENT',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),

          // ── Layer 6: Broadcast badges (top-right) ──
          if (event.broadcastInfo != null && event.broadcastInfo!.isNotEmpty)
            Positioned(
              top: 12,
              right: 12,
              child: _buildBroadcastBadges(event.broadcastInfo!),
            ),

          // ── Layer 7: Event name (center, bold 17pt, drop shadow) ──
          if (!hasRealPoster)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Text(
                  event.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.3,
                    shadows: [
                      Shadow(
                        blurRadius: 8.0,
                        color: Colors.black87,
                        offset: Offset(0, 2),
                      ),
                      Shadow(
                        blurRadius: 16.0,
                        color: Colors.black54,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

          // ── Layer 8: Date/time (bottom-left) ──
          Positioned(
            left: 12,
            bottom: 36,
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black87,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Layer 9: Venue + City (bottom-left, below date) ──
          Positioned(
            left: 12,
            bottom: 12,
            right: 120,
            child: Text(
              event.venue.isNotEmpty
                  ? '${event.venue}, ${event.city}'
                  : '${event.city}, ${event.country}',
              style: TextStyle(
                color: palette.accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                shadows: const [
                  Shadow(
                    blurRadius: 4,
                    color: Colors.black87,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ── Layer 10: Promotion badge (bottom-right) ──
          Positioned(
            right: 10,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: palette.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                event.country,
                style: TextStyle(
                  color: palette.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sport / promotion-aware palette for programmatic poster
  ({Color bg1, Color bg2, Color accent}) _eventPosterPalette() {
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
        name.contains('brawl') ||
        sport == 'bkfc') {
      return (
        bg1: const Color(0xFF1A0A0A),
        bg2: const Color(0xFF0A0A1A),
        accent: const Color(0xFFE53935),
      );
    }
    if (name.contains('boxing') ||
        name.contains('legends') ||
        name.contains('wbc') ||
        sport == 'boxing') {
      return (
        bg1: const Color(0xFF0A2D1A),
        bg2: const Color(0xFF0A0E1A),
        accent: const Color(0xFFFFD700),
      );
    }
    if (name.contains('kickbox') ||
        name.contains('muay thai') ||
        name.contains('k1') ||
        sport == 'kickboxing') {
      return (
        bg1: const Color(0xFF2D1A0A),
        bg2: const Color(0xFF0A0E1A),
        accent: const Color(0xFFFF9800),
      );
    }
    if (name.contains('wrestling') || sport == 'pro wrestling') {
      return (
        bg1: const Color(0xFF1A0A2E),
        bg2: const Color(0xFF0A0E1A),
        accent: const Color(0xFF9D00FF),
      );
    }
    if (name.contains('eternal') || name.contains('cage warriors')) {
      return (
        bg1: const Color(0xFF0A1A2D),
        bg2: const Color(0xFF0A0E1A),
        accent: const Color(0xFF00BCD4),
      );
    }
    return (
      bg1: const Color(0xFF0A1A2D),
      bg2: const Color(0xFF0A0E1A),
      accent: DesignTokens.neonCyan,
    );
  }

  /// Builds branded broadcast badges from comma-separated broadcastInfo.
  /// Each channel gets its own color-coded pill badge.
  Widget _buildBroadcastBadges(String broadcastInfo) {
    final channels = broadcastInfo
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .take(3) // max 3 badges to prevent overflow
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: channels.map((channel) {
        final colors = ImageAssets.broadcastColors(channel);
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: colors.bg.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Text(
              channel,
              style: TextStyle(
                color: colors.fg,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSportIcon() {
    switch (event.sportType?.toLowerCase()) {
      case 'mma':
        return Icons.sports_martial_arts;
      case 'boxing':
        return Icons.sports_kabaddi;
      case 'kickboxing':
        return Icons.sports_martial_arts;
      case 'bkfc':
        return Icons.sports_kabaddi;
      case 'pro wrestling':
        return Icons
            .sports_mma; // Changed from sports_wrestling (doesn't exist)
      default:
        return Icons.sports_mma;
    }
  }
}

/// Diagonal slash accent painter — broadcast-quality cinematic energy
class _EventSlashPainter extends CustomPainter {
  final Color color;
  const _EventSlashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.20),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Main slash
    final path1 = Path()
      ..moveTo(size.width * 0.25, 0)
      ..lineTo(size.width * 0.65, size.height)
      ..lineTo(size.width * 0.75, size.height)
      ..lineTo(size.width * 0.35, 0)
      ..close();
    canvas.drawPath(path1, paint);

    // Secondary thinner slash
    final paint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.10),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path2 = Path()
      ..moveTo(size.width * 0.6, 0)
      ..lineTo(size.width * 0.2, size.height)
      ..lineTo(size.width * 0.27, size.height)
      ..lineTo(size.width * 0.67, 0)
      ..close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _EventSlashPainter oldDelegate) =>
      color != oldDelegate.color;
}
