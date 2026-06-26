import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/image_assets.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/ppv_model.dart';
import '../../../shared/models/ppv_presentation_model.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/widgets/dfc_poster_frame.dart';

// ═══════════════════════════════════════════════════════════════════════════
// FIGHT CARD POSTER — Data-driven, zero external assets needed.
//
// Builds a premium event poster from the data you already have:
// fighters, date, venue, price, sport. No ghost files, no placeholders.
// UFC / DAZN / Kayo quality — the event IS the poster.
// ═══════════════════════════════════════════════════════════════════════════

/// Full PPV fight card poster with title, date, venue, price, fighters.
class FightCardPoster extends StatelessWidget {
  final PPVEvent event;
  final PPVPresentationModel presentation;
  final double? width;
  final double? height;
  final bool showPrice;
  final bool showHeader;
  final bool showStatusBadge;
  final bool showUndercard;
  final bool showFooter;

  FightCardPoster({
    super.key,
    required this.event,
    PPVPresentationModel? presentation,
    this.width,
    this.height,
    this.showPrice = true,
    this.showHeader = true,
    this.showStatusBadge = true,
    this.showUndercard = true,
    this.showFooter = true,
  }) : presentation = presentation ?? PPVPresentationModel.fromEvent(event);

  String? _resolvedPosterUrl() {
    final posterUrl = presentation.posterUrl;
    if (posterUrl != null &&
        posterUrl.isNotEmpty &&
        !ImageAssets.isGenericPosterAsset(posterUrl)) {
      return posterUrl;
    }

    return ImageAssets.posterAssetForEventMetadata(
      eventId: event.eventId,
      title: event.title,
      promoter: event.promotion,
      eventDate: event.eventDate,
      streamUrl: event.streamUrl,
      ticketUrl: event.ticketUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = eventPaletteForTitle(event.title);
    final mainEvent = event.fightCard.isNotEmpty
        ? event.fightCard.firstWhere(
            (f) => f.isMainEvent,
            orElse: () => event.fightCard.first,
          )
        : null;
    final dateStr = DateFormat('E, MMM d, yyyy').format(event.eventDate);
    final timeStr = DateFormat('h:mm a').format(event.eventDate);

    final posterUrl = _resolvedPosterUrl();
    final usePosterImage = posterUrl != null && posterUrl.isNotEmpty;
    if (!usePosterImage) {
      return SizedBox(
        width: width,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF101826), Color(0xFF060B12)],
            ),
            border: Border.all(color: palette.accent.withValues(alpha: 0.18)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported_outlined,
                    size: 42,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Official poster pending',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$dateStr • $timeStr',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final resolvedShowHeader = showHeader;
    final resolvedShowStatusBadge = showStatusBadge;
    final resolvedShowUndercard = showUndercard;
    final resolvedShowFooter = showFooter;

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.4,
            colors: [
              palette.accent.withValues(alpha: 0.35),
              palette.bg1,
              palette.bg2,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: DFCPosterFrame(
                imageUrl: posterUrl,
                borderRadius: BorderRadius.zero,
                loadingWidget: Container(
                  color: Colors.black.withValues(alpha: 0.18),
                ),
                errorWidget: const SizedBox.shrink(),
              ),
            ),

            // ── TOP: Event title + promotion ──
            if (resolvedShowHeader)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (event.sport != null || event.promotion != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: palette.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: palette.accent.withValues(alpha: 0.5),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            (event.promotion ?? event.sport ?? '')
                                .toUpperCase(),
                            style: TextStyle(
                              color: palette.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ),
                      Text(
                        event.title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (event.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          event.subtitle!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // ── STATUS BADGE (top-right) ──
            if (resolvedShowStatusBadge)
              Positioned(
                top: 6,
                right: 8,
                child: _StatusBadge(status: event.status),
              ),

            // ── CENTER: Fighters VS ──
            if (mainEvent != null) ...[
              // Weight class tag
              Positioned(
                top: (height ?? 200) * 0.35,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: palette.accent.withValues(alpha: 0.4),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      mainEvent.isTitleFight
                          ? '${mainEvent.weightClass.toUpperCase()} TITLE'
                          : mainEvent.weightClass.toUpperCase(),
                      style: TextStyle(
                        color: palette.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
              ),
              // Fighter 1
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: SizedBox(
                    width: 80,
                    child: Text(
                      mainEvent.fighter1Name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              // VS badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: palette.accent,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: palette.accent.withValues(alpha: 0.6),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Text(
                    'VS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
              // Fighter 2
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: SizedBox(
                    width: 80,
                    child: Text(
                      mainEvent.fighter2Name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ] else
              // No fight card — show title centered large
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    palette.icon,
                    size: 40,
                    color: palette.accent.withValues(alpha: 0.3),
                  ),
                ),
              ),

            // ── UNDERCARD (between center and bottom) ──
            if (resolvedShowUndercard && event.fightCard.length > 1)
              Positioned(
                left: 8,
                right: 8,
                bottom: (showPrice ? 72 : 50),
                child: _UndercardStrip(
                  fights: event.fightCard,
                  accent: palette.accent,
                ),
              ),

            // ── SPONSOR STRIP ──
            if (resolvedShowFooter && event.sponsors.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom:
                    (showPrice ? 72 : 50) +
                    (event.fightCard.length > 1 ? 28 : 0),
                child: _SponsorStrip(sponsors: event.sponsors),
              ),

            // ── BOTTOM: Date, venue, price — the sell ──
            if (resolvedShowFooter)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.95),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Date + time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$dateStr  \u2022  $timeStr',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Venue + platforms
                      if (event.streamPlatforms.isNotEmpty)
                        Text(
                          event.streamPlatforms.join(' \u2022 '),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      // Price badge + CTA + fight count
                      if (showPrice || event.fightCard.length > 1) ...[
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (showPrice)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      palette.accent,
                                      palette.accent.withValues(alpha: 0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: palette.accent.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  event.priceDisplay,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            if (showPrice && event.fightCard.length > 1)
                              const SizedBox(width: 8),
                            if (event.fightCard.length > 1)
                              Text(
                                '${event.fightCard.length} BOUTS',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                          ],
                        ),
                      ],
                      // BUY / WATCH CTA
                      if (showPrice) ...[
                        const SizedBox(height: 5),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                palette.accent,
                                palette.accent.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: palette.accent.withValues(alpha: 0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Text(
                            event.status == PPVStatus.live
                                ? 'WATCH LIVE NOW'
                                : 'BUY PPV \u2022 ${event.priceDisplay}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                      // DFC branding
                      const SizedBox(height: 4),
                      Text(
                        'DATAFIGHTCENTRAL.COM',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STATUS BADGE — PPV event status indicator (PRESALE, ON SALE, LIVE, etc.)
// ═══════════════════════════════════════════════════════════════════════════
class _StatusBadge extends StatelessWidget {
  final PPVStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (status) {
      PPVStatus.announced => ('ANNOUNCED', Colors.blueGrey),
      PPVStatus.presale => ('PRESALE', DesignTokens.neonAmber),
      PPVStatus.onSale => ('ON SALE', DesignTokens.neonGreen),
      PPVStatus.live => ('● LIVE', Colors.red),
      PPVStatus.replay => ('REPLAY', DesignTokens.neonCyan),
      PPVStatus.expired => ('ENDED', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// UNDERCARD STRIP — Compact listing of non-main-event bouts.
// ═══════════════════════════════════════════════════════════════════════════
class _UndercardStrip extends StatelessWidget {
  final List<PPVFight> fights;
  final Color accent;
  const _UndercardStrip({required this.fights, required this.accent});

  @override
  Widget build(BuildContext context) {
    final undercard = fights.where((f) => !f.isMainEvent).take(3).toList();
    if (undercard.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 30, height: 0.5, color: accent.withValues(alpha: 0.3)),
        const SizedBox(height: 3),
        ...undercard.map(
          (f) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              '${f.fighter1Name.split(' ').last.toUpperCase()} vs '
              '${f.fighter2Name.split(' ').last.toUpperCase()}'
              '${f.isTitleFight ? ' ★' : ''}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EVENT POSTER — For EventModel (carousel, feed, legends, events tab).
// Same premium look, built from EventModel fields.
// ═══════════════════════════════════════════════════════════════════════════
class DfcEventPoster extends StatelessWidget {
  final EventModel event;
  final double? width;
  final double? height;

  const DfcEventPoster({
    super.key,
    required this.event,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final palette = eventPaletteForTitle(
      '${event.name} ${event.sportType ?? ''} ${event.promotionName ?? ''}',
    );
    final dateStr = DateFormat('E, MMM d').format(event.eventDate);
    final timeStr = event.mainCardTime != null
        ? DateFormat('h:mm a').format(event.mainCardTime!)
        : DateFormat('h:mm a').format(event.eventDate);

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.4,
            colors: [
              palette.accent.withValues(alpha: 0.30),
              palette.bg1,
              palette.bg2,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Branded background image
            Positioned.fill(
              child: Opacity(
                opacity: 0.35,
                child: Image.asset(
                  ImageAssets.posterForSport(event.sportType ?? 'MMA'),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Image.asset(
                    ImageAssets.dfcBrandedPlaceholder,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            // Slash accents
            Positioned.fill(
              child: CustomPaint(
                painter: _FightSlashPainter(color: palette.accent),
              ),
            ),
            // Watermark icon
            Positioned(
              right: -15,
              bottom: -10,
              child: Icon(
                palette.icon,
                size: (height ?? 160) * 0.5,
                color: palette.accent.withValues(alpha: 0.06),
              ),
            ),

            // ── TOP: Sport badge ──
            if (event.sportType != null || event.promotionName != null)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: palette.accent.withValues(alpha: 0.5),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      (event.promotionName ?? event.sportType ?? '')
                          .toUpperCase(),
                      style: TextStyle(
                        color: palette.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),
                ),
              ),

            // ── CENTER: Event title ──
            Positioned(
              left: 10,
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Text(
                  event.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    height: 1.15,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // ── BOTTOM: Date, venue ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.9),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Date + time row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$dateStr  \u2022  $timeStr',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Venue + city
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 11,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '${event.venue}, ${event.city}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Broadcast info
                    if (event.broadcastInfo != null &&
                        event.broadcastInfo!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        event.broadcastInfo!,
                        style: TextStyle(
                          color: palette.accent.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // Ticket CTA
                    if (event.ticketUrl != null &&
                        event.ticketUrl!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              palette.accent,
                              palette.accent.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: palette.accent.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Text(
                          'GET TICKETS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                    // DFC branding
                    const SizedBox(height: 4),
                    Text(
                      'DATAFIGHTCENTRAL.COM',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // LIVE badge
            if (event.isLive)
              Positioned(
                top: 6,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Text(
                    '\u25CF LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED: Palette + painter used by both poster widgets.
// ═══════════════════════════════════════════════════════════════════════════

class EventPalette {
  final Color bg1;
  final Color bg2;
  final Color accent;
  final IconData icon;
  const EventPalette({
    required this.bg1,
    required this.bg2,
    required this.accent,
    required this.icon,
  });
}

EventPalette eventPaletteForTitle(String title) {
  final t = title.toLowerCase();
  if (t.contains('ufc')) {
    return const EventPalette(
      bg1: Color(0xFF2D0A0A),
      bg2: Color(0xFF0A0E1A),
      accent: Color(0xFFD4AF37),
      icon: Icons.sports_mma,
    );
  }
  if (t.contains('ibc') ||
      t.contains('bkfc') ||
      t.contains('bare knuckle') ||
      t.contains('brawl')) {
    return const EventPalette(
      bg1: Color(0xFF1A0A0A),
      bg2: Color(0xFF0A0A1A),
      accent: Color(0xFFE53935),
      icon: Icons.sports_mma,
    );
  }
  if (t.contains('eternal') || t.contains('mma')) {
    return const EventPalette(
      bg1: Color(0xFF0A1A2D),
      bg2: Color(0xFF0A0E1A),
      accent: Color(0xFF00BCD4),
      icon: Icons.sports_mma,
    );
  }
  if (t.contains('boxing') || t.contains('wbc') || t.contains('legends')) {
    return const EventPalette(
      bg1: Color(0xFF0A2D1A),
      bg2: Color(0xFF0A0E1A),
      accent: Color(0xFF4CAF50),
      icon: Icons.sports,
    );
  }
  if (t.contains('elite') || t.contains('fight series')) {
    return const EventPalette(
      bg1: Color(0xFF1A0A2E),
      bg2: Color(0xFF0A0E1A),
      accent: Color(0xFFAB47BC),
      icon: Icons.sports_mma,
    );
  }
  if (t.contains('muay thai') ||
      t.contains('k1') ||
      t.contains('kickbox') ||
      t.contains('one ')) {
    return const EventPalette(
      bg1: Color(0xFF2D1A0A),
      bg2: Color(0xFF0A0E1A),
      accent: Color(0xFFFF9800),
      icon: Icons.sports_kabaddi,
    );
  }
  if (t.contains('pfl')) {
    return const EventPalette(
      bg1: Color(0xFF0A0A2D),
      bg2: Color(0xFF0A0E1A),
      accent: Color(0xFF2196F3),
      icon: Icons.sports_mma,
    );
  }
  if (t.contains('hex') || t.contains('cage')) {
    return const EventPalette(
      bg1: Color(0xFF1A1A0A),
      bg2: Color(0xFF0A0E1A),
      accent: Color(0xFFCDDC39),
      icon: Icons.sports_mma,
    );
  }
  return const EventPalette(
    bg1: Color(0xFF1A0A2E),
    bg2: Color(0xFF0A0E1A),
    accent: DesignTokens.neonCyan,
    icon: Icons.sports_mma,
  );
}

class _FightSlashPainter extends CustomPainter {
  final Color color;
  const _FightSlashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.15),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(size.width * 0.3, 0)
      ..lineTo(size.width * 0.7, size.height)
      ..lineTo(size.width * 0.75, size.height)
      ..lineTo(size.width * 0.35, 0)
      ..close();

    canvas.drawPath(path, paint);

    final path2 = Path()
      ..moveTo(size.width * 0.55, 0)
      ..lineTo(size.width * 0.85, size.height)
      ..lineTo(size.width * 0.87, size.height)
      ..lineTo(size.width * 0.57, 0)
      ..close();

    final paint2 = Paint()..color = color.withValues(alpha: 0.06);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _FightSlashPainter oldDelegate) =>
      color != oldDelegate.color;
}

// ═══════════════════════════════════════════════════════════════════════════
// SPONSOR STRIP — Horizontal row of sponsor logos/names on the poster
// ═══════════════════════════════════════════════════════════════════════════
class _SponsorStrip extends StatelessWidget {
  final List<Map<String, String>> sponsors;
  const _SponsorStrip({required this.sponsors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: Colors.black.withValues(alpha: 0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'PRESENTED BY  ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 7,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          ...sponsors.take(4).map((s) {
            final logoUrl = s['logoUrl'];
            final name = s['name'] ?? '';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: logoUrl != null && logoUrl.isNotEmpty
                  ? Image.network(
                      logoUrl,
                      height: 14,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Text(
                        name.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    )
                  : Text(
                      name.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 8,
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
}
