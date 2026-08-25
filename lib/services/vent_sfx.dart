import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'storage_service.dart';

enum Sfx {
  hit,
  smash,
  pop,
  zap,
  whoosh,
  splash,
  fire,
  shred,
  confetti,
  boom,
  swirl,
  crack,
  ko,
  suck,
}

/// Cartoon SFX + haptic helpers. Safe on web (haptics no-op).
class VentSfx {
  VentSfx._();

  static final VentSfx instance = VentSfx._();

  static const _poolSize = 6;
  final List<AudioPlayer> _pool = [];
  int _next = 0;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
    } catch (_) {
      // Web / desktop may not support the same audio context.
    }
    for (var i = 0; i < _poolSize; i++) {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      _pool.add(player);
    }
    _ready = true;
  }

  /// Unlock audio on web after a user gesture.
  Future<void> unlock() async {
    if (!_ready) await init();
    if (_pool.isEmpty) return;
    try {
      await _pool.first.setVolume(0);
      await _pool.first.play(AssetSource('sfx/hit.wav'));
      await _pool.first.stop();
      await _pool.first.setVolume(1);
    } catch (_) {}
  }

  void play(Sfx sfx) {
    if (!StorageService.instance.sfxEnabled) return;
    if (!_ready || _pool.isEmpty) {
      init();
      return;
    }
    // Round-robin pool — avoid stop()->play() on the same player every time.
    final player = _pool[_next % _pool.length];
    _next++;
    player.play(AssetSource('sfx/${sfx.name}.wav')).catchError((_) {});
  }

  static bool get _hapticsOn => StorageService.instance.hapticsEnabled;

  static void light() {
    if (!_hapticsOn) return;
    HapticFeedback.selectionClick();
  }

  static void medium() {
    if (!_hapticsOn) return;
    HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (!_hapticsOn) return;
    HapticFeedback.heavyImpact();
  }

  static Future<void> rumble() async {
    if (!_hapticsOn) return;
    HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    HapticFeedback.heavyImpact();
  }
}
