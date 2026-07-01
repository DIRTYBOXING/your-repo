import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/image_assets.dart';
import '../../../shared/models/event_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SPONSOR DECK GENERATOR — One-page sponsor pitch auto-built from event data
///
/// Creates a shareable sponsor activation proposal from EventModel metadata.
/// Includes: event overview, audience reach, activation tiers, contact CTA.
/// Promoters can copy the deck text or share it directly.
/// ═══════════════════════════════════════════════════════════════════════════
class SponsorDeckScreen extends StatefulWidget {
  final EventModel? event;
  final String? eventId;

  const SponsorDeckScreen({super.key, this.event, this.eventId});

  @override
  State<SponsorDeckScreen> createState() => _SponsorDeckScreenState();
}

class _SponsorDeckScreenState extends State<SponsorDeckScreen> {
  late EventModel _event;
  String _promoterName = 'Heath';
  String _promoterEmail = '';
  int _selectedTier = -1;

  @override
  void initState() {
    super.initState();
    _event =
        widget.event ??
        EventModel(
          id: 'custom',
          promoterId: 'self',
          name: 'Your Event Name',
          venue: 'Venue TBA',
          city: 'City',
          country: 'Australia',
          eventDate: DateTime.now().add(const Duration(days: 30)),
          sportType: 'MMA',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildDeckHeader()),
            SliverToBoxAdapter(child: _buildEventOverview()),
            SliverToBoxAdapter(child: _buildAudienceReach()),
            SliverToBoxAdapter(child: _buildActivationTiers()),
            SliverToBoxAdapter(child: _buildDeliverables()),
            SliverToBoxAdapter(child: _buildContactCTA()),
            SliverToBoxAdapter(child: _buildCopyDeckButton()),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: DesignTokens.bgPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Sponsor Deck',
        style: TextStyle(
          color: DesignTokens.neonCyan,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.copy, color: Colors.white70),
          onPressed: _copyDeckToClipboard,
          tooltip: 'Copy deck text',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── DECK HEADER ──────────────────────────────────────────────────
  Widget _buildDeckHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1B2A), Color(0xFF0A1628)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // DFC badge
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(bottom: 12),
            child: Image.asset(
              ImageAssets.dfcBrandedPlaceholder,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.sports_mma,
                color: DesignTokens.neonCyan,
                size: 32,
              ),
            ),
          ),
          const Text(
            'PARTNERSHIP OPPORTUNITY',
            style: TextStyle(
              color: DesignTokens.neonCyan,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _event.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_event.venue} • ${_event.city}, ${_event.country}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, d MMMM yyyy').format(_event.eventDate),
            style: const TextStyle(
              color: DesignTokens.neonAmber,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── EVENT OVERVIEW ───────────────────────────────────────────────
  Widget _buildEventOverview() {
    return _buildSection(
      title: 'Event Overview',
      icon: Icons.event,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _event.description ??
                'A high-energy ${_event.sportType ?? "combat sports"} event with targeted local reach and national streaming potential.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow('Sport', _event.sportType ?? 'Combat Sports'),
          _buildStatRow('Venue', _event.venue),
          _buildStatRow('Location', '${_event.city}, ${_event.country}'),
          _buildStatRow(
            'Date',
            DateFormat('d MMM yyyy').format(_event.eventDate),
          ),
          if (_event.broadcastInfo != null)
            _buildStatRow('Broadcast', _event.broadcastInfo!),
        ],
      ),
    );
  }

  // ── AUDIENCE REACH ───────────────────────────────────────────────
  Widget _buildAudienceReach() {
    return _buildSection(
      title: 'Audience & Reach',
      icon: Icons.groups,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Measurable activations with real-time engagement data.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildReachCard(
                'Venue Capacity',
                '2,000–8,000',
                Icons.stadium,
                DesignTokens.neonCyan,
              ),
              const SizedBox(width: 12),
              _buildReachCard(
                'Stream Reach',
                '10K–50K',
                Icons.live_tv,
                DesignTokens.neonMagenta,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildReachCard(
                'Social Impressions',
                '200K+',
                Icons.trending_up,
                DesignTokens.neonAmber,
              ),
              const SizedBox(width: 12),
              _buildReachCard(
                'Clip Views',
                '500K+',
                Icons.play_circle,
                DesignTokens.neonGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReachCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ACTIVATION TIERS ─────────────────────────────────────────────
  Widget _buildActivationTiers() {
    final tiers = [
      {
        'name': 'Bronze Partner',
        'price': '\$500 – \$1,500',
        'color': const Color(0xFFCD7F32),
        'perks': [
          'Logo on event poster & social posts',
          'Verbal mention during broadcast',
          '1 branded clip post-event',
          'Post-event reach report',
        ],
      },
      {
        'name': 'Silver Partner',
        'price': '\$1,500 – \$5,000',
        'color': const Color(0xFFC0C0C0),
        'perks': [
          'All Bronze benefits',
          'Broadcast overlay branding (30s per round)',
          'On-site banner placement',
          '3 branded clips with metrics',
          'Lead capture via QR activation',
          'Named segment: "brought to you by…"',
        ],
      },
      {
        'name': 'Gold Partner',
        'price': '\$5,000 – \$15,000',
        'color': DesignTokens.neonGold,
        'perks': [
          'All Silver benefits',
          'Title co-brand: "[Event] presented by [Brand]"',
          'Ring canvas / cage mat branding',
          'VIP hospitality suite (8 guests)',
          '10 branded highlight clips',
          'Dedicated social campaign (3-post series)',
          'Exclusive lead capture + sampling access',
          'Full post-event ROI dashboard',
        ],
      },
      {
        'name': 'Platinum Title Sponsor',
        'price': '\$15,000+',
        'color': const Color(0xFFE5E4E2),
        'perks': [
          'All Gold benefits',
          'Full event naming rights',
          'Fighter walkout branding',
          'Custom branded content series (5 videos)',
          'Exclusive category lockout',
          'First right of refusal for next event',
          'Real-time impression tracking dashboard',
          'Dedicated DFC account manager',
        ],
      },
    ];

    return _buildSection(
      title: 'Sponsorship Tiers',
      icon: Icons.workspace_premium,
      child: Column(
        children: tiers.asMap().entries.map((entry) {
          final idx = entry.key;
          final tier = entry.value;
          final color = tier['color'] as Color;
          final selected = _selectedTier == idx;

          return GestureDetector(
            onTap: () => setState(() {
              _selectedTier = selected ? -1 : idx;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.12)
                    : color.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? color.withValues(alpha: 0.5)
                      : color.withValues(alpha: 0.15),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield, color: color, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        tier['name'] as String,
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        tier['price'] as String,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  if (selected) ...[
                    const SizedBox(height: 12),
                    ...(tier['perks'] as List<String>).map(
                      (perk) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: color.withValues(alpha: 0.7),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                perk,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── DELIVERABLES ─────────────────────────────────────────────────
  Widget _buildDeliverables() {
    final items = [
      ('Broadcast Overlays', 'Logo placement during live stream', Icons.tv),
      ('Social Clips', 'Branded highlight clips post-event', Icons.videocam),
      ('On-Site Branding', 'Banners, mat, walkout graphics', Icons.flag),
      ('Lead Capture', 'QR codes, sampling, data collection', Icons.qr_code),
      (
        'ROI Report',
        'Post-event analytics with impressions and leads',
        Icons.analytics,
      ),
      ('VIP Access', 'Hospitality suites and meet & greets', Icons.diamond),
    ];

    return _buildSection(
      title: 'Activation Deliverables',
      icon: Icons.checklist,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items.map((item) {
          return Container(
            width: (MediaQuery.of(context).size.width - 60) / 2,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.$3, color: DesignTokens.neonCyan, size: 20),
                const SizedBox(height: 6),
                Text(
                  item.$1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.$2,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── CONTACT CTA ──────────────────────────────────────────────────
  Widget _buildContactCTA() {
    return _buildSection(
      title: 'Ready to Partner?',
      icon: Icons.handshake,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Short trial package available for this event. '
            '10-minute call to discuss activation fit.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Promoter name input
          _buildTextField(
            label: 'Your Name',
            value: _promoterName,
            onChanged: (v) => setState(() => _promoterName = v),
          ),
          const SizedBox(height: 10),
          _buildTextField(
            label: 'Contact Email',
            value: _promoterEmail,
            onChanged: (v) => setState(() => _promoterEmail = v),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: TextEditingController(text: value),
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: DesignTokens.neonCyan,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  // ── COPY DECK BUTTON ─────────────────────────────────────────────
  Widget _buildCopyDeckButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _copyDeckToClipboard,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [DesignTokens.neonCyan, Color(0xFF00C8CC)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.copy, color: Color(0xFF050A14), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Copy Sponsor Deck',
                      style: TextStyle(
                        color: Color(0xFF050A14),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _copyOutreachEmail,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: DesignTokens.neonAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: DesignTokens.neonAmber.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.email, color: DesignTokens.neonAmber, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Copy Outreach Email',
                      style: TextStyle(
                        color: DesignTokens.neonAmber,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SHARED SECTION WRAPPER ───────────────────────────────────────
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: DesignTokens.neonCyan, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CLIPBOARD ACTIONS ────────────────────────────────────────────
  void _copyDeckToClipboard() {
    final date = DateFormat('d MMMM yyyy').format(_event.eventDate);
    final deck =
        '''
PARTNERSHIP OPPORTUNITY — ${_event.name}

EVENT OVERVIEW
━━━━━━━━━━━━━━━
Sport: ${_event.sportType ?? 'Combat Sports'}
Venue: ${_event.venue}
Location: ${_event.city}, ${_event.country}
Date: $date
${_event.broadcastInfo != null ? 'Broadcast: ${_event.broadcastInfo}' : ''}
${_event.description ?? ''}

AUDIENCE & REACH
━━━━━━━━━━━━━━━
• Venue Capacity: 2,000–8,000
• Live Stream Reach: 10K–50K viewers
• Social Impressions: 200K+
• Post-Event Clip Views: 500K+

SPONSORSHIP TIERS
━━━━━━━━━━━━━━━
Bronze (\$500–\$1,500): Logo placement, verbal mention, 1 branded clip, reach report
Silver (\$1,500–\$5,000): Broadcast overlay, on-site banner, 3 branded clips, lead capture
Gold (\$5,000–\$15,000): Title co-brand, ring branding, VIP suite, 10 clips, ROI dashboard
Platinum (\$15,000+): Naming rights, walkout branding, content series, category lockout

DELIVERABLES
━━━━━━━━━━━━━━━
✓ Broadcast overlays & social clips
✓ On-site branding & lead capture
✓ Post-event ROI analytics report
✓ VIP hospitality access

CONTACT
━━━━━━━━━━━━━━━
${_promoterName.isNotEmpty ? _promoterName : 'Your Name'}
${_promoterEmail.isNotEmpty ? _promoterEmail : 'your@email.com'}
Powered by DataFightCentral
''';

    Clipboard.setData(ClipboardData(text: deck));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sponsor deck copied to clipboard'),
          backgroundColor: DesignTokens.neonCyan,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyOutreachEmail() {
    final date = DateFormat('d MMMM yyyy').format(_event.eventDate);
    final email =
        '''
Subject: Partnership opportunity — ${_event.name}, ${_event.city}, $date

Hi [Name],

We're producing ${_event.name} on $date at ${_event.venue} — a high-energy local ${_event.sportType?.toLowerCase() ?? 'combat sports'} event with targeted local reach and national streaming potential.

We offer measurable activations (on-site, broadcast overlays, social clips) and a short trial package for this event.

Can I send a one-page deck and arrange a quick 10-minute call?

— ${_promoterName.isNotEmpty ? _promoterName : 'Your Name'}
Powered by DataFightCentral
''';

    Clipboard.setData(ClipboardData(text: email));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Outreach email copied to clipboard'),
          backgroundColor: DesignTokens.neonAmber,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
