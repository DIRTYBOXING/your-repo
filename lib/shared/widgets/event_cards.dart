import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/constants/image_assets.dart';
import '../../core/theme/app_theme.dart';
import 'dfc_network_image.dart';
import '../../core/utils/image_url_sanitizer.dart';
import '../../shared/models/event_model.dart';

String _safePosterUrl(String? raw) => ImageUrlSanitizer.sanitize(
  raw,
);

String _resolvedPosterUrl(EventModel event, {String variant = 'hero'}) {
  final currentPoster = event.posterUrl?.trim();
  final useMappedPoster =
      currentPoster == null ||
      currentPoster.isEmpty ||
      ImageAssets.isGenericPosterAsset(currentPoster);
  final raw = useMappedPoster
      ? ImageAssets.posterAssetForEventMetadataVariant(
          eventId: event.id,
          title: event.name,
          promoter: event.promotionName ?? event.promoterId,
          eventDate: event.eventDate,
          streamUrl: event.streamUrl,
          ticketUrl: event.ticketUrl,
          variant: variant,
        )
      : ImageAssets.posterVariantFromUrl(currentPoster, variant: variant);
  return _safePosterUrl(raw);
}

bool _isFireEventModel(EventModel event) {
  final promoter = event.promoterId.toLowerCase();
  final name = event.name.toLowerCase();
  final description = (event.description ?? '').toLowerCase();
  return promoter == 'ibc' ||
      name.contains('ibc') ||
      description.contains('international brawling');
}

DateTime _eventStartTime(EventModel event) =>
    event.mainCardTime ?? event.eventDate;

EventStatus _displayStatus(EventModel event) {
  switch (event.status) {
    case EventStatus.canceled:
    case EventStatus.archived:
    case EventStatus.completed:
    case EventStatus.results:
      return event.status;
    case EventStatus.draft:
    case EventStatus.announced:
    case EventStatus.onSale:
    case EventStatus.upcoming:
    case EventStatus.live:
      final now = DateTime.now();
      final scheduledStart = _eventStartTime(event);
      final liveWindowStart = scheduledStart.subtract(
        const Duration(minutes: 45),
      );
      final liveWindowEnd = scheduledStart.add(const Duration(hours: 6));

      if (now.isAfter(liveWindowEnd)) {
        return EventStatus.completed;
      }

      if (!now.isBefore(liveWindowStart) && !now.isAfter(liveWindowEnd)) {
        return EventStatus.live;
      }

      return EventStatus.upcoming;
  }
}

bool _hasExplicitMainCardTime(EventModel event) => event.mainCardTime != null;

Widget _buildFireSmokeOverlay({bool compact = false}) {
  final smokeAlpha = compact ? 0.12 : 0.16;
  final glowAlpha = compact ? 0.32 : 0.4;
  return IgnorePointer(
    child: Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFFF6A00).withValues(alpha: glowAlpha),
                const Color(0xFFFF2A00).withValues(alpha: glowAlpha * 0.75),
                Colors.black.withValues(alpha: compact ? 0.45 : 0.5),
              ],
              stops: const [0.0, 0.35, 1.0],
            ),
          ),
        ),
        Align(
          alignment: const Alignment(-0.8, -0.7),
          child: Container(
            width: compact ? 110 : 150,
            height: compact ? 70 : 95,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: smokeAlpha),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0.75, -0.45),
          child: Container(
            width: compact ? 120 : 170,
            height: compact ? 80 : 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: smokeAlpha * 0.9),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(-0.15, -0.2),
          child: Container(
            width: compact ? 140 : 200,
            height: compact ? 95 : 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: smokeAlpha * 0.8),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildPosterImage(
  String? raw, {
  required BoxFit fit,
  double? width,
  double? height,
}) {
  final safe = _safePosterUrl(raw);
  if (safe.startsWith('http://') || safe.startsWith('https://')) {
    return DfcNetworkImage(url: safe, fit: fit, width: width, height: height);
  }

  return Image.asset(
    safe,
    fit: fit,
    width: width,
    height: height,
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
  );
}

Color _eventAccentColor(String? sportType) {
  switch (sportType?.toLowerCase()) {
    case 'mma':
      return AppTheme.neonCyan;
    case 'boxing':
      return const Color(0xFFFF5A4F);
    case 'bkfc':
    case 'brawling':
      return const Color(0xFF8E9AAF);
    case 'kickboxing':
      return const Color(0xFFFF8C42);
    case 'pro wrestling':
      return const Color(0xFF9D4EDD);
    case 'muay thai':
      return const Color(0xFFFFB703);
    default:
      return AppTheme.neonCyan;
  }
}

