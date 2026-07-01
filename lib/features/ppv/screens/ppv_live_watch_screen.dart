import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/streaming_platforms.dart';
import '../../../core/utils/web_route_test_hook.dart';
import '../../../shared/models/ppv_model.dart';
import '../../../shared/services/ppv_service.dart';
import '../../../shared/services/youtube_service.dart';
import '../models/judge_score_models.dart';
import '../services/judge_score_service.dart';
import '../services/ppv_notification_service.dart';
import '../services/ppv_access_service.dart';
import '../widgets/multi_audio_track_selector.dart';
import '../widgets/fight_card_poster.dart';
import '../widgets/dfc_video_player.dart';
import '../widgets/ppv_gate.dart';
import '../widgets/ppv_age_gate.dart';
import '../widgets/ppv_checkout_sheet.dart';
import '../widgets/round_scoring_widget.dart';
import '../widgets/judge_tutorial_dialog.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV LIVE WATCH SCREEN — The Main Event Viewer
/// ═══════════════════════════════════════════════════════════════════════════
///
/// This is where the magic happens. Users who purchased a PPV land here
/// to watch the live stream, chat with other viewers, see the fight card,
/// and get real-time updates round by round.
///
/// Route: /ppv/:ppvId/watch
///
/// Features:
///   • Live stream embed (HLS/DASH via streamUrl or external link)
///   • Live chat (Firestore subcollection ppv_events/{ppvId}/chat)
///   • Fight card with live results updating
///   • Viewer count & engagement stats
///   • Multi-platform stream links (DFC, TrillerTV+, Kayo)
///   • Round-by-round scoring
///   • Pre-event countdown → auto-flip to LIVE
///
/// IBC III specific: March 7, 2026 — Gold Coast Sports & Leisure Centre
/// ═══════════════════════════════════════════════════════════════════════════
class PPVLiveWatchScreen extends StatefulWidget {
  final String ppvId;
  const PPVLiveWatchScreen({super.key, required this.ppvId});

  @override
  State<PPVLiveWatchScreen> createState() => _PPVLiveWatchScreenState();
}

