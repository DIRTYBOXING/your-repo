import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC WEBRTC SERVICE — Real-time Video Streaming
/// Supports: 1-to-1 calls, group rooms, drone streaming, AI overlay
/// ═══════════════════════════════════════════════════════════════════════════

class WebRTCService {
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // ignore: unused_field
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );

  // WebRTC configuration
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      // Add TURN servers for production
    ],
  };

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  String? _currentSessionId;
  StreamSubscription? _signalingSubscription;

  // Callbacks
  Function(MediaStream)? onLocalStream;
  Function(MediaStream)? onRemoteStream;
  Function(RTCPeerConnectionState)? onConnectionState;
  Function(String)? onError;

  /// ─── INITIALIZE LOCAL MEDIA ─────────────────────────────────────────────
  Future<MediaStream> initializeMedia({
    bool video = true,
    bool audio = true,
    bool screenShare = false,
    String? deviceId, // For drone camera selection
  }) async {
    final Map<String, dynamic> constraints = {
      'audio': audio,
      'video': video
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
              'deviceId': ?deviceId,
            }
          : false,
    };

    if (screenShare) {
      _localStream = await navigator.mediaDevices.getDisplayMedia(constraints);
    } else {
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    }

    onLocalStream?.call(_localStream!);
    return _localStream!;
  }

  /// ─── CREATE ROOM (Caller) ───────────────────────────────────────────────
  Future<String> createRoom({
    required String roomType, // 'call', 'group', 'drone', 'training'
    String? roomName,
    List<String>? allowedUsers,
  }) async {
    // Create peer connection
    _peerConnection = await createPeerConnection(_iceServers);
    _registerPeerConnectionListeners();

    // Add local tracks
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }

    // Create room document
    final roomRef = _db.collection('webrtc_rooms').doc();
    _currentSessionId = roomRef.id;

    // Create offer
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // Store room info
    await roomRef.set({
      'type': roomType,
      'name': roomName ?? 'DFC Room',
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': allowedUsers?.first ?? 'anonymous',
      'allowedUsers': allowedUsers ?? [],
      'status': 'waiting',
      'offer': {'type': offer.type, 'sdp': offer.sdp},
    });

    // Listen for answer
    roomRef.snapshots().listen((snapshot) async {
      final data = snapshot.data();
      if (data == null) return;

      if (data['answer'] != null && _peerConnection != null) {
        final answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );
        await _peerConnection!.setRemoteDescription(answer);
      }
    });

    // Listen for ICE candidates
    _listenForCandidates(roomRef.id, 'calleeCandidates');

    // Store caller candidates
    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        roomRef.collection('callerCandidates').add(candidate.toMap());
      }
    };

    return roomRef.id;
  }

  /// ─── JOIN ROOM (Callee) ─────────────────────────────────────────────────
  Future<void> joinRoom(String roomId) async {
    final roomRef = _db.collection('webrtc_rooms').doc(roomId);
    final roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists) {
      onError?.call('Room not found');
      return;
    }

    _currentSessionId = roomId;
    final data = roomSnapshot.data()!;

    // Create peer connection
    _peerConnection = await createPeerConnection(_iceServers);
    _registerPeerConnectionListeners();

    // Add local tracks
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }

    // Set remote description (offer)
    final offer = RTCSessionDescription(
      data['offer']['sdp'],
      data['offer']['type'],
    );
    await _peerConnection!.setRemoteDescription(offer);

    // Create answer
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    // Store answer
    await roomRef.update({
      'answer': {'type': answer.type, 'sdp': answer.sdp},
      'status': 'connected',
    });

    // Listen for caller candidates
    _listenForCandidates(roomId, 'callerCandidates');

    // Store callee candidates
    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        roomRef.collection('calleeCandidates').add(candidate.toMap());
      }
    };
  }

  /// ─── DRONE STREAMING MODE ───────────────────────────────────────────────
  Future<String> startDroneStream({
    required String droneId,
    required String sessionName,
    String? gymId,
    String? fighterId,
  }) async {
    // Initialize with drone-specific settings
    await initializeMedia();

    final roomId = await createRoom(
      roomType: 'drone',
      roomName: 'Drone: $sessionName',
      allowedUsers: [?fighterId],
    );

    // Store drone session metadata
    await _db.collection('drone_sessions').doc(roomId).set({
      'droneId': droneId,
      'sessionName': sessionName,
      'gymId': gymId,
      'fighterId': fighterId,
      'roomId': roomId,
      'startedAt': FieldValue.serverTimestamp(),
      'status': 'streaming',
      'aiOverlayEnabled': true,
    });

    return roomId;
  }

  /// ─── TRAINING SESSION WITH AI OVERLAY ───────────────────────────────────
  Future<String> startTrainingSession({
    required String fighterId,
    required String sessionType, // 'sparring', 'bagwork', 'padwork', 'drilling'
    String? coachId,
    bool enableAIAnalysis = true,
  }) async {
    await initializeMedia();

    final roomId = await createRoom(
      roomType: 'training',
      roomName: 'Training: $sessionType',
      allowedUsers: [fighterId, ?coachId],
    );

    // Create training session doc
    await _db.collection('training_sessions').doc(roomId).set({
      'fighterId': fighterId,
      'coachId': coachId,
      'sessionType': sessionType,
      'roomId': roomId,
      'startedAt': FieldValue.serverTimestamp(),
      'status': 'active',
      'aiAnalysis': {
        'enabled': enableAIAnalysis,
        'frames_analyzed': 0,
        'insights': [],
      },
    });

    // If AI analysis enabled, start frame capture
    if (enableAIAnalysis) {
      _startAIFrameCapture(roomId, fighterId);
    }

    return roomId;
  }

  /// ─── AI FRAME CAPTURE FOR ANALYSIS ──────────────────────────────────────
  void _startAIFrameCapture(String sessionId, String fighterId) {
    // Capture frame every 2 seconds for AI analysis
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_localStream == null || _currentSessionId != sessionId) {
        timer.cancel();
        return;
      }

      try {
        // Get video track
        final videoTrack = _localStream!.getVideoTracks().firstOrNull;
        if (videoTrack == null) return;

        // In production, capture frame and send to ATLAS backend
        // For now, log the event
        await _db.collection('training_sessions').doc(sessionId).update({
          'aiAnalysis.frames_analyzed': FieldValue.increment(1),
          'aiAnalysis.lastFrameAt': FieldValue.serverTimestamp(),
        });

        // Call ATLAS for analysis (placeholder)
        // final analysis = await _analyzeFrame(frameData);
        // Store insight if significant
      } catch (e) {
        debugPrint('Frame capture error: $e');
      }
    });
  }

  /// ─── GROUP CALL / MULTI-PEER ────────────────────────────────────────────
  Future<String> createGroupRoom({
    required String roomName,
    required List<String> participants,
    int maxParticipants = 6,
  }) async {
    await initializeMedia();

    final roomRef = _db.collection('webrtc_group_rooms').doc();

    await roomRef.set({
      'name': roomName,
      'createdAt': FieldValue.serverTimestamp(),
      'participants': participants,
      'maxParticipants': maxParticipants,
      'activeConnections': [],
      'status': 'open',
    });

    return roomRef.id;
  }

  /// ─── LISTEN FOR ICE CANDIDATES ──────────────────────────────────────────
  void _listenForCandidates(String roomId, String collection) {
    _signalingSubscription = _db
        .collection('webrtc_rooms')
        .doc(roomId)
        .collection(collection)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data()!;
              final candidate = RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMLineIndex'],
              );
              _peerConnection?.addCandidate(candidate);
            }
          }
        });
  }

  /// ─── REGISTER PEER CONNECTION LISTENERS ─────────────────────────────────
  void _registerPeerConnectionListeners() {
    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        onRemoteStream?.call(_remoteStream!);
      }
    };

    _peerConnection!.onConnectionState = (state) {
      onConnectionState?.call(state);

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        onError?.call('Connection failed');
      }
    };

    _peerConnection!.onIceConnectionState = (state) {
      debugPrint('ICE state: $state');
    };
  }

  /// ─── MUTE/UNMUTE ────────────────────────────────────────────────────────
  void toggleAudio(bool enabled) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = enabled;
    });
  }

  void toggleVideo(bool enabled) {
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = enabled;
    });
  }

  /// ─── SWITCH CAMERA ──────────────────────────────────────────────────────
  Future<void> switchCamera() async {
    if (_localStream == null) return;

    final videoTrack = _localStream!.getVideoTracks().firstOrNull;
    if (videoTrack != null) {
      await Helper.switchCamera(videoTrack);
    }
  }

  /// ─── END SESSION ────────────────────────────────────────────────────────
  Future<void> endSession() async {
    // Close peer connection
    await _peerConnection?.close();
    _peerConnection = null;

    // Stop local stream
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream = null;
    _remoteStream = null;

    // Cancel signaling subscription
    await _signalingSubscription?.cancel();

    // Update room status
    if (_currentSessionId != null) {
      await _db.collection('webrtc_rooms').doc(_currentSessionId).update({
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
      });
    }

    _currentSessionId = null;
  }

  /// ─── GETTERS ────────────────────────────────────────────────────────────
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  String? get currentSessionId => _currentSessionId;
  bool get isConnected =>
      _peerConnection?.connectionState ==
      RTCPeerConnectionState.RTCPeerConnectionStateConnected;
}
