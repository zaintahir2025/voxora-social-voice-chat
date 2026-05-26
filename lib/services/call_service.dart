import 'dart:async';

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
  final Map<String, List<RTCIceCandidate>> _pendingCandidates = {};
  final Set<String> _processedSignalIds = {};

  RealtimeChannel? _channel;
  MediaStream? _localStream;
  bool _disposed = false;
  bool _started = false;
  bool _joinSignalSent = false;
  bool _syncingSignals = false;
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
      _status = 'Connecting call';
      _notify();
      _subscribeSignals();
    } catch (_) {
      _status = 'Camera or microphone unavailable';
      _started = false;
      await stop(sendLeave: false);
      _notify();
    }
  }

  Future<void> stop({bool sendLeave = true}) async {
    if (sendLeave && _started) await _sendSignal('leave');
    _started = false;
    _joinSignalSent = false;
    _syncingSignals = false;
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
    _pendingCandidates.clear();
    _processedSignalIds.clear();
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

  void _subscribeSignals() {
    final channel = _client.channel('friend-call-$callId-$userId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'call_signals',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'call_id',
        value: callId,
      ),
      callback: (payload) {
        unawaited(_handleSignalRecord(payload.newRecord));
      },
    );
    _channel = channel.subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        unawaited(_syncSignalsAndJoin());
        return;
      }
      if (status == RealtimeSubscribeStatus.channelError) {
        _status = error?.toString() ?? 'Call channel error';
        _notify();
      }
    });
  }

  Future<void> _syncSignalsAndJoin() async {
    if (_syncingSignals) return;
    _syncingSignals = true;
    try {
      final rows = await _client
          .from('call_signals')
          .select()
          .eq('call_id', callId)
          .order('created_at')
          .limit(1000);
      for (final row in rows as List) {
        await _handleSignalRecord(Map<String, dynamic>.from(row as Map));
      }
      if (!_joinSignalSent) {
        _joinSignalSent = true;
        await _sendSignal('join');
      }
      if (_peers.isEmpty) {
        _status = video ? 'Ringing with video' : 'Ringing';
        _notify();
      }
    } catch (_) {
      _status = 'Call setup failed';
      _notify();
    } finally {
      _syncingSignals = false;
    }
  }

  Future<void> _handleSignalRecord(Map<String, dynamic> record) async {
    if (!_started || record.isEmpty) return;
    final signalId = record['id']?.toString();
    if (signalId != null && !_processedSignalIds.add(signalId)) return;

    final peerId = record['sender_id']?.toString();
    if (peerId == null || peerId == userId) return;

    final target = record['recipient_id']?.toString();
    if (target != null && target != userId) return;

    final type = record['signal_type']?.toString();
    final payload = Map<String, dynamic>.from(
      (record['payload'] as Map?) ?? const <String, dynamic>{},
    );
    if (type == null) return;

    try {
      if (type == 'leave') {
        await _removePeer(peerId);
        return;
      }

      final peer = await _peerFor(peerId);
      if (type == 'join') {
        if (_shouldCreateOffer(peerId)) {
          await _createOffer(peerId, peer);
        }
        return;
      }

      if (type == 'offer') {
        final description = _description(payload['description']);
        if (description == null) return;
        await peer.setRemoteDescription(description);
        await _drainPendingCandidates(peerId, peer);
        final answer = await peer.createAnswer(_sdpConstraints());
        await peer.setLocalDescription(answer);
        await _sendSignal(
          'answer',
          to: peerId,
          payload: {'description': answer.toMap()},
        );
        return;
      }

      if (type == 'answer') {
        final description = _description(payload['description']);
        if (description == null) return;
        await peer.setRemoteDescription(description);
        await _drainPendingCandidates(peerId, peer);
        return;
      }

      if (type == 'candidate') {
        final candidate = _candidate(payload['candidate']);
        if (candidate != null) {
          await _addCandidateOrQueue(peerId, peer, candidate);
        }
      }
    } catch (_) {
      _status = 'Call signal failed';
      _notify();
    }
  }

  Future<RTCPeerConnection> _peerFor(String peerId) async {
    final existing = _peers[peerId];
    if (existing != null) return existing;

    final peer = await createPeerConnection({
      'sdpSemantics': 'unified-plan',
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
      unawaited(
        _sendSignal(
          'candidate',
          to: peerId,
          payload: {'candidate': candidate.toMap()},
        ),
      );
    };
    peer.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        _status = 'In call';
        _notify();
      }
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
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _status = 'In call';
        _notify();
        return;
      }
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
        _status = 'Connecting media';
        _notify();
        return;
      }
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        unawaited(_removePeer(peerId));
      }
    };

    _peers[peerId] = peer;
    return peer;
  }

  bool _shouldCreateOffer(String peerId) => userId.compareTo(peerId) < 0;

  Future<void> _createOffer(String peerId, RTCPeerConnection peer) async {
    if (await peer.getLocalDescription() != null) return;
    _status = 'Connecting media';
    _notify();
    final offer = await peer.createOffer(_sdpConstraints());
    await peer.setLocalDescription(offer);
    await _sendSignal(
      'offer',
      to: peerId,
      payload: {'description': offer.toMap()},
    );
  }

  Future<void> _addCandidateOrQueue(
    String peerId,
    RTCPeerConnection peer,
    RTCIceCandidate candidate,
  ) async {
    if (await peer.getRemoteDescription() == null) {
      _pendingCandidates.putIfAbsent(peerId, () => []).add(candidate);
      return;
    }
    await peer.addCandidate(candidate);
  }

  Future<void> _drainPendingCandidates(
    String peerId,
    RTCPeerConnection peer,
  ) async {
    final candidates = _pendingCandidates.remove(peerId) ?? const [];
    for (final candidate in candidates) {
      await peer.addCandidate(candidate);
    }
  }

  Map<String, dynamic> _sdpConstraints() => {
    'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': video},
    'optional': [],
  };

  Future<void> _sendSignal(
    String type, {
    String? to,
    Map<String, dynamic> payload = const <String, dynamic>{},
  }) async {
    await _client.from('call_signals').insert({
      'call_id': callId,
      'sender_id': userId,
      'recipient_id': to,
      'signal_type': type,
      'payload': payload,
    });
  }

  Future<void> _removePeer(String peerId) async {
    final peer = _peers.remove(peerId);
    _pendingCandidates.remove(peerId);
    await peer?.close();
    await peer?.dispose();
    if (_peers.isEmpty) remoteRenderer.srcObject = null;
    _status = _peers.isEmpty ? 'Waiting for friend' : 'In call';
    _notify();
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
    unawaited(_disposeMedia());
    super.dispose();
  }

  Future<void> _disposeMedia() async {
    await stop(sendLeave: true);
    await localRenderer.dispose();
    await remoteRenderer.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
