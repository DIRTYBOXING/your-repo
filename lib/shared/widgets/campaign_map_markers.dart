import 'package:flutter/material.dart';
import 'dart:ui' as ui;

// ══════════════════════════════════════════════════════════════════════════════
// CAMPAIGN MAP MARKERS — Glowing markers for Dark Map overlay
// Pink Shield (DV-safe gyms) is the showstopper. Coffee & Gold are clean.
// ══════════════════════════════════════════════════════════════════════════════

/// Glowing Pink Shield marker — the star of the dark map.
/// Pulses, radiates, breathes. Unmissable on a dark background.
class PinkShieldMarker extends StatefulWidget {
  final double size;
  final VoidCallback? onTap;
  final bool showLabel;
  final String? label;

  const PinkShieldMarker({
    super.key,
    this.size = 48,
    this.onTap,
    this.showLabel = false,
    this.label,
  });

  @override
  State<PinkShieldMarker> createState() => _PinkShieldMarkerState();
}

class _PinkShieldMarkerState extends State<PinkShieldMarker>
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
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _pulse = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _glow = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulse, _glow]),
        builder: (context, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow aura
                  Container(
                    width: widget.size * 1.8 * _pulse.value,
                    height: widget.size * 1.8 * _pulse.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(
                            0xFFFF69B4,
                          ).withValues(alpha: 0.25 * _glow.value),
                          const Color(
                            0xFFC2185B,
                          ).withValues(alpha: 0.08 * _glow.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Mid glow ring
                  Container(
                    width: widget.size * 1.3,
                    height: widget.size * 1.3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFF69B4,
                          ).withValues(alpha: 0.4 * _glow.value),
                          blurRadius: 18,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  // Shield shape
                  Transform.scale(
                    scale: _pulse.value,
                    child: CustomPaint(
                      size: Size(widget.size, widget.size * 1.15),
                      painter: _PinkShieldPainter(glowIntensity: _glow.value),
                    ),
                  ),
                ],
              ),
              if (widget.showLabel && widget.label != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF69B4).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFFFF69B4).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    widget.label!,
                    style: const TextStyle(
                      color: Color(0xFFFF69B4),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Custom painter for the Pink Shield shape with neon glow
class _PinkShieldPainter extends CustomPainter {
  final double glowIntensity;
  _PinkShieldPainter({this.glowIntensity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shield path
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..quadraticBezierTo(w * 0.85, h * 0.02, w, h * 0.2)
      ..quadraticBezierTo(w * 0.95, h * 0.55, w * 0.5, h)
      ..quadraticBezierTo(w * 0.05, h * 0.55, 0, h * 0.2)
      ..quadraticBezierTo(w * 0.15, h * 0.02, w * 0.5, 0)
      ..close();

    // Outer glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFF69B4).withValues(alpha: 0.5 * glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, glowPaint);

    // Main fill gradient
    final gradient = ui.Gradient.linear(
      Offset(w * 0.5, 0),
      Offset(w * 0.5, h),
      [const Color(0xFFF48FB1), const Color(0xFFC2185B)],
    );
    final fillPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Inner highlight
    final innerPath = Path()
      ..moveTo(w * 0.5, h * 0.08)
      ..quadraticBezierTo(w * 0.72, h * 0.1, w * 0.8, h * 0.22)
      ..quadraticBezierTo(w * 0.65, h * 0.35, w * 0.5, h * 0.5)
      ..quadraticBezierTo(w * 0.35, h * 0.35, w * 0.3, h * 0.22)
      ..quadraticBezierTo(w * 0.3, h * 0.1, w * 0.5, h * 0.08)
      ..close();

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2 + 0.1 * glowIntensity)
      ..style = PaintingStyle.fill;
    canvas.drawPath(innerPath, highlightPaint);

    // Heart inside shield
    _drawHeart(canvas, Offset(w * 0.5, h * 0.42), w * 0.22);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6 + 0.2 * glowIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);
  }

  void _drawHeart(Canvas canvas, Offset center, double scale) {
    final path = Path();
    final x = center.dx;
    final y = center.dy;
    final s = scale;

    path.moveTo(x, y + s * 0.35);
    path.cubicTo(x - s, y - s * 0.3, x - s * 0.5, y - s * 0.8, x, y - s * 0.3);
    path.cubicTo(x + s * 0.5, y - s * 0.8, x + s, y - s * 0.3, x, y + s * 0.35);
    path.close();

    final paint = Paint()
      ..color = const Color(0xFFF8BBD0).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinkShieldPainter old) =>
      old.glowIntensity != glowIntensity;
}

// ══════════════════════════════════════════════════════════════════════════════
// COFFEE CAMPAIGN MARKER — Warm amber glow, clean and simple
// ══════════════════════════════════════════════════════════════════════════════

