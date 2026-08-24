import 'package:flutter_test/flutter_test.dart';
import 'package:getmeback/models/room_setup.dart';
import 'package:getmeback/models/vent_action.dart';

void main() {
  test('V1A ships 20 rooms with sprite mode', () {
    expect(RoomSetup.all, hasLength(20));
    for (final room in RoomSetup.all) {
      expect(room.spriteMode, isTrue, reason: room.id);
      expect(room.props, isNotEmpty);
    }
  });

  test('V1A includes Room Rampage vent action', () {
    final action = VentAction.findByType(VentActionType.roomRampage);
    expect(action, isNotNull);
    expect(action!.title, 'Room Rampage');
  });

  test('V1A kitchen is the sprite pilot with materials', () {
    final kitchen = RoomSetup.findById('kitchen');
    expect(kitchen, isNotNull);
    expect(kitchen!.props.length, 6);
    expect(kitchen.resolvedBaseAsset, contains('kitchen_base'));
  });
}
