import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/image_assets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT CARD POST WIDGET — PFL / UFC Social-Media Style
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Renders a fight card post (postType == 'fight_card') as a rich visual card
/// instead of raw monospace text. Inspired by PFL's Facebook fight card posts
/// but elevated with DFC's neon-glass design language.
///
/// Layout:
///   ┌─ HEADER BANNER ──────────────────────────┐
///   │  Promotion logo | EVENT NAME              │
///   │  📅 Date  ·  📍 Venue, City               │
///   │  ──── MAIN CARD ────                      │
///   ├─ BOUT ROW ────────────────────────────────┤
///   │  🔴 Fighter A          VS    🔵 Fighter B │
///   │     (12-3-0)                   (8-1-0)    │
///   │  ───── Welterweight · 5×5min ─────        │
///   ├─ BOUT ROW ────────────────────────────────┤
///   │  🔴 Fighter C          VS    🔵 Fighter D │
///   │  ...                                      │
///   ├─ BROADCAST STRIP ─────────────────────────┤
///   │  DFC FIGHTPIPE | 7:00 PM AEST             │
///   └───────────────────────────────────────────┘
///
/// ═══════════════════════════════════════════════════════════════════════════

class FightCardPostWidget extends StatelessWidget {
  final String content;
  final String? promotionLogo;

