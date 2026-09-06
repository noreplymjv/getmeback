import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import '../models/prop_state.dart';
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
    // Subtle dynamic pitch shifting (+-10%) to prevent sound fatigue during intense tapping
    final randomRate = 0.92 + (Random().nextDouble() * 0.16);
    player.setPlaybackRate(randomRate).catchError((_) {});
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

  /// Material-tuned haptic pulse (Flutter intensity tiers; not Core Haptics).
  static Future<void> material(PropMaterial material) async {
    if (!_hapticsOn) return;
    switch (material) {
      case PropMaterial.glass:
        HapticFeedback.lightImpact();
        await Future<void>.delayed(const Duration(milliseconds: 28));
        HapticFeedback.selectionClick();
      case PropMaterial.ceramic:
        HapticFeedback.mediumImpact();
        await Future<void>.delayed(const Duration(milliseconds: 35));
        HapticFeedback.heavyImpact();
      case PropMaterial.wood:
        HapticFeedback.mediumImpact();
      case PropMaterial.metal:
        HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 40));
        HapticFeedback.mediumImpact();
      case PropMaterial.plastic:
        HapticFeedback.selectionClick();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        HapticFeedback.lightImpact();
      case PropMaterial.fabric:
        HapticFeedback.selectionClick();
    }
  }
}
