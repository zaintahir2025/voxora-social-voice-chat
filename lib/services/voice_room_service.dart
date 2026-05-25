import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VoiceRoomController extends ChangeNotifier {
  VoiceRoomController({required this.roomId, required this.userId});

  final String roomId;
  final String userId;

  final _client = Supabase.instance.client;
  final Map<String, RTCPeerConnection> _peers = {};
  final Map<String, MediaStream> _remoteStreams = {};

  RealtimeChannel? _channel;
  MediaStream? _localStream;
  bool _disposed = false;

  bool _enabled = false;
  bool get enabled => _enabled;

  bool _muted = false;
  bool get muted => _muted;

  String _status = 'Voice idle';
  String get status => _status;

  int get remoteCount => _remoteStreams.length;

  Future<void> start() async {
    if (_enabled) {
      return;
    }

    _enabled = true;
    _status = 'Requesting microphone';
    _notify();

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });

      _channel = _client.channel(
        'voice-room-$roomId',
        opts: const RealtimeChannelConfig(self: false, private: true),
      );

      _channel!
          .onBroadcast(
            event: 'signal',
            callback: (payload) {
              _handleSignal(payload);
            },
          )
          .subscribe((status, error) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              _status = 'Connected to room audio';
              _notify();
              _sendSignal({'type': 'join'});
            }
            if (status == RealtimeSubscribeStatus.channelError) {
              _status = error?.toString() ?? 'Voice channel error';
              _notify();
            }
          });
    } catch (error) {
      _enabled = false;
      _status = 'Microphone unavailable';
      await _cleanUpPeers();
      _localStream?.getTracks().forEach((track) => track.stop());
      _localStream = null;
      _notify();
    }
  }

  Future<void> stop() async {
    if (!_enabled && _localStream == null) {
      return;
    }

    await _sendSignal({'type': 'leave'});
    _enabled = false;
    _muted = false;
    _status = 'Voice idle';
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream = null;
    await _cleanUpPeers();
    if (_channel != null) {
      await _channel!.unsubscribe();
      _channel = null;
    }
    _notify();
  }

  void toggleMute() {
    if (_localStream == null) {
      return;
    }
    _muted = !_muted;
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = !_muted;
    }
    _status = _muted ? 'Microphone muted' : 'Connected to room audio';
    _notify();
  }

  Future<void> _handleSignal(Map<String, dynamic> payload) async {
    if (!_enabled || payload['from'] == userId) {
      return;
    }
    final target = payload['to'];
    if (target != null && target != userId) {
      return;
    }

    final peerId = payload['from']?.toString();
    final type = payload['type']?.toString();
    if (peerId == null || type == null) {
      return;
    }

    if (type == 'leave') {
      await _removePeer(peerId);
      return;
    }

    final peer = await _peerFor(peerId);
    if (type == 'join') {
      final offer = await peer.createOffer();
      await peer.setLocalDescription(offer);
      await _sendSignal({
        'type': 'offer',
        'to': peerId,
        'description': offer.toMap(),
      });
    }

    if (type == 'offer') {
      final description = _readDescription(payload['description']);
      if (description == null) return;
      await peer.setRemoteDescription(description);
      final answer = await peer.createAnswer();
      await peer.setLocalDescription(answer);
      await _sendSignal({
        'type': 'answer',
        'to': peerId,
        'description': answer.toMap(),
      });
    }

    if (type == 'answer') {
      final description = _readDescription(payload['description']);
      if (description == null) return;
      await peer.setRemoteDescription(description);
    }

    if (type == 'candidate') {
      final candidate = _readCandidate(payload['candidate']);
      if (candidate == null) return;
      await peer.addCandidate(candidate);
    }
  }

  Future<RTCPeerConnection> _peerFor(String peerId) async {
    final existing = _peers[peerId];
    if (existing != null) {
      return existing;
    }

    final peer = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:global.stun.twilio.com:3478'},
      ],
    });

    final stream = _localStream;
    if (stream != null) {
      await peer.addStream(stream);
    }

    peer.onIceCandidate = (candidate) {
      _sendSignal({
        'type': 'candidate',
        'to': peerId,
        'candidate': candidate.toMap(),
      });
    };

    peer.onAddStream = (stream) {
      _remoteStreams[peerId] = stream;
      _status =
          'Connected to $remoteCount remote speaker${remoteCount == 1 ? '' : 's'}';
      _notify();
    };

    peer.onTrack = (event) {
      final streams = event.streams;
      if (streams.isNotEmpty) {
        _remoteStreams[peerId] = streams.first;
        _status =
            'Connected to $remoteCount remote speaker${remoteCount == 1 ? '' : 's'}';
        _notify();
      }
    };

    peer.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _removePeer(peerId);
      }
    };

    _peers[peerId] = peer;
    return peer;
  }

  Future<void> _sendSignal(Map<String, dynamic> payload) async {
    final channel = _channel;
    if (channel == null) {
      return;
    }
    await channel.sendBroadcastMessage(
      event: 'signal',
      payload: {...payload, 'from': userId},
    );
  }

  RTCSessionDescription? _readDescription(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    return RTCSessionDescription(
      raw['sdp']?.toString(),
      raw['type']?.toString(),
    );
  }

  RTCIceCandidate? _readCandidate(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    return RTCIceCandidate(
      raw['candidate']?.toString(),
      raw['sdpMid']?.toString(),
      raw['sdpMLineIndex'] is int ? raw['sdpMLineIndex'] as int : null,
    );
  }

  Future<void> _removePeer(String peerId) async {
    _remoteStreams.remove(peerId);
    final peer = _peers.remove(peerId);
    await peer?.close();
    await peer?.dispose();
    if (_enabled) {
      _status = remoteCount == 0
          ? 'Connected to room audio'
          : 'Connected to $remoteCount remote speaker${remoteCount == 1 ? '' : 's'}';
    }
    _notify();
  }

  Future<void> _cleanUpPeers() async {
    for (final peer in _peers.values) {
      await peer.close();
      await peer.dispose();
    }
    _peers.clear();
    _remoteStreams.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    _enabled = false;
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream = null;
    for (final peer in _peers.values) {
      peer.close();
      peer.dispose();
    }
    _peers.clear();
    _remoteStreams.clear();
    _channel?.unsubscribe();
    _channel = null;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
