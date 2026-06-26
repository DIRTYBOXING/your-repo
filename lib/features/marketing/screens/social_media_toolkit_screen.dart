import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_card.dart';
import '../../../shared/widgets/dfc_cosmetic_widgets.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SOCIAL MEDIA TOOLKIT — Platform Specs, Analytics, Strategy & Best Practices
// ═══════════════════════════════════════════════════════════════════════════════

class SocialMediaToolkitScreen extends StatefulWidget {
  const SocialMediaToolkitScreen({super.key});

  @override
  State<SocialMediaToolkitScreen> createState() =>
      _SocialMediaToolkitScreenState();
}

class _SocialMediaToolkitScreenState extends State<SocialMediaToolkitScreen>
    with SingleTickerProviderStateMixin {
  // DFC neon palette — dark tones for background, bright for accents
  static const _bgRose = Color(0xFF3D0040); // deep magenta background
  static const _bgBlue = Color(0xFF003844); // deep cyan background
  static const _sRose = Color(0xFFFF00FF); // neonMagenta — icons/text/accents
  static const _sBlue = Color(0xFF00F5FF); // neonCyan — icons/text/accents

  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: Stack(
        children: [
          const DFCCosmicBackground(
            particleCount: 18,
            primaryColor: _bgRose,
            secondaryColor: _bgBlue,
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildPlatformSpecs(),
                      _buildAnalytics(),
                      _buildStrategy(),
                      _buildBestPractices(),
                      _buildTools(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.perm_media_outlined, color: _sRose, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_sRose, _sBlue],
                  ).createShader(bounds),
                  child: const Text(
                    'SOCIAL MEDIA TOOLKIT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(left: 48),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Specs · Analytics · Strategy · Best Practices · Tools',
                style: TextStyle(
                  color: DesignTokens.textDisabled,
                  fontSize: DesignTokens.fontSizeMicro,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const DFCNeonDivider(color: _sRose),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTabBar() {
    final tabs = [
      (Icons.photo_size_select_actual, 'SPECS'),
      (Icons.analytics_outlined, 'ANALYTICS'),
      (Icons.rocket_launch, 'STRATEGY'),
      (Icons.star_outline, 'PRACTICES'),
      (Icons.build_outlined, 'TOOLS'),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: TabBar(
        controller: _tabCtrl,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.zero,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _sRose.withValues(alpha: 0.25),
              _sBlue.withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: _sRose.withValues(alpha: 0.4), width: 0.5),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: DesignTokens.textMuted,
        labelStyle: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        tabs: tabs
            .map(
              (t) => Tab(
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t.$1, size: 13),
                    const SizedBox(width: 4),
                    Text(t.$2),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1 — PLATFORM IMAGE SPECS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPlatformSpecs() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        // Hero card
        DFCCard.glass(
          accent: _sRose,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _sRose.withValues(alpha: 0.3),
                          _sBlue.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.aspect_ratio,
                      color: _sRose,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Platform Image Dimensions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Exact pixel sizes for every major platform',
                          style: TextStyle(
                            color: DesignTokens.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Use the correct dimensions for maximum quality and algorithm reach. Wrong sizes = cropping, blur, and lower distribution.',
                style: TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeCaption,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // INSTAGRAM
        _platformSection(
          platform: 'INSTAGRAM',
          icon: Icons.camera_alt,
          accent: _sRose,
          specs: [
            const _SpecItem('Profile Photo', '320 × 320 px'),
            const _SpecItem('Square Post', '1080 × 1080 px'),
            const _SpecItem('Portrait Post', '1080 × 1350 px'),
            const _SpecItem('Landscape Post', '1080 × 566 px'),
            const _SpecItem('Stories / Reels', '1080 × 1920 px'),
            const _SpecItem('Carousel', '1080 × 1080 px (each)'),
            const _SpecItem('IGTV Cover', '420 × 654 px'),
            const _SpecItem('Ad (Single Image)', '1080 × 1080 px'),
            const _SpecItem('Ad (Story)', '1080 × 1920 px'),
          ],
        ),
        const SizedBox(height: 16),

        // FACEBOOK
        _platformSection(
          platform: 'FACEBOOK',
          icon: Icons.facebook,
          accent: DesignTokens.neonBlue,
          specs: [
            const _SpecItem('Profile Photo', '170 × 170 px'),
            const _SpecItem('Cover Photo', '820 × 312 px'),
            const _SpecItem('Shared Image', '1200 × 630 px'),
            const _SpecItem('Event Cover', '1920 × 1005 px'),
            const _SpecItem('Stories', '1080 × 1920 px'),
            const _SpecItem('Video Post', '1280 × 720 px min'),
            const _SpecItem('Carousel Ad', '1080 × 1080 px'),
            const _SpecItem('Link Preview', '1200 × 628 px'),
            const _SpecItem('Group Cover', '1640 × 856 px'),
          ],
        ),
        const SizedBox(height: 16),

        // TWITTER / X
        _platformSection(
          platform: 'TWITTER / X',
          icon: Icons.tag,
          accent: DesignTokens.neonCyan,
          specs: [
            const _SpecItem('Profile Photo', '400 × 400 px'),
            const _SpecItem('Header Photo', '1500 × 500 px'),
            const _SpecItem('In-Stream Image', '1600 × 900 px'),
            const _SpecItem('Card Image', '800 × 418 px'),
            const _SpecItem('Video Thumbnail', '1280 × 720 px'),
            const _SpecItem('Ad (Single Image)', '1200 × 675 px'),
            const _SpecItem('Fleet / Stories', '1080 × 1920 px'),
          ],
        ),
        const SizedBox(height: 16),

        // LINKEDIN
        _platformSection(
          platform: 'LINKEDIN',
          icon: Icons.business_center,
          accent: DesignTokens.neonGold,
          specs: [
            const _SpecItem('Profile Photo', '400 × 400 px'),
            const _SpecItem('Cover / Banner', '1584 × 396 px'),
            const _SpecItem('Shared Image', '1200 × 627 px'),
            const _SpecItem('Company Logo', '300 × 300 px'),
            const _SpecItem('Company Cover', '1128 × 191 px'),
            const _SpecItem('Blog Post Image', '1200 × 644 px'),
            const _SpecItem('Video Post', '256 × 144 to 4096 × 2304 px'),
            const _SpecItem('Ad (Sponsored)', '1200 × 627 px'),
          ],
        ),
        const SizedBox(height: 16),

        // TIKTOK
        _platformSection(
          platform: 'TIKTOK',
          icon: Icons.music_note,
          accent: DesignTokens.neonGreen,
          specs: [
            const _SpecItem('Profile Photo', '200 × 200 px'),
            const _SpecItem('Video (Full Screen)', '1080 × 1920 px'),
            const _SpecItem('Video (Feed)', '1080 × 1920 px'),
            const _SpecItem('Ad (In-Feed)', '540 × 960 px min'),
            const _SpecItem('Ad (TopView)', '1080 × 1920 px'),
            const _SpecItem('Thumbnail', '1080 × 1920 px'),
            const _SpecItem('Aspect Ratio', '9:16 (recommended)'),
            const _SpecItem('Max File Size', '287.6 MB (mobile)'),
          ],
        ),
        const SizedBox(height: 16),

        // PINTEREST
        _platformSection(
          platform: 'PINTEREST',
          icon: Icons.push_pin,
          accent: DesignTokens.neonRed,
          specs: [
            const _SpecItem('Profile Photo', '165 × 165 px'),
            const _SpecItem('Standard Pin', '1000 × 1500 px'),
            const _SpecItem('Long Pin', '1000 × 2100 px'),
            const _SpecItem('Square Pin', '1000 × 1000 px'),
            const _SpecItem('Idea Pin Cover', '1080 × 1920 px'),
            const _SpecItem('Board Cover', '222 × 150 px'),
            const _SpecItem('Carousel Pin', '1000 × 1500 px (each)'),
            const _SpecItem('Video Pin', '1000 × 1500 px'),
          ],
        ),
        const SizedBox(height: 16),

        // YOUTUBE
        _platformSection(
          platform: 'YOUTUBE',
          icon: Icons.play_circle_outline,
          accent: DesignTokens.neonAmber,
          specs: [
            const _SpecItem('Channel Profile', '800 × 800 px'),
            const _SpecItem('Channel Banner', '2560 × 1440 px'),
            const _SpecItem('Video Thumbnail', '1280 × 720 px'),
            const _SpecItem('Shorts', '1080 × 1920 px'),
            const _SpecItem('Video Upload', '1920 × 1080 px (1080p)'),
            const _SpecItem('4K Upload', '3840 × 2160 px'),
            const _SpecItem('End Screen', '1280 × 720 px'),
            const _SpecItem('Watermark', '150 × 150 px'),
            const _SpecItem('Display Ad', '300 × 250 px'),
          ],
        ),
        const SizedBox(height: 24),

        // QUICK TIP CARD
        DFCCard.glass(
          accent: DesignTokens.neonGold,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: DesignTokens.neonGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tips_and_updates,
                  color: DesignTokens.neonGold,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pro Tip',
                      style: TextStyle(
                        color: DesignTokens.neonGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Always export at 2× resolution for retina/high-DPI screens. Use PNG for graphics, JPEG for photos, and MP4 (H.264) for video.',
                      style: TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _platformSection({
    required String platform,
    required IconData icon,
    required Color accent,
    required List<_SpecItem> specs,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DFCSectionHeader(title: platform, icon: icon),
        const SizedBox(height: 4),
        DFCCard.glass(
          accent: accent,
          child: Column(
            children: specs.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.label,
                            style: const TextStyle(
                              color: DesignTokens.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: s.value));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied: ${s.value}'),
                                backgroundColor: accent.withValues(alpha: 0.8),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.25),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  s.value,
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.copy, size: 10, color: accent),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < specs.length - 1)
                    Divider(
                      height: 1,
                      thickness: 0.3,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2 — ANALYTICS & METRICS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAnalytics() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        // Hero
        DFCCard.glass(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DesignTokens.neonCyan.withValues(alpha: 0.3),
                          DesignTokens.neonBlue.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.insights,
                      color: DesignTokens.neonCyan,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '10 Metrics That Actually Matter',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Stop chasing vanity stats — track what drives results',
                          style: TextStyle(
                            color: DesignTokens.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Core Metrics ──
        const DFCSectionHeader(title: 'CORE METRICS', icon: Icons.bar_chart),
        const SizedBox(height: 6),

        _metricCard(
          number: '01',
          title: 'Impressions & Reach',
          description:
              'Reach = unique viewers. Impressions = total screen appearances. Top-of-funnel visibility — pair with engagement for real insight.',
          accent: DesignTokens.neonCyan,
          icon: Icons.visibility,
          tip:
              'A post with 10K impressions but 0.1% engagement means wide reach but weak content. Fix the hook.',
        ),
        const SizedBox(height: 10),

        _metricCard(
          number: '02',
          title: 'Engagement Rate',
          description:
              'Interactions ÷ total viewers. A 10% rate on a small account outperforms a 0.5% rate on a massive one. Shares are the #1 signal for algorithmic boost.',
          accent: DesignTokens.neonMagenta,
          icon: Icons.favorite,
          tip:
              'Instagram\'s Adam Mosseri confirmed: share rate is the most important metric for reaching more people.',
        ),
        const SizedBox(height: 10),

        _metricCard(
          number: '03',
          title: 'Video Views & Watch Time',
          description:
              'Views = who pressed play. Watch time = who stayed. Platforms prioritize content that holds attention. Every second earns you the next one.',
          accent: DesignTokens.neonGreen,
          icon: Icons.play_circle,
          tip:
              'If viewers drop off in the first 3 seconds, your hook is weak. Lead with impact, cut the filler.',
        ),
        const SizedBox(height: 10),

        _metricCard(
          number: '04',
          title: 'Conversion Rate',
          description:
              'People who took action (signup, purchase, booking) ÷ viewers. 2–5% is solid. If traffic is high but conversions low, audit your landing page.',
          accent: DesignTokens.neonGold,
          icon: Icons.trending_up,
          tip:
              'Use UTM tags on every link. Without tracking, you\'re guessing which posts actually drive revenue.',
        ),
        const SizedBox(height: 10),

        _metricCard(
          number: '05',
          title: 'Evergreen Performance',
          description:
              'Your best content doesn\'t expire. Track reposts of high-performers — if they still get clicks, comments, or shares the 2nd/3rd time, they\'re evergreen gold.',
          accent: DesignTokens.neonBlue,
          icon: Icons.loop,
          tip:
              'Study your evergreen winners. Steal the format, tone, and structure — then make more like them.',
        ),
        const SizedBox(height: 10),

        _metricCard(
          number: '06',
          title: 'Brand Mentions',
          description:
              'How often people talk about you — tagged or not. Monitor @mentions, branded hashtags, and untagged name-drops. Spikes = viral moment OR crisis.',
          accent: DesignTokens.neonRed,
          icon: Icons.alternate_email,
          tip:
              'Set up alerts for your brand name. You want more people talking about you — for the right reasons.',
        ),
        const SizedBox(height: 16),

        // ── Performance Metrics ──
        const DFCSectionHeader(title: 'PERFORMANCE METRICS', icon: Icons.speed),
        const SizedBox(height: 6),

        _metricCard(
          number: '07',
          title: 'Top-Performing Posts',
          description:
              'Review your top posts monthly. Patterns emerge: winning formats, preferred tone, optimal timing. Build on what works — repurpose winners across platforms.',
          accent: DesignTokens.neonAmber,
          icon: Icons.emoji_events,
          tip:
              'Turn a strong LinkedIn post into a short-form video. Expand a viral tweet into a blog. Never waste a winner.',
        ),
        const SizedBox(height: 10),

        _metricCard(
          number: '08',
          title: 'Optimal Posting Times',
          description:
              'Algorithms favor early engagement. The more people interact right after posting, the further it spreads. Analyze YOUR audience\'s active hours — not generic guides.',
          accent: DesignTokens.neonCyan,
          icon: Icons.schedule,
          tip:
              'If your audience spans time zones, schedule different drops for different regions. Golden hour in NYC is 3 AM in Sydney.',
        ),
        const SizedBox(height: 10),

        _metricCard(
          number: '09',
          title: 'Content Themes',
          description:
              'Tag posts by theme (educational, promotional, inspirational, meme-based). Compare engagement over time. Know what crushes it AND what\'s a snooze.',
          accent: DesignTokens.neonGreen,
          icon: Icons.category,
          tip:
              'Knowing what doesn\'t land is just as useful as knowing what does. Drop the dead weight, double down on winners.',
        ),
        const SizedBox(height: 10),

        _metricCard(
          number: '10',
          title: 'Format Performance',
          description:
              'Videos vs images vs carousels vs text. Which formats double your engagement? Which waste space? Cut underperformers. Experiment with new formats.',
          accent: DesignTokens.neonMagenta,
          icon: Icons.view_carousel,
          tip:
              'Formats evolve fast. Reels, Shorts, Threads, Lives — don\'t chase every trend, but test what fits your audience.',
        ),
        const SizedBox(height: 20),

        // ── Emerging Analytics ──
        const DFCSectionHeader(title: 'EMERGING ANALYTICS', icon: Icons.auto_awesome),
        const SizedBox(height: 6),

        _emergingCard(
          title: 'Social Sentiment',
          description:
              'Break down emotional tone behind comments, tags, and replies — positive, neutral, or negative. Know if people are hyped, frustrated, or confused.',
          icon: Icons.sentiment_satisfied_alt,
          accent: DesignTokens.neonGreen,
        ),
        const SizedBox(height: 8),
        _emergingCard(
          title: 'Response Rate & Speed',
          description:
              'How fast you reply to DMs, comments, and mentions. People expect replies within 24 hours. Ignore them and frustration shows up everywhere.',
          icon: Icons.reply_all,
          accent: DesignTokens.neonCyan,
        ),
        const SizedBox(height: 8),
        _emergingCard(
          title: 'Predictive Content Analysis',
          description:
              'AI tools scan content — images, tone, hashtags, timing — and predict if it\'ll hit or flop before posting. A smarter gut check, backed by data.',
          icon: Icons.psychology,
          accent: DesignTokens.neonMagenta,
        ),
        const SizedBox(height: 8),
        _emergingCard(
          title: 'Internal Efficiency',
          description:
              'Time-to-publish, post volume per channel, content reuse rate. Are things flowing or are you burning energy in the wrong places?',
          icon: Icons.timer,
          accent: DesignTokens.neonAmber,
        ),
      ],
    );
  }

  Widget _metricCard({
    required String number,
    required String title,
    required String description,
    required Color accent,
    required IconData icon,
    String? tip,
  }) {
    return DFCCard.glass(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
          if (tip != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: accent.withValues(alpha: 0.15),
                  width: 0.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, color: accent, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        color: accent.withValues(alpha: 0.9),
                        fontSize: 10.5,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emergingCard({
    required String title,
    required String description,
    required IconData icon,
    required Color accent,
  }) {
    return DFCCard.glass(
      accent: accent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.25),
                  accent.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3 — STRATEGY (Growth, TikTok, Platform-Specific)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStrategy() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        // Hero
        DFCCard.glass(
          accent: DesignTokens.neonGreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DesignTokens.neonGreen.withValues(alpha: 0.3),
                          DesignTokens.neonCyan.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.rocket_launch,
                      color: DesignTokens.neonGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Growth Strategies',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Platform-specific tactics to build your audience',
                          style: TextStyle(
                            color: DesignTokens.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── TikTok Growth ──
        const DFCSectionHeader(title: 'TIKTOK GROWTH', icon: Icons.music_note),
        const SizedBox(height: 6),

        _strategyCard(
          title: 'Hook in 0.5 Seconds',
          items: [
            'Open with movement, text, or a bold statement',
            'Pattern interrupts stop the scroll',
            'Front-load value — don\'t build to it',
            'If you lose them in 3 seconds, the algorithm buries you',
          ],
          accent: DesignTokens.neonGreen,
          icon: Icons.bolt,
        ),
        const SizedBox(height: 10),
        _strategyCard(
          title: 'Algorithm Signals',
          items: [
            'Watch time is king — hold attention to the end',
            'Saves and shares outweigh likes',
            'Comments with replies boost distribution',
            'Loose loops + "Wait for it" = rewatches',
            'Post 1-3x daily during audience peak hours',
          ],
          accent: DesignTokens.neonCyan,
          icon: Icons.auto_graph,
        ),
        const SizedBox(height: 10),
        _strategyCard(
          title: 'Hashtags & Discovery',
          items: [
            'Mix trending + niche hashtags (3-5 max)',
            'Use trending sounds — even at low volume',
            'Niche hashtags (#MuayThaiTraining) > generic (#Fitness)',
            'Duet and Stitch high-performing content in your niche',
          ],
          accent: DesignTokens.neonMagenta,
          icon: Icons.tag,
        ),
        const SizedBox(height: 20),

        // ── Instagram Growth ──
        const DFCSectionHeader(title: 'INSTAGRAM GROWTH', icon: Icons.camera_alt),
        const SizedBox(height: 6),

        _strategyCard(
          title: 'Reels Strategy',
          items: [
            '90-second Reels get priority distribution',
            'Use text overlays — 85% watch without sound',
            'Trending audio + original content = reach multiplier',
            'Post Reels 4-7x per week for maximum growth',
            'End with a CTA: "Follow for more" or "Save this"',
          ],
          accent: DesignTokens.neonMagenta,
          icon: Icons.video_library,
        ),
        const SizedBox(height: 10),
        _strategyCard(
          title: 'Engagement Tactics',
          items: [
            'Reply to every comment in the first hour',
            'Use Stories polls/questions for 2-way engagement',
            'Carousels get 3× more engagement than single images',
            'Collaborate with creators via Collab Posts feature',
            'Share rate > like rate for algorithmic reach',
          ],
          accent: DesignTokens.neonGold,
          icon: Icons.chat_bubble_outline,
        ),
        const SizedBox(height: 20),

        // ── YouTube Growth ──
        const DFCSectionHeader(
          title: 'YOUTUBE GROWTH',
          icon: Icons.play_circle_outline,
        ),
        const SizedBox(height: 6),

        _strategyCard(
          title: 'Shorts Strategy',
          items: [
            '< 60 seconds, vertical (1080×1920)',
            'Hook viewers in 1 second — title card or bold text',
            'Loop-friendly endings boost rewatch rate',
            'Post 3-5 Shorts/week + 1 long-form video',
            'Shorts drive subscribers; long-form drives watch hours',
          ],
          accent: DesignTokens.neonAmber,
          icon: Icons.short_text,
        ),
        const SizedBox(height: 10),
        _strategyCard(
          title: 'YouTube SEO',
          items: [
            'Keywords in title, description (first 2 lines), and tags',
            'Custom thumbnails with faces + contrasting colors',
            'Timestamps/chapters increase click-through from search',
            '8-15 min optimal for ad revenue + retention',
            'End screens + cards drive internal traffic loops',
          ],
          accent: DesignTokens.neonBlue,
          icon: Icons.search,
        ),
        const SizedBox(height: 20),

        // ── LinkedIn Growth ──
        const DFCSectionHeader(title: 'LINKEDIN GROWTH', icon: Icons.business_center),
        const SizedBox(height: 6),

        _strategyCard(
          title: 'Content That Works',
          items: [
            'Personal stories outperform polished corporate content',
            'Text-only posts often beat image posts (algorithm boost)',
            'Document carousels (PDF uploads) get 3× impressions',
            'Comment within first 30 mins to boost distribution',
            'Newsletter feature gives direct inbox access',
          ],
          accent: DesignTokens.neonGold,
          icon: Icons.article,
        ),
        const SizedBox(height: 20),

        // ── Cross-Platform ──
        const DFCSectionHeader(title: 'CROSS-PLATFORM', icon: Icons.devices),
        const SizedBox(height: 6),

        _strategyCard(
          title: 'Multi-Platform Growth Formula',
          items: [
            'Create once → repurpose everywhere (adjust for format)',
            'TikTok → Reels → Shorts pipeline (remove watermarks)',
            'Platform-native always outperforms cross-posted links',
            'Build email list from social — own your audience',
            'Consistent posting schedule > sporadic viral attempts',
            'Engage in niche communities before promoting',
          ],
          accent: DesignTokens.neonCyan,
          icon: Icons.hub,
        ),
      ],
    );
  }

  Widget _strategyCard({
    required String title,
    required List<String> items,
    required Color accent,
    required IconData icon,
  }) {
    return DFCCard.glass(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 11.5,
                        height: 1.4,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 4 — BEST PRACTICES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBestPractices() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        // Hero
        DFCCard.glass(
          accent: DesignTokens.neonGold,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DesignTokens.neonGold.withValues(alpha: 0.3),
                          DesignTokens.neonAmber.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      color: DesignTokens.neonGold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Best Practices',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Design, branding, monitoring & posting guidelines',
                          style: TextStyle(
                            color: DesignTokens.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Design Best Practices ──
        const DFCSectionHeader(
          title: 'DESIGN FUNDAMENTALS',
          icon: Icons.design_services,
        ),
        const SizedBox(height: 6),

        _practiceCard(
          title: 'High Resolution Always',
          description:
              'Never upload compressed or low-res images. Social platforms already compress on upload — start with the highest quality possible.',
          icon: Icons.hd,
          accent: DesignTokens.neonCyan,
        ),
        const SizedBox(height: 8),
        _practiceCard(
          title: 'Mobile-First Design',
          description:
              '75-85% of social media usage is mobile. Design for small screens first. Test readability on a phone before posting.',
          icon: Icons.phone_iphone,
          accent: DesignTokens.neonMagenta,
        ),
        const SizedBox(height: 8),
        _practiceCard(
          title: 'Consistent Brand Identity',
          description:
              'Lock in your color palette, fonts, logo placement, and tone. Every post should be instantly recognizable as yours.',
          icon: Icons.palette,
          accent: DesignTokens.neonGold,
        ),
        const SizedBox(height: 8),
        _practiceCard(
          title: 'Readable Typography',
          description:
              'Minimum 24pt for key text on social images. High contrast (light text on dark, dark text on light). Max 2 fonts per design.',
          icon: Icons.text_fields,
          accent: DesignTokens.neonGreen,
        ),
        const SizedBox(height: 8),
        _practiceCard(
          title: 'Strong CTAs',
          description:
              'Every post needs a clear call-to-action. "Follow for more", "Save this", "Link in bio", "Drop a comment". Tell people what to do.',
          icon: Icons.touch_app,
          accent: DesignTokens.neonAmber,
        ),
        const SizedBox(height: 8),
        _practiceCard(
          title: 'Accessibility Matters',
          description:
              'Add alt text to images. Use captions on all videos. Ensure color contrast passes WCAG standards. Don\'t rely on color alone to convey meaning.',
          icon: Icons.accessibility_new,
          accent: DesignTokens.neonBlue,
        ),
        const SizedBox(height: 20),

        // ── Brand Monitoring ──
        const DFCSectionHeader(
          title: 'BRAND MONITORING',
          icon: Icons.shield_outlined,
        ),
        const SizedBox(height: 6),

        _practiceCard(
          title: 'Reputation Management',
          description:
              'Monitor what people say about your brand 24/7. Set alerts for brand name, common misspellings, and competitor mentions. React fast to crises.',
          icon: Icons.security,
          accent: DesignTokens.neonRed,
        ),
        const SizedBox(height: 8),
        _practiceCard(
          title: 'Customer Engagement',
          description:
              'Reply to comments, DMs, and mentions within hours, not days. Positive interactions build brand loyalty. Ignored complaints go viral.',
          icon: Icons.people_outline,
          accent: DesignTokens.neonCyan,
        ),
        const SizedBox(height: 8),
        _practiceCard(
          title: 'Competitor Analysis',
          description:
              'Track competitor content, engagement rates, and audience growth. Identify what works in your space. Don\'t copy — outperform.',
          icon: Icons.compare_arrows,
          accent: DesignTokens.neonMagenta,
        ),
        const SizedBox(height: 8),
        _practiceCard(
          title: 'Cybersecurity Awareness',
          description:
              'Watch for fake accounts impersonating your brand. Report them immediately. Use 2FA on all social accounts. Limit admin access.',
          icon: Icons.gpp_good,
          accent: DesignTokens.neonGold,
        ),
        const SizedBox(height: 20),

        // ── Posting Best Practices ──
        const DFCSectionHeader(title: 'POSTING GUIDELINES', icon: Icons.schedule),
        const SizedBox(height: 6),

        _bestTimesGrid(),
        const SizedBox(height: 16),

        // ── Social SEO ──
        const DFCSectionHeader(title: 'SOCIAL SEO', icon: Icons.travel_explore),
        const SizedBox(height: 6),

        _practiceCard(
          title: 'Keyword-Rich Captions',
          description:
              'Social platforms are search engines now. Use keywords naturally in captions, bios, and alt text — not just hashtags.',
          icon: Icons.manage_search,
          accent: DesignTokens.neonCyan,
        ),
        const SizedBox(height: 8),
        _practiceCard(
          title: 'Hashtag Strategy',
          description:
              'Niche > generic. 3-5 targeted hashtags beat 30 random ones. Research trending hashtags in your vertical weekly.',
          icon: Icons.tag,
          accent: DesignTokens.neonGreen,
        ),
        const SizedBox(height: 8),
        _practiceCard(
          title: 'Profile Optimization',
          description:
              'Keywords in display name, bio, and username. Clear CTA in bio link. Consistent handle across all platforms.',
          icon: Icons.person_search,
          accent: DesignTokens.neonMagenta,
        ),
      ],
    );
  }

  Widget _practiceCard({
    required String title,
    required String description,
    required IconData icon,
    required Color accent,
  }) {
    return DFCCard.glass(
      accent: accent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: accent.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Icon(icon, color: accent, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bestTimesGrid() {
    final times = [
      const _BestTime(
        'Instagram',
        'Tue-Thu 11am-1pm',
        Icons.camera_alt,
        DesignTokens.neonMagenta,
      ),
      const _BestTime(
        'Facebook',
        'Tue-Thu 9am-12pm',
        Icons.facebook,
        DesignTokens.neonBlue,
      ),
      const _BestTime(
        'Twitter/X',
        'Mon-Wed 9-11am',
        Icons.tag,
        DesignTokens.neonCyan,
      ),
      const _BestTime(
        'TikTok',
        'Tue-Thu 2-5pm',
        Icons.music_note,
        DesignTokens.neonGreen,
      ),
      const _BestTime(
        'LinkedIn',
        'Tue-Thu 10am-12pm',
        Icons.business_center,
        DesignTokens.neonGold,
      ),
      const _BestTime(
        'YouTube',
        'Thu-Fri 12-3pm',
        Icons.play_circle_outline,
        DesignTokens.neonAmber,
      ),
      const _BestTime(
        'Pinterest',
        'Fri-Sun 8-11pm',
        Icons.push_pin,
        DesignTokens.neonRed,
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: times.map((t) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 48) / 2,
          child: DFCCard.glass(
            accent: t.color,
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: t.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(t.icon, color: t.color, size: 15),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.platform,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        t.time,
                        style: TextStyle(
                          color: t.color,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 5 — TOOLS & SOFTWARE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTools() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        // Hero
        DFCCard.glass(
          accent: DesignTokens.neonBlue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DesignTokens.neonBlue.withValues(alpha: 0.3),
                          DesignTokens.neonCyan.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.construction,
                      color: DesignTokens.neonBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tools & Software',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Essential features & tools for your analytics stack',
                          style: TextStyle(
                            color: DesignTokens.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Must-Have Features ──
        const DFCSectionHeader(title: 'MUST-HAVE FEATURES', icon: Icons.checklist),
        const SizedBox(height: 6),

        _featureCard(
          number: '1',
          title: 'Automated Reporting',
          items: [
            'Pre-built templates (monthly, campaign, platform)',
            'One-click exports to PDF or email',
            'Auto-summarized takeaways with key insights',
            'If you\'re copying from dashboards into spreadsheets, you don\'t have the right tool',
          ],
          accent: DesignTokens.neonCyan,
          icon: Icons.auto_fix_high,
        ),
        const SizedBox(height: 10),
        _featureCard(
          number: '2',
          title: 'Actionable Metrics',
          items: [
            'KPIs linked to actual ROI and conversions',
            'Customizable metrics view per campaign/platform',
            'Alerts when meaningful changes happen',
            'More metrics shouldn\'t mean more confusion',
          ],
          accent: DesignTokens.neonGreen,
          icon: Icons.query_stats,
        ),
        const SizedBox(height: 10),
        _featureCard(
          number: '3',
          title: 'Unified Dashboard',
          items: [
            'All channels in one clean interface',
            'Compare performance across platforms instantly',
            'Normalize inconsistent metrics (views vs reach)',
            'Supports emerging platforms (Threads, Shorts)',
          ],
          accent: DesignTokens.neonMagenta,
          icon: Icons.dashboard,
        ),
        const SizedBox(height: 10),
        _featureCard(
          number: '4',
          title: 'Customizable Reports',
          items: [
            'Filters by campaign, audience, or channel',
            'Branded exports (logos, custom colors)',
            'Shareable links + scheduled email delivery',
            'Client-by-client views for agencies',
          ],
          accent: DesignTokens.neonGold,
          icon: Icons.tune,
        ),
        const SizedBox(height: 10),
        _featureCard(
          number: '5',
          title: 'AI Insights & Alerts',
          items: [
            'Natural-language summaries of trends',
            'Predictive insights (best time, best topic)',
            'Spike/drop alerts for engagement & sentiment',
            'Pattern recognition humans would miss',
          ],
          accent: DesignTokens.neonBlue,
          icon: Icons.psychology,
        ),
        const SizedBox(height: 20),

        // ── Tool Categories ──
        const DFCSectionHeader(title: 'TOOL CATEGORIES', icon: Icons.category),
        const SizedBox(height: 6),

        _toolCategoryGrid(),
        const SizedBox(height: 20),

        // ── Platform Analytics ──
        const DFCSectionHeader(title: 'NATIVE ANALYTICS', icon: Icons.analytics),
        const SizedBox(height: 6),

        _nativeAnalyticsRow(),
        const SizedBox(height: 16),

        // ── Pro Tip ──
        DFCCard.glass(
          accent: DesignTokens.neonGold,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: DesignTokens.neonGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tips_and_updates,
                  color: DesignTokens.neonGold,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reporting Rule',
                      style: TextStyle(
                        color: DesignTokens.neonGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Check in weekly. Deliver formal reports monthly. Weekly reviews spot trends early. Monthly reports give leadership a clear performance view.',
                      style: TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Declining metrics card
        DFCCard.glass(
          accent: DesignTokens.neonRed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.trending_down,
                    color: DesignTokens.neonRed,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'If Metrics Are Declining…',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...[
                'Identify what actually dropped: reach? engagement? conversions?',
                'Audit content — what\'s still resonating vs. what\'s flat',
                'Look at successful competitors for format inspiration',
                'Test new formats, adjust posting times, tweak CTAs',
                'Small tweaks often reset momentum',
              ].map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: const BoxDecoration(
                          color: DesignTokens.neonRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: DesignTokens.textSecondary,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _featureCard({
    required String number,
    required String title,
    required List<String> items,
    required Color accent,
    required IconData icon,
  }) {
    return DFCCard.glass(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: TextStyle(
                      color: accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: accent, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: accent, size: 12),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 11,
                        height: 1.35,
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

  Widget _toolCategoryGrid() {
    final categories = [
      ('Scheduling', Icons.calendar_month, DesignTokens.neonCyan),
      ('Analytics', Icons.bar_chart, DesignTokens.neonGreen),
      ('Listening', Icons.hearing, DesignTokens.neonMagenta),
      ('Messaging', Icons.message, DesignTokens.neonBlue),
      ('Design', Icons.brush, DesignTokens.neonGold),
      ('Hashtag Research', Icons.tag, DesignTokens.neonAmber),
      ('Calendar', Icons.date_range, DesignTokens.neonCyan),
      ('AI Content', Icons.auto_awesome, DesignTokens.neonRed),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((c) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 48) / 2,
          child: DFCCard.glass(
            accent: c.$3,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: c.$3.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(c.$2, color: c.$3, size: 15),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.$1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _nativeAnalyticsRow() {
    final platforms = [
      ('Instagram Insights', Icons.camera_alt, DesignTokens.neonMagenta),
      ('Facebook Insights', Icons.facebook, DesignTokens.neonBlue),
      ('TikTok Analytics', Icons.music_note, DesignTokens.neonGreen),
      ('LinkedIn Analytics', Icons.business_center, DesignTokens.neonGold),
      ('Twitter Analytics', Icons.tag, DesignTokens.neonCyan),
      ('YouTube Studio', Icons.play_circle_outline, DesignTokens.neonAmber),
      ('Pinterest Analytics', Icons.push_pin, DesignTokens.neonRed),
    ];

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: platforms.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final p = platforms[i];
          return Container(
            width: 100,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: p.$3.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: p.$3.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(p.$2, color: p.$3, size: 22),
                const SizedBox(height: 4),
                Text(
                  p.$1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class _SpecItem {
  final String label;
  final String value;
  const _SpecItem(this.label, this.value);
}

class _BestTime {
  final String platform;
  final String time;
  final IconData icon;
  final Color color;
  const _BestTime(this.platform, this.time, this.icon, this.color);
}
