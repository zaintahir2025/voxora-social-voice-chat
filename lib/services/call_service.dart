import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendCallController extends ChangeNotifier {
  FriendCallController({
    required this.callId,
    required this.userId,
    required this.video,
  });

  final String callId;
  final String userId;
  final bool video;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  final SupabaseClient _client = Supabase.instance.client;
  final Map<String, RTCPeerConnection> _peers = {};

  RealtimeChannel? _channel;
  MediaStream? _localStream;
  bool _disposed = false;
  bool _started = false;
  bool _muted = false;
  bool _cameraOff = false;
  String _status = 'Starting call';

  bool get started => _started;
  bool get muted => _muted;
  bool get cameraOff => _cameraOff;
  String get status => _status;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _status = 'Requesting media permission';
    _notify();

    await localRenderer.initialize();
    await remoteRenderer.initialize();

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': video,
      });
      localRenderer.srcObject = _localStream;

      _channel = _client.channel(
        'friend-call-$callId',
        opts: const RealtimeChannelConfig(self: false, private: false),
      );

      _channel!.onBroadcast(event: 'signal', callback: _handleSignal).subscribe(
        (status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            _status = 'Connected';
            _notify();
            _send({'type': 'join'});
          }
          if (status == RealtimeSubscribeStatus.channelError) {
            _status = error?.toString() ?? 'Call channel error';
            _notify();
          }
        },
      );
    } catch (error) {
      _status = 'Media permission unavailable';
      _started = false;
      await stop(sendLeave: false);
      _notify();
    }
  }

  Future<void> stop({bool sendLeave = true}) async {
    if (sendLeave) await _send({'type': 'leave'});
    _started = false;
    _muted = false;
    _cameraOff = false;
    _status = 'Call ended';
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream = null;
    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
    for (final peer in _peers.values) {
      await peer.close();
      await peer.dispose();
    }
    _peers.clear();
    await _channel?.unsubscribe();
    _channel = null;
    _notify();
  }

  void toggleMute() {
    final stream = _localStream;
    if (stream == null) return;
    _muted = !_muted;
    for (final track in stream.getAudioTracks()) {
      track.enabled = !_muted;
    }
    _notify();
  }

  void toggleCamera() {
    final stream = _localStream;
    if (stream == null) return;
    _cameraOff = !_cameraOff;
    for (final track in stream.getVideoTracks()) {
      track.enabled = !_cameraOff;
    }
    _notify();
  }

  Future<void> _handleSignal(Map<String, dynamic> payload) async {
    if (!_started || payload['from'] == userId) return;
    final target = payload['to'];
    if (target != null && target != userId) return;

    final peerId = payload['from']?.toString();
    final type = payload['type']?.toString();
    if (peerId == null || type == null) return;

    if (type == 'leave') {
      await _removePeer(peerId);
      return;
    }

    final peer = await _peerFor(peerId);
    if (type == 'join') {
      final offer = await peer.createOffer();
      await peer.setLocalDescription(offer);
      await _send({
        'type': 'offer',
        'to': peerId,
        'description': offer.toMap(),
      });
      return;
    }

    if (type == 'offer') {
      final description = _description(payload['description']);
      if (description == null) return;
      await peer.setRemoteDescription(description);
      final answer = await peer.createAnswer();
      await peer.setLocalDescription(answer);
      await _send({
        'type': 'answer',
        'to': peerId,
        'description': answer.toMap(),
      });
      return;
    }

    if (type == 'answer') {
      final description = _description(payload['description']);
      if (description != null) await peer.setRemoteDescription(description);
      return;
    }

    if (type == 'candidate') {
      final candidate = _candidate(payload['candidate']);
      if (candidate != null) await peer.addCandidate(candidate);
    }
  }

  Future<RTCPeerConnection> _peerFor(String peerId) async {
    final existing = _peers[peerId];
    if (existing != null) return existing;

    final peer = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:global.stun.twilio.com:3478'},
      ],
    });

    final stream = _localStream;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await peer.addTrack(track, stream);
      }
    }

    peer.onIceCandidate = (candidate) {
      _send({
        'type': 'candidate',
        'to': peerId,
        'candidate': candidate.toMap(),
      });
    };
    peer.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams.first;
        _status = 'In call';
        _notify();
      }
    };
    peer.onAddStream = (stream) {
      remoteRenderer.srcObject = stream;
      _status = 'In call';
      _notify();
    };
    peer.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _removePeer(peerId);
      }
    };

    _peers[peerId] = peer;
    return peer;
  }

  Future<void> _removePeer(String peerId) async {
    final peer = _peers.remove(peerId);
    await peer?.close();
    await peer?.dispose();
    if (_peers.isEmpty) remoteRenderer.srcObject = null;
    _status = _peers.isEmpty ? 'Waiting for friend' : 'In call';
    _notify();
  }

  Future<void> _send(Map<String, dynamic> payload) async {
    final channel = _channel;
    if (channel == null) return;
    await channel.sendBroadcastMessage(
      event: 'signal',
      payload: {...payload, 'from': userId},
    );
  }

  RTCSessionDescription? _description(dynamic raw) {
    if (raw is! Map) return null;
    return RTCSessionDescription(
      raw['sdp']?.toString(),
      raw['type']?.toString(),
    );
  }

  RTCIceCandidate? _candidate(dynamic raw) {
    if (raw is! Map) return null;
    return RTCIceCandidate(
      raw['candidate']?.toString(),
      raw['sdpMid']?.toString(),
      raw['sdpMLineIndex'] is int ? raw['sdpMLineIndex'] as int : null,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    stop(sendLeave: true);
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
