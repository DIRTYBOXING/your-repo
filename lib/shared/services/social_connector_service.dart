import 'package:flutter/foundation.dart';

enum ConnectorPlatform {
  facebook,
  linkedin,
  tiktok,
  instagram,
  snapchat,
  whatsapp,
  xTwitter,
  airtasker,
  youtube,
  threads,
  bluesky,
  pinterest,
}

extension ConnectorPlatformExt on ConnectorPlatform {
  String get label {
    switch (this) {
      case ConnectorPlatform.facebook:
        return 'Facebook';
      case ConnectorPlatform.linkedin:
        return 'LinkedIn';
      case ConnectorPlatform.tiktok:
        return 'TikTok';
      case ConnectorPlatform.instagram:
        return 'Instagram';
      case ConnectorPlatform.snapchat:
        return 'Snapchat';
      case ConnectorPlatform.whatsapp:
        return 'WhatsApp';
      case ConnectorPlatform.xTwitter:
        return 'X / Twitter';
      case ConnectorPlatform.airtasker:
        return 'Airtasker';
      case ConnectorPlatform.youtube:
        return 'YouTube';
      case ConnectorPlatform.threads:
        return 'Threads';
      case ConnectorPlatform.bluesky:
        return 'Bluesky';
      case ConnectorPlatform.pinterest:
        return 'Pinterest';
    }
  }

  String get domain {
    switch (this) {
      case ConnectorPlatform.facebook:
        return 'facebook.com';
      case ConnectorPlatform.linkedin:
        return 'linkedin.com';
      case ConnectorPlatform.tiktok:
        return 'tiktok.com';
      case ConnectorPlatform.instagram:
        return 'instagram.com';
      case ConnectorPlatform.snapchat:
        return 'snapchat.com';
      case ConnectorPlatform.whatsapp:
        return 'whatsapp.com';
      case ConnectorPlatform.xTwitter:
        return 'x.com';
      case ConnectorPlatform.airtasker:
        return 'airtasker.com';
      case ConnectorPlatform.youtube:
        return 'youtube.com';
      case ConnectorPlatform.threads:
        return 'threads.net';
      case ConnectorPlatform.bluesky:
        return 'bsky.app';
      case ConnectorPlatform.pinterest:
        return 'pinterest.com';
    }
  }
}

class ConnectorState {
  final ConnectorPlatform platform;
  final bool connected;
  final bool enabled;
  final DateTime? lastSyncedAt;

  const ConnectorState({
    required this.platform,
    this.connected = false,
    this.enabled = true,
    this.lastSyncedAt,
  });

  ConnectorState copyWith({
    bool? connected,
    bool? enabled,
    DateTime? lastSyncedAt,
  }) {
    return ConnectorState(
      platform: platform,
      connected: connected ?? this.connected,
      enabled: enabled ?? this.enabled,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

class SocialConnectorService extends ChangeNotifier {
  final Map<ConnectorPlatform, ConnectorState> _connectors = {
    for (final platform in ConnectorPlatform.values)
      platform: ConnectorState(platform: platform),
  };

  bool _unifiedEcosystemEnabled = true;
  bool _crossPostEnabled = true;
  bool _strictCleanMode = true;

  bool get unifiedEcosystemEnabled => _unifiedEcosystemEnabled;
  bool get crossPostEnabled => _crossPostEnabled;
  bool get strictCleanMode => _strictCleanMode;

  List<ConnectorState> get connectors => ConnectorPlatform.values
      .map((p) => _connectors[p]!)
      .toList(growable: false);

  int get connectedCount =>
      _connectors.values.where((connector) => connector.connected).length;

  int get enabledCount =>
      _connectors.values.where((connector) => connector.enabled).length;

  ConnectorState stateFor(ConnectorPlatform platform) => _connectors[platform]!;

  Future<void> connectPlatform(ConnectorPlatform platform) async {
    _connectors[platform] = _connectors[platform]!.copyWith(
      connected: true,
      lastSyncedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> disconnectPlatform(ConnectorPlatform platform) async {
    _connectors[platform] = _connectors[platform]!.copyWith(connected: false);
    notifyListeners();
  }

  void setPlatformEnabled(ConnectorPlatform platform, bool enabled) {
    _connectors[platform] = _connectors[platform]!.copyWith(enabled: enabled);
    notifyListeners();
  }

  void setUnifiedEcosystemEnabled(bool value) {
    _unifiedEcosystemEnabled = value;
    notifyListeners();
  }

  void setCrossPostEnabled(bool value) {
    _crossPostEnabled = value;
    notifyListeners();
  }

  void setStrictCleanMode(bool value) {
    _strictCleanMode = value;
    notifyListeners();
  }

  Future<void> syncNow() async {
    final now = DateTime.now();
    for (final platform in ConnectorPlatform.values) {
      final current = _connectors[platform]!;
      if (current.connected && current.enabled) {
        _connectors[platform] = current.copyWith(lastSyncedAt: now);
      }
    }
    notifyListeners();
  }
}
