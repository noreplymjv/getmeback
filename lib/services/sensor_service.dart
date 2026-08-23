import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Gyro parallax + shake detection with graceful fallback when sensors unavailable.
class SensorService {
  SensorService._();
  static final SensorService instance = SensorService._();

  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  Offset parallax = Offset.zero;
  final _shakeController = StreamController<void>.broadcast();

  Stream<void> get onShake => _shakeController.stream;

  bool _listening = false;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);
  static const _shakeCooldown = Duration(milliseconds: 900);

  void start() {
    if (_listening || kIsWeb) return;
    _listening = true;

    _gyroSub = gyroscopeEventStream().listen(
      (e) {
        parallax = Offset(
          (e.y * 8).clamp(-14.0, 14.0),
          (e.x * 6).clamp(-10.0, 10.0),
        );
      },
      onError: (_) {},
      cancelOnError: true,
    );

    _accelSub = accelerometerEventStream().listen(
      (e) {
        final mag = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
        if (mag > 22) {
          final now = DateTime.now();
          if (now.difference(_lastShake) > _shakeCooldown) {
            _lastShake = now;
            _shakeController.add(null);
          }
        }
      },
      onError: (_) {},
      cancelOnError: true,
    );
  }

  void stop() {
    _listening = false;
    _gyroSub?.cancel();
    _accelSub?.cancel();
    _gyroSub = null;
    _accelSub = null;
    parallax = Offset.zero;
  }

  void dispose() {
    stop();
    _shakeController.close();
  }
}
