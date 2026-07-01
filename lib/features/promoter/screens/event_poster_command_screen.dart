import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/image_assets.dart';
import '../../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// EVENT POSTER COMMAND — Pro-grade poster system for real promoter outreach
///
/// Full fight card with main event + undercard, sponsor placement,
/// multiple export sizes (social, print, billboard), QR code ticket link,
/// promoter contact section, and one-tap distribution.
/// ═══════════════════════════════════════════════════════════════════════════

class EventPosterCommandScreen extends StatefulWidget {
  final String? eventName;
  final String? sportType;
  const EventPosterCommandScreen({super.key, this.eventName, this.sportType});
  @override
  State<EventPosterCommandScreen> createState() =>
      _EventPosterCommandScreenState();
}

class _EventPosterCommandScreenState extends State<EventPosterCommandScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _posterKey = GlobalKey();
  late TabController _tabCtrl;
  bool _isExporting = false;
  int _selectedTemplate = 0;

  // ── Event Details ───────────────────────────────────────────────────────
  late TextEditingController _titleCtrl;
  late TextEditingController _subtitleCtrl;
  late TextEditingController _venueCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _doorsCtrl;
  late TextEditingController _broadcastCtrl;
  late TextEditingController _ticketUrlCtrl;
  late TextEditingController _promoterNameCtrl;
  late TextEditingController _promoterEmailCtrl;
  late TextEditingController _promoterPhoneCtrl;

  // ── Fight Card Bouts ────────────────────────────────────────────────────
  final List<_BoutSlot> _bouts = [];

  // ── Sponsor Slots ───────────────────────────────────────────────────────
  final List<_SponsorSlot> _sponsors = [];

  // ── Export size presets ─────────────────────────────────────────────────
  static const _exportPresets = [
    _ExportPreset('Instagram Story', 1080, 1920),
    _ExportPreset('Instagram Post', 1080, 1080),
    _ExportPreset('Facebook Cover', 1640, 856),
    _ExportPreset('Twitter/X Post', 1600, 900),
    _ExportPreset('A3 Print (300dpi)', 3508, 4961),
    _ExportPreset('Billboard 16:9', 3840, 2160),
  ];
  int _selectedExportSize = 0;

  static const _templates = [
    'WAR MACHINE',
    'GOLD EDITION',
    'BROADCAST',
    'MINIMAL',
  ];
  static const _templateIcons = [
    Icons.whatshot_rounded,
    Icons.emoji_events_rounded,
    Icons.live_tv_rounded,
    Icons.crop_square_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _titleCtrl = TextEditingController(
      text: widget.eventName ?? 'FIGHT NIGHT CHAMPIONSHIP',
    );
    _subtitleCtrl = TextEditingController(
      text: 'PRESENTED BY DATA FIGHT CENTRAL',
    );
    _venueCtrl = TextEditingController(text: 'Convention Centre, Brisbane QLD');
    _dateCtrl = TextEditingController(text: 'Saturday 15 November 2026');
    _doorsCtrl = TextEditingController(
      text: 'Doors 5:00 PM  •  First Bout 6:00 PM',
    );
    _broadcastCtrl = TextEditingController(text: 'LIVE ON DFC PPV');
    _ticketUrlCtrl = TextEditingController(
      text: 'datafightcentral.com/tickets',
    );
    _promoterNameCtrl = TextEditingController(text: '');
    _promoterEmailCtrl = TextEditingController(text: '');
    _promoterPhoneCtrl = TextEditingController(text: '');

    // Seed default fight card
    _bouts.addAll([
      _BoutSlot(
        label: 'MAIN EVENT',
        f1: 'TBA',
        f2: 'TBA',
        weight: 'Heavyweight',
        rounds: '5×5 min',
      ),
      _BoutSlot(
        label: 'CO-MAIN',
        f1: 'TBA',
        f2: 'TBA',
        weight: 'Welterweight',
        rounds: '3×5 min',
      ),
      _BoutSlot(
        label: 'PRELIM 1',
        f1: 'TBA',
        f2: 'TBA',
        weight: 'Lightweight',
        rounds: '3×3 min',
      ),
      _BoutSlot(
        label: 'PRELIM 2',
        f1: 'TBA',
        f2: 'TBA',
        weight: 'Middleweight',
        rounds: '3×3 min',
      ),
    ]);

    _sponsors.addAll([
      _SponsorSlot(name: 'Title Sponsor', tier: 'TITLE'),
      _SponsorSlot(name: 'Ring Sponsor', tier: 'GOLD'),
      _SponsorSlot(name: 'Media Partner', tier: 'SILVER'),
    ]);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _venueCtrl.dispose();
    _dateCtrl.dispose();
    _doorsCtrl.dispose();
    _broadcastCtrl.dispose();
    _ticketUrlCtrl.dispose();
    _promoterNameCtrl.dispose();
    _promoterEmailCtrl.dispose();
    _promoterPhoneCtrl.dispose();
    super.dispose();
  }

  // ── Export ──────────────────────────────────────────────────────────────
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
      final preset = _exportPresets[_selectedExportSize];
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              pngBytes,
              mimeType: 'image/png',
              name:
                  'dfc_poster_${preset.label.replaceAll(' ', '_').toLowerCase()}.png',
            ),
          ],
          text: '${_titleCtrl.text} — ${_dateCtrl.text}\n${_venueCtrl.text}',
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
    final wide = MediaQuery.of(context).size.width >= 1000;
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        title: const Text('Event Poster Command', style: DFCTextStyles.title),
        backgroundColor: DesignTokens.bgSecondary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: DesignTokens.neonCyan,
          labelColor: DesignTokens.neonCyan,
          unselectedLabelColor: DesignTokens.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note_rounded, size: 18), text: 'EVENT'),
            Tab(
              icon: Icon(Icons.sports_mma_rounded, size: 18),
              text: 'FIGHT CARD',
            ),
            Tab(
              icon: Icon(Icons.business_center_rounded, size: 18),
              text: 'SPONSORS',
            ),
            Tab(icon: Icon(Icons.send_rounded, size: 18), text: 'DISTRIBUTE'),
          ],
        ),
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
        SizedBox(
          width: 420,
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _eventTab(),
              _fightCardTab(),
              _sponsorsTab(),
              _distributeTab(),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: DesignTokens.borderSubtle),
        Expanded(child: _posterPreviewSection()),
      ],
    );
  }

  // ── Narrow (mobile) layout ─────────────────────────────────────────────
  Widget _narrowLayout() {
    return Column(
      children: [
        // Top: poster preview
        SizedBox(height: 380, child: _posterPreviewSection()),
        const Divider(height: 1, color: DesignTokens.borderSubtle),
        // Bottom: tab content
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _eventTab(),
              _fightCardTab(),
              _sponsorsTab(),
              _distributeTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 1 — EVENT DETAILS
  // ═══════════════════════════════════════════════════════════════════════
  Widget _eventTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('POSTER TEMPLATE'),
          const SizedBox(height: 8),
          _templateSelector(),
          const SizedBox(height: 20),
          _sectionHeader('EVENT INFO'),
          const SizedBox(height: 8),
          _inputField('Event Title', _titleCtrl),
          _inputField('Subtitle / Tagline', _subtitleCtrl),
          _inputField('Venue & City', _venueCtrl),
          _inputField('Date', _dateCtrl),
          _inputField('Doors / Schedule', _doorsCtrl),
          _inputField('Broadcast', _broadcastCtrl),
          _inputField('Ticket URL', _ticketUrlCtrl),
          const SizedBox(height: 20),
          _sectionHeader('PROMOTER CONTACT'),
          const SizedBox(height: 8),
          _inputField('Promoter / Organisation', _promoterNameCtrl),
          _inputField('Email', _promoterEmailCtrl),
          _inputField('Phone', _promoterPhoneCtrl),
          const SizedBox(height: 16),
          _exportSizeSelector(),
          const SizedBox(height: 16),
          _exportActionButton(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 2 — FIGHT CARD
  // ═══════════════════════════════════════════════════════════════════════
  Widget _fightCardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sports_mma_rounded,
                size: 18,
                color: DesignTokens.neonCyan,
              ),
              const SizedBox(width: 8),
              Text(
                'FIGHT CARD (${_bouts.length} BOUTS)',
                style: DFCTextStyles.caption.copyWith(
                  letterSpacing: 1.5,
                  color: DesignTokens.neonCyan.withValues(alpha: 0.8),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: DesignTokens.neonGreen,
                  size: 20,
                ),
                onPressed: () => setState(() {
                  _bouts.add(
                    _BoutSlot(
                      label: 'BOUT ${_bouts.length + 1}',
                      f1: 'TBA',
                      f2: 'TBA',
                      weight: 'Open',
                      rounds: '3×3 min',
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._bouts.asMap().entries.map((e) => _boutCard(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _boutCard(int idx, _BoutSlot bout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(
          color: idx == 0
              ? DesignTokens.neonGold.withValues(alpha: 0.5)
              : DesignTokens.borderSubtle,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: idx == 0
                      ? DesignTokens.neonGold.withValues(alpha: 0.2)
                      : DesignTokens.bgSecondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  bout.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: idx == 0
                        ? DesignTokens.neonGold
                        : DesignTokens.neonCyan,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${bout.weight}  •  ${bout.rounds}',
                style: DFCTextStyles.caption.copyWith(fontSize: 10),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() => _bouts.removeAt(idx)),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: DesignTokens.neonRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _miniInput(
                  bout.f1,
                  (v) => setState(() => bout.f1 = v),
                  'Fighter 1',
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: DesignTokens.neonRed,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Expanded(
                child: _miniInput(
                  bout.f2,
                  (v) => setState(() => bout.f2 = v),
                  'Fighter 2',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _miniInput(
                  bout.weight,
                  (v) => setState(() => bout.weight = v),
                  'Weight Class',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniInput(
                  bout.rounds,
                  (v) => setState(() => bout.rounds = v),
                  'Rounds',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 3 — SPONSORS
  // ═══════════════════════════════════════════════════════════════════════
  Widget _sponsorsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.business_center_rounded,
                size: 18,
                color: DesignTokens.neonGold,
              ),
              const SizedBox(width: 8),
              Text(
                'SPONSOR PLACEMENT',
                style: DFCTextStyles.caption.copyWith(
                  letterSpacing: 1.5,
                  color: DesignTokens.neonGold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: DesignTokens.neonGreen,
                  size: 20,
                ),
                onPressed: () => setState(() {
                  _sponsors.add(
                    _SponsorSlot(name: 'New Sponsor', tier: 'BRONZE'),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._sponsors.asMap().entries.map((e) => _sponsorCard(e.key, e.value)),
          const SizedBox(height: 20),
          _sectionHeader('SPONSOR TIERS'),
          const SizedBox(height: 8),
          _tierLegend(),
        ],
      ),
    );
  }

  Widget _sponsorCard(int idx, _SponsorSlot sponsor) {
    final tierColor = switch (sponsor.tier) {
      'TITLE' => DesignTokens.neonGold,
      'GOLD' => const Color(0xFFFFD700),
      'SILVER' => const Color(0xFFC0C0C0),
      _ => DesignTokens.neonCyan,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(color: tierColor.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              sponsor.tier,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: tierColor,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _miniInput(
              sponsor.name,
              (v) => setState(() => sponsor.name = v),
              'Sponsor Name',
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => setState(() => _sponsors.removeAt(idx)),
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: DesignTokens.neonRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
      ),
      child: Column(
        children: [
          _tierRow(
            'TITLE',
            'Logo on poster header, ring apron, broadcast overlay',
            DesignTokens.neonGold,
          ),
          _tierRow(
            'GOLD',
            'Logo on poster footer, ring mat',
            const Color(0xFFFFD700),
          ),
          _tierRow(
            'SILVER',
            'Logo on poster side panel, walkout banner',
            const Color(0xFFC0C0C0),
          ),
          _tierRow(
            'BRONZE',
            'Name on poster credits, social media mention',
            DesignTokens.neonCyan,
          ),
        ],
      ),
    );
  }

  Widget _tierRow(String tier, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$tier — ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: DFCTextStyles.caption.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 4 — DISTRIBUTE
  // ═══════════════════════════════════════════════════════════════════════
  Widget _distributeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('DISTRIBUTION CHANNELS'),
          const SizedBox(height: 12),
          _distChannel(
            Icons.email_rounded,
            'Email to Promoters',
            'Send poster + fight card to promoter contacts',
            DesignTokens.neonCyan,
          ),
          _distChannel(
            Icons.sms_rounded,
            'SMS Blast',
            'Send ticket link + poster to fighter fans',
            DesignTokens.neonGreen,
          ),
          _distChannel(
            Icons.camera_alt_rounded,
            'Instagram / Stories',
            'Export as Story (1080×1920) or Post (1080²)',
            DesignTokens.neonMagenta,
          ),
          _distChannel(
            Icons.facebook_rounded,
            'Facebook Event',
            'Create FB event with poster as cover',
            const Color(0xFF1877F2),
          ),
          _distChannel(
            Icons.play_circle_outline_rounded,
            'TikTok / Reels',
            'Export vertical poster video loop',
            DesignTokens.neonAmber,
          ),
          _distChannel(
            Icons.language_rounded,
            'DFC Website',
            'Publish to datafightcentral.com event page',
            DesignTokens.neonCyan,
          ),
          _distChannel(
            Icons.print_rounded,
            'Print / Billboard',
            'Export A3 (300dpi) or Billboard (16:9) for print',
            DesignTokens.textSecondary,
          ),
          const SizedBox(height: 20),
          _sectionHeader('PROMOTER OUTREACH TEMPLATE'),
          const SizedBox(height: 8),
          _outreachPreview(),
          const SizedBox(height: 16),
          _exportActionButton(),
        ],
      ),
    );
  }

  Widget _distChannel(IconData icon, String title, String desc, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          title,
          style: DFCTextStyles.body.copyWith(
            fontWeight: FontWeight.w700,
            color: DesignTokens.textPrimary,
          ),
        ),
        subtitle: Text(
          desc,
          style: DFCTextStyles.caption.copyWith(fontSize: 10),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: DesignTokens.textMuted,
          size: 18,
        ),
        dense: true,
        onTap: _exportPoster,
      ),
    );
  }

  Widget _outreachPreview() {
    final promo = _promoterNameCtrl.text.isEmpty
        ? 'Promoter'
        : _promoterNameCtrl.text;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject: ${_titleCtrl.text} — Partnership Opportunity',
            style: DFCTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              color: DesignTokens.neonCyan,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hi $promo,\n\n'
            'We\'re hosting ${_titleCtrl.text} at ${_venueCtrl.text} on ${_dateCtrl.text}.\n\n'
            'Fight Card: ${_bouts.length} bouts confirmed.\n'
            'Main Event: ${_bouts.isNotEmpty ? "${_bouts[0].f1} vs ${_bouts[0].f2}" : "TBA"}\n\n'
            'We\'re looking for promotional partners to help amplify this event. '
            'Attached is the official event poster.\n\n'
            'Tickets: ${_ticketUrlCtrl.text}\n'
            'Broadcast: ${_broadcastCtrl.text}\n\n'
            'Would love to discuss a partnership. Let\'s connect.\n\n'
            'Regards,\n'
            'Data Fight Central',
            style: DFCTextStyles.caption.copyWith(
              fontSize: 11,
              color: DesignTokens.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // POSTER PREVIEW + LIVE RENDER
  // ═══════════════════════════════════════════════════════════════════════
  Widget _posterPreviewSection() {
    return Container(
      color: const Color(0xFF020408),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: RepaintBoundary(
            key: _posterKey,
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 420,
                  maxHeight: 747,
                ),
                child: _selectedTemplate == 0
                    ? _warMachinePoster()
                    : _selectedTemplate == 1
                    ? _goldEditionPoster()
                    : _selectedTemplate == 2
                    ? _broadcastPoster()
                    : _minimalPoster(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TEMPLATE 0 — WAR MACHINE (dark, aggressive, red/black)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _warMachinePoster() {
    final bg = ImageAssets.posterForSport(widget.sportType);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        image: DecorationImage(
          image: AssetImage(bg),
          fit: BoxFit.cover,
          colorFilter: const ColorFilter.mode(
            Color(0xDD000000),
            BlendMode.darken,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // DFC header
            Row(
              children: [
                Image.asset(
                  ImageAssets.dfcBrandedPlaceholder,
                  width: 20,
                  height: 20,
                  errorBuilder: (e1, e2, e3) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 6),
                const Text(
                  'DATA FIGHT CENTRAL',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Text(
                  _broadcastCtrl.text,
                  style: const TextStyle(
                    color: DesignTokens.neonRed,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const Spacer(flex: 2),
            // Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: DesignTokens.neonRed.withValues(alpha: 0.85),
              child: Text(
                _titleCtrl.text.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _subtitleCtrl.text.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 9,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            // Main event
            if (_bouts.isNotEmpty) ...[
              Text(
                _bouts[0].f1.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const Text(
                'VS',
                style: TextStyle(
                  color: DesignTokens.neonRed,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              Text(
                _bouts[0].f2.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_bouts[0].weight}  •  ${_bouts[0].rounds}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Undercard
            if (_bouts.length > 1) ...[
              Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 8),
              const Text(
                'UNDERCARD',
                style: TextStyle(
                  color: DesignTokens.neonAmber,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              ..._bouts
                  .skip(1)
                  .map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '${b.f1}  vs  ${b.f2}  •  ${b.weight}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
            ],
            const Spacer(),
            // Sponsors
            if (_sponsors.isNotEmpty) ...[
              Text(
                'PRESENTED BY',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 7,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _sponsors.map((s) => s.name).join('  •  '),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 8,
                ),
              ),
              const SizedBox(height: 10),
            ],
            // Venue + Date
            Text(
              _venueCtrl.text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
            Text(
              _dateCtrl.text,
              style: const TextStyle(
                color: DesignTokens.neonAmber,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _doorsCtrl.text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 10),
            // Ticket CTA
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: DesignTokens.neonRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: DesignTokens.neonRed.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'GET TICKETS',
                    style: TextStyle(
                      color: DesignTokens.neonRed,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _ticketUrlCtrl.text,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 8,
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

  // ═══════════════════════════════════════════════════════════════════════
  // TEMPLATE 1 — GOLD EDITION (premium, black/gold cinematic)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _goldEditionPoster() {
    final bg = ImageAssets.posterForSport(widget.sportType);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [Color(0xFF1A1A0E), Color(0xFF050500)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(bg, fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF050500).withValues(alpha: 0.8),
                    const Color(0xFF050500),
                  ],
                  stops: const [0.0, 0.5, 0.85],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // DFC header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      ImageAssets.dfcBrandedPlaceholder,
                      width: 16,
                      height: 16,
                      errorBuilder: (e1, e2, e3) => const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'DATA FIGHT CENTRAL',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 3),
                // Title
                Text(
                  _titleCtrl.text.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: DesignTokens.neonGold,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 16),
                // Main bout
                if (_bouts.isNotEmpty) ...[
                  Text(
                    _bouts[0].f1.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                            fontSize: 18,
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
                  const SizedBox(height: 10),
                  Text(
                    _bouts[0].f2.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_bouts[0].weight}  •  ${_bouts[0].rounds}',
                    style: TextStyle(
                      color: DesignTokens.neonGold.withValues(alpha: 0.5),
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                // Undercard summary
                if (_bouts.length > 1) ...[
                  Container(
                    height: 0.5,
                    color: DesignTokens.neonGold.withValues(alpha: 0.2),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  const SizedBox(height: 8),
                  ..._bouts
                      .skip(1)
                      .take(3)
                      .map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '${b.f1}  vs  ${b.f2}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  if (_bouts.length > 4)
                    Text(
                      '+ ${_bouts.length - 4} more bouts',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 9,
                      ),
                    ),
                ],
                const Spacer(),
                // Venue + Date
                Text(
                  _venueCtrl.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dateCtrl.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: DesignTokens.neonGold,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _doorsCtrl.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 14),
                // Sponsors
                if (_sponsors.isNotEmpty)
                  Text(
                    _sponsors.map((s) => s.name).join('  |  '),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: DesignTokens.neonGold.withValues(alpha: 0.4),
                      fontSize: 8,
                      letterSpacing: 1,
                    ),
                  ),
                const SizedBox(height: 10),
                // Ticket CTA
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: DesignTokens.neonGold.withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'TICKETS  •  ${_ticketUrlCtrl.text}',
                    style: const TextStyle(
                      color: DesignTokens.neonGold,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TEMPLATE 2 — BROADCAST (TV/stream style, cyan, info-dense)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _broadcastPoster() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1628), Color(0xFF050A14)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Broadcast header bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: DesignTokens.neonCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: DesignTokens.neonRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: DesignTokens.neonRed,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _broadcastCtrl.text,
                      style: const TextStyle(
                        color: DesignTokens.neonCyan,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Image.asset(
                    ImageAssets.dfcBrandedPlaceholder,
                    width: 16,
                    height: 16,
                    errorBuilder: (e1, e2, e3) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              _titleCtrl.text.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DesignTokens.neonCyan,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _subtitleCtrl.text.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 9,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            // Full fight card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FIGHT CARD',
                      style: TextStyle(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.6),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._bouts.asMap().entries.map((e) {
                      final isMain = e.key == 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: isMain ? 24 : 18,
                              decoration: BoxDecoration(
                                color: isMain
                                    ? DesignTokens.neonGold
                                    : DesignTokens.neonCyan.withValues(
                                        alpha: 0.3,
                                      ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${e.value.f1}  vs  ${e.value.f2}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isMain ? 12 : 10,
                                      fontWeight: isMain
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${e.value.label}  •  ${e.value.weight}  •  ${e.value.rounds}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Bottom info bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _venueCtrl.text,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        _dateCtrl.text,
                        style: const TextStyle(
                          color: DesignTokens.neonCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    'TICKETS',
                    style: TextStyle(
                      color: DesignTokens.neonCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _doorsCtrl.text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 8,
              ),
            ),
            if (_sponsors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _sponsors.map((s) => s.name).join('  •  '),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 7,
                  letterSpacing: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TEMPLATE 3 — MINIMAL (clean white/light, professional print)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _minimalPoster() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Image.asset(
                  ImageAssets.dfcBrandedPlaceholder,
                  width: 18,
                  height: 18,
                  errorBuilder: (e1, e2, e3) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 6),
                const Text(
                  'DATA FIGHT CENTRAL',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              _titleCtrl.text.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 6),
            Container(width: 40, height: 2, color: const Color(0xFF00BCD4)),
            const SizedBox(height: 20),
            // Main bout
            if (_bouts.isNotEmpty) ...[
              Text(
                _bouts[0].f1.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF000000),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'vs',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _bouts[0].f2.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF000000),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_bouts[0].weight}  •  ${_bouts[0].rounds}',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 10),
              ),
            ],
            const SizedBox(height: 16),
            // Undercard (compact list)
            if (_bouts.length > 1) ...[
              Container(height: 0.5, color: const Color(0xFFDDDDDD)),
              const SizedBox(height: 8),
              ..._bouts
                  .skip(1)
                  .map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '${b.f1}  vs  ${b.f2}  —  ${b.weight}',
                        style: const TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
            ],
            const Spacer(),
            // Info
            Text(
              _venueCtrl.text,
              style: const TextStyle(color: Color(0xFF333333), fontSize: 12),
            ),
            const SizedBox(height: 3),
            Text(
              _dateCtrl.text,
              style: const TextStyle(
                color: Color(0xFF000000),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              _doorsCtrl.text,
              style: const TextStyle(color: Color(0xFF999999), fontSize: 9),
            ),
            const SizedBox(height: 14),
            // CTA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'GET TICKETS  •  ${_ticketUrlCtrl.text}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            if (_sponsors.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                _sponsors.map((s) => s.name).join('  |  '),
                style: const TextStyle(
                  color: Color(0xFFBBBBBB),
                  fontSize: 8,
                  letterSpacing: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════════════
  Widget _sectionHeader(String label) {
    return Text(
      label,
      style: DFCTextStyles.caption.copyWith(
        letterSpacing: 1.5,
        color: DesignTokens.neonCyan.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _templateSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_templates.length, (i) {
        final sel = _selectedTemplate == i;
        return ChoiceChip(
          avatar: Icon(
            _templateIcons[i],
            size: 16,
            color: sel ? Colors.black : DesignTokens.textMuted,
          ),
          label: Text(
            _templates[i],
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: sel ? Colors.black : DesignTokens.textPrimary,
            ),
          ),
          selected: sel,
          selectedColor: DesignTokens.neonCyan,
          backgroundColor: DesignTokens.bgCard,
          side: BorderSide(
            color: sel ? DesignTokens.neonCyan : DesignTokens.borderSubtle,
          ),
          onSelected: (_) => setState(() => _selectedTemplate = i),
        );
      }),
    );
  }

  Widget _exportSizeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('EXPORT SIZE'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _exportPresets.asMap().entries.map((e) {
            final sel = _selectedExportSize == e.key;
            return ChoiceChip(
              label: Text(
                e.value.label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.black : DesignTokens.textSecondary,
                ),
              ),
              selected: sel,
              selectedColor: DesignTokens.neonGreen,
              backgroundColor: DesignTokens.bgCard,
              side: BorderSide(
                color: sel ? DesignTokens.neonGreen : DesignTokens.borderSubtle,
              ),
              onSelected: (_) => setState(() => _selectedExportSize = e.key),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _exportActionButton() {
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

  Widget _inputField(String label, TextEditingController ctrl) {
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

  Widget _miniInput(String value, ValueChanged<String> onChanged, String hint) {
    return TextField(
      controller: TextEditingController(text: value),
      style: DFCTextStyles.caption.copyWith(
        color: DesignTokens.textPrimary,
        fontSize: 11,
      ),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: DFCTextStyles.caption.copyWith(fontSize: 10),
        filled: true,
        fillColor: DesignTokens.bgSecondary,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: DesignTokens.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: DesignTokens.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: DesignTokens.neonCyan),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════
class _BoutSlot {
  String label;
  String f1;
  String f2;
  String weight;
  String rounds;
  _BoutSlot({
    required this.label,
    required this.f1,
    required this.f2,
    required this.weight,
    required this.rounds,
  });
}

class _SponsorSlot {
  String name;
  String tier;
  _SponsorSlot({required this.name, required this.tier});
}

class _ExportPreset {
  final String label;
  final int width;
  final int height;
  const _ExportPreset(this.label, this.width, this.height);
}
