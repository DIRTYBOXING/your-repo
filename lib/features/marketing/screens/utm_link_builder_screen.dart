import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_cosmetic_widgets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// UTM LINK BUILDER — Build tracked marketing links for any channel
/// ═══════════════════════════════════════════════════════════════════════════

class UtmLinkBuilderScreen extends StatefulWidget {
  final String? baseUrl;
  const UtmLinkBuilderScreen({super.key, this.baseUrl});

  @override
  State<UtmLinkBuilderScreen> createState() => _UtmLinkBuilderScreenState();
}

class _UtmLinkBuilderScreenState extends State<UtmLinkBuilderScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseAnim;
  late final TextEditingController _baseUrlCtrl;
  final _sourceCtrl = TextEditingController(text: 'facebook');
  final _mediumCtrl = TextEditingController(text: 'paid_social');
  final _campaignCtrl = TextEditingController(text: 'ticket_launch');
  final _termCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  String _generatedUrl = '';
  final List<_UtmHistoryEntry> _history = [];
  int _selectedPreset = -1;

  static const _presets = [
    _UtmPreset('Facebook Paid', 'facebook', 'paid_social', 'ticket_launch'),
    _UtmPreset('Facebook Organic', 'facebook', 'social_post', 'organic_teaser'),
    _UtmPreset('Retargeting', 'facebook', 'retargeting', '48h_push'),
    _UtmPreset('Email Blast', 'email', 'newsletter', 'event_announce'),
    _UtmPreset('SMS Alert', 'sms', 'text_message', 'ticket_alert'),
    _UtmPreset('Instagram', 'instagram', 'social_post', 'ig_story'),
    _UtmPreset('Google Ads', 'google', 'cpc', 'search_campaign'),
    _UtmPreset('TikTok', 'tiktok', 'social_post', 'clip_promo'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _baseUrlCtrl = TextEditingController(
      text: widget.baseUrl ?? 'https://datafightcentral.com/tickets/event',
    );
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    _baseUrlCtrl.dispose();
    _sourceCtrl.dispose();
    _mediumCtrl.dispose();
    _campaignCtrl.dispose();
    _termCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _buildLink() {
    final base = _baseUrlCtrl.text.trim();
    if (base.isEmpty) return;

    final params = <String, String>{};
    void add(String key, String value) {
      final v = value.trim();
      if (v.isNotEmpty) params[key] = v;
    }

    add('utm_source', _sourceCtrl.text);
    add('utm_medium', _mediumCtrl.text);
    add('utm_campaign', _campaignCtrl.text);
    add('utm_term', _termCtrl.text);
    add('utm_content', _contentCtrl.text);

    final queryString = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    final separator = base.contains('?') ? '&' : '?';
    final url = '$base$separator$queryString';

    setState(() {
      _generatedUrl = url;
      _history.insert(
        0,
        _UtmHistoryEntry(
          url: url,
          source: _sourceCtrl.text.trim(),
          campaign: _campaignCtrl.text.trim(),
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        backgroundColor: DesignTokens.neonCyan.withValues(alpha: 0.9),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _applyPreset(int index) {
    final p = _presets[index];
    setState(() {
      _selectedPreset = index;
      _sourceCtrl.text = p.source;
      _mediumCtrl.text = p.medium;
      _campaignCtrl.text = p.campaign;
    });
  }

  void _exportHistory() {
    if (_history.isEmpty) return;
    final csv = StringBuffer('source,campaign,url,timestamp\n');
    for (final e in _history) {
      csv.writeln(
        '${e.source},${e.campaign},${e.url},${e.timestamp.toIso8601String()}',
      );
    }
    Clipboard.setData(ClipboardData(text: csv.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_history.length} links exported to clipboard as CSV'),
        backgroundColor: DesignTokens.neonGreen.withValues(alpha: 0.9),
        duration: const Duration(seconds: 2),
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
            particleCount: 16,
            primaryColor: DesignTokens.neonCyan,
            secondaryColor: DesignTokens.neonGold,
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
              Icons.link,
              color: DesignTokens.neonCyan.withValues(
                alpha: 0.6 + _pulseAnim.value * 0.4,
              ),
              size: 26,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [DesignTokens.neonCyan, DesignTokens.neonGold],
              ).createShader(bounds),
              child: const Text(
                'UTM LINK BUILDER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          if (_history.isNotEmpty)
            IconButton(
              onPressed: _exportHistory,
              icon: const Icon(Icons.download, color: DesignTokens.neonGold),
              tooltip: 'Export CSV',
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
                _presetChips(),
                const SizedBox(height: 16),
                _formSection(),
                const SizedBox(height: 16),
                _outputSection(),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(10, 0, 20, 20),
            child: _historySection(),
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
          _presetChips(),
          const SizedBox(height: 16),
          _formSection(),
          const SizedBox(height: 16),
          _outputSection(),
          const SizedBox(height: 24),
          _historySection(),
        ],
      ),
    );
  }

  // ── Presets ────────────────────────────────────────────────────────────

  Widget _presetChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK PRESETS',
          style: TextStyle(
            color: DesignTokens.neonCyan.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_presets.length, (i) {
            final p = _presets[i];
            final selected = i == _selectedPreset;
            return ChoiceChip(
              label: Text(p.name),
              selected: selected,
              selectedColor: DesignTokens.neonCyan.withValues(alpha: 0.2),
              backgroundColor: DesignTokens.bgCard,
              labelStyle: TextStyle(
                color: selected ? DesignTokens.neonCyan : Colors.white70,
                fontSize: 12,
              ),
              side: BorderSide(
                color: selected
                    ? DesignTokens.neonCyan.withValues(alpha: 0.6)
                    : Colors.white12,
              ),
              onSelected: (_) => _applyPreset(i),
            );
          }),
        ),
      ],
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────

  Widget _formSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecoration.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('BASE TICKET URL'),
          _textField(
            _baseUrlCtrl,
            'https://datafightcentral.com/tickets/event',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('SOURCE'),
                    _textField(_sourceCtrl, 'facebook'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('MEDIUM'),
                    _textField(_mediumCtrl, 'paid_social'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('CAMPAIGN'),
                    _textField(_campaignCtrl, 'ticket_launch'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('TERM (optional)'),
                    _textField(_termCtrl, 'bkfc_fans'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('CONTENT (optional)'),
                    _textField(_contentCtrl, 'hero_banner'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _buildLink,
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('BUILD UTM LINK'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.neonCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              if (_generatedUrl.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _copyToClipboard(_generatedUrl),
                  icon: const Icon(Icons.copy, color: DesignTokens.neonGold),
                  tooltip: 'Copy link',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Output ────────────────────────────────────────────────────────────

  Widget _outputSection() {
    if (_generatedUrl.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: GlassDecoration.card(
        accent: DesignTokens.neonGold,
        hasGlow: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: DesignTokens.neonGreen,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'GENERATED LINK',
                style: TextStyle(
                  color: DesignTokens.neonGold.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _copyToClipboard(_generatedUrl),
            child: Text(
              _generatedUrl,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniAction(
                'Copy',
                Icons.copy,
                () => _copyToClipboard(_generatedUrl),
              ),
              const SizedBox(width: 8),
              _miniAction('Build Another', Icons.refresh, () {
                setState(() => _generatedUrl = '');
              }),
            ],
          ),
        ],
      ),
    );
  }

  // ── History ───────────────────────────────────────────────────────────

  Widget _historySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecoration.card(accent: DesignTokens.neonGold),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: DesignTokens.neonGold, size: 18),
              const SizedBox(width: 8),
              Text(
                'LINK HISTORY (${_history.length})',
                style: TextStyle(
                  color: DesignTokens.neonGold.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              if (_history.isNotEmpty)
                GestureDetector(
                  onTap: _exportHistory,
                  child: Text(
                    'EXPORT CSV',
                    style: TextStyle(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_history.isEmpty)
            Text(
              'No links built yet.\nUse the form above to generate tracked URLs.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            )
          else
            ...List.generate(
              _history.length > 20 ? 20 : _history.length,
              (i) => _historyTile(_history[i]),
            ),
        ],
      ),
    );
  }

  Widget _historyTile(_UtmHistoryEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _copyToClipboard(entry.url),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.source.toUpperCase(),
                      style: const TextStyle(
                        color: DesignTokens.neonCyan,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.campaign,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.copy,
                    size: 12,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                entry.url,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Widget _fieldLabel(String text) {
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

  Widget _textField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
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
      ),
    );
  }

  Widget _miniAction(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: DesignTokens.neonCyan),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data Models ────────────────────────────────────────────────────────────

class _UtmPreset {
  final String name;
  final String source;
  final String medium;
  final String campaign;
  const _UtmPreset(this.name, this.source, this.medium, this.campaign);
}

class _UtmHistoryEntry {
  final String url;
  final String source;
  final String campaign;
  final DateTime timestamp;
  const _UtmHistoryEntry({
    required this.url,
    required this.source,
    required this.campaign,
    required this.timestamp,
  });
}