class _PPVLiveWatchScreenState extends State<PPVLiveWatchScreen>
    with TickerProviderStateMixin {
  final PPVService _ppvService = PPVService();
  final PPVAccessService _ppvAccessService = PPVAccessService();
  final PPVNotificationService _notificationService = PPVNotificationService();
  final JudgeScoreService _judgeService = JudgeScoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScroll = ScrollController();

  PPVEvent? _ppv;
  bool _loading = true;
  bool _chatExpanded = true;
  bool _fightCardExpanded = false;
  final int _currentRound = 1;
  final String _currentFightId = 'main_event';
  AudioTrack _selectedAudioTrack = AudioTrack.pro;
  int _viewerCount = 0;
  Timer? _viewerTimer;
  Timer? _countdownTimer;
  Timer? _drmRefreshTimer;
  StreamSubscription<FightModeSignal>? _fightModeSignalSub;
  StreamSubscription<JudgeProfile>? _judgeProfileSub;
  JudgeProfile? _judgeProfile;
  Duration _timeUntilEvent = Duration.zero;
  bool _fightModeEnabled = false;
  String? _signedPlaybackUrl;
  String? _drmPlaybackToken;

  bool _fightFlashActive = false;
  String? _lastSignalLabel;
  DateTime? _lastSignalAt;
  String? _lastSignalSource;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _flashCtrl;
  late Animation<double> _flash;

  @override
  void initState() {
    super.initState();
    setWebRouteTestHook('ppv-watch');
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _flash = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut));
    _subscribeToJudgeProfile();
    _loadPPV();
    _loadFightModePreference();
    _startViewerSimulation();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _flashCtrl.dispose();
    _chatController.dispose();
    _chatScroll.dispose();
    _viewerTimer?.cancel();
    _countdownTimer?.cancel();
    _drmRefreshTimer?.cancel();
    _fightModeSignalSub?.cancel();
    _judgeProfileSub?.cancel();
    super.dispose();
  }

  void _subscribeToJudgeProfile() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _judgeProfileSub = _judgeService.streamUserProfile(userId).listen((
        profile,
      ) {
        if (mounted) {
          setState(() {
            _judgeProfile = profile;
          });
        }
      });
    }
  }

  Future<void> _showJudgeScoringSheet() async {
    // Check if first time judging - show tutorial
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null && _judgeProfile?.totalRounds == 0) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) => const JudgeTutorialDialog(),
      );
      if (!mounted) return;
      if (shouldProceed != true) return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
        ),
        child: RoundScoringWidget(
          eventId: widget.ppvId,
          fightId: _currentFightId,
          currentRound: _currentRound,
          redCornerName: 'Red Corner',
          blueCornerName: 'Blue Corner',
          onScoreSubmitted: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '🎯 Score submitted! Check leaderboard for ranking.',
                ),
                backgroundColor: Colors.cyanAccent,
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showJudgeLeaderboard() {
    context.push('/ppv/judge-leaderboard?eventId=${widget.ppvId}');
  }

  void _showAudioTrackSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MultiAudioTrackSelector(
        selectedTrack: _selectedAudioTrack,
        onTrackChanged: (track) {
          setState(() {
            _selectedAudioTrack = track;
          });
          // Audio stream source switching pending media player integration
        },
        availableTracks: const [
          AudioTrack.pro,
          AudioTrack.casual,
          AudioTrack.ambient,
        ],
      ),
    );
  }

  Future<void> _loadFightModePreference() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final doc = await _firestore
        .collection('user_notification_prefs')
        .doc(userId)
        .get();
    if (!doc.exists || !mounted) return;

    setState(() {
      _fightModeEnabled = doc.data()?['fightModeEnabled'] ?? false;
    });
  }

  Future<void> _toggleFightMode() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final nextValue = !_fightModeEnabled;
    setState(() {
      _fightModeEnabled = nextValue;
    });

    await _firestore.collection('user_notification_prefs').doc(userId).set({
      'fightModeEnabled': nextValue,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _triggerFightModeKO() async {
    if (!_fightModeEnabled) return;

    setState(() {
      _fightFlashActive = true;
    });

    _flashCtrl.forward(from: 0);
    await _notificationService.triggerFightModeKnockoutPulse();
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() {
      _fightFlashActive = false;
    });
  }

  Future<void> _triggerFightModeWalkout() async {
    if (!_fightModeEnabled) return;
    await _notificationService.triggerFightModeWalkoutPreview(widget.ppvId);
  }

  Future<void> _openCheckout() async {
    final ppv = _ppv;
    if (ppv == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to purchase PPV access.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final opened = await PPVCheckoutSheet.show(
      context: context,
      event: ppv,
      tierId: 4,
      paymentMethod: 'stripe',
      userId: user.uid,
    );

    if (!mounted || opened != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Checkout opened. Access unlocks automatically after payment confirmation.',
        ),
      ),
    );
  }

  Future<void> _triggerFightModeMainEvent() async {
    if (!_fightModeEnabled) return;
    await _notificationService.triggerFightModeMainEventPreview(widget.ppvId);
  }

  Future<void> _loadPPV() async {
    final ppv = await _ppvService.getPPVEvent(widget.ppvId);
    if (mounted) {
      setState(() {
        _ppv = ppv;
        _signedPlaybackUrl = null;
        _drmPlaybackToken = null;
        _loading = false;
        if (ppv != null) {
          _timeUntilEvent = ppv.eventDate.difference(DateTime.now());
          if (_timeUntilEvent.isNegative) _timeUntilEvent = Duration.zero;
        }
      });
      _startCountdown();
      unawaited(_refreshSignedPlaybackUrl());
      unawaited(_refreshDrmPlaybackToken());
    }
  }

  Future<void> _refreshSignedPlaybackUrl() async {
    final ppv = _ppv;
    if (ppv == null) {
      return;
    }

    final signedUrl = await _ppvAccessService.fetchSignedPlaybackUrl(ppv.id);
    if (!mounted || signedUrl == null || signedUrl.isEmpty) {
      return;
    }

    setState(() {
      _signedPlaybackUrl = signedUrl;
    });
  }

  Future<void> _refreshDrmPlaybackToken() async {
    final ppv = _ppv;
    if (ppv == null || !ppv.hasDrmPlaybackConfig) {
      return;
    }

    final token = await _ppvAccessService.fetchDrmPlaybackToken(
      ppv,
      device: kIsWeb ? 'web' : 'mobile',
    );
    if (!mounted || token == null) {
      return;
    }

    setState(() {
      _drmPlaybackToken = token.token;
    });

    _scheduleDrmRefresh(token.expiresInSeconds);
  }

  void _scheduleDrmRefresh(int expiresInSeconds) {
    _drmRefreshTimer?.cancel();
    if (expiresInSeconds <= 0) {
      return;
    }

    final refreshAfterSeconds = expiresInSeconds > 20
        ? expiresInSeconds - 10
        : expiresInSeconds.clamp(5, 15);
    _drmRefreshTimer = Timer(Duration(seconds: refreshAfterSeconds), () {
      if (mounted) {
        unawaited(_refreshDrmPlaybackToken());
      }
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_ppv == null || !mounted) return;
      setState(() {
        _timeUntilEvent = _ppv!.eventDate.difference(DateTime.now());
        if (_timeUntilEvent.isNegative) _timeUntilEvent = Duration.zero;
      });
    });
  }

  void _startViewerSimulation() {
    // Simulate growing viewer count for demo
    _viewerCount = 1247;
    _viewerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        _viewerCount += (DateTime.now().second % 7) - 2;
        if (_viewerCount < 1000) _viewerCount = 1000 + DateTime.now().second;
      });
    });
  }

  bool get _isLive =>
      _ppv?.status == PPVStatus.live || _timeUntilEvent == Duration.zero;

  bool get _hasDirectStreamPlayback =>
      (_ppv?.streamUrl ?? '').trim().isNotEmpty;

  List<String> get _partnerPlatforms {
    final ppv = _ppv;
    if (ppv == null) {
      return const <String>[];
    }

    return ppv.streamPlatforms
        .where((platform) => platform.toUpperCase() != 'DFC')
        .where((platform) => StreamingPlatforms.urlFor(platform).isNotEmpty)
        .toList(growable: false);
  }

  String get _countdownText {
    if (_isLive) return 'LIVE NOW';
    final d = _timeUntilEvent;
    if (d.inDays > 0) {
      return '${d.inDays}d ${d.inHours % 24}h ${d.inMinutes % 60}m';
    }
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m ${d.inSeconds % 60}s';
    }
    return '${d.inMinutes}m ${d.inSeconds % 60}s';
  }

  String _signalAgeText() {
    if (_lastSignalAt == null) return '';
    final age = DateTime.now().difference(_lastSignalAt!);
    if (age.inSeconds < 60) return '${age.inSeconds}s';
    return '${age.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Loading...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        ),
      );
    }

    if (_ppv == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'PPV Event Not Found',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/ppv'),
                child: const Text('Back to PPV Hub'),
              ),
            ],
          ),
        ),
      );
    }

    return PpvAgeGate(
      child: Semantics(
        label: 'data-test=ppv-watch-root-${widget.ppvId}',
        child: PpvGate(
          ppvId: widget.ppvId,
          event: _ppv,
          child: Semantics(
            label: 'data-test=ppv-watch-surface',
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Semantics(
                      label: 'data-test=ppv-watch',
                      child: const SizedBox(width: 1, height: 1),
                    ),
                  ),
                  CustomScrollView(
                    slivers: [
                      // ── App Bar ──
                      SliverAppBar(
                        backgroundColor: _isLive
                            ? Colors.red.shade900
                            : Colors.black,
                        pinned: true,
                        expandedHeight: 0,
                        title: Row(
                          children: [
                            if (_isLive)
                              AnimatedBuilder(
                                animation: _pulse,
                                builder: (_, _) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(
                                      alpha: _pulse.value,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        color: Colors.white,
                                        size: 8,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'LIVE',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                _ppv!.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          if (_lastSignalLabel != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.65),
                                ),
                              ),
                              child: Text(
                                '${_lastSignalLabel!} (${_lastSignalSource ?? '?'}) ${_signalAgeText()}',
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          // Judge XP Badge
                          if (_judgeProfile != null &&
                              _judgeProfile!.totalXP > 0)
                            GestureDetector(
                              onTap: _showJudgeLeaderboard,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.purple.withValues(alpha: 0.3),
                                      Colors.cyanAccent.withValues(alpha: 0.3),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.cyanAccent.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.gavel,
                                      color: Colors.cyanAccent,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_judgeProfile!.totalXP} XP',
                                      style: const TextStyle(
                                        color: Colors.cyanAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Judge Round Button
                          IconButton(
                            icon: const Icon(
                              Icons.gavel,
                              color: Colors.cyanAccent,
                            ),
                            onPressed: _showJudgeScoringSheet,
                            tooltip: 'Score This Round',
                          ),
                          // Audio Track Button
                          IconButton(
                            icon: const Icon(
                              Icons.headset,
                              color: Colors.cyanAccent,
                            ),
                            onPressed: _showAudioTrackSelector,
                            tooltip: 'Audio Track',
                          ),
                          // Viewer count
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.visibility,
                                  color: Colors.cyanAccent,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _viewerCount.toString().replaceAllMapped(
                                    RegExp(r'(\d)(?=(\d{3})+$)'),
                                    (m) => '${m[1]},',
                                  ),
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            // ── Stream Player Area ──
                            _buildStreamPlayer(),

                            // ── Stream Platform Links ──
                            _buildStreamPlatforms(),

                            // ── Fight Mode ──
                            _buildFightModePanel(),

                            // ── Live Chat ──
                            _buildLiveChat(),

                            // ── Fight Card ──
                            _buildFightCard(),

                            // ── Event Info ──
                            _buildEventInfo(),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_fightFlashActive)
                    IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _flash,
                        builder: (context, child) => Container(
                          color: Colors.redAccent.withValues(
                            alpha: _flash.value,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFightModePanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _fightModeEnabled
              ? Colors.redAccent.withValues(alpha: 0.9)
              : Colors.white24,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _fightModeEnabled ? Icons.flash_on : Icons.flash_off,
            color: _fightModeEnabled ? Colors.redAccent : Colors.white70,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FIGHT MODE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  _fightModeEnabled
                      ? 'KO flash + heavy vibration is armed'
                      : 'Enable for knockout flash and haptic blast',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _toggleFightMode,
            child: Text(_fightModeEnabled ? 'ON' : 'OFF'),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            enabled: _fightModeEnabled,
            onSelected: (value) {
              if (value == 'walkout') {
                _triggerFightModeWalkout();
              } else if (value == 'main') {
                _triggerFightModeMainEvent();
              } else {
                _triggerFightModeKO();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'walkout', child: Text('Test Walkout')),
              PopupMenuItem(value: 'main', child: Text('Test Main Event')),
              PopupMenuItem(value: 'ko', child: Text('Test KO Pulse')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _fightModeEnabled ? Colors.redAccent : Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'HYPE TEST',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STREAM PLAYER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStreamPlayer() {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey.shade900, Colors.black],
        ),
      ),
      child: _isLive ? _buildLivePlayerUI() : _buildPreEventUI(),
    );
  }

  Widget _buildLivePlayerUI() {
    final streamUrl = _signedPlaybackUrl ?? _ppv?.streamUrl;
    if (_isEmbeddableStream(streamUrl)) {
      return Stack(
        fit: StackFit.expand,
        children: [
          DFCVideoPlayer(
            streamUrl: streamUrl,
            isLive: true,
            viewerCount: _viewerCount,
            eventTitle: _ppv!.title,
            posterUrl: _ppv!.posterUrl,
            drmToken: _drmPlaybackToken,
            widevineLicenseUrl: _ppv!.drmWidevineLicenseUrl,
            fairplayLicenseUrl: _ppv!.drmFairplayLicenseUrl,
            fairplayCertificateUrl: _ppv!.drmFairplayCertificateUrl,
            showChat: _chatExpanded,
            onChatToggle: () {
              setState(() {
                _chatExpanded = !_chatExpanded;
              });
            },
          ),
          if (streamUrl != null)
            Positioned(
              bottom: 12,
              right: 12,
              child: ElevatedButton.icon(
                onPressed: () => _openStream(streamUrl),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Open External'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.7),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      );
    }

    if (!_hasDirectStreamPlayback) {
      return _buildRightsPendingPlayerUI();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Simulated stream background
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [Colors.deepPurple.shade900, Colors.black],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, _) => Icon(
                    Icons.play_circle_filled,
                    size: 80,
                    color: Colors.cyanAccent.withValues(alpha: _pulse.value),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'STREAM ACTIVE',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _ppv!.title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                // Stream URL button
                if (_ppv!.streamUrl != null)
                  ElevatedButton.icon(
                    onPressed: () => _openStream(_ppv!.streamUrl!),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Open Full Stream'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () =>
                        _openStream('https://www.trillertvplus.com'),
                    icon: const Icon(Icons.live_tv, size: 16),
                    label: const Text('Watch on TrillerTV+'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // LIVE badge overlay
        Positioned(
          top: 12,
          left: 12,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: _pulse.value),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: _pulse.value * 0.5),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 8),
                  SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Viewer count overlay
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.visibility,
                  color: Colors.cyanAccent,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_viewerCount watching',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightsPendingPlayerUI() {
    final partnerPlatform = _partnerPlatforms.isNotEmpty
        ? _partnerPlatforms.first
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blueGrey.shade900,
            Colors.black,
            Colors.red.shade900.withValues(alpha: 0.25),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_outlined,
                size: 56,
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'Live video is temporarily unavailable in DFC',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Playback stays hidden until the event media approval check is complete. This protects rights, replay, and downstream distribution.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              if (partnerPlatform != null) ...[
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () =>
                      _openStream(StreamingPlatforms.urlFor(partnerPlatform)),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text('Open $partnerPlatform'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreEventUI() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade900,
            Colors.black,
            Colors.red.shade900.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_ppv!.fightCard.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FightCardPoster(event: _ppv!, height: 80, width: 140),
              ),
            const SizedBox(height: 12),
            Text(
              _ppv!.subtitle ?? _ppv!.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Countdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(8),
                color: Colors.black.withValues(alpha: 0.5),
              ),
              child: Column(
                children: [
                  Text(
                    'STARTS IN',
                    style: TextStyle(
                      color: Colors.cyanAccent.withValues(alpha: 0.7),
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _countdownText,
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Gold Coast Sports & Leisure Centre',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STREAM PLATFORMS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStreamPlatforms() {
    final platforms = _ppv!.streamPlatforms;
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade900.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLive && !_hasDirectStreamPlayback)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                'DFC playback is hidden until rights-approved event media is available. Partner links below can still be used when provided.',
                style: TextStyle(
                  color: Colors.orange.shade100,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          Row(
            children: [
              const Icon(Icons.live_tv, color: Colors.cyanAccent, size: 16),
              const SizedBox(width: 6),
              Text(
                _isLive ? 'WATCH ON' : 'AVAILABLE ON',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...platforms.map(_platformChip),
              _platformChip('Eventbrite', icon: Icons.confirmation_number),
            ],
          ),
        ],
      ),
    );
  }

  Widget _platformChip(String name, {IconData? icon}) {
    final color = StreamingPlatforms.colorFor(name);
    final chipIcon = icon ?? StreamingPlatforms.iconFor(name);
    final url = StreamingPlatforms.urlFor(name);

    return InkWell(
      onTap: () {
        if (url.isNotEmpty) _openStream(url);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(chipIcon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIVE CHAT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLiveChat() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Chat header
          InkWell(
            onTap: () => setState(() => _chatExpanded = !_chatExpanded),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.chat_bubble,
                    color: Colors.cyanAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'LIVE CHAT',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  if (_isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(color: Colors.green, fontSize: 10),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _chatExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white54,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_chatExpanded) ...[
            // Chat messages
            SizedBox(
              height: 200,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _ppvService.streamChat(widget.ppvId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white.withValues(alpha: 0.3),
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isLive
                                ? 'Be the first to chat!'
                                : 'Chat opens when event goes LIVE',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final messages = snapshot.data!;
                  return ListView.builder(
                    controller: _chatScroll,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final msg = messages[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${msg['userName'] ?? 'Fan'}: ',
                                style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              TextSpan(
                                text: msg['message'] ?? '',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Chat input
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: _isLive
                            ? 'Send a message...'
                            : 'Chat opens at event time',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.cyanAccent.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.cyanAccent.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Colors.cyanAccent,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      enabled: _isLive,
                      onSubmitted: (_) => _sendChat(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isLive ? _sendChat : null,
                    icon: const Icon(Icons.send),
                    color: Colors.cyanAccent,
                    iconSize: 20,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _sendChat() {
    final msg = _chatController.text.trim();
    if (msg.isEmpty) return;
    _ppvService.sendChatMessage(
      ppvId: widget.ppvId,
      userId: 'viewer_${DateTime.now().millisecondsSinceEpoch}',
      userName: 'DFC Fan',
      message: msg,
    );
    _chatController.clear();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIGHT CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFightCard() {
    final fights = _ppv!.fightCard;
    if (fights.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                setState(() => _fightCardExpanded = !_fightCardExpanded),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.format_list_numbered,
                    color: Colors.deepPurple,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'FIGHT CARD (${fights.length} BOUTS)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _fightCardExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white54,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_fightCardExpanded)
            ...fights.asMap().entries.map((e) {
              final i = e.key;
              final fight = e.value;
              return _buildFightRow(fight, i, fights.length);
            }),
          if (!_fightCardExpanded && fights.isNotEmpty)
            _buildFightRow(
              fights.firstWhere(
                (f) => f.isMainEvent,
                orElse: () => fights.first,
              ),
              0,
              1,
            ),
        ],
      ),
    );
  }

  Widget _buildFightRow(PPVFight fight, int index, int total) {
    final isMain = fight.isMainEvent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: index < total - 1
            ? Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              )
            : null,
        color: isMain
            ? Colors.deepPurple.withValues(alpha: 0.05)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          // Fight number
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMain
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                color: isMain
                    ? Colors.red
                    : Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              isMain ? '★' : '${index + 1}',
              style: TextStyle(
                color: isMain ? Colors.red : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Fighter names
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isMain)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'MAIN',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (fight.isTitleFight)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'TITLE',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${fight.fighter1Name} vs ${fight.fighter2Name}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMain ? 14 : 13,
                    fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  '${fight.weightClass} • ${fight.rounds} Rds',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Result badge
          if (fight.result != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                fight.result!,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (_isLive)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: _pulse.value * 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EVENT INFO
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEventInfo() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EVENT DETAILS',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.event,
            'Date',
            '${_ppv!.eventDate.day}/${_ppv!.eventDate.month}/${_ppv!.eventDate.year}',
          ),
          _infoRow(
            Icons.access_time,
            'Time',
            '${_ppv!.eventDate.hour}:${_ppv!.eventDate.minute.toString().padLeft(2, '0')} AEST',
          ),
          _infoRow(
            Icons.location_on,
            'Venue',
            'Gold Coast Sports & Leisure Centre',
          ),
          _infoRow(
            Icons.sports_mma,
            'Promoter',
            _ppv!.promoterId == 'ibc' ? 'Danny Mac — IBC' : _ppv!.promoterId,
          ),
          _infoRow(Icons.attach_money, 'PPV Price', _ppv!.priceDisplay),
          _infoRow(Icons.people, 'Purchases', '${_ppv!.purchaseCount}'),

          const SizedBox(height: 16),

          // Purchase / Buy button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openCheckout,
              icon: const Icon(Icons.shopping_cart),
              label: Text('BUY PPV — ${_ppv!.priceDisplay}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Back to PPV hub
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/ppv'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to PPV Hub'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.cyanAccent,
                side: const BorderSide(color: Colors.cyanAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openStream(String url) async {
    final uri = YouTubeService.normalizePublicYoutubeUri(
      url,
      fallbackSearchQuery: 'DFC PPV live stream',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool _isEmbeddableStream(String? url) {
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return false;
    }

    final host = uri.host.toLowerCase();
    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      return false;
    }

    final path = uri.path.toLowerCase();
    return path.endsWith('.m3u8') ||
        path.endsWith('.mpd') ||
        path.endsWith('.mp4') ||
        path.endsWith('.webm') ||
        !path.contains('.');
  }
}
