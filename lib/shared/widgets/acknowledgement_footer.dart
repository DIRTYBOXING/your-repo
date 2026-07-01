import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ACKNOWLEDGEMENT OF COUNTRY FOOTER
///
/// We acknowledge the Traditional Custodians of the land on which we live,
/// train, and compete. We pay our respects to Elders past and present and
/// extend that respect to all Aboriginal and Torres Strait Islander peoples
/// today.
///
/// Both flags are rendered with CustomPainter — zero network dependencies.
/// ═══════════════════════════════════════════════════════════════════════════

// ─── Aboriginal Flag colours ─────────────────────────────────────────────
const _abBlack = Color(0xFF000000);
const _abRed = Color(0xFFCC0000);
const _abYellow = Color(0xFFFFCD00);

// ─── Torres Strait Islander Flag colours ─────────────────────────────────
const _tsiGreen = Color(0xFF009E49);
const _tsiBlue = Color(0xFF003DA5);
const _tsiBlack = Color(0xFF000000);
const _tsiWhite = Color(0xFFFFFFFF);

// ─── Earth ochre tones for the dot-art divider ───────────────────────────
const _ochreRed = Color(0xFFCC3300);
const _ochreYellow = Color(0xFFFFCD00);
const _ochreTeal = Color(0xFF00C9A7);

// ══════════════════════════════════════════════════════════════════════════
//  CUSTOM PAINTERS — native flag rendering, works offline, no assets needed
// ══════════════════════════════════════════════════════════════════════════

/// Paints the Australian Aboriginal Flag.
/// Top half black, bottom half red, centred yellow disc.
class _AboriginalFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final half = size.height / 2;
    // Black top
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, half),
      Paint()..color = _abBlack,
    );
    // Red bottom
    canvas.drawRect(
      Rect.fromLTWH(0, half, size.width, half),
      Paint()..color = _abRed,
    );
    // Yellow sun circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height * 0.28,
      Paint()..color = _abYellow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Paints the Torres Strait Islander Flag.
