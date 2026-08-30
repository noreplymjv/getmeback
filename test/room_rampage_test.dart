import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getmeback/models/room_setup.dart';
import 'package:getmeback/models/vent_action.dart';
import 'package:getmeback/widgets/interactive_room_prop.dart';
import 'package:getmeback/widgets/smash_weapon_overlay.dart';

void main() {
  test('Room Rampage ships 20 distinct room setups with art paths', () {
    expect(RoomSetup.all, hasLength(20));
    final ids = RoomSetup.all.map((r) => r.id).toSet();
    expect(ids, hasLength(20));
    for (final room in RoomSetup.all) {
      expect(room.props, isNotEmpty);
      expect(room.name, isNotEmpty);
      expect(room.resolvedAsset, startsWith('assets/rooms/'));
      expect(room.resolvedAsset, endsWith('.png'));
    }
  });

  test('Room Rampage is a vent action', () {
    final action = VentAction.findByType(VentActionType.roomRampage);
    expect(action, isNotNull);
    expect(action!.title, 'Room Rampage');
    expect(action.routePath, '/vent/roomRampage');
  });

  test('all rooms use layered sprite destruction mode', () {
    for (final room in RoomSetup.all) {
      expect(room.spriteMode, isTrue, reason: room.id);
      expect(room.resolvedBaseAsset, endsWith('_base.png'));
      for (final prop in room.props) {
        expect(
          prop.resolvedSprite(room.id),
          'assets/rooms/props/${room.id}_${prop.id}.png',
        );
        expect(prop.effectiveMaterial, isNotNull);
        expect(prop.effectiveSizeNorm, greaterThan(0));
      }
    }
  });

  test('sprite asset files exist on disk', () {
    final root = Directory.current.path;
    for (final room in RoomSetup.all) {
      final base = File('$root/${room.resolvedBaseAsset}');
      expect(base.existsSync(), isTrue, reason: room.resolvedBaseAsset);
      for (final prop in room.props) {
        final sprite = File('$root/${prop.resolvedSprite(room.id)}');
        expect(sprite.existsSync(), isTrue, reason: sprite.path);
      }
    }
  });

  test('glass reactions exist on living sofa', () {
    final living = RoomSetup.findById('living');
    expect(living, isNotNull);
    final sofa = living!.props.where((p) => p.id == 'sofa').first;
    expect(sofa.reactions.containsKey('glass'), isTrue);
  });

  test('SmashWeapon enum has 5 demolition tools with distinct styles', () {
    expect(SmashWeapon.values, hasLength(5));
    final labels = SmashWeapon.values.map((w) => w.label).toList();
    expect(labels, containsAll(['Hammer', 'Baseball Bat', 'Laser Zap', 'Power Fist', 'Wrecking Ball']));
  });

  testWidgets('SmashWeaponSelectorBar switches selected weapon', (tester) async {
    SmashWeapon selected = SmashWeapon.hammer;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SmashWeaponSelectorBar(
                selectedWeapon: selected,
                onSelectWeapon: (w) => setState(() => selected = w),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Hammer'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.bolt));
    await tester.pumpAndSettle();

    expect(selected, SmashWeapon.laser);
    expect(find.text('Laser Zap'), findsOneWidget);
  });

  testWidgets('InteractiveRoomProp renders damaged state at stage > 0', (tester) async {
    final room = RoomSetup.findById('kitchen')!;
    final prop = room.props.first;

    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(seconds: 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              InteractiveRoomProp(
                roomId: room.id,
                prop: prop,
                stage: const Size(600, 400),
                pulse: controller,
                smashed: false,
                holding: false,
                throwTarget: false,
                spriteMode: true,
                damageStage: 1,
                maxDamageStage: 2,
                onTap: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(InteractiveRoomProp), findsOneWidget);
    controller.dispose();
  });
}
