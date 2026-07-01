import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_cosmetic_widgets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FACEBOOK POST PREVIEW — Compose, preview, and export social posts
/// with UTM links and 3 post variants (Teaser / Launch / Last Chance)
/// ═══════════════════════════════════════════════════════════════════════════

class FacebookPostPreviewScreen extends StatefulWidget {
  final String? eventName;
  final String? date;
  final String? ticketUrl;
  const FacebookPostPreviewScreen({
    super.key,
    this.eventName,
    this.date,
    this.ticketUrl,
  });

  @override
  State<FacebookPostPreviewScreen> createState() =>
      _FacebookPostPreviewScreenState();
}

class _FacebookPostPreviewScreenState extends State<FacebookPostPreviewScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseAnim;
  late final TextEditingController _headlineCtrl;
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _ticketUrlCtrl;
  late final TextEditingController _imageUrlCtrl;

  int _selectedVariant = 0;
  bool _showPreview = false;

  static const _variants = [
    _PostVariant(
      name: 'Teaser',
      icon: Icons.visibility_outlined,
      color: DesignTokens.neonCyan,
      timing: '3 weeks out',
      utmMedium: 'social_post',
      utmCampaign: 'organic_teaser',
      posterNote: 'Clean poster (1080×1350)',
      ctaLabel: 'Buy Tickets',
      pinNote: 'Pin to top of event thread',
    ),
    _PostVariant(
      name: 'Ticket Launch',
      icon: Icons.rocket_launch_outlined,
      color: DesignTokens.neonGold,
      timing: '2 weeks out / paid',
      utmMedium: 'paid_social',
      utmCampaign: 'ticket_launch',
      posterNote: 'Cinematic poster (1080×1350) or 15s motion cut',
      ctaLabel: 'Buy Tickets',
      pinNote: 'Main conversion ad — test 3 creatives × 3 audiences',
    ),
    _PostVariant(
      name: 'Last Chance',
      icon: Icons.timer_outlined,
      color: DesignTokens.neonRed,
      timing: '3 days / 24h out',
      utmMedium: 'retargeting',
      utmCampaign: '48h_push',
      posterNote: 'Gritty poster (1080×1350) or OG crop (1200×628)',
      ctaLabel: 'Buy Tickets / Watch Live',
      pinNote: 'Pin reply with venue, door times, and FAQ',
    ),
  ];

  // Default post bodies per variant
  static const _defaultBodies = [
    // Teaser
    "{fighters} ({location}). Ringside, VIP, and PPV available. Tickets on sale now — grab yours before they're gone.",
    // Ticket Launch
    '{fighters} — limited VIP packages. Secure your spot now.',
    // Last Chance
    "Tonight. Doors 6:00 PM • Main Card 8:00 PM. Last tickets and PPV available — don't miss {fighters}.",
  ];

  @override
  void initState() {
    super.initState();
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    final event = widget.eventName ?? 'Townsville Fight Show';
    final date = widget.date ?? '25 October 2026';
    _headlineCtrl = TextEditingController(text: '$event — $date');
    _bodyCtrl = TextEditingController(
      text: _defaultBodies[0]
          .replaceAll('{fighters}', 'Aze Hepi vs Logan')
          .replaceAll('{location}', 'Queensland')
          .replaceAll('{event}', event),
    );
    _ticketUrlCtrl = TextEditingController(
      text: widget.ticketUrl ?? 'https://tickets.example/townsville',
    );
    _imageUrlCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    _headlineCtrl.dispose();
    _bodyCtrl.dispose();
    _ticketUrlCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  String _buildUtmUrl() {
    final base = _ticketUrlCtrl.text.trim();
    if (base.isEmpty) return '';
    final v = _variants[_selectedVariant];
    final sep = base.contains('?') ? '&' : '?';
    return '$base${sep}utm_source=facebook'
            '&utm_medium=${Uri.encodeComponent(v.utmMedium)}' '&utm_campaign=${Uri.encodeComponent(v.utmCampaign)}';
  }

  void _switchVariant(int index) {
    final event = widget.eventName ?? 'Townsville Fight Show';
    setState(() {
      _selectedVariant = index;
      _bodyCtrl.text = _defaultBodies[index]
          .replaceAll('{fighters}', 'Aze Hepi vs Logan')
          .replaceAll('{location}', 'Queensland')
          .replaceAll('{event}', event);
      _showPreview = false;
    });
  }

  void _copyAll() {
    final url = _buildUtmUrl();
    final full =
        '${_headlineCtrl.text.trim()}\n\n${_bodyCtrl.text.trim()}\n\n$url';
    Clipboard.setData(ClipboardData(text: full));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Post copy + UTM link copied to clipboard'),
        backgroundColor: DesignTokens.neonCyan.withValues(alpha: 0.9),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _buildUtmUrl()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('UTM link copied'),
        backgroundColor: DesignTokens.neonGold.withValues(alpha: 0.9),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: Stack(
        children: [
          const DFCCosmicBackground(
            particleCount: 14,
            primaryColor: Color(0xFF4267B2), // Facebook blue
            secondaryColor: DesignTokens.neonCyan,
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: wide ? _wideLayout() : _narrowLayout()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, a) => Icon(
              Icons.facebook,
              color: const Color(
                0xFF4267B2,
              ).withValues(alpha: 0.6 + _pulseAnim.value * 0.4),
              size: 26,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF4267B2), DesignTokens.neonCyan],
              ).createShader(bounds),
              child: const Text(
                'POST PREVIEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _copyAll,
            icon: const Icon(Icons.copy_all, color: DesignTokens.neonCyan),
            tooltip: 'Copy all',
          ),
        ],
      ),
    );
  }

  // ── Layouts ────────────────────────────────────────────────────────────

  Widget _wideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 10, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _variantSelector(),
                const SizedBox(height: 16),
                _editForm(),
                const SizedBox(height: 16),
                _utmOutput(),
                const SizedBox(height: 16),
                _abTestVariants(),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(10, 0, 20, 20),
            child: _phonePreview(),
          ),
        ),
      ],
    );
  }

  Widget _narrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _variantSelector(),
          const SizedBox(height: 16),
          _editForm(),
          const SizedBox(height: 16),
          _utmOutput(),
          const SizedBox(height: 16),
          _phonePreview(),
          const SizedBox(height: 16),
          _abTestVariants(),
        ],
      ),
    );
  }

  // ── Variant selector ──────────────────────────────────────────────────

  Widget _variantSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'POST VARIANT',
          style: TextStyle(
            color: DesignTokens.neonCyan.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(_variants.length, (i) {
            final v = _variants[i];
            final selected = i == _selectedVariant;
            return Expanded(
              child: GestureDetector(
                onTap: () => _switchVariant(i),
                child: Container(
                  margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? v.color.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? v.color.withValues(alpha: 0.6)
                          : Colors.white12,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        v.icon,
                        color: selected ? v.color : Colors.white38,
                        size: 22,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        v.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected ? v.color : Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        v.timing,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── Edit form ─────────────────────────────────────────────────────────

  Widget _editForm() {
    final v = _variants[_selectedVariant];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecoration.card(accent: v.color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('HEADLINE'),
          _field(_headlineCtrl, 'Event Name — Date'),
          const SizedBox(height: 12),
          _label('POST BODY'),
          TextField(
            controller: _bodyCtrl,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDeco('Write your post body...'),
          ),
          const SizedBox(height: 12),
          _label('TICKET URL'),
          _field(_ticketUrlCtrl, 'https://your-ticket-site.com/event'),
          const SizedBox(height: 12),
          _label('IMAGE URL (optional)'),
          _field(_imageUrlCtrl, 'https://...poster.jpg'),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.image_outlined,
                size: 14,
                color: v.color.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                v.posterNote,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _showPreview = true),
                  icon: const Icon(Icons.preview, size: 18),
                  label: const Text('RENDER PREVIEW'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: v.color,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _copyAll,
                icon: const Icon(Icons.copy_all, color: DesignTokens.neonGold),
                tooltip: 'Copy post + link',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── UTM output ────────────────────────────────────────────────────────

  Widget _utmOutput() {
    final url = _buildUtmUrl();
    if (url.isEmpty) return const SizedBox.shrink();
    final v = _variants[_selectedVariant];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: GlassDecoration.card(accent: DesignTokens.neonGold),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, color: DesignTokens.neonGold, size: 16),
              const SizedBox(width: 6),
              Text(
                'UTM LINK — ${v.name.toUpperCase()}',
                style: TextStyle(
                  color: DesignTokens.neonGold.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _copyLink,
                child: const Icon(
                  Icons.copy,
                  size: 14,
                  color: DesignTokens.neonGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            url,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Phone preview ─────────────────────────────────────────────────────

  Widget _phonePreview() {
    final v = _variants[_selectedVariant];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecoration.card(accent: v.color, hasGlow: _showPreview),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android, color: v.color, size: 16),
              const SizedBox(width: 6),
              Text(
                'FACEBOOK PREVIEW',
                style: TextStyle(
                  color: v.color.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Facebook post card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page header
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [DesignTokens.neonCyan, v.color],
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'DFC',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data Fight Central',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Sponsored · 🌏',
                              style: TextStyle(
                                color: Colors.black45,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.more_horiz,
                        color: Colors.black38,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                // Post body
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _showPreview
                        ? _bodyCtrl.text.trim()
                        : 'Click Render Preview to see your post...',
                    style: TextStyle(
                      color: _showPreview ? Colors.black87 : Colors.black38,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Image placeholder
                Container(
                  width: double.infinity,
                  height: 200,
                  color: _showPreview
                      ? v.color.withValues(alpha: 0.1)
                      : Colors.grey.shade200,
                  child: _showPreview && _imageUrlCtrl.text.trim().isNotEmpty
                      ? Image.network(
                          _imageUrlCtrl.text.trim(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, e, st) => _posterPlaceholder(v),
                        )
                      : _posterPlaceholder(v),
                ),
                // Link preview bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: Colors.grey.shade100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _showPreview
                            ? Uri.tryParse(_ticketUrlCtrl.text.trim())?.host ??
                                  'datafightcentral.com'
                            : 'datafightcentral.com',
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _showPreview
                            ? _headlineCtrl.text.trim()
                            : 'Headline will appear here',
                        style: TextStyle(
                          color: _showPreview ? Colors.black87 : Colors.black38,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // CTA bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.thumb_up_outlined,
                        size: 16,
                        color: Colors.black38,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Like',
                        style: TextStyle(color: Colors.black45, fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: Colors.black38,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Comment',
                        style: TextStyle(color: Colors.black45, fontSize: 12),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4267B2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          v.ctaLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Pin note
          Row(
            children: [
              Icon(
                Icons.push_pin,
                size: 14,
                color: v.color.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  v.pinNote,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _posterPlaceholder(_PostVariant v) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 40,
            color: v.color.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 6),
          Text(
            v.posterNote,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: v.color.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ── A/B test variants ─────────────────────────────────────────────────

  Widget _abTestVariants() {
    const variants = [
      ('Urgency', 'Limited ringside seats — secure yours now.', Icons.timer),
      (
        'Value',
        'Ringside, VIP, and PPV options — pick your experience.',
        Icons.star_outline,
      ),
      (
        'Social Proof',
        'Join hundreds of fight fans — tickets selling fast.',
        Icons.groups_outlined,
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecoration.card(accent: DesignTokens.neonMagenta),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.science_outlined,
                color: DesignTokens.neonMagenta,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'A/B TEST COPY VARIANTS',
                style: TextStyle(
                  color: DesignTokens.neonMagenta.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...variants.map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _bodyCtrl.text = v.$2);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        v.$3,
                        size: 16,
                        color: DesignTokens.neonMagenta.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.$1.toUpperCase(),
                              style: const TextStyle(
                                color: DesignTokens.neonMagenta,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              v.$2,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: _inputDeco(hint),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: DesignTokens.neonCyan),
      ),
    );
  }
}

// ── Data Models ────────────────────────────────────────────────────────────

class _PostVariant {
  final String name;
  final IconData icon;
  final Color color;
  final String timing;
  final String utmMedium;
  final String utmCampaign;
  final String posterNote;
  final String ctaLabel;
  final String pinNote;
  const _PostVariant({
    required this.name,
    required this.icon,
    required this.color,
    required this.timing,
    required this.utmMedium,
    required this.utmCampaign,
    required this.posterNote,
    required this.ctaLabel,
    required this.pinNote,
  });
}
