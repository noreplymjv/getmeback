import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getmeback/services/storage_service.dart';
import 'package:getmeback/widgets/dramatic_fx.dart';
import 'package:getmeback/widgets/prop_shatter_fx.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DramaticFxController', () {
    test('hit-stop freezes tick updates briefly', () {
      final fx = DramaticFxController();
      fx.particles.add(
        FxParticle(
          x: 0,
          y: 0,
          vx: 10,
          vy: 10,
          size: 4,
          color: Colors.red,
          life: 1,
        ),
      );
      fx.triggerHitStop(const Duration(milliseconds: 40));
      expect(fx.isHitStopped, isTrue);
      final lifeBefore = fx.particles.first.life;
      final xBefore = fx.particles.first.x;

      fx.tick(0.01);
      expect(fx.isHitStopped, isTrue);
      expect(fx.particles.first.life, lifeBefore);
      expect(fx.particles.first.x, xBefore);

      fx.tick(0.05);
      expect(fx.isHitStopped, isFalse);
      fx.tick(0.016);
      expect(fx.particles.first.life, lessThan(lifeBefore));
      fx.dispose();
    });

    test('shake uses perlin noise not sine pattern', () {
      final fx = DramaticFxController();
      fx.shakeBurst(amp: 20, duration: 0.4);
      final samples = <Offset>[];
      for (var i = 0; i < 12; i++) {
        fx.tick(0.016);
        samples.add(fx.shake);
      }
      expect(samples.any((o) => o != Offset.zero), isTrue);
      final unique =
          samples.map((o) => '${o.dx.toStringAsFixed(2)},${o.dy.toStringAsFixed(2)}').toSet();
      expect(unique.length, greaterThan(2));
      fx.dispose();
    });
  });

  group('PropShatterController floor', () {
    test('shards bounce on floorY', () {
      final ctrl = PropShatterController()..floorY = 400;
      ctrl.burst(
        at: const Offset(200, 380),
        style: PropShatterStyle.ceramic,
        count: 1,
      );
      final shard = ctrl.shards.first;
      shard.vy = 500;
      shard.y = 395;

      ctrl.tick(0.05);
      expect(shard.y, lessThanOrEqualTo(400));
      expect(shard.vy, lessThan(0));
      ctrl.dispose();
    });
  });

  group('StorageService zen streak', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.instance.loadSettings();
    });

    test('first calm completion starts streak at 1', () async {
      final streak = await StorageService.instance.recordCalmCompletion();
      expect(streak, 1);
      expect(await StorageService.instance.getZenStreak(), 1);
    });

    test('duplicate same-day calm does not increment', () async {
      await StorageService.instance.recordCalmCompletion();
      final again = await StorageService.instance.recordCalmCompletion();
      expect(again, 1);
    });
  });
}
