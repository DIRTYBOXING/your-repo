import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_cosmetic_widgets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PROMOTER OUTREACH HQ — Email/DM templates, call scripts, pilot proposals
/// ═══════════════════════════════════════════════════════════════════════════

class PromoterOutreachHqScreen extends StatefulWidget {
  const PromoterOutreachHqScreen({super.key});

  @override
  State<PromoterOutreachHqScreen> createState() =>
      _PromoterOutreachHqScreenState();
}

class _PromoterOutreachHqScreenState extends State<PromoterOutreachHqScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseAnim;

  // ── Placeholders ──
  final _promoterNameCtrl = TextEditingController(text: '[Promoter Name]');
  final _eventNameCtrl = TextEditingController(text: 'Townsville Fight Show');
  final _eventDateCtrl = TextEditingController(text: '25 Oct 2026');
  final _fighterNameCtrl = TextEditingController(text: 'Aze Hepi');
  final _guaranteeCtrl = TextEditingController(text: '[GUARANTEE_AMOUNT]');
  final _adBudgetCtrl = TextEditingController(text: '500–1,000');
  final _ticketUrlCtrl = TextEditingController(text: '[LIVE_TICKET_URL]');
  final _phoneCtrl = TextEditingController(text: '[YOUR_PHONE]');
  final _timeRangeCtrl = TextEditingController(text: '[TIME RANGE]');

  int _selectedTemplate = 0;

  static const _templateNames = [
    'Escrow + Term Sheet Email',
    'Confirm 85/15 Terms Email',
    'Foxtel Media Outreach',
    'Short DM (Instagram/FB)',
    'Call Script',
    'Follow-up Nudge',
    'LinkedIn Outreach',
    'Promoter Pitch Deck Intro',
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
    _promoterNameCtrl.dispose();
    _eventNameCtrl.dispose();
    _eventDateCtrl.dispose();
    _fighterNameCtrl.dispose();
    _guaranteeCtrl.dispose();
    _adBudgetCtrl.dispose();
    _ticketUrlCtrl.dispose();
    _phoneCtrl.dispose();
    _timeRangeCtrl.dispose();
    super.dispose();
  }

  String _fillTemplate(String raw) {
    return raw
        .replaceAll('[Promoter Name]', _promoterNameCtrl.text)
        .replaceAll('[EVENT_NAME]', _eventNameCtrl.text)
        .replaceAll('[EVENT_DATE]', _eventDateCtrl.text)
        .replaceAll('[FIGHTER_NAME]', _fighterNameCtrl.text)
        .replaceAll('[GUARANTEE_AMOUNT]', _guaranteeCtrl.text)
        .replaceAll('[AD_BUDGET]', _adBudgetCtrl.text)
        .replaceAll('[LIVE_TICKET_URL]', _ticketUrlCtrl.text)
        .replaceAll('[YOUR_PHONE]', _phoneCtrl.text)
        .replaceAll('[TIME RANGE]', _timeRangeCtrl.text);
  }

  void _copyTemplate() {
    final body = _fillTemplate(_templates[_selectedTemplate]);
    Clipboard.setData(ClipboardData(text: body));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_templateNames[_selectedTemplate]} copied'),
        backgroundColor: const Color(0xFF00FF88),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TEMPLATES
  // ═══════════════════════════════════════════════════════════════════════

  static const _templates = [
    // 0 — Escrow + Term Sheet Email
    '''Subject: Urgent — Confirm Terms, Escrow, and PPV Integration for [EVENT_NAME]

Hi [Promoter Name],

This is DFC (Logan) representing [FIGHTER_NAME]. Attached is the one-page term sheet and MOU for [EVENT_NAME] ([EVENT_DATE]).

Required actions within 72 hours:
(1) Deposit AUD [GUARANTEE_AMOUNT] into escrow at [ESCROW_ACCOUNT_DETAILS] and send confirmation.
(2) Grant read-only access to ticketing dashboard and Meta pixel.
(3) Provide PPV provider details and API/CSV access.

Deal summary (85/15 sliding split):
- Tier 1 (0-AUD 25,000): Promoter 15% / Fighter 85%
- Tier 2 (25,001-75,000): Promoter 25% / Fighter 75%
- Tier 3 (75,001-200,000): Promoter 35% / Fighter 65%
- Tier 4 (Above 200,000): Promoter 50% / Fighter 50%

Ad spend remains paused until escrow and access are confirmed. If you agree, sign and return the attached term sheet and I will schedule the T-7 E2E PPV test.

Best,
DFC (Logan)
Phone: [YOUR_PHONE]
Ticket URL: [LIVE_TICKET_URL]''',

    // 1 — Confirm 85/15 Terms Email
    '''Subject: Urgent — Confirm 85/15 Sliding Terms and Launch Timeline for [EVENT_NAME]

Hi [Promoter Name],

This is DFC (Logan) representing [FIGHTER_NAME]. I built the promo engine and I am ready to activate, but I need written confirmation of terms and access before I resume paid spend.

Key terms to confirm within 48 hours:
- Revenue split: 85/15 sliding — Promoter 15% / Fighter 85% floor, scaling as revenue grows.
- Guarantee: Promoter deposits AUD [GUARANTEE_AMOUNT] into escrow within 72 hours of signing.
- Marketing spend: Pilot AUD [AD_BUDGET]; regional scale AUD 3,000 (promoter funds unless agreed).
- PPV revenue: Net PPV revenue follows sliding tiers after platform fees.
- Reporting: Daily sales CSV, read-only access to ticketing dashboard, Meta pixel, and PPV reporting.
- Exclusivity: DFC has exclusive digital activation rights in territory for the event duration.
- Payment timing: Promoter pays fighter within 7 days of event; final reconciliation within 14 days.
- Escrow: Funds in escrow applied to guarantee and final reconciliation. Paid activation paused until funded.

Please confirm by signing the attached one-page term sheet and grant read-only access within 24 hours. Ad spend remains paused until I receive signed confirmation, escrow funded, and access granted.

Available for a call today between [TIME RANGE].
Best,
DFC (Logan)
Phone: [YOUR_PHONE]
Ticket URL: [LIVE_TICKET_URL]''',

    // 2 — Foxtel Media Outreach
    '''Subject: Clip license and co-promo pilot request — [EVENT_NAME] [EVENT_DATE] — DFC

Hi Foxtel Media Team,

I am DFC (Logan) promoting [EVENT_NAME] ([EVENT_DATE]) featuring [FIGHTER_NAME]. I request a short pilot license to use one Foxtel/Kayo clip on our event page and social channels in exchange for pinned promo placement and UTM-tracked performance data.

Pilot ask:
- One clip for 7 days on our event page and social channels.
- Delivery: MP4 H.264 1080p or signed embed code.
- Measurement: UTM links for every clip; daily CSV of clicks and conversions.
- KPI window: 7 days; metrics: impressions, CTR, landing CVR, ticket sales, PPV buys.

If you are open to a pilot, please advise the licensing contact and delivery format. I will send a one-page MOU and the UTM'd landing page immediately.

Thanks,
DFC (Logan)
Phone: [YOUR_PHONE]
Ticket URL: [LIVE_TICKET_URL]''',

    // 3 — Short DM (Instagram / Facebook)
    '''Hi — DFC (Logan) here. I have emailed a one-page term sheet for [EVENT_NAME] featuring [FIGHTER_NAME]. Need escrow confirmation (AUD [GUARANTEE_AMOUNT]) and pixel/ticket access within 72 hours or I pause paid activation. Can we do a 10-minute call today?''',

    // 4 — Call Script
    '''CALL SCRIPT — [EVENT_NAME]

OPEN:
"Hi [Promoter Name], it is Logan from DFC. Quick call — I have sent the term sheet and need escrow confirmation and pixel access to start the pilot. Can you confirm who will fund the escrow and when we can get read-only access?"

TERMS:
"We start 85/15 to cover fighter risk and grassroots activation. As the event outperforms, the split slides so you capture upside — fair and measurable."
"Pilot: AUD [AD_BUDGET] spend; I run creative and ops; you get daily reporting and read-only access."

CLOSE:
"If you confirm escrow and access today I will schedule the T-7 E2E test and start a small pilot spend to prove uplift."

IF THEY STALL:
"No pixel access, no paid activation. I will run organic only until we have signed terms and escrow funded."

IF THEY PUSH BACK ON 85/15:
"We can add a small promoter advance or reduce T1 threshold, but the 85/15 floor stays — it is how I cover fighter risk and mobilize grassroots."

NON-NEGOTIABLE:
"Daily CSVs, read-only pixel/ticketing access, guarantee in escrow before paid activation."
"No pixel access, no paid activation — that is non-negotiable."
"We need signed PPV integration confirmation and a successful end-to-end test within 72 hours or I withdraw digital activation."''',

    // 5 — Follow-up Nudge
    '''Subject: Follow-up — [EVENT_NAME] pilot terms (48hr deadline)

Hi [Promoter Name],

Following up on my proposal from earlier this week. The 48-hour deadline for pilot terms confirmation is approaching.

Quick recap of what I need:
1. Signed one-page term sheet (attached again for convenience).
2. Escrow deposit of AUD [GUARANTEE_AMOUNT] — account details in the term sheet.
3. Read-only access to Meta pixel + ticketing dashboard.
4. Confirmation of ad budget (AUD [AD_BUDGET]).

All paid spend remains paused until I have the above confirmed in writing. I am ready to launch creative and begin the 7-day pilot within 48 hours of signed terms and funded escrow.

If no response by [EVENT_DATE minus 14 days], I will pause all promotion activities.

Let me know if you need a quick call to finalize — available today [TIME RANGE].

Best,
DFC (Logan)
Phone: [YOUR_PHONE]''',

    // 6 — LinkedIn Outreach
    '''Hi [Promoter Name], I am DFC (Logan) promoting [EVENT_NAME] featuring [FIGHTER_NAME]. I have sent a one-page term sheet with an 85/15 sliding revenue split and request a short pilot to prove uplift. Can we schedule 15 minutes to confirm escrow and PPV access?''',

    // 7 — Promoter Pitch Deck Intro
    '''Subject: Partnership Opportunity — DFC Promotion Engine for [EVENT_NAME]

Hi [Promoter Name],

DFC (Data Fight Central) is a grassroots fight promotion platform that sells out events and streams PPV. We are proposing a partnership for [EVENT_NAME] ([EVENT_DATE]) featuring [FIGHTER_NAME].

What we bring:
- Full-stack promotion engine: social, paid ads, UTM tracking, daily reporting.
- 85/15 sliding revenue split — fighter-first, promoter upside as event scales.
- E2E PPV with token security, device limits, and real-time dashboards.
- Escrow-backed guarantee for fighter protection.

Next steps:
1. Review attached one-page term sheet.
2. Confirm escrow deposit within 72 hours.
3. Grant read-only ticketing + pixel access.
4. We run a 7-day pilot to prove uplift.

I am available for a call this week. Let me know a time that works.

Best,
DFC (Logan)
Phone: [YOUR_PHONE]
Ticket URL: [LIVE_TICKET_URL]''',
  ];

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final wide = w > 900;

    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: Stack(
        children: [
          const DFCCosmicBackground(
            particleCount: 35,
            primaryColor: DesignTokens.neonCyan,
            secondaryColor: DesignTokens.neonMagenta,
          ),
          SafeArea(
            child: Column(
              children: [
                _header(),
                Expanded(child: wide ? _wideLayout() : _narrowLayout()),
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
              Icons.outgoing_mail,
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
                  'PROMOTER OUTREACH HQ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Copy-ready emails, DMs, call scripts & proposals',
                  style: TextStyle(color: DesignTokens.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wideLayout() {
    return Row(
      children: [
        Expanded(flex: 4, child: _inputPanel()),
        Expanded(flex: 6, child: _previewPanel()),
      ],
    );
  }

  Widget _narrowLayout() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [_inputPanel(), const SizedBox(height: 16), _previewPanel()],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INPUT PANEL
  // ═══════════════════════════════════════════════════════════════════════

  Widget _inputPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('TEMPLATE'),
          const SizedBox(height: 8),
          ...List.generate(_templateNames.length, (i) {
            final sel = i == _selectedTemplate;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => setState(() => _selectedTemplate = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                        : DesignTokens.bgCard,
                    border: Border.all(
                      color: sel
                          ? DesignTokens.neonCyan
                          : DesignTokens.neonCyan.withValues(alpha: 0.15),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _templateIcons[i],
                        color: sel ? DesignTokens.neonCyan : Colors.white38,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _templateNames[i],
                        style: TextStyle(
                          color: sel ? DesignTokens.neonCyan : Colors.white70,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 20),
          _sectionLabel('FILL PLACEHOLDERS'),
          const SizedBox(height: 8),
          _field(_promoterNameCtrl, 'Promoter Name', DesignTokens.neonCyan),
          _field(_eventNameCtrl, 'Event Name', DesignTokens.neonGold),
          _field(_eventDateCtrl, 'Event Date', DesignTokens.neonGold),
          _field(_fighterNameCtrl, 'Fighter Name', DesignTokens.neonMagenta),
          _field(_guaranteeCtrl, 'Guarantee (AUD)', DesignTokens.neonGreen),
          _field(_adBudgetCtrl, 'Ad Budget (AUD)', DesignTokens.neonAmber),
          _field(_ticketUrlCtrl, 'Ticket URL', DesignTokens.neonCyan),
          _field(_phoneCtrl, 'Phone', DesignTokens.neonCyan),
          _field(_timeRangeCtrl, 'Available Time', DesignTokens.neonCyan),
        ],
      ),
    );
  }

  static const _templateIcons = [
    Icons.account_balance_outlined,
    Icons.verified_outlined,
    Icons.live_tv_outlined,
    Icons.chat_bubble_outline,
    Icons.phone_outlined,
    Icons.schedule_send_outlined,
    Icons.business_outlined,
    Icons.slideshow_outlined,
  ];

  // ═══════════════════════════════════════════════════════════════════════
  // PREVIEW PANEL
  // ═══════════════════════════════════════════════════════════════════════

  Widget _previewPanel() {
    final filled = _fillTemplate(_templates[_selectedTemplate]);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            children: [
              Icon(
                _templateIcons[_selectedTemplate],
                color: DesignTokens.neonCyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _templateNames[_selectedTemplate].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: DesignTokens.neonGreen),
                tooltip: 'Copy to clipboard',
                onPressed: _copyTemplate,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Preview card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: GlassDecoration.card(),
            child: SelectableText(
              filled,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.7,
                fontFamily: 'monospace',
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Action checklist ──
          _checklistCard(),

          const SizedBox(height: 16),

          // ── Copy button ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('COPY TO CLIPBOARD'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.neonCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              onPressed: _copyTemplate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _checklistCard() {
    const items = [
      'Send email with term sheet + escrow instructions (72hr deadline)',
      'DM promoter the short message and request 15-min call',
      'Open escrow and provide account details; request confirmation',
      'Request read-only Meta pixel + ticketing dashboard access',
      'Confirm PPV provider and schedule T-7 E2E test',
      'Do NOT resume paid spend until escrow funded + E2E passes',
      'Run 7-day pilot (AUD 1,000) and deliver daily CSVs',
      'Produce one-page case study after pilot for next pitch',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecoration.card(accent: DesignTokens.neonAmber),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EXECUTION CHECKLIST',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_box_outline_blank,
                    color: DesignTokens.neonAmber,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
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

  Widget _field(TextEditingController ctrl, String label, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        onChanged: (_) => setState(() {}),
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
          isDense: true,
        ),
      ),
    );
  }
}
