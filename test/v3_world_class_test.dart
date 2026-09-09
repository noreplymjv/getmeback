import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:getmeback/models/prop_state.dart';
import 'package:getmeback/models/vent_target.dart';
import 'package:getmeback/screens/kintsugi_screen.dart';
import 'package:getmeback/services/sensor_service.dart';
import 'package:getmeback/services/storage_service.dart';
import 'package:getmeback/services/vent_sfx.dart';
import 'package:getmeback/widgets/dramatic_fx.dart';
import 'package:getmeback/widgets/prop_voronoi_shatter.dart';
import 'package:getmeback/widgets/tactile_paper_shredder.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('V3 Phase 1: Mouse Pointer Parallax & Audio Engine 3.0', () {
    test('SensorService updates parallax from pointer offset', () {
      final sensor = SensorService.instance;
      sensor.updatePointerParallax(const Offset(0.5, -0.5), intensity: 14.0);
      expect(sensor.parallax.dx, equals(7.0));
      expect(sensor.parallax.dy, closeTo(-4.9, 0.01));
    });

    test('VentSfx supports panning, volume, and settle audio without crashing', () {
      StorageService.instance.setSfxEnabled(false);
      // Calling play with V3 parameters should execute cleanly
      VentSfx.instance.play(
        Sfx.crack,
        pan: -0.75,
        volume: 0.8,
        withDebrisSettle: true,
      );
    });
  });

  group('V3 Phase 2: DramaticFx Optical Shockwave & Bullet-Time', () {
    test('DramaticFxController triggers shockwave and chromatic aberration', () {
      final fx = DramaticFxController();
      expect(fx.shockwaves.isEmpty, isTrue);
      expect(fx.chromaticAberration, equals(0.0));

      fx.triggerShockwave(
        at: const Offset(100, 100),
        color: Colors.cyan,
        maxRadius: 300,
        chromatic: 0.85,
      );

      expect(fx.shockwaves.length, equals(1));
      expect(fx.shockwaves.first.x, equals(100));
      expect(fx.chromaticAberration, equals(0.85));

      // Tick should decay chromatic aberration and expand shockwave
      fx.tick(0.1);
      expect(fx.chromaticAberration, lessThan(0.85));
      expect(fx.shockwaves.first.radius, greaterThan(16.0));
    });

    test('DramaticFxController executes Bullet-Time slow motion', () {
      final fx = DramaticFxController();
      expect(fx.isBulletTime, isFalse);

      fx.triggerBulletTime(duration: const Duration(milliseconds: 500), factor: 0.25);
      expect(fx.isBulletTime, isTrue);
      expect(fx.bulletTimeFactor, equals(0.25));

      // Tick past duration ends bullet time
      fx.tick(0.6);
      expect(fx.isBulletTime, isFalse);
    });
  });

  group('V3 Phase 3: Procedural Voronoi Texture Shatter', () {
    test('VoronoiShatterEngine generates polygonal shards with specular bevels', () {
      final shards = VoronoiShatterEngine.fracture(
        stageCenter: const Offset(200, 300),
        propSize: const Size(80, 80),
        localImpact: const Offset(40, 40),
        color: const Color(0xFF64B5F6),
        material: PropMaterial.glass,
        cellCount: 16,
      );

      expect(shards.length, equals(16));
      for (final s in shards) {
        expect(s.polygon.length, greaterThanOrEqualTo(4));
        expect(s.material, equals(PropMaterial.glass));
        expect(s.life, greaterThan(0));
      }

      // Physics tick simulation with floor bounce
      final s0 = shards.first;
      final initialY = s0.y;
      s0.tick(0.05, floorY: 500);
      expect(s0.y, isNot(equals(initialY)));
    });
  });

  group('V3 Phase 4: Zen 3.0 Kintsugi Restoration & Paper Shredder', () {
    testWidgets('KintsugiScreen renders and displays restoration canvas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: KintsugiScreen(target: VentTarget.roomGuest),
        ),
      );

      expect(find.text('Kintsugi Restoration'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('0% Repaired'), findsOneWidget);
    });

    testWidgets('TactilePaperShredderDialog renders notepad and feed button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TactilePaperShredderDialog()),
        ),
      );

      expect(find.text('Rage Shredder'), findsOneWidget);
      expect(find.text('FEED TO SHREDDER'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
