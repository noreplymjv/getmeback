import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';

/// Microphone-driven scream intensity with tap fallback on web / denied mic.
class ScreamMeterService {
  ScreamMeterService();

  NoiseMeter? _meter;
  StreamSubscription<NoiseReading>? _sub;
  bool _available = false;
  bool get isAvailable => _available;

  final _intensityController = StreamController<double>.broadcast();
  Stream<double> get intensity => _intensityController.stream;

  double _level = 0;

  Future<bool> start() async {
    if (kIsWeb) return false;

    final status = await Permission.microphone.request();
    if (!status.isGranted) return false;

    try {
      _meter = NoiseMeter();
      _available = true;
      _sub = _meter!.noise.listen(
        (reading) {
          // Map ~45–95 dB into 0–1 scream intensity.
          final db = reading.meanDecibel;
          if (db.isNaN || db.isInfinite) return;
          final normalized = ((db - 48) / 42).clamp(0.0, 1.0);
          _level = (_level * 0.55 + normalized * 0.45).clamp(0.0, 1.0);
          _intensityController.add(_level);
        },
        onError: (_) {
          _available = false;
        },
        cancelOnError: true,
      );
      return true;
    } catch (_) {
      _available = false;
      return false;
    }
  }

  void boostFromTap() {
    _level = (_level + 0.14).clamp(0.0, 1.0);
    _intensityController.add(_level);
  }

  void decay([double amount = 0.08]) {
    _level = (_level - amount).clamp(0.0, 1.0);
    _intensityController.add(_level);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _meter = null;
    _available = false;
    _level = 0;
  }

  void dispose() {
    stop();
    _intensityController.close();
  }
}
