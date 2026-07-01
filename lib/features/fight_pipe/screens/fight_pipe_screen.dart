import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/app_audio_service.dart';

class FightPipeScreen extends StatefulWidget {
  final String userId;

  const FightPipeScreen({super.key, required this.userId});

  @override
  State<FightPipeScreen> createState() => _FightPipeScreenState();
}

class _FightPipeScreenState extends State<FightPipeScreen>
    with TickerProviderStateMixin {
  late final TabController _tabCtrl;
  late final AnimationController _pulseCtrl;
  Timer? _timer;

  final DateTime _featuredStart = DateTime.now().add(
    const Duration(days: 2, hours: 7, minutes: 22),
  );
  Duration _remaining = Duration.zero;

  static const _liveEvents = [
    _FightPipeEvent(
      title: 'DFC: Pacific Shockwave',
      subtitle: 'Main Card Live',
      location: 'Port Moresby, PNG',
      actionText: 'WATCH LIVE',
      viewers: 18420,
      priceAUD: 14.99,
      accent: Color(0xFFFF6B35),
      isLive: true,
    ),
  ];

  static const _upcomingEvents = [
    _FightPipeEvent(
      title: 'DFC: Australia vs Oceania',
      subtitle: 'PPV Numbered Event',
      location: 'Melbourne, AUS',
      actionText: 'BUY PPV',
      viewers: 0,
      priceAUD: 19.99,
      accent: Color(0xFFFFD740),
      isLive: false,
    ),
    _FightPipeEvent(
      title: 'DFC Fight Night: Manila Rumble',
      subtitle: 'Fight Night Series',
      location: 'Manila, PH',
      actionText: 'PRE-ORDER',
      viewers: 0,
      priceAUD: 9.99,
      accent: Color(0xFF00E5FF),
      isLive: false,
    ),
  ];

  static const _replays = [
    _FightPipeReplay(
      title: 'DFC Replay: Gold Coast Clash',
      division: 'Welterweight',
      duration: '02:14:08',
      watched: 72000,
    ),
    _FightPipeReplay(
      title: 'DFC Replay: K1 India Open',
      division: 'Lightweight',
      duration: '01:46:30',
      watched: 55200,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _tick() {
    final diff = _featuredStart.difference(DateTime.now());
    if (!mounted) return;
    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
    });
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AppAudioService>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rocket_launch,
                color: Color(0xFFFF6B35),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'FightPipe',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: audio.requiresGesture
                ? 'Enable audio'
                : 'Mute branded audio',
            onPressed: () async {
              if (audio.requiresGesture) {
                await audio.unlockPlayback();
              } else {
                await audio.toggleMuted();
              }
            },
            icon: Icon(
              audio.requiresGesture
                  ? Icons.volume_up
                  : (audio.muted ? Icons.volume_off : Icons.volume_up),
              color: const Color(0xFFFFD740),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          _buildFeaturedHero(),
          _buildAudioRail(audio),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildLiveTab(audio),
                _buildUpcomingTab(audio),
                _buildReplayTab(audio),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedHero() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF6B35).withValues(alpha: 0.24),
            const Color(0xFFFFD740).withValues(alpha: 0.12),
            AppTheme.cardDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF6B35).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'PPV BY DFC · WATCH ON FIGHTPIPE',
                style: TextStyle(
                  color: Color(0xFFFFD740),
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, child) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF69FF47,
                    ).withValues(alpha: 0.10 + 0.12 * _pulseCtrl.value),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(
                        0xFF69FF47,
                      ).withValues(alpha: 0.35 + 0.25 * _pulseCtrl.value),
                    ),
                  ),
                  child: const Text(
                    'COUNTDOWN LIVE',
                    style: TextStyle(
                      color: Color(0xFF69FF47),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'DFC Numbered Event 028',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Main card + prelims + creator watch parties',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _timeBox('D', _remaining.inDays.toString().padLeft(2, '0')),
              _timeBox(
                'H',
                (_remaining.inHours % 24).toString().padLeft(2, '0'),
              ),
              _timeBox(
                'M',
                (_remaining.inMinutes % 60).toString().padLeft(2, '0'),
              ),
              _timeBox(
                'S',
                (_remaining.inSeconds % 60).toString().padLeft(2, '0'),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  _regionalPrice(),
                  style: const TextStyle(
                    color: Color(0xFFFF6B35),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeBox(String label, String value) {
    return Container(
      width: 44,
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.cardDark,
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: const Color(0xFFFF6B35),
        labelColor: const Color(0xFFFF6B35),
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        tabs: const [
          Tab(icon: Icon(Icons.circle, size: 10), text: 'LIVE NOW'),
          Tab(icon: Icon(Icons.calendar_today, size: 13), text: 'UPCOMING'),
          Tab(icon: Icon(Icons.replay, size: 14), text: 'REPLAY'),
        ],
      ),
    );
  }

  Widget _buildAudioRail(AppAudioService audio) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.graphic_eq, color: Color(0xFFFFD740), size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'FightPipe audio control rail',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              if (audio.activeCue != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF69FF47).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    audio.activeCue!.label.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF69FF47),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            audio.readinessLabel,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          if (!audio.brandedAudioReady) ...[
            const SizedBox(height: 8),
            Text(
              'No branded FightPipe MP3 files are loaded yet. PPV stream audio remains the primary audio path, so live events stay safe even before music lands.',
              style: TextStyle(
                color: Colors.orange.shade200,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
          if (audio.lastError != null) ...[
            const SizedBox(height: 8),
            Text(
              audio.lastError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _audioAction(
                label: audio.requiresGesture ? 'Enable Audio' : 'Lobby Loop',
                color: const Color(0xFFFFD740),
                onTap: () async {
                  if (audio.requiresGesture) {
                    await audio.unlockPlayback();
                  } else {
                    await audio.playCue(AppAudioCue.fightPipeLobby, loop: true);
                  }
                },
              ),
              _audioAction(
                label: 'Countdown',
                color: const Color(0xFFFF6B35),
                onTap: () => audio.playCue(AppAudioCue.fightPipeCountdown),
              ),
              _audioAction(
                label: 'Sting',
                color: const Color(0xFF00E5FF),
                onTap: () => audio.playCue(AppAudioCue.fightPipeSting),
              ),
              _audioAction(
                label: 'Stop',
                color: Colors.white54,
                onTap: audio.stop,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                audio.muted ? Icons.volume_off : Icons.volume_down,
                color: AppTheme.textSecondary,
                size: 16,
              ),
              Expanded(
                child: Slider(
                  value: audio.volume,
                  activeColor: const Color(0xFFFF6B35),
                  inactiveColor: Colors.white12,
                  onChanged: audio.enabled ? audio.setVolume : null,
                ),
              ),
              Text(
                '${(audio.volume * 100).round()}%',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _audioAction({
    required String label,
    required Color color,
    required Future<void> Function() onTap,
  }) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildLiveTab(AppAudioService audio) {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _liveEvents.length,
      itemBuilder: (_, i) => _eventCard(_liveEvents[i], audio),
    );
  }

  Widget _buildUpcomingTab(AppAudioService audio) {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _upcomingEvents.length,
      itemBuilder: (_, i) => _eventCard(_upcomingEvents[i], audio),
    );
  }

  Widget _eventCard(_FightPipeEvent event, AppAudioService audio) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: event.accent.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              if (event.isLive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            event.subtitle,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(
            event.location,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 9,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: event.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    event.isLive
                        ? '${_fmt(event.viewers)} watching now'
                        : _regionalPrice(baseAud: event.priceAUD),
                    style: TextStyle(
                      color: event.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  await _handleEventAction(event, audio);
                  if (!mounted) return;
                  if (event.isLive) {
                    context.go('/ppv/ppv-ibc-03/watch');
                    return;
                  }
                  context.go('/ppv');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: event.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  event.actionText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplayTab(AppAudioService audio) {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _replays.length,
      itemBuilder: (_, i) {
        final replay = _replays[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.play_arrow, color: Color(0xFFFF6B35)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      replay.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${replay.division} · ${replay.duration} · ${_fmt(replay.watched)} views',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () async {
                  await audio.playCue(AppAudioCue.fightPipeSting);
                  if (!mounted) return;
                  context.go('/ppv/ppv-ibc-03/watch');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF6B35),
                  side: BorderSide(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.5),
                  ),
                ),
                child: const Text('WATCH'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _regionalPrice({double baseAud = 12.99}) {
    final code =
        Localizations.localeOf(context).countryCode?.toUpperCase() ?? 'AU';
    return switch (code) {
      'IN' => 'INR ${(baseAud * 55).toStringAsFixed(0)}',
      'PG' => 'PGK ${(baseAud * 2.7).toStringAsFixed(0)}',
      'US' => 'USD ${(baseAud * 0.65).toStringAsFixed(2)}',
      'CA' => 'CAD ${(baseAud * 0.89).toStringAsFixed(2)}',
      'GB' => 'GBP ${(baseAud * 0.51).toStringAsFixed(2)}',
      'DE' ||
      'FR' ||
      'IT' ||
      'ES' ||
      'NL' ||
      'PT' ||
      'IE' ||
      'BE' ||
      'AT' => 'EUR ${(baseAud * 0.60).toStringAsFixed(2)}',
      'JP' => 'JPY ${(baseAud * 99).toStringAsFixed(0)}',
      'KR' => 'KRW ${(baseAud * 900).toStringAsFixed(0)}',
      'SG' => 'SGD ${(baseAud * 0.86).toStringAsFixed(2)}',
      'NZ' => 'NZD ${(baseAud * 1.08).toStringAsFixed(2)}',
      'BR' => 'BRL ${(baseAud * 3.8).toStringAsFixed(2)}',
      'MX' => 'MXN ${(baseAud * 13).toStringAsFixed(2)}',
      'ZA' => 'ZAR ${(baseAud * 11.7).toStringAsFixed(0)}',
      'NG' => 'NGN ${(baseAud * 1050).toStringAsFixed(0)}',
      'KE' => 'KES ${(baseAud * 85).toStringAsFixed(0)}',
      'GH' => 'GHS ${(baseAud * 10.5).toStringAsFixed(0)}',
      'EG' => 'EGP ${(baseAud * 33).toStringAsFixed(0)}',
      'MA' => 'MAD ${(baseAud * 6.3).toStringAsFixed(0)}',
      _ => 'AUD ${baseAud.toStringAsFixed(2)}',
    };
  }

  String _fmt(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toString();
  }

  Future<void> _handleEventAction(
    _FightPipeEvent event,
    AppAudioService audio,
  ) async {
    if (audio.requiresGesture) {
      await audio.unlockPlayback();
    }

    if (event.isLive) {
      await audio.stop();
      return;
    }

    if (event.actionText == 'PRE-ORDER') {
      await audio.playCue(AppAudioCue.fightPipeSting);
      return;
    }

    await audio.playCue(AppAudioCue.fightPipeCountdown);
  }
}

class _FightPipeEvent {
  final String title;
  final String subtitle;
  final String location;
  final String actionText;
  final int viewers;
  final double priceAUD;
  final Color accent;
  final bool isLive;

  const _FightPipeEvent({
    required this.title,
    required this.subtitle,
    required this.location,
    required this.actionText,
    required this.viewers,
    required this.priceAUD,
    required this.accent,
    required this.isLive,
  });
}

class _FightPipeReplay {
  final String title;
  final String division;
  final String duration;
  final int watched;

  const _FightPipeReplay({
    required this.title,
    required this.division,
    required this.duration,
    required this.watched,
  });
}
