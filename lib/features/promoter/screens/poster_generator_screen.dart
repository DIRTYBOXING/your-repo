import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/image_assets.dart';
import '../../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// POSTER GENERATOR — In-app fight poster factory
///
/// Three cinematic styles: Gritty, Cinematic, Clean.
/// Uses RepaintBoundary capture → share_plus for export.
/// Multi-vendor ticket marketplace: shows ALL ticket sellers.
/// ═══════════════════════════════════════════════════════════════════════════

class PosterGeneratorScreen extends StatefulWidget {
  final String? eventName;
  final String? fighter1;
  final String? fighter2;
  final String? venue;
  final String? date;
  final String? sportType;

  const PosterGeneratorScreen({
    super.key,
    this.eventName,
    this.fighter1,
    this.fighter2,
    this.venue,
    this.date,
    this.sportType,
  });

  @override
  State<PosterGeneratorScreen> createState() => _PosterGeneratorScreenState();
}

class _PosterGeneratorScreenState extends State<PosterGeneratorScreen> {
  final GlobalKey _posterKey = GlobalKey();
  int _selectedStyle = 0; // 0 = Gritty, 1 = Cinematic, 2 = Clean
  bool _isExporting = false;

  // Editable fields
  late TextEditingController _eventCtrl;
  late TextEditingController _fighter1Ctrl;
  late TextEditingController _fighter2Ctrl;
  late TextEditingController _venueCtrl;
  late TextEditingController _dateCtrl;

  // Multi-vendor ticket sellers
  final List<_TicketSeller> _ticketSellers = const [
    _TicketSeller('Ticketek', 'https://ticketek.com.au'),
    _TicketSeller('Eventbrite', 'https://eventbrite.com.au'),
    _TicketSeller('BKFC App', 'https://bkfc.com'),
    _TicketSeller('DFC FightPipe', 'https://datafightcentral.com/fightpipe'),
    _TicketSeller('Moshtix', 'https://moshtix.com.au'),
    _TicketSeller('Venue Box Office', ''),
  ];

  static const _styles = ['GRITTY', 'CINEMATIC', 'CLEAN'];
  static const _styleIcons = [
    Icons.whatshot_rounded,
    Icons.movie_creation_outlined,
    Icons.auto_awesome_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _eventCtrl = TextEditingController(text: widget.eventName ?? 'FIGHT NIGHT');
    _fighter1Ctrl = TextEditingController(
      text: widget.fighter1 ?? 'FIGHTER ONE',
    );
    _fighter2Ctrl = TextEditingController(
      text: widget.fighter2 ?? 'FIGHTER TWO',
    );
    _venueCtrl = TextEditingController(
      text: widget.venue ?? 'Townsville Entertainment Centre',
    );
    _dateCtrl = TextEditingController(text: widget.date ?? '25 October 2026');
  }