/// Green bars top & bottom, thin black dividers, blue centre field,
/// white Dhari headdress, white 5-pointed star.
class _TorresStraitFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stripe = h * 0.18; // green stripe height
    final divider = h * 0.04; // thin black line
    final white = Paint()..color = _tsiWhite;

    // Green top bar
    canvas.drawRect(Rect.fromLTWH(0, 0, w, stripe), Paint()..color = _tsiGreen);
    // Black divider
    canvas.drawRect(
      Rect.fromLTWH(0, stripe, w, divider),
      Paint()..color = _tsiBlack,
    );
    // Blue centre
    canvas.drawRect(
      Rect.fromLTWH(0, stripe + divider, w, h - 2 * (stripe + divider)),
      Paint()..color = _tsiBlue,
    );
    // Black divider bottom
    canvas.drawRect(
      Rect.fromLTWH(0, h - stripe - divider, w, divider),
      Paint()..color = _tsiBlack,
    );
    // Green bottom bar
    canvas.drawRect(
      Rect.fromLTWH(0, h - stripe, w, stripe),
      Paint()..color = _tsiGreen,
    );

    // ── Dhari (headdress) — simplified white silhouette ──
    final cx = w / 2;
    final cy = h * 0.42;
    final dhariW = w * 0.36;
    final dhariH = h * 0.38;

    final dhari = Path()
      // Left wing — smooth curve from base outward and up
      ..moveTo(cx - dhariW * 0.15, cy + dhariH * 0.25)
      ..quadraticBezierTo(
        cx - dhariW * 0.8,
        cy - dhariH * 0.1,
        cx - dhariW * 0.55,
        cy - dhariH * 0.45,
      )
      ..quadraticBezierTo(
        cx - dhariW * 0.3,
        cy - dhariH * 0.2,
        cx,
        cy - dhariH * 0.05,
      )
      // Right wing — mirror
      ..quadraticBezierTo(
        cx + dhariW * 0.3,
        cy - dhariH * 0.2,
        cx + dhariW * 0.55,
        cy - dhariH * 0.45,
      )
      ..quadraticBezierTo(
        cx + dhariW * 0.8,
        cy - dhariH * 0.1,
        cx + dhariW * 0.15,
        cy + dhariH * 0.25,
      )
      ..close();
    canvas.drawPath(dhari, white);

    // ── Five-pointed star inside the Dhari ──
    _drawStar(
      canvas,
      Offset(cx, cy + dhariH * 0.06),
      h * 0.075,
      5,
      Paint()..color = _tsiWhite,
    );
  }

  void _drawStar(
    Canvas canvas,
    Offset centre,
    double r,
    int points,
    Paint paint,
  ) {
    final path = Path();
    final innerR = r * 0.4;
    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? r : innerR;
      final angle = (math.pi / points) * i - math.pi / 2;
      final pt = Offset(
        centre.dx + radius * math.cos(angle),
        centre.dy + radius * math.sin(angle),
      );
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Paints a row of small dots in Aboriginal earth tones — used as a divider.
class _DotDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const colours = [_ochreRed, _ochreYellow, _ochreTeal];
    final dotR = size.height / 2;
    final spacing = dotR * 2.8;
    final count = (size.width / spacing).floor();
    final startX = (size.width - (count - 1) * spacing) / 2;
    for (var i = 0; i < count; i++) {
      canvas.drawCircle(
        Offset(startX + i * spacing, size.height / 2),
        dotR * 0.45,
        Paint()..color = colours[i % colours.length].withValues(alpha: 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ══════════════════════════════════════════════════════════════════════════
//  FULL FOOTER
// ══════════════════════════════════════════════════════════════════════════

class AcknowledgementFooter extends StatelessWidget {
  final bool showSocialLinks;
  final Color? backgroundColor;

  const AcknowledgementFooter({
    super.key,
    this.showSocialLinks = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF050A14),
        border: Border(
          top: BorderSide(color: _ochreTeal.withValues(alpha: 0.25)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 28),

          // ── Dot-art divider ───────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 6,
            child: CustomPaint(painter: _DotDividerPainter()),
          ),
          const SizedBox(height: 24),

          // ── Flags side-by-side ────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _flag(
                painter: _AboriginalFlagPainter(),
                tooltip: 'Australian Aboriginal Flag',
              ),
              const SizedBox(width: 20),
              _flag(
                painter: _TorresStraitFlagPainter(),
                tooltip: 'Torres Strait Islander Flag',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Acknowledgement text ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              'We acknowledge the Traditional Custodians of the land on which '
              'we live, train, and compete. We pay our respects to Elders past '
              'and present and extend that respect to all Aboriginal and Torres '
              'Strait Islander peoples today.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.7,
                letterSpacing: 0.15,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Dot-art divider ───────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 6,
            child: CustomPaint(painter: _DotDividerPainter()),
          ),

          // ── Social links ──────────────────────────────────────────
          if (showSocialLinks) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _socialIcon(
                  Icons.facebook,
                  'https://facebook.com/DataFightCentral',
                  const Color(0xFF1877F2),
                ),
                const SizedBox(width: 14),
                _socialIcon(
                  Icons.camera_alt,
                  'https://instagram.com/DataFightCentral',
                  const Color(0xFFE4405F),
                ),
                const SizedBox(width: 14),
                _socialIcon(
                  Icons.play_circle_fill,
                  'https://youtube.com/@DataFightCentral',
                  const Color(0xFFFF0000),
                ),
                const SizedBox(width: 14),
                _socialIcon(
                  Icons.alternate_email,
                  'https://x.com/DataFightCentra',
                  Colors.white,
                ),
              ],
            ),
          ],

          // ── Site links ────────────────────────────────────────────
          const SizedBox(height: 16),
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              _FooterLink('About'),
              _Dot(),
              _FooterLink('Privacy'),
              _Dot(),
              _FooterLink('Terms'),
              _Dot(),
              _FooterLink('Contact'),
            ],
          ),

          // ── Copyright ─────────────────────────────────────────────
          const SizedBox(height: 14),
          Text(
            'DataFightCentral\u2122',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\u00A9 2026 Dirtyboxer Pty Ltd',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Live event production \u2022 Streaming & PPV \u2022 Online marketplace \u2022 Branded merchandise',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'hello@datafightcentral.com \u2022 accounts@datafightcentral.com',
            style: TextStyle(
              fontSize: 8,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  Widget _flag({required CustomPainter painter, required String tooltip}) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 64,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: CustomPaint(painter: painter, size: const Size(64, 38)),
        ),
      ),
    );
  }

  Widget _socialIcon(IconData icon, String url, Color color) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

/// Tiny link used inside the footer Wrap.
class _FooterLink extends StatelessWidget {
  final String label;
  const _FooterLink(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: _ochreTeal.withValues(alpha: 0.75),
          decoration: TextDecoration.underline,
          decorationColor: _ochreTeal.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

/// Dot separator between footer links.
class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Text(
      '\u2022',
      style: TextStyle(
        fontSize: 10,
        color: Colors.white.withValues(alpha: 0.2),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  COMPACT FOOTER — one-liner for space-constrained screens
// ══════════════════════════════════════════════════════════════════════════

class CompactAcknowledgement extends StatelessWidget {
  const CompactAcknowledgement({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF050A14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mini Aboriginal flag
          SizedBox(
            width: 26,
            height: 15,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: CustomPaint(painter: _AboriginalFlagPainter()),
            ),
          ),
          const SizedBox(width: 8),
          // Mini Torres Strait flag
          SizedBox(
            width: 26,
            height: 15,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: CustomPaint(painter: _TorresStraitFlagPainter()),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'We acknowledge the Traditional Custodians of this land',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.55),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
