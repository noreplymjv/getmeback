import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getmeback/models/vent_target.dart';
import 'package:getmeback/theme/app_theme.dart';
import 'package:getmeback/vent_scenes/anvil_drop_scene.dart';
import 'package:getmeback/vent_scenes/balloon_pop_scene.dart';
import 'package:getmeback/vent_scenes/black_hole_scene.dart';
import 'package:getmeback/vent_scenes/blender_scene.dart';
import 'package:getmeback/vent_scenes/boxing_ko_scene.dart';
import 'package:getmeback/vent_scenes/catapult_scene.dart';
import 'package:getmeback/vent_scenes/dart_throw_scene.dart';
import 'package:getmeback/vent_scenes/fire_poof_scene.dart';
import 'package:getmeback/vent_scenes/ice_shatter_scene.dart';
import 'package:getmeback/vent_scenes/lightning_scene.dart';
import 'package:getmeback/vent_scenes/paint_bomb_scene.dart';
import 'package:getmeback/vent_scenes/pinata_scene.dart';
import 'package:getmeback/vent_scenes/punch_bag_scene.dart';
import 'package:getmeback/vent_scenes/shredder_scene.dart';
import 'package:getmeback/vent_scenes/sink_scene.dart';
import 'package:getmeback/vent_scenes/sledgehammer_scene.dart';
import 'package:getmeback/vent_scenes/smash_scene.dart';
import 'package:getmeback/vent_scenes/stomp_scene.dart';
import 'package:getmeback/vent_scenes/tornado_scene.dart';
import 'package:getmeback/vent_scenes/trash_can_scene.dart';
import 'package:getmeback/vent_scenes/volcano_scene.dart';
import 'package:getmeback/widgets/target_avatar.dart';

final _target = VentTarget(
  id: 't1',
  name: 'Test Target',
  presetId: 'angry_boss',
  createdAt: DateTime(2026),
);

final _scenes = <String, Widget>{
  'anvilDrop': AnvilDropScene(target: _target),
  'balloonPop': BalloonPopScene(target: _target),
  'blackHole': BlackHoleScene(target: _target),
  'blender': BlenderScene(target: _target),
  'boxingKo': BoxingKoScene(target: _target),
  'catapult': CatapultScene(target: _target),
  'dartThrow': DartThrowScene(target: _target),
  'firePoof': FirePoofScene(target: _target),
  'iceShatter': IceShatterScene(target: _target),
  'lightning': LightningScene(target: _target),
  'paintBomb': PaintBombScene(target: _target),
  'pinata': PinataScene(target: _target),
  'punchBag': PunchBagScene(target: _target),
  'shredder': ShredderScene(target: _target),
  'sink': SinkScene(target: _target),
  'sledgehammer': SledgehammerScene(target: _target),
  'smash': SmashScene(target: _target),
  'stomp': StompScene(target: _target),
  'tornado': TornadoScene(target: _target),
  'trashCan': TrashCanScene(target: _target),
  'volcano': VolcanoScene(target: _target),
};

const _sizes = <String, Size>{
  'small phone': Size(320, 568),
  'phone': Size(390, 844),
  'tablet': Size(834, 1112),
};

void main() {
  for (final entry in _sizes.entries) {
    group('${entry.key} (${entry.value.width}x${entry.value.height})', () {
      for (final scene in _scenes.entries) {
        testWidgets('${scene.key} art fits the stage', (tester) async {
          tester.view.physicalSize = entry.value;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            MaterialApp(theme: AppTheme.dark, home: scene.value),
          );
          await tester.pump(const Duration(milliseconds: 300));

          final avatars = tester.widgetList<TargetAvatar>(
            find.byType(TargetAvatar),
          );
          final shortestSide = entry.value.shortestSide;
          for (final avatar in avatars) {
            expect(
              avatar.size,
              lessThanOrEqualTo(shortestSide * 0.45),
              reason: '${scene.key}: avatar is oversized for the stage',
            );
          }
        });
      }
    });
  }
}
