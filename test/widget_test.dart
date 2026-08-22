import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getmeback/main.dart';
import 'package:getmeback/models/vent_target.dart';
import 'package:getmeback/services/storage_service.dart';
import 'package:getmeback/utils/target_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.loadSettings();
  });

  testWidgets('Home shows Characters, Rooms, and Watch Demo', (tester) async {
    await tester.pumpWidget(const GetMeBackApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('GetMeBack'), findsWidgets);
    expect(find.text('Characters'), findsOneWidget);
    expect(find.text('Rooms & Scenes'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Watch Demo'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Watch Demo'), findsOneWidget);
  });

  test('deleteTarget removes saved target', () async {
    final target = VentTarget(
      id: 'del-1',
      name: 'Temp Boss',
      presetId: 'angry_boss',
      createdAt: DateTime(2026),
    );
    await StorageService.instance.saveTarget(target);
    var list = await StorageService.instance.loadTargets();
    expect(list.any((t) => t.id == 'del-1'), isTrue);

    await StorageService.instance.deleteTarget('del-1');
    list = await StorageService.instance.loadTargets();
    expect(list.any((t) => t.id == 'del-1'), isFalse);
  });

  test('TargetImage.forgetPath clears blob memory cache', () {
    TargetImage.cacheBlob('x', Uint8List.fromList([1, 2, 3]));
    TargetImage.forgetPath('idb:x');
    expect(TargetImage.webBlobId('idb:x'), 'x');
  });
}
