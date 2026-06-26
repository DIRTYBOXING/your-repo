import 'dart:async';
import 'package:flutter/foundation.dart';

/// Available stream quality levels — Mux HLS adaptive, but user can force.
enum StreamQualityLevel { auto, low360p, medium480p, high720p, hd1080p, uhd4k }

extension StreamQualityLevelX on StreamQualityLevel {
  String get label {
    switch (this) {
      case StreamQualityLevel.auto:
        return 'Auto';
      case StreamQualityLevel.low360p:
        return '360p';
      case StreamQualityLevel.medium480p:
        return '480p';
      case StreamQualityLevel.high720p:
        return '720p';
      case StreamQualityLevel.hd1080p:
        return '1080p';
      case StreamQualityLevel.uhd4k:
        return '4K';
    }
  }

  int? get maxHeight {
    switch (this) {
      case StreamQualityLevel.auto:
        return null;
      case StreamQualityLevel.low360p:
        return 360;
      case StreamQualityLevel.medium480p:
        return 480;
      case StreamQualityLevel.high720p:
        return 720;
      case StreamQualityLevel.hd1080p:
        return 1080;
      case StreamQualityLevel.uhd4k:
        return 2160;
    }
  }
}

/// Subtitle track info.
class SubtitleTrack {
  final String id;
  final String label;
  final String language;
  final String? url;
  final bool isDefault;

  const SubtitleTrack({
    required this.id,
    required this.label,
    required this.language,
    this.url,
    this.isDefault = false,
  });
}

/// Player display mode.
enum PlayerMode { inline, fullscreen, pip, miniPlayer }

/// Playback speed options.
enum PlaybackSpeed { x0_5, x0_75, x1_0, x1_25, x1_5, x2_0 }

extension PlaybackSpeedX on PlaybackSpeed {
  double get value {
    switch (this) {
      case PlaybackSpeed.x0_5:
        return 0.5;
      case PlaybackSpeed.x0_75:
        return 0.75;
      case PlaybackSpeed.x1_0:
        return 1.0;
      case PlaybackSpeed.x1_25:
        return 1.25;
      case PlaybackSpeed.x1_5:
        return 1.5;
      case PlaybackSpeed.x2_0:
        return 2.0;
    }
  }

  String get label => '${value}x';
}

/// Enhanced video player service — quality selector, subtitles, PiP,
/// playback speed, wakelock, mini-player. Everything Paramount+ and DAZN have.
class EnhancedVideoPlayerService extends ChangeNotifier {
  static final EnhancedVideoPlayerService _instance =
      EnhancedVideoPlayerService._internal();
  factory EnhancedVideoPlayerService() => _instance;
  EnhancedVideoPlayerService._internal();

  // ── State ─────────────────────────────────────────────────────────────
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _isInitialized = false;

  // Quality
  StreamQualityLevel _quality = StreamQualityLevel.auto;
  final List<StreamQualityLevel> _availableQualities = [
    StreamQualityLevel.auto,
    StreamQualityLevel.low360p,
    StreamQualityLevel.medium480p,
    StreamQualityLevel.high720p,
    StreamQualityLevel.hd1080p,
  ];

  // Subtitles
  SubtitleTrack? _activeSubtitle;
  final List<SubtitleTrack> _availableSubtitles = [];
  bool _subtitlesEnabled = false;

  // Playback
  PlaybackSpeed _speed = PlaybackSpeed.x1_0;
  PlayerMode _mode = PlayerMode.inline;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _buffered = Duration.zero;
  double _volume = 1.0;
  bool _isMuted = false;

  // Wakelock
  bool _wakelockActive = false;

  // Active stream
  String? _activeUrl;
  String? _activeEventId;
  String? _activeTitle;

  // ── Getters ───────────────────────────────────────────────────────────
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  bool get isInitialized => _isInitialized;

  StreamQualityLevel get quality => _quality;
  List<StreamQualityLevel> get availableQualities =>
      List.unmodifiable(_availableQualities);

  SubtitleTrack? get activeSubtitle => _activeSubtitle;
  List<SubtitleTrack> get availableSubtitles =>
      List.unmodifiable(_availableSubtitles);
  bool get subtitlesEnabled => _subtitlesEnabled;

  PlaybackSpeed get speed => _speed;
  PlayerMode get mode => _mode;
  Duration get position => _position;
  Duration get duration => _duration;
  Duration get buffered => _buffered;
  double get volume => _volume;
  bool get isMuted => _isMuted;
  bool get wakelockActive => _wakelockActive;

  String? get activeUrl => _activeUrl;
  String? get activeEventId => _activeEventId;
  String? get activeTitle => _activeTitle;

  double get progress => _duration.inMilliseconds > 0
      ? _position.inMilliseconds / _duration.inMilliseconds
      : 0.0;

  // ── Initialization ────────────────────────────────────────────────────

