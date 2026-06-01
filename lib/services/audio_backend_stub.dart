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

  Future<void> startGameMusic() async {}

  Future<void> stopGameMusic() async {}
}