  const FightCardPostWidget({
    super.key,
    required this.content,
    this.promotionLogo,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = _ParsedFightCard.fromText(content);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.2),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.neonCyan.withValues(alpha: 0.06),
            blurRadius: 16,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── EVENT HEADER BANNER ──
          _buildHeaderBanner(parsed),

          // ── BOUT ROWS ──
          if (parsed.bouts.isNotEmpty) ...[
            for (int i = 0; i < parsed.bouts.length; i++) ...[
              if (i == 0 ||
                  parsed.bouts[i].section != parsed.bouts[i - 1].section)
                _buildSectionDivider(parsed.bouts[i].section),
              _buildBoutRow(parsed.bouts[i], isMainEvent: i == 0),
              if (i < parsed.bouts.length - 1)
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          ],

          // ── BROADCAST / HASHTAG STRIP ──
          _buildBroadcastStrip(parsed),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HEADER BANNER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderBanner(_ParsedFightCard card) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.neonRed.withValues(alpha: 0.15),
            const Color(0xFF0A0E18),
            DesignTokens.neonCyan.withValues(alpha: 0.08),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        children: [
          // Fight Card badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: DesignTokens.neonMagenta.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: DesignTokens.neonMagenta.withValues(alpha: 0.5),
                width: 0.6,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sports_mma,
                  size: 12,
                  color: DesignTokens.neonMagenta,
                ),
                SizedBox(width: 5),
                Text(
                  'FIGHT CARD',
                  style: TextStyle(
                    color: DesignTokens.neonMagenta,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Promotion name
          if (card.promotionName.isNotEmpty)
            Text(
              card.promotionName.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DesignTokens.neonGold,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),

          // Event name
          if (card.eventName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              card.eventName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                height: 1.2,
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Date + Venue row
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: [
              if (card.date.isNotEmpty)
                _iconLabel(
                  Icons.calendar_today,
                  card.date,
                  DesignTokens.neonCyan,
                ),
              if (card.venue.isNotEmpty)
                _iconLabel(
                  Icons.location_on,
                  card.venue,
                  DesignTokens.neonAmber,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconLabel(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color.withValues(alpha: 0.9),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION DIVIDER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSectionDivider(String section) {
    if (section.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.white.withValues(alpha: 0.03),
      child: Center(
        child: Text(
          section,
          style: TextStyle(
            color: DesignTokens.neonCyan.withValues(alpha: 0.7),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOUT ROW — The PFL-style matchup strip
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBoutRow(_ParsedBout bout, {bool isMainEvent = false}) {
    final bool isTitle = bout.titleFight.isNotEmpty;
    final bool bothFightersMissing =
        bout.redName.isEmpty && bout.blueName.isEmpty;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isMainEvent ? 14 : 10,
      ),
      decoration: isMainEvent
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.neonRed.withValues(alpha: 0.06),
                  Colors.transparent,
                  DesignTokens.neonBlue.withValues(alpha: 0.06),
                ],
              ),
            )
          : null,
      child: Column(
        children: [
          // Title fight label
          if (isTitle)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: DesignTokens.neonGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: DesignTokens.neonGold.withValues(alpha: 0.4),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  bout.titleFight.toUpperCase(),
                  style: const TextStyle(
                    color: DesignTokens.neonGold,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),

          // Fighter matchup row — skip TBA VS TBA when both are missing
          if (bothFightersMissing)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'MATCHUP PENDING',
                  style: TextStyle(
                    color: DesignTokens.neonAmber.withValues(alpha: 0.7),
                    fontSize: isMainEvent ? 13 : 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                // Red corner
                Expanded(
                  child: _buildCorner(
                    name: bout.redName,
                    record: bout.redRecord,
                    color: DesignTokens.neonRed,
                    alignment: CrossAxisAlignment.start,
                    isMainEvent: isMainEvent,
                  ),
                ),

                // VS badge
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: isMainEvent ? 12 : 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                // Blue corner
                Expanded(
                  child: _buildCorner(
                    name: bout.blueName,
                    record: bout.blueRecord,
                    color: DesignTokens.neonBlue,
                    alignment: CrossAxisAlignment.end,
                    isMainEvent: isMainEvent,
                  ),
                ),
            ],
          ),

          // Weight class + rounds strip
          if (bout.weightClass.isNotEmpty || bout.rules.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                [
                  if (bout.weightClass.isNotEmpty) bout.weightClass,
                  if (bout.rules.isNotEmpty) bout.rules,
                ].join(' · '),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCorner({
    required String name,
    required String record,
    required Color color,
    required CrossAxisAlignment alignment,
    required bool isMainEvent,
  }) {
    final textAlign = alignment == CrossAxisAlignment.start
        ? TextAlign.left
        : TextAlign.right;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        // Color dot + name
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (alignment == CrossAxisAlignment.start)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            Flexible(
              child: Text(
                name.isNotEmpty ? name : 'TBA',
                textAlign: textAlign,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMainEvent ? 15 : 13,
                  fontWeight: isMainEvent ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: isMainEvent ? 0.3 : 0,
                ),
              ),
            ),
            if (alignment == CrossAxisAlignment.end)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (record.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              top: 2,
              left: alignment == CrossAxisAlignment.start ? 12 : 0,
              right: alignment == CrossAxisAlignment.end ? 12 : 0,
            ),
            child: Text(
              record,
              textAlign: textAlign,
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BROADCAST / HASHTAG STRIP
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBroadcastStrip(_ParsedFightCard card) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.08),
            const Color(0xFF0A0E18),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: DesignTokens.neonCyan.withValues(alpha: 0.12),
            width: 0.6,
          ),
        ),
      ),
      child: Row(
        children: [
          // DFC branding
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: DesignTokens.neonCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  ImageAssets.dfcIcon,
                  width: 14,
                  height: 14,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.sports_mma,
                    size: 14,
                    color: DesignTokens.neonCyan,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'DFC',
                  style: TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Bout count
          Text(
            '${card.bouts.length} BOUTS',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),

          const Spacer(),

          // Hashtags
          if (card.hashtags.isNotEmpty)
            Flexible(
              child: Text(
                card.hashtags.take(3).join(' '),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TEXT PARSER — Extracts structured data from fight card text posts
// ═══════════════════════════════════════════════════════════════════════════

class _ParsedFightCard {
  final String promotionName;
  final String eventName;
  final String date;
  final String venue;
  final List<_ParsedBout> bouts;
  final List<String> hashtags;

  _ParsedFightCard({
    this.promotionName = '',
    this.eventName = '',
    this.date = '',
    this.venue = '',
    this.bouts = const [],
    this.hashtags = const [],
  });

  factory _ParsedFightCard.fromText(String text) {
    final lines = text.split('\n').map((l) => l.trim()).toList();

    String promotionName = '';
    String eventName = '';
    String date = '';
    String venue = '';
    final bouts = <_ParsedBout>[];
    final hashtags = <String>[];
    String currentSection = '';

    // State machine for parsing bouts
    String? pendingRedCorner;
    String? pendingBlueCorner;
    String? pendingMeta;
    String? pendingTitle;
    String? boutSection;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty || line.startsWith('═') || line.startsWith('───')) {
        continue;
      }

      // Remove emoji prefix for matching
      final clean = line.replaceAll(RegExp(r'^[🥊📢📅📍🔴🔵\s]+'), '').trim();

      // Hashtags
      if (line.contains('#')) {
        final tags = RegExp(r'#\w+').allMatches(line).map((m) => m.group(0)!);
        hashtags.addAll(tags);
        continue;
      }

      // Title: "FIGHT CARD ANNOUNCEMENT"
      if (line.contains('FIGHT CARD ANNOUNCEMENT')) continue;

      // Section headers (MAIN EVENT, SEMI-MAIN, etc.)
      if (_isSectionHeader(line)) {
        currentSection = _extractSection(line);
        boutSection = currentSection;
        continue;
      }

      // Date line: starts with 📅
      if (line.startsWith('📅') ||
          line.contains(RegExp(r'\d{2}/\d{2}/\d{4}'))) {
        date = clean;
        continue;
      }

      // Venue line: starts with 📍
      if (line.startsWith('📍')) {
        venue = clean;
        continue;
      }

      // Event name: starts with 📢
      if (line.startsWith('📢')) {
        eventName = clean;
        continue;
      }

      // VS separator
      if (line.trim().toUpperCase() == 'VS') {
        continue;
      }

      // Red corner: starts with 🔴
      if (line.startsWith('🔴')) {
        // If there's a pending bout, flush it first
        if (pendingRedCorner != null) {
          bouts.add(
            _ParsedBout.fromParsed(
              section: boutSection ?? currentSection,
              redRaw: pendingRedCorner,
              blueRaw: pendingBlueCorner ?? '',
              metaRaw: pendingMeta ?? '',
              titleFight: pendingTitle ?? '',
            ),
          );
          pendingRedCorner = null;
          pendingBlueCorner = null;
          pendingMeta = null;
          pendingTitle = null;
        }
        pendingRedCorner = line.replaceFirst('🔴', '').trim();
        continue;
      }

      // Blue corner: starts with 🔵
      if (line.startsWith('🔵')) {
        pendingBlueCorner = line.replaceFirst('🔵', '').trim();
        continue;
      }

      // Meta line: contains weight class / rounds pattern
      if (line.contains('•') && (line.contains('×') || line.contains('min'))) {
        pendingMeta = line;
        // Flush current bout
        if (pendingRedCorner != null) {
          bouts.add(
            _ParsedBout.fromParsed(
              section: boutSection ?? currentSection,
              redRaw: pendingRedCorner,
              blueRaw: pendingBlueCorner ?? '',
              metaRaw: pendingMeta,
              titleFight: pendingTitle ?? '',
            ),
          );
          pendingRedCorner = null;
          pendingBlueCorner = null;
          pendingMeta = null;
          pendingTitle = null;
        }
        continue;
      }

      // Title fight line: contains "Title" or "Championship"
      if (line.contains('Title') ||
          line.contains('Championship') ||
          line.contains('Belt')) {
        pendingTitle = line.replaceAll(RegExp(r'^[\s—\-]+'), '').trim();
        continue;
      }

      // Promotion name: first non-header, non-emoji text line
      if (promotionName.isEmpty && eventName.isEmpty && clean.isNotEmpty) {
        promotionName = clean;
        continue;
      }
    }

    // Flush last bout
    if (pendingRedCorner != null) {
      bouts.add(
        _ParsedBout.fromParsed(
          section: boutSection ?? currentSection,
          redRaw: pendingRedCorner,
          blueRaw: pendingBlueCorner ?? '',
          metaRaw: pendingMeta ?? '',
          titleFight: pendingTitle ?? '',
        ),
      );
    }

    return _ParsedFightCard(
      promotionName: promotionName,
      eventName: eventName,
      date: date,
      venue: venue,
      bouts: bouts,
      hashtags: hashtags,
    );
  }

  static bool _isSectionHeader(String line) {
    final upper = line.toUpperCase().replaceAll(RegExp(r'[—\-═\s]'), '');
    return [
          'MAINEVENT',
          'SEMIMAIN',
          'COMAIN',
          'PRELIM',
          'UNDERCARD',
          'SUPERFIGHT',
          'EXHIBITION',
          'MAINCARD',
        ].contains(upper) ||
        line.contains(
          RegExp(r'MAIN\s*EVENT|SEMI[\s-]?MAIN|CO[\s-]?MAIN|PRELIM|UNDERCARD'),
        );
  }

  static String _extractSection(String line) {
    final upper = line.toUpperCase().replaceAll(RegExp(r'[—═\-]'), '').trim();
    if (upper.contains('MAIN EVENT')) return 'MAIN EVENT';
    if (upper.contains('SEMI')) return 'SEMI-MAIN';
    if (upper.contains('CO-MAIN') || upper.contains('CO MAIN')) {
      return 'CO-MAIN';
    }
    if (upper.contains('PRELIM')) return 'PRELIM';
    if (upper.contains('UNDERCARD')) return 'UNDERCARD';
    if (upper.contains('SUPER')) return 'SUPER FIGHT';
    if (upper.contains('EXHIBITION')) return 'EXHIBITION';
    if (upper.contains('MAIN CARD')) return 'MAIN CARD';
    return upper;
  }
}

class _ParsedBout {
  final String section;
  final String redName;
  final String redRecord;
  final String blueName;
  final String blueRecord;
  final String weightClass;
  final String rules;
  final String titleFight;

  _ParsedBout({
    this.section = '',
    this.redName = '',
    this.redRecord = '',
    this.blueName = '',
    this.blueRecord = '',
    this.weightClass = '',
    this.rules = '',
    this.titleFight = '',
  });

  factory _ParsedBout.fromParsed({
    required String section,
    required String redRaw,
    required String blueRaw,
    required String metaRaw,
    required String titleFight,
  }) {
    // Parse "Fighter Name (12-3-0)" into name + record
    final redParts = _splitNameRecord(redRaw);
    final blueParts = _splitNameRecord(blueRaw);

    // Parse "Welterweight • 5×5min • Full Contact"
    String weightClass = '';
    String rules = '';
    if (metaRaw.isNotEmpty) {
      final parts = metaRaw.split('•').map((s) => s.trim()).toList();
      if (parts.isNotEmpty) weightClass = parts[0];
      if (parts.length >= 2) {
        weightClass = '${parts[0]} · ${parts[1]}';
      }
      if (parts.length >= 3) rules = parts[2];
    }

    return _ParsedBout(
      section: section,
      redName: redParts.$1,
      redRecord: redParts.$2,
      blueName: blueParts.$1,
      blueRecord: blueParts.$2,
      weightClass: weightClass,
      rules: rules,
      titleFight: titleFight,
    );
  }

  static (String, String) _splitNameRecord(String raw) {
    final match = RegExp(r'^(.*?)\s*\(([^)]+)\)\s*$').firstMatch(raw);
    if (match != null) {
      return (match.group(1)!.trim(), match.group(2)!.trim());
    }
    return (raw.trim(), '');
  }
}
