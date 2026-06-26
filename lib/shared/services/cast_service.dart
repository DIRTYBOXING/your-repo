import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Cast target device types
enum CastDeviceType { chromecast, airplay, smartTv, fireTV, roku }

/// A discovered cast target
class CastDevice {
  final String id;
  final String name;
  final CastDeviceType type;
  final bool isConnected;

  const CastDevice({
    required this.id,
    required this.name,
    required this.type,
    this.isConnected = false,
  });
}

/// Current cast session state
enum CastState { idle, connecting, connected, playing, paused, error }

/// Manages casting fight streams to TVs, Chromecast, AirPlay, Fire TV.
/// Uses native platform channels for discovery + Mux HLS URLs for playback.
class CastService extends ChangeNotifier {
  static final CastService _instance = CastService._internal();
  factory CastService() => _instance;
  CastService._internal();

  // ── State ─────────────────────────────────────────────────────────────
  CastState _state = CastState.idle;
  CastDevice? _activeDevice;
  final List<CastDevice> _discoveredDevices = [];
  String? _activeStreamUrl;
  String? _activeEventId;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  String? _lastError;

  // ── Getters ───────────────────────────────────────────────────────────
  CastState get state => _state;
  CastDevice? get activeDevice => _activeDevice;
  List<CastDevice> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);
  String? get activeStreamUrl => _activeStreamUrl;
  String? get activeEventId => _activeEventId;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  bool get isCasting =>
      _state == CastState.playing || _state == CastState.paused;
  String? get lastError => _lastError;

  // ── Discovery ─────────────────────────────────────────────────────────

  /// Scan local network for cast-capable devices.
  Future<List<CastDevice>> discoverDevices() async {
    _discoveredDevices.clear();

    // Chromecast/DIAL discovery via mDNS
    final chromecastDevices = await _discoverChromecast();
    _discoveredDevices.addAll(chromecastDevices);

    // AirPlay discovery via Bonjour
    final airplayDevices = await _discoverAirPlay();
    _discoveredDevices.addAll(airplayDevices);

    notifyListeners();
    return _discoveredDevices;
  }

  Future<List<CastDevice>> _discoverChromecast() async {
    // mDNS scan for _googlecast._tcp services
    // In production this calls platform channel → Android/iOS native cast SDK
    // For now returns empty — native bridge wired per-platform
    return [];
  }

  Future<List<CastDevice>> _discoverAirPlay() async {
    // Bonjour scan for _airplay._tcp services
    // In production this calls platform channel → iOS AirPlay API
    return [];
  }

  // ── Connection ────────────────────────────────────────────────────────

  /// Connect to a discovered cast device.
  Future<bool> connectToDevice(CastDevice device) async {
    _state = CastState.connecting;
    _lastError = null;
    notifyListeners();

    try {
      // Native platform channel → establish session
      await Future.delayed(const Duration(milliseconds: 500));

      _activeDevice = CastDevice(
        id: device.id,
        name: device.name,
        type: device.type,
        isConnected: true,
      );
      _state = CastState.connected;
      notifyListeners();
      return true;
    } catch (e) {
      _state = CastState.error;
      _lastError = 'Connection failed: $e';
      notifyListeners();
      return false;
    }
  }

  /// Disconnect from current cast device.
  Future<void> disconnect() async {
    _activeDevice = null;
    _activeStreamUrl = null;
    _activeEventId = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    _state = CastState.idle;
    notifyListeners();
  }

  // ── Playback ──────────────────────────────────────────────────────────

  /// Cast an HLS stream URL to the connected device.
  Future<bool> castStream({
    required String hlsUrl,
    required String eventId,
    String? title,
    String? thumbnailUrl,
    Duration startPosition = Duration.zero,
  }) async {
    if (_activeDevice == null) return false;

    _state = CastState.playing;
    _activeStreamUrl = hlsUrl;
    _activeEventId = eventId;
    _position = startPosition;
    notifyListeners();

    // Log cast session to Firestore for analytics
    _logCastSession(eventId, _activeDevice!);
    return true;
  }

  /// Pause cast playback.
  void pause() {
    if (_state != CastState.playing) return;
    _state = CastState.paused;
    notifyListeners();
  }

  /// Resume cast playback.
  void resume() {
    if (_state != CastState.paused) return;
    _state = CastState.playing;
    notifyListeners();
  }

  /// Seek to position on cast device.
  void seekTo(Duration position) {
    _position = position;
    notifyListeners();
  }

  /// Set volume (0.0 – 1.0).
  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Update playback position (called by periodic timer or native callback).
  void updatePosition(Duration position, Duration duration) {
    _position = position;
    _duration = duration;
    notifyListeners();
  }

  // ── Analytics ─────────────────────────────────────────────────────────

  void _logCastSession(String eventId, CastDevice device) {
    try {
      FirebaseFirestore.instance.collection('cast_sessions').add({
        'eventId': eventId,
        'deviceType': device.type.name,
        'deviceName': device.name,
        'startedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Non-critical — don't block casting
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Get a user-friendly label for device type.
  static String deviceTypeLabel(CastDeviceType type) {
    switch (type) {
      case CastDeviceType.chromecast:
        return 'Chromecast';
      case CastDeviceType.airplay:
        return 'AirPlay';
      case CastDeviceType.smartTv:
        return 'Smart TV';
      case CastDeviceType.fireTV:
        return 'Fire TV';
      case CastDeviceType.roku:
        return 'Roku';
    }
  }

  /// Icon name for each device type.
  static String deviceTypeIcon(CastDeviceType type) {
    switch (type) {
      case CastDeviceType.chromecast:
        return 'cast';
      case CastDeviceType.airplay:
        return 'airplay';
      case CastDeviceType.smartTv:
        return 'tv';
      case CastDeviceType.fireTV:
        return 'tv';
      case CastDeviceType.roku:
        return 'tv';
    }
  }
}