Color _foregroundOn(Color background) =>
    background.computeLuminance() > 0.55 ? Colors.black : Colors.white;

LinearGradient _eventChromeGradient(
  String? sportType, {
  double accentAlpha = 0.18,
}) {
  final accent = _eventAccentColor(sportType);
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      accent.withValues(alpha: accentAlpha),
      const Color(0xFF101826),
      AppTheme.cardBackground,
    ],
    stops: const [0.0, 0.38, 1.0],
  );
}

String _eventMicroLabel(EventModel event) {
  final raw = event.name.trim();
  if (raw.isEmpty) {
    return (event.sportType ?? 'Combat').toUpperCase();
  }

  final primary = raw.contains(':') ? raw.split(':').first : raw;
  final compact = primary.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.length <= 18) {
    return compact.toUpperCase();
  }
  return '${compact.substring(0, 15).trim()}...'.toUpperCase();
}

String _eventLocationLine(EventModel event) {
  final location = [
    if (event.city.isNotEmpty) event.city,
    if (event.country.isNotEmpty) event.country,
  ].join(', ');
  final broadcast = event.broadcastInfo?.trim();
  if (location.isNotEmpty && broadcast != null && broadcast.isNotEmpty) {
    return '$location • $broadcast';
  }
  if (location.isNotEmpty) {
    return location;
  }
  if (broadcast != null && broadcast.isNotEmpty) {
    return broadcast;
  }
  return 'Combat sports event';
}

String _eventScheduleLine(EventModel event) {
  final pattern = _hasExplicitMainCardTime(event)
      ? 'MMM dd • h:mm a'
      : 'MMM dd';
  return DateFormat(pattern).format(_eventStartTime(event));
}

Widget _buildPillChip(
  String label,
  Color color, {
  Color? textColor,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 5,
  ),
}) {
  final foreground = textColor ?? _foregroundOn(color);
  return Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: 0.55)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: foreground,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    ),
  );
}

