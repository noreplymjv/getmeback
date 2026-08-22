import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getmeback/models/prop_state.dart';
import 'package:getmeback/models/room_setup.dart';
import 'package:getmeback/widgets/prop_destruction_scars.dart';

void main() {
  testWidgets('destruction scars layer paints without error', (tester) async {
    final kitchen = RoomSetup.findById('kitchen')!;
    final glass = kitchen.props.firstWhere((p) => p.id == 'glass');
    const stage = Size(400, 300);
    final scar = DestructionScar.fromProp(
      prop: glass,
      roomId: 'kitchen',
      stage: stage,
      center: const Offset(80, 160),
      style: PropSmashStyle.shatter,
    );

    expect(scar.material, PropMaterial.glass);
    expect(scar.extent.width, greaterThan(0));
  });
}