class CoffeeCampaignMarker extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const CoffeeCampaignMarker({super.key, this.size = 36, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
          ),
          border: Border.all(color: const Color(0xFFD7CCC8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8D6E63).withValues(alpha: 0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text('☕', style: TextStyle(fontSize: size * 0.45)),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// GOLD COIN MARKER — Mentor & community fund, warm gold
// ══════════════════════════════════════════════════════════════════════════════

class GoldCoinMarker extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const GoldCoinMarker({super.key, this.size = 36, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
          ),
          border: Border.all(color: const Color(0xFFFFF8E1), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD600).withValues(alpha: 0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text('🪙', style: TextStyle(fontSize: size * 0.45)),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DONATION THANK-YOU TICKER — Live scrolling donation feed
// Shows name (or "Anonymous"), amount, campaign, with glow accent
// ══════════════════════════════════════════════════════════════════════════════

class DonationThankYouTicker extends StatefulWidget {
  final List<DonationEntry> donations;
  final double height;

  const DonationThankYouTicker({
    super.key,
    required this.donations,
    this.height = 40,
  });

  @override
  State<DonationThankYouTicker> createState() => _DonationThankYouTickerState();
}

class _DonationThankYouTickerState extends State<DonationThankYouTicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _scrollCtrl;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              if (mounted) {
                setState(() {
                  _currentIndex = (_currentIndex + 1) % widget.donations.length;
                });
                _scrollCtrl.forward(from: 0);
              }
            }
          });
    _scrollCtrl.forward();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.donations.isEmpty) return const SizedBox.shrink();
    final d = widget.donations[_currentIndex];
    final campaignColor = _colorForCampaign(d.campaign);

    return AnimatedBuilder(
      animation: _scrollCtrl,
      builder: (context, _) {
        final progress = _scrollCtrl.value;
        // Fade in (0-.15), hold (.15-.85), fade out (.85-1)
        double opacity;
        if (progress < 0.15) {
          opacity = progress / 0.15;
        } else if (progress > 0.85) {
          opacity = (1.0 - progress) / 0.15;
        } else {
          opacity = 1.0;
        }

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: campaignColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: campaignColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.favorite, color: campaignColor, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Segoe UI',
                      ),
                      children: [
                        TextSpan(
                          text: d.displayName,
                          style: TextStyle(
                            color: campaignColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: ' donated ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        TextSpan(
                          text: '\$${d.amount}',
                          style: TextStyle(
                            color: campaignColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: ' to ${d.campaign}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  d.timeAgo,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _colorForCampaign(String campaign) {
    final lower = campaign.toLowerCase();
    if (lower.contains('pink') || lower.contains('shield')) {
      return const Color(0xFFFF69B4);
    }
    if (lower.contains('coffee')) {
      return const Color(0xFF8D6E63);
    }
    if (lower.contains('gold') || lower.contains('coin')) {
      return const Color(0xFFFFD600);
    }
    return const Color(0xFF00E5FF);
  }
}

class DonationEntry {
  final String? name;
  final int amount;
  final String campaign;
  final String timeAgo;

  const DonationEntry({
    this.name,
    required this.amount,
    required this.campaign,
    required this.timeAgo,
  });

  String get displayName => name ?? 'Anonymous';
}

// ══════════════════════════════════════════════════════════════════════════════
// DEMO DONATIONS — Seed data for ticker
// ══════════════════════════════════════════════════════════════════════════════
const kDemoDonations = <DonationEntry>[
  DonationEntry(
    name: 'Sarah M.',
    amount: 25,
    campaign: 'Pink Shield',
    timeAgo: '2m ago',
  ),
  DonationEntry(amount: 10, campaign: 'Coffee Campaign', timeAgo: '5m ago'),
  DonationEntry(
    name: 'Coach Ray',
    amount: 50,
    campaign: 'Gold Coin Drive',
    timeAgo: '8m ago',
  ),
  DonationEntry(
    name: 'Jess K.',
    amount: 5,
    campaign: 'Pink Shield',
    timeAgo: '12m ago',
  ),
  DonationEntry(amount: 100, campaign: 'Pink Shield', timeAgo: '15m ago'),
  DonationEntry(
    name: 'Tiger Muay Thai',
    amount: 250,
    campaign: 'Gold Coin Drive',
    timeAgo: '22m ago',
  ),
  DonationEntry(
    name: 'Mike T.',
    amount: 10,
    campaign: 'Coffee Campaign',
    timeAgo: '30m ago',
  ),
  DonationEntry(amount: 25, campaign: 'Pink Shield', timeAgo: '45m ago'),
  DonationEntry(
    name: 'Harmony FC',
    amount: 500,
    campaign: 'Pink Shield',
    timeAgo: '1h ago',
  ),
  DonationEntry(
    name: 'Dan W.',
    amount: 15,
    campaign: 'Coffee Campaign',
    timeAgo: '1h ago',
  ),
  DonationEntry(amount: 50, campaign: 'Gold Coin Drive', timeAgo: '2h ago'),
  DonationEntry(
    name: 'Phoenix BJJ',
    amount: 200,
    campaign: 'Pink Shield',
    timeAgo: '3h ago',
  ),
];