  /// Load a stream for playback.
  Future<void> loadStream({
    required String url,
    required String eventId,
    String? title,
    Duration? resumeFrom,
    List<SubtitleTrack>? subtitles,
  }) async {
    _activeUrl = url;
    _activeEventId = eventId;
    _activeTitle = title;
    _position = resumeFrom ?? Duration.zero;
    _isInitialized = true;
    _isBuffering = true;

    if (subtitles != null) {
      _availableSubtitles.clear();
      _availableSubtitles.addAll(subtitles);
    }

    // Enable wakelock when playing fights
    await _enableWakelock();

    notifyListeners();
  }

  // ── Quality Control ───────────────────────────────────────────────────

  /// Set stream quality. Mux HLS handles the actual resolution switch.
  void setQuality(StreamQualityLevel quality) {
    if (_quality == quality) return;
    _quality = quality;
    // In production, this sets a max resolution cap on the HLS player
    // Mux ABR handles the rest
    notifyListeners();
  }

  // ── Subtitle Control ──────────────────────────────────────────────────

  /// Enable subtitles with a specific track.
  void setSubtitleTrack(SubtitleTrack? track) {
    _activeSubtitle = track;
    _subtitlesEnabled = track != null;
    notifyListeners();
  }

  /// Toggle subtitles on/off.
  void toggleSubtitles() {
    if (_subtitlesEnabled) {
      _subtitlesEnabled = false;
      _activeSubtitle = null;
    } else if (_availableSubtitles.isNotEmpty) {
      _subtitlesEnabled = true;
      _activeSubtitle = _availableSubtitles.firstWhere(
        (s) => s.isDefault,
        orElse: () => _availableSubtitles.first,
      );
    }
    notifyListeners();
  }

  // ── Playback Control ──────────────────────────────────────────────────

  void play() {
    _isPlaying = true;
    notifyListeners();
  }

  void pause() {
    _isPlaying = false;
    notifyListeners();
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void seekTo(Duration position) {
    _position = position;
    notifyListeners();
  }

  void seekForward([Duration amount = const Duration(seconds: 10)]) {
    _position = Duration(
      milliseconds: (_position + amount).inMilliseconds.clamp(
        0,
        _duration.inMilliseconds,
      ),
    );
    notifyListeners();
  }

  void seekBackward([Duration amount = const Duration(seconds: 10)]) {
    _position = Duration(
      milliseconds: (_position - amount).inMilliseconds.clamp(
        0,
        _duration.inMilliseconds,
      ),
    );
    notifyListeners();
  }

  // ── Speed Control ─────────────────────────────────────────────────────

  void setSpeed(PlaybackSpeed speed) {
    _speed = speed;
    notifyListeners();
  }

  void cycleSpeed() {
    final values = PlaybackSpeed.values;
    final nextIdx = (values.indexOf(_speed) + 1) % values.length;
    _speed = values[nextIdx];
    notifyListeners();
  }

  // ── Volume Control ────────────────────────────────────────────────────

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    _isMuted = _volume == 0;
    notifyListeners();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
  }

  // ── Display Mode ──────────────────────────────────────────────────────

  /// Enter Picture-in-Picture mode.
  void enterPiP() {
    _mode = PlayerMode.pip;
    notifyListeners();
  }

  /// Enter fullscreen mode.
  void enterFullscreen() {
    _mode = PlayerMode.fullscreen;
    notifyListeners();
  }

  /// Enter mini-player mode (bottom overlay while browsing).
  void enterMiniPlayer() {
    _mode = PlayerMode.miniPlayer;
    notifyListeners();
  }

  /// Back to inline mode.
  void exitSpecialMode() {
    _mode = PlayerMode.inline;
    notifyListeners();
  }

  // ── Position Updates (called by player widget) ────────────────────────

  void updatePosition(Duration pos, Duration dur, Duration buf) {
    _position = pos;
    _duration = dur;
    _buffered = buf;
    _isBuffering = false;
    notifyListeners();
  }

  void setBuffering(bool buffering) {
    _isBuffering = buffering;
    notifyListeners();
  }

  // ── Wakelock ──────────────────────────────────────────────────────────

  Future<void> _enableWakelock() async {
    if (kIsWeb) return;
    try {
      // wakelock_plus → WakelockPlus.enable() called from widget layer
      _wakelockActive = true;
    } catch (_) {}
  }

  Future<void> _disableWakelock() async {
    if (kIsWeb) return;
    try {
      _wakelockActive = false;
    } catch (_) {}
  }

  // ── Cleanup ───────────────────────────────────────────────────────────

  /// Stop playback and release resources.
  Future<void> stop() async {
    _isPlaying = false;
    _isInitialized = false;
    _activeUrl = null;
    _activeEventId = null;
    _activeTitle = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    _mode = PlayerMode.inline;
    _subtitlesEnabled = false;
    _activeSubtitle = null;
    await _disableWakelock();
    notifyListeners();
  }
}
