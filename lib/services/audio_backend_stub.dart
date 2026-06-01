import 'package:flutter/services.dart';

class PlatformAudioBackend {
  Future<void> playNotification() {
    return SystemSound.play(SystemSoundType.alert);
  }

  Future<void> playTap() {
    return SystemSound.play(SystemSoundType.click);
  }

  Future<void> playGameMove() {
    return SystemSound.play(SystemSoundType.click);
  }

  Future<void> playVictory() async {
    await SystemSound.play(SystemSoundType.alert);
    await Future<void>.delayed(const Duration(milliseconds: 130));
    await SystemSound.play(SystemSoundType.click);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await SystemSound.play(SystemSoundType.alert);
  }

  Future<void> startGameMusic() async {}

  Future<void> stopGameMusic() async {}
}
