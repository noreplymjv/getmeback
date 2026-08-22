import 'package:flutter_test/flutter_test.dart';
import 'package:getmeback/models/room_setup.dart';
import 'package:getmeback/models/vent_action.dart';

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

  test('glass reactions exist on living sofa', () {
    final living = RoomSetup.findById('living');
    expect(living, isNotNull);
    final sofa = living!.props.where((p) => p.id == 'sofa').first;
    expect(sofa.reactions.containsKey('glass'), isTrue);
  });
}
