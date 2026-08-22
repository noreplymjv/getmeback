import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getmeback/models/room_hotspots.dart';
import 'package:getmeback/models/room_setup.dart';

void main() {
  test('every room prop has a tuned hotspot', () {
    for (final room in RoomSetup.all) {
      for (final prop in room.props) {
        final spot = RoomHotspots.forProp(
          roomId: room.id,
          propId: prop.id,
          fallback: prop.align,
        );
        expect(spot.dx, inInclusiveRange(0.0, 1.0));
        expect(spot.dy, inInclusiveRange(0.0, 1.0));
      }
    }
  });

  test('kitchen glass sits on counter zone not center wall', () {
    final spot = RoomHotspots.forProp(
      roomId: 'kitchen',
      propId: 'glass',
      fallback: Alignment.center,
    );
    expect(spot.dx, lessThan(0.35));
    expect(spot.dy, greaterThan(0.45));
  });
}
