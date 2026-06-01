import 'dart:async';

import 'package:flutter/foundation.dart';

import 'audio_backend.dart';

class AudioService extends ChangeNotifier {
  AudioService._();

  static final AudioService instance = AudioService._();

  final PlatformAudioBackend _backend = PlatformAudioBackend();

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _gameMusicPlaying = false;
  DateTime _lastSfxAt = DateTime.fromMillisecondsSinceEpoch(0);

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get gameMusicPlaying => _gameMusicPlaying;

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    if (_soundEnabled) unawaited(playTap());
    notifyListeners();
  }

  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;
    if (_musicEnabled) {
      await startGameMusic();
    } else {
      await stopGameMusic();
    }
    notifyListeners();
  }

  Future<void> playNotification() {
    return _playSfx(_backend.playNotification);
  }

  Future<void> playTap() {
    return _playSfx(_backend.playTap, throttleMs: 70);
  }

  Future<void> playGameMove() {
    return _playSfx(_backend.playGameMove, throttleMs: 90);
  }

  Future<void> startGameMusic() async {
    if (!_musicEnabled || _gameMusicPlaying) return;
    try {
      await _backend.startGameMusic();
      _gameMusicPlaying = true;
      notifyListeners();
    } catch (_) {
      _gameMusicPlaying = false;
    }
  }

  Future<void> stopGameMusic() async {
    if (!_gameMusicPlaying) return;
    try {
      await _backend.stopGameMusic();
    } finally {
      _gameMusicPlaying = false;
      notifyListeners();
    }
  }

  Future<void> _playSfx(
    Future<void> Function() play, {
    int throttleMs = 0,
  }) async {
    if (!_soundEnabled) return;
    final now = DateTime.now();
    if (throttleMs > 0 &&
        now.difference(_lastSfxAt).inMilliseconds < throttleMs) {
      return;
    }
    _lastSfxAt = now;
    try {
      await play();
    } catch (_) {
      // Browsers can block sound before a user gesture; visuals keep working.
    }
  }
}
