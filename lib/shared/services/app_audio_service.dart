import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppAudioCue { fightPipeLobby, fightPipeCountdown, fightPipeSting }

extension AppAudioCueX on AppAudioCue {
  String get assetPath {
    switch (this) {
      case AppAudioCue.fightPipeLobby:
        return 'assets/audio/fightpipe_lobby.mp3';
      case AppAudioCue.fightPipeCountdown:
        return 'assets/audio/fightpipe_countdown.mp3';
      case AppAudioCue.fightPipeSting:
        return 'assets/audio/fightpipe_sting.mp3';
    }
  }

  String get label {
    switch (this) {
      case AppAudioCue.fightPipeLobby:
        return 'Lobby Loop';
      case AppAudioCue.fightPipeCountdown:
        return 'Countdown';
      case AppAudioCue.fightPipeSting:
        return 'FightPipe Sting';
    }
  }
}

class AppAudioService extends ChangeNotifier {
  static const _enabledKey = 'dfc_audio_enabled';
  static const _mutedKey = 'dfc_audio_muted';
  static const _volumeKey = 'dfc_audio_volume';

  final AudioPlayer _player = AudioPlayer();
  final Set<AppAudioCue> _availableCues = <AppAudioCue>{};

  bool _initialized = false;
  bool _enabled = true;
  bool _muted = false;
  bool _loading = false;
  bool _gestureUnlocked = !kIsWeb;
  double _volume = 0.72;
  String? _lastError;
  AppAudioCue? _activeCue;

  bool get initialized => _initialized;
  bool get enabled => _enabled;
  bool get muted => _muted;
  bool get loading => _loading;
  bool get requiresGesture => kIsWeb && !_gestureUnlocked;
  double get volume => _volume;
  String? get lastError => _lastError;
  AppAudioCue? get activeCue => _activeCue;
  bool get brandedAudioReady => _availableCues.isNotEmpty;
  List<AppAudioCue> get availableCues => _availableCues.toList(growable: false);

  String get readinessLabel {
    if (!enabled) return 'Branded audio disabled';
    if (requiresGesture) return 'Tap once to unlock audio on web';
    if (!brandedAudioReady) return 'No branded audio files loaded yet';
    if (_activeCue != null) return '${_activeCue!.label} active';
    return 'Audio stack ready';
  }

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? true;
    _muted = prefs.getBool(_mutedKey) ?? false;
    _volume = (prefs.getDouble(_volumeKey) ?? 0.72).clamp(0.0, 1.0);

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed &&
          _player.loopMode != LoopMode.one) {
        _activeCue = null;
        notifyListeners();
      }
    });

    await _player.setVolume(_effectiveVolume);
    await refreshCatalog();
    _initialized = true;
    notifyListeners();
  }

  Future<void> refreshCatalog() async {
    _availableCues.clear();
    for (final cue in AppAudioCue.values) {
      if (await _assetExists(cue.assetPath)) {
        _availableCues.add(cue);
      }
    }
    notifyListeners();
  }

  Future<void> unlockPlayback() async {
    _gestureUnlocked = true;
    _lastError = null;
    notifyListeners();
  }

  Future<bool> playCue(AppAudioCue cue, {bool loop = false}) async {
    if (!_enabled) {
      _lastError = 'Branded audio is disabled.';
      notifyListeners();
      return false;
    }
    if (requiresGesture) {
      _lastError = 'Web playback needs one user tap before audio can start.';
      notifyListeners();
      return false;
    }
    if (!_availableCues.contains(cue)) {
      _lastError = 'Missing audio file: ${cue.assetPath}';
      _activeCue = null;
      notifyListeners();
      return false;
    }

    _loading = true;
    _lastError = null;
    notifyListeners();

    try {
      await _player.stop();
      await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
      await _player.setAsset(cue.assetPath);
      await _player.setVolume(_effectiveVolume);
      await _player.play();
      _activeCue = cue;
      return true;
    } catch (error) {
      _activeCue = null;
      _lastError = 'Audio playback failed: $error';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _activeCue = null;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    if (!value) {
      await stop();
    }
    notifyListeners();
  }

  Future<void> toggleMuted() async {
    _muted = !_muted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mutedKey, _muted);
    await _player.setVolume(_effectiveVolume);
    notifyListeners();
  }

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, _volume);
    await _player.setVolume(_effectiveVolume);
    notifyListeners();
  }

  double get _effectiveVolume => (!_enabled || _muted) ? 0.0 : _volume;

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
