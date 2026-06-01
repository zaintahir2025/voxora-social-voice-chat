import 'dart:async';
import 'dart:js_interop';
import 'dart:math';

import 'package:web/web.dart' as web;

class PlatformAudioBackend {
  web.AudioContext? _context;
  web.GainNode? _musicGain;
  Timer? _musicTimer;
  int _step = 0;

  Future<void> playNotification() async {
    _playTone(880, 0.10, volume: 0.08);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    _playTone(1175, 0.12, volume: 0.07);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    _playTone(1568, 0.16, volume: 0.06);
  }

  Future<void> playTap() async {
    _playTone(520, 0.055, volume: 0.035);
  }

  Future<void> playGameMove() async {
    _playTone(360, 0.06, volume: 0.045);
    await Future<void>.delayed(const Duration(milliseconds: 45));
    _playTone(620, 0.08, volume: 0.035);
  }

  Future<void> startGameMusic() async {
    final context = _ensureContext();
    _musicTimer?.cancel();
    _musicGain = context.createGain()..gain.value = 0.055;
    _musicGain!.connect(context.destination);
    _step = 0;
    _musicTimer = Timer.periodic(const Duration(milliseconds: 520), (_) {
      final roots = [220.0, 246.94, 196.0, 261.63];
      final root = roots[(_step ~/ 4) % roots.length];
      final intervals = [1.0, 1.5, 2.0, 1.25];
      final frequency = root * intervals[_step % intervals.length];
      _playTone(
        frequency,
        0.34,
        volume: 0.035 + 0.015 * sin(_step * 0.7).abs(),
        destination: _musicGain,
      );
      _step++;
    });
  }

  Future<void> stopGameMusic() async {
    _musicTimer?.cancel();
    _musicTimer = null;
    _musicGain?.disconnect();
    _musicGain = null;
  }

  web.AudioContext _ensureContext() {
    final context = _context ??= web.AudioContext();
    if (context.state == 'suspended') {
      unawaited(context.resume().toDart);
    }
    return context;
  }

  void _playTone(
    double frequency,
    double seconds, {
    required double volume,
    web.AudioNode? destination,
  }) {
    try {
      final context = _ensureContext();
      final oscillator = context.createOscillator()
        ..type = 'sine'
        ..frequency.value = frequency;
      final gain = context.createGain()..gain.value = volume;
      oscillator.connect(gain);
      gain.connect(destination ?? context.destination);
      oscillator.start(context.currentTime);
      oscillator.stop(context.currentTime + seconds);
      Timer(Duration(milliseconds: (seconds * 1000).ceil() + 80), () {
        oscillator.disconnect();
        gain.disconnect();
      });
    } catch (_) {}
  }
}
