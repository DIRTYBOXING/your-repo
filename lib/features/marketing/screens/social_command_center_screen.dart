import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_cosmetic_widgets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SOCIAL COMMAND CENTER — Profiles, content calendar, SEO, UTM, moderation
/// ═══════════════════════════════════════════════════════════════════════════

class SocialCommandCenterScreen extends StatefulWidget {
  const SocialCommandCenterScreen({super.key});

  @override
  State<SocialCommandCenterScreen> createState() =>
      _SocialCommandCenterScreenState();
}

class _SocialCommandCenterScreenState extends State<SocialCommandCenterScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseAnim;
  int _activeTab = 0;

  // ── Profile fields ──
  final _handleCtrl = TextEditingController(text: 'DFC_FightCentral');
  final _emailCtrl = TextEditingController(text: 'hello@datafightcentral.com');
  final _phoneCtrl = TextEditingController(text: '[YOUR_PHONE]');
  final _siteCtrl = TextEditingController(
    text: 'https://www.datafightcentral.com',
  );

  // ── Profiles status ──
  final List<_SocialProfile> _profiles = [
    const _SocialProfile(
      'Facebook Page',
      Icons.facebook,
      DesignTokens.neonCyan,
    ),
    const _SocialProfile(
      'Instagram Business',
      Icons.camera_alt,
      DesignTokens.neonMagenta,
    ),
    const _SocialProfile(
      'TikTok Pro',
      Icons.music_note,
      DesignTokens.neonGold,
    ),
    const _SocialProfile(
      'X (Twitter)',
      Icons.alternate_email,
      Colors.white70,
    ),
    const _SocialProfile(
      'YouTube',
      Icons.play_circle_fill,
      DesignTokens.neonRed,
      status: 'Existing (FightPipe)',
    ),
    const _SocialProfile(
      'LinkedIn Company',
      Icons.business,
      DesignTokens.neonCyan,
    ),
  ];

  // ── Content calendar ──
  final List<_ContentPost> _posts = [
    const _ContentPost(
      0,
      'Pinned: Tickets & PPV Live',
      'Pin',
      'All',
      'Townsville Fight Show — [FIGHTER]. Tickets & PPV live. Buy now: datafightcentral.com?utm_source=facebook&utm_medium=social_post&utm_campaign=launch',
    ),
    const _ContentPost(
      1,
      'Teaser Video (15s)',
      'Reel/TikTok',
      'IG, TT, FB',
      '[FIGHTER] — ready for Townsville. Ringside & PPV at datafightcentral.com',
    ),
    const _ContentPost(
      2,
      'Fighter Bio Card',
      'Feed',
      'All',
      'Photo + 3-line bio and CTA to buy tickets.',
    ),
    const _ContentPost(
      3,
      'Behind the Scenes',
      'Story',
      'IG, FB',
      'Weigh-in clip; tag gym partners.',
    ),
    const _ContentPost(
      4,
      'UGC Ask',
      'Feed',
      'All',
      'Tag a mate who owes you a night out — 2 free PPV codes.',
    ),
    const _ContentPost(
      5,
      'VIP Upsell',
      'Feed',
      'All',
      'VIP package details + limited quantity. Meet & greet + merch bundle.',
    ),
    const _ContentPost(
      6,
      'Social Proof',
      'Story',
      'IG, FB',
      'Screenshot of early ticket sales or sold section.',
    ),
    const _ContentPost(
      7,
      'Media Partner Ask',
      'Feed',
      'FB, LI',
      'Short message to Foxtel/media partners asking for clip license pilot.',
    ),
    const _ContentPost(
      8,
      '7-Day Countdown',
      'Reel/TikTok',
      'All',
      '7-day countdown creative with urgency hook.',
    ),
    const _ContentPost(
      9,
      'Last Chance (24h)',
      'Feed+Story',
      'All',
      '24-hour urgency creative. Final ticket push.',
    ),
    const _ContentPost(
      10,
      'Event Day Live',
      'Live',
      'IG, FB, YT',
      'Live updates, link to PPV, and support contact.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    _handleCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _siteCtrl.dispose();
    super.dispose();
  }

  void _copyBios() {
    final handle = _handleCtrl.text;
    final email = _emailCtrl.text;
    final site = _siteCtrl.text;

    final text =
        '''DFC SOCIAL PROFILE BIOS
${'=' * 50}

NAME: DFC — Data Fight Central
HANDLE: @$handle

SHORT BIO (IG/TikTok):
Promoting grassroots fight nights, PPV & VIP. Townsville roots.
Tickets & streams: $site

LONG BIO (Facebook/LinkedIn):
DFC builds fight nights that sell out and stream. Daily promos,
exclusive behind-the-scenes, and PPV access.
Bookings & partners: $email

PINNED CTA: Buy Tickets / Watch Live → $site

OG IMAGE TEXT:
Townsville Fight Show — Aze Hepi vs Logan — 25 Oct
Tickets & PPV at datafightcentral.com
''';
    Clipboard.setData(ClipboardData(text: text));
    _snack('All profile bios copied');
  }

  void _copySeoTags() {
    final site = _siteCtrl.text;
    final text =
        '''<!-- Basic SEO -->
<title>Townsville Fight Show | Aze Hepi vs Logan — Tickets & PPV</title>
<meta name="description" content="Townsville Fight Show — Aze Hepi vs Logan. Buy ringside tickets or stream live PPV. Secure your seat at datafightcentral.com">

<!-- Open Graph -->
<meta property="og:title" content="Townsville Fight Show — Aze Hepi vs Logan">
<meta property="og:description" content="Ringside tickets and PPV available. Live 25 Oct. Buy now at datafightcentral.com">
<meta property="og:image" content="$site/og-image.jpg">
<meta property="og:url" content="$site">
<meta property="og:type" content="event">

<!-- Twitter / X -->
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="Townsville Fight Show — Aze Hepi vs Logan">
<meta name="twitter:description" content="Ringside tickets and PPV available. Live 25 Oct.">

<!-- Canonical -->
<link rel="canonical" href="$site">

<!-- JSON-LD Event -->
<script type="application/ld+json">
{
  "@context":"https://schema.org",
  "@type":"SportsEvent",
  "name":"Townsville Fight Show — Aze Hepi vs Logan",
  "startDate":"2026-10-25T20:00:00+10:00",
  "location":{"@type":"Place","name":"Townsville Arena","address":"Townsville, QLD"},
  "image":["$site/og-image.jpg"],
  "offers":{"@type":"Offer","url":"$site","priceCurrency":"AUD"}
}
</script>''';
    Clipboard.setData(ClipboardData(text: text));
    _snack('SEO meta tags + JSON-LD copied');
  }

  void _copyContentCalendar() {
    final buf = StringBuffer();
    buf.writeln('DFC CONTENT CALENDAR — FIRST 10 POSTS');
    buf.writeln('=' * 50);
    for (final p in _posts) {
      buf.writeln();
      buf.writeln('Day ${p.day}: ${p.title}');
      buf.writeln('  Format: ${p.format} | Platforms: ${p.platforms}');
      buf.writeln('  Caption: ${p.caption}');
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    _snack('Content calendar copied');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF00FF88)),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: Stack(
        children: [
          const DFCCosmicBackground(
            particleCount: 40,
            primaryColor: DesignTokens.neonCyan,
            secondaryColor: DesignTokens.neonMagenta,
          ),
          SafeArea(
            child: Column(
              children: [
                _header(),
                _tabBar(),
                Expanded(child: _tabBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, a) => Icon(
              Icons.hub,
              color: Color.lerp(
                DesignTokens.neonCyan,
                DesignTokens.neonMagenta,
                _pulseAnim.value,
              ),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SOCIAL COMMAND CENTER',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Profiles · Content · SEO · UTM · Moderation',
                  style: TextStyle(color: DesignTokens.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    const tabs = ['Profiles', 'Content', 'SEO & UTM', 'Moderation'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final sel = i == _activeTab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: sel
                      ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                      : DesignTokens.bgCard,
                  border: Border.all(
                    color: sel
                        ? DesignTokens.neonCyan
                        : DesignTokens.neonCyan.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    color: sel ? DesignTokens.neonCyan : Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _tabBody() {
    switch (_activeTab) {
      case 0:
        return _profilesTab();
      case 1:
        return _contentTab();
      case 2:
        return _seoTab();
      case 3:
        return _moderationTab();
      default:
        return _profilesTab();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 0: PROFILES
  // ═══════════════════════════════════════════════════════════════════════

  Widget _profilesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionLabel('BRAND IDENTITY'),
        const SizedBox(height: 8),
        _inputField(_handleCtrl, 'Handle (@)', DesignTokens.neonCyan),
        const SizedBox(height: 8),
        _inputField(_emailCtrl, 'Business Email', DesignTokens.neonGold),
        const SizedBox(height: 8),
        _inputField(_phoneCtrl, 'Phone', DesignTokens.neonMagenta),
        const SizedBox(height: 8),
        _inputField(_siteCtrl, 'Website URL', DesignTokens.neonGreen),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text('COPY ALL BIOS'),
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.neonCyan,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _copyBios,
        ),
        const SizedBox(height: 20),
        _sectionLabel('PLATFORM STATUS'),
        const SizedBox(height: 8),
        ...List.generate(_profiles.length, (i) {
          final p = _profiles[i];
          final done = p.status != 'Create';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _profiles[i] = _SocialProfile(
                    p.name,
                    p.icon,
                    p.color,
                    status: done ? 'Create' : 'Live',
                  );
                });
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: done
                      ? DesignTokens.neonGreen.withValues(alpha: 0.08)
                      : DesignTokens.bgCard,
                  border: Border.all(
                    color: done
                        ? DesignTokens.neonGreen
                        : p.color.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(p.icon, color: p.color, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: done
                            ? DesignTokens.neonGreen.withValues(alpha: 0.2)
                            : DesignTokens.neonAmber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.status,
                        style: TextStyle(
                          color: done
                              ? DesignTokens.neonGreen
                              : DesignTokens.neonAmber,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        _sectionLabel('SECURITY CHECKLIST'),
        const SizedBox(height: 8),
        _checkItem('Set up Meta Business Suite + Ad Account'),
        _checkItem('Enable two-factor authentication on all accounts'),
        _checkItem('Add backup admin (trusted partner)'),
        _checkItem('Store credentials in password manager'),
        _checkItem('Make personal profiles private'),
        _checkItem('Apply for verification once ticket sales start'),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 1: CONTENT CALENDAR
  // ═══════════════════════════════════════════════════════════════════════

  Widget _contentTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _sectionLabel(
                  'FIRST 10 POSTS + LAUNCH KIT (${_posts.length} items)',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: DesignTokens.neonGreen),
                tooltip: 'Copy full calendar',
                onPressed: _copyContentCalendar,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _posts.length,
            itemBuilder: (_, i) {
              final p = _posts[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: GlassDecoration.card(
                    accent: i == 0
                        ? DesignTokens.neonGold
                        : DesignTokens.neonCyan,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.neonCyan.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Day ${p.day}',
                              style: const TextStyle(
                                color: DesignTokens.neonCyan,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.neonMagenta.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              p.format,
                              style: const TextStyle(
                                color: DesignTokens.neonMagenta,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            p.platforms,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: p.caption));
                              _snack('Post ${p.day} caption copied');
                            },
                            child: const Icon(
                              Icons.copy,
                              color: Colors.white38,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.caption,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 2: SEO & UTM
  // ═══════════════════════════════════════════════════════════════════════

  Widget _seoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionLabel('SEO META TAGS + JSON-LD'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: GlassDecoration.card(accent: DesignTokens.neonGold),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Copy-ready HTML for <head>',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'OG tags, Twitter cards, canonical URL, and JSON-LD SportsEvent schema — all generated from your site URL.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.code),
                  label: const Text('COPY SEO TAGS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.neonGold,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _copySeoTags,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sectionLabel('UTM RULES (MUST ENFORCE)'),
        const SizedBox(height: 8),
        _utmRule(
          'Canonical URL',
          'Always use ${_siteCtrl.text} as the base',
          DesignTokens.neonCyan,
        ),
        _utmRule(
          'Template',
          '?utm_source={platform}&utm_medium={paid|organic|sms}&utm_campaign={campaign}',
          DesignTokens.neonGold,
        ),
        _utmRule(
          'Facebook Paid',
          '?utm_source=facebook&utm_medium=paid_social&utm_campaign=ticket_launch',
          DesignTokens.neonMagenta,
        ),
        _utmRule(
          'TikTok Organic',
          '?utm_source=tiktok&utm_medium=organic&utm_campaign=teaser',
          DesignTokens.neonGreen,
        ),
        _utmRule(
          'SMS Push',
          '?utm_source=sms&utm_medium=sms&utm_campaign=last_chance',
          DesignTokens.neonAmber,
        ),
        const SizedBox(height: 20),
        _sectionLabel('PIXEL & TRACKING'),
        const SizedBox(height: 8),
        _trackingItem(
          Icons.visibility,
          'Meta Pixel',
          'Server-side events: view_content, add_to_cart, initiate_checkout, purchase',
        ),
        _trackingItem(
          Icons.analytics,
          'GA4',
          'Purchase events + cross-domain tracking for PPV',
        ),
        _trackingItem(
          Icons.token,
          'PPV Tokens',
          'Single-use, tied to email/phone, 2-device limit, expiry at event end',
        ),
        _trackingItem(
          Icons.table_chart,
          'Daily CSV',
          'transaction_id, timestamp, product, gross, fees, net, buyer_email, utm_source',
        ),
        _trackingItem(
          Icons.dashboard,
          'Dashboard',
          'Real-time viewers, revenue, refunds, geo breakdown',
        ),
        const SizedBox(height: 20),
        _sectionLabel('RETARGETING WINDOWS'),
        const SizedBox(height: 8),
        _retargetRow(
          '0–3 days',
          'Video viewers 3s/10s/25% → site visitors',
          DesignTokens.neonCyan,
        ),
        _retargetRow(
          '3–7 days',
          'Add-to-cart → checkout abandoners',
          DesignTokens.neonGold,
        ),
        _retargetRow(
          'Last 72h',
          'SMS + email + dynamic creative urgency',
          DesignTokens.neonRed,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 3: MODERATION
  // ═══════════════════════════════════════════════════════════════════════

  Widget _moderationTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionLabel('COMMUNITY & MODERATION RULES'),
        const SizedBox(height: 8),
        _modRule('Set a short comment policy and pin it to the Page'),
        _modRule('Assign moderators for live chat + comments during events'),
        _modRule(
          'Use canned responses: tickets, PPV access, refunds, schedule',
        ),
        _modRule(
          'Escalation: refund/chargeback → ops lead; playback → stream engineer',
        ),
        const SizedBox(height: 20),
        _sectionLabel('ADMIN ROLES & SECURITY'),
        const SizedBox(height: 8),
        _roleRow('Admin', 'You (Logan)', DesignTokens.neonGold),
        _roleRow('Editor', 'Campaign lead', DesignTokens.neonCyan),
        _roleRow('Advertiser', 'Media buyer', DesignTokens.neonMagenta),
        _roleRow('Analyst', 'Reporting access', DesignTokens.neonGreen),
        _roleRow('Backup Admin', 'Trusted partner', DesignTokens.neonAmber),
        const SizedBox(height: 20),
        _sectionLabel('GROWTH HACKS'),
        const SizedBox(height: 8),
        _growthItem('Cross-post short clips to Reels, TikTok, YouTube Shorts'),
        _growthItem('Share incentives: promo codes for fans who share + tag'),
        _growthItem(
          'Micro-influencer program: 5 local, unique promo codes, pay per sale',
        ),
        _growthItem(
          'Clip licensing pilot: pitch Foxtel/Kayo for one clip as credibility boost',
        ),
        _growthItem(
          'Email + SMS capture: gate PPV with email/phone for last-minute pushes',
        ),
        const SizedBox(height: 20),
        _sectionLabel('LEGAL & COPYRIGHT'),
        const SizedBox(height: 8),
        _legalItem('Never post Foxtel/Kayo clips without written license'),
        _legalItem(
          'Collect consent for marketing when capturing emails/phones',
        ),
        _legalItem('Publish clear refund policy for PPV and tickets'),
        _legalItem('Keep daily CSVs for audits and reconciliation'),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: DesignTokens.neonCyan.withValues(alpha: 0.7),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String label, Color accent) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: accent.withValues(alpha: 0.7),
          fontSize: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: accent.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: accent),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: DesignTokens.bgCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }

  Widget _checkItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(
            Icons.check_box_outline_blank,
            color: DesignTokens.neonAmber,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _utmRule(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              value,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trackingItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: DesignTokens.neonGold, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  TextSpan(
                    text: desc,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _retargetRow(String window, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              window,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modRule(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield, color: DesignTokens.neonAmber, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleRow(String role, String person, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              role,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              person,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _growthItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.trending_up,
            color: DesignTokens.neonGreen,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legalItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gavel, color: DesignTokens.neonRed, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════════════════

class _SocialProfile {
  final String name;
  final IconData icon;
  final Color color;
  final String status;
  const _SocialProfile(
    this.name,
    this.icon,
    this.color, {
    this.status = 'Create',
  });
}

class _ContentPost {
  final int day;
  final String title;
  final String format;
  final String platforms;
  final String caption;
  const _ContentPost(
    this.day,
    this.title,
    this.format,
    this.platforms,
    this.caption,
  );
}
