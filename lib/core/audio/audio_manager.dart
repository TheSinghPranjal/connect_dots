enum SoundEvent {
  pathStart,
  pathMove,
  pathComplete,
  invalidMove,
  undo,
  restart,
  hint,
  levelComplete,
  starEarned,
  buttonTap,
  challengeFailed,
}

/// Audio abstraction — no-op by default so the game runs without assets.
abstract class AudioManager {
  Future<void> init();
  Future<void> play(SoundEvent event);
  Future<void> setSoundEnabled(bool enabled);
  Future<void> setMusicEnabled(bool enabled);
  Future<void> dispose();
}

class NoOpAudioManager implements AudioManager {
  bool soundEnabled = true;
  bool musicEnabled = true;

  @override
  Future<void> init() async {}

  @override
  Future<void> play(SoundEvent event) async {}

  @override
  Future<void> setSoundEnabled(bool enabled) async {
    soundEnabled = enabled;
  }

  @override
  Future<void> setMusicEnabled(bool enabled) async {
    musicEnabled = enabled;
  }

  @override
  Future<void> dispose() async {}
}
