import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// REAL-TIME WEBSOCKET SERVICE — Live Fight Updates, Chat, Scores
/// ═══════════════════════════════════════════════════════════════════════════

final _firestore = FirebaseFirestore.instance;

enum WSMessageType {
  fightUpdate,
  roundEnd,
  knockout,
  submission,
  decision,
  chatMessage,
  viewerCount,
  prediction,
  scoreUpdate,
  heartbeat,
  error,
  connect,
  disconnect,
}

enum ConnectionState { disconnected, connecting, connected, reconnecting }

class WSMessage {
  final String id;
  final WSMessageType type;
  final String channel;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  const WSMessage({
    required this.id,
    required this.type,
    required this.channel,
    required this.payload,
    required this.timestamp,
  });

  factory WSMessage.fromJson(Map<String, dynamic> json) => WSMessage(
    id: json['id'] ?? '',
    type: WSMessageType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => WSMessageType.heartbeat,
    ),
    channel: json['channel'] ?? 'global',
    payload: Map<String, dynamic>.from(json['payload'] ?? {}),
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'channel': channel,
    'payload': payload,
    'timestamp': timestamp.toIso8601String(),
  };
}

class RealtimeWebSocketService with ChangeNotifier {
  static final RealtimeWebSocketService _instance =
      RealtimeWebSocketService._internal();
  factory RealtimeWebSocketService() => _instance;
  RealtimeWebSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  ConnectionState _connectionState = ConnectionState.disconnected;
  String? _currentUserId;
  final Set<String> _subscribedChannels = {};
  final List<WSMessage> _messageBuffer = [];
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _reconnectDelay = Duration(seconds: 3);

  // Event callbacks
  final List<void Function(WSMessage)> _messageListeners = [];
  final Map<WSMessageType, List<void Function(WSMessage)>> _typeListeners = {};

  ConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == ConnectionState.connected;
  Set<String> get subscribedChannels => Set.unmodifiable(_subscribedChannels);

  /// Connect to the WebSocket server
  Future<void> connect({required String userId, String? wsUrl}) async {
    if (_connectionState == ConnectionState.connecting ||
        _connectionState == ConnectionState.connected) {
      return;
    }

    _currentUserId = userId;
    _connectionState = ConnectionState.connecting;
    notifyListeners();

    try {
      // Get WebSocket URL from Firestore config or use default
      final configDoc = await _firestore
          .collection('config')
          .doc('websocket')
          .get();
      final url =
          wsUrl ?? configDoc.data()?['url'] ?? 'wss://ws.datafightcentral.com';

      debugPrint('🔌 RealtimeWebSocketService: Connecting to $url');
      _channel = WebSocketChannel.connect(Uri.parse('$url?userId=$userId'));

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // Start heartbeat
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(
        _heartbeatInterval,
        (_) => _sendHeartbeat(),
      );

      _connectionState = ConnectionState.connected;
      _reconnectAttempts = 0;
      notifyListeners();

      // Resubscribe to channels
      for (final channel in _subscribedChannels) {
        _sendSubscribe(channel);
      }

      debugPrint('🔌 RealtimeWebSocketService: Connected');
    } catch (e) {
      debugPrint('RealtimeWebSocketService: Connect failed: $e');
      _connectionState = ConnectionState.disconnected;
      notifyListeners();
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final message = WSMessage.fromJson(json);

      // Buffer recent messages
      _messageBuffer.add(message);
      if (_messageBuffer.length > 100) _messageBuffer.removeAt(0);

      // Notify global listeners
      for (final listener in _messageListeners) {
        listener(message);
      }

      // Notify type-specific listeners
      final typeListeners = _typeListeners[message.type];
      if (typeListeners != null) {
        for (final listener in typeListeners) {
          listener(message);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('RealtimeWebSocketService: Parse error: $e');
    }
  }

  void _onError(Object error) {
    debugPrint('RealtimeWebSocketService: WebSocket error: $error');
    _connectionState = ConnectionState.disconnected;
    notifyListeners();
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('RealtimeWebSocketService: WebSocket closed');
    _connectionState = ConnectionState.disconnected;
    notifyListeners();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts || _currentUserId == null) {
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay * (_reconnectAttempts + 1), () {
      _reconnectAttempts++;
      _connectionState = ConnectionState.reconnecting;
      notifyListeners();
      connect(userId: _currentUserId!);
    });
  }

  void _sendHeartbeat() {
    if (!isConnected) return;
    _send({'type': 'heartbeat', 'timestamp': DateTime.now().toIso8601String()});
  }

  void _send(Map<String, dynamic> data) {
    if (_channel == null || !isConnected) return;
    try {
      _channel!.sink.add(jsonEncode(data));
    } catch (e) {
      debugPrint('RealtimeWebSocketService: Send failed: $e');
    }
  }

  /// Subscribe to a channel (e.g., 'fight:123', 'chat:event456')
  void subscribe(String channel) {
    _subscribedChannels.add(channel);
    if (isConnected) _sendSubscribe(channel);
  }

  void _sendSubscribe(String channel) {
    _send({'type': 'subscribe', 'channel': channel});
  }

  /// Unsubscribe from a channel
  void unsubscribe(String channel) {
    _subscribedChannels.remove(channel);
    if (isConnected) _send({'type': 'unsubscribe', 'channel': channel});
  }

  /// Send a message to a channel
  void sendMessage(
    String channel,
    WSMessageType type,
    Map<String, dynamic> payload,
  ) {
    _send({
      'type': type.name,
      'channel': channel,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Add listener for all messages
  void addMessageListener(void Function(WSMessage) listener) {
    _messageListeners.add(listener);
  }

  void removeMessageListener(void Function(WSMessage) listener) {
    _messageListeners.remove(listener);
  }

  /// Add listener for specific message type
  void addTypeListener(WSMessageType type, void Function(WSMessage) listener) {
    _typeListeners.putIfAbsent(type, () => []).add(listener);
  }

  void removeTypeListener(
    WSMessageType type,
    void Function(WSMessage) listener,
  ) {
    _typeListeners[type]?.remove(listener);
  }

  /// Get recent messages from buffer
  List<WSMessage> getRecentMessages({
    int limit = 50,
    String? channel,
    WSMessageType? type,
  }) {
    var messages = _messageBuffer.reversed.toList();
    if (channel != null) {
      messages = messages.where((m) => m.channel == channel).toList();
    }
    if (type != null) messages = messages.where((m) => m.type == type).toList();
    return messages.take(limit).toList();
  }

  /// Disconnect from WebSocket
  void disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _connectionState = ConnectionState.disconnected;
    _currentUserId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _messageListeners.clear();
    _typeListeners.clear();
    super.dispose();
  }
}