  @override
  void dispose() {
    _eventCtrl.dispose();
    _fighter1Ctrl.dispose();
    _fighter2Ctrl.dispose();
    _venueCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  // ── Export via RepaintBoundary ──────────────────────────────────────────
  Future<void> _exportPoster() async {
    setState(() => _isExporting = true);
    try {
      final boundary =
          _posterKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              pngBytes,
              mimeType: 'image/png',
              name: 'dfc_poster.png',
            ),
          ],
          text:
              '${_eventCtrl.text} — ${_fighter1Ctrl.text} vs ${_fighter2Ctrl.text}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: DesignTokens.neonRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        title: const Text('Poster Generator', style: DFCTextStyles.title),
        backgroundColor: DesignTokens.bgSecondary,
        elevation: 0,
        actions: [
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: DesignTokens.neonCyan,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(
                Icons.share_rounded,
                color: DesignTokens.neonCyan,
              ),
              tooltip: 'Export & Share',
              onPressed: _exportPoster,
            ),
        ],
      ),
      body: wide ? _wideLayout() : _narrowLayout(),
    );
  }

  // ── Wide (desktop) layout ──────────────────────────────────────────────
  Widget _wideLayout() {
    return Row(
      children: [
        // Left: controls
        SizedBox(width: 320, child: _controlsPanel()),
        // Centre: poster preview
        Expanded(child: _posterPreviewArea()),
      ],
    );
  }

  // ── Narrow (mobile) layout ─────────────────────────────────────────────
  Widget _narrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        children: [
          _styleSelector(),
          const SizedBox(height: 16),
          _posterPreviewArea(),
          const SizedBox(height: 16),
          _editFields(),
          const SizedBox(height: 16),
          _ticketMarketplace(),
          const SizedBox(height: 16),
          _exportButton(),
        ],
      ),
    );
  }

  // ── Controls panel (desktop sidebar) ───────────────────────────────────
  Widget _controlsPanel() {
    return Container(
      color: DesignTokens.bgSecondary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'POSTER STYLE',
              style: DFCTextStyles.caption.copyWith(
                letterSpacing: 1.5,
                color: DesignTokens.neonCyan.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 10),
            _styleSelector(),
            const SizedBox(height: 24),
            Text(
              'EVENT DETAILS',
              style: DFCTextStyles.caption.copyWith(
                letterSpacing: 1.5,
                color: DesignTokens.neonCyan.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 10),
            _editFields(),
            const SizedBox(height: 24),
            Text(
              'TICKET SELLERS',
              style: DFCTextStyles.caption.copyWith(
                letterSpacing: 1.5,
                color: DesignTokens.neonCyan.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 10),
            _ticketMarketplace(),
            const SizedBox(height: 24),
            _exportButton(),
          ],
        ),
      ),
    );
  }

  // ── Style selector chips ───────────────────────────────────────────────
  Widget _styleSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_styles.length, (i) {
        final selected = _selectedStyle == i;
        return ChoiceChip(
          avatar: Icon(
            _styleIcons[i],
            size: 16,
            color: selected ? Colors.black : DesignTokens.textMuted,
          ),
          label: Text(
            _styles[i],
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: selected ? Colors.black : DesignTokens.textPrimary,
            ),
          ),
          selected: selected,
          selectedColor: DesignTokens.neonCyan,
          backgroundColor: DesignTokens.bgCard,
          side: BorderSide(
            color: selected ? DesignTokens.neonCyan : DesignTokens.borderSubtle,
          ),
          onSelected: (_) => setState(() => _selectedStyle = i),
        );
      }),
    );
  }

  // ── Editable fields ────────────────────────────────────────────────────
  Widget _editFields() {
    return Column(
      children: [
        _field('Event Title', _eventCtrl),
        _field('Fighter 1', _fighter1Ctrl),
        _field('Fighter 2', _fighter2Ctrl),
        _field('Venue', _venueCtrl),
        _field('Date', _dateCtrl),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        style: DFCTextStyles.body.copyWith(color: DesignTokens.textPrimary),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: DFCTextStyles.caption,
          filled: true,
          fillColor: DesignTokens.bgCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            borderSide: const BorderSide(color: DesignTokens.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            borderSide: const BorderSide(color: DesignTokens.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            borderSide: const BorderSide(color: DesignTokens.neonCyan),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  // ── Ticket marketplace (multi-vendor) ──────────────────────────────────
  Widget _ticketMarketplace() {
    return Container(
      decoration: GlassDecoration.card(
        accent: DesignTokens.neonGold,
        radius: DesignTokens.radiusSmall,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.storefront_rounded,
                size: 16,
                color: DesignTokens.neonGold,
              ),
              const SizedBox(width: 6),
              Text(
                'Multi-Vendor Marketplace',
                style: DFCTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.neonGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Fans choose their preferred seller:',
            style: DFCTextStyles.caption,
          ),
          const SizedBox(height: 6),
          ..._ticketSellers.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.confirmation_num_outlined,
                    size: 13,
                    color: DesignTokens.neonCyan,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    s.name,
                    style: DFCTextStyles.body.copyWith(
                      color: DesignTokens.textPrimary,
                    ),
                  ),
                  if (s.url.isNotEmpty) ...[
                    const Spacer(),
                    Text(
                      'Available',
                      style: DFCTextStyles.caption.copyWith(
                        color: DesignTokens.neonGreen,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Export button ──────────────────────────────────────────────────────
  Widget _exportButton() {
    return SizedBox(
      width: double.infinity,
      height: DesignTokens.buttonHeightLarge,
      child: ElevatedButton.icon(
        onPressed: _isExporting ? null : _exportPoster,
        icon: _isExporting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const Icon(Icons.share_rounded, size: 18),
        label: Text(_isExporting ? 'Exporting…' : 'Export & Share Poster'),
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.neonCyan,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          ),
        ),
      ),
    );
  }

  // ── Poster preview area ────────────────────────────────────────────────
  Widget _posterPreviewArea() {
    return Center(
      child: RepaintBoundary(
        key: _posterKey,
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 711),
            child: _selectedStyle == 0
                ? _grittyPoster()
                : _selectedStyle == 1
                ? _cinematicPoster()
                : _cleanPoster(),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // POSTER STYLES
  // ═══════════════════════════════════════════════════════════════════════

  // ── Gritty ─────────────────────────────────────────────────────────────
  Widget _grittyPoster() {
    final bg = ImageAssets.posterForSport(widget.sportType);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        image: DecorationImage(
          image: AssetImage(bg),
          fit: BoxFit.cover,
          colorFilter: const ColorFilter.mode(
            Color(0xCC000000),
            BlendMode.darken,
          ),
        ),
      ),
      child: CustomPaint(
        painter: _GrittyOverlayPainter(),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              // Event title
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: DesignTokens.neonRed.withValues(alpha: 0.8),
                child: Text(
                  _eventCtrl.text.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Fighter 1
              Text(
                _fighter1Ctrl.text.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              // VS
              const Text(
                'VS',
                style: TextStyle(
                  color: DesignTokens.neonRed,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              // Fighter 2
              Text(
                _fighter2Ctrl.text.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              // Venue + Date
              Text(
                _venueCtrl.text,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _dateCtrl.text,
                style: const TextStyle(
                  color: DesignTokens.neonAmber,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              // Ticket CTA
              _ticketCta(DesignTokens.neonRed),
              const SizedBox(height: 12),
              // DFC branding
              _dfcBrand(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Cinematic ──────────────────────────────────────────────────────────
  Widget _cinematicPoster() {
    final bg = ImageAssets.posterForSport(widget.sportType);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const RadialGradient(
          center: Alignment.topCenter,
          radius: 1.4,
          colors: [Color(0xFF1A1A2E), Color(0xFF050510)],
        ),
      ),
      child: Stack(
        children: [
          // Background image with heavy vignette
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(bg, fit: BoxFit.cover),
            ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF050510).withValues(alpha: 0.7),
                    const Color(0xFF050510),
                  ],
                  stops: const [0.0, 0.5, 0.8],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(flex: 3),
                // Event title
                Text(
                  _eventCtrl.text.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: DesignTokens.neonGold,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 20),
                // Fighter 1
                Text(
                  _fighter1Ctrl.text.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 14),
                // VS divider
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 1,
                      color: DesignTokens.neonGold.withValues(alpha: 0.4),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          color: DesignTokens.neonGold,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 1,
                      color: DesignTokens.neonGold.withValues(alpha: 0.4),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Fighter 2
                Text(
                  _fighter2Ctrl.text.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                // Venue + Date
                Text(
                  _venueCtrl.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dateCtrl.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: DesignTokens.neonGold,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                _ticketCta(DesignTokens.neonGold),
                const SizedBox(height: 12),
                _dfcBrand(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Clean ──────────────────────────────────────────────────────────────
  Widget _cleanPoster() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(flex: 2),
            // Event title
            Text(
              _eventCtrl.text.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 20),
            // Fighter 1
            Text(
              _fighter1Ctrl.text.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF000000),
                fontSize: 38,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            // vs
            const Text(
              'vs',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 22,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            // Fighter 2
            Text(
              _fighter2Ctrl.text.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF000000),
                fontSize: 38,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            const Spacer(),
            // Venue + Date
            Text(
              _venueCtrl.text,
              style: const TextStyle(color: Color(0xFF333333), fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              _dateCtrl.text,
              style: const TextStyle(
                color: Color(0xFF000000),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            // Clean CTA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'BUY TICKETS — ALL SELLERS AVAILABLE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // DFC brand
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  ImageAssets.dfcBrandedPlaceholder,
                  width: 20,
                  height: 20,
                  errorBuilder: (_, e, st) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 6),
                const Text(
                  'DATA FIGHT CENTRAL',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────
  Widget _ticketCta(Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            'TICKETS FROM ALL SELLERS',
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ticketek  •  Eventbrite  •  BKFC  •  DFC FightPipe',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dfcBrand() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          ImageAssets.dfcBrandedPlaceholder,
          width: 16,
          height: 16,
          errorBuilder: (_, e, st) => const SizedBox.shrink(),
        ),
        const SizedBox(width: 6),
        Text(
          'DATA FIGHT CENTRAL',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRITTY OVERLAY PAINTER — grain + scratches
// ═══════════════════════════════════════════════════════════════════════════

class _GrittyOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Diagonal scratches
    final scratchPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 30; i++) {
      final x = (size.width / 30) * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.width * 0.15, size.height),
        scratchPaint,
      );
    }

    // Horizontal accent line
    final accentPaint = Paint()
      ..color = DesignTokens.neonRed.withValues(alpha: 0.2)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, size.height * 0.35),
      Offset(size.width * 0.3, size.height * 0.35),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// TICKET SELLER MODEL
// ═══════════════════════════════════════════════════════════════════════════

class _TicketSeller {
  final String name;
  final String url;
  const _TicketSeller(this.name, this.url);
}