Widget _buildPosterTile({
  required EventModel event,
  required String posterUrl,
  required double width,
  required double height,
  String? microLabel,
  double radius = 14,
}) {
  final accent = _eventAccentColor(event.sportType);
  final label = microLabel?.trim();
  return Container(
    width: width,
    height: height,
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: _eventChromeGradient(event.sportType, accentAlpha: 0.24),
      border: Border.all(color: accent.withValues(alpha: 0.72), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.2),
          blurRadius: 14,
          spreadRadius: 1,
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius - 2),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildPosterImage(
            posterUrl,
            fit: BoxFit.cover,
            width: width,
            height: height,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.04),
                  Colors.black.withValues(alpha: 0.14),
                  Colors.black.withValues(alpha: 0.5),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.45),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          if (label != null && label.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                color: Colors.black.withValues(alpha: 0.58),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// ═══════════════════════════════════════════════════════════════════════════
/// EVENT CARD WIDGETS - TrillerTV-style event promotion cards
/// ═══════════════════════════════════════════════════════════════════════════

/// Large featured event card for homepage banners
class FeaturedEventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const FeaturedEventCard({super.key, required this.event, this.onTap});
  @override
  Widget build(BuildContext context) {
    final accentColor = _getEventColor(event.sportType);
    final posterUrl = _resolvedPosterUrl(event, variant: 'thumb');
    final status = _displayStatus(event);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 280,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _eventChromeGradient(
            event.sportType,
            accentAlpha: status == EventStatus.live ? 0.24 : 0.18,
          ),
          border: Border.all(color: accentColor.withValues(alpha: 0.22)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (status == EventStatus.live) _buildLiveBadge(),
                        _buildSportBadge(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      event.sportType?.toUpperCase() ?? 'COMBAT SPORTS',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      event.name,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _eventLocationLine(event),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const Spacer(),
                    _buildDateTimeBadge(),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Center(
                child: _buildPosterTile(
                  event: event,
                  posterUrl: posterUrl,
                  width: 128,
                  height: 220,
                  microLabel: _eventMicroLabel(event),
                  radius: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(999),
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
            width: 8,
            height: 8,
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
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportBadge() {
    final accentColor = _getEventColor(event.sportType);
    return _buildPillChip(
      event.sportType ?? 'COMBAT',
      accentColor,
      textColor: _foregroundOn(accentColor),
    );
  }

  Widget _buildDateTimeBadge() {
    final dateFormat = DateFormat('MMM dd');
    final timeFormat = DateFormat('h:mm a');
    final hasExplicitTime = _hasExplicitMainCardTime(event);
    final scheduledStart = _eventStartTime(event);
    final accentColor = _getEventColor(event.sportType);
    final label = hasExplicitTime
        ? '${dateFormat.format(event.eventDate)} | ${timeFormat.format(scheduledStart)}'
        : dateFormat.format(event.eventDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.36)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _getEventColor(String? sportType) {
    switch (sportType?.toLowerCase()) {
      case 'mma':
        return AppTheme.neonCyan;
      case 'bkfc':
        return const Color(0xFFFF6B00);
      case 'boxing':
        return const Color(0xFFFFD700);
      case 'kickboxing':
        return const Color(0xFFE84393);
      case 'pro wrestling':
        return const Color(0xFF9D00FF);
      case 'muay thai':
        return const Color(0xFFFF4757);
      default:
        return AppTheme.neonCyan;
    }
  }
}

/// Compact event card for lists and grids
class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const EventCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = _displayStatus(event);
    final accentColor = _getEventColor(event.sportType);
    final fireMode = _isFireEventModel(event);
    final posterUrl = _resolvedPosterUrl(event, variant: 'thumb');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 132,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                gradient: _eventChromeGradient(
                  event.sportType,
                  accentAlpha: fireMode ? 0.22 : 0.14,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return _buildPosterTile(
                          event: event,
                          posterUrl: posterUrl,
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          microLabel: _eventMicroLabel(event),
                          radius: 10,
                        );
                      },
                    ),
                  ),
                  if (fireMode) _buildFireSmokeOverlay(compact: true),
                  if (status == EventStatus.live)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _buildPillChip(
                        'LIVE',
                        Colors.red,
                        textColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _buildPillChip(
                      (event.sportType ?? 'COMBAT').toUpperCase(),
                      accentColor,
                      textColor: _foregroundOn(accentColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                  if (event.broadcastInfo != null &&
                      event.broadcastInfo!.isNotEmpty)
                    Positioned(
                      left: 6,
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.52),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.broadcastInfo!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatEventDate(event),
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _eventLocationLine(event),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatEventDate(EventModel event) {
    final now = DateTime.now();
    final date = event.eventDate;
    final diff = date.difference(now);
    final hasExplicitTime = _hasExplicitMainCardTime(event);
    final timeLabel = hasExplicitTime
        ? ' | ${DateFormat('h:mm a').format(_eventStartTime(event))}'
        : '';

    if (diff.inDays == 0) {
      return 'Today$timeLabel';
    } else if (diff.inDays == 1) {
      return 'Tomorrow$timeLabel';
    } else {
      return '${DateFormat('MMM dd').format(date)}$timeLabel';
    }
  }

  Color _getEventColor(String? sportType) {
    switch (sportType?.toLowerCase()) {
      case 'mma':
        return AppTheme.neonCyan;
      case 'bkfc':
        return const Color(0xFFFF6B00);
      case 'boxing':
        return const Color(0xFFFFD700);
      case 'kickboxing':
        return const Color(0xFFE84393);
      case 'pro wrestling':
        return const Color(0xFF9D00FF);
      default:
        return AppTheme.neonCyan;
    }
  }
}

/// Live event indicator strip
class LiveEventStrip extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const LiveEventStrip({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = _displayStatus(event);
    final accentColor = _eventAccentColor(event.sportType);
    final tilePosterUrl = _resolvedPosterUrl(event, variant: 'thumb');
    final actionColor = status == EventStatus.live ? accentColor : accentColor;
    final actionTextColor = _foregroundOn(actionColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 98,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: _eventChromeGradient(
            event.sportType,
            accentAlpha: status == EventStatus.live ? 0.24 : 0.18,
          ),
          border: Border(
            bottom: BorderSide(
              color: status == EventStatus.live
                  ? Colors.red.withValues(alpha: 0.82)
                  : accentColor.withValues(alpha: 0.72),
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildPosterTile(
              event: event,
              posterUrl: tilePosterUrl,
              width: 76,
              height: 72,
              microLabel: _eventMicroLabel(event),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (status == EventStatus.live)
                        _buildPillChip(
                          'LIVE',
                          Colors.red,
                          textColor: Colors.white,
                        ),
                      _buildPillChip(
                        (event.sportType ?? 'COMBAT').toUpperCase(),
                        accentColor,
                        textColor: _foregroundOn(accentColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _eventLocationLine(event),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status == EventStatus.live
                        ? 'Live on ${event.broadcastInfo ?? 'DFC'}'
                        : _eventScheduleLine(event),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accentColor.withValues(alpha: 0.92),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: actionColor,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: actionColor.withValues(alpha: 0.28),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                status == EventStatus.live ? 'WATCH' : 'DETAILS',
                style: TextStyle(
                  color: actionTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// EVENT CONVEYOR BELT — Living timeline where events flow through lifecycle
// New events build up → approaching events glow → LIVE events pulse →
// finished events fade out as new ones take their place
// ══════════════════════════════════════════════════════════════════════════════

/// Lifecycle phase for an event on the conveyor belt
enum _EventPhase { distant, approaching, imminent, live, recent, faded }

class EventConveyorBelt extends StatefulWidget {
  final List<EventModel> events;
  final void Function(EventModel)? onEventTap;

  const EventConveyorBelt({super.key, required this.events, this.onEventTap});

  @override
  State<EventConveyorBelt> createState() => _EventConveyorBeltState();
}

class _EventConveyorBeltState extends State<EventConveyorBelt>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _pulse;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _pulse = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _glow = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  static _EventPhase _phaseOf(EventModel e) {
    final now = DateTime.now();
    if (e.status == EventStatus.live) return _EventPhase.live;
    if (e.status == EventStatus.completed) {
      final ago = now.difference(e.eventDate);
      return ago.inHours < 48 ? _EventPhase.recent : _EventPhase.faded;
    }
    final until = e.eventDate.difference(now);
    if (until.isNegative) return _EventPhase.recent;
    if (until.inHours < 24) return _EventPhase.imminent;
    if (until.inDays < 7) return _EventPhase.approaching;
    return _EventPhase.distant;
  }

  static double _opacityFor(_EventPhase phase, double glowVal) {
    switch (phase) {
      case _EventPhase.live:
        return 1.0;
      case _EventPhase.imminent:
        return 0.85 + 0.15 * glowVal;
      case _EventPhase.approaching:
        return 0.7;
      case _EventPhase.distant:
        return 0.4;
      case _EventPhase.recent:
        return 0.25;
      case _EventPhase.faded:
        return 0.10;
    }
  }

  static double _scaleFor(_EventPhase phase) {
    switch (phase) {
      case _EventPhase.live:
        return 1.0;
      case _EventPhase.imminent:
        return 0.98;
      case _EventPhase.approaching:
        return 0.95;
      case _EventPhase.distant:
        return 0.88;
      case _EventPhase.recent:
        return 0.82;
      case _EventPhase.faded:
        return 0.75;
    }
  }

  static Color _glowColorFor(EventModel e, _EventPhase phase) {
    if (phase == _EventPhase.live) return Colors.red;
    if (phase == _EventPhase.imminent) return const Color(0xFFFF0080);
    final sport = (e.sportType ?? '').toLowerCase();
    switch (sport) {
      case 'mma':
        return AppTheme.neonCyan;
      case 'boxing':
        return const Color(0xFFFFD700);
      case 'bkfc':
      case 'brawling':
        return const Color(0xFFFF6B00);
      case 'kickboxing':
        return const Color(0xFFE84393);
      case 'muay thai':
        return const Color(0xFFFF4757);
      default:
        return AppTheme.neonCyan;
    }
  }

  String _timeLabel(EventModel e) {
    final now = DateTime.now();
    if (e.status == EventStatus.live) return 'LIVE NOW';
    if (e.status == EventStatus.completed) {
      final ago = now.difference(e.eventDate);
      if (ago.inHours < 1) return 'JUST ENDED';
      if (ago.inHours < 24) return '${ago.inHours}h AGO';
      if (ago.inDays < 7) return '${ago.inDays}d AGO';
      return 'COMPLETED';
    }
    final until = e.eventDate.difference(now);
    if (until.isNegative) return 'ENDED';
    if (until.inHours < 1) return 'STARTING';
    if (until.inHours < 24) return '${until.inHours}h';
    if (until.inDays < 7) return '${until.inDays}d';
    if (until.inDays < 30) return '${until.inDays}d';
    return '${(until.inDays / 7).floor()}w';
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<EventModel>.from(widget.events);
    sorted.sort((a, b) {
      final orderA = _sortOrder(_phaseOf(a));
      final orderB = _sortOrder(_phaseOf(b));
      if (orderA != orderB) return orderA.compareTo(orderB);
      return a.eventDate.compareTo(b.eventDate);
    });

    final visible = sorted
        .where((e) => _phaseOf(e) != _EventPhase.faded)
        .toList();

    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _glow]),
      builder: (context, _) {
        return SizedBox(
          height: 195,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final event = visible[index];
              final phase = _phaseOf(event);
              final opacity = _opacityFor(phase, _glow.value);
              final scale = _scaleFor(phase);
              final glowColor = _glowColorFor(event, phase);
              final isLive = phase == _EventPhase.live;
              final isRecent = phase == _EventPhase.recent;
              final posterUrl = _resolvedPosterUrl(event, variant: 'thumb');

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onEventTap?.call(event);
                },
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: opacity,
                  child: Transform.scale(
                    scale: isLive ? scale * _pulse.value : scale,
                    child: Container(
                      width: 155,
                      margin: const EdgeInsets.only(
                        right: 12,
                        top: 4,
                        bottom: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isLive
                              ? Colors.red.withValues(
                                  alpha: 0.6 + 0.4 * _glow.value,
                                )
                              : isRecent
                              ? Colors.white.withValues(alpha: 0.05)
                              : glowColor.withValues(
                                  alpha: 0.12 + 0.08 * _glow.value,
                                ),
                          width: isLive ? 2 : 1,
                        ),
                        boxShadow: [
                          if (isLive)
                            BoxShadow(
                              color: Colors.red.withValues(
                                alpha: 0.35 * _glow.value,
                              ),
                              blurRadius: 16,
                              spreadRadius: 2,
                            )
                          else if (phase == _EventPhase.imminent)
                            BoxShadow(
                              color: glowColor.withValues(
                                alpha: 0.25 * _glow.value,
                              ),
                              blurRadius: 12,
                              spreadRadius: 1,
                            )
                          else if (phase == _EventPhase.approaching)
                            BoxShadow(
                              color: glowColor.withValues(alpha: 0.12),
                              blurRadius: 8,
                            ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: _eventChromeGradient(
                                    event.sportType,
                                    accentAlpha: isLive
                                        ? 0.24
                                        : isRecent
                                        ? 0.06
                                        : 0.14,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: _buildPosterTile(
                                event: event,
                                posterUrl: posterUrl,
                                width: 50,
                                height: 66,
                                radius: 10,
                              ),
                            ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.15),
                                      Colors.black.withValues(alpha: 0.38),
                                      Colors.black.withValues(alpha: 0.82),
                                    ],
                                    stops: const [0.0, 0.45, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      glowColor.withValues(
                                        alpha: isLive
                                            ? 0.18 + 0.08 * _glow.value
                                            : isRecent
                                            ? 0.03
                                            : 0.08,
                                      ),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (isRecent)
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.4),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                12,
                                72,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      _buildPhaseIndicator(phase, glowColor),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _timeLabel(event),
                                          style: TextStyle(
                                            color: isLive
                                                ? Colors.red
                                                : isRecent
                                                ? Colors.white38
                                                : glowColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    (event.sportType ?? 'COMBAT').toUpperCase(),
                                    style: TextStyle(
                                      color: glowColor.withValues(
                                        alpha: isRecent ? 0.3 : 0.78,
                                      ),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    event.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isRecent
                                          ? Colors.white38
                                          : Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${event.city}${event.country.isNotEmpty ? ', ${event.country}' : ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: isRecent ? 0.15 : 0.5,
                                      ),
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat(
                                      'MMM dd',
                                    ).format(event.eventDate),
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: isRecent ? 0.15 : 0.42,
                                      ),
                                      fontSize: 9,
                                    ),
                                  ),
                                  if (event.broadcastInfo != null &&
                                      !isRecent) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.28,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        event.broadcastInfo!.length > 14
                                            ? '${event.broadcastInfo!.substring(0, 12)}...'
                                            : event.broadcastInfo!,
                                        style: TextStyle(
                                          color: glowColor.withValues(
                                            alpha: 0.88,
                                          ),
                                          fontSize: 8,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPhaseIndicator(_EventPhase phase, Color color) {
    switch (phase) {
      case _EventPhase.live:
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.6 * _glow.value),
                blurRadius: 8,
                spreadRadius: 2 * _glow.value,
              ),
            ],
          ),
        );
      case _EventPhase.imminent:
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5 * _glow.value),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      case _EventPhase.approaching:
        return Icon(
          Icons.schedule,
          size: 11,
          color: color.withValues(alpha: 0.9),
        );
      case _EventPhase.distant:
        return Icon(
          Icons.circle_outlined,
          size: 9,
          color: color.withValues(alpha: 0.6),
        );
      case _EventPhase.recent:
        return const Icon(Icons.history, size: 10, color: Colors.white24);
      case _EventPhase.faded:
        return const SizedBox.shrink();
    }
  }

  static int _sortOrder(_EventPhase phase) {
    switch (phase) {
      case _EventPhase.live:
        return 0;
      case _EventPhase.imminent:
        return 1;
      case _EventPhase.approaching:
        return 2;
      case _EventPhase.distant:
        return 3;
      case _EventPhase.recent:
        return 4;
      case _EventPhase.faded:
        return 5;
    }
  }
}
