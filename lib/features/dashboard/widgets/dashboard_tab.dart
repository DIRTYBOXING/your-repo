import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_logos.dart';
import '../../../shared/widgets/dfc_glass_panel.dart';
import '../../../core/utils/corner_voice.dart';
import '../../../core/utils/chart_painters.dart';
import 'package:video_player/video_player.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});
  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final _adCtrl = PageController(viewportFraction: 0.88);
  int _adPage = 0;
  Timer? _timer;

  static const _stocks = [
    (
      'EDR',
      'UFC',
      '\u{1F3DF}\u{FE0F}',
      28.45,
      2.3,
      <double>[24.0, 25, 23, 26, 27, 25, 28, 27, 29, 28.45],
    ),
    (
      'ONEW',
      'ONE',
      '\u{1F94A}',
      12.80,
      -1.2,
      <double>[14.0, 13.5, 13, 12.8, 13.2, 12.5, 12.9, 13, 12.6, 12.8],
    ),
    (
      'ELST',
      'Everlast',
      '\u{1F94B}',
      8.92,
      0.8,
      <double>[8.2, 8.4, 8.3, 8.5, 8.6, 8.7, 8.5, 8.8, 8.9, 8.92],
    ),
    (
      'BKFC',
      'BareKnuckle',
      '\u{1F44A}',
      3.45,
      5.7,
      <double>[2.8, 2.9, 3.0, 3.1, 3.0, 3.2, 3.3, 3.1, 3.4, 3.45],
    ),
    (
      'MNST',
      'Monster',
      '\u{26A1}',
      54.20,
      1.1,
      <double>[52.0, 53, 52.5, 53.5, 54, 53, 54.5, 53.8, 54, 54.2],
    ),
    (
      'RBUL',
      'RedBull',
      '\u{1F402}',
      89.10,
      -0.4,
      <double>[90.0, 89.5, 90, 89, 89.5, 88.5, 89, 89.5, 89, 89.1],
    ),
  ];

  static const _ads = [
    (
      'ULTIMATE HONOUR',
      'John Scida: Elite Mentorship',
      '50 years of legacy. The safest hands in the game.',
      Icons.workspace_premium,
      AppColors.neonAmber,
      'Support Legacy',
    ),
    (
      'DFC PARTNER',
      'Supporting Local Gyms',
      'We build the tools. You build the champions.',
      Icons.handshake,
      AppColors.neonBlue,
      'Partner With Us',
    ),
    (
      'UFC',
      'UFC Fight Pass',
      'Stream every fight.',
      Icons.live_tv,
      Color(0xFFE53935),
      'Subscribe',
    ),
    (
      'ONE',
      'ONE Championship',
      'Home of martial arts.',
      Icons.sports_martial_arts,
      Color(0xFFFF9800),
      'Watch',
    ),
    (
      'BKFC',
      'Bare Knuckle FC',
      'Raw. Real. Unfiltered.',
      Icons.sports_mma,
      Color(0xFF9C27B0),
      'Tickets',
    ),
    (
      'Everlast',
      'Train Like a Champ',
      'Premium fighter gear.',
      Icons.sports,
      Color(0xFF00BCD4),
      'Shop',
    ),
    (
      'Monster',
      'Unleash The Beast',
      'Fuel your fight.',
      Icons.bolt,
      Color(0xFF76FF03),
      'More',
    ),
    (
      'MMA Mag',
      'MMA Magazine',
      'Stories that hit.',
      Icons.menu_book,
      Color(0xFFFF5722),
      'Read',
    ),
    (
      'Int. Kickboxer',
      'Kickboxer Mag',
      'World-class coverage.',
      Icons.auto_stories,
      Color(0xFFFFCA28),
      'Subscribe',
    ),
    (
      'Red Bull',
      'Red Bull Wings',
      'Fuel your training.',
      Icons.rocket,
      Color(0xFF2196F3),
      'Explore',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _adPage = (_adPage + 1) % _ads.length;
      _adCtrl.animateToPage(
        _adPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _adCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Command Center',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CornerVoice.quote(DateTime.now().day),
            style: const TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _micro('Readiness', '82', '/100', Icons.bolt, AppColors.neonBlue),
              const SizedBox(width: 8),
              _micro(
                'Resting HR',
                '62',
                'bpm',
                Icons.favorite,
                AppColors.neonRed,
              ),
              const SizedBox(width: 8),
              _micro(
                'Hydration',
                '2.1',
                'L',
                Icons.water_drop,
                AppColors.neonSky,
              ),
              const SizedBox(width: 8),
              _micro(
                'Sleep',
                '7.2',
                'hrs',
                Icons.bedtime,
                AppColors.neonPurple,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const PromoVideoCard(),
          const SizedBox(height: 14),
          DfcGlassPanel(
            glowColor: AppColors.neonBlue,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Daily Performance',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    _chip('HR', true),
                    const SizedBox(width: 4),
                    _chip('HRV', false),
                    const SizedBox(width: 4),
                    _chip('Stress', false),
                    const SizedBox(width: 4),
                    _chip('Steps', false),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: const Size(double.infinity, 140),
                        painter: GraphPainter([
                          40,
                          55,
                          48,
                          72,
                          65,
                          80,
                          74,
                          68,
                          82,
                          78,
                          85,
                          90,
                        ], AppColors.neonBlue),
                      ),
                      const Positioned(
                        right: 8,
                        top: 8,
                        child: Tooltip(
                          message:
                              'Health graphs work like stocks: green = good, red = bad. Learning to read these helps you understand both your body and your money! 📈',
                          child: Icon(
                            Icons.info_outline,
                            color: AppColors.neonBlue,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(
                Icons.show_chart,
                size: 16,
                color: AppColors.neonAmber,
              ),
              SizedBox(width: 6),
              Text(
                'Fight Stocks',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Spacer(),
              Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neonGreen,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _stocks.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final s = _stocks[i];
                final up = s.$5 >= 0;
                return DfcGlassPanel(
                  glowColor: up ? AppColors.neonGreen : AppColors.neonRed,
                  padding: const EdgeInsets.all(10),
                  child: SizedBox(
                    width: 140,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(s.$3, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                s.$1,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (up
                                            ? AppColors.neonGreen
                                            : AppColors.neonRed)
                                        .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${up ? '+' : ''}${s.$5.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: up
                                      ? AppColors.neonGreen
                                      : AppColors.neonRed,
                                ),
                              ),
                            ),
                            Tooltip(
                              message:
                                  'Fight Stocks: Green = up, Red = down. Just like your health, your wealth can go up or down—learn to spot the trends!',
                              child: Icon(
                                Icons.info_outline,
                                color: up
                                    ? AppColors.neonGreen
                                    : AppColors.neonRed,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${s.$4.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 24,
                          child: CustomPaint(
                            size: const Size(double.infinity, 24),
                            painter: MiniSparkPainter(
                              s.$6,
                              up ? AppColors.neonGreen : AppColors.neonRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          DfcGlassPanel(
            glowColor: AppColors.neonGreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.psychology,
                      size: 16,
                      color: AppColors.neonGreen,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Corner Voice',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neonGreen,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neonOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'FIGHT BUILDING',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neonOrange,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Text(
                      'Day 12',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '30 days left',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    value: 12 / 42,
                    backgroundColor: AppColors.bg,
                    valueColor: AlwaysStoppedAnimation(AppColors.neonGreen),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  CornerVoice.campDay(12, 42),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  CornerVoice.weightCut(72.1, 70.0, 30),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          DfcGlassPanel(
            glowColor: AppColors.neonRed,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 16,
                      color: AppColors.neonRed,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Alerts',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neonRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _alertDot('Resting HR elevated 12%'),
                _alertDot('Weight: 2.1kg over target'),
                _alertDot('Sleep debt: 1.5 hours'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          DfcGlassPanel(
            glowColor: AppColors.neonPurple,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.volunteer_activism,
                      size: 16,
                      color: AppColors.neonPurple,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Community Support',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neonPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  CornerVoice.supportMessage(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mental Health • Addiction • Safety • Housing',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(Icons.campaign, size: 14, color: AppColors.neonOrange),
              SizedBox(width: 6),
              Text(
                'Sponsored',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textTertiary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: PageView.builder(
              controller: _adCtrl,
              itemCount: _ads.length,
              onPageChanged: (i) => setState(() => _adPage = i),
              itemBuilder: (_, i) {
                final a = _ads[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: DfcGlassPanel(
                    glowColor: a.$5,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: a.$5.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(a.$4, size: 22, color: a.$5),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                a.$1,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: a.$5,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                a.$2,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                a.$3,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: a.$5.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            a.$6,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _qAct(Icons.add_circle, 'Training', AppColors.neonBlue),
                _qAct(Icons.monitor_weight, 'Weight', AppColors.neonOrange),
                _qAct(Icons.volunteer_activism, 'Support', AppColors.neonRed),
                _qAct(Icons.water_drop, 'Hydration', AppColors.neonSky),
                _qAct(Icons.bedtime, 'Sleep', AppColors.neonPurple),
                _qAct(Icons.event, 'Event', AppColors.neonGreen),
                _qAct(Icons.edit, 'Post', AppColors.neonRed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _micro(String l, String v, String u, IconData ic, Color c) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(ic, size: 14, color: c),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: v,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: c,
                  ),
                ),
                TextSpan(
                  text: u,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l,
            style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
          ),
        ],
      ),
    ),
  );

  Widget _chip(String l, bool a) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: a
          ? AppColors.neonBlue.withValues(alpha: 0.15)
          : AppColors.elevated,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: a ? AppColors.neonBlue.withValues(alpha: 0.5) : AppColors.border,
      ),
    ),
    child: Text(
      l,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: a ? AppColors.neonBlue : AppColors.textTertiary,
      ),
    ),
  );

  Widget _alertDot(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.neonRed,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          t,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    ),
  );

  Widget _qAct(IconData ic, String l, Color c) => Padding(
    padding: const EdgeInsets.only(right: 10),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.withValues(alpha: 0.25)),
          ),
          child: Icon(ic, size: 20, color: c),
        ),
        const SizedBox(height: 6),
        Text(
          l,
          style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
        ),
      ],
    ),
  );
}

class PromoVideoCard extends StatefulWidget {
  const PromoVideoCard({super.key});

  @override
  State<PromoVideoCard> createState() => _PromoVideoCardState();
}

class _PromoVideoCardState extends State<PromoVideoCard> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(AppLogos.promoVideo)
      ..initialize()
          .then((_) {
            setState(() => _initialized = true);
            _controller.setLooping(true);
            _controller.setVolume(0);
            _controller.play();
          })
          .catchError((e) {
            debugPrint('PromoVideo error: $e');
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox.shrink();

    return DfcGlassPanel(
      glowColor: AppColors.neonBlue,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              VideoPlayer(_controller),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FEATURED PROMO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neonBlue,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'Data Fight Central: The Future',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
