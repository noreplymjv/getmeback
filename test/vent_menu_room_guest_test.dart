import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getmeback/models/vent_target.dart';
import 'package:getmeback/screens/vent_menu_screen.dart';
import 'package:getmeback/services/storage_service.dart';
import 'package:getmeback/theme/app_theme.dart';
import 'package:getmeback/vent_scenes/smash_scene.dart';
import 'package:getmeback/widgets/vent_action_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'targets_migrated_to_secure_v1': true});
    FlutterSecureStorage.setMockInitialValues({});
    await StorageService.instance.loadSettings();
  });

  testWidgets('vent-menu/room_guest loads and displays actions without hanging',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const VentMenuScreen(targetId: 'room_guest'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(VentMenuScreen), findsOneWidget);
    expect(find.text('Choose Your Vent'), findsOneWidget);
    expect(find.byType(VentActionCard), findsWidgets);
    expect(
      find.text(
        'Face vents only — tap a scene below.\nFor room smashing, use Home → Rooms & Scenes.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('SmashScene with roomGuestTarget renders without hanging',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: SmashScene(target: roomGuestTarget),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SmashScene), findsOneWidget);
  });

  testWidgets('vent-menu with invalid targetId shows Character Not Found error state',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const VentMenuScreen(targetId: 'invalid_target_123'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Character Not Found'), findsWidgets);
    expect(find.text('Choose Character'), findsOneWidget);
    expect(find.text('Go Home'), findsOneWidget);
  });
}
