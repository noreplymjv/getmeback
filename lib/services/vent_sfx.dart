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

/// Cartoon SFX + haptic helpers with Acoustic 3.0 (pitch shifts, stereo panning, settle audio).
class VentSfx {
  VentSfx._();

  static final VentSfx instance = VentSfx._();

  static const _poolSize = 8;
  final List<AudioPlayer> _pool = [];
  int _next = 0;
  bool _ready = false;
  final _rng = Random();

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
      // Web / desktop fallback
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

  /// Plays sound with Acoustic 3.0: pitch randomization (+-8%), volume control,
  /// optional stereo panning, and optional delayed debris settle tinkle.
  void play(
    Sfx sfx, {
    double pan = 0.0,
    double volume = 1.0,
    bool withDebrisSettle = false,
  }) {
    if (!StorageService.instance.sfxEnabled) return;
    if (!_ready || _pool.isEmpty) {
      init();
      return;
    }
    final player = _pool[_next % _pool.length];
    _next++;

    // Acoustic 3.0: Randomize playback rate (+-8%) to prevent acoustic fatigue
    final randomRate = 0.92 + (_rng.nextDouble() * 0.16);
    player.setPlaybackRate(randomRate).catchError((_) {});
    player.setVolume(volume.clamp(0.0, 1.0)).catchError((_) {});
    
    // Balance panning if supported (-1.0 left to +1.0 right)
    player.setBalance(pan.clamp(-1.0, 1.0)).catchError((_) {});

    player.play(AssetSource('sfx/${sfx.name}.wav')).catchError((_) {});

    if (withDebrisSettle) {
      Future.delayed(const Duration(milliseconds: 140), () {
        if (!StorageService.instance.sfxEnabled) return;
        final settlePlayer = _pool[_next % _pool.length];
        _next++;
        settlePlayer.setVolume(0.35 * volume).catchError((_) {});
        settlePlayer.setPlaybackRate(1.15 + _rng.nextDouble() * 0.2).catchError((_) {});
        settlePlayer.play(AssetSource('sfx/crack.wav')).catchError((_) {});
      });
    }
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
